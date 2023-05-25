// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

contract TestnetDeployMockNouns is Script {
    MockNouns mockNouns;
    MockDescriptor mockDescriptor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        mockDescriptor = new MockDescriptor();
        mockDescriptor.setBackgroundCount(2);
        mockDescriptor.setBodyCount(30);
        mockDescriptor.setAccessoryCount(140);
        mockDescriptor.setHeadCount(242);
        mockDescriptor.setGlassesCount(23);

        mockNouns = new MockNouns(address(mockDescriptor));
        vm.stopBroadcast();

        console2.log("mockNouns", address(mockNouns));
    }
}
