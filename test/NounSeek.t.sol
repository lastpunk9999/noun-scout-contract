// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounSeekTest.sol";

contract NounSeekTest is BaseNounSeekTest {
    event RequestAdded(
        uint256 requestId,
        address indexed requester,
        NounSeek.Traits trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 indexed nounId,
        bytes32 indexed traitsHash,
        uint256 amount,
        string message
    );
    event RequestRemoved(
        uint256 requestId,
        address indexed requester,
        NounSeek.Traits trait,
        uint16 traitId,
        uint16 indexed nounId,
        uint16 doneeId,
        bytes32 indexed traitsHash,
        uint256 amount
    );

    function setUp() public override {
        BaseNounSeekTest.setUp();
    }

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounSeek.nouns()));
        assertEq(nounSeek.headCount(), 99);
        assertEq(nounSeek.glassesCount(), 98);
        assertEq(nounSeek.accessoryCount(), 97);
        assertEq(nounSeek.bodyCount(), 96);
        assertEq(nounSeek.backgroundCount(), 95);
    }

    function test_PAUSE_UNPAUSE() public {}

    function test_SETMINVALUE() public {}

    function test_SETReimbursementBPS() public {}

    function test_ADDDONEE() public {}

    function test_TOGGLEDONNEACTIVE() public {}

    function test_ADD_happyCase() public {

        vm.expectEmit(true, true, true, true);
        // expect the event to have the an empty message and the correct donation value
        emit RequestAdded(
            0,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            minValue,

            ""
        );

        // USER 1
        // - adds a request
        vm.prank(user1);

        uint256 requestIdUser1 = nounSeek.add{value: minValue}(
            HEAD,
            9,
            ANY_ID,
            1
        );

        NounSeek.Request memory request1 = nounSeek.rawRequestById(
            address(user1),
            requestIdUser1
        );

        assertEq(uint8(request1.trait), uint8(HEAD));
        assertEq(request1.traitId, 9);
        assertEq(request1.doneeId, 1);
        assertEq(request1.nounId, ANY_ID);
        assertEq(request1.amount, minValue);

        NounSeek.Request[] memory requestsUser1 = nounSeek.rawRequestsByAddress(
            address(user1)
        );

        assertEq(requestsUser1.length, 1);

        uint256 amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            1
        );

        assertEq(amount, minValue);

        // USER 1
        // - adds additional request for same traits and donee
        vm.prank(user1);
        assertEq(
            nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1),
            requestIdUser1 + 1
        );
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));

        assertEq(requestsUser1.length, 2);

        amount = nounSeekViewUtils.amountForDoneeByTrait(HEAD, 9, ANY_ID, 1);

        assertEq(amount, minValue * 2);


        // USER 2
        // - adds additional request for different HEAD, specific noun Id, different donee
        vm.expectEmit(true, true, true, true);


        // expect the event to have the an empty message and the correct donation value
        emit RequestAdded(
            0,
            address(user2),
            HEAD,
            8,
            2,
            99,
            nounSeek.traitHash(HEAD, 8, 99),
            minValue,
            ""
        );

        vm.prank(user2);
        uint256 requestIdUser2 = nounSeek.add{value: minValue}(HEAD, 8, 99, 2);

        NounSeek.Request memory request2 = nounSeek.rawRequestById(
            address(user2),
            requestIdUser2
        );

        assertEq(uint8(request2.trait), uint8(HEAD));
        assertEq(request2.traitId, 8);
        assertEq(request2.doneeId, 2);
        assertEq(request2.nounId, 99);
        assertEq(request2.amount, minValue, "request2.amount");

        // Should include user1 and user2 requests
        uint256[][] memory donationsByTraitId = nounSeek
            .donationsForNounIdByTrait(HEAD, 99);

        // USER1 ANY_Id requested 2 times
        assertEq(donationsByTraitId[9][1], minValue * 2);
        // USER2 Noun Id 99 requested 1 times
        assertEq(
            donationsByTraitId[8][2],
            minValue,
            "donationsByTraitId[8][2]"
        );

        // USER 3
        // - adds additional request for same HEAD, next Noun Id, same donee
        vm.prank(user3);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);

        // Should include user1 and user2 requests
        (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][] memory nextAuctionDonations,

        ) = nounSeekViewUtils.donationsForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionId, 101);
        assertEq(nextNonAuctionId, 100);
        // USER1 ANY_Id requested 2 times + USER3 Noun Id 101 requested 1 times
        assertEq(
            nextAuctionDonations[9][1],
            minValue * 3,
            "nextAuctionDonations[9][1]"
        );
    }

    function test_ADD_failsWhenPaused() public {
        nounSeek.pause();
        vm.expectRevert(bytes("Pausable: paused"));
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADD_failsBelowMinValue() public {
        vm.prank(user1);
        vm.expectRevert(NounSeek.ValueTooLow.selector);
        nounSeek.add{value: minValue - 1}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADD_failsInactiveDonee() public {
        nounSeek.setDoneeActive(1, false);
        vm.prank(user1);
        vm.expectRevert(NounSeek.InactiveDonee.selector);
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
    }

    function test_ADDWITHMESSAGE_happyCase() public {
        uint256 donation = 9 ether;
        vm.expectEmit(true, true, true, true);
        // expect the event to have the "hello" message and the correct donation value
        emit RequestAdded(
            0,
            address(user1),
            HEAD,
            9,
            1,
            ANY_ID,
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            donation,
            "hello"
        );

        // expect the minValue to pay for the message to be transferred to the donnee
        vm.expectCall(address(donee1), messageValue, "");

        vm.prank(user1);

        uint256 requestIdUser1 = nounSeek.addWithMessage{
            value: donation + messageValue
        }(HEAD, 9, ANY_ID, 1, "hello");

        NounSeek.Request memory request1 = nounSeek.rawRequestById(
            address(user1),
            requestIdUser1
        );

        assertEq(uint8(request1.trait), uint8(HEAD));
        assertEq(request1.traitId, 9);
        assertEq(request1.doneeId, 1);
        assertEq(request1.nounId, ANY_ID);
        assertEq(request1.amount, donation);

        NounSeek.Request[] memory requestsUser1 = nounSeek.rawRequestsByAddress(
            address(user1)
        );

        assertEq(requestsUser1.length, 1);

        uint256 amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            1
        );

        assertEq(amount, donation);
    }

    function test_ADDWITHMESSAGE_failsWhenValueTooLow() public {
        vm.expectRevert(NounSeek.ValueTooLow.selector);
        vm.prank(user1);

        nounSeek.addWithMessage{value: minValue}(HEAD, 9, ANY_ID, 1, "hello");
    }

    function test_REMOVE_after_addWithMessage_happyCaseFIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        // addWithMessage()
        uint256 requestId1 = nounSeek.addWithMessage{value: minValue + messageValue}(
            HEAD,
            9,
            ANY_ID,
            1,
            "hello"
        );

        // add()
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        uint256[][] memory donationsByTraitId = nounSeek
            .donationsForNounIdByTrait(HEAD, ANY_ID);
        NounSeek.Request[] memory requestsUser1 = nounSeek.rawRequestsByAddress(
            address(user1)
        );

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(donationsByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId1,
            address(user1),
            HEAD,
            9,
            ANY_ID,
            1,
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            minValue
        );

        vm.expectCall(address(user1), minValue, "");

        nounSeek.remove(requestId1);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, minValue);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], minValue);

        // Remove second request
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            ANY_ID,
            1,
            nounSeek.traitHash(HEAD, 9, ANY_ID),
            minValue
        );
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId2);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], 0);
    }

    function test_REMOVE_happyCaseFIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256[][] memory donationsByTraitId = nounSeek
            .donationsForNounIdByTrait(HEAD, ANY_ID);
        NounSeek.Request[] memory requestsUser1 = nounSeek.rawRequestsByAddress(
            address(user1)
        );

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(donationsByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId1);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, minValue);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId2);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], 0);
    }

    function test_REMOVE_happyCaseLIFO() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT + 1);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256[][] memory donationsByTraitId = nounSeek
            .donationsForNounIdByTrait(HEAD, ANY_ID);
        NounSeek.Request[] memory requestsUser1 = nounSeek.rawRequestsByAddress(
            address(user1)
        );

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(donationsByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId2);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId1);
        requestsUser1 = nounSeek.rawRequestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], 0);
    }

    function test_REMOVE_revertsAuctionEndingSoon() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounSeek.AuctionEndingSoon.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_revertsAuctionEnded() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounSeek.AuctionEndingSoon.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_revertsAlreadyRemoved() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        nounSeek.remove(requestId1);

        vm.expectRevert(NounSeek.AlreadyRemoved.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_revertsNotRequester() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.prank(user2);
        // Index out of bounds Error
        vm.expectRevert(stdError.indexOOBError);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_revertsCurrentMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 103, 1);
        uint256 requestId3 = nounSeek.add{value: minValue}(HEAD, 9, 99, 1);
        uint256 requestId4 = nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounSeek.add{value: minValue}(HEAD, 8, 103, 1);
        uint256 requestId6 = nounSeek.add{value: minValue}(HEAD, 8, 99, 1);

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
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 103)
        );
        nounSeek.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 103)
        );
        nounSeek.remove(requestId2);

        // Successful
        nounSeek.remove(requestId3);
        nounSeek.remove(requestId4);
        nounSeek.remove(requestId5);
        nounSeek.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 99, 1);
        uint256 requestId3 = nounSeek.add{value: minValue}(HEAD, 9, 100, 1);
        uint256 requestId4 = nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounSeek.add{value: minValue}(HEAD, 8, 99, 1);
        uint256 requestId6 = nounSeek.add{value: minValue}(HEAD, 8, 100, 1);

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
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 99)
        );
        nounSeek.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 99)
        );
        nounSeek.remove(requestId2);

        // Successful
        nounSeek.remove(requestId3);
        nounSeek.remove(requestId4);
        nounSeek.remove(requestId5);
        nounSeek.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousDoubleMintAuctionedMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 101, 1);
        uint256 requestId3 = nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        uint256 requestId4 = nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounSeek.add{value: minValue}(HEAD, 8, 102, 1);
        uint256 requestId6 = nounSeek.add{value: minValue}(HEAD, 8, 101, 1);

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
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 101)
        );
        nounSeek.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 101)
        );
        nounSeek.remove(requestId2);

        // Successful
        nounSeek.remove(requestId3);
        nounSeek.remove(requestId4);
        nounSeek.remove(requestId5);
        nounSeek.remove(requestId6);
    }

    function test_REMOVE_revertsPreviousNonAuctionedMatchFound() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, 100, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId3 = nounSeek.add{value: minValue}(HEAD, 9, 103, 1);
        uint256 requestId4 = nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        uint256 requestId5 = nounSeek.add{value: minValue}(HEAD, 8, 100, 1);
        uint256 requestId6 = nounSeek.add{value: minValue}(HEAD, 8, 101, 1);

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
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 100)
        );
        nounSeek.remove(requestId1);

        // Successful
        nounSeek.remove(requestId2); // ANY_ID requets do no match non-auctioned Nouns
        nounSeek.remove(requestId3);
        nounSeek.remove(requestId4);
        nounSeek.remove(requestId5);
        nounSeek.remove(requestId6);
    }

    function test_REMOVE_revertsAlreadySent() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, 100, 0);
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
        vm.expectCall(address(donee0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounSeek.settle(HEAD, 100, allDoneeIds);

        vm.startPrank(user1);
        vm.expectRevert(NounSeek.DonationAlreadySent.selector);

        nounSeek.remove(requestId1);

        mockAuctionHouse.setNounId(103);

        vm.expectRevert(NounSeek.DonationAlreadySent.selector);

        nounSeek.remove(requestId1);
    }

    function test_REMOVE_removeAfterMatchAndInactiveDonee() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounSeek.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        uint256 donee0Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            0
        );
        uint256 donee1Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(donee0Amount, minValue);
        assertEq(donee1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set donee1 to inactive
        nounSeek.setDoneeActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(donee0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounSeek.settle(HEAD, 100, allDoneeIds);

        donee0Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 0);
        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);

        // donee0 matched, funds removed
        assertEq(donee0Amount, 0);
        // donee1 did not match, funds remain
        assertEq(donee1Amount, minValue);

        // requestId2 can be removed
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            100,
            1,
            nounSeek.traitHash(HEAD, 9, 100),
            minValue
        );

        uint256 amount = nounSeek.remove(requestId2);
        assertEq(amount, minValue);

        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);
        assertEq(donee1Amount, 0);
    }

    function test_REMOVE_revertsAfterInactiveDoneeBecomesActiveAndMatches()
        public
    {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounSeek.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        uint256 donee0Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            0
        );
        uint256 donee1Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(donee0Amount, minValue);
        assertEq(donee1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set donee1 to inactive
        nounSeek.setDoneeActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(donee0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounSeek.settle(HEAD, 100, allDoneeIds);

        donee0Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 0);
        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);

        // donee0 matched, funds removed
        assertEq(donee0Amount, 0);
        // donee1 did not match, funds remain
        assertEq(donee1Amount, minValue);

        // set donee1 to active
        nounSeek.setDoneeActive(1, true);

        vm.prank(user2);
        vm.expectCall(address(donee1), minValue - minReimbursement, "");
        nounSeek.settle(HEAD, 100, allDoneeIds);

        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);
        assertEq(donee1Amount, 0);

        // requestId2 cannot be removed
        vm.startPrank(user1);
        vm.expectRevert(NounSeek.DonationAlreadySent.selector);

        nounSeek.remove(requestId2);
    }

    function test_REMOVE_removeAfterInactiveDoneeBecomesActive() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        nounSeek.add{value: minValue}(HEAD, 9, 100, 0);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 100, 1);

        vm.stopPrank();

        uint256 donee0Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            0
        );
        uint256 donee1Amount = nounSeek.amounts(
            nounSeek.traitHash(HEAD, 9, 100),
            1
        );

        assertEq(donee0Amount, minValue);
        assertEq(donee1Amount, minValue);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockAuctionHouse.setNounId(102);

        // set donee1 to inactive
        nounSeek.setDoneeActive(1, false);

        vm.prank(user2);

        // Sanity check match occured
        vm.expectCall(address(donee0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");
        nounSeek.settle(HEAD, 100, allDoneeIds);

        donee0Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 0);
        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);

        // donee0 matched, funds removed
        assertEq(donee0Amount, 0);
        // donee1 did not match, funds remain
        assertEq(donee1Amount, minValue);

        // set donee1 to active
        nounSeek.setDoneeActive(1, true);

        vm.startPrank(user1);

        // donee1, now active, matches Noun 100, cannot be removed
        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 100)
        );
        nounSeek.remove(requestId2);
        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);
        // donee1 funds removed
        assertEq(donee1Amount, minValue);

        // Current/prev Noun no longer matches
        mockAuctionHouse.setNounId(199);

        vm.expectEmit(true, true, true, true);
        emit RequestRemoved(
            requestId2,
            address(user1),
            HEAD,
            9,
            100,
            1,
            nounSeek.traitHash(HEAD, 9, 100),
            minValue
        );
        vm.expectCall(address(user1), minValue, "");
        uint256 amount = nounSeek.remove(requestId2);
        assertEq(amount, minValue);
        donee1Amount = nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), 1);
        // donee1 funds removed
        assertEq(donee1Amount, 0);
    }

    function test_REQUESTSBYACTIVEADDRESS_happyCase() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        // 3-4 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 102, 1);

        // 5 Should match, but donee2 will be set inactive
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 2);

        vm.stopPrank();

        // Case 1
        // Auction ends in the future
        // Noun seed/auctioned Noun do not match
        uint256 timestamp = 1_000_000;
        vm.warp(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);

        NounSeek.RequestWithStatus[] memory requests = nounSeek
            .requestsByAddress(user1);

        assertEq(requests.length, 5);

        // Sanity check first request
        assertEq(uint8(requests[0].trait), uint8(HEAD));
        assertEq(requests[0].id, 0);
        assertEq(requests[0].traitId, 9);
        assertEq(requests[0].nounId, ANY_ID);
        assertEq(requests[0].doneeId, 0);

        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        // Sanity check last request
        assertEq(uint8(requests[4].trait), uint8(HEAD));
        assertEq(requests[4].id, 4);
        assertEq(requests[4].traitId, 9);
        assertEq(requests[4].nounId, ANY_ID);
        assertEq(requests[4].doneeId, 2);

        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        // Case 2
        // Auction ends soon
        vm.warp(timestamp + 24 hours);
        requests = nounSeek.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.AUCTION_ENDING_SOON)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounSeek.RequestStatus.AUCTION_ENDING_SOON)
        );

        // Set donee2 inactive
        nounSeek.setDoneeActive(2, false);

        // Case 3
        // Auction ends soon
        // Donee 2 is inactive
        requests = nounSeek.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.AUCTION_ENDING_SOON)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
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
        // Donee2 is inactive
        requests = nounSeek.requestsByAddress(user1);
        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.MATCH_FOUND)
        );
        assertEq(
            uint8(requests[4].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        // User2 performs the match; request 1 and 2 should match
        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allDoneeIds);

        // Case 5
        // After Match
        // Donee 2 inactive
        requests = nounSeek.requestsByAddress(user1);

        assertEq(requests.length, 5);

        // Request 1,2 Matched
        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        // Request 3,4 Did Not Match

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, ANY_ID);
        assertEq(requests[2].doneeId, 0);

        assertEq(
            uint8(requests[2].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        assertEq(uint8(requests[3].trait), uint8(HEAD));
        assertEq(requests[3].id, 3);
        assertEq(requests[3].traitId, 8);
        assertEq(requests[3].nounId, 102);
        assertEq(requests[3].doneeId, 1);

        assertEq(
            uint8(requests[3].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        // Request 5 would have matched, but is inactive
        assertEq(uint8(requests[4].trait), uint8(HEAD));
        assertEq(requests[4].id, 4);
        assertEq(requests[4].traitId, 9);
        assertEq(requests[4].nounId, ANY_ID);
        assertEq(requests[4].doneeId, 2);

        assertEq(
            uint8(requests[4].status),
            uint8(NounSeek.RequestStatus.CAN_REMOVE)
        );

        // User removes request 3
        vm.prank(user1);
        nounSeek.remove(3);

        // Case 6
        // After Remove
        // Contains Matched, non-matched, donee inactive
        requests = nounSeek.requestsByAddress(user1);

        assertEq(requests.length, 4);

        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, 0);
        assertEq(requests[2].doneeId, 0);

        assertEq(uint8(requests[3].trait), uint8(HEAD));
        assertEq(requests[3].id, 4);
        assertEq(requests[3].traitId, 9);
        assertEq(requests[3].nounId, ANY_ID);
        assertEq(requests[3].doneeId, 2);

        // User removes request 4
        vm.prank(user1);
        nounSeek.remove(4);

        // Case 6
        // After Remove
        // Contains Matched, non-matched, donee inactive
        requests = nounSeek.requestsByAddress(user1);

        assertEq(requests.length, 3);

        assertEq(
            uint8(requests[0].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        assertEq(
            uint8(requests[1].status),
            uint8(NounSeek.RequestStatus.DONATION_SENT)
        );

        assertEq(uint8(requests[2].trait), uint8(HEAD));
        assertEq(requests[2].id, 2);
        assertEq(requests[2].traitId, 8);
        assertEq(requests[2].nounId, 0);
        assertEq(requests[2].doneeId, 0);
    }

    function test_REIMBURSEMENT_totalEqualToMinReimbursement() public {
        nounSeek.setMinReimbursement(minValue);
        vm.prank(user1);
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);

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
        uint256 reimbursement = (minValue * nounSeek.baseReimbursementBPS()) /
            10_000;

        vm.expectCall(address(donee0), minValue - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allDoneeIds);
    }

    function test_REIMBURSEMENT_reimbursementLessThanMinReimbursement() public {
        vm.prank(user1);
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        uint256 reimbursement = nounSeek.minReimbursement();
        vm.expectCall(address(donee0), minValue - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allDoneeIds);
    }

    function test_REIMBURSEMENT_reimbursementGreaterThanMaxReimbursement()
        public
    {
        uint256 value = 5 ether;

        vm.prank(user1);
        nounSeek.add{value: value}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        uint256 reimbursement = nounSeek.maxReimbursement();
        vm.expectCall(address(donee0), value - reimbursement, "");

        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allDoneeIds);
    }
}
