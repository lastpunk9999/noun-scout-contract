// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

contract TestnetDeploy is Script {
    NounSeek nounSeek;
    MockNouns mockNouns;
    MockAuctionHouse mockAuctionHouse;
    MockDescriptor mockDescriptor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));

        // Add Donees
        nounSeek.addDonee(
            "Morris Animal Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Morris Animal Foundation is a non-profit organization."
        );
        nounSeek.addDonee(
            "Leukemia & Lymphoma Society",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Leukemia & Lymphoma Society is a non-profit organization."
        );
        nounSeek.addDonee(
            "Center for Biological Diversity",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Center for Biological Diversity is a non-profit organization."
        );
        nounSeek.addDonee(
            "African Wildlife Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "African Wildlife Foundation is a non-profit organization."
        );
        nounSeek.addDonee(
            "Michael J. Fox Foundation for Parkinson's Research",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Michael J. Fox Foundation for Parkinson's Research is a non-profit organization."
        );
        nounSeek.addDonee(
            "Marine Mammal Center",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Marine Mammal Center is a non-profit organization."
        );
        nounSeek.addDonee(
            "Alzheimer's Association",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Alzheimer's Association is a non-profit organization."
        );
        nounSeek.addDonee(
            "Breast Cancer Research Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Breast Cancer Research Foundation is a non-profit organization."
        );
        nounSeek.addDonee(
            "National Kidney Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "National Kidney Foundation is a non-profit organization."
        );
        nounSeek.addDonee(
            "Freedom Of The Press Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Freedom Of The Press Foundation is a non-profit organization."
        );

        // setup Traits
        mockDescriptor.setHeadCount(242);
        nounSeek.updateTraitCounts();
        mockAuctionHouse.setNounId(99);
        mockAuctionHouse.setEndTime(9999999999);
        uint256 minValue = 1 gwei;
        nounSeek.setMinValue(minValue);

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i,
                0,
                i % 10,
                "Bowsprit crimp pillage weigh anchor rigging chantey quarter lee jack pirate"
            );
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i + 10,
                100,
                i % 10,
                "Stern ballast rope's end ahoy lookout scourge of the seven seas aye jolly boat log piracy"
            );
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                i + 20,
                101,
                i % 10,
                "Coxswain fore starboard weigh anchor rope's end sutler hang the jib execution dock marooned yo-ho-ho"
            );
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.addWithMessage{value: minValue * 2}(
                NounSeek.Traits.HEAD,
                0,
                0,
                i % 10,
                "Chase Yellow Jack fathom pirate quarterdeck crow's nest heave to salmagundi piracy draught"
            );
        }

        vm.stopBroadcast();

        console2.log("mockAuctionHouse", address(mockAuctionHouse));
        console2.log("mockDescriptor", address(mockDescriptor));
        console2.log("mockNouns", address(mockNouns));
        console2.log("nounSeek", address(nounSeek));
    }
}
