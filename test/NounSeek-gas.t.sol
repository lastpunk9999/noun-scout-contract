// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "forge-std/console2.sol";
// import "../src/NounSeek.sol";
// import "./MockContracts.sol";
// import "../src/Interfaces.sol";

// contract EnhancedTest is Test {
//     function mkaddr(string memory name) public returns (address) {
//         address addr = address(
//             uint160(uint256(keccak256(abi.encodePacked(name))))
//         );
//         vm.label(addr, name);
//         vm.deal(addr, 100e18);
//         return addr;
//     }
// }

// contract NounSeekTest is EnhancedTest {
//     NounSeek nounSeek;
//     MockNouns mockNouns;
//     MockAuctionHouse mockAuctionHouse;
//     MockDescriptor mockDescriptor;

//     struct Log {
//         bytes32[] topics;
//         bytes data;
//     }

//     event SeekAdded(
//         uint256 seekId,
//         uint48 body,
//         uint48 accessory,
//         uint48 head,
//         uint48 glasses,
//         uint256 nounId,
//         bool onlyAuctionedNoun
//     );

//     event SeekAmountUpdated(uint256 seekId, uint256 amount);
//     event SeekRemoved(uint256 seekId);
//     event RequestAdded(
//         uint16 requestId,
//         uint256 seekId,
//         address seeker,
//         uint256 amount
//     );
//     event RequestRemoved(uint16 requestId);
//     event SeekMatched(uint256 seekId, uint256 nounId, address finder);
//     event FinderWithdrew(uint256 seekId, address finder, uint256 amount);

//     address user1 = mkaddr("user1");
//     address user2 = mkaddr("user2");
//     address user3 = mkaddr("user3");
//     address donee1 = mkaddr("donee1");
//     address donee2 = mkaddr("donee2");
//     address donee3 = mkaddr("donee3");
//     address donee4 = mkaddr("donee4");
//     address donee5 = mkaddr("donee5");

//     uint256 cleanSnapshot;

//     uint256 AUCTION_END_LIMIT;
//     uint16 ANY_ID;
//     uint16 MAX = 9999 wei;
//     uint256 reimbursementBPS;
//     NounSeek.Traits BACKGROUND = NounSeek.Traits.BACKGROUND;
//     NounSeek.Traits HEAD = NounSeek.Traits.HEAD;
//     NounSeek.Traits GLASSES = NounSeek.Traits.GLASSES;
//     NounSeek.Traits ACCESSORY = NounSeek.Traits.ACCESSORY;

//     function setUp() public {
//         mockAuctionHouse = new MockAuctionHouse();
//         mockDescriptor = new MockDescriptor();
//         mockNouns = new MockNouns(address(mockDescriptor));
//         nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));

//         AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
//         ANY_ID = nounSeek.ANY_ID();
//         reimbursementBPS = nounSeek.reimbursementBPS();

//         nounSeek.addDonee("donee1", donee1, "");
//         nounSeek.addDonee("donee2", donee2, "");
//         nounSeek.addDonee("donee3", donee3, "");
//         nounSeek.addDonee("donee4", donee4, "");
//         nounSeek.addDonee("donee5", donee5, "");
//         nounSeek.setMinValue(1);

//         mockDescriptor.setHeadCount(242);
//         mockDescriptor.setGlassesCount(98);
//         mockDescriptor.setAccessoryCount(97);
//         mockDescriptor.setBodyCount(96);
//         mockDescriptor.setBackgroundCount(95);
//         nounSeek.updateTraitCounts();
//         mockAuctionHouse.setNounId(99);
//     }

//     function test_add_request_match() public {
//         nounSeek.addDonee("donee1", donee1, "");
//         nounSeek.addDonee("donee2", donee2, "");
//         nounSeek.addDonee("donee3", donee3, "");
//         nounSeek.addDonee("donee4", donee4, "");
//         nounSeek.addDonee("donee5", donee5, "");

//         nounSeek.addDonee("donee1", donee1, "");
//         nounSeek.addDonee("donee2", donee2, "");
//         nounSeek.addDonee("donee3", donee3, "");
//         nounSeek.addDonee("donee4", donee4, "");
//         nounSeek.addDonee("donee5", donee5, "");
//         nounSeek.addDonee("donee1", donee1, "");
//         nounSeek.addDonee("donee2", donee2, "");
//         nounSeek.addDonee("donee3", donee3, "");
//         nounSeek.addDonee("donee4", donee4, "");
//         nounSeek.addDonee("donee5", donee5, "");
//         mockDescriptor.setHeadCount(242);
//         nounSeek.updateTraitCounts();

//         // Current auctioned Noun is 99
//         for (uint16 i; i < 10; i++) {
//             nounSeek.add{value: 1000}(HEAD, 0, ANY_ID, i % 5);
//         }
//         for (uint16 i; i < 10; i++) {
//             nounSeek.add{value: 1000}(HEAD, 0, 101, i % 5);
//         }
//         for (uint16 i; i < 241; i++) {
//             nounSeek.add{value: 1000}(HEAD, i + 1, ANY_ID, i % 20);
//         }
//         for (uint16 i; i < 241; i++) {
//             nounSeek.add{value: 1000}(HEAD, i + 1, 100, i % 20);
//         }
//         for (uint16 i; i < 241; i++) {
//             nounSeek.add{value: 1000}(HEAD, i + 1, 101, i % 20);
//         }

//         (
//             uint16 any_id,
//             uint16 nextAuctionedId,
//             uint16 nextNonAuctionedId,
//             NounSeek.Request[][] memory anyIdRequests,
//             NounSeek.Request[][] memory nextAuctionedRequests,
//             NounSeek.Request[][] memory nextNonAuctionedRequests
//         ) = nounSeek.allTraitRequestsForNextNoun(HEAD);
//         mockAuctionHouse.setNounId(102);
//         vm.prank(user1);
//         nounSeek.matchAndDonate(101, HEAD, MAX);
//     }
// }
