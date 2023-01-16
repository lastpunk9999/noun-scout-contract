// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounScoutTest.sol";

contract NounScoutTest is BaseNounScoutTest {
    event RequestAdded(
        uint256 requestId,
        address indexed requester,
        NounScout.Traits trait,
        uint16 traitId,
        uint16 recipientId,
        uint16 indexed nounId,
        uint16 pledgeGroupId,
        bytes32 indexed traitsHash,
        uint256 amount,
        string message
    );
    event RequestRemoved(
        uint256 requestId,
        address indexed requester,
        NounScout.Traits trait,
        uint16 traitId,
        uint16 indexed nounId,
        uint16 pledgeGroupId,
        uint16 recipientId,
        bytes32 indexed traitsHash,
        uint256 amount
    );

    function setUp() public override {
        BaseNounScoutTest.setUp();
    }

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounScout.nouns()));
        assertEq(nounScout.headCount(), 99);
        assertEq(nounScout.glassesCount(), 98);
        assertEq(nounScout.accessoryCount(), 97);
        assertEq(nounScout.bodyCount(), 96);
        assertEq(nounScout.backgroundCount(), 95);
    }

    function test_PAUSE_UNPAUSE() public {}

    function test_SETMINVALUE() public {}

    function test_SETReimbursementBPS() public {}

    function test_ADDRECIPIENT() public {}

    function test_TOGGLEDONNEACTIVE() public {}

    function test_ADD_happyCase() public {
        vm.expectEmit(true, true, true, true);
        // expect the event to have the an empty message and the correct pledge value
        emit RequestAdded(
            0,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            0,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue,
            ""
        );

        // USER 1
        // - adds a request
        vm.prank(user1);

        uint256 requestIdUser1 = nounScout.add{value: minValue}(
            HEAD,
            9,
            ANY_ID,
            1
        );

        NounScout.Request memory request1 = nounScout.rawRequestById(
            address(user1),
            requestIdUser1
        );

        assertEq(uint8(request1.trait), uint8(HEAD));
        assertEq(request1.traitId, 9);
        assertEq(request1.recipientId, 1);
        assertEq(request1.nounId, ANY_ID);
        assertEq(request1.amount, minValue, "request1.amount, minValue");

        NounScout.Request[] memory requestsUser1 = nounScout
            .rawRequestsByAddress(address(user1));

        assertEq(requestsUser1.length, 1);

        (uint256 amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, ANY_ID),
            1
        );

        assertEq(amount, minValue, "amount, minValue");

        // USER 1
        // - adds additional request for same traits and recipient
        vm.prank(user1);
        assertEq(
            nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1),
            requestIdUser1 + 1
        );
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));

        assertEq(requestsUser1.length, 2);

        amount = nounScoutViewUtils.amountForRecipientByTrait(
            HEAD,
            9,
            ANY_ID,
            1
        );

        assertEq(amount, minValue * 2, "amount, minValue * 2");

        // USER 2
        // - adds additional request for different HEAD, specific noun Id, different recipient
        vm.expectEmit(true, true, true, true);

        // expect the event to have the an empty message and the correct pledge value
        emit RequestAdded(
            0,
            address(user2),
            HEAD,
            8,
            2,
            99,
            0,
            nounScout.traitHash(HEAD, 8, 99),
            minValue,
            ""
        );

        vm.prank(user2);
        uint256 requestIdUser2 = nounScout.add{value: minValue}(HEAD, 8, 99, 2);

        NounScout.Request memory request2 = nounScout.rawRequestById(
            address(user2),
            requestIdUser2
        );

        assertEq(uint8(request2.trait), uint8(HEAD));
        assertEq(request2.traitId, 8);
        assertEq(request2.recipientId, 2);
        assertEq(request2.nounId, 99);
        assertEq(request2.amount, minValue, "request2.amount");

        // Should include user1 and user2 requests
        uint256[][] memory pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            99
        );

        // USER1 ANY_Id requested 2 times
        assertEq(
            pledgesByTraitId[9][1],
            minValue * 2,
            "pledgesByTraitId[9][1]"
        );
        // USER2 Noun Id 99 requested 1 times
        assertEq(pledgesByTraitId[8][2], minValue, "pledgesByTraitId[8][2]");

        // USER 3
        // - adds additional request for same HEAD, next Noun Id, same recipient
        vm.prank(user3);
        nounScout.add{value: minValue}(HEAD, 9, 101, 1);

        // Should include user1 and user2 requests
        (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][] memory nextAuctionPledges,

        ) = nounScoutViewUtils.pledgesForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionId, 101);
        assertEq(nextNonAuctionId, 100);
        // USER1 ANY_Id requested 2 times + USER3 Noun Id 101 requested 1 times
        assertEq(
            nextAuctionPledges[9][1],
            minValue * 3,
            "nextAuctionPledges[9][1]"
        );
    }

    function test_ADD_happyCase_storesPledgeGroupIdIncrementsAfterSettle()
        public
    {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);

        vm.expectEmit(true, true, true, true);
        emit RequestAdded(
            0,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            0,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue,
            ""
        );

        // USER 1
        // - adds a request
        vm.prank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        NounScout.Request memory request1 = nounScout.rawRequestById(
            address(user1),
            requestId1
        );

        assertEq(request1.pledgeGroupId, 0);

        // - removes first request
        vm.prank(user1);
        nounScout.remove(requestId1);

        vm.expectEmit(true, true, true, true);
        emit RequestAdded(
            1,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            0,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue,
            ""
        );

        // - adds another request
        vm.prank(user1);

        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        NounScout.Request memory request2 = nounScout.rawRequestById(
            address(user1),
            requestId2
        );

        // pledgeGroupId has not incremeneted
        assertEq(request2.pledgeGroupId, request1.pledgeGroupId);

        // set seed for previous auction
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(102);

        // User2 settles
        vm.prank(user2);
        nounScout.settle(HEAD, 101, allRecipientIds);

        // User 1 adds another request, pledgeGroupId should increase
        vm.expectEmit(true, true, true, true);
        emit RequestAdded(
            2,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            1,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue,
            ""
        );

        // - adds another request
        vm.prank(user1);

        uint256 requestId3 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        NounScout.Request memory request3 = nounScout.rawRequestById(
            address(user1),
            requestId3
        );

        // pledgeGroupId has incremeneted
        assertEq(request3.pledgeGroupId, request2.pledgeGroupId + 1);
    }

    function test_ADD_failsWhenPaused() public {
        nounScout.pause();
        vm.expectRevert(bytes("Pausable: paused"));
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADD_failsBelowMinValue() public {
        vm.prank(user1);
        vm.expectRevert(NounScout.ValueTooLow.selector);
        nounScout.add{value: minValue - 1}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADD_failsInactiveRecipient() public {
        nounScout.setRecipientActive(1, false);
        vm.prank(user1);
        vm.expectRevert(NounScout.InactiveRecipient.selector);
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADDWITHMESSAGE_happyCase() public {
        uint256 pledge = 9 ether;
        vm.expectEmit(true, true, true, true);
        // expect the event to have the "hello" message and the correct pledge value
        emit RequestAdded(
            0,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            0,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            pledge,
            "hello"
        );

        // expect the minValue to pay for the message to be transferred to the recipient
        vm.expectCall(address(recipient1), messageValue, "");

        vm.prank(user1);

        uint256 requestIdUser1 = nounScout.addWithMessage{
            value: pledge + messageValue
        }(HEAD, 9, ANY_ID, 1, "hello");

        NounScout.Request memory request1 = nounScout.rawRequestById(
            address(user1),
            requestIdUser1
        );

        assertEq(uint8(request1.trait), uint8(HEAD));
        assertEq(request1.traitId, 9);
        assertEq(request1.recipientId, 1);
        assertEq(request1.nounId, ANY_ID);
        assertEq(request1.amount, pledge);

        NounScout.Request[] memory requestsUser1 = nounScout
            .rawRequestsByAddress(address(user1));

        assertEq(requestsUser1.length, 1);

        (uint256 amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, ANY_ID),
            1
        );

        assertEq(amount, pledge);
    }

    function test_ADDWITHMESSAGE_failsWhenValueTooLow() public {
        vm.expectRevert(NounScout.ValueTooLow.selector);
        vm.prank(user1);

        nounScout.addWithMessage{value: minValue}(HEAD, 9, ANY_ID, 1, "hello");
    }

    function test_REMOVE_after_addWithMessage_happyCaseFIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        // addWithMessage()
        uint256 requestId1 = nounScout.addWithMessage{
            value: minValue + messageValue
        }(HEAD, 9, ANY_ID, 1, "hello");

        // add()
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        uint256[][] memory pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            ANY_ID
        );
        NounScout.Request[] memory requestsUser1 = nounScout
            .rawRequestsByAddress(address(user1));

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(pledgesByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId1,
            address(user1),
            HEAD,
            9,
            ANY_ID,
            0,
            1,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue
        );

        vm.expectCall(address(user1), minValue, "");

        nounScout.remove(requestId1);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, minValue);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], minValue);

        // Remove second request
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            ANY_ID,
            0,
            1,
            nounScout.traitHash(HEAD, 9, ANY_ID),
            minValue
        );
        vm.expectCall(address(user1), minValue, "");
        nounScout.remove(requestId2);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], 0);
    }

    function test_REMOVE_happyCaseFIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256[][] memory pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            ANY_ID
        );
        NounScout.Request[] memory requestsUser1 = nounScout
            .rawRequestsByAddress(address(user1));

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(pledgesByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounScout.remove(requestId1);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, minValue);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounScout.remove(requestId2);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], 0);
    }

    function test_REMOVE_happyCaseLIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT + 1);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256[][] memory pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            ANY_ID
        );
        NounScout.Request[] memory requestsUser1 = nounScout
            .rawRequestsByAddress(address(user1));

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(pledgesByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounScout.remove(requestId2);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);
        assertEq(requestsUser1[1].amount, 0);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounScout.remove(requestId1);
        requestsUser1 = nounScout.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, ANY_ID);
        assertEq(pledgesByTraitId[9][1], 0);
    }

    function test_REMOVE_revertsAuctionEndingSoon() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounScout.AuctionEndingSoon.selector);
        nounScout.remove(requestId1);
    }

    function test_REMOVE_revertsAuctionEnded() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounScout.AuctionEndingSoon.selector);
        nounScout.remove(requestId1);
    }

    function test_REMOVE_revertsAlreadyRemoved() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        nounScout.remove(requestId1);

        vm.expectRevert(NounScout.AlreadyRemoved.selector);
        nounScout.remove(requestId1);
    }

    function test_REMOVE_revertsNotRequester() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.prank(user2);
        // Index out of bounds Error
        vm.expectRevert(stdError.indexOOBError);
        nounScout.remove(requestId1);
    }

    function test_REMOVE_revertsCurrentMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 103, 1);
        uint256 requestId3 = nounScout.add{value: minValue}(HEAD, 9, 99, 1);
        uint256 requestId4 = nounScout.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounScout.add{value: minValue}(HEAD, 8, 103, 1);
        uint256 requestId6 = nounScout.add{value: minValue}(HEAD, 8, 99, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 103);
        mockAuctionHouse.setNounId(103);
        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 103)
        );
        nounScout.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 103)
        );
        nounScout.remove(requestId2);

        // Successful
        nounScout.remove(requestId3);
        nounScout.remove(requestId4);
        nounScout.remove(requestId5);
        nounScout.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 99, 1);
        uint256 requestId3 = nounScout.add{value: minValue}(HEAD, 9, 100, 1);
        uint256 requestId4 = nounScout.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounScout.add{value: minValue}(HEAD, 8, 99, 1);
        uint256 requestId6 = nounScout.add{value: minValue}(HEAD, 8, 100, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Previous auctioned Noun has seed skipping over non-auctioned Noun
        mockNouns.setSeed(seed, 99);
        mockAuctionHouse.setNounId(101);
        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 99)
        );
        nounScout.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 99)
        );
        nounScout.remove(requestId2);

        // Successful
        nounScout.remove(requestId3);
        nounScout.remove(requestId4);
        nounScout.remove(requestId5);
        nounScout.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousDoubleMintAuctionedMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 101, 1);
        uint256 requestId3 = nounScout.add{value: minValue}(HEAD, 9, 102, 1);
        uint256 requestId4 = nounScout.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounScout.add{value: minValue}(HEAD, 8, 102, 1);
        uint256 requestId6 = nounScout.add{value: minValue}(HEAD, 8, 101, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Previous auctioned Noun has seed
        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(102);
        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 101)
        );
        nounScout.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 101)
        );
        nounScout.remove(requestId2);

        // Successful
        nounScout.remove(requestId3);
        nounScout.remove(requestId4);
        nounScout.remove(requestId5);
        nounScout.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousNonAuctionedMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, 100, 1);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId3 = nounScout.add{value: minValue}(HEAD, 9, 103, 1);
        uint256 requestId4 = nounScout.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounScout.add{value: minValue}(HEAD, 8, 100, 1);
        uint256 requestId6 = nounScout.add{value: minValue}(HEAD, 8, 101, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Previous non-auctioned Noun has seed
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);
        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 100)
        );
        nounScout.remove(requestId1);

        // Successful
        nounScout.remove(requestId2); // ANY_ID requets do no match non-auctioned Nouns
        nounScout.remove(requestId3);
        nounScout.remove(requestId4);
        nounScout.remove(requestId5);
        nounScout.remove(requestId6);
    }

    function test_REMOVE_revertsAlreadySent() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint256 requestId1 = nounScout.add{value: minValue}(HEAD, 9, 100, 0);
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounScout.settle(HEAD, 100, allRecipientIds);

        vm.startPrank(user1);
        vm.expectRevert(NounScout.PledgeSent.selector);

        nounScout.remove(requestId1);

        mockAuctionHouse.setNounId(103);

        vm.expectRevert(NounScout.PledgeSent.selector);

        nounScout.remove(requestId1);
    }

    function test_REMOVE_removeAfterMatchAndInactiveRecipient() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounScout.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        (uint256 recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (uint256 recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(recipient0Amount, minValue);
        assertEq(recipient1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set recipient1 to inactive
        nounScout.setRecipientActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounScout.settle(HEAD, 100, allRecipientIds);

        (recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        // recipient0 matched, funds removed
        assertEq(recipient0Amount, 0);
        // recipient1 did not match, funds remain
        assertEq(recipient1Amount, minValue);

        // requestId2 can be removed
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            100,
            0,
            1,
            nounScout.traitHash(HEAD, 9, 100),
            minValue
        );

        uint256 amount = nounScout.remove(requestId2);
        assertEq(amount, minValue);

        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );
        assertEq(recipient1Amount, 0);
    }

    function test_REMOVE_revertsAfterInactiveRecipientBecomesActiveAndMatches()
        public
    {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounScout.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        (uint256 recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (uint256 recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(recipient0Amount, minValue);
        assertEq(recipient1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set recipient1 to inactive
        nounScout.setRecipientActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounScout.settle(HEAD, 100, allRecipientIds);

        (recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        // recipient0 matched, funds removed
        assertEq(recipient0Amount, 0);
        // recipient1 did not match, funds remain
        assertEq(recipient1Amount, minValue);

        // set recipient1 to active
        nounScout.setRecipientActive(1, true);

        vm.prank(user2);
        vm.expectCall(address(recipient1), minValue - minReimbursement, "");
        nounScout.settle(HEAD, 100, allRecipientIds);

        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );
        assertEq(recipient1Amount, 0);

        // requestId2 cannot be removed
        vm.startPrank(user1);
        vm.expectRevert(NounScout.PledgeSent.selector);

        nounScout.remove(requestId2);
    }

    function test_REMOVE_removeAfterInactiveRecipientBecomesActive() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounScout.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounScout.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        (uint256 recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (uint256 recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(recipient0Amount, minValue);
        assertEq(recipient1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set recipient1 to inactive
        nounScout.setRecipientActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounScout.settle(HEAD, 100, allRecipientIds);

        (recipient0Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            0
        );
        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );

        // recipient0 matched, funds removed
        assertEq(recipient0Amount, 0);
        // recipient1 did not match, funds remain
        assertEq(recipient1Amount, minValue);

        // set recipient1 to active
        nounScout.setRecipientActive(1, true);

        vm.startPrank(user1);

        // recipient1, now active, matches Noun 100, cannot be removed
        vm.expectRevert(
            abi.encodeWithSelector(NounScout.MatchFound.selector, 100)
        );
        nounScout.remove(requestId2);
        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );
        // recipient1 funds removed
        assertEq(recipient1Amount, minValue);

        // Current/prev Noun no longer matches
        mockAuctionHouse.setNounId(199);

        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            100,
            0,
            1,
            nounScout.traitHash(HEAD, 9, 100),
            minValue
        );
        vm.expectCall(address(user1), minValue, "");
        uint256 amount = nounScout.remove(requestId2);
        assertEq(amount, minValue);
        (recipient1Amount, ) = nounScout.pledgeGroups(
            nounScout.traitHash(HEAD, 9, 100),
            1
        );
        // recipient1 funds removed
        assertEq(recipient1Amount, 0);
    }

    function test_REMOVE_removeAfterPause() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId = nounScout.add{value: minValue}(HEAD, 9, 100, 1);

        vm.expectRevert(NounScout.AuctionEndingSoon.selector);
        nounScout.remove(requestId);
        vm.stopPrank();

        nounScout.pause();
        NounScout.RequestWithStatus[] memory requests = nounScout
            .requestsByAddress(user1);
        assertEq(requests.length, 1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        nounScout.unpause();
        requests = nounScout.requestsByAddress(user1);
        assertEq(requests.length, 1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.AUCTION_ENDING_SOON)
        );

        nounScout.pause();
        vm.prank(user1);
        nounScout.remove(requestId);
        requests = nounScout.requestsByAddress(user1);
        assertEq(requests.length, 0);
    }

    // User 1 pledges funds to a recipient for a nounId and trait
    // Noun matches and funds are donated
    // User 2 pledges the same or more funds to the same recipient, nounId, and trait
    // User 1 should not be able to withdraw the funds User 2 pledged
    function test_REMOVE_cannotRemoveOtherUsersFundsAfterSettle() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint256 user1RequestId = nounScout.add{value: minValue}(HEAD, 0, 0, 0);

        mockAuctionHouse.setNounId(103);

        // Settle as User3
        vm.startPrank(user3);
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user3), minReimbursement, "");
        nounScout.settle(HEAD, 102, allRecipientIds);
        vm.stopPrank();

        // Allow Requests for Head 0 to be removed
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            10,
            10,
            10
        );
        mockNouns.setSeed(seed, 103);
        mockNouns.setSeed(seed, 104);
        mockAuctionHouse.setNounId(104);

        // User2 pledges funds to the same recipient, nounId, trait as User 1
        vm.prank(user2);
        nounScout.add{value: minValue}(HEAD, 0, 0, 0);

        NounScout.RequestWithStatus[] memory requestsUser2 = nounScout
            .requestsByAddress(user2);
        assertEq(requestsUser2.length, 1);
        assertEq(
            uint8(requestsUser2[0].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE),
            "user2 request status"
        );

        // User 1 should have no active requests
        NounScout.RequestWithStatus[] memory requestsUser1 = nounScout
            .requestsByAddress(user1);
        assertEq(requestsUser1.length, 1, "user1 requests length");
        assertEq(
            uint8(requestsUser1[0].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT),
            "user1 request status"
        );
        // User 1 should not be able to remove funds
        vm.startPrank(user1);
        vm.expectRevert(NounScout.PledgeSent.selector);
        nounScout.remove(user1RequestId);
    }

    function test_REQUESTSBYACTIVEADDRESS_happyCase() public {
        vm.startPrank(user1);
        // 1 Should match
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounScout.add{value: minValue}(HEAD, 9, 102, 1);
        // 3-4 Should not match
        nounScout.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounScout.add{value: minValue}(HEAD, 8, 102, 1);

        // 5 Should match, but recipient2 will be set inactive
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 2);

        vm.stopPrank();

        // Case 1
        // Auction ends in the future
        // Noun seed/auctioned Noun do not match
        uint256 timestamp = 1_000_000;
        vm.warp(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);

        NounScout.RequestWithStatus[] memory requests = nounScout
            .requestsByAddress(user1);

        assertEq(requests.length, 5);

        // Sanity check first request
        assertEq(uint8(requests[0].trait), uint8(HEAD));
        assertEq(requests[0].id, 0);
        assertEq(requests[0].traitId, 9);
        assertEq(requests[0].nounId, ANY_ID);
        assertEq(requests[0].recipientId, 0);

        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // Sanity check last request
        assertEq(uint8(requests[4].trait), uint8(HEAD));
        assertEq(requests[4].id, 4);
        assertEq(requests[4].traitId, 9);
        assertEq(requests[4].nounId, ANY_ID);
        assertEq(requests[4].recipientId, 2);

        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // Case 2
        // Auction ends soon
        vm.warp(timestamp + 24 hours);
        requests = nounScout.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.AUCTION_ENDING_SOON)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounScout.RequestStatus.AUCTION_ENDING_SOON)
        );

        // Set recipient2 inactive
        nounScout.setRecipientActive(2, false);

        // Case 3
        // Auction ends soon
        // Recipient 2 is inactive
        requests = nounScout.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.AUCTION_ENDING_SOON)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // Create matchable Noun
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            9
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // Mock new auction ending in 24 hours
        vm.warp(timestamp);

        // Case 4
        // Noun Match Found
        // Recipient2 is inactive
        requests = nounScout.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.MATCH_FOUND)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // User2 performs the match; request 1 and 2 should match
        vm.prank(user2);
        nounScout.settle(HEAD, 102, allRecipientIds);

        // Case 5
        // After Match
        // Recipient 2 inactive
        requests = nounScout.requestsByAddress(user1);

        assertEq(requests.length, 5);

        // Request 1,2 Matched
        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        // Request 3,4 Did Not Match

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, ANY_ID);
        assertEq(requests[2].recipientId, 0);

        assertEq(
            uint8(requests[2].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        assertEq(uint8(requests[3].trait), uint8(HEAD));
        assertEq(requests[3].id, 3);
        assertEq(requests[3].traitId, 8);
        assertEq(requests[3].nounId, 102);
        assertEq(requests[3].recipientId, 1);

        assertEq(
            uint8(requests[3].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // Request 5 would have matched, but is inactive
        assertEq(uint8(requests[4].trait), uint8(HEAD));
        assertEq(requests[4].id, 4);
        assertEq(requests[4].traitId, 9);
        assertEq(requests[4].nounId, ANY_ID);
        assertEq(requests[4].recipientId, 2);

        assertEq(
            uint8(requests[4].status),
            uint8(NounScout.RequestStatus.CAN_REMOVE)
        );

        // User removes request 3
        vm.prank(user1);
        nounScout.remove(3);

        // Case 6
        // After Remove
        // Contains Matched, non-matched, recipient inactive
        requests = nounScout.requestsByAddress(user1);

        assertEq(requests.length, 4);

        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, 0);
        assertEq(requests[2].recipientId, 0);

        assertEq(uint8(requests[3].trait), uint8(HEAD));
        assertEq(requests[3].id, 4);
        assertEq(requests[3].traitId, 9);
        assertEq(requests[3].nounId, ANY_ID);
        assertEq(requests[3].recipientId, 2);

        // User removes request 4
        vm.prank(user1);
        nounScout.remove(4);

        // Case 6
        // After Remove
        // Contains Matched, non-matched, recipient inactive
        requests = nounScout.requestsByAddress(user1);

        assertEq(requests.length, 3);

        assertEq(
            uint8(requests[0].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounScout.RequestStatus.PLEDGE_SENT)
        );

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, 0);
        assertEq(requests[2].recipientId, 0);
    }

    function test_REIMBURSEMENT_totalEqualToMinReimbursement() public {
        nounScout.setMinReimbursement(minValue);
        vm.prank(user1);
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // minReimbursement and total pledged amoutn are equal, so simple BPS calculation used
        uint256 reimbursement = (minValue * nounScout.baseReimbursementBPS()) /
            10_000;

        vm.expectCall(address(recipient0), minValue - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounScout.settle(HEAD, 102, allRecipientIds);
    }

    function test_REIMBURSEMENT_reimbursementLessThanMinReimbursement() public {
        vm.prank(user1);
        nounScout.add{value: minValue}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        uint256 reimbursement = nounScout.minReimbursement();
        vm.expectCall(address(recipient0), minValue - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounScout.settle(HEAD, 102, allRecipientIds);
    }

    function test_REIMBURSEMENT_reimbursementGreaterThanMaxReimbursement()
        public
    {
        uint256 value = 5 ether;

        vm.prank(user1);
        nounScout.add{value: value}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        uint256 reimbursement = nounScout.maxReimbursement();
        vm.expectCall(address(recipient0), value - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounScout.settle(HEAD, 102, allRecipientIds);
    }
}
