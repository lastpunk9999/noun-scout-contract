// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
import "./MockContracts.sol";

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

contract NounSeekTest is EnhancedTest {
    NounSeek nounSeek;
    MockNouns mockNouns;
    MockSeeder mockSeeder;
    MockAuctionHouse mockAuctionHouse;
    MockDescriptor mockDescriptor;

    address user1 = mkaddr("user1");
    address user2 = mkaddr("user2");
    address user3 = mkaddr("user3");

    uint256 cleanSnapshot;

    uint256 AUCTION_END_LIMIT;
    uint256 AUCTION_START_LIMIT;
    uint256 NO_PREFERENCE;

    function setUp() public {
        mockSeeder = new MockSeeder();
        mockDescriptor = new MockDescriptor();
        mockAuctionHouse = new MockAuctionHouse();
        mockNouns = new MockNouns(mockSeeder, mockDescriptor);
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse);
        AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
        AUCTION_START_LIMIT = nounSeek.AUCTION_START_LIMIT();
        NO_PREFERENCE = nounSeek.NO_PREFERENCE();
    }

    function captureSnapshot() internal {
        vm.warp(AUCTION_START_LIMIT * 3);
        mockAuctionHouse.setStartTime(
            block.timestamp - (AUCTION_START_LIMIT * 2)
        );
        mockAuctionHouse.setEndTime(block.timestamp + 24 hours);

        cleanSnapshot = vm.snapshot();
    }

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounSeek.nouns()));
        assertEq(address(mockSeeder), address(nounSeek.seeder()));
        assertEq(address(mockAuctionHouse), address(nounSeek.auctionHouse()));
        captureSnapshot();
    }

    // function test_ADD_NounIdNotMultipleOfTenOnlyAuctionedNoun() public {
    //     vm.prank(user1);
    //     nounSeek.add{value: 1}(5, 5, 5, 5, 11, true);
    //     vm.stopPrank();
    //     // vm.revertTo(cleanSnapshot);
    // }

    // function test_ADD_NounIdNotMultipleOfTenNotOnlyAuctionedNoun() public {
    //     vm.prank(user1);
    //     nounSeek.add{value: 1}(5, 5, 5, 5, 11, false);
    //     vm.stopPrank();
    //     // vm.revertTo(cleanSnapshot);
    // }

    // function test_ADD_NounIdMultipleOf10SetsOnlyAuctionedNounCorrectly()
    //     public
    // {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.prank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         10,
    //         true
    //     );

    //     (, , , , , bool onlyAuctionedNoun, , ) = nounSeek.seeks(seekId);
    //     assertEq(false, onlyAuctionedNoun);
    // }

    // function test_ADD_NO_PREFERENCENouNIdSetsOnlyAuctionedNounCorrectly() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         NO_PREFERENCE,
    //         true
    //     );
    //     (, , , , , bool onlyAuctionedNoun, , ) = nounSeek.seeks(seekId);
    //     assertEq(true, onlyAuctionedNoun);

    //     (receiptId, seekId) = nounSeek.add{value: 1}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         NO_PREFERENCE,
    //         false
    //     );
    //     (, , , , , onlyAuctionedNoun, , ) = nounSeek.seeks(seekId);
    //     assertEq(false, onlyAuctionedNoun);
    //     vm.stopPrank();
    // }

    // function test_ADD_NounIdOnlyAuctionedNounCorrectly() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.prank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         11,
    //         false
    //     );

    //     (, , , , , bool onlyAuctionedNoun, , ) = nounSeek.seeks(seekId);
    //     assertEq(true, onlyAuctionedNoun);
    // }

    // function test_ADD_IncreaseSeekAndReceiptCountIfNewSeek() public {
    //     // vm.revertTo(cleanSnapshot);
    //     uint256 receiptCount_BEFORE = nounSeek.receiptCount();
    //     uint256 seekCount_BEFORE = nounSeek.seekCount();
    //     vm.prank(user1);
    //     nounSeek.add{value: 1}(5, 5, 5, 5, 10, false);
    //     vm.stopPrank();
    //     assertEq(receiptCount_BEFORE + 1, nounSeek.receiptCount());
    //     assertEq(seekCount_BEFORE + 1, nounSeek.seekCount());
    // }

    // function test_ADD_IncreaseOnlyReceiptCountIfNewSeek() public {
    //     // vm.revertTo(cleanSnapshot);
    //     uint256 receiptCount_BEFORE = nounSeek.receiptCount();
    //     uint256 seekCount_BEFORE = nounSeek.seekCount();
    //     vm.prank(user1);
    //     nounSeek.add{value: 1}(5, 5, 5, 5, 10, false);
    //     nounSeek.add{value: 1}(5, 5, 5, 5, 10, false);
    //     vm.stopPrank();
    //     assertEq(receiptCount_BEFORE + 2, nounSeek.receiptCount());
    //     assertEq(seekCount_BEFORE + 1, nounSeek.seekCount());
    // }

    // function test_ADD_seekAmountAndBalanceIncreasesCorrectly() public {
    //     uint256 amount = 1;
    //     // vm.revertTo(cleanSnapshot);
    //     (, , , , , , uint256 amount_BEFORE, ) = nounSeek.seeks(1);
    //     vm.prank(user1);
    //     (uint256 receiptId1, ) = nounSeek.add{value: amount}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         10,
    //         false
    //     );
    //     (uint256 receiptId2, ) = nounSeek.add{value: amount}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         10,
    //         false
    //     );
    //     vm.stopPrank();
    //     (, , , , , , uint256 amount_AFTER, ) = nounSeek.seeks(1);
    //     (, uint256 receipt1Amount, ) = nounSeek.receipts(receiptId1);
    //     (, uint256 receipt2Amount, ) = nounSeek.receipts(receiptId2);
    //     assertEq(amount_BEFORE + (amount * 2), amount_AFTER);
    //     assertEq(amount_AFTER, address(nounSeek).balance);
    //     assertEq(amount_AFTER, receipt1Amount + receipt2Amount);
    // }

    // function test_ADD_structsSetCorrectly() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.prank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);
    //     vm.stopPrank();
    //     (address seeker, uint256 receiptAmount, uint256 seekId) = nounSeek
    //         .receipts(receiptId);
    //     (
    //         uint48 b,
    //         uint48 a,
    //         uint48 h,
    //         uint48 g,
    //         uint256 nounId,
    //         bool onlyAuctionedNoun,
    //         uint256 amount,
    //         address finder
    //     ) = nounSeek.seeks(seekId);
    //     bytes32 traitsHash = keccak256(
    //         abi.encodePacked(b, a, h, g, nounId, onlyAuctionedNoun)
    //     );
    //     uint256 reverseSeekId = nounSeek.traitsHashToSeekId(traitsHash);
    //     assertEq(reverseSeekId, seekId);
    //     assertEq(seeker, address(user1));
    //     assertEq(99, receiptAmount);
    //     assertEq(1, b);
    //     assertEq(2, a);
    //     assertEq(3, h);
    //     assertEq(4, g);
    //     assertEq(5, nounId);
    //     assertEq(true, onlyAuctionedNoun);
    //     assertEq(99, amount);
    //     assertEq(address(0), finder);
    // }

    // function test_REMOVE_failsIfZeroAddress() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.prank(user1);
    //     vm.expectRevert(bytes("Not authorized"));
    //     nounSeek.remove(1);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_failsIfNotSeeker() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.prank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     vm.prank(user2);
    //     vm.expectRevert(bytes("Not authorized"));
    //     nounSeek.remove(receiptId);
    // }

    // function test_REMOVE_failsIfBeforeMaxStartWindow() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.startPrank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    //     vm.warp(block.timestamp + AUCTION_START_LIMIT);
    //     vm.expectRevert(bytes("Remove after auction start delay"));
    //     nounSeek.remove(receiptId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_failsIfAfterMaxEndWindow() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.startPrank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    //     vm.warp(block.timestamp + 24 hours - AUCTION_END_LIMIT);
    //     vm.expectRevert(bytes("Remove before auction end delay"));
    //     nounSeek.remove(receiptId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_correctIfAfterStartWindow() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.startPrank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    //     vm.warp(block.timestamp + AUCTION_START_LIMIT + 1 seconds);
    //     nounSeek.remove(receiptId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_correctIfBeforeEndWindow() public {
    //     // vm.revertTo(cleanSnapshot);
    //     vm.startPrank(user1);
    //     (uint256 receiptId, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    //     vm.warp(block.timestamp + 24 hours - AUCTION_END_LIMIT - 1 seconds);
    //     nounSeek.remove(receiptId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_resetsReceiptsAndSeeksCorrectly() public {
    //     // vm.revertTo(cleanSnapshot);
    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    //     vm.warp(block.timestamp + AUCTION_START_LIMIT + 1 seconds);
    //     vm.startPrank(user1);
    //     (uint256 receiptId1, uint256 seekId) = nounSeek.add{value: 99}(
    //         1,
    //         2,
    //         3,
    //         4,
    //         5,
    //         true
    //     );

    //     (uint256 receiptId2, ) = nounSeek.add{value: 99}(1, 2, 3, 4, 5, true);

    //     nounSeek.remove(receiptId1);
    //     (, , , , , , uint256 seekAmount1, ) = nounSeek.seeks(seekId);
    //     (address seeker1, uint256 receiptAmount1, ) = nounSeek.receipts(
    //         receiptId1
    //     );
    //     assertEq(99, seekAmount1);
    //     assertEq(0, receiptAmount1);
    //     assertEq(address(0), seeker1);

    //     vm.expectRevert("Not authorized");
    //     nounSeek.remove(receiptId1);

    //     nounSeek.remove(receiptId2);
    //     (, , , , , , uint256 seekAmount2, ) = nounSeek.seeks(seekId);
    //     (address seeker2, uint256 receiptAmount2, ) = nounSeek.receipts(
    //         receiptId2
    //     );
    //     assertEq(0, seekAmount2);
    //     assertEq(0, receiptAmount2);
    //     assertEq(address(0), seeker2);

    //     vm.expectRevert("Not authorized");
    //     nounSeek.remove(receiptId2);

    //     vm.stopPrank();
    // }

    // function test_ISMATCH_body_anyId_anyNounType() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         false
    //     );

    //     INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );
    //     INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
    //         0,
    //         11,
    //         0,
    //         0,
    //         0
    //     );
    //     // Correct Seed, Auctioned Noun
    //     assertEq(true, nounSeek.traitsMatch(seed1, 5, seekId));
    //     // Correct Seed, Non-Auctioned Noun
    //     assertEq(true, nounSeek.traitsMatch(seed1, 20, seekId));

    //     // Incorrect Seed, Auctioned Noun
    //     assertEq(false, nounSeek.traitsMatch(seed2, 5, seekId));
    //     // Incorrect Seed, Non-Auctioned Noun
    //     assertEq(false, nounSeek.traitsMatch(seed2, 20, seekId));
    // }

    // function test_ISMATCH_body_specificId_nonAuctioned() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         20,
    //         true // sets only Auctioned Noun to true, contract wll set it to false
    //     );

    //     INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );
    //     INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
    //         0,
    //         11,
    //         0,
    //         0,
    //         0
    //     );
    //     // Correct Seed, non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed1, 5, seekId));
    //     // Correct Seed, matching Id
    //     assertEq(true, nounSeek.traitsMatch(seed1, 20, seekId));

    //     // Incorrect Seed,  non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 5, seekId));
    //     // Incorrect Seed, matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 20, seekId));
    // }

    // function test_ISMATCH_body_specificId_Auctioned() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         5,
    //         false // sets only Auctioned Noun to false, contract wll set it to true
    //     );

    //     INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );
    //     INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
    //         0,
    //         11,
    //         0,
    //         0,
    //         0
    //     );
    //     // Correct Seed, matching Id
    //     assertEq(true, nounSeek.traitsMatch(seed1, 5, seekId));
    //     // Correct Seed, non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed1, 20, seekId));

    //     // Incorrect Seed,  matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 5, seekId));
    //     // Incorrect Seed, non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 20, seekId));
    // }

    // function test_ISMATCH_body_head_anyId_Auctioned() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         5,
    //         false
    //     );

    //     INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );
    //     INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );
    //     // Correct Seed, matching id
    //     assertEq(true, nounSeek.traitsMatch(seed1, 5, seekId));
    //     // Correct Seed, non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed1, 20, seekId));

    //     // Incorrect Seed,  matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 5, seekId));
    //     // Incorrect Seed, non-matching Id
    //     assertEq(false, nounSeek.traitsMatch(seed2, 20, seekId));
    // }

    // function test_ISMATCH_alreadyFound() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         5,
    //         false
    //     );

    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );
    //     mockAuctionHouse.setNounId(6);
    //     mockNouns.setSeed(seed, 5);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     // Before find
    //     assertEq(true, nounSeek.traitsMatch(seed, 5, seekId));
    //     assertEq(true, nounSeek.find(seekIds)[0]);
    //     // After find
    //     assertEq(false, nounSeek.traitsMatch(seed, 5, seekId));
    // }

    // function test_FOUND_anyId_onlyAuctioned() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         true
    //     );

    //     (, , , , , , , address finder) = nounSeek.seeks(seekId);
    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;
    //     mockAuctionHouse.setNounId(11);
    //     vm.stopPrank();
    //     vm.startPrank(user2);

    //     // Seed does not match, Id does not match
    //     assertEq(false, nounSeek.find(seekIds)[0]);
    //     (, , , , , , , finder) = nounSeek.seeks(seekId);
    //     assertEq(address(0), finder);
    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );
    //     mockNouns.setSeed(seed, 10);

    //     // Seed matches, Id does not match
    //     assertEq(false, nounSeek.find(seekIds)[0]);
    //     (, , , , , , , finder) = nounSeek.seeks(seekId);
    //     assertEq(address(0), finder);
    //     seed.background = 1;
    //     mockNouns.setSeed(seed, 9);
    //     // Seed matches, Id matches
    //     assertEq(true, nounSeek.find(seekIds)[0]);
    //     (, , , , , , , finder) = nounSeek.seeks(seekId);
    //     assertEq(address(user2), finder);
    // }

    // function test_FOUND_anyId_nonAuctioned() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         false
    //     );

    //     (, , , , , , , address finder) = nounSeek.seeks(seekId);
    //     mockAuctionHouse.setNounId(11);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     vm.stopPrank();
    //     vm.startPrank(user2);

    //     // Seed does not match, Id does not match
    //     assertEq(false, nounSeek.find(seekIds)[0]);
    //     (, , , , , , , finder) = nounSeek.seeks(seekId);
    //     assertEq(address(0), finder);
    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );
    //     mockNouns.setSeed(seed, 10);
    //     // Seed matches, Id matches

    //     assertEq(true, nounSeek.find(seekIds)[0]);
    //     (, , , , , , , finder) = nounSeek.seeks(seekId);
    //     assertEq(address(user2), finder);
    // }

    // function test_FOUND_twoSeeks_oneFails() public {
    //     vm.startPrank(user1);
    //     (uint256 receiptId1, uint256 seekId1) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         false
    //     );
    //     (uint256 receiptId2, uint256 seekId2) = nounSeek.add{value: 1}(
    //         11,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         false
    //     );
    //     vm.stopPrank();

    //     (, , , , , , , address finder1) = nounSeek.seeks(seekId1);
    //     (, , , , , , , address finder2) = nounSeek.seeks(seekId2);
    //     assertEq(address(0), finder1);
    //     assertEq(address(0), finder2);

    //     mockAuctionHouse.setNounId(11);

    //     uint256[] memory seekIds = new uint256[](2);
    //     seekIds[0] = seekId1;
    //     seekIds[1] = seekId2;

    //     vm.startPrank(user2);

    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );
    //     mockNouns.setSeed(seed, 10);

    //     bool[] memory matches = nounSeek.find(seekIds);

    //     assertEq(true, matches[0]);
    //     assertEq(false, matches[1]);
    //     (, , , , , , , finder1) = nounSeek.seeks(seekId1);
    //     (, , , , , , , finder2) = nounSeek.seeks(seekId2);
    //     assertEq(address(user2), finder1);
    //     assertEq(address(0), finder2);
    // }

    // function test_finderWITHDRAW() public {
    //     /// Start a new auction for Noun 9
    //     mockAuctionHouse.startAuction(9);

    //     // Jump 1 hour + 1 minute after auction start to allow `add()`
    //     vm.warp(mockAuctionHouse.auction().startTime + AUCTION_START_LIMIT + 1);

    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );

    //     mockNouns.setSeed(seed, 8);

    //     vm.prank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1 ether}(
    //         seed.body,
    //         seed.accessory,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         true
    //     );

    //     // Sanity check on balance
    //     (, , , , , , uint256 amount, address finder) = nounSeek.seeks(seekId);
    //     assertEq(1 ether, address(nounSeek).balance);
    //     assertEq(1 ether, amount);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     // Jump to start of auction to allow `find()`
    //     vm.warp(mockAuctionHouse.auction().startTime);

    //     vm.prank(user2);
    //     assertEq(true, nounSeek.find(seekIds)[0]);

    //     vm.prank(user3);
    //     vm.expectRevert(bytes("Not finder"));
    //     nounSeek.withdraw(seekId);

    //     vm.prank(user2);
    //     assertEq(true, nounSeek.withdraw(seekId));
    //     (, , , , , , amount, finder) = nounSeek.seeks(seekId);

    //     assertEq(amount, 0);
    //     assertEq(address(nounSeek).balance, 0);

    //     // user2 attempts to withdraw again
    //     vm.prank(user2);
    //     vm.expectRevert(bytes("Nothing to withrdaw"));
    //     nounSeek.withdraw(seekId);
    // }

    // function test_SETTLE_basic() public {
    //     vm.prank(user1);
    //     (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1 ether}(
    //         10,
    //         0,
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         uint48(NO_PREFERENCE),
    //         false
    //     );
    //     INounsSeederLike.Seed memory seed10 = INounsSeederLike.Seed(
    //         0,
    //         0,
    //         0,
    //         0,
    //         0
    //     );
    //     INounsSeederLike.Seed memory seed11 = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         0,
    //         0,
    //         0
    //     );

    //     mockSeeder.setSeed(seed10, 10);
    //     mockSeeder.setSeed(seed11, 11);
    //     mockAuctionHouse.setNounId(9);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     vm.prank(user2);
    //     nounSeek.settle(seekIds);
    //     (, , , , , , , address finder) = nounSeek.seeks(seekId);
    //     assertEq(address(user2), finder);

    //     vm.expectRevert(bytes("No match"));
    //     nounSeek.settle(seekIds);
    // }
}
