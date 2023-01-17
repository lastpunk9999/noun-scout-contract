// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

/* Deploy NounScout */
contract TestnetDeploy1 is Script {
    NounScout nounScout;
    MockNouns mockNouns = MockNouns(0x84dF24AcbB4eB6ffC1e8E2F281bB43feee7E4254);
    MockAuctionHouse mockAuctionHouse =
        MockAuctionHouse(0x37B8e93b956D4271a05A30CB56cfd2D1550ea816);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        nounScout = new NounScout(
            mockNouns,
            mockAuctionHouse,
            IWETH(address(0))
        );

        vm.stopBroadcast();
        console2.log("nounScout", address(nounScout));
    }
}
