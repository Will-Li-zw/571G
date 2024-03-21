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

    PyramidCards public pyramidCards;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;

    address customer = address(1); // fake user
    uint256 constant PRICE = 0.001 ether; // test ether
    address admin = address(2); // fake admin

    uint96 constant BASE_FEE = 1e17; // 25e^18      base_cost per each request
    uint96 constant GAS_PRICE_LINK = 1e9;  

    uint96 constant FUND_AMOUNT = 1e18;  // 1e^18
    uint32 constant callBackGasLimit = 100000;
    bytes32 constant gasLane = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    string constant collection = "A";
    // uint256[] ids = new uint256[](5);
    // uint256[] prob = new uint256[](5);

    event CardDraw(address indexed owner, uint256 id);

    function setUp() public {
        vm.startPrank(admin);
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        uint64 sub_id = vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(sub_id, FUND_AMOUNT);
        
        pyramidCards = new PyramidCards(address(vrfCoordinatorMock), gasLane, sub_id, callBackGasLimit);

        vrfCoordinatorMock.addConsumer(sub_id, address(pyramidCards));

        (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) = vrfCoordinatorMock.getSubscription(sub_id);
        console.log("Balance is: ", balance);
        console.log("owner is: ", owner);
        console.log("Address of this contract is: ", address(this));
        console.log("Admin of Pyramid is: ", pyramidCards.admin());
        console.log("consumer is: ", consumers[0]);

        vm.deal(customer, 10 ether);    // original balance of user

        // setup the ids and probs
        // ids[0] = 1;
        // ids[1] = 2;
        // ids[2] = 3;
        // ids[3] = 4;
        // ids[4] = 5;
        // // ids = [uint256(1), 2, 3, 4, 5];
        // prob[0] = 10;
        // prob[1] = 10;
        // prob[2] = 10;
        // prob[3] = 35;
        // prob[4] = 35;
        vm.stopPrank();
    }

    // test 1 -- test addbalance
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

    function testAddBalanceFailWithZeroAmount() public {
        vm.prank(customer); 
        vm.expectRevert("The sent balance must be greater than 0"); 
        pyramidCards.addBalance{value: 0}();
        vm.stopPrank();
    }

    function testAddBalanceFailWithNonMultipleOfPrice() public {
        uint256 nonMultipleAmount = 0.0015 ether; // An amount that is not a multiple of PRICE
        vm.prank(customer); 
        vm.expectRevert("The sent balance must be multiple of unit price"); 
        pyramidCards.addBalance{value: nonMultipleAmount}();
    }

    function testRedeemChance() public {
        uint256 cardIdToRedeem = 1;
        uint256 NUMS_EXCHANGE_CHANCE = 4; // Assuming this is a constant in your contract

        // Mint cards to the customer, test both consume all of the chosen cards or not
        vm.startPrank(admin);
        pyramidCards.testMintCard(customer, cardIdToRedeem, NUMS_EXCHANGE_CHANCE);
        pyramidCards.testMintCard(customer, cardIdToRedeem + 1, NUMS_EXCHANGE_CHANCE + 1);
        vm.stopPrank();
        
        // Check the balance has increased as expected
        uint256 initialChances = pyramidCards.getUserBalances(customer);
        vm.startPrank(customer);
        pyramidCards.redeemChance(cardIdToRedeem);
        pyramidCards.redeemChance(cardIdToRedeem + 1);

        uint256 newChances = pyramidCards.getUserBalances(customer);
        assertEq(newChances, initialChances + 2, "Chances should increase by 1 after redeeming");

        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection(customer);
        bool firstCardFound = false;

        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == cardIdToRedeem + 1) {
                //the second card should still be in the collection with quantity 1
                assertEq(quantities[i], 1, "Card quantity should decrease by NUMS_EXCHANGE_CHANCE");
            }
            if (ids[i] == cardIdToRedeem) {
                firstCardFound = true;
                break;
            }
        }
        //the first card should not be in the collection
        assertFalse(firstCardFound, "Card shouldn't be in the user's collection"); 
        vm.stopPrank();
    }


    function testRedeemChanceRevertInsufficientCards() public {
        uint256 cardIdToRedeem = 1;
        uint256 NUMS_EXCHANGE_CHANCE = 4; // Assuming this is a constant in your contract
        uint256 insufficientQuantity = NUMS_EXCHANGE_CHANCE - 1; // Not enough cards to redeem

        // Mint fewer cards than needed for redemption
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardIdToRedeem, insufficientQuantity);

        // Expect the transaction to revert
        vm.startPrank(customer);
        vm.expectRevert("Not enough cards to redeem chance");
        pyramidCards.redeemChance(cardIdToRedeem);
        vm.stopPrank();
    }

    function testGetUserCollection() public {
        // Setup: Mint two kinds of cards to the customer
        uint256 cardId1 = 1;
        uint256 quantity1 = 3; 
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardId1, quantity1);

        uint256 cardId2 = 2;
        uint256 quantity2 = 5; 
        vm.prank(admin);
        pyramidCards.testMintCard(customer, cardId2, quantity2);

        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection(customer);

        // Check that the returned data is correct
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == cardId1) {
                assertEq(quantities[i], quantity1, "Quantity of card 1 does not match");
            }
            if (ids[i] == cardId2) {
                assertEq(quantities[i], quantity2, "Quantity of card 2 does not match");
            }
        }

    }
    // function testRandom() public {
    //     vm.startPrank(customer);
    //     pyramidCards.AddBalance{value: 1 ether}();
    //     pyramidCards.drawRandomCard();
    //     (uint256 i, address owner, uint256 amount) = pyramidCards.userCollection(customer, 0);
    //     console.log("id is: ", i);
    //     vm.stopPrank();
    // }

    // User should not be able to draw a pool that does not exist.
    function testRandom() public {
        vm.startPrank(customer);
        pyramidCards.addBalance{value: 1 ether}();
        vm.expectRevert("This pool does not exist");
        pyramidCards.drawRandomCard(collection);
        vm.stopPrank();
    }

    // Pyramid contract should correctly records the random request ID
    function testRandomRequest() public {
        // vm.startPrank(admin);
        // pyramidCards.createCollections(collection, ids, prob);
        // vm.stopPrank();

        // vm.startPrank(customer);
        // pyramidCards.AddBalance{value: 1 ether}();
        // uint256 requestId = pyramidCards.drawRandomCard(collection);
        // assertEq(customer, pyramidCards.s_requestIdToSender(requestId));
        // assertEq(collection, pyramidCards.s_requestIdToCollection(requestId));
        // // (uint256 i, address owner, uint256 amount) = pyramidCards.userCollection(customer, 0);
        // // console.log("id is: ", i);
        // vm.stopPrank();
    }

    // VRFMock should correctly callback and create card for user
    function testRandomCardCreation1() public {
        // create collection of cards
        // vm.startPrank(admin);
        // pyramidCards.createCollections(collection, ids, prob);
        // vm.stopPrank();
        // // now consumer draw
        // vm.startPrank(customer);
        // pyramidCards.AddBalance{value: 1 ether}();
        // uint256 requestId = pyramidCards.drawRandomCard(collection);
        // vm.expectEmit(true, false, false, true);
        // // 2. Emit the expected event
        // emit CardDraw(address(customer), 4);
        // vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // (uint256 i, uint256 amount) = pyramidCards.userCollection(customer, 0);
        // console.log("the newly created id is: ", i);
        // assertEq(amount, 1);
        // vm.stopPrank();
    }

    // VRFMock multiple requests test
    function testRandomCardCreation2() public {
        // create collection of cards
        // vm.startPrank(admin);
        // pyramidCards.createCollections(collection, ids, prob);
        // vm.stopPrank();
        // // now consumer draw
        // vm.startPrank(customer);
        // pyramidCards.AddBalance{value: 1 ether}();
        // uint256 requestId = pyramidCards.drawRandomCard(collection);
        // vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // requestId = pyramidCards.drawRandomCard(collection);
        // vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // (uint256 i, uint256 amount) = pyramidCards.userCollection(customer, 0);
        // // console.log("the newly created id is: ", i);
        // assertEq(amount, 1);
        // vm.stopPrank();
    }

}
