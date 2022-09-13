// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

contract TestnetUpdate is Script {
    NounSeek nounSeek = NounSeek(0xeB84D22a052F7a6Ff2A5288a40819dF1747Ad840);

    // MockAuctionHouse mockAuctionHouse =
    //     MockAuctionHouse(0x5e291edAf07F9131757b13DF5abD1c7D48634Ed3);
    // MockDescriptor mockDescriptor =
    //     MockDescriptor(0x1Bc39C637e05398c0Fc320c0B2388A0DED0e05D5);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        for (uint16 i; i < 30; i++) {
            nounSeek.add{value: 10}(NounSeek.Traits.HEAD, i, 0, i % 10);
        }
        // nounSeek.addDonee("donee1", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee2", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee3", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee4", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee5", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee6", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee7", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee8", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee("donee9", 0x8A6636Af3e6B3589fDdf09611Db7d030A8532943);
        // nounSeek.addDonee(
        //     "donee10",
        //     0x8A6636Af3e6B3589fDdf09611Db7d030A8532943
        // );
        // mockDescriptor.setHeadCount(242);
        // nounSeek.updateTraitCounts();
        // mockAuctionHouse.setNounId(99);
        vm.stopBroadcast();
    }
}
