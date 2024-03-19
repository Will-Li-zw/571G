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
    function AddBalance() external payable {
        require(msg.value > 0, "The sent balance must be greater than 0");
        // TODO: change to draw chances;
        userBalances[msg.sender] += msg.value;
    }

    function redeemChance(uint256 id) external {

    }

    function getUserCollection(address user) public view returns(uint256[] memory, uint256[] memory) {

    }

    function getUserBalances(address user) public view returns(uint256) {

    }
    

    // User can draw card given he/she has enough ether
    function drawRandomCard(string memory collection) external drawPriceEnough returns(uint256){
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

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address cardOwner = s_requestIdToSender[requestId];
        string memory collection = s_requestIdToCollection[requestId];
        uint256 rng = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 cardIndex = getCardIdFromRng(rng, collection);
        uint256 cardId = poolNameToIds[collection][cardIndex];

        // user draw this card!
        // if this card already be possessed?
        Card[] memory cards = userCollection[cardOwner];
        console.log("User currently has: ", cards.length);
        for (uint256 i = 0; i < cards.length; i++){
            if (cards[i].id == cardId){
                cards[i].quantity += 1;
                return;
            }
        }
        // otherwise: this is a new card
        userCollection[cardOwner].push(Card({
            id: cardId,
            quantity: 1
        }));
    }

    // chance array
    function getChanceArray(string memory collection) public view returns(uint256[] memory) {
        // 0 - 24, 25 - 49, 50 - 74: 1,2,3
        // 75 - 89: 4
        // 90 - 99: 5
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
    // create a new collection of cards
    function createCollections(string memory name, uint256[] memory ids, uint256[] memory probabilities) external isAdmin {
        // create new card
        // TODO: Set two mappings:

        // poolNameToIds
        // poolNameToProbabilities
    }

    function getCollections() public view  {

    }

    function getCollectionProbability(string memory collection) public view returns(uint256[] memory) {

    }


    // create a new collection of cards
    function setCollectionAward(string memory awardName, uint256[] memory ids, uint256[] memory num) public isAdmin {
        
    }

    function getCollectionAward(string memory awardName) public view {

    }

}
