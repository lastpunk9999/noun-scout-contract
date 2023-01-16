// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

contract TestnetDeploy is Script {
    NounSeek nounSeek;
    MockNouns mockNouns = MockNouns(0x84dF24AcbB4eB6ffC1e8E2F281bB43feee7E4254);
    MockAuctionHouse mockAuctionHouse =
        MockAuctionHouse(0x37B8e93b956D4271a05A30CB56cfd2D1550ea816);

    // MockDescriptor mockDescriptor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // mockAuctionHouse = new MockAuctionHouse();
        // mockDescriptor = new MockDescriptor();
        // mockNouns = new MockNouns(address(mockDescriptor));
        // nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));
        // Add Recipients
        nounSeek.addRecipient(
            "Freedom Of The Press Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Freedom Of The Press Foundation is a non-profit organization."
        );
        nounSeek.addRecipient(
            "Internet Archive",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Internet Archive is a non-profit organization."
        );
        nounSeek.addRecipient(
            "Rainforest Foundation US",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Rainforest Foundation US is a non-profit organization."
        );
        nounSeek.addRecipient(
            "Tor Project",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Tor Project is a non-profit organization."
        );

        nounSeek.addRecipient(
            "No logo Recipient",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "No logo Recipient Center is a non-profit organization."
        );
        nounSeek.addRecipient(
            "Inactive Recipient",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Inactive Recipient Center is a non-profit organization."
        );
        // nounSeek.addRecipient(
        //     "Alzheimer's Association",
        //     0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
        //     "Alzheimer's Association is a non-profit organization."
        // );
        // nounSeek.addRecipient(
        //     "Breast Cancer Research Foundation",
        //     0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
        //     "Breast Cancer Research Foundation is a non-profit organization."
        // );
        // nounSeek.addRecipient(
        //     "National Kidney Foundation",
        //     0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
        //     "National Kidney Foundation is a non-profit organization."
        // );
        // nounSeek.addRecipient(
        //     "Freedom Of The Press Foundation",
        //     0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
        //     "Freedom Of The Press Foundation is a non-profit organization."
        // );

        // setup Traits
        // mockDescriptor.setHeadCount(242);
        // nounSeek.updateTraitCounts();
        mockAuctionHouse.setNounId(99);
        mockAuctionHouse.setEndTime(9999999999);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            1,
            2,
            9,
            3
        );

        mockNouns.setSeed(seed, 98);

        uint256 minValue = 0.0001 ether;
        nounSeek.setMinReimbursement(minValue / 10);
        nounSeek.setMinValue(minValue);
        nounSeek.setRecipientActive(5, false);
        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 recipientId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i,
                0,
                i % 4,
                "Bowsprit crimp pillage weigh anchor rigging chantey quarter lee jack pirate"
            );
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 recipientId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i + 10,
                100,
                i % 4,
                "Stern ballast rope's end ahoy lookout scourge of the seven seas aye jolly boat log piracy"
            );
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 recipientId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i + 20,
                101,
                i % 4,
                "Coxswain fore starboard weigh anchor rope's end sutler hang the jib execution dock marooned yo-ho-ho"
            );
        }

        // Add other Trait Requests
        for (uint16 i; i < 20; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 recipientId*/
            uint16 trait = i % 4;
            uint16 traitId = i % 7;
            // background only has 2 ids
            if (trait == 0) {
                traitId = i % 2;
            }
            // make sure there are no head requests
            if (trait == 3) {
                trait = 4;
            }
            NounSeek.Traits traitEnum = NounSeek.Traits(trait);
            nounSeek.addWithMessage{value: minValue * 2}(
                traitEnum,
                traitId,
                0,
                i % 4,
                "Chase Yellow Jack fathom pirate quarterdeck crow's nest heave to salmagundi piracy draught"
            );
        }

        vm.stopBroadcast();

        console2.log("mockAuctionHouse", address(mockAuctionHouse));
        // console2.log("mockDescriptor", address(mockDescriptor));
        console2.log("mockNouns", address(mockNouns));
        console2.log("nounSeek", address(nounSeek));
    }
}
