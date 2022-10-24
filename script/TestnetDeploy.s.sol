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
            "donee1",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee2",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee3",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee4",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee5",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee6",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee7",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee8",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee9",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );
        nounSeek.addDonee(
            "donee10",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            ""
        );

        // setup Traits
        mockDescriptor.setHeadCount(242);
        nounSeek.updateTraitCounts();
        mockAuctionHouse.setNounId(99);

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.add{value: 10}(NounSeek.Traits.HEAD, i, 0, i % 10);
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.add{value: 10}(NounSeek.Traits.HEAD, i + 10, 100, i % 10);
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.add{value: 10}(NounSeek.Traits.HEAD, i + 20, 101, i % 10);
        }

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 doneeId*/
            nounSeek.add{value: 10}(NounSeek.Traits.HEAD, 0, 0, i % 10);
        }

        vm.stopBroadcast();

        console2.log("mockAuctionHouse", address(mockAuctionHouse));
        console2.log("mockDescriptor", address(mockDescriptor));
        console2.log("mockNouns", address(mockNouns));
        console2.log("nounSeek", address(nounSeek));
    }
}
