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

    uint96 constant BASE_FEE = 25000000000000000000; // 25e^18
    uint96 constant GAS_PRICE_LINK = 1e9;  

    uint96 constant FUND_AMOUNT = 10000000000000000000;  // 1e^18
    uint32 constant callBackGasLimit = 500000;
    bytes32 constant gasLane = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    function setUp() public {
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        uint64 sub_id = vrfCoordinatorMock.createSubscription();
        // console.log(transactionReceipt);
        vrfCoordinatorMock.fundSubscription(sub_id, FUND_AMOUNT);
        

        
        pyramidCards = new PyramidCards(address(vrfCoordinatorMock), gasLane,   sub_id, callBackGasLimit);

        vrfCoordinatorMock.addConsumer(sub_id, address(pyramidCards));

        (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) = vrfCoordinatorMock.getSubscription(sub_id);
        console.log("Balance is: ", balance);
        console.log("owner is: ", owner);
        console.log("consumer is: ", consumers[0]);

        vm.deal(customer, 10 ether);    // original balance of user
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
    // function testRandom() public {
    //     vm.startPrank(customer);
    //     pyramidCards.AddBalance{value: 1 ether}();
    //     pyramidCards.drawRandomCard();
    //     (uint256 i, address owner, uint256 amount) = pyramidCards.userCollection(customer, 0);
    //     console.log("id is: ", i);
    //     vm.stopPrank();
    // }

}
