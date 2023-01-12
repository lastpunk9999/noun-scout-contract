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
        // Total 20 Recipients
        // Add 5-9
        nounSeek.addRecipient("recipient0", recipient0, "");
        nounSeek.addRecipient("recipient1", recipient1, "");
        nounSeek.addRecipient("recipient2", recipient2, "");
        nounSeek.addRecipient("recipient3", recipient3, "");
        nounSeek.addRecipient("recipient4", recipient4, "");
        // Add 10-14
        nounSeek.addRecipient("recipient0", recipient0, "");
        nounSeek.addRecipient("recipient1", recipient1, "");
        nounSeek.addRecipient("recipient2", recipient2, "");
        nounSeek.addRecipient("recipient3", recipient3, "");
        nounSeek.addRecipient("recipient4", recipient4, "");
        // Add 15-19
        nounSeek.addRecipient("recipient0", recipient0, "");
        nounSeek.addRecipient("recipient1", recipient1, "");
        nounSeek.addRecipient("recipient2", recipient2, "");
        nounSeek.addRecipient("recipient3", recipient3, "");
        nounSeek.addRecipient("recipient4", recipient4, "");

        mockDescriptor.setBackgroundCount(2);
        mockDescriptor.setBodyCount(23);
        mockDescriptor.setAccessoryCount(130);
        mockDescriptor.setHeadCount(242);
        mockDescriptor.setGlassesCount(30);

        nounSeek.updateTraitCounts();

        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);

        vm.warp(timestamp);
    }

    function test_PLEDGESFORUPCOMINGNOUNBYTRAIT_NoNonAuctionedNoSpecificID()
        public
    {
        vm.startPrank(user1);

        // For traitIds 0 - 9
        for (uint16 traitId; traitId < 10; traitId++) {
            // add a request for ANY_ID, to recipient 0
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 0);
            // add a request for Noun 101, to recipient 1
            nounSeek.add{value: minValue}(HEAD, traitId, 101, 1);
            // add a request for Noun 100, to recipient 2
            nounSeek.add{value: minValue}(HEAD, traitId, 100, 2);
        }

        uint256 recipientsCount = nounSeek.recipients().length;

        // Next Noun has No Requests
        mockAuctionHouse.setNounId(98);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionPledges,
            uint256[][] memory nextNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionedId, 99);
        assertEq(nextNonAuctionedId, type(uint16).max);

        assertEq(nextAuctionPledges.length, nounSeek.headCount());

        // There is no non-auction Noun, so no slots for recipients
        assertEq(nextNonAuctionPledges.length, 0);

        for (uint256 traitId; traitId < 10; traitId++) {
            assertEq(nextAuctionPledges[traitId].length, recipientsCount);
            // Check that recipient#1 and donnee#2 are zero
            assertEq(nextAuctionPledges[traitId][1], 0);
            assertEq(nextAuctionPledges[traitId][2], 0);
            // Check that recipient#0 is minValue because of ANY_ID request
            assertEq(nextAuctionPledges[traitId][0], minValue);
        }
    }

    function test_PLEDGESFORUPCOMINGNOUNBYTRAIT_NonAuctionedAndSpecificID()
        public
    {
        vm.startPrank(user1);

        // For Each trait, except Background

        for (uint16 traitId; traitId < 10; traitId++) {
            // add a request for ANY_ID, to recipient 0
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 0);
            // add a request for Noun 101 and ANY_ID, to recipient 1
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 1);
            nounSeek.add{value: minValue}(HEAD, traitId, 101, 1);
            // add a request for Noun 100, to recipient 2
            nounSeek.add{value: minValue}(HEAD, traitId, 100, 2);
        }

        uint256 recipientsCount = nounSeek.recipients().length;

        // Next Noun has Non-Auctioned Noun and Specific Id Requests
        mockAuctionHouse.setNounId(99);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionPledges,
            uint256[][] memory nextNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionedId, 101);
        assertEq(nextNonAuctionedId, 100);

        assertEq(nextAuctionPledges.length, nounSeek.headCount());

        assertEq(nextNonAuctionPledges.length, nounSeek.headCount());

        for (uint256 traitId; traitId < 10; traitId++) {
            assertEq(nextAuctionPledges[traitId].length, recipientsCount);

            assertEq(nextNonAuctionPledges[traitId].length, recipientsCount);
            // recipient#0 only had ANY_ID requests
            assertEq(nextAuctionPledges[traitId][0], minValue);
            // recipient#1 had specific ID and ANY_ID requests
            assertEq(nextAuctionPledges[traitId][1], minValue * 2);
            // recipient#2 had no requests for ANY_ID or Noun 101
            assertEq(nextAuctionPledges[traitId][2], 0);

            // recipient#0 had no requests for Noun 100
            assertEq(nextNonAuctionPledges[traitId][0], 0);
            // recipient#1 had no requests for Noun 100
            assertEq(nextNonAuctionPledges[traitId][1], 0);
            // recipient#2 had requests for Noun 100
            assertEq(nextNonAuctionPledges[traitId][2], minValue);
        }
    }

    function test_PLEDGESFORNOUNONAUCTIONBYTRAIT_NoNonAuctionedNoSpecificID()
        public
    {
        vm.startPrank(user1);
        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9

            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to recipient 1
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    102,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }
        uint256 recipientsCount = nounSeek.recipients().length;

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);
        mockNouns.setSeed(seed, 102);

        // Current Noun has specific ID and ANY_ID requests for GLASSES
        mockAuctionHouse.setNounId(102);
        (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[] memory currentAuctionPledges,
            uint256[] memory prevNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForNounOnAuctionByTrait(GLASSES);

        assertEq(currentAuctionedId, 102);
        assertEq(prevNonAuctionedId, type(uint16).max);

        assertEq(currentAuctionPledges.length, recipientsCount);

        // // There is no non-auction Noun, so no slots for recipients
        assertEq(prevNonAuctionPledges.length, 0);

        assertEq(currentAuctionPledges[0], minValue);
        assertEq(currentAuctionPledges[1], minValue * 2);
        assertEq(currentAuctionPledges[2], 0);
        assertEq(currentAuctionPledges[3], 0);

        // Current Noun has no matching requests for HEAD
        (
            ,
            ,
            currentAuctionPledges,
            prevNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForNounOnAuctionByTrait(HEAD);
        assertEq(currentAuctionPledges.length, recipientsCount);

        assertEq(currentAuctionPledges[0], 0);
        assertEq(currentAuctionPledges[1], 0);
        assertEq(currentAuctionPledges[2], 0);
        assertEq(currentAuctionPledges[3], 0);
    }

    function test_PLEDGESFORNOUNONAUCTIONBYTRAIT_NonAuctionedAndSpecificID()
        public
    {
        vm.startPrank(user1);
        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to recipient 1
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 102, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    102,
                    3
                );
            }
        }
        uint256 recipientsCount = nounSeek.recipients().length;

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);

        // Current Noun has specific ID and ANY_ID requests for GLASSES
        mockAuctionHouse.setNounId(101);
        (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[] memory currentAuctionPledges,
            uint256[] memory prevNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForNounOnAuctionByTrait(GLASSES);

        assertEq(currentAuctionedId, 101);
        assertEq(prevNonAuctionedId, 100);

        assertEq(currentAuctionPledges.length, recipientsCount);

        assertEq(prevNonAuctionPledges.length, recipientsCount);

        assertEq(currentAuctionPledges[0], minValue);
        assertEq(currentAuctionPledges[1], minValue * 2);
        assertEq(currentAuctionPledges[2], 0);
        assertEq(currentAuctionPledges[3], 0);

        // NOUN 100 request were only for recipient 2
        assertEq(prevNonAuctionPledges[0], 0);
        assertEq(prevNonAuctionPledges[1], 0);
        assertEq(prevNonAuctionPledges[2], minValue);
        assertEq(prevNonAuctionPledges[3], 0);

        // No requests for match current HEAD
        (
            ,
            ,
            currentAuctionPledges,
            prevNonAuctionPledges
        ) = nounSeekViewUtils.pledgesForNounOnAuctionByTrait(HEAD);

        assertEq(currentAuctionPledges.length, recipientsCount);

        assertEq(prevNonAuctionPledges.length, recipientsCount);

        assertEq(currentAuctionPledges[0], 0);
        assertEq(currentAuctionPledges[1], 0);
        assertEq(currentAuctionPledges[2], 0);
        assertEq(currentAuctionPledges[3], 0);

        assertEq(prevNonAuctionPledges[0], 0);
        assertEq(prevNonAuctionPledges[1], 0);
        assertEq(prevNonAuctionPledges[2], 0);
        assertEq(prevNonAuctionPledges[3], 0);
    }

    function test_PLEDGESFORMATCHABLENOUNBYTRAIT_AuctionedNoSkip() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    102,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 recipientsCount = nounSeek.recipients().length;

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);
        mockNouns.setSeed(seed, 102);

        mockAuctionHouse.setNounId(103);
        // Current Noun has specific ID and ANY_ID requests for GLASSES
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounPledges,
            uint256[] memory nonAuctionedNounPledges,
            uint256 totalPledges,
            uint256 reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(GLASSES);

        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges.length, recipientsCount);
        assertEq(nonAuctionedNounPledges.length, 0);

        assertEq(auctionedNounPledges[0], minValue);
        assertEq(auctionedNounPledges[1], minValue * 2);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        uint256 expectedTotal = (minValue * 3) - minReimbursement;
        assertEq(totalPledges, expectedTotal);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounPledges,
            nonAuctionedNounPledges,
            totalPledges,
            reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(HEAD);

        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges.length, recipientsCount);
        assertEq(nonAuctionedNounPledges.length, 0);

        assertEq(auctionedNounPledges[0], 0);
        assertEq(auctionedNounPledges[1], 0);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalPledges, 0);
    }

    function test_PLEDGESFORMATCHABLENOUNBYTRAIT_AuctionedSkip() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    99,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 recipientsCount = nounSeek.recipients().length;

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 99);
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);

        mockAuctionHouse.setNounId(101);
        // Current Noun has specific ID and ANY_ID requests for GLASSES
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounPledges,
            uint256[] memory nonAuctionedNounPledges,
            uint256 totalPledges,
            uint256 reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(GLASSES);

        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges.length, recipientsCount);

        assertEq(nonAuctionedNounPledges.length, 0);

        uint256 expectedPledge = minValue;
        assertEq(auctionedNounPledges[0], expectedPledge);
        assertEq(auctionedNounPledges[1], expectedPledge * 2);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        uint256 expectedTotalPledge = (minValue * 3) - minReimbursement;
        assertEq(totalPledges, expectedTotalPledge);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounPledges,
            nonAuctionedNounPledges,
            totalPledges,
            reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(HEAD);

        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges.length, recipientsCount);

        assertEq(nonAuctionedNounPledges.length, 0);

        assertEq(auctionedNounPledges[0], 0);
        assertEq(auctionedNounPledges[1], 0);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalPledges, 0);
    }

    function test_PLEDGESFORMATCHABLENOUNBYTRAIT_NonAuctioned() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    99,
                    3
                );
            }
        }

        uint256 recipientsCount = nounSeek.recipients().length;

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 99);
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);

        mockAuctionHouse.setNounId(102);
        // Current Noun has specific ID and ANY_ID requests for GLASSES
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounPledges,
            uint256[] memory nonAuctionedNounPledges,
            uint256 totalPledges,
            uint256 reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(GLASSES);
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounPledges.length, recipientsCount);

        assertEq(nonAuctionedNounPledges.length, recipientsCount);

        uint256 expectedPledge = minValue;
        assertEq(auctionedNounPledges[0], expectedPledge);
        assertEq(auctionedNounPledges[1], expectedPledge * 2);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        assertEq(nonAuctionedNounPledges[0], 0);
        assertEq(nonAuctionedNounPledges[1], 0);
        assertEq(nonAuctionedNounPledges[2], expectedPledge);
        assertEq(nonAuctionedNounPledges[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        // 4 requests total for the trait
        // (1) ANY ID (2) ANY ID (3) 101 specific Id (4) 101 specific id
        uint256 expectedTotalPledge = (minValue * 4) - minReimbursement;
        assertEq(totalPledges, expectedTotalPledge);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounPledges,
            nonAuctionedNounPledges,
            totalPledges,
            reimbursement
        ) = nounSeekViewUtils.pledgesForMatchableNounByTrait(HEAD);
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounPledges.length, recipientsCount);

        assertEq(nonAuctionedNounPledges.length, recipientsCount);

        assertEq(auctionedNounPledges[0], 0);
        assertEq(auctionedNounPledges[1], 0);
        assertEq(auctionedNounPledges[2], 0);
        assertEq(auctionedNounPledges[3], 0);

        assertEq(nonAuctionedNounPledges[0], 0);
        assertEq(nonAuctionedNounPledges[1], 0);
        assertEq(nonAuctionedNounPledges[2], 0);
        assertEq(nonAuctionedNounPledges[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalPledges, 0);
    }
}
