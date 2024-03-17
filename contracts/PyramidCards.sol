// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PyramidCards {

    struct Card {
        uint256 id;
        address owner;
        uint256 price;      // # TODO: we may cancel the market setting of the project
        bool isForSale;
    }

    // ============================================== StateVariables ==============================================
    uint256 public constant PRICE = 0.001 ether;
    address public admin;

    mapping(address => uint256) public userBalances;     // balance of each user
    mapping(address => Card[]) public userCollection;    // cards collection of each user

    mapping(string => uint8[]) public collectionCards;   // Collection "A" -> id [1,2,3,4,5]
    mapping(uint8 => uint8) public collectionProbability;// id -> probability of each id
    mapping(string => uint256) public collectionAward;   // Collection "A" -> award value

    Card[] public cardForSale;                           // cards for sale  # TODO: we may cancel the market setting of the project


    // ============================================== Modifiers ==============================================
    modifier isAdmin(){
        require(msg.sender == admin, "You are not the admin, access denied");
        _;
    }

    modifier drawPriceEnough(){
        require(msg.value == PRICE, "Ether not enough, cannot draw");
        _;
    }

    // ============================================== Events ==============================================
    event CardListed(uint256 id, address owner, uint256 price);
    event CardDelisted(uint256 id);
    event CardBought(uint256 id, address from, address to, uint256 price);


    // ============================================== User Functions ==============================================
    // constructors
    constructor() {
        admin = msg.sender;
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

    // User can draw card
    function drawCard() external payable drawPriceEnough {
        // Random function of chainlink:
        uint256 randomId = 0;
        // Retrieve the random card, modify the owner information
        Card memory card = Card({
            id: randomId,
            owner: msg.sender,
            price: 0,
            isForSale: false
        });
        // Add to the user's collection
        userCollection[msg.sender].push(Card({
            id: randomId,
            owner: msg.sender,
            price: 0,
            isForSale: false
        }));
    }

    // make cards for sale
    function addMyCardForSale(uint256 id) public {

    }

    // buy the card with id
    function buyCard(uint256 id) public {

    }

    // User want to exchange two cards for one draw chance
    function exchangeForDraw(uint256 id_1, uint256 id_2) public {

    }

    // ============================================== Admin Functions ==============================================
    // create a new collection of cards
    function createCollectionofCards(string memory name, uint256 id) external isAdmin {
        // create new card
        // TODO: how to deal with images

        // collectionCards[name] = 
    }

    // create a new collection of cards
    function setCollectionAward(string memory name, uint256 awardValue) external isAdmin {
        collectionAward[name] = awardValue;
    }

    // get all cards that for sale
    function getAllForSale() public view returns (Card[] memory) {
        return cardForSale;
    }
}
