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
        // Total 20 Donees
        // Add 5-9
        nounSeek.addDonee("donee0", donee0, "");
        nounSeek.addDonee("donee1", donee1, "");
        nounSeek.addDonee("donee2", donee2, "");
        nounSeek.addDonee("donee3", donee3, "");
        nounSeek.addDonee("donee4", donee4, "");
        // Add 10-14
        nounSeek.addDonee("donee0", donee0, "");
        nounSeek.addDonee("donee1", donee1, "");
        nounSeek.addDonee("donee2", donee2, "");
        nounSeek.addDonee("donee3", donee3, "");
        nounSeek.addDonee("donee4", donee4, "");
        // Add 15-19
        nounSeek.addDonee("donee0", donee0, "");
        nounSeek.addDonee("donee1", donee1, "");
        nounSeek.addDonee("donee2", donee2, "");
        nounSeek.addDonee("donee3", donee3, "");
        nounSeek.addDonee("donee4", donee4, "");

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

    function test_DONATIONSFORNOUNBYTRAIT() public {
        vm.startPrank(user1);

        // 100 times
        for (uint16 i; i < 100; i++) {
            // For donees 0 - 14
            for (uint16 j; j < 15; j++) {
                // Add a request for each head, with any id, going to donee 0 - 14
                nounSeek.add{value: minValue}(HEAD, i, ANY_ID, j);
                // Add a request for each head, with any 101, going to donee 0 - 4
                nounSeek.add{value: minValue}(HEAD, i, 101, j);
            }
        }

        // 20 times
        for (uint16 i; i < 20; i++) {
            // Add a request for each glasses, for any id, going to donee 0 - 4
            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any id, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, ANY_ID, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each head, with any 101, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, 101, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each head, with any 100, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, 100, j);
            }
        }

        // HEAD with ANY_ID and Specific Id 101
        uint256[][] memory donationsByTraitId = nounSeek
            .donationsForNounIdByTrait(HEAD, 101);

        assertEq(donationsByTraitId.length, nounSeek.headCount());

        // For all donee slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 donees were requested with ANY_ID and specific
            assertEq(donationsByTraitId[0][i], i < 15 ? minValue * 2 : 0);
            // For Head 99, the first 5 donees were requested with ANY_ID and specific
            assertEq(donationsByTraitId[99][i], i < 15 ? minValue * 2 : 0);
            // For Head 100, no requests were made
            assertEq(donationsByTraitId[100][i], 0);
        }

        // GLASSES with ANY_ID and Specific Id 101
        donationsByTraitId = nounSeek.donationsForNounIdByTrait(GLASSES, 101);

        assertEq(donationsByTraitId.length, nounSeek.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 donees were requested with ANY_ID and specific
            assertEq(donationsByTraitId[0][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 19, the first 5 donees were requested with ANY_ID and specific
            assertEq(donationsByTraitId[19][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 20, no requests were made
            assertEq(donationsByTraitId[20][i], 0);
        }

        // GLASSES with Specific Id 100
        donationsByTraitId = nounSeek.donationsForNounIdByTrait(GLASSES, 100);

        assertEq(donationsByTraitId.length, nounSeek.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 donees were requested with specific id
            assertEq(donationsByTraitId[0][i], i < 15 ? minValue : 0);
            // For Glasses 19, the first 5 donees were requested with specific id
            assertEq(donationsByTraitId[19][i], i < 15 ? minValue : 0);
            // For Glasses 20, no requests were made
            assertEq(donationsByTraitId[20][i], 0);
        }
    }

    function test_DONATIONSFORNEXTNOUNBYTRAIT_NoNonAuctionedNoSpecificID()
        public
    {
        vm.startPrank(user1);

        // For traitIds 0 - 9
        for (uint16 traitId; traitId < 10; traitId++) {
            // add a request for ANY_ID, to donee 0
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 0);
            // add a request for Noun 101, to donee 1
            nounSeek.add{value: minValue}(HEAD, traitId, 101, 1);
            // add a request for Noun 100, to donee 2
            nounSeek.add{value: minValue}(HEAD, traitId, 100, 2);
        }

        uint256 doneesCount = nounSeek.donees().length;

        // Next Noun has No Requests
        mockAuctionHouse.setNounId(98);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        ) = nounSeek.donationsForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionedId, 99);
        assertEq(nextNonAuctionedId, type(uint16).max);

        assertEq(nextAuctionDonations.length, nounSeek.headCount());

        // There is no non-auction Noun, so no slots for donees
        assertEq(nextNonAuctionDonations.length, 0);

        for (uint256 traitId; traitId < 10; traitId++) {
            assertEq(nextAuctionDonations[traitId].length, doneesCount);
            // Check that donee#1 and donnee#2 are zero
            assertEq(nextAuctionDonations[traitId][1], 0);
            assertEq(nextAuctionDonations[traitId][2], 0);
            // Check that donee#0 is minValue because of ANY_ID request
            assertEq(nextAuctionDonations[traitId][0], minValue);
        }
    }

    function test_DONATIONSFORNEXTNOUNBYTRAIT_NonAuctionedAndSpecificID()
        public
    {
        vm.startPrank(user1);

        // For Each trait, except Background

        for (uint16 traitId; traitId < 10; traitId++) {
            // add a request for ANY_ID, to donee 0
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 0);
            // add a request for Noun 101 and ANY_ID, to donee 1
            nounSeek.add{value: minValue}(HEAD, traitId, ANY_ID, 1);
            nounSeek.add{value: minValue}(HEAD, traitId, 101, 1);
            // add a request for Noun 100, to donee 2
            nounSeek.add{value: minValue}(HEAD, traitId, 100, 2);
        }

        uint256 doneesCount = nounSeek.donees().length;

        // Next Noun has Non-Auctioned Noun and Specific Id Requests
        mockAuctionHouse.setNounId(99);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        ) = nounSeek.donationsForUpcomingNounByTrait(HEAD);

        assertEq(nextAuctionedId, 101);
        assertEq(nextNonAuctionedId, 100);

        assertEq(nextAuctionDonations.length, nounSeek.headCount());

        assertEq(nextNonAuctionDonations.length, nounSeek.headCount());

        for (uint256 traitId; traitId < 10; traitId++) {
            assertEq(nextAuctionDonations[traitId].length, doneesCount);

            assertEq(nextNonAuctionDonations[traitId].length, doneesCount);
            // donee#0 only had ANY_ID requests
            assertEq(nextAuctionDonations[traitId][0], minValue);
            // donee#1 had specific ID and ANY_ID requests
            assertEq(nextAuctionDonations[traitId][1], minValue * 2);
            // donee#2 had no requests for ANY_ID or Noun 101
            assertEq(nextAuctionDonations[traitId][2], 0);

            // donee#0 had no requests for Noun 100
            assertEq(nextNonAuctionDonations[traitId][0], 0);
            // donee#1 had no requests for Noun 100
            assertEq(nextNonAuctionDonations[traitId][1], 0);
            // donee#2 had requests for Noun 100
            assertEq(nextNonAuctionDonations[traitId][2], minValue);
        }
    }

    function test_DONATIONSFORCURRENTNOUNBYTRAIT_NoNonAuctionedNoSpecificID()
        public
    {
        vm.startPrank(user1);
        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9

            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to donee 1
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
                // add a request for Noun 100, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }
        uint256 doneesCount = nounSeek.donees().length;

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
            uint256[] memory currentAuctionDonations,
            uint256[] memory prevNonAuctionDonations
        ) = nounSeek.donationsForNounOnAuctionByTrait(GLASSES);

        assertEq(currentAuctionedId, 102);
        assertEq(prevNonAuctionedId, type(uint16).max);

        assertEq(currentAuctionDonations.length, doneesCount);

        // // There is no non-auction Noun, so no slots for donees
        assertEq(prevNonAuctionDonations.length, 0);

        assertEq(currentAuctionDonations[0], minValue);
        assertEq(currentAuctionDonations[1], minValue * 2);
        assertEq(currentAuctionDonations[2], 0);
        assertEq(currentAuctionDonations[3], 0);

        // Current Noun has no matching requests for HEAD
        (, , currentAuctionDonations, prevNonAuctionDonations) = nounSeek
            .donationsForNounOnAuctionByTrait(HEAD);
        assertEq(currentAuctionDonations.length, doneesCount);

        assertEq(currentAuctionDonations[0], 0);
        assertEq(currentAuctionDonations[1], 0);
        assertEq(currentAuctionDonations[2], 0);
        assertEq(currentAuctionDonations[3], 0);
    }

    function test_DONATIONSFORCURRENTNOUNBYTRAIT_NonAuctionedAndSpecificID()
        public
    {
        vm.startPrank(user1);
        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to donee 1
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
                // add a request for Noun 100, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 102, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    102,
                    3
                );
            }
        }
        uint256 doneesCount = nounSeek.donees().length;

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
            uint256[] memory currentAuctionDonations,
            uint256[] memory prevNonAuctionDonations
        ) = nounSeek.donationsForNounOnAuctionByTrait(GLASSES);

        assertEq(currentAuctionedId, 101);
        assertEq(prevNonAuctionedId, 100);

        assertEq(currentAuctionDonations.length, doneesCount);

        assertEq(prevNonAuctionDonations.length, doneesCount);

        assertEq(currentAuctionDonations[0], minValue);
        assertEq(currentAuctionDonations[1], minValue * 2);
        assertEq(currentAuctionDonations[2], 0);
        assertEq(currentAuctionDonations[3], 0);

        // NOUN 100 request were only for donee 2
        assertEq(prevNonAuctionDonations[0], 0);
        assertEq(prevNonAuctionDonations[1], 0);
        assertEq(prevNonAuctionDonations[2], minValue);
        assertEq(prevNonAuctionDonations[3], 0);

        // No requests for match current HEAD
        (, , currentAuctionDonations, prevNonAuctionDonations) = nounSeek
            .donationsForNounOnAuctionByTrait(HEAD);

        assertEq(currentAuctionDonations.length, doneesCount);

        assertEq(prevNonAuctionDonations.length, doneesCount);

        assertEq(currentAuctionDonations[0], 0);
        assertEq(currentAuctionDonations[1], 0);
        assertEq(currentAuctionDonations[2], 0);
        assertEq(currentAuctionDonations[3], 0);

        assertEq(prevNonAuctionDonations[0], 0);
        assertEq(prevNonAuctionDonations[1], 0);
        assertEq(prevNonAuctionDonations[2], 0);
        assertEq(prevNonAuctionDonations[3], 0);
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUNBYTRAIT_AuctionedNoSkip()
        public
    {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to donee 1
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
                // add a request for Noun 100, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 doneesCount = nounSeek.donees().length;

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
            uint256[] memory auctionedNounDonations,
            uint256[] memory nonAuctionedNounDonations,
            uint256 totalDonations,
            uint256 reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(GLASSES);

        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations.length, doneesCount);
        assertEq(nonAuctionedNounDonations.length, 0);

        assertEq(auctionedNounDonations[0], minValue);
        assertEq(auctionedNounDonations[1], minValue * 2);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        uint256 expectedTotal = (minValue * 3) - minReimbursement;
        assertEq(totalDonations, expectedTotal);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounDonations,
            nonAuctionedNounDonations,
            totalDonations,
            reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(HEAD);

        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations.length, doneesCount);
        assertEq(nonAuctionedNounDonations.length, 0);

        assertEq(auctionedNounDonations[0], 0);
        assertEq(auctionedNounDonations[1], 0);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalDonations, 0);
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUNBYTRAIT_AuctionedSkip()
        public
    {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to donee 1
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
                // add a request for Noun 100, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 doneesCount = nounSeek.donees().length;

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
            uint256[] memory auctionedNounDonations,
            uint256[] memory nonAuctionedNounDonations,
            uint256 totalDonations,
            uint256 reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(GLASSES);

        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations.length, doneesCount);

        assertEq(nonAuctionedNounDonations.length, 0);

        uint256 expectedDonation = minValue;
        assertEq(auctionedNounDonations[0], expectedDonation);
        assertEq(auctionedNounDonations[1], expectedDonation * 2);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        uint256 expectedTotalDonation = (minValue * 3) - minReimbursement;
        assertEq(totalDonations, expectedTotalDonation);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounDonations,
            nonAuctionedNounDonations,
            totalDonations,
            reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(HEAD);

        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations.length, doneesCount);

        assertEq(nonAuctionedNounDonations.length, 0);

        assertEq(auctionedNounDonations[0], 0);
        assertEq(auctionedNounDonations[1], 0);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalDonations, 0);
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUNBYTRAIT_NonAuctioned()
        public
    {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to donee 1
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
                // add a request for Noun 100, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to donee 2
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    99,
                    3
                );
            }
        }

        uint256 doneesCount = nounSeek.donees().length;

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
            uint256[] memory auctionedNounDonations,
            uint256[] memory nonAuctionedNounDonations,
            uint256 totalDonations,
            uint256 reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(GLASSES);
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounDonations.length, doneesCount);

        assertEq(nonAuctionedNounDonations.length, doneesCount);

        uint256 expectedDonation = minValue;
        assertEq(auctionedNounDonations[0], expectedDonation);
        assertEq(auctionedNounDonations[1], expectedDonation * 2);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        assertEq(nonAuctionedNounDonations[0], 0);
        assertEq(nonAuctionedNounDonations[1], 0);
        assertEq(nonAuctionedNounDonations[2], expectedDonation);
        assertEq(nonAuctionedNounDonations[3], 0);

        // Minimum value was sent, so minimum reimbursement is applied
        uint256 expectedReimbursement = minReimbursement;
        assertEq(reimbursement, expectedReimbursement);

        // 4 requests total for the trait
        // (1) ANY ID (2) ANY ID (3) 101 specific Id (4) 101 specific id
        uint256 expectedTotalDonation = (minValue * 4) - minReimbursement;
        assertEq(totalDonations, expectedTotalDonation);

        // No requests for match current HEAD
        (
            auctionedNounId,
            nonAuctionedNounId,
            auctionedNounDonations,
            nonAuctionedNounDonations,
            totalDonations,
            reimbursement
        ) = nounSeek.donationsForMatchableNounByTrait(HEAD);
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounDonations.length, doneesCount);

        assertEq(nonAuctionedNounDonations.length, doneesCount);

        assertEq(auctionedNounDonations[0], 0);
        assertEq(auctionedNounDonations[1], 0);
        assertEq(auctionedNounDonations[2], 0);
        assertEq(auctionedNounDonations[3], 0);

        assertEq(nonAuctionedNounDonations[0], 0);
        assertEq(nonAuctionedNounDonations[1], 0);
        assertEq(nonAuctionedNounDonations[2], 0);
        assertEq(nonAuctionedNounDonations[3], 0);

        assertEq(reimbursement, 0);

        assertEq(totalDonations, 0);
    }
}
