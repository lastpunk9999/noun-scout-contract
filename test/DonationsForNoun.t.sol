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

    function test_DONATIONSFORNOUN() public {
        vm.startPrank(user1);

        // 100 HEAD Ids
        for (uint16 i; i < 100; i++) {
            // For donees 0 - 14
            for (uint16 j; j < 15; j++) {
                // Add a request for each head, with any id, going to donee 0 - 14
                nounSeek.add{value: minValue}(HEAD, i, ANY_ID, j);
                // Add a request for each head, with any 101, going to donee 0 - 4
                nounSeek.add{value: minValue}(HEAD, i, 101, j);
            }
        }

        // 20 GLASSES Ids
        for (uint16 i; i < 20; i++) {
            // Add a request for each glasses, for any id, going to donee 0 - 4
            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any id, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, ANY_ID, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any 101, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, 101, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any 100, going to donee 0 - 14
                nounSeek.add{value: minValue}(GLASSES, i, 100, j);
            }
        }

        // ANY_ID and specific Id = 101
        uint256[][][5] memory donations = nounSeek.donationsForNounId(101);

        // For all donee slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 donees were requested with ANY_ID and specific
            assertEq(donations[3][0][i], i < 15 ? minValue * 2 : 0);
            // For Head 99, the first 5 donees were requested with ANY_ID and specific
            assertEq(donations[3][99][i], i < 15 ? minValue * 2 : 0);
            // For Head 100, no requests were made
            assertEq(donations[3][100][i], 0);
        }

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 donees were requested with ANY_ID and specific
            assertEq(donations[4][0][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 19, the first 5 donees were requested with ANY_ID and specific
            assertEq(donations[4][19][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 20, no requests were made
            assertEq(donations[4][20][i], 0);
        }

        // Only specific Id = 100
        donations = nounSeek.donationsForNounId(100);
        for (uint256 i = 0; i < 20; i++) {
            // No HEAD requests
            assertEq(donations[3][0][i], 0);

            // For Glasses 0, the first 5 donees were requested with specific Id
            assertEq(donations[4][0][i], i < 15 ? minValue : 0);
            // For Glasses 19, the first 5 donees were requested with specific Id
            assertEq(donations[4][19][i], i < 15 ? minValue : 0);
            // For Glasses 20, no requests were made
            assertEq(donations[4][20][i], 0);
        }
    }

    function test_DONATIONSFORNEXTNOUN_NoNonAuctionedNoSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to donee 0
                nounSeek.add{value: minValue}(
                    NounSeek.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101, to donee 1
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
            }
        }

        uint256 doneesCount = nounSeek.doneesCount();

        // Next Noun has No Requests
        mockAuctionHouse.setNounId(98);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][][5] memory nextAuctionDonations,
            uint256[][][5] memory nextNonAuctionDonations
        ) = nounSeek.donationsForNextNoun();
        assertEq(nextAuctionedId, 99);
        assertEq(nextNonAuctionedId, type(uint16).max);

        assertEq(nextAuctionDonations[0].length, nounSeek.backgroundCount());
        assertEq(nextAuctionDonations[1].length, nounSeek.bodyCount());
        assertEq(nextAuctionDonations[2].length, nounSeek.accessoryCount());
        assertEq(nextAuctionDonations[3].length, nounSeek.headCount());
        assertEq(nextAuctionDonations[4].length, nounSeek.glassesCount());

        // There is no non-auction Noun, so no slots for traits or donees
        assertEq(nextNonAuctionDonations[0].length, 0);
        assertEq(nextNonAuctionDonations[1].length, 0);
        assertEq(nextNonAuctionDonations[2].length, 0);
        assertEq(nextNonAuctionDonations[3].length, 0);
        assertEq(nextNonAuctionDonations[4].length, 0);

        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionDonations[trait][trait].length, doneesCount);
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // Check that donee#1 and donnee#2 are zero
                assertEq(nextAuctionDonations[trait][traitId][1], 0);
                assertEq(nextAuctionDonations[trait][traitId][2], 0);
                // Check that donee#0 is minValue because of ANY_ID request
                assertEq(nextAuctionDonations[trait][traitId][0], minValue);
            }
        }
    }

    function test_DONATIONSFORNEXTNOUN_NonAuctionedAndSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
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
            }
        }

        uint256 doneesCount = nounSeek.doneesCount();

        // Next Noun has Non-Auctioned Noun and Specific Id Requests
        mockAuctionHouse.setNounId(99);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][][5] memory nextAuctionDonations,
            uint256[][][5] memory nextNonAuctionDonations
        ) = nounSeek.donationsForNextNoun();
        assertEq(nextAuctionedId, 101);
        assertEq(nextNonAuctionedId, 100);

        assertEq(nextAuctionDonations[0].length, nounSeek.backgroundCount());
        assertEq(nextAuctionDonations[1].length, nounSeek.bodyCount());
        assertEq(nextAuctionDonations[2].length, nounSeek.accessoryCount());
        assertEq(nextAuctionDonations[3].length, nounSeek.headCount());
        assertEq(nextAuctionDonations[4].length, nounSeek.glassesCount());

        // There is no non-auction Noun, so no slots for traits or donees
        assertEq(nextNonAuctionDonations[0].length, nounSeek.backgroundCount());
        assertEq(nextNonAuctionDonations[1].length, nounSeek.bodyCount());
        assertEq(nextNonAuctionDonations[2].length, nounSeek.accessoryCount());
        assertEq(nextNonAuctionDonations[3].length, nounSeek.headCount());
        assertEq(nextNonAuctionDonations[4].length, nounSeek.glassesCount());

        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionDonations[trait][trait].length, doneesCount);
            assertEq(nextNonAuctionDonations[trait][trait].length, doneesCount);
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // donee#0 only had ANY_ID requests
                assertEq(nextAuctionDonations[trait][traitId][0], minValue);
                // donee#1 had specific ID and ANY_ID requests
                assertEq(nextAuctionDonations[trait][traitId][1], minValue * 2);
                // donee#2 had no requests for ANY_ID or Noun 101
                assertEq(nextAuctionDonations[trait][traitId][2], 0);

                // donee#0 had no requests for Noun 100
                assertEq(nextNonAuctionDonations[trait][traitId][0], 0);
                // donee#1 had no requests for Noun 100
                assertEq(nextNonAuctionDonations[trait][traitId][1], 0);
                // donee#2 had requests for Noun 100
                assertEq(nextNonAuctionDonations[trait][traitId][2], minValue);
            }
        }
    }

    function test_DONATIONSFORCURRENTNOUN_NoNonAuctionedNoSpecificID() public {
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

        uint256 doneesCount = nounSeek.doneesCount();

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

        // Current Noun has specific ID and ANY_ID requests
        mockAuctionHouse.setNounId(102);
        (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[][5] memory currentAuctionDonations,
            uint256[][5] memory prevNonAuctionDonations
        ) = nounSeek.donationsForCurrentNoun();
        assertEq(currentAuctionedId, 102);
        assertEq(prevNonAuctionedId, type(uint16).max);

        assertEq(currentAuctionDonations[0].length, doneesCount);
        assertEq(currentAuctionDonations[1].length, doneesCount);
        assertEq(currentAuctionDonations[2].length, doneesCount);
        assertEq(currentAuctionDonations[3].length, doneesCount);
        assertEq(currentAuctionDonations[4].length, doneesCount);

        // // There is no non-auction Noun, so no slots for donees
        assertEq(prevNonAuctionDonations[0].length, 0);
        assertEq(prevNonAuctionDonations[1].length, 0);
        assertEq(prevNonAuctionDonations[2].length, 0);
        assertEq(prevNonAuctionDonations[3].length, 0);
        assertEq(prevNonAuctionDonations[4].length, 0);

        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 102 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expected = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(currentAuctionDonations[trait][0], expected);
            assertEq(currentAuctionDonations[trait][1], expected * 2);
            assertEq(currentAuctionDonations[trait][2], 0);
            assertEq(currentAuctionDonations[trait][3], 0);
        }
    }

    function test_DONATIONSFORCURRENTNOUN_NonAuctionedAndSpecificID() public {
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

        uint256 doneesCount = nounSeek.doneesCount();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            1,
            10,
            2,
            10,
            3
        );
        mockNouns.setSeed(seed, 100);
        mockNouns.setSeed(seed, 101);

        // Current Noun has specific ID and ANY_ID requests
        mockAuctionHouse.setNounId(101);
        (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[][5] memory currentAuctionDonations,
            uint256[][5] memory prevNonAuctionDonations
        ) = nounSeek.donationsForCurrentNoun();
        assertEq(currentAuctionedId, 101);
        assertEq(prevNonAuctionedId, 100);

        assertEq(currentAuctionDonations[0].length, doneesCount);
        assertEq(currentAuctionDonations[1].length, doneesCount);
        assertEq(currentAuctionDonations[2].length, doneesCount);
        assertEq(currentAuctionDonations[3].length, doneesCount);
        assertEq(currentAuctionDonations[4].length, doneesCount);

        assertEq(prevNonAuctionDonations[0].length, doneesCount);
        assertEq(prevNonAuctionDonations[1].length, doneesCount);
        assertEq(prevNonAuctionDonations[2].length, doneesCount);
        assertEq(prevNonAuctionDonations[3].length, doneesCount);
        assertEq(prevNonAuctionDonations[4].length, doneesCount);

        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expected = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(currentAuctionDonations[trait][0], expected);
            assertEq(currentAuctionDonations[trait][1], expected * 2);
            assertEq(currentAuctionDonations[trait][2], 0);
            assertEq(currentAuctionDonations[trait][3], 0);

            // NOUN 100 request were only for donee 2
            assertEq(prevNonAuctionDonations[trait][0], 0);
            assertEq(prevNonAuctionDonations[trait][1], 0);
            assertEq(prevNonAuctionDonations[trait][2], expected);
            assertEq(prevNonAuctionDonations[trait][3], 0);
        }
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUN_AuctionedNoSkip()
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

        uint256 doneesCount = nounSeek.doneesCount();

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

        // Current Noun has specific ID and ANY_ID requests
        mockAuctionHouse.setNounId(103);
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[][5] memory auctionedNounDonations,
            uint256[][5] memory nonAuctionedNounDonations,
            uint256[5] memory totalDonationsPerTrait,
            uint256[5] memory reimbursementPerTrait
        ) = nounSeek.donationsAndReimbursementForPreviousNoun();
        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations[0].length, doneesCount);
        assertEq(auctionedNounDonations[1].length, doneesCount);
        assertEq(auctionedNounDonations[2].length, doneesCount);
        assertEq(auctionedNounDonations[3].length, doneesCount);
        assertEq(auctionedNounDonations[4].length, doneesCount);

        assertEq(nonAuctionedNounDonations[0].length, 0);
        assertEq(nonAuctionedNounDonations[1].length, 0);
        assertEq(nonAuctionedNounDonations[2].length, 0);
        assertEq(nonAuctionedNounDonations[3].length, 0);
        assertEq(nonAuctionedNounDonations[4].length, 0);

        assertEq(totalDonationsPerTrait.length, 5);
        assertEq(reimbursementPerTrait.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedDonation = (trait == 1 || trait == 3)
                ? 0
                : minValue;
            assertEq(auctionedNounDonations[trait][0], expectedDonation);
            assertEq(auctionedNounDonations[trait][1], expectedDonation * 2);
            assertEq(auctionedNounDonations[trait][2], 0);
            assertEq(auctionedNounDonations[trait][3], 0);

            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : MIN_REIMBURSEMENT;
            assertEq(reimbursementPerTrait[trait], expectedReimbursement);

            uint256 expectedPerTraitDonation = (trait == 1 || trait == 3)
                ? 0
                : (minValue * 3) - MIN_REIMBURSEMENT;
            assertEq(totalDonationsPerTrait[trait], expectedPerTraitDonation);
        }
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUN_AuctionedSkip()
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

        uint256 doneesCount = nounSeek.doneesCount();

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

        // Current Noun has specific ID and ANY_ID requests
        mockAuctionHouse.setNounId(101);
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[][5] memory auctionedNounDonations,
            uint256[][5] memory nonAuctionedNounDonations,
            uint256[5] memory totalDonationsPerTrait,
            uint256[5] memory reimbursementPerTrait
        ) = nounSeek.donationsAndReimbursementForPreviousNoun();
        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounDonations[0].length, doneesCount);
        assertEq(auctionedNounDonations[1].length, doneesCount);
        assertEq(auctionedNounDonations[2].length, doneesCount);
        assertEq(auctionedNounDonations[3].length, doneesCount);
        assertEq(auctionedNounDonations[4].length, doneesCount);

        assertEq(nonAuctionedNounDonations[0].length, 0);
        assertEq(nonAuctionedNounDonations[1].length, 0);
        assertEq(nonAuctionedNounDonations[2].length, 0);
        assertEq(nonAuctionedNounDonations[3].length, 0);
        assertEq(nonAuctionedNounDonations[4].length, 0);

        assertEq(totalDonationsPerTrait.length, 5);
        assertEq(reimbursementPerTrait.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedDonation = (trait == 1 || trait == 3)
                ? 0
                : minValue;
            assertEq(auctionedNounDonations[trait][0], expectedDonation);
            assertEq(auctionedNounDonations[trait][1], expectedDonation * 2);
            assertEq(auctionedNounDonations[trait][2], 0);
            assertEq(auctionedNounDonations[trait][3], 0);

            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : MIN_REIMBURSEMENT;
            assertEq(reimbursementPerTrait[trait], expectedReimbursement);

            uint256 expectedPerTraitDonation = (trait == 1 || trait == 3)
                ? 0
                : (minValue * 3) - MIN_REIMBURSEMENT;
            assertEq(totalDonationsPerTrait[trait], expectedPerTraitDonation);
        }
    }

    function test_DONATIONSANDREIMBURSEMENTSFORPREVIOUSNOUN_NonAuctioned()
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

        uint256 doneesCount = nounSeek.doneesCount();

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

        // Current Noun has specific ID and ANY_ID requests
        mockAuctionHouse.setNounId(102);
        (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[][5] memory auctionedNounDonations,
            uint256[][5] memory nonAuctionedNounDonations,
            uint256[5] memory totalDonationsPerTrait,
            uint256[5] memory reimbursementPerTrait
        ) = nounSeek.donationsAndReimbursementForPreviousNoun();
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounDonations[0].length, doneesCount);
        assertEq(auctionedNounDonations[1].length, doneesCount);
        assertEq(auctionedNounDonations[2].length, doneesCount);
        assertEq(auctionedNounDonations[3].length, doneesCount);
        assertEq(auctionedNounDonations[4].length, doneesCount);

        assertEq(nonAuctionedNounDonations[0].length, doneesCount);
        assertEq(nonAuctionedNounDonations[1].length, doneesCount);
        assertEq(nonAuctionedNounDonations[2].length, doneesCount);
        assertEq(nonAuctionedNounDonations[3].length, doneesCount);
        assertEq(nonAuctionedNounDonations[4].length, doneesCount);

        assertEq(totalDonationsPerTrait.length, 5);
        assertEq(reimbursementPerTrait.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedDonation = (trait == 1 || trait == 3)
                ? 0
                : minValue;
            assertEq(auctionedNounDonations[trait][0], expectedDonation);
            assertEq(auctionedNounDonations[trait][1], expectedDonation * 2);
            assertEq(auctionedNounDonations[trait][2], 0);
            assertEq(auctionedNounDonations[trait][3], 0);

            assertEq(nonAuctionedNounDonations[trait][0], 0);
            assertEq(nonAuctionedNounDonations[trait][1], 0);
            assertEq(nonAuctionedNounDonations[trait][2], expectedDonation);
            assertEq(nonAuctionedNounDonations[trait][3], 0);

            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : MIN_REIMBURSEMENT;
            assertEq(reimbursementPerTrait[trait], expectedReimbursement);

            // 4 requests total for the trait
            // (1) ANY ID (2) ANY ID (3) 101 specific Id (4) 101 specific id
            uint256 expectedPerTraitDonation = (trait == 1 || trait == 3)
                ? 0
                : (minValue * 4) - MIN_REIMBURSEMENT;
            assertEq(totalDonationsPerTrait[trait], expectedPerTraitDonation);
        }
    }
}
