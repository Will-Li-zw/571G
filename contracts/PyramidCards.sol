// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract PyramidCards is VRFConsumerBaseV2 {

    struct Card {
        uint256 id;
        address owner;
        string collection;
        uint256 amount; 
        }

    // ============================================== StateVariables ==============================================
    uint256 public constant PRICE = 0.001 ether;
    address public admin;

    mapping(address => uint256) public userBalances;     // balance of each user
    mapping(address => Card[]) public userCollection;    // cards collection of each user

    string[] public collections;   // Collection "A" -> id [1,2,3,4,5] id are fixed
    mapping(string => string) public collectionAward;   // Collection "A" -> award value

    // Card[] public cardForSale;                           // cards for sale  # TODO: we may cancel the market setting of the project

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
        userBalances[msg.sender] += msg.value;
    }
    
    // User can withDraw the ether from their account
    function withdraw() external {
        uint256 balance = userBalances[msg.sender];
        require(balance > 0, "No value can be withdrawn");

        userBalances[msg.sender] = 0; 
        (bool ok, ) = msg.sender.call{value: balance}("");
        require(ok, "Failed to withdraw ether");
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
            owner: cardOwner,
            collection: collection,
            amount: 1
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

    // User want to exchange two cards for one draw chance
    function exchangeForDraw(string memory collection, uint256 id) public {
        
    }

    // ============================================== Admin Functions ==============================================
    // create a new collection of cards
    function createCollections(string memory name) external isAdmin {
        // create new card
        // TODO: how to deal with images

        // collectionCards[name] = 
    }

    // create a new collection of cards
    function setCollectionAward(string memory name, string memory awardValue) external isAdmin {
        collectionAward[name] = awardValue;
    }

}
