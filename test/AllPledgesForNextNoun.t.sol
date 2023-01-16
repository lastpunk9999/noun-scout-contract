// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "forge-std/Test.sol";
// import "forge-std/console2.sol";
// import "../src/NounSeek.sol";
// import "./MockContracts.sol";
// import "../src/Interfaces.sol";
// import "./BaseNounSeekTest.sol";

// contract NounSeekTest is BaseNounSeekTest {
//     function setUp() public override {
//         BaseNounSeekTest.setUp();
//     }

//     function test_ALLPLEDGESFORUPCOMINGNOUN() public {
//         // Total 20 Recipients
//         // Add 5-9
//         nounSeek.addRecipient("recipient0", recipient0, "");
//         nounSeek.addRecipient("recipient1", recipient1, "");
//         nounSeek.addRecipient("recipient2", recipient2, "");
//         nounSeek.addRecipient("recipient3", recipient3, "");
//         nounSeek.addRecipient("recipient4", recipient4, "");
//         // Add 10-14
//         nounSeek.addRecipient("recipient0", recipient0, "");
//         nounSeek.addRecipient("recipient1", recipient1, "");
//         nounSeek.addRecipient("recipient2", recipient2, "");
//         nounSeek.addRecipient("recipient3", recipient3, "");
//         nounSeek.addRecipient("recipient4", recipient4, "");
//         // Add 15-19
//         nounSeek.addRecipient("recipient0", recipient0, "");
//         nounSeek.addRecipient("recipient1", recipient1, "");
//         nounSeek.addRecipient("recipient2", recipient2, "");
//         nounSeek.addRecipient("recipient3", recipient3, "");
//         nounSeek.addRecipient("recipient4", recipient4, "");

//         mockDescriptor.setHeadCount(242);

//         nounSeek.updateTraitCounts();

//         uint256 timestamp = 9999999999;
//         mockAuctionHouse.setEndTime(timestamp + 24 hours);

//         vm.warp(timestamp);

//         vm.startPrank(user1);

//         // 100 times
//         for (uint16 i; i < 100; i++) {
//             // For recipients 0 - 4
//             for (uint16 j; j < 15; j++) {
//                 // Add a request for each head, with any id, going to recipient 0 - 4
//                 nounSeek.add{value: minValue}(HEAD, i, ANY_ID, j);
//             }
//         }

//         // For heads 0 - 99
//         for (uint16 i; i < 100; i++) {
//             // For recipients 0 - 4
//             for (uint16 j; j < 15; j++) {
//                 // Add a request for each head, with any 101, going to recipient 0 - 4
//                 nounSeek.add{value: minValue}(HEAD, i, 101, j);
//             }
//         }
//         // For heads 0 - 99
//         for (uint16 i = 0; i < 100; i++) {
//             // For recipients 0 - 4
//             for (uint16 j; j < 15; j++) {
//                 // Add a request for each head, with any 101, going to recipient 0 - 4
//                 nounSeek.add{value: minValue}(HEAD, i, 100, j);
//             }
//         }
//         // for (uint16 i; i < 241; i++) {
//         //     nounSeek.add{value: minValue}(HEAD, i + 1, ANY_ID, i % 5);
//         // }
//         // for (uint16 i; i < 241; i++) {
//         //     nounSeek.add{value: minValue}(HEAD, i + 1, 100, i % 5);
//         // }
//         // for (uint16 i; i < 241; i++) {
//         //     nounSeek.add{value: minValue}(HEAD, i + 1, 101, i % 5);
//         // }

//         mockAuctionHouse.setNounId(99);
//         (
//             uint16 nextAuctionedId,
//             uint16 nextNonAuctionedId,
//             uint256[][] memory nextAuctionPledges,
//             uint256[][] memory nextNonAuctionPledges
//         ) = nounSeek.pledgesForUpcomingNounByTrait(HEAD);
//         assertEq(nextAuctionedId, 101);
//         assertEq(nextNonAuctionedId, 100);
//         // All recipients are represented
//         assertEq(nextAuctionPledges[0].length, 20);
//         assertEq(nextNonAuctionPledges[0].length, 20);

//         // For all recipient slots for next auctioned Noun
//         for (uint256 i = 0; i < 20; i++) {
//             // For Head 0, the first 5 recipients were requested with ANY_ID and specific
//             assertEq(nextAuctionPledges[0][i], i < 15 ? minValue * 2 : 0);
//             // For Head 99, the first 5 recipients were requested with ANY_ID and specific
//             assertEq(nextAuctionPledges[99][i], i < 15 ? minValue * 2 : 0);
//             // For Head 100, no requests were made
//             assertEq(nextAuctionPledges[100][i], 0);
//         }
//         // For all recipient slots for next non-auctioned Noun
//         for (uint256 i = 0; i < 20; i++) {
//             // For Head 100, the first 5 recipients were requested with specific id
//             assertEq(nextNonAuctionPledges[0][i], i < 15 ? minValue : 0);
//             // For Head 199, the first 5 recipients were requested with specific id
//             assertEq(nextNonAuctionPledges[99][i], i < 15 ? minValue : 0);
//             // Head 99 not requestesd
//             assertEq(nextNonAuctionPledges[100][i], 0);
//         }

//         // mockAuctionHouse.setNounId(102);

//         // nounSeek.settle(HEAD);
//     }
// }
