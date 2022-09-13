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
        vm.stopBroadcast();
        console2.log("mockAuctionHouse", address(mockAuctionHouse));
        console2.log("mockDescriptor", address(mockDescriptor));
        console2.log("mockNouns", address(mockNouns));
        console2.log("nounSeek", address(nounSeek));
    }
}
