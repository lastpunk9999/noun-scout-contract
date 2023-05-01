// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

/* Add Mock Recipients */
contract TestnetDeploy2 is Script {
    NounScoutV2 nounScout = NounScoutV2(0x8622C77d8fC1c0Cc593AAD46db53d4C8fB138bd3);
    MockNouns mockNouns = MockNouns(0x84dF24AcbB4eB6ffC1e8E2F281bB43feee7E4254);
    MockAuctionHouse mockAuctionHouse =
        MockAuctionHouse(0x37B8e93b956D4271a05A30CB56cfd2D1550ea816);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        nounScout.addRecipient(
            "Freedom Of The Press Foundation",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Freedom Of The Press Foundation is a non-profit organization."
        );
        nounScout.addRecipient(
            "Internet Archive",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Internet Archive is a non-profit organization."
        );
        nounScout.addRecipient(
            "Rainforest Foundation US",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Rainforest Foundation US is a non-profit organization."
        );
        nounScout.addRecipient(
            "Tor Project",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Tor Project is a non-profit organization."
        );

        nounScout.addRecipient(
            "No logo Recipient",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "No logo Recipient Center is a non-profit organization."
        );
        nounScout.addRecipient(
            "Inactive Recipient",
            0x8A6636Af3e6B3589fDdf09611Db7d030A8532943,
            "Inactive Recipient Center is a non-profit organization."
        );

        vm.stopBroadcast();
    }
}
