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

    function test_PLEDGESFORNOUNBYTRAIT() public {
        vm.startPrank(user1);

        // 100 times
        for (uint16 i; i < 100; i++) {
            // For recipients 0 - 14
            for (uint16 j; j < 15; j++) {
                // Add 2x request for each head, with any id, going to recipient 0 - 14
                nounScout.add{value: minValue * 2}(HEAD, i, ANY_AUCTION_ID, j);
                // Add a request for each head, with any 101, going to recipient 0 - 4
                nounScout.add{value: minValue}(HEAD, i, 101, j);
            }
        }

        // 20 times
        for (uint16 i; i < 20; i++) {
            // Add a request for each glasses, for any id, going to recipient 0 - 4
            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, with any auction id, going to recipient 0 - 14
                nounScout.add{value: minValue}(GLASSES, i, ANY_AUCTION_ID, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add 2x request for each glasses, for ID 101, going to recipient 0 - 14
                nounScout.add{value: minValue * 2}(GLASSES, i, 101, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add a request for each glasses, for ID 100, going to recipient 0 - 14
                nounScout.add{value: minValue}(GLASSES, i, 100, j);
            }

            for (uint16 j; j < 15; j++) {
                // Add 2x request for each glasses, with any auction non id, going to recipient 0 - 14
                nounScout.add{value: minValue * 2}(
                    GLASSES,
                    i,
                    ANY_NON_AUCTION_ID,
                    j
                );
            }
        }

        // HEAD with ANY_AUCTION_ID and Specific Id 101
        uint256[][] memory pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            101,
            true
        );

        assertEq(pledgesByTraitId.length, nounScout.headCount());

        // For all recipient slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 3 : 0);
            // For Head 99, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[99][i], i < 15 ? minValue * 3 : 0);
            // For Head 100, no requests were made
            assertEq(pledgesByTraitId[100][i], 0);
        }

        // HEAD with Specific Id 101 NOT including any auction ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(HEAD, 101, false);

        assertEq(pledgesByTraitId.length, nounScout.headCount());

        // For all recipient slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue : 0);
            // For Head 99, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[99][i], i < 15 ? minValue : 0);
            // For Head 100, no requests were made
            assertEq(pledgesByTraitId[100][i], 0);
        }

        // HEAD ONLY any auction ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            HEAD,
            ANY_AUCTION_ID,
            true
        );

        assertEq(pledgesByTraitId.length, nounScout.headCount());

        // For all recipient slots for next auctioned Noun
        for (uint256 i = 0; i < 20; i++) {
            // For Head 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 2 : 0);
            // For Head 99, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[99][i], i < 15 ? minValue * 2 : 0);
            // For Head 100, no requests were made
            assertEq(pledgesByTraitId[100][i], 0);
        }

        // GLASSES for ID 101 including any auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            101,
            true
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 3 : 0);
            // For Glasses 19, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue * 3 : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }

        // GLASSES for ID 101 NOT including any auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            101,
            false
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 19, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }

        // GLASSES ONLY any auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            ANY_AUCTION_ID,
            true
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue : 0);
            // For Glasses 19, the first 5 recipients were requested with ANY_AUCTION_ID and specific
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }

        // GLASSES for ID 100 including any non auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            100,
            true
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 3 : 0);
            // For Glasses 19, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue * 3 : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }

        // GLASSES for ID 100 NOT including any non auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            100,
            false
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue : 0);
            // For Glasses 19, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }

        // GLASSES ONLY non auctioned ID
        pledgesByTraitId = nounScout.pledgesForNounIdByTrait(
            GLASSES,
            ANY_NON_AUCTION_ID,
            false
        );

        assertEq(pledgesByTraitId.length, nounScout.glassesCount());

        for (uint256 i = 0; i < 20; i++) {
            // For Glasses 0, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[0][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 19, the first 5 recipients were requested with specific id
            assertEq(pledgesByTraitId[19][i], i < 15 ? minValue * 2 : 0);
            // For Glasses 20, no requests were made
            assertEq(pledgesByTraitId[20][i], 0);
        }
    }
}
