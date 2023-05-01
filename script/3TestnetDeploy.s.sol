// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";
import "../test/MockContracts.sol";
import "../src/Interfaces.sol";

/* Set Mock Auction and Mock seeds*/
contract TestnetDeploy3 is Script {
    NounScoutV2 nounScout = NounScoutV2(0x8622C77d8fC1c0Cc593AAD46db53d4C8fB138bd3);
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
