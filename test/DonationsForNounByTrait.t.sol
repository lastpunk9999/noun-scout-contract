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
}
