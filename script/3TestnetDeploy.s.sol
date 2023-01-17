// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScout.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

/* Set Mock Auction and Mock seeds*/
contract TestnetDeploy3 is Script {
    NounScout nounScout = NounScout(0xf070A06F603D5c36A1aF8a44641e3d583dcD8307);
    MockNouns mockNouns = MockNouns(0x84dF24AcbB4eB6ffC1e8E2F281bB43feee7E4254);
    MockAuctionHouse mockAuctionHouse =
        MockAuctionHouse(0x37B8e93b956D4271a05A30CB56cfd2D1550ea816);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

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
        nounScout.setMinReimbursement(minValue / 10);
        nounScout.setMinValue(minValue);
        nounScout.setMessageValue(minValue);
        nounScout.setRecipientActive(5, false);

        vm.stopBroadcast();
    }
}
