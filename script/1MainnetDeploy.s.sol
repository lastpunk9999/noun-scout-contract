// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";
import "../src/Interfaces.sol";

/* Deploy NounScoutV2 */
contract MainnetDeploy1 is Script {
    NounScoutV2 nounScout;
    INounsTokenLike nouns =
        INounsTokenLike(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
    INounsAuctionHouseLike auctionHouse =
        INounsAuctionHouseLike(0x830BD73E4184ceF73443C15111a1DF14e495C706);
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        nounScout = new NounScoutV2(nouns, auctionHouse, weth);

        vm.stopBroadcast();
        console2.log("nounScout", address(nounScout));
    }
}
