// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {PyramidCards} from "../contracts/PyramidCards.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract PyramidCardsTest is Test {
    struct Card {
        uint256 id;
        address owner;
        uint256 amount;
    }
    // local contracts deployment:

    PyramidCards public pyramidCards;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;

    // params to deploy the contract
    uint96 constant BASE_FEE = 1e17; // 25e^18      base_cost per each request
    uint96 constant GAS_PRICE_LINK = 1e9;
    uint96 constant FUND_AMOUNT = 1e18; // 1e^18
    uint32 constant callBackGasLimit = 100000;
    bytes32 constant gasLane = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // mock accounts
    address customer = address(1); // fake user
    address admin = address(2); // fake admin

    // params for test
    uint256 constant PRICE = 0.001 ether; // test ether
    uint256 constant NUMS_EXCHANGE_CHANCE = 4;

    // Test cases for admin functions (for collection tests)
    string collectionTestName = "TestCollection";
    uint256[] validProbabilities = [20, 30, 50];
    uint256[] invalidProbabilities = [30, 40, 60];
    string[] urlTestArray = ["a", "b", "c"];

    // Test cases for admin functions (for award tests)
    string awardTestName = "TestAward";
    string awardTestName2 = "TestAward2";
    uint256[] validRequiredIds = [1, 2, 3];
    uint256[] invalidRequiredIds = [1, 2, 3, 4];
    uint256[] requiredNums = [1, 1, 2];
    uint256[] invalidRequiredNums = [1, 1, 2, 3];

    // uint256[] ids = new uint256[](5);
    // uint256[] prob = new uint256[](5);

    event CardDraw(address indexed owner, uint256 id);
    event CardRequest(address indexed owner, uint256 requestId);
    event CardRedeemed(address indexed owner, uint256 id, uint256 balance);  // Event to log user redeem and new balance
    event PoolCreated(address indexed admin, uint256[] ids); // Event to log pool
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    function setUp() public {
        vm.startPrank(admin);
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        uint64 sub_id = vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(sub_id, FUND_AMOUNT);

        pyramidCards = new PyramidCards(address(vrfCoordinatorMock), gasLane, sub_id, callBackGasLimit);

        vrfCoordinatorMock.addConsumer(sub_id, address(pyramidCards));

        (uint96 balance,, address owner, address[] memory consumers) = vrfCoordinatorMock.getSubscription(sub_id);
        console.log("Balance is: ", balance);
        console.log("owner is: ", owner);
        console.log("Address of this contract is: ", address(this));
        console.log("Admin of Pyramid is: ", pyramidCards.admin());
        console.log("consumer is: ", consumers[0]);

        vm.deal(customer, 10 ether); // original balance of user
        vm.stopPrank();
    }

    // ============================================== Customer Function Test ==============================================

    /**
     * Test 1: User can add a multiple draw chance to their balance
     */
    function testAddBalance() public {
        uint256 initialBalance = pyramidCards.getUserBalances(customer);
        uint16 unit = 3;
        uint256 amount = PRICE * unit;

        vm.prank(customer);
        pyramidCards.addBalance{value: amount}();

        uint256 newBalance = pyramidCards.getUserBalances(customer);
        assertEq(newBalance, initialBalance + unit, "Balance should increase by the sent amount / PRICE");

        vm.stopPrank();
    }

    /**
     * Test 2: addBalance edge case test: no value received
     */
    function testAddBalanceFailWithZeroAmount() public {
        vm.prank(customer);
        vm.expectRevert("The sent balance must be greater than 0");
        pyramidCards.addBalance{value: 0}();
        vm.stopPrank();
    }

    /**
     * Test 3: addBalance edge case test: when value received is not a multiple of unit price
     */
    function testAddBalanceFailWithNonMultipleOfPrice() public {
        uint256 nonMultipleAmount = 0.0015 ether; // An amount that is not a multiple of PRICE
        vm.prank(customer);
        vm.expectRevert("The sent balance must be multiple of unit price");
        pyramidCards.addBalance{value: nonMultipleAmount}();
    }

    /**
     * Test 4: User could redeem four same cards to one draw chance
     */
    function testRedeemChance() public {
        uint256 cardIdToRedeem = 1;

        // Add cards to the customer, test both consume all of the chosen cards or not
        vm.startPrank(admin);
        pyramidCards.testMintCard(customer, cardIdToRedeem, NUMS_EXCHANGE_CHANCE);
        pyramidCards.testMintCard(customer, cardIdToRedeem + 1, NUMS_EXCHANGE_CHANCE + 1);
        vm.stopPrank();
        // check the existence of two cards
        vm.startPrank(customer);
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        bool card1Found;
        bool card2Found;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == cardIdToRedeem) {
                //the second card should still be in the collection with quantity 1
                assertEq(quantities[i], NUMS_EXCHANGE_CHANCE, "Card quantity should be 4");
                card1Found = true;
            }
            if (ids[i] == cardIdToRedeem + 1) {
                assertEq(quantities[i], NUMS_EXCHANGE_CHANCE + 1, "Card quantity should be 5");
                card2Found = true;
            }
        }
        assertEq(card1Found, true, "card 1 does not exist");
        assertEq(card2Found, true, "card 2 does not exist");

        uint256 initialChances = pyramidCards.getUserBalances(customer);
        vm.startPrank(customer);
        vm.expectEmit(true, false, false, true);
        emit CardRedeemed(address(customer), cardIdToRedeem, 1);
        pyramidCards.redeemChance(cardIdToRedeem);
        vm.expectEmit(true, false, false, true);
        emit CardRedeemed(address(customer), cardIdToRedeem + 1, 2);
        pyramidCards.redeemChance(cardIdToRedeem + 1);
        uint256 newChances = pyramidCards.getUserBalances(customer);
        assertEq(newChances, initialChances + 2, "Chances should increase by 2 after redeeming"); // because we redeem twice

        (ids, quantities) = pyramidCards.getUserCollection();
        bool firstCardFound = false;
        bool secondCardFound = false;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == cardIdToRedeem + 1) {
                //the second card should still be in the collection with quantity 1
                assertEq(quantities[i], 1, "Card quantity should decrease by NUMS_EXCHANGE_CHANCE");
                secondCardFound = true;
            }
            if (ids[i] == cardIdToRedeem) {
                firstCardFound = true;
                break;
            }
        }
        //the first card should not be in the collection
        assertFalse(firstCardFound, "First Card shouldn't be in the user's collection");
        assertTrue(secondCardFound, "Second Card should still have 1 quantity left");
        vm.stopPrank();
    }

    /**
     * Test 5: User cannot redeem card when no enough cards are selected.
     */
    function testRedeemChanceRevertInsufficientCards() public {
        uint256 cardIdToRedeem = 1;
        uint256 insufficientQuantity = NUMS_EXCHANGE_CHANCE - 1; // Not enough cards to redeem

        // Add fewer cards than needed for redemption
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardIdToRedeem, insufficientQuantity);

        // Expect the trans action to revert
        vm.startPrank(customer);
        vm.expectRevert("Not enough cards to redeem chance");
        pyramidCards.redeemChance(cardIdToRedeem);
        vm.stopPrank();
    }

    /**
     * Test 6: User should be able to check inventory of collection
     */
    function testGetUserCollection() public {
        // Setup: Add two kinds of cards to the customer
        uint256 cardId1 = 1;
        uint256 quantity1 = 3;
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardId1, quantity1);

        uint256 cardId2 = 2;
        uint256 quantity2 = 5;
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardId2, quantity2);

        vm.startPrank(customer);
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();

        // Check that the returned data is correct
        bool card1Found = false;
        bool card2Found = false;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == cardId1) {
                assertEq(quantities[i], quantity1, "Quantity of card 1 does not match");
                card1Found = true;
            }
            if (ids[i] == cardId2) {
                assertEq(quantities[i], quantity2, "Quantity of card 2 does not match");
                card2Found = true;
            }
        }
        assertEq(card1Found, true, "card 1 does not exist");
        assertEq(card2Found, true, "card 2 does not exist");
        vm.stopPrank();
    }

    // ============================================== Admin Function Test ==============================================

    /**
     * Test 1: Admin cannot CREATE card collections with invalid inputs,
     *          and other users cannot create card collections
     *          collection can be created using proper params
     */
    function testCreateCollections() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.stopPrank();

        // If the sum of probabilities does not equal to 100% (expect to have error)
        vm.startPrank(admin);
        vm.expectRevert("Invalid probability inputs, the sum is not 100%");
        pyramidCards.createCollections(collectionTestName, awardTestName,invalidProbabilities, urlTestArray);

        // If collection name already exist (expect to have error)
        uint256[] memory expectedIds = new uint256[](3);
        expectedIds[0] = 1;
        expectedIds[1] = 2;
        expectedIds[2] = 3;
        vm.expectEmit(true, false, false, true);
        emit PoolCreated(address(admin), expectedIds);
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.expectRevert("Collection name is already active");
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.stopPrank();

        // test the getters:
        string[] memory poolNames;
        uint256[] memory ids;
        uint256[] memory probs;
        uint256[] memory lens;
        string[] memory urls;
        string[] memory awards;
        uint256[] memory quantities;
        uint256[] memory expectedQuantities = new uint256[](3);
        expectedQuantities[0] = 1;
        expectedQuantities[1] = 1;
        expectedQuantities[2] = 1;
        (poolNames, ids, probs, lens) = pyramidCards.getAllCollections();
        assertEq(collectionTestName, poolNames[0], "PoolName created not match");
        assertEq(expectedIds, ids, "Ids created not match");
        assertEq(validProbabilities, probs, "Probs not match");
        assertEq(lens[0], ids.length, "Length array not match");
        (ids, urls) = pyramidCards.getAllURLs();
        assertEq(expectedIds, ids, "Ids not match");
        assertEq(urlTestArray, urls, "Urls not match");
        (awards, ids, quantities, lens) = pyramidCards.getAllRewards();
        assertEq(awardTestName, awards[0], "Award not match");
        assertEq(expectedIds, ids, "Ids not match");
        assertEq(expectedQuantities, quantities, "quantities not match");
        assertEq(lens[0], ids.length, "Length array not match");
    }


    /**
     * Test 2: Only admin can transfer admin rights to a new admin address
     */
    function testChangeAdmin() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.changeAdmin(customer);
        vm.stopPrank();

        // If user is admin
        vm.startPrank(admin);
        vm.expectEmit(true, true, false, false);
        emit AdminChanged(address(admin), address(customer));
        pyramidCards.changeAdmin(customer);
        assertEq(pyramidCards.admin(), customer);
        vm.stopPrank();
    }

    /**
     * Test 3: Admin can withdraw the money in the contract
     */
    function testWithDrawContractMoney() public {
        // when no balance in the contract, withdraw fails
        uint256 initialAdminBalance = admin.balance;
        vm.startPrank(admin);
        vm.expectRevert("The balance of this contract should be larger than 0");
        pyramidCards.adminDrawMoney();
        vm.stopPrank();

        // customer cannot withdraw
        vm.startPrank(customer);
        pyramidCards.addBalance{value: PRICE}();
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.adminDrawMoney();
        vm.stopPrank();

        // admin successfully withdraw
        vm.startPrank(admin);
        pyramidCards.adminDrawMoney();
        uint256 afterAdminBalance = admin.balance;
        assertEq(initialAdminBalance + PRICE, afterAdminBalance, "The money withdrawn is not correct");
    }

    /**
     * Test 4: Test front-end getter admin account
     */
    function testIsAdmin() public {
        bool result;
        // customer is not the admin
        vm.prank(customer);
        result = pyramidCards.accountIsAdmin();
        assertEq(false, result, "Customer is not admin");
        // admin will return true
        vm.prank(admin);
        result = pyramidCards.accountIsAdmin();
        assertEq(true, result);
    }

    // ============================================== Draw Card VRF Function Test ==============================================
    /**
     * Test 1: User should not be able to draw if the pool does not exist
     */
    function testDrawNoPool() public {
        vm.startPrank(customer);
        pyramidCards.addBalance{value: PRICE}();
        vm.expectRevert("This pool does not exist");
        pyramidCards.drawRandomCard(collectionTestName);
        vm.stopPrank();
    }

    /**
     * Test 2: Request id to vrfCoordinator should be correctly recorded in the mappings
     */
    function testRandomRequest() public {
        // Create the pool for draw
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.stopPrank();

        // User draws a card
        vm.startPrank(customer);
        uint256 requestId = 1;  // mock test, the requestId always starts from 1
        pyramidCards.addBalance{value: PRICE}();
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        assertEq(customer, pyramidCards.s_requestIdToSender(requestId));
        assertEq(collectionTestName, pyramidCards.s_requestIdToCollection(requestId));
        vm.stopPrank();
    }

    /**
     * Test 3: user should be able to add a random card into his/her collection.
     */
    function testRandomDrawforOnce() public {
        // create a collection of cards
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.stopPrank();

        // user now draw
        vm.startPrank(customer);
        uint256 requestId = 1;
        pyramidCards.addBalance{value: PRICE}();
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);

        // vm.expectEmit(true, false, false, true);
        // emit CardDraw(address(customer), 3);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards)); // NOTE: the random seed is set by requestId, which is always 1 in this case
            // So the returned random word is always the same
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        assertEq(ids.length, 1, "Only one card should be drawn");
        assertEq(ids[0], 3, "Drawn card will have id 3 in this specific case");
        assertEq(quantities[0], 1, "We only draw one card, but non-1 value received");
        vm.stopPrank();
    }

    /**
     * Test 4: user draw "randomly" 5 times and check the result, mock random test
     */
    function testRandomDraw5times() public {
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, awardTestName, validProbabilities, urlTestArray);
        vm.stopPrank();

        // user now draw
        vm.startPrank(customer);
        pyramidCards.addBalance{value: 5 * PRICE}();

        // 1st Draw
        uint256 requestId = 1;
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 3);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards)); // NOTE: the random seed is set by requestId, which is always 1 in this case
            // So the returned random word is always the same
        
        // 2nd Draw
        requestId = 2;
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 3rd Draw
        requestId = 3;
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 4th Draw
        requestId = 4;
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 3);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 5th Draw
        requestId = 5;
        vm.expectEmit(true, false, false, true);
        emit CardRequest(address(customer), requestId);
        pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 3);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 6th Draw expect fail because out of balance:
        vm.expectRevert("Drawchance not enough, cannot draw");
        pyramidCards.drawRandomCard(collectionTestName);

        // Final check:
        // id2 card: 2 times
        // id3 card: 3 time
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        bool id2Found = false;
        bool id3Found = false;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == 2) {
                assertEq(quantities[i], 2, "Wrong number of id2 card found");
                id2Found = true;
            } else if (ids[i] == 3) {
                assertEq(quantities[i], 3, "Wrong number of id3 card found");
                id3Found = true;
            } else {
                revert("wrong id detected, should not have been drawn");
            }
        }
        assertEq(id2Found, true, "No id2 card found.");
        assertEq(id3Found, true, "No id3 card found.");
        vm.stopPrank();
    }
}
