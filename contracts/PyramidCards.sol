// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract PyramidCards is VRFConsumerBaseV2 {
    struct Card {
        uint256 id; // this id will be different for each card
        uint256 quantity;
    }

    // ============================================== StateVariables ==============================================
    uint256 public constant PRICE = 0.001 ether;
    address public admin;

    mapping(address => uint256) public userBalances; // draw balance of each user
    mapping(address => Card[]) public userCollection; // cards collection of each user

    mapping(string => uint256[]) public poolNameToIds; // Collection "A" -> id [1,2,3,4,5] id are fixed
    mapping(string => uint256[]) public poolNameToProbabilities; //     "A" -> pro[20,20,20,20,20]

    string[] public poolNamesArray; // pool names keys to find all information stored in mappings
    uint256[] public idArray; // plain ids array
    uint256[] public probArray; // plain prob array for front-end
    uint256[] public lensArray; // plain lens array records the lenth of each PoolName string to numof ids
    string[] public awardNameArray; // plain award array to store keys

    mapping(string => Card[]) public collectionAward; // mapping of reward to Card[]

    uint256 private idCounter = 0; // Tracks the next sequential number for assigning each ID (ID will never repeat)
    mapping(string => bool) private collectionActive; // Tracks the existing keys in poolNameToIds mapping (default value is FALSE for booleans)
    mapping(string => bool) private awardActive;      // Tracks the existing keys of award in collectionAward mapping 
    mapping(uint256 => string) private IdsToUrls; // Records id to url of each image

    // Variables for chainlink random number function:
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
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
    modifier isAdmin() {
        require(msg.sender == admin, "You are not the admin, access denied");
        _;
    }

    modifier drawChanceEnough() {
        require(userBalances[msg.sender] > 0, "Drawchance not enough, cannot draw");
        _;
    }

    modifier isCollectionValidToCreate(string memory name, uint256[] memory probs) {
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

    // ============================================== Events ==============================================
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin); // Event to log the transfer of admin rights (optional)
    event CardRequest(address indexed owner, uint256 requestId);
    event CardDraw(address indexed owner, uint256 id); // Event to log which card is drawn
    event PoolCreated(address indexed admin, uint256[] ids); // Event to log pool
    event CardRedeemed(address indexed owner, uint256 id, uint256 balance);  // Event to log user redeem and new balance

    // ============================================== User Functions ==============================================
    // constructor
    constructor(address vrfCoordinatorV2, bytes32 gasLane, uint64 subscriptionId, uint32 callBackGasLimit)
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
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
        for (uint256 i = 0; i < userCollection[msg.sender].length; i++) {
            if (userCollection[msg.sender][i].id == id) {
                require(
                    userCollection[msg.sender][i].quantity >= NUMS_EXCHANGE_CHANCE, "Not enough cards to redeem chance"
                );

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
        emit CardRedeemed(msg.sender, id, userBalances[msg.sender]);
    }

    // User want to use a collection of cards to redeem award
    function redeemAward(string memory awardName) external {
        require(awardActive[awardName], "award does not exist");

        // reduce the quantity of 1 of id
        uint256 id;
        for (uint256 i = 0; i < collectionAward[awardName].length; i++){
            id = collectionAward[awardName][i].id;
            remove1ofId(msg.sender, id);        // may revert if quantity not match
        }

  
        // remove the Card if quantity == 0
        bool doubleCheck = false;       // guard boolean
        for (uint256 i = 0; i < userCollection[msg.sender].length; i++){
            if (doubleCheck){
                i -= 1;
                doubleCheck = false;
            }
            // Remove the card from array if the quantity is now zero
            if (userCollection[msg.sender][i].quantity == 0) {
                removeCardFromCollection(msg.sender, i);
                doubleCheck = true; // need to go back to this loop in the next update
            }
        }

        // TODO: have not yet tested: 
        // if (doubleCheck){   // this means that there's still one entry left in the array to be checked
        //     removeCardFromCollection(msg.sender, 0);
        //     doubleCheck = false;
        // }
    }
    
    // Helper function to reduce a card quantity
    function remove1ofId(address user, uint256 id) internal {

        // first remove 1
        for (uint256 i = 0; i < userCollection[user].length; i++){
            if (userCollection[user][i].id == id){
                require(userCollection[user][i].quantity > 0, "User does not has enough card to redeem award.");
                userCollection[user][i].quantity -= 1;
                break;
            }
        }
    }

    // Helper function to remove a card from array
    function removeCardFromCollection(address user, uint256 index) internal {
        require(index < userCollection[user].length, "Index out of bounds");

        // Move the last element into the place to delete, and remove the last element from the list
        userCollection[user][index] = userCollection[user][userCollection[user].length - 1];
        userCollection[user].pop();
    }

    // FUNCTION only for testing and can only be called by admin
    function testMintCard(address user, uint256 cardId, uint256 quantity) public isAdmin {
        bool cardExists = false;

        // Check if the user already has the card
        for (uint256 i = 0; i < userCollection[user].length; i++) {
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
    function getUserCollection() public view returns (uint256[] memory, uint256[] memory) {
        address user = msg.sender;
        uint256[] memory ids = new uint256[](userCollection[user].length);
        uint256[] memory quantities = new uint256[](userCollection[user].length);

        for (uint256 i = 0; i < userCollection[user].length; i++) {
            ids[i] = userCollection[user][i].id;
            quantities[i] = userCollection[user][i].quantity;
        }

        //return the id and corresponding quantities as arrays
        return (ids, quantities);
    }

    // get user's draw chance
    function getUserBalances(address user) public view returns (uint256) {
        return userBalances[user];
    }

    // User can draw card given he/she has enough ether
    function drawRandomCard(string memory collection) external drawChanceEnough {
        // Random function of chainlink:
        require(poolNameToIds[collection].length != 0, "This pool does not exist");
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQEUST_CONFIRMATIONS, i_callBackGasLimit, NOM_WORDS
        );

        emit CardRequest(msg.sender, requestId);

        s_requestIdToSender[requestId] = msg.sender; // record requestId to address
        s_requestIdToCollection[requestId] = collection; // record requestId to collection we want to draw
    }

    // callback function for vrfCoordinatorV2 to genearte randomWords
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // retrieve card owner and collection name first
        address cardOwner = s_requestIdToSender[requestId];
        string memory collection = s_requestIdToCollection[requestId];
        // calculate the drawn card based on rng returned from VRFCoordinatorV2
        uint256 rng = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 cardIndex = getCardIdFromRng(rng, collection);
        uint256 cardId = poolNameToIds[collection][cardIndex];

        // emit the event of drawed card
        emit CardDraw(cardOwner, poolNameToIds[collection][cardIndex]);


        // user draw this card
        // if this card already be possessed?
        for (uint256 i = 0; i < userCollection[cardOwner].length; i++) {
            if (userCollection[cardOwner][i].id == cardId) {
                userCollection[cardOwner][i].quantity += 1;
                userBalances[cardOwner] -= 1;
                return;
            }
        }
        // otherwise: this is a new card
        userCollection[cardOwner].push(Card({id: cardId, quantity: 1}));
        userBalances[cardOwner] -= 1;
    }

    // chance array for cardId generation
    function getChanceArray(string memory collection) public view returns (uint256[] memory) {
        uint256[] memory probability = poolNameToProbabilities[collection];
        uint256[] memory chanceArray = new uint256[](probability.length);
        uint256 sum = 0;
        for (uint256 i = 0; i < probability.length; i++) {
            sum = sum + probability[i];
            chanceArray[i] = sum;
        }
        return chanceArray;
    }

    // get cardId from the chance array and rng
    function getCardIdFromRng(uint256 rng, string memory collection) private view returns (uint256) {
        uint256 lowerBound = 0;
        uint256[] memory chanceArray = getChanceArray(collection);
        uint256 i;
        for (i = 0; i < chanceArray.length; i++) {
            if (rng >= lowerBound && rng < chanceArray[i]) {
                break;
            }
            lowerBound = chanceArray[i];
        }
        return i;
    }

    // ============================================== Admin Functions ==============================================

    // Admin can create pool for the collectableCards
    function createCollections(
        string memory name,
        string memory awardName,
        uint256[] memory probabilities,
        string[] memory urls
    ) external isAdmin isCollectionValidToCreate(name, probabilities) {
        // Store the IDs and probabilities of the new collection in the two mappings
        uint256[] memory result_ids = new uint256[](probabilities.length);
        poolNamesArray.push(name);
        awardNameArray.push(awardName);
        lensArray.push(probabilities.length);

        for (uint256 i = 0; i < probabilities.length; i++) {
            idCounter++; // Let ID start from 1
            poolNameToIds[name].push(idCounter); // Increase the size of the array and add the IDs
            poolNameToProbabilities[name].push(probabilities[i]); // Increase the size of the array and add the probabilities
            IdsToUrls[idCounter] = urls[i]; // Record the url of the image
            collectionAward[awardName].push(Card({id: idCounter, quantity: 1}));
            idArray.push(idCounter);
            probArray.push(probabilities[i]);
            result_ids[i] = idCounter;
        }
        // Activate the collection (update the tracker mapping)
        collectionActive[name] = true;
        awardActive[awardName] = true;
        emit PoolCreated(msg.sender, result_ids);
    }

    // Admin can refer the role to another person
    function changeAdmin(address newAdmin) public isAdmin {
        // Log the admin transfer event (optional)
        emit AdminChanged(admin, newAdmin);
        // Update the admin to the new address
        admin = newAdmin;
    }

    // Admin can withdraw money
    function adminDrawMoney() public isAdmin {
        require(address(this).balance > 0, "The balance of this contract should be larger than 0");
        (bool ok,) = admin.call{value: address(this).balance}("");
        require(ok, "Failed to withdraw ether to admin");
    }

    // ============================================== front-end Functions ==============================================
    
    // front-end method to get all urls with ids one-to-one
    function getAllURLs() external view returns (uint256[] memory, string[] memory) {
        string[] memory result_urls = new string[](idArray.length);
        for (uint256 i = 0; i < idArray.length; i++) {
            string memory url = IdsToUrls[idArray[i]];
            result_urls[i] = url;
        }
        return (idArray, result_urls);
    }

    // front-end method to get all information about collections
    function getAllCollections()
        external
        view
        returns (string[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        return (poolNamesArray, idArray, probArray, lensArray);
    }

    // front-end method to get all information about collections
    function getAllRewards()
        external
        view
        returns (string[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256[] memory quantityArray = new uint256[](idArray.length);
        uint256 index = 0;
        for (uint256 i = 0; i < awardNameArray.length; i++) {
            string memory award = awardNameArray[i]; // find the award name
            Card[] memory cards = collectionAward[award]; // find the required cards[] array
            for (uint256 j = 0; j < cards.length; j++) {
                // then we extract the quantity information
                quantityArray[index] = cards[j].quantity;
                index += 1;
            }
        }

        return (awardNameArray, idArray, quantityArray, lensArray);
    }

    // front-end method to judge current user is admin or not
    function accountIsAdmin() external view returns (bool) {
        return (msg.sender == admin);
    }
}
