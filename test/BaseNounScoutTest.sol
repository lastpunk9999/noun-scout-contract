// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounScoutV2.sol";
import "../src/NounScoutViewUtils.sol";
import "./MockContracts.sol";
import "../src/Interfaces.sol";

contract EnhancedTest is Test {
    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        vm.deal(addr, 10000e18);
        return addr;
    }
}

contract BaseNounScoutTest is EnhancedTest {
    NounScoutV2 nounScout;
    MockNouns mockNouns;
    MockAuctionHouse mockAuctionHouse;
    MockDescriptor mockDescriptor;
    NounScoutViewUtils nounScoutViewUtils;
    uint16[] public allRecipientIds;

    address user1 = mkaddr("user1");
    address user2 = mkaddr("user2");
    address user3 = mkaddr("user3");
    address recipient0 = mkaddr("recipient0");
    address recipient1 = mkaddr("recipient1");
    address recipient2 = mkaddr("recipient2");
    address recipient3 = mkaddr("recipient3");
    address recipient4 = mkaddr("recipient4");
    uint256 AUCTION_END_LIMIT;
    uint16 ANY_AUCTION_ID;
    uint16 ANY_NON_AUCTION_ID;
    uint256 minValue;
    uint256 maxValue;
    uint256 messageValue;
    uint256 baseReimbursementBPS;

    uint256 maxReimbursement;
    uint256 minReimbursement;
    NounScoutV2.Traits HEAD = NounScoutV2.Traits.HEAD;
    NounScoutV2.Traits GLASSES = NounScoutV2.Traits.GLASSES;

    function setUp() public virtual {
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounScout = new NounScoutV2(
            mockNouns,
            mockAuctionHouse,
            IWETH(address(0))
        );
        nounScoutViewUtils = new NounScoutViewUtils(nounScout);

        AUCTION_END_LIMIT = nounScout.AUCTION_END_LIMIT();
        ANY_AUCTION_ID = nounScout.ANY_AUCTION_ID();
        ANY_NON_AUCTION_ID = nounScout.ANY_NON_AUCTION_ID();
        minValue = nounScout.minValue();
        messageValue = nounScout.messageValue();
        baseReimbursementBPS = nounScout.baseReimbursementBPS();
        maxReimbursement = nounScout.maxReimbursement();
        minReimbursement = nounScout.minReimbursement();
        maxValue = (maxReimbursement * 10_000) / baseReimbursementBPS;

        nounScout.addRecipient("recipient0", recipient0, "recipient0");
        nounScout.addRecipient("recipient1", recipient1, "recipient1");
        nounScout.addRecipient("recipient2", recipient2, "recipient2");
        nounScout.addRecipient("recipient3", recipient3, "recipient3");
        nounScout.addRecipient("recipient4", recipient4, "recipient4");

        mockDescriptor.setHeadCount(99);
        mockDescriptor.setGlassesCount(98);
        mockDescriptor.setAccessoryCount(97);
        mockDescriptor.setBodyCount(96);
        mockDescriptor.setBackgroundCount(95);
        nounScout.updateTraitCounts();
        mockAuctionHouse.setNounId(99);
        allRecipientIds = recipientIds(nounScout.recipients().length, 0, 1);
    }

    function recipientIds(
        uint256 length,
        uint16 skip,
        uint16 mul
    ) public pure returns (uint16[] memory _recipientIds) {
        _recipientIds = new uint16[](length);
        for (uint16 i; i < length; i++) {
            _recipientIds[i] = (i * mul) + skip;
        }
    }
}
