pragma solidity ^0.8.13;

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
        vm.deal(addr, 100e18);
        return addr;
    }
}

contract BaseNounSeekTest is EnhancedTest {
    NounSeek nounSeek;
    MockNouns mockNouns;
    MockAuctionHouse mockAuctionHouse;
    MockDescriptor mockDescriptor;
    NounSeekViewUtils nounSeekViewUtils;

    address user1 = mkaddr("user1");
    address user2 = mkaddr("user2");
    address user3 = mkaddr("user3");
    address donee0 = mkaddr("donee0");
    address donee1 = mkaddr("donee1");
    address donee2 = mkaddr("donee2");
    address donee3 = mkaddr("donee3");
    address donee4 = mkaddr("donee4");
    uint256 AUCTION_END_LIMIT;
    uint16 ANY_ID;
    uint256 minValue;
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
        baseReimbursementBPS = nounSeek.baseReimbursementBPS();
        maxReimbursement = nounSeek.maxReimbursement();
        minReimbursement = nounSeek.minReimbursement();

        nounSeek.addDonee("donee0", donee0, "donee0");
        nounSeek.addDonee("donee1", donee1, "donee1");
        nounSeek.addDonee("donee2", donee2, "donee2");
        nounSeek.addDonee("donee3", donee3, "donee3");
        nounSeek.addDonee("donee4", donee4, "donee4");

        mockDescriptor.setHeadCount(99);
        mockDescriptor.setGlassesCount(98);
        mockDescriptor.setAccessoryCount(97);
        mockDescriptor.setBodyCount(96);
        mockDescriptor.setBackgroundCount(95);
        nounSeek.updateTraitCounts();
        mockAuctionHouse.setNounId(99);
    }
}
