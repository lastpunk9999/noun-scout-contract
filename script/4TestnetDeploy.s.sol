// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

/* Add Mock Requets */
contract TestnetDeploy4 is Script {
    NounScout nounScout = NounScout(0xf070A06F603D5c36A1aF8a44641e3d583dcD8307);
    MockNouns mockNouns = MockNouns(0x84dF24AcbB4eB6ffC1e8E2F281bB43feee7E4254);
    MockAuctionHouse mockAuctionHouse =
        MockAuctionHouse(0x37B8e93b956D4271a05A30CB56cfd2D1550ea816);

    // MockDescriptor mockDescriptor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        uint256 value = nounScout.minValue() + nounScout.messageValue();

        for (uint16 i; i < 10; i++) {
            /*
            Traits trait,
            uint16 traitId,
            uint16 nounId,
            uint16 recipientId*/
            nounScout.addWithMessage{value: value}(
                NounScout.Traits.HEAD,
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
            nounScout.addWithMessage{value: value}(
                NounScout.Traits.HEAD,
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
            nounScout.addWithMessage{value: value}(
                NounScout.Traits.HEAD,
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
            NounScout.Traits traitEnum = NounScout.Traits(trait);
            nounScout.addWithMessage{value: value}(
                traitEnum,
                traitId,
                0,
                i % 4,
                "Chase Yellow Jack fathom pirate quarterdeck crow's nest heave to salmagundi piracy draught"
            );
        }

        vm.stopBroadcast();
    }
}
