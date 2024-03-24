// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";

contract PyramidCards is VRFConsumerBaseV2 {

    struct Card {
        uint256 id;         // this id will be different for each card
        uint256 quantity; 
    }

    // ============================================== StateVariables ==============================================
    uint256 public constant PRICE = 0.001 ether;
    address public admin;

    mapping(address => uint256) public userBalances;     // draw balance of each user
    mapping(address => Card[]) public userCollection;    // cards collection of each user

    mapping(string => uint256[]) public poolNameToIds;   // Collection "A" -> id [1,2,3,4,5] id are fixed
    mapping(string => uint256[]) public poolNameToProbabilities; //     "A" -> pro[20,20,20,20,20]
    mapping(string => Card[]) public collectionAward;   // collection and their rewards

    uint256 public idCounter = 0;                       // Tracks the next sequential number for assigning each ID (ID will never repeat)
    mapping(string => bool) public collectionActive;    // Tracks the existing keys in poolNameToIds mapping (default value is FALSE for booleans)
    mapping(string => bool) public awardActive;         // Tracks the existing keys in collectionAward mapping
    mapping(uint256 => string) private IdsToPoolName;   // Records each ID as KEY and its corresponding collection name as VALUE
                                                        // *** MESSAGE FOR TEAM: CAN EITHER CHANGE THE CARD STRUCT (ADD COLLECTION NAME VARIABLE) OR SET THIS REVERSED MAPPING ***

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    // Variables for chainlink random number function:
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NOM_WORDS = 1;
    uint16 private constant REQEUST_CONFIRMATIONS = 3;
    uint256 private constant MAX_CHANCE_VALUE = 100;
    // record mapping
    mapping(uint256 => address) public s_requestIdToSender;
    mapping(uint256 => string) public s_requestIdToCollection;

    // number of cards to redeem for new chance
    uint16 private constant NUMS_EXCHANGE_CHANCE = 4;


    // ============================================== Modifiers ==============================================
    modifier isAdmin(){
        require(msg.sender == admin, "You are not the admin, access denied");
        _;
    }

    modifier drawChanceEnough(){
        require(userBalances[msg.sender] > 0, "Drawchance not enough, cannot draw");
        _;
    }

    modifier isCollectionValidToCreate(string memory name, uint256[] memory probs){
        // Check if the input name is valid
        require(collectionActive[name] == false, "Collection name is already active");
        // Check if the input probabilities are valid
        uint256 sumProb = 0;
        for (uint256 i = 0; i < probs.length; i++) {
            sumProb += probs[i];
        }
        require(sumProb == 100, "Invalid probability inputs, the sum is not 100%");
        _;
    }

    modifier isCollectionNameValidToOperate(string memory name){
        require(collectionActive[name] == true, "Collection name is not active");
        _;
    }

    modifier isAwardValidToAdd(string memory awardName, uint256[] memory ids, uint256[] memory num){
        // Check if the input award name is valid
        require(awardActive[awardName] == false, "Award name is already active");
        // Check if the input required ids are valid
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0 && ids[i] <= idCounter, "ID set is invalid");
        }
        // Check if the input required ids and required quantities have the same size
        require(ids.length == num.length, "The size of input required IDs and required quantities do not match");
        _;
    }

    modifier isAwardvalidToOperate(string memory awardName){
        require(awardActive[awardName] == true, "Award name is not active");
        _;
    }

    // ============================================== Events ==============================================
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);     // Event to log the transfer of admin rights (optional)
    event CardDraw(address indexed owner, uint256 id);  // Event to log which card is drawn


    // ============================================== User Functions ==============================================
    // constructor
    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        admin = msg.sender;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
    }

    // User can use this to add draw balance to theirselves
    function addBalance() external payable {
        require(msg.value > 0, "The sent balance must be greater than 0");
        require(msg.value % PRICE == 0, "The sent balance must be multiple of unit price");
        
        // add to user's draw chances;
        userBalances[msg.sender] += msg.value / PRICE;
    }

    // dismantle cards to redeem chance
    function redeemChance(uint256 id) external {
        bool cardFound = false;
        // Find the card in the user's collection and check the quantity
        for (uint i = 0; i < userCollection[msg.sender].length; i++) {
            if (userCollection[msg.sender][i].id == id) {
                require(userCollection[msg.sender][i].quantity >= NUMS_EXCHANGE_CHANCE, "Not enough cards to redeem chance");
                
                // Deduct from the card's quantity
                userCollection[msg.sender][i].quantity -= NUMS_EXCHANGE_CHANCE;

                // Remove the card from array if the quantity is now zero
                if (userCollection[msg.sender][i].quantity == 0) {
                    removeCardFromCollection(msg.sender, i);
                }

                cardFound = true;
                break;
            }
        }

        // Revert if the card was not in the user's collection after iteration
        require(cardFound, "Card not found in collection");

        // add draw chances
        userBalances[msg.sender]++;
    }

    // Helper function to remove a card from array
    function removeCardFromCollection(address user, uint index) internal {
        require(index < userCollection[user].length, "Index out of bounds");

        // Move the last element into the place to delete, and remove the last element from the list
        userCollection[user][index] = userCollection[user][userCollection[user].length - 1];
        userCollection[user].pop();
    }

    // FUNCTION only for testing and can only be called by admin
    function testMintCard(address user, uint256 cardId, uint256 quantity) public isAdmin {
        bool cardExists = false;

        // Check if the user already has the card
        for (uint i = 0; i < userCollection[user].length; i++) {
            if (userCollection[user][i].id == cardId) {
                userCollection[user][i].quantity += quantity; // Increase the quantity
                cardExists = true;
                break;
            }
        }

        // If the card does not exist, add a new card to the collection
        if (!cardExists) {
            userCollection[user].push(Card(cardId, quantity));
        }
    }
    
    // Function to get collection of card of the caller
    function getUserCollection() public view returns(uint256[] memory, uint256[] memory) {
        address user = msg.sender;
        uint256[] memory ids = new uint256[](userCollection[user].length);
        uint256[] memory quantities = new uint256[](userCollection[user].length);

        for (uint i = 0; i < userCollection[user].length; i++) {
            ids[i] = userCollection[user][i].id;
            quantities[i] = userCollection[user][i].quantity;
        }

        //return the id and corresponding quantities as arrays
        return (ids, quantities);
    }

    // get user's draw chance
    function getUserBalances(address user) public view returns(uint256) {
        return userBalances[user];
    }
    
    // User can draw card given he/she has enough ether
    function drawRandomCard(string memory collection) external drawChanceEnough returns(uint256){
        // Random function of chainlink:
        require(poolNameToIds[collection].length != 0, "This pool does not exist");
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQEUST_CONFIRMATIONS,
            i_callBackGasLimit,
            NOM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;    // record requestId to address
        s_requestIdToCollection[requestId] = collection;    // record requestId to collection we want to draw
        return requestId;
    }

    // callback function for vrfCoordinatorV2 to genearte randomWords
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // retrieve card owner and collection name first
        address cardOwner = s_requestIdToSender[requestId];
        string memory collection = s_requestIdToCollection[requestId];
        // calculate the drawn card based on rng returned from VRFCoordinatorV2
        uint256 rng = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 cardIndex = getCardIdFromRng(rng, collection);
        console.log("Random card index is: ", cardIndex);
        uint256 cardId = poolNameToIds[collection][cardIndex];
        console.log("Random card id is: ", cardId);

        // emit the event of drawed card
        emit CardDraw(cardOwner, cardId);

        // user draw this card
        // if this card already be possessed?
        console.log("User currently has: ", userCollection[cardOwner].length);
        for (uint256 i = 0; i < userCollection[cardOwner].length; i++){
            if (userCollection[cardOwner][i].id == cardId){
                userCollection[cardOwner][i].quantity += 1;
                userBalances[cardOwner] -= 1;
                return;
            }
        }
        // otherwise: this is a new card
        userCollection[cardOwner].push(Card({
            id: cardId,
            quantity: 1
        }));
        userBalances[cardOwner] -= 1;
    }

    // chance array for cardId generation
    function getChanceArray(string memory collection) public view returns(uint256[] memory) {
        uint256[] memory probability = poolNameToProbabilities[collection];
        uint256[] memory chanceArray = new uint256[](probability.length);
        uint sum = 0;
        for(uint256 i = 0; i < probability.length; i++){
            sum = sum + probability[i];
            chanceArray[i] = sum;
        }        
        return chanceArray;
    }

    // get cardId from the chance array and rng
    function getCardIdFromRng(uint256 rng, string memory collection) private view returns(uint256) {
        uint256 cumulativeSum = 0;
        uint256[] memory chanceArray = getChanceArray(collection);
        uint256 i;
        for(i = 0; i < chanceArray.length; i++) {
            if(rng >= cumulativeSum && rng < cumulativeSum + chanceArray[i]) {
                break;
            }
            cumulativeSum = cumulativeSum + chanceArray[i];
        }
        return i;
    }

    // ============================================== Admin Functions ==============================================

    /** Admin creates a new collection by storing the card IDs and probabilities in two mappings corresponding to the collection name
     *  Input : The collection name and an array of each card's probability
     *  Output: None
     */
    function createCollections(string memory name, uint256[] memory probabilities) external isAdmin isCollectionValidToCreate(name, probabilities) {
        // Store the IDs and probabilities of the new collection in the two mappings
        for (uint256 i = 0; i < probabilities.length; i++) {
            idCounter++;                                            // Let ID start from 1
            poolNameToIds[name].push(idCounter);                    // Increase the size of the array and add the IDs 
            poolNameToProbabilities[name].push(probabilities[i]);   // Increase the size of the array and add the probabilities
            IdsToPoolName[i] = name;                                // Record the collection name for each new card ID
        }
        // Activate the collection (update the tracker mapping)
        collectionActive[name] = true;
    }


    /** Admin deletes an existing collection
     *  Input : The collection name
     *  Output: None
     */
    function deleteCollections(string memory name) public isAdmin isCollectionNameValidToOperate(name) {
        // Reset the mapping value to default address
        for (uint256 i = 0; i < poolNameToIds[name].length; i++) {
            delete IdsToPoolName[poolNameToIds[name][i]];
        }
        delete poolNameToIds[name];
        delete poolNameToProbabilities[name];
        // Deactivate the collection (update the tracker mapping)
        collectionActive[name] = false;
    }


    /** Let frontend developers get the IDs of all cards in a specific collection
     *  Input : The collection name
     *  Output: An array that contains all IDs in the collection
     */ 
    function getCollections(string memory name) public view isCollectionNameValidToOperate(name) returns(uint256[] memory) {
        return poolNameToIds[name];
    }


    /** Let frontend developers to get all probabilities of all cards in a specific collection
     *  Input:  The collection name
     *  Output: An array that contains all probabilities in the collection
     */ 
    function getCollectionProbability(string memory name) public view isCollectionNameValidToOperate(name) returns(uint256[] memory) {
        return poolNameToProbabilities[name];
    }


    /**  Admin defines and sets a new award by storing the cards in the mapping corresponding to the IDs
     *   mapping(string => Card[]) public collectionAward;
     *   Input : The award name, an array of required card IDs, and an array of required quantities
     *   Output: None
     */
    function setCollectionAward(string memory awardName, uint256[] memory ids, uint256[] memory num) public isAdmin isAwardValidToAdd(awardName, ids, num) {
        // Store the input required IDs and required quantities of the new award in the mapping
        for (uint256 i = 0; i < ids.length; i++) {
            collectionAward[awardName].push(Card({
                id: ids[i],
                quantity: num[i]
            }));
        }
        // Activate the award (update the tracker mapping)
        awardActive[awardName] = true;
    }


    /** Admin deletes an existing award
     *  Input : The award name
     *  Output: None
     */
    function deleteCollectionAward(string memory awardName) public isAdmin isAwardvalidToOperate(awardName) {
        // Reset the mapping value to default address
        delete collectionAward[awardName];
        // Deactivate the collection (update the tracker mapping)
        awardActive[awardName] = false;
    }


    /** Let frontend developers to get all cards in a specific award collection
     *  Input:  The award name
     *  Output: Two arrays that contains required card ids and quantities SEPARATELY for the award collection
     */ 
    function getCollectionAward(string memory awardName) public view isAwardvalidToOperate(awardName) returns(uint256[] memory, uint256[] memory) {
        // Create two temporary arrays for returning required IDs and required quantities
        uint256[] memory awardRequiredIds = new uint256[](collectionAward[awardName].length);
        uint256[] memory awardRequiredQuantities = new uint256[](collectionAward[awardName].length);
        
        // Copy the information from original mapping
        for (uint256 i = 0; i < collectionAward[awardName].length; i++) {
            awardRequiredIds[i] = collectionAward[awardName][i].id;
            awardRequiredQuantities[i] = collectionAward[awardName][i].quantity;
        }
        return (awardRequiredIds, awardRequiredQuantities);
    }


    /** Original admin address transfers admin rights to a new admin address
     *  Input:  The award name
     *  Output: None
     */ 
    function changeAdmin(address newAdmin) public isAdmin {
        // Log the admin transfer event (optional)
        emit AdminChanged(admin, newAdmin);
        // Update the admin to the new address
        admin = newAdmin;
    }


    /** Admin can monitor user's card information (collection name, ID, and quantity)
     *  Input:  The user address
     *  Output: Three arrays that contains the collection name, ID, and quantity SEPARATELY for each card that the user have
     */ 
    function getUserCardCollections(address user) public view isAdmin returns (string[] memory , uint256[] memory, uint256[] memory quantities) {
        // Create three temporary arrays for returning the information of the user's cards
        string[] memory userCardCollectionNames = new string[](userCollection[user].length);
        uint256[] memory userCardIds = new uint256[](userCollection[user].length);
        uint256[] memory userCardQuantities = new uint256[](userCollection[user].length);
        // Copy the user's card information from original mapping
        for (uint256 i = 0; i < userCollection[user].length; i++) {
            userCardCollectionNames[i] = IdsToPoolName[userCollection[user][i].id];
            userCardIds[i] = userCollection[user][i].id;
            userCardQuantities[i] = userCollection[user][i].quantity;
        }
        return (userCardCollectionNames, userCardIds, userCardQuantities);
    }


    /** Admin can draw money from the contract
     */
    function adminDrawMoney() public isAdmin {
        require(address(this).balance > 0, "The balance of this contract should be larger than 0");
        (bool ok, ) = admin.call{value: address(this).balance}("");
        require(ok, "Failed to withdraw ether to admin");
    }

}
