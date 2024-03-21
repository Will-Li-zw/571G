// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract PyramidCards is VRFConsumerBaseV2 {

    struct Card {
        uint256 id;         // this id will be different for each card
        uint256 quantity; 
    }

    // ============================================== StateVariables ==============================================
    uint256 public constant PRICE = 0.001 ether;
    address public admin;

    mapping(address => uint256) public userBalances;     // balance of each user
    mapping(address => Card[]) public userCollection;    // cards collection of each user

    mapping(string => uint256[]) public poolNameToIds;   // Collection "A" -> id [1,2,3,4,5] id are fixed
    mapping(string => uint256[]) public poolNameToProbabilities; //     "A" -> pro[20,20,20,20,20]
    mapping(string => Card[]) public collectionAward;   // TODO: "Fake award"


    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    // Variables for chainlink random number function:
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NOM_WORDS = 1;
    uint16 private constant REQEUST_CONFIRMATIONS = 3;

    uint256 private constant MAX_CHANCE_VALUE = 100;
    // record mapping
    mapping(uint256 => address) s_requestIdToSender;
    mapping(uint256 => string) s_requestIdToCollection;

    // number of cards to redeem for new chance
    uint16 private constant NUMS_EXCHANGE_CHANCE = 4;

    // ============================================== Modifiers ==============================================
    modifier isAdmin(){
        require(msg.sender == admin, "You are not the admin, access denied");
        _;
    }

    modifier drawPriceEnough(){
        require(userBalances[msg.sender] > 0, "Drawchance not enough, cannot draw");
        _;
    }

    // ============================================== Events ==============================================
    event CardListed(uint256 id, address owner, uint256 price);
    event CardDelisted(uint256 id);
    event CardBought(uint256 id, address from, address to, uint256 price);


    // ============================================== User Functions ==============================================
    // constructors
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

    // User can use this to add balance to theirselves
    function addBalance() external payable {
        require(msg.value > 0, "The sent balance must be greater than 0");
        require(msg.value % PRICE == 0, "The sent balance must be multiple of unit price");
        
        // add to user's draw chances;
        userBalances[msg.sender] += msg.value / PRICE;
    }

    //dismantle cards to redeem chance
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

    // Admin function to add cards for testing
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
    
    function getUserCollection(address user) public view returns(uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](userCollection[user].length);
        uint256[] memory quantities = new uint256[](userCollection[user].length);

        for (uint i = 0; i < userCollection[user].length; i++) {
            ids[i] = userCollection[user][i].id;
            quantities[i] = userCollection[user][i].quantity;
        }

        //return the id and corresponding quantities as arrays
        return (ids, quantities);
    }

    function getUserBalances(address user) public view returns(uint256) {
        return userBalances[user];
    }
    

    // User can draw card given he/she has enough ether
    function drawRandomCard(string memory collection) external drawPriceEnough {
        // Random function of chainlink:
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQEUST_CONFIRMATIONS,
            i_callBackGasLimit,
            NOM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;    // record requestId to address
        s_requestIdToCollection[requestId] = collection;    // record requestId to collection we want to draw
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address cardOwner = s_requestIdToSender[requestId];
        uint256 rng = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 cardId = getCardIdFromRng(rng); // cardId from 1 to 5
        string memory collection = s_requestIdToCollection[requestId];

        // user draw this card!
        userCollection[cardOwner].push(Card({
            id: cardId,
            quantity: 1
        }));
    }

    // chance array
    function getChanceArray() public pure returns(uint256[5] memory) {
        // 0 - 24, 25 - 49, 50 - 74: 1,2,3
        // 75 - 89: 4
        // 90 - 99: 5
        return [25, 50, 75, 90, MAX_CHANCE_VALUE];
    }

    // get cardId from the chance array and rng
    function getCardIdFromRng(uint256 rng) private pure returns(uint256) {
        uint256 cumulativeSum = 0;
        uint256[5] memory chanceArray = getChanceArray();
        uint256 i;
        for(i = 0; i < chanceArray.length; i++) {
            if(rng >= cumulativeSum && rng < cumulativeSum + chanceArray[i]) {
                break;
            }
            cumulativeSum = cumulativeSum + chanceArray[i];
        }
        return i+1;
    }

    // ============================================== Admin Functions ==============================================
    // create a new collection of cards
    function createCollections(string memory name, uint256[] memory ids, uint256[] memory probabilities) external isAdmin {
        // create new card
        // TODO: Set two mappings:

        // poolNameToIds
        // poolNameToProbabilities
    }

    function getCollections() public view  {

    }

    function getCollectionProbability() public view  {

    }


    // create a new collection of cards
    function setCollectionAward(string memory awardName, uint256[] memory ids, uint256[] memory num) public isAdmin {
        
    }

    function getCollectionAward(string memory awardName) public view {

    }

}
