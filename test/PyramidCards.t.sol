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
    uint96 constant FUND_AMOUNT = 1e18;  // 1e^18
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

    function setUp() public {
        vm.startPrank(admin);
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        uint64 sub_id = vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(sub_id, FUND_AMOUNT);
        
        pyramidCards = new PyramidCards(address(vrfCoordinatorMock), gasLane, sub_id, callBackGasLimit);

        vrfCoordinatorMock.addConsumer(sub_id, address(pyramidCards));

        (uint96 balance, , address owner, address[] memory consumers) = vrfCoordinatorMock.getSubscription(sub_id);
        console.log("Balance is: ", balance);
        console.log("owner is: ", owner);
        console.log("Address of this contract is: ", address(this));
        console.log("Admin of Pyramid is: ", pyramidCards.admin());
        console.log("consumer is: ", consumers[0]);

        vm.deal(customer, 10 ether);    // original balance of user
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

        vm.startPrank(customer);
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        bool card1Found;
        bool card2Found;
        for (uint i = 0; i < ids.length; i++) {
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
        pyramidCards.redeemChance(cardIdToRedeem);
        pyramidCards.redeemChance(cardIdToRedeem + 1);
        uint256 newChances = pyramidCards.getUserBalances(customer);
        assertEq(newChances, initialChances + 2, "Chances should increase by 2 after redeeming");   // because we redeem twice

        (ids, quantities) = pyramidCards.getUserCollection();
        bool firstCardFound = false;
        bool secondCardFound = false;
        for (uint i = 0; i < ids.length; i++) {
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
        for (uint i = 0; i < ids.length; i++) {
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
     */
    function testCreateCollectionsInvalid() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.stopPrank();

        // If the sum of probabilities does not equal to 100% (expect to have error)
        vm.startPrank(admin);
        vm.expectRevert("Invalid probability inputs, the sum is not 100%");
        pyramidCards.createCollections(collectionTestName, invalidProbabilities);

        // If collection name already exist (expect to have error)
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.expectRevert("Collection name is already active");
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.stopPrank();
    }


    /** 
     * Test 2: Admin cannot DELETE card collections with invalid inputs,
     *          and other users cannot delete card collections
     */ 
    function testDeleteCollectionsInvalid() public {
        // If collection name does not exist (expect to have error)
        vm.startPrank(admin);
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


    /** 
     * Test 3: Users cannot GET the collections information with invalid inputs
     */ 
    function testGetCollectionInformation() public {
        // If collection name does not exist (expect to have error)
        vm.startPrank(customer);

        vm.expectRevert("Collection name is not active");
        pyramidCards.getCollections(collectionTestName);

        vm.expectRevert("Collection name is not active");
        pyramidCards.getCollectionProbability(collectionTestName);

        vm.stopPrank();
    }


    /** 
     * Test 4: Only admin can create and delete the collections with valid inputs,
     *          and all users can get the collections information with valid inputs
     */
    function testSuccessAddDeleteGetCollections() public {
        // Admin creates new card collection
        vm.startPrank(admin);
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
            assertEq(testCollections[i], i + 1);    // id should be from 1 to 3
        }
        vm.stopPrank();

        // Admin deletes the card collection
        vm.startPrank(admin);
        pyramidCards.deleteCollections(collectionTestName);
        assertEq(pyramidCards.collectionActive(collectionTestName), false);
        vm.stopPrank();
    }


    /** 
     * Test 5: Admin cannot SET collection awards with invalid inputs, 
     *          and other users cannot set collection awards
     */
    function testSetCollectionAwardInvalid() public {
        // Create card collections, let idcounter add up to 3
        vm.startPrank(admin);
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


    /** 
     * Test 6: Admin cannot DELETE collection awards with invalid inputs,
     *          and other users cannot delete collection awards
     */ 
    function testDeleteCollectionAwardInvalid() public {
        // Create card collections, let idcounter add up to 3
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        // If award name does not exist (expect to have error)
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


    /** 
     * Test 7: Users cannot GET the collection award information with invalid inputs
     */ 
    function testGetCollectionAwardInvalid() public {
        // If award name does not exist (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("Award name is not active");
        pyramidCards.getCollectionAward(awardTestName);
        vm.stopPrank();
    }


    /** 
     * Test 8: Only admin can set and delete the collection awards with valid inputs,
     *          and all users can get the awards information with valid inputs
     */
    function testSuccessSetDeleteGetCollectionAward() public {
        // Admin creates new award
        vm.startPrank(admin);
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
        vm.startPrank(admin);
        pyramidCards.deleteCollectionAward(awardTestName);
        assertEq(pyramidCards.awardActive(awardTestName), false);
        vm.stopPrank();
    }


    /** 
     * Test 9: Only admin can transfer admin rights to a new admin address
     */
    function testChangeAdmin() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.changeAdmin(customer);
        vm.stopPrank();

        // If user is admin
        vm.startPrank(admin);
        pyramidCards.changeAdmin(customer);
        assertEq(pyramidCards.admin(), customer);
        vm.stopPrank();
    }


    /** 
     * Test 10: Only admin can monitor user's card information (collection name, ID, and quantity)
     */
    function testGetUserCardCollections() public {
        // If user is not admin (expect to have error)
        vm.startPrank(customer);
        vm.expectRevert("You are not the admin, access denied");
        pyramidCards.getUserCardCollections(customer);
        vm.stopPrank();

        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        vm.stopPrank();

        // Draw a card for test
        vm.startPrank(customer);
        pyramidCards.addBalance{value: PRICE}();
        uint256 requestId = pyramidCards.drawRandomCard(collectionTestName);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));    // NOTE: the random seed is set by requestId, which is always 1 in this case
                                                                                    // So the returned random word is always the same
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        assertEq(ids.length, 1, "Only one card should be drawn");
        assertEq(ids[0], 2, "Drawn card will have id 2 in this specific case");
        assertEq(quantities[0], 1, "We only draw one card, but non-1 value received");
        vm.stopPrank();

        // use admin to check the user collection
        vm.startPrank(admin);
        (string[] memory collectionName, uint256[] memory id, uint256[] memory cardQuantities) = pyramidCards.getUserCardCollections(customer);
        assertEq(collectionName.length, 1, "Only one card should be in user's collection");
        assertEq(id.length, 1, "Only one card should be in user's collection");
        assertEq(cardQuantities.length, 1, "Only one card should be in user's collection");
        assertEq(collectionName[0], collectionTestName, "collection name mismatch");
        assertEq(id[0], 2, "Card id mismatch");
        assertEq(cardQuantities[0], 1, "Only one card of id 2 should be drawn");

    }

    /** 
     * Test 11: Admin can withdraw the money in the contract
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
        assertEq(initialAdminBalance+PRICE, afterAdminBalance, "The money withdrawn is not correct");
    }
    

    // ============================================== Draw Card VRF Function Test ==============================================
    /** 
     * Test 1: User should not be able to draw if the pool does not exist
     */
    function testRandom() public {
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
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, validProbabilities);
        assertEq(pyramidCards.collectionActive(collectionTestName), true);
        vm.stopPrank();

        vm.startPrank(customer);
        pyramidCards.addBalance{value: PRICE}();
        uint256 requestId = pyramidCards.drawRandomCard(collectionTestName);
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
        pyramidCards.createCollections(collectionTestName, validProbabilities);        
        vm.stopPrank();

        // user now draw
        vm.startPrank(customer);
        pyramidCards.addBalance{value: PRICE}();
        uint256 requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        // 2. Emit the expected event
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));    // NOTE: the random seed is set by requestId, which is always 1 in this case
                                                                                    // So the returned random word is always the same
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        assertEq(ids.length, 1, "Only one card should be drawn");
        assertEq(ids[0], 2, "Drawn card will have id 2 in this specific case");
        assertEq(quantities[0], 1, "We only draw one card, but non-1 value received");
        vm.stopPrank();
    }

    /** 
     * Test 4: user draw "randomly" 5 times and check the result, mock random test
     */
    function testRandomDraw5times() public {
        vm.startPrank(admin);
        pyramidCards.createCollections(collectionTestName, validProbabilities);        
        vm.stopPrank();

        // user now draw
        vm.startPrank(customer);
        pyramidCards.addBalance{value: 5*PRICE}();

        // 1st Draw
        uint256 requestId;
        requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));    // NOTE: the random seed is set by requestId, which is always 1 in this case
                                                                                    // So the returned random word is always the same
        // 2nd Draw
        requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 3rd Draw
        requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 4th Draw
        requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 2);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 5th Draw
        requestId = pyramidCards.drawRandomCard(collectionTestName);
        vm.expectEmit(true, false, false, true);
        emit CardDraw(address(customer), 3);
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(pyramidCards));

        // 6th Draw expect fail because out of balance:
        vm.expectRevert("Drawchance not enough, cannot draw");
        requestId = pyramidCards.drawRandomCard(collectionTestName);

        
        // Final check: 
        // id2 card: 4 times
        // id3 card: 1 time
        (uint256[] memory ids, uint256[] memory quantities) = pyramidCards.getUserCollection();
        bool id2Found = false;
        bool id3Found = false;
        for (uint i = 0; i < ids.length; i++){
            if (ids[i] == 2){
                assertEq(quantities[i], 4, "Wrong number of id2 card found");
                id2Found = true;
            }
            else if (ids[i] == 3){
                assertEq(quantities[i], 1, "Wrong number of id3 card found");
                id3Found = true;
            }
            else {
                revert("wrong id detected, should not have been drawn");
            }
        }
        assertEq(id2Found, true, "No id2 card found.");
        assertEq(id3Found, true, "No id3 card found.");
        vm.stopPrank();
    } 

}
