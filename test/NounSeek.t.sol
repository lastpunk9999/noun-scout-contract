// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounSeekTest.sol";

contract NounSeekTest is BaseNounSeekTest {
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
        // USER 1
        // - adds a request
        vm.prank(user1);

        uint256 requestIdUser1 = nounSeek.add{value: minValue}(
            HEAD,
            9,
            ANY_ID,
            1
        );

        uint16 nonce1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);

        NounSeek.Request memory request1 = nounSeek.requestById(
            address(user1),
            requestIdUser1
        );

        assertEq(uint8(request1.trait), uint8(HEAD));
        assertEq(request1.traitId, 9);
        assertEq(request1.doneeId, 1);
        assertEq(request1.nounId, ANY_ID);
        assertEq(request1.amount, minValue);
        assertEq(request1.nonce, nonce1);

        NounSeek.Request[] memory requestsUser1 = nounSeek.requestsByAddress(
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
        requestsUser1 = nounSeek.requestsByAddress(address(user1));

        assertEq(requestsUser1.length, 2);

        amount = nounSeek.amountForDoneeByTrait(HEAD, 9, ANY_ID, 1);

        assertEq(amount, minValue * 2);

        assertEq(
            nounSeek.requestById(address(user1), requestIdUser1 + 1).nonce,
            nonce1
        );

        // USER 2
        // - adds additional request for different HEAD, specific noun Id, different donee
        vm.prank(user2);
        uint256 requestIdUser2 = nounSeek.add{value: minValue}(HEAD, 8, 99, 2);

        uint16 nonce2 = nounSeek.nonceForTraits(HEAD, 8, 99);

        NounSeek.Request memory request2 = nounSeek.requestById(
            address(user2),
            requestIdUser2
        );

        assertEq(uint8(request2.trait), uint8(HEAD));
        assertEq(request2.traitId, 8);
        assertEq(request2.doneeId, 2);
        assertEq(request2.nounId, 99);
        assertEq(request2.amount, minValue, "request2.amount");
        assertEq(request2.nonce, nonce2);

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
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,

        ) = nounSeek.donationsForNextNounByTrait(HEAD);

        assertEq(nextAuctionedId, 101);
        assertEq(nextNonAuctionedId, 100);
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
        nounSeek.toggleDoneeActive(1);
        vm.prank(user1);
        vm.expectRevert(NounSeek.InactiveDonee.selector);
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
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
        NounSeek.Request[] memory requestsUser1 = nounSeek.requestsByAddress(
            address(user1)
        );

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(donationsByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId1);
        requestsUser1 = nounSeek.requestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, minValue);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId2);
        requestsUser1 = nounSeek.requestsByAddress(address(user1));
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
        NounSeek.Request[] memory requestsUser1 = nounSeek.requestsByAddress(
            address(user1)
        );

        // Sanity check
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);

        assertEq(donationsByTraitId[9][1], minValue * 2);

        // Remove first request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId2);
        requestsUser1 = nounSeek.requestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, minValue);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], minValue);

        // Remove second request
        vm.expectCall(address(user1), minValue, "");
        nounSeek.remove(requestId1);
        requestsUser1 = nounSeek.requestsByAddress(address(user1));
        assertEq(requestsUser1.length, 2);
        assertEq(requestsUser1[0].amount, 0);
        assertEq(requestsUser1[1].amount, 0);

        donationsByTraitId = nounSeek.donationsForNounIdByTrait(HEAD, ANY_ID);
        assertEq(donationsByTraitId[9][1], 0);
    }

    function test_REMOVE_failsAuctionEndingSoon() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounSeek.TooLate.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_failsAuctionEnded() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        vm.expectRevert(NounSeek.TooLate.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_failsAlreadyRemoved() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);
        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);

        nounSeek.remove(requestId1);

        vm.expectRevert(NounSeek.ValueTooLow.selector);
        nounSeek.remove(requestId1);
    }

    function test_REMOVE_failsNotRequester() public {
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

    // Case 1: see NounSeek.sol comments
    function test_REMOVE_failsCase1() public {
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

    // Case 3: see NounSeek.sol comments
    function test_REMOVE_failsCase3() public {
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

    // Case 2: see NounSeek.sol comments
    function test_REMOVE_failsCase2() public {
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.startPrank(user1);

        uint256 requestId1 = nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 1);
        uint256 requestId2 = nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        uint256 requestId3 = nounSeek.add{value: minValue}(HEAD, 9, 101, 1);
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
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);
        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 102)
        );
        nounSeek.remove(requestId1);

        vm.expectRevert(
            abi.encodeWithSelector(NounSeek.MatchFound.selector, 102)
        );
        nounSeek.remove(requestId2);

        // Successful
        nounSeek.remove(requestId3);
        nounSeek.remove(requestId4);
        nounSeek.remove(requestId5);
        nounSeek.remove(requestId6);
    }

    // Case 2b: see NounSeek.sol comments
    function test_REMOVE_failsCase2b() public {
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

    function test_REMOVE_succeedsNoTransferAlreadyMatched() public {
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
        vm.expectCall(address(donee0), minValue - MIN_REIMBURSEMENT, "");
        vm.expectCall(address(user2), MIN_REIMBURSEMENT, "");
        nounSeek.matchAndDonate(HEAD);

        mockAuctionHouse.setNounId(103);
        vm.prank(user1);
        uint256 amount = nounSeek.remove(requestId1);
        assertEq(amount, 0);
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

        vm.stopPrank();

        NounSeek.ActiveRequest[] memory requests = nounSeek
            .requestsActiveByAddress(user1);

        assertEq(requests.length, 4);

        // Sanity check first request
        assertEq(uint8(requests[0].trait), uint8(HEAD));
        assertEq(requests[0].id, 0);
        assertEq(requests[0].traitId, 9);
        assertEq(requests[0].nounId, ANY_ID);
        assertEq(requests[0].doneeId, 0);

        // Match Noun
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);

        // Requests shoud be unmatched only
        requests = nounSeek.requestsActiveByAddress(user1);

        assertEq(requests.length, 2);

        assertEq(uint8(requests[0].trait), uint8(HEAD));
        assertEq(requests[0].id, 2);
        assertEq(requests[0].traitId, 8);
        assertEq(requests[0].nounId, ANY_ID);
        assertEq(requests[0].doneeId, 0);

        assertEq(uint8(requests[1].trait), uint8(HEAD));
        assertEq(requests[1].id, 3);
        assertEq(requests[1].traitId, 8);
        assertEq(requests[1].nounId, 102);
        assertEq(requests[1].doneeId, 1);

        // Delete active request
        uint256 timestamp = 1_000_000;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);

        vm.prank(user1);
        nounSeek.remove(3);

        // Requests should be only unmatched and not deleted
        requests = nounSeek.requestsActiveByAddress(user1);

        assertEq(requests.length, 1);

        assertEq(uint8(requests[0].trait), uint8(HEAD));
        assertEq(requests[0].id, 2);
        assertEq(requests[0].traitId, 8);
        assertEq(requests[0].nounId, 0);
        assertEq(requests[0].doneeId, 0);
    }
}
