// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";
import "./BaseNounScoutTest.sol";

contract NounScoutTest is BaseNounScoutTest {
    function setUp() public override {
        BaseNounScoutTest.setUp();
        // Total 20 Recipients
        // Add 5-9
        nounScout.addRecipient("recipient0", recipient0, "");
        nounScout.addRecipient("recipient1", recipient1, "");
        nounScout.addRecipient("recipient2", recipient2, "");
        nounScout.addRecipient("recipient3", recipient3, "");
        nounScout.addRecipient("recipient4", recipient4, "");
        // Add 10-14
        nounScout.addRecipient("recipient0", recipient0, "");
        nounScout.addRecipient("recipient1", recipient1, "");
        nounScout.addRecipient("recipient2", recipient2, "");
        nounScout.addRecipient("recipient3", recipient3, "");
        nounScout.addRecipient("recipient4", recipient4, "");
        // Add 15-19
        nounScout.addRecipient("recipient0", recipient0, "");
        nounScout.addRecipient("recipient1", recipient1, "");
        nounScout.addRecipient("recipient2", recipient2, "");
        nounScout.addRecipient("recipient3", recipient3, "");
        nounScout.addRecipient("recipient4", recipient4, "");

        mockDescriptor.setBackgroundCount(2);
        mockDescriptor.setBodyCount(23);
        mockDescriptor.setAccessoryCount(130);
        mockDescriptor.setHeadCount(242);
        mockDescriptor.setGlassesCount(30);

        nounScout.updateTraitCounts();

        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);

        vm.warp(timestamp);
    }

    function test_PLEDGESFORNOUN() public {
        vm.startPrank(user1);

        // 100 HEAD Ids
        for (uint16 i; i < 100; i++) {
            // For recipients 0 - 14
            for (uint16 j; j < 15; j++) {
                // Add a request for each head, with any id, going to recipient 0 - 14
                nounScout.add{value: minValue}(HEAD, i, ANY_ID, j);
                // Add a request for each head, with any 101, going to recipient 0 - 4
                nounScout.add{value: minValue}(HEAD, i, 101, j);
            }
        }

        // 20 GLASSES Ids
        for (uint16 i; i < 20; i++) {
            // Add a request for each glasses, for any id, going to recipient 0 - 4
            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any id, going to recipient 0 - 14
                nounScout.add{value: minValue}(GLASSES, i, ANY_ID, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any 101, going to recipient 0 - 14
                nounScout.add{value: minValue}(GLASSES, i, 101, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any 100, going to recipient 0 - 14
                nounScout.add{value: minValue}(GLASSES, i, 100, j);
            }
        }

        // ANY_ID and specific Id = 101
        uint256[][][5] memory pledges = nounScout.pledgesForNounId(101);

        // For all recipient slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 recipients were requested with ANY_ID and specific
            assertEq(pledges[3][0][i], i < 15 ? minValue * 2 : 0);
            // For Head 99, the first 5 recipients were requested with ANY_ID and specific
            assertEq(pledges[3][99][i], i < 15 ? minValue * 2 : 0);
            // For Head 100, no requests were made
            assertEq(pledges[3][100][i], 0);
        }

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with ANY_ID and specific
            assertEq(pledges[4][0][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 19, the first 5 recipients were requested with ANY_ID and specific
            assertEq(pledges[4][19][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 20, no requests were made
            assertEq(pledges[4][20][i], 0);
        }

        // Only specific Id = 100
        pledges = nounScout.pledgesForNounId(100);
        for (uint256 i = 0; i < 20; i++) {
            // No HEAD requests
            assertEq(pledges[3][0][i], 0);

            // For Glasses 0, the first 5 recipients were requested with specific Id
            assertEq(pledges[4][0][i], i < 15 ? minValue : 0);
            // For Glasses 19, the first 5 recipients were requested with specific Id
            assertEq(pledges[4][19][i], i < 15 ? minValue : 0);
            // For Glasses 20, no requests were made
            assertEq(pledges[4][20][i], 0);
        }
    }

    function test_PLEDGESFORUPCOMINGNOUN_NoNonAuctionedNoSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

        // Next Noun has No Requests
        mockAuctionHouse.setNounId(98);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][][5] memory nextAuctionPledges,
            uint256[][][5] memory nextNonAuctionPledges
        ) = nounScout.pledgesForUpcomingNoun();
        assertEq(nextAuctionedId, 99);
        assertEq(nextNonAuctionedId, type(uint16).max);

        assertEq(nextAuctionPledges[0].length, nounScout.backgroundCount());
        assertEq(nextAuctionPledges[1].length, nounScout.bodyCount());
        assertEq(nextAuctionPledges[2].length, nounScout.accessoryCount());
        assertEq(nextAuctionPledges[3].length, nounScout.headCount());
        assertEq(nextAuctionPledges[4].length, nounScout.glassesCount());

        // There is no non-auction Noun, so no slots for traits or recipients
        assertEq(nextNonAuctionPledges[0].length, 0);
        assertEq(nextNonAuctionPledges[1].length, 0);
        assertEq(nextNonAuctionPledges[2].length, 0);
        assertEq(nextNonAuctionPledges[3].length, 0);
        assertEq(nextNonAuctionPledges[4].length, 0);

        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionPledges[trait][trait].length, recipientsCount);
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // Check that recipient#1 and recipient#2 are zero
                assertEq(nextAuctionPledges[trait][traitId][1], 0);
                assertEq(nextAuctionPledges[trait][traitId][2], 0);
                // Check that recipient#0 is minValue because of ANY_ID request
                assertEq(nextAuctionPledges[trait][traitId][0], minValue);
            }
        }
    }

    function test_PLEDGESFORUPCOMINGNOUN_NonAuctionedAndSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

        // Next Noun has Non-Auctioned Noun and Specific Id Requests
        mockAuctionHouse.setNounId(99);
        (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][][5] memory nextAuctionPledges,
            uint256[][][5] memory nextNonAuctionPledges
        ) = nounScout.pledgesForUpcomingNoun();
        assertEq(nextAuctionedId, 101);
        assertEq(nextNonAuctionedId, 100);

        assertEq(nextAuctionPledges[0].length, nounScout.backgroundCount());
        assertEq(nextAuctionPledges[1].length, nounScout.bodyCount());
        assertEq(nextAuctionPledges[2].length, nounScout.accessoryCount());
        assertEq(nextAuctionPledges[3].length, nounScout.headCount());
        assertEq(nextAuctionPledges[4].length, nounScout.glassesCount());

        // There is no non-auction Noun, so no slots for traits or recipients
        assertEq(nextNonAuctionPledges[0].length, nounScout.backgroundCount());
        assertEq(nextNonAuctionPledges[1].length, nounScout.bodyCount());
        assertEq(nextNonAuctionPledges[2].length, nounScout.accessoryCount());
        assertEq(nextNonAuctionPledges[3].length, nounScout.headCount());
        assertEq(nextNonAuctionPledges[4].length, nounScout.glassesCount());

        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionPledges[trait][trait].length, recipientsCount);
            assertEq(
                nextNonAuctionPledges[trait][trait].length,
                recipientsCount
            );
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // recipient#0 only had ANY_ID requests
                assertEq(nextAuctionPledges[trait][traitId][0], minValue);
                // recipient#1 had specific ID and ANY_ID requests
                assertEq(nextAuctionPledges[trait][traitId][1], minValue * 2);
                // recipient#2 had no requests for ANY_ID or Noun 101
                assertEq(nextAuctionPledges[trait][traitId][2], 0);

                // recipient#0 had no requests for Noun 100
                assertEq(nextNonAuctionPledges[trait][traitId][0], 0);
                // recipient#1 had no requests for Noun 100
                assertEq(nextNonAuctionPledges[trait][traitId][1], 0);
                // recipient#2 had requests for Noun 100
                assertEq(nextNonAuctionPledges[trait][traitId][2], minValue);
            }
        }
    }

    function test_PLEDGESFORUPCOMINGNOUN_WithInactiveRecipient() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for 99, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    0
                );
                // add a request for ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );

                // add a request for 99, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    1
                );
            }
        }
        vm.stopPrank();

        // set recipient1 inactive
        nounScout.setRecipientActive(1, false);

        // Next Noun matches ANY_ID requests
        mockAuctionHouse.setNounId(98);
        (, , uint256[][][5] memory nextAuctionPledges, ) = nounScout
            .pledgesForUpcomingNoun();

        assertEq(nextAuctionPledges[0].length, nounScout.backgroundCount());
        assertEq(nextAuctionPledges[1].length, nounScout.bodyCount());
        assertEq(nextAuctionPledges[2].length, nounScout.accessoryCount());
        assertEq(nextAuctionPledges[3].length, nounScout.headCount());
        assertEq(nextAuctionPledges[4].length, nounScout.glassesCount());

        uint256 recipientsCount = nounScout.recipients().length;
        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionPledges[trait][trait].length, recipientsCount);
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // recipient0 matches ANY_ID and 98 specified
                assertEq(nextAuctionPledges[trait][traitId][0], minValue * 2);
                // recipient#1 is 0 because inactive
                assertEq(nextAuctionPledges[trait][traitId][1], 0);
            }
        }

        // set recipient1 active
        nounScout.setRecipientActive(1, true);

        mockAuctionHouse.setNounId(98);
        (, , nextAuctionPledges, ) = nounScout.pledgesForUpcomingNoun();

        for (uint256 trait = 0; trait < 5; trait++) {
            // Random check that each traitId has enough slots for each Donnee
            assertEq(nextAuctionPledges[trait][trait].length, recipientsCount);
        }
        for (uint256 trait = 1; trait < 5; trait++) {
            for (uint256 traitId; traitId < 10; traitId++) {
                // recipient0 matches ANY_ID and 98 specified
                assertEq(nextAuctionPledges[trait][traitId][0], minValue * 2);
                // recipient1 now active, matches ANY_ID and 98 specified
                assertEq(nextAuctionPledges[trait][traitId][1], minValue * 2);
            }
        }
    }

    function test_PLEDGESFORNOUNONAUCTION_NoNonAuctionedNoSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    102,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

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
            uint256[][5] memory currentAuctionPledges,
            uint256[][5] memory prevNonAuctionPledges
        ) = nounScout.pledgesForNounOnAuction();
        assertEq(currentAuctionedId, 102);
        assertEq(prevNonAuctionedId, type(uint16).max);

        assertEq(currentAuctionPledges[0].length, recipientsCount);
        assertEq(currentAuctionPledges[1].length, recipientsCount);
        assertEq(currentAuctionPledges[2].length, recipientsCount);
        assertEq(currentAuctionPledges[3].length, recipientsCount);
        assertEq(currentAuctionPledges[4].length, recipientsCount);

        // // There is no non-auction Noun, so no slots for recipients
        assertEq(prevNonAuctionPledges[0].length, 0);
        assertEq(prevNonAuctionPledges[1].length, 0);
        assertEq(prevNonAuctionPledges[2].length, 0);
        assertEq(prevNonAuctionPledges[3].length, 0);
        assertEq(prevNonAuctionPledges[4].length, 0);

        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 102 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expected = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(currentAuctionPledges[trait][0], expected);
            assertEq(currentAuctionPledges[trait][1], expected * 2);
            assertEq(currentAuctionPledges[trait][2], 0);
            assertEq(currentAuctionPledges[trait][3], 0);
        }
    }

    function test_PLEDGESFORNOUNONAUCTION_NonAuctionedAndSpecificID() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 101 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 102, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    102,
                    3
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

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
            uint256[][5] memory currentAuctionPledges,
            uint256[][5] memory prevNonAuctionPledges
        ) = nounScout.pledgesForNounOnAuction();
        assertEq(currentAuctionedId, 101);
        assertEq(prevNonAuctionedId, 100);

        assertEq(currentAuctionPledges[0].length, recipientsCount);
        assertEq(currentAuctionPledges[1].length, recipientsCount);
        assertEq(currentAuctionPledges[2].length, recipientsCount);
        assertEq(currentAuctionPledges[3].length, recipientsCount);
        assertEq(currentAuctionPledges[4].length, recipientsCount);

        assertEq(prevNonAuctionPledges[0].length, recipientsCount);
        assertEq(prevNonAuctionPledges[1].length, recipientsCount);
        assertEq(prevNonAuctionPledges[2].length, recipientsCount);
        assertEq(prevNonAuctionPledges[3].length, recipientsCount);
        assertEq(prevNonAuctionPledges[4].length, recipientsCount);

        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expected = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(currentAuctionPledges[trait][0], expected);
            assertEq(currentAuctionPledges[trait][1], expected * 2);
            assertEq(currentAuctionPledges[trait][2], 0);
            assertEq(currentAuctionPledges[trait][3], 0);

            // NOUN 100 request were only for recipient 2
            assertEq(prevNonAuctionPledges[trait][0], 0);
            assertEq(prevNonAuctionPledges[trait][1], 0);
            assertEq(prevNonAuctionPledges[trait][2], expected);
            assertEq(prevNonAuctionPledges[trait][3], 0);
        }
    }

    function test_PLEDGESFORNOUNONAUCTION_WithInactiveRecipient() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for 99, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    0
                );
                // add a request for ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );

                // add a request for 99, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    1
                );
            }
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            1,
            2,
            3,
            4
        );
        mockNouns.setSeed(seed, 99);

        // set recipient1 inactive
        nounScout.setRecipientActive(1, false);
        (, , uint256[][5] memory currentAuctionPledges, ) = nounScout
            .pledgesForNounOnAuction();

        uint256 recipientsCount = nounScout.recipients().length;

        assertEq(currentAuctionPledges[0].length, recipientsCount);
        assertEq(currentAuctionPledges[1].length, recipientsCount);
        assertEq(currentAuctionPledges[2].length, recipientsCount);
        assertEq(currentAuctionPledges[3].length, recipientsCount);
        assertEq(currentAuctionPledges[4].length, recipientsCount);

        // recipient0 has values
        assertEq(currentAuctionPledges[1][0], minValue * 2);
        assertEq(currentAuctionPledges[2][0], minValue * 2);
        assertEq(currentAuctionPledges[3][0], minValue * 2);
        assertEq(currentAuctionPledges[4][0], minValue * 2);

        // recipient1 has no values because it is inactive
        assertEq(currentAuctionPledges[1][1], 0);
        assertEq(currentAuctionPledges[2][1], 0);
        assertEq(currentAuctionPledges[3][1], 0);
        assertEq(currentAuctionPledges[4][1], 0);

        // set recipient1 active
        nounScout.setRecipientActive(1, true);

        (, , currentAuctionPledges, ) = nounScout.pledgesForNounOnAuction();

        // recipient1 has values reset because it is now active
        assertEq(currentAuctionPledges[1][1], minValue * 2);
        assertEq(currentAuctionPledges[2][1], minValue * 2);
        assertEq(currentAuctionPledges[3][1], minValue * 2);
        assertEq(currentAuctionPledges[4][1], minValue * 2);
    }

    function test_PLEDGESFORMATCHABLENOUN_AuctionedNoSkip() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    102,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

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
            uint256[][5] memory auctionedNounPledges,
            uint256[][5] memory nonAuctionedNounPledges,
            uint256[5] memory auctionNounTotalReimbursement,
            uint256[5] memory nonAuctionNounTotalReimbursement
        ) = nounScout.pledgesForMatchableNoun();
        assertEq(auctionedNounId, 102);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges[0].length, recipientsCount);
        assertEq(auctionedNounPledges[1].length, recipientsCount);
        assertEq(auctionedNounPledges[2].length, recipientsCount);
        assertEq(auctionedNounPledges[3].length, recipientsCount);
        assertEq(auctionedNounPledges[4].length, recipientsCount);

        assertEq(nonAuctionedNounPledges[0].length, 0);
        assertEq(nonAuctionedNounPledges[1].length, 0);
        assertEq(nonAuctionedNounPledges[2].length, 0);
        assertEq(nonAuctionedNounPledges[3].length, 0);
        assertEq(nonAuctionedNounPledges[4].length, 0);

        assertEq(auctionNounTotalReimbursement.length, 5);
        assertEq(nonAuctionNounTotalReimbursement.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedPledge = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(auctionedNounPledges[trait][0], expectedPledge);
            assertEq(auctionedNounPledges[trait][1], expectedPledge * 2);
            assertEq(auctionedNounPledges[trait][2], 0);
            assertEq(auctionedNounPledges[trait][3], 0);

            // Auctioned Noun
            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : minReimbursement;
            assertEq(
                auctionNounTotalReimbursement[trait],
                expectedReimbursement
            );

            // Non-Auctioned Noun
            assertEq(nonAuctionNounTotalReimbursement[trait], 0);
        }
    }

    function test_PLEDGESFORMATCHABLENOUN_AuctionedSkip() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    1
                );
                // add a request for Noun 100, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    3
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

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
            uint256[][5] memory auctionedNounPledges,
            uint256[][5] memory nonAuctionedNounPledges,
            uint256[5] memory auctionNounTotalReimbursement,
            uint256[5] memory nonAuctionNounTotalReimbursement
        ) = nounScout.pledgesForMatchableNoun();
        assertEq(auctionedNounId, 99);
        assertEq(nonAuctionedNounId, type(uint16).max);

        assertEq(auctionedNounPledges[0].length, recipientsCount);
        assertEq(auctionedNounPledges[1].length, recipientsCount);
        assertEq(auctionedNounPledges[2].length, recipientsCount);
        assertEq(auctionedNounPledges[3].length, recipientsCount);
        assertEq(auctionedNounPledges[4].length, recipientsCount);

        assertEq(nonAuctionedNounPledges[0].length, 0);
        assertEq(nonAuctionedNounPledges[1].length, 0);
        assertEq(nonAuctionedNounPledges[2].length, 0);
        assertEq(nonAuctionedNounPledges[3].length, 0);
        assertEq(nonAuctionedNounPledges[4].length, 0);

        assertEq(auctionNounTotalReimbursement.length, 5);
        assertEq(nonAuctionNounTotalReimbursement.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedPledge = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(auctionedNounPledges[trait][0], expectedPledge);
            assertEq(auctionedNounPledges[trait][1], expectedPledge * 2);
            assertEq(auctionedNounPledges[trait][2], 0);
            assertEq(auctionedNounPledges[trait][3], 0);

            // Auctioned Noun
            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : minReimbursement;
            assertEq(
                auctionNounTotalReimbursement[trait],
                expectedReimbursement
            );

            // Non-Auctioned Noun
            assertEq(nonAuctionNounTotalReimbursement[trait], 0);
        }
    }

    function test_PLEDGESFORMATCHABLENOUN_NonAuctioned() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // BACKGROUND has only 2 variations
                if (trait == 0 && traitId > 1) continue;
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for Noun 102 and ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    101,
                    1
                );
                // add a maxValue request for Noun 100, to recipient 2
                nounScout.add{value: maxValue}(
                    NounScout.Traits(trait),
                    traitId,
                    100,
                    2
                );

                // add a request for Noun 101, to recipient 2
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    99,
                    3
                );
            }
        }

        uint256 recipientsCount = nounScout.recipients().length;

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
            uint256[][5] memory auctionedNounPledges,
            uint256[][5] memory nonAuctionedNounPledges,
            uint256[5] memory auctionNounTotalReimbursement,
            uint256[5] memory nonAuctionNounTotalReimbursement
        ) = nounScout.pledgesForMatchableNoun();
        assertEq(auctionedNounId, 101);
        assertEq(nonAuctionedNounId, 100);

        assertEq(auctionedNounPledges[0].length, recipientsCount);
        assertEq(auctionedNounPledges[1].length, recipientsCount);
        assertEq(auctionedNounPledges[2].length, recipientsCount);
        assertEq(auctionedNounPledges[3].length, recipientsCount);
        assertEq(auctionedNounPledges[4].length, recipientsCount);

        assertEq(nonAuctionedNounPledges[0].length, recipientsCount);
        assertEq(nonAuctionedNounPledges[1].length, recipientsCount);
        assertEq(nonAuctionedNounPledges[2].length, recipientsCount);
        assertEq(nonAuctionedNounPledges[3].length, recipientsCount);
        assertEq(nonAuctionedNounPledges[4].length, recipientsCount);

        assertEq(auctionNounTotalReimbursement.length, 5);
        assertEq(nonAuctionNounTotalReimbursement.length, 5);
        for (uint256 trait; trait < 5; trait++) {
            // The BODY and HEAD trait of the seed for Noun 101 do not match any requests which were for traitIds less than 10
            // These are expected to be 0
            uint256 expectedPledge = (trait == 1 || trait == 3) ? 0 : minValue;
            assertEq(auctionedNounPledges[trait][0], expectedPledge);
            assertEq(auctionedNounPledges[trait][1], expectedPledge * 2);
            assertEq(auctionedNounPledges[trait][2], 0);
            assertEq(auctionedNounPledges[trait][3], 0);

            expectedPledge = (trait == 1 || trait == 3) ? 0 : maxValue;
            assertEq(nonAuctionedNounPledges[trait][0], 0);
            assertEq(nonAuctionedNounPledges[trait][1], 0);
            assertEq(nonAuctionedNounPledges[trait][2], expectedPledge);
            assertEq(nonAuctionedNounPledges[trait][3], 0);

            // Auctioned Noun
            // Minimum value was sent, so minimum reimbursement is applied
            uint256 expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : minReimbursement;
            assertEq(
                auctionNounTotalReimbursement[trait],
                expectedReimbursement
            );

            // Non-Auctioned Noun
            // Maximum value was sent (that can be reimbursed), so max reimbursement is applied
            expectedReimbursement = (trait == 1 || trait == 3)
                ? 0
                : maxReimbursement;
            assertEq(
                nonAuctionNounTotalReimbursement[trait],
                expectedReimbursement
            );
        }
    }

    function test_PLEDGESFORMATCHABLENOUN_WithInactiveRecipient() public {
        vm.startPrank(user1);

        // For Each trait, except Background
        for (uint16 trait = 1; trait < 5; trait++) {
            // For traitIds 0 - 9
            for (uint16 traitId; traitId < 10; traitId++) {
                // add a request for ANY_ID, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    0
                );
                // add a request for 99, to recipient 0
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    98,
                    0
                );
                // add a request for ANY_ID, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    ANY_ID,
                    1
                );

                // add a request for 99, to recipient 1
                nounScout.add{value: minValue}(
                    NounScout.Traits(trait),
                    traitId,
                    98,
                    1
                );
            }
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            1,
            2,
            3,
            4
        );
        mockNouns.setSeed(seed, 98);
        mockAuctionHouse.setNounId(99);

        // set recipient1 inactive
        nounScout.setRecipientActive(1, false);

        (
            ,
            ,
            uint256[][5] memory auctionedNounPledges,
            ,
            uint256[5] memory auctionNounTotalReimbursement,

        ) = nounScout.pledgesForMatchableNoun();

        uint256 recipientsCount = nounScout.recipients().length;

        assertEq(auctionedNounPledges[0].length, recipientsCount);
        assertEq(auctionedNounPledges[1].length, recipientsCount);
        assertEq(auctionedNounPledges[2].length, recipientsCount);
        assertEq(auctionedNounPledges[3].length, recipientsCount);
        assertEq(auctionedNounPledges[4].length, recipientsCount);

        // recipient0 has values
        assertEq(auctionedNounPledges[1][0], minValue * 2);
        assertEq(auctionedNounPledges[2][0], minValue * 2);
        assertEq(auctionedNounPledges[3][0], minValue * 2);
        assertEq(auctionedNounPledges[4][0], minValue * 2);

        // recipient1 has no values because it is inactive
        assertEq(auctionedNounPledges[1][1], 0);
        assertEq(auctionedNounPledges[2][1], 0);
        assertEq(auctionedNounPledges[3][1], 0);
        assertEq(auctionedNounPledges[4][1], 0);

        assertEq(auctionNounTotalReimbursement[1], minReimbursement);
        assertEq(auctionNounTotalReimbursement[2], minReimbursement);
        assertEq(auctionNounTotalReimbursement[3], minReimbursement);
        assertEq(auctionNounTotalReimbursement[4], minReimbursement);

        // set recipient1 active
        nounScout.setRecipientActive(1, true);

        (
            ,
            ,
            auctionedNounPledges,
            ,
            auctionNounTotalReimbursement,

        ) = nounScout.pledgesForMatchableNoun();

        // recipient0 has values
        assertEq(auctionedNounPledges[1][0], minValue * 2);
        assertEq(auctionedNounPledges[2][0], minValue * 2);
        assertEq(auctionedNounPledges[3][0], minValue * 2);
        assertEq(auctionedNounPledges[4][0], minValue * 2);

        // recipient1 has values because it is now active
        assertEq(auctionedNounPledges[1][1], minValue * 2);
        assertEq(auctionedNounPledges[2][1], minValue * 2);
        assertEq(auctionedNounPledges[3][1], minValue * 2);
        assertEq(auctionedNounPledges[4][1], minValue * 2);

        assertEq(auctionNounTotalReimbursement[1], minReimbursement);
        assertEq(auctionNounTotalReimbursement[2], minReimbursement);
        assertEq(auctionNounTotalReimbursement[3], minReimbursement);
        assertEq(auctionNounTotalReimbursement[4], minReimbursement);
    }
}
