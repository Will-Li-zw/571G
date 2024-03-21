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
    address customer2 = address(1); // fake user 2
    uint256 constant PRICE = 1.5 ether; // test ether

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
        vm.startPrank(customer);
        pyramidCards.AddBalance{value: 1 ether}();
        uint256 balance = pyramidCards.userBalances(customer);
        assertEq(balance, 1 ether);
        vm.stopPrank();
    }

    // function testRandom() public {
    //     vm.startPrank(customer);
    //     pyramidCards.AddBalance{value: 1 ether}();
    //     pyramidCards.drawRandomCard();
    //     (uint256 i, address owner, uint256 amount) = pyramidCards.userCollection(customer, 0);
    //     console.log("id is: ", i);
    //     vm.stopPrank();
    // }


    // ============================================== Admin Function Test ==============================================


    // Test cases for admin functions (for collection tests)
    string collectionTestName = "TestCollection";
    uint256[] validProbabilities = [20, 30, 50];
    uint256[] invalidProbabilities = [30, 40, 60];

    // Test cases for admin functions (for award tests)
    string awardTestName = "TestAward";
    string awardTestName2 = "TestAward2";
    uint256[] validRequiredIds = [1, 2, 3];
    uint256[] invalidRequiredIds = [1, 2, 3, 4];
    uint256[] requiredNums = [1, 1, 2];
    uint256[] invalidRequiredNums = [1, 1, 2, 3];


    /** Test 1: Admin cannot CREATE card collections with invalid inputs, 
     *          and other users cannot create card collections
     */
    function testCreateCollections() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.stopPrank();

        // If the sum of probabilities does not equal to 100% (expect to have error)
        vm.startPrank(pyramidCards.admin());
        vm.expectRevert("Invalid probability inputs, the sum is not 100%");
        pyramidCards.createCollections(collectionTestName, invalidProbabilities);

        // If collection name already exist (expect to have error)
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.expectRevert("Collection name is already active");
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.stopPrank();
    }


    /** Test 2: Admin cannot DELETE card collections with invalid inputs,
     *          and other users cannot delete card collections
     */ 
    function testDeleteCollections() public {
        // If collection name does not exist (expect to have error)
        vm.startPrank(pyramidCards.admin());
        vm.expectRevert("Collection name is not active");
        pyramidCards.deleteCollections(collectionTestName);

        // If user is not admin (expect to have error)
        pyramidCards.createCollections(collectionTestName, validProbabilities);     // Admin creates the collection first
        vm.stopPrank();

        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.deleteCollections(collectionTestName);                         // Other users try to delete the existing collection
        vm.stopPrank();
    }


    /** Test 3: Users cannot GET the collections information with invalid inputs
     */ 
    function testGetCollections() public {
        // If collection name does not exist (expect to have error)
        vm.startPrank(customer);

        vm.expectRevert("Collection name is not active");
        uint256[] memory testCollections = pyramidCards.getCollections(collectionTestName);

        vm.expectRevert("Collection name is not active");
        uint256[] memory testCollectionsProbabilities = pyramidCards.getCollectionProbability(collectionTestName);

        vm.stopPrank();
    }


    /** Test 4: Only admin can create and delete the collections with valid inputs,
     *          and all users can get the collections information with valid inputs
     */
    function testSuccessAddDeleteGetCollections() public {
        // Admin creates new card collection
        vm.startPrank(pyramidCards.admin());
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        assertEq(pyramidCards.collectionActive(collectionTestName), true);
        vm.stopPrank();

        // User gets collection information
        vm.startPrank(customer);
        uint256[] memory testCollections = pyramidCards.getCollections(collectionTestName);
        uint256[] memory testCollectionsProbabilities = pyramidCards.getCollectionProbability(collectionTestName);

        assertEq(testCollections.length, validProbabilities.length);                // Need to have the same quantity of ids as what we have set
        assertEq(testCollectionsProbabilities.length, validProbabilities.length);
        for (uint256 i = 0; i < testCollections.length; i++) {                      // Check the returned probabilities
            assertEq(testCollectionsProbabilities[i], validProbabilities[i]);
        }
        vm.stopPrank();

        // Admin deletes the card collection
        vm.startPrank(pyramidCards.admin());
        pyramidCards.deleteCollections(collectionTestName);
        assertEq(pyramidCards.collectionActive(collectionTestName), false);
        vm.stopPrank();
    }


    /** Test 5: Admin cannot SET collection awards with invalid inputs, 
     *          and other users cannot set collection awards
     */
    function testSetCollectionAward() public {
        // Create card collections, let idcounter add up to 3
        vm.startPrank(pyramidCards.admin());
        pyramidCards.createCollections(collectionTestName, validProbabilities);

        // If the input size of required IDs and required quantities do not match
        vm.expectRevert("The size of input required IDs and required quantities do not match");
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, invalidRequiredNums);

        // If any card ID input does not exist (expect to have error)
        vm.expectRevert("ID set is invalid");
        pyramidCards.setCollectionAward(awardTestName, invalidRequiredIds, invalidRequiredNums);

        // If award name already exist (expect to have error)
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, requiredNums);
        vm.expectRevert("Award name is already active");
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, requiredNums);
        vm.stopPrank();

        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, requiredNums);
        vm.stopPrank();
    }


    /** Test 6: Admin cannot DELETE collection awards with invalid inputs,
     *          and other users cannot delete collection awards
     */ 
    function testDeleteCollectionAward() public {
        // Create card collections, let idcounter add up to 3
        vm.startPrank(pyramidCards.admin());
        pyramidCards.createCollections(collectionTestName, validProbabilities);

        // If award name does not exist (expect to have error)
        vm.startPrank(pyramidCards.admin());
        vm.expectRevert("Award name is not active");
        pyramidCards.deleteCollectionAward(awardTestName);

        // If user is not admin (expect to have error)
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, requiredNums);  // Admin creates the collection award first
        vm.stopPrank();

        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.deleteCollectionAward(awardTestName);                         // Other users try to delete the existing collection award
        vm.stopPrank();
    }


    /** Test 7: Users cannot GET the collection award information with invalid inputs
     */ 
    function testGetCollectionAward() public {
        // If award name does not exist (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("Award name is not active");
        (uint256[] memory testAwardRequiredIds, uint256[] memory testAwardRequiredQuantities) = pyramidCards.getCollectionAward(awardTestName);
        vm.stopPrank();
    }


    /** Test 8: Only admin can set and delete the collection awards with valid inputs,
     *          and all users can get the awards information with valid inputs
     */
    function testSuccessSetDeleteGetCollectionAward() public {
        // Admin creates new award
        vm.startPrank(pyramidCards.admin());
        pyramidCards.createCollections(collectionTestName, validProbabilities);             // Create card collections, let idcounter add up to 3
        pyramidCards.setCollectionAward(awardTestName, validRequiredIds, requiredNums);
        assertEq(pyramidCards.awardActive(awardTestName), true);
        vm.stopPrank();

        // User gets award information
        vm.startPrank(customer);
        (uint256[] memory testAwardRequiredIds, uint256[] memory testAwardRequiredQuantities) = pyramidCards.getCollectionAward(awardTestName);

        assertEq(testAwardRequiredIds.length, validRequiredIds.length);              // Check the size of the array
        assertEq(testAwardRequiredQuantities.length, requiredNums.length);
        for (uint256 i = 0; i < testAwardRequiredIds.length; i++) {             // Check the returned probabilities
            assertEq(testAwardRequiredIds[i], validRequiredIds[i]);
            assertEq(testAwardRequiredQuantities[i], requiredNums[i]);
        }
        vm.stopPrank();

        // Admin deletes the award
        vm.startPrank(pyramidCards.admin());
        pyramidCards.deleteCollectionAward(awardTestName);
        assertEq(pyramidCards.awardActive(awardTestName), false);
        vm.stopPrank();
    }


    /** Test 9: Only admin can transfer admin rights to a new admin address
     */
    function testChangeAdmin() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.changeAdmin(customer);
        vm.stopPrank();

        // If user is admin
        vm.startPrank(pyramidCards.admin());
        pyramidCards.changeAdmin(customer);
        assertEq(pyramidCards.admin(), customer);
        vm.stopPrank();
    }


    /** Test 10: Only admin can monitor user's card information (collection name, ID, and quantity)
     */
    function testGetUserCardCollections() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.getUserCardCollections(customer);
        vm.stopPrank();

        // If user is admin (*** MESSAGE FOR TEAM: TBD, THIS TEST CASE REQIURES USERS TO DRAW CERTAIN AMOUNT OF CARDS ***
    }

}
