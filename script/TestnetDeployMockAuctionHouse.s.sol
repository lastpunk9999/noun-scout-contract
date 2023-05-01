// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

contract TestnetDeployMockAuctionHouse is Script {
    MockAuctionHouse mockAuctionHouse;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        mockAuctionHouse = new MockAuctionHouse();
        vm.stopBroadcast();

        console2.log("mockAuctionHouse", address(mockAuctionHouse));
    }
}
