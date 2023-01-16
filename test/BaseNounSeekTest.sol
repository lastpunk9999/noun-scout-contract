pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "../src/NounSeekViewUtils.sol";
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

contract BaseNounSeekTest is EnhancedTest {
    NounSeek nounSeek;
    MockNouns mockNouns;
    MockAuctionHouse mockAuctionHouse;
    MockDescriptor mockDescriptor;
    NounSeekViewUtils nounSeekViewUtils;
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
    uint16 ANY_ID;
    uint256 minValue;
    uint256 maxValue;
    uint256 messageValue;
    uint256 baseReimbursementBPS;

    uint256 maxReimbursement;
    uint256 minReimbursement;
    NounSeek.Traits HEAD = NounSeek.Traits.HEAD;
    NounSeek.Traits GLASSES = NounSeek.Traits.GLASSES;

    function setUp() public virtual {
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));
        nounSeekViewUtils = new NounSeekViewUtils(nounSeek);

        AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
        ANY_ID = nounSeek.ANY_ID();
        minValue = nounSeek.minValue();
        messageValue = nounSeek.messageValue();
        baseReimbursementBPS = nounSeek.baseReimbursementBPS();
        maxReimbursement = nounSeek.maxReimbursement();
        minReimbursement = nounSeek.minReimbursement();
        maxValue = (maxReimbursement * 10_000) / baseReimbursementBPS;

        nounSeek.addRecipient("recipient0", recipient0, "recipient0");
        nounSeek.addRecipient("recipient1", recipient1, "recipient1");
        nounSeek.addRecipient("recipient2", recipient2, "recipient2");
        nounSeek.addRecipient("recipient3", recipient3, "recipient3");
        nounSeek.addRecipient("recipient4", recipient4, "recipient4");

        mockDescriptor.setHeadCount(99);
        mockDescriptor.setGlassesCount(98);
        mockDescriptor.setAccessoryCount(97);
        mockDescriptor.setBodyCount(96);
        mockDescriptor.setBackgroundCount(95);
        nounSeek.updateTraitCounts();
        mockAuctionHouse.setNounId(99);
        allRecipientIds = recipientIds(nounSeek.recipients().length, 0, 1);
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
