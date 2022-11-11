// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounSeekTest.sol";

contract MatchAndDonate is BaseNounSeekTest {
    function setUp() public override {
        BaseNounSeekTest.setUp();
    }

    // Auctioned is immediate previous
    function test_MATCHANDDONATE_happyMatchCase1() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 102, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 103, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, 102);
        uint16 nonces3 = nounSeek.nonceForTraits(HEAD, 8, ANY_ID);
        uint16 nonces4 = nounSeek.nonceForTraits(HEAD, 8, 102);
        uint16 nonces5 = nounSeek.nonceForTraits(HEAD, 9, 103);
        uint16 nonces6 = nounSeek.nonceForTraits(HEAD, 9, 101);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(102);

        vm.startPrank(user2);

        // Cannot match Noun on auction
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
        mockAuctionHouse.setNounId(103);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(donee1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces1 + 1);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces2 + 1);

        // nonces remain for non-matches
        assertEq(nounSeek.nonceForTraits(HEAD, 8, ANY_ID), nonces3);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, 102), nonces4);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 103), nonces5);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 101), nonces6);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);
    }

    // Auctioned Noun matches with non-auctioned non-match immediately before
    function test_MATCHANDDONATE_happyMatchCase2() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 101, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 99, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, 101);
        uint16 nonces3 = nounSeek.nonceForTraits(HEAD, 8, ANY_ID);
        uint16 nonces4 = nounSeek.nonceForTraits(HEAD, 8, 101);
        uint16 nonces5 = nounSeek.nonceForTraits(HEAD, 9, 102);
        uint16 nonces6 = nounSeek.nonceForTraits(HEAD, 9, 99);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(101);

        vm.startPrank(user2);

        // Cannot match Noun on auction
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
        mockAuctionHouse.setNounId(102);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(donee1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces1 + 1);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 101), nonces2 + 1);

        // nonces remain for non-matches
        assertEq(nounSeek.nonceForTraits(HEAD, 8, ANY_ID), nonces3);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, 101), nonces4);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces5);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 99), nonces6);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);
    }

    // Auctioned Noun matches with non-auctioned match immediately before
    function test_MATCHANDDONATE_happyMatchCase3() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 100, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 101, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 99, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, 100);
        uint16 nonces3 = nounSeek.nonceForTraits(HEAD, 8, ANY_ID);
        uint16 nonces4 = nounSeek.nonceForTraits(HEAD, 8, 101);
        uint16 nonces5 = nounSeek.nonceForTraits(HEAD, 9, 102);
        uint16 nonces6 = nounSeek.nonceForTraits(HEAD, 9, 99);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(101);

        vm.startPrank(user2);

        // Cannot match Noun on auction
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
        mockAuctionHouse.setNounId(102);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(donee1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces1 + 1);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 100), nonces2 + 1);

        // nonces remain for non-matches
        assertEq(nounSeek.nonceForTraits(HEAD, 8, ANY_ID), nonces3);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, 101), nonces4);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces5);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 99), nonces6);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);
    }

    // Auctioned Noun non-match with non-auctioned match immediately before
    function test_MATCHANDDONATE_happyMatchCase4() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 100, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 100, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, 100, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 101, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 99, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, 100);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces3 = nounSeek.nonceForTraits(HEAD, 8, ANY_ID);
        uint16 nonces4 = nounSeek.nonceForTraits(HEAD, 8, 101);
        uint16 nonces5 = nounSeek.nonceForTraits(HEAD, 9, 101);
        uint16 nonces6 = nounSeek.nonceForTraits(HEAD, 9, 99);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 100);

        mockAuctionHouse.setNounId(101);

        vm.startPrank(user2);

        // Cannot match Noun on auction
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
        mockAuctionHouse.setNounId(102);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(donee1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 100), nonces1 + 1);

        // nonces remain for non-matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces2);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, ANY_ID), nonces3);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, 101), nonces4);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces5);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 99), nonces6);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);
    }

    // Previous Noun is non-auctioned, previous auctioned matches
    function test_MATCHANDDONATE_happyMatchCase5() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 99, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, 100, 0);
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 100, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, 99);
        uint16 nonces3 = nounSeek.nonceForTraits(HEAD, 8, 100);
        uint16 nonces4 = nounSeek.nonceForTraits(HEAD, 8, ANY_ID);
        uint16 nonces5 = nounSeek.nonceForTraits(HEAD, 9, 101);
        uint16 nonces6 = nounSeek.nonceForTraits(HEAD, 9, 100);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 99);

        mockAuctionHouse.setNounId(99);

        vm.startPrank(user2);

        // Cannot match Noun on auction
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
        mockAuctionHouse.setNounId(101);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(donee1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces1 + 1);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 99), nonces2 + 1);

        // nonces remain for non-matches

        assertEq(nounSeek.nonceForTraits(HEAD, 8, 100), nonces3);
        assertEq(nounSeek.nonceForTraits(HEAD, 8, ANY_ID), nonces4);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 101), nonces5);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 100), nonces6);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);
    }

    // If the amount sent produces reimburesement greater than `maxReimbursement`
    function test_MATCHANDDONATE_HappyAboveMaxReimbursement() public {
        // The maximum amount that can be sent before reimburesement bps drops
        uint256 thresholdValue = (maxReimbursement * 10_000) /
            maxReimbursementBPS;

        vm.prank(user1);

        // Send twice the value of the threshold (8 eth)
        nounSeek.add{value: thresholdValue * 2}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // Expect no more than the maximum reimbursement value to be deducted from the donation
        vm.expectCall(
            address(donee0),
            (thresholdValue * 2) - maxReimbursement,
            ""
        );
        // Expect no more than the maximum reimbursement value to be sent to the matcher
        vm.expectCall(address(user2), maxReimbursement, "");

        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);
    }

    function test_MATCHANDDONATE_HappyBelowMinReimbursement() public {
        // The minimum amount that can be sent before reimburesement bps is raised = 0.08 ETH
        uint256 thresholdValue = (minReimbursement * 10_000) /
            maxReimbursementBPS;

        vm.prank(user1);
        // Send half the value of the threshold (0.08-1 ETH)
        nounSeek.add{value: thresholdValue - 1}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // Expect min reimburesement to be deducted from the donation
        vm.expectCall(
            address(donee0),
            thresholdValue - 1 - minReimbursement,
            ""
        );

        // Expect half the maximum reimburesement to be sent to the matcher
        vm.expectCall(address(user2), minReimbursement, "");

        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);
    }

    function test_MATCHANDDONATE_HappyAboveMinReimbursementBelowMaxReimbursement()
        public
    {
        // above 0.08 ETH minimum total, below 4 ETH maximum total
        uint256 thresholdValue = 1 ether;

        vm.prank(user1);
        // Send half the value of the threshold (2 eth)
        nounSeek.add{value: thresholdValue}(HEAD, 9, ANY_ID, 0);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // maxReimbursementBPS of 2.5% is applied to the total
        uint256 reimbursement = (thresholdValue * maxReimbursementBPS) / 10_000;

        // Expect reimbursement deducted from the total
        vm.expectCall(address(donee0), thresholdValue - reimbursement, "");

        // Expect reimburesement to be sent to the matcher
        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);
    }

    function test_MATCHANDDONATE_allDoneesInactive() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 102, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 103, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 1);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        nounSeek.setDoneeActive(0, false);
        nounSeek.setDoneeActive(1, false);
        vm.startPrank(user2);

        // No donations to send; all donees inactive
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.matchAndDonate(HEAD);
    }

    function test_MATCHANDDONATE_oneDoneeInactive() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);

        uint16 nonces1 = nounSeek.nonceForTraits(HEAD, 9, ANY_ID);
        uint16 nonces2 = nounSeek.nonceForTraits(HEAD, 9, 102);

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 102);
        mockAuctionHouse.setNounId(103);

        // Set donee1 inactive
        nounSeek.setDoneeActive(1, false);

        // reqeust 1
        vm.expectCall(address(donee0), minValue - minReimbursement, "");
        // request 1 reimbursement
        vm.expectCall(address(user2), minReimbursement, "");

        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);

        // nonces increase for matches
        assertEq(nounSeek.nonceForTraits(HEAD, 9, ANY_ID), nonces1 + 1);
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces2);

        assertEq(nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 0), 0), 0);

        // donnee1 retains deposited amount
        assertEq(
            nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 102), 1),
            minValue
        );

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.matchAndDonate(HEAD);

        // Set donee1 active
        nounSeek.setDoneeActive(1, true);

        // reqeust 2
        vm.expectCall(address(donee1), minValue - minReimbursement, "");
        // request 2 reimbursement
        vm.expectCall(address(user2), minReimbursement, "");

        // can re-match noun
        vm.prank(user2);
        nounSeek.matchAndDonate(HEAD);

        // nonces increase for active donee match
        assertEq(nounSeek.nonceForTraits(HEAD, 9, 102), nonces2 + 1);

        // donnee1 amounts are 0
        assertEq(nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 102), 1), 0);
    }
}
