// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounSeekTest.sol";

contract Settle is BaseNounSeekTest {
    function setUp() public override {
        BaseNounSeekTest.setUp();
    }

    // Auctioned is immediate previous
    function test_SETTLE_happyMatchCase1() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);
        // 3-6 Should not match
        nounSeek.add{value: minValue}(HEAD, 8, ANY_ID, 0);
        nounSeek.add{value: minValue}(HEAD, 8, 102, 1);
        nounSeek.add{value: minValue}(HEAD, 9, 103, 2);
        nounSeek.add{value: minValue}(HEAD, 9, 101, 3);

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
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 102, allRecipientIds);

        mockAuctionHouse.setNounId(103);

        // reqeust 1
        vm.expectCall(address(recipient0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(recipient1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 102, allRecipientIds);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 102, allRecipientIds);
    }

    // Auctioned Noun matches with non-auctioned non-match immediately before
    function test_SETTLE_happyMatchCase2() public {
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
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);

        // Cannot match previous non-auctioned Noun
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);

        // Cannot match uint16.max
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, type(uint16).max, allRecipientIds);

        mockAuctionHouse.setNounId(102);

        // No matches for non-auctioned Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);

        // reqeust 1
        vm.expectCall(address(recipient0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(recipient1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 101, allRecipientIds);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);
    }

    // Auctioned Noun matches with non-auctioned match immediately before
    function test_SETTLE_happyMatchCase3() public {
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
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);

        // Cannot match previous non-auctioned Noun
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);

        // Cannot match uint16.max
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, type(uint16).max, allRecipientIds);

        mockAuctionHouse.setNounId(102);

        // Only request 1 matches 101
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 101, allRecipientIds);

        // Only request 2 matches 100
        vm.expectCall(address(recipient1), minValue - minReimbursement, "");
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 100, allRecipientIds);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);

        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);
    }

    // Auctioned Noun non-match with non-auctioned match immediately before
    function test_SETTLE_happyMatchCase4() public {
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

        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 100);

        mockAuctionHouse.setNounId(102);

        vm.startPrank(user2);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);

        // reqeust 1
        vm.expectCall(address(recipient0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(recipient1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 100, allRecipientIds);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);
    }

    // Previous Noun is non-auctioned, previous auctioned matches
    function test_SETTLE_happyMatchCase5() public {
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
        vm.expectRevert(NounSeek.IneligibleNounId.selector);

        nounSeek.settle(HEAD, 99, allRecipientIds);

        mockAuctionHouse.setNounId(101);

        // reqeust 1
        vm.expectCall(address(recipient0), minValue - minReimbursement / 2, "");
        // request 2
        vm.expectCall(address(recipient1), minValue - minReimbursement / 2, "");
        // request 1 + 2
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 99, allRecipientIds);

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 99, allRecipientIds);
    }

    // If the amount sent produces reimburesement greater than `maxReimbursement`
    function test_SETTLE_HappyAboveMaxReimbursement() public {
        // The maximum amount that can be sent before reimburesement bps drops
        uint256 thresholdValue = (maxReimbursement * 10_000) /
            baseReimbursementBPS;

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

        // Expect no more than the maximum reimbursement value to be deducted from the pledge
        vm.expectCall(
            address(recipient0),
            (thresholdValue * 2) - maxReimbursement,
            ""
        );
        // Expect no more than the maximum reimbursement value to be sent to the matcher
        vm.expectCall(address(user2), maxReimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allRecipientIds);
    }

    function test_SETTLE_HappyBelowMinReimbursement() public {
        // The minimum amount that can be sent before reimburesement bps is raised = 0.08 ETH
        uint256 thresholdValue = (minReimbursement * 10_000) /
            baseReimbursementBPS;

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

        // Expect min reimburesement to be deducted from the pledge
        vm.expectCall(
            address(recipient0),
            thresholdValue - 1 - minReimbursement,
            ""
        );

        // Expect half the maximum reimburesement to be sent to the matcher
        vm.expectCall(address(user2), minReimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allRecipientIds);
    }

    function test_SETTLE_HappyAboveMinReimbursementBelowMaxReimbursement()
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

        // baseReimbursementBPS of 2.5% is applied to the total
        uint256 reimbursement = (thresholdValue * baseReimbursementBPS) /
            10_000;

        // Expect reimbursement deducted from the total
        vm.expectCall(address(recipient0), thresholdValue - reimbursement, "");

        // Expect reimburesement to be sent to the matcher
        vm.expectCall(address(user2), reimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allRecipientIds);
    }

    function test_SETTLE_allRecipientsInactive() public {
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

        nounSeek.setRecipientActive(0, false);
        nounSeek.setRecipientActive(1, false);
        vm.startPrank(user2);

        // No pledges to send; all recipients inactive
        vm.expectRevert(NounSeek.NoMatch.selector);

        nounSeek.settle(HEAD, 102, allRecipientIds);
    }

    function test_SETTLE_oneRecipientInactive() public {
        vm.startPrank(user1);
        // 1 Should match
        nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, 0);
        // 2 Should match
        nounSeek.add{value: minValue}(HEAD, 9, 102, 1);

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

        // Set recipient1 inactive
        nounSeek.setRecipientActive(1, false);

        // reqeust 1
        vm.expectCall(address(recipient0), minValue - minReimbursement, "");
        // request 1 reimbursement
        vm.expectCall(address(user2), minReimbursement, "");

        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allRecipientIds);

        assertEq(nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 0), 0), 0);

        // donnee1 retains deposited amount
        assertEq(
            nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 102), 1),
            minValue
        );

        // Cannot re-match Noun
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 102, allRecipientIds);

        // Set recipient1 active
        nounSeek.setRecipientActive(1, true);

        // reqeust 2
        vm.expectCall(address(recipient1), minValue - minReimbursement, "");
        // request 2 reimbursement
        vm.expectCall(address(user2), minReimbursement, "");

        // can re-match noun
        vm.prank(user2);
        nounSeek.settle(HEAD, 102, allRecipientIds);

        // donnee1 amounts are 0
        assertEq(nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 102), 1), 0);
    }

    function test_SETTLE_failsIneligibleImmediateAuctionedNounId() public {
        // only 99 is eligible
        mockAuctionHouse.setNounId(101);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, type(uint16).max, allRecipientIds);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 102, allRecipientIds);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);
        // eligible
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 99, allRecipientIds);
    }

    function test_SETTLE_failsIneligibleNonAuctionedNounId() public {
        // only 100 and 101 are eligible
        mockAuctionHouse.setNounId(102);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, type(uint16).max, allRecipientIds);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 102, allRecipientIds);
        // eligible
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 101, allRecipientIds);
        // eligible
        vm.expectRevert(NounSeek.NoMatch.selector);
        nounSeek.settle(HEAD, 100, allRecipientIds);
        // ineligible
        vm.expectRevert(NounSeek.IneligibleNounId.selector);
        nounSeek.settle(HEAD, 99, allRecipientIds);
    }

    function test_SETTLE_matchesOnlySpecifiedRecipientIds() public {
        vm.startPrank(user1);
        // Each eligible Noun Id has a request for HEAD 9 sent to every recipient Id
        for (uint16 i = 0; i < allRecipientIds.length; i++) {
            nounSeek.add{value: minValue}(HEAD, 9, ANY_ID, i);
            nounSeek.add{value: minValue}(HEAD, 9, 101, i);
            nounSeek.add{value: minValue}(HEAD, 9, 100, i);
        }

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
        mockAuctionHouse.setNounId(102);

        uint16[] memory recipientIds = new uint16[](2);

        // Only specify to recipient0 and recipient2
        recipientIds[0] = 0;
        recipientIds[1] = 2;

        vm.startPrank(user2);
        // recipient0 has 2 matching requets, 1) ANY_ID, 2) specific 101
        vm.expectCall(
            address(recipient0),
            (minValue * 2) - (minReimbursement / 2),
            ""
        );
        // recipient2 has 2 matching requets, 1) ANY_ID, 2) specific 101
        vm.expectCall(
            address(recipient2),
            (minValue * 2) - (minReimbursement / 2),
            ""
        );
        vm.expectCall(address(user2), minReimbursement, "");

        nounSeek.settle(HEAD, 101, recipientIds);

        for (uint16 i; i < allRecipientIds.length; i++) {
            uint256 amount = minValue;
            if (i == 0 || i == 2) amount = 0;
            assertEq(
                nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 101), i),
                amount
            );
            assertEq(
                nounSeek.amounts(nounSeek.traitHash(HEAD, 9, ANY_ID), i),
                amount
            );
            assertEq(
                nounSeek.amounts(nounSeek.traitHash(HEAD, 9, 100), i),
                minValue
            );
        }
    }

    function test_SETTLE_revertsWhenPaused() public {
        vm.prank(user1);
        // 1 Should match
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

        nounSeek.pause();

        vm.expectRevert(bytes("Pausable: paused"));
        nounSeek.settle(HEAD, 102, allRecipientIds);

        nounSeek.unpause();

        vm.startPrank(user2);
        vm.expectCall(address(user2), minReimbursement, "");
        nounSeek.settle(HEAD, 102, allRecipientIds);
    }
}
