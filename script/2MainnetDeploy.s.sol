// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";

/* Add Recipients */
contract MainnetDeploy2 is Script {
    NounScoutV2 nounScout = NounScoutV2(0x30Dc2c9F7FC9aFEcd4f8146ba2461D81B7C1De5e);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // https://freedom.press/donate/cryptocurrency/
        nounScout.addRecipient(
            "Freedom Of The Press Foundation",
            0x998F25Be40241CA5D8F5fCaF3591B5ED06EF3Be7,
            "Freedom of the Press Foundation is a 501(c)(3) non-profit organization that protects, defends, and empowers public-interest journalism in the 21st century."
        );

        // https://archive.org/donate/cryptocurrency/
        nounScout.addRecipient(
            "Internet Archive",
            0x1B40ed3d89fd40f875bF62A0ce79f562714d011E,
            "The Internet Archive, a 501(c)(3) non-profit, is building a digital library of Internet sites and other cultural artifacts in digital form."
        );

        // https://rainforestfoundation.org/engage/give/cryptocurrency/
        nounScout.addRecipient(
            "Rainforest Foundation US",
            0x338326660F32319E2B0Ad165fcF4a528c1994aCb,
            "The mission of the Rainforest Foundation is to support indigenous and traditional peoples of the world's rainforests in their efforts to protect their environment and fulfill their rights."
        );

        // https://donate.torproject.org/cryptocurrency/
        nounScout.addRecipient(
            "Tor Project",
            0x532Fb5D00f40ced99B16d1E295C77Cda2Eb1BB4F,
            "The Tor Project, a 501(c)(3) US nonprofit, believes everyone should be able to explore the internet with privacy. We advance human rights and defend your privacy online through free software and open networks."
        );

        vm.stopBroadcast();
    }
}
