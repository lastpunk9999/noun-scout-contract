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

    struct Log {
        bytes32[] topics;
        bytes data;
    }

    event SeekAdded(
        uint256 seekId,
        uint48 body,
        uint48 accessory,
        uint48 head,
        uint48 glasses,
        uint256 nounId,
        bool onlyAuctionedNoun
    );

    event SeekAmountUpdated(uint256 seekId, uint256 amount);
    event SeekRemoved(uint256 seekId);
    event RequestAdded(
        uint256 requestId,
        uint256 seekId,
        address seeker,
        uint256 amount
    );
    event RequestRemoved(uint256 requestId);
    event SeekMatched(uint256 seekId, uint256 nounId, address finder);
    event FinderWithdrew(uint256 seekId, address finder, uint256 amount);

    address user1 = mkaddr("user1");
    address user2 = mkaddr("user2");
    address user3 = mkaddr("user3");

    uint256 cleanSnapshot;

    uint256 AUCTION_END_LIMIT;
    uint256 AUCTION_START_LIMIT;
    uint48 NO_PREFERENCE;

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
        cleanSnapshot = vm.snapshot();
    }

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounSeek.nouns()));
        assertEq(address(mockSeeder), address(nounSeek.seeder()));
        assertEq(address(mockAuctionHouse), address(nounSeek.auctionHouse()));
        captureSnapshot();
    }

    function _resetToRequestWindow() internal {
        vm.revertTo(cleanSnapshot);
        vm.warp(AUCTION_START_LIMIT * 3);
        mockAuctionHouse.setStartTime(
            block.timestamp - (AUCTION_START_LIMIT * 2) + 1
        );
        mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    }

    function _resetToMatchWindow() internal {
        mockAuctionHouse.setStartTime(block.timestamp);
        mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    }

    function _addSeek(address user, uint256 value)
        internal
        returns (uint256, uint256)
    {
        vm.prank(user);
        return
            nounSeek.add{value: value}(
                5,
                5,
                NO_PREFERENCE,
                NO_PREFERENCE,
                11,
                true
            );
    }

    function test_ADD_happyCaseNewSeek() public {
        vm.revertTo(cleanSnapshot);
        _resetToRequestWindow();

        (uint256 receiptId, uint256 seekId) = _addSeek(user1, 1);

        assertEq(nounSeek.seekCount(), 1);
        assertEq(nounSeek.requestCount(), 1);

        NounSeek.Seek memory seek = nounSeek.seeks(seekId);

        assertEq(seek.body, 5);
        assertEq(seek.accessory, 5);
        assertEq(seek.head, NO_PREFERENCE);
        assertEq(seek.glasses, NO_PREFERENCE);
        assertEq(seek.nounId, 11);
        assertEq(seek.onlyAuctionedNoun, true);
        assertEq(seek.amount, 1);
        assertEq(seek.finder, address(0));

        bytes32 traitsHash = keccak256(
            abi.encodePacked(
                uint48(5),
                uint48(5),
                NO_PREFERENCE,
                NO_PREFERENCE,
                uint256(11),
                true
            )
        );
        assertEq(nounSeek.traitsHashToSeekId(traitsHash), seekId);

        NounSeek.Request memory request = nounSeek.requests(receiptId);

        assertEq(request.seeker, address(user1));
        assertEq(request.amount, 1);
        assertEq(request.seekId, 1);

        assertEq(address(nounSeek).balance, 1);
        // vm.revertTo(cleanSnapshot);
    }

    function test_ADD_happyCaseExistingSeek() public {
        // vm.revertTo(cleanSnapshot);
        _resetToRequestWindow();

        _addSeek(user1, 1);

        (uint256 receiptId, uint256 seekId) = _addSeek(user2, 1);

        assertEq(nounSeek.seekCount(), 1);
        assertEq(nounSeek.requestCount(), 2);

        NounSeek.Seek memory seek = nounSeek.seeks(seekId);

        assertEq(seek.body, 5);
        assertEq(seek.accessory, 5);
        assertEq(seek.head, NO_PREFERENCE);
        assertEq(seek.glasses, NO_PREFERENCE);
        assertEq(seek.nounId, 11);
        assertEq(seek.onlyAuctionedNoun, true);
        assertEq(seek.amount, 2);
        assertEq(seek.finder, address(0));

        bytes32 traitsHash = keccak256(
            abi.encodePacked(
                uint48(5),
                uint48(5),
                NO_PREFERENCE,
                NO_PREFERENCE,
                uint256(11),
                true
            )
        );
        assertEq(nounSeek.traitsHashToSeekId(traitsHash), seekId);

        NounSeek.Request memory request = nounSeek.requests(receiptId);

        assertEq(request.seeker, address(user2));
        assertEq(request.amount, 1);
        assertEq(request.seekId, 1);

        assertEq(address(nounSeek).balance, 2);
    }

    function test_ADD_failsWhenBeforeStartWindow() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setStartTime(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);

        vm.warp(timestamp);
        vm.expectRevert("Too soon");
        _addSeek(user1, 1);

        vm.warp(timestamp + AUCTION_START_LIMIT);
        vm.expectRevert("Too soon");
        _addSeek(user1, 1);
    }

    function test_ADD_failsWhenAfterEndWindow() public {
        uint256 timestamp = 9999999999;
        uint256 endTime = timestamp + 24 hours;
        mockAuctionHouse.setStartTime(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(endTime - AUCTION_END_LIMIT);
        vm.expectRevert("Too late");
        _addSeek(user1, 1);

        vm.warp(endTime);
        vm.expectRevert("Too late");
        _addSeek(user1, 1);
    }

    function test_REMOVE_happyCase() public {
        _resetToRequestWindow();
        (uint256 requestId1, uint256 seekId) = _addSeek(user1, 1);
        (uint256 requestId2, ) = _addSeek(user2, 1);

        assertEq(nounSeek.seeks(seekId).amount, 2);
        assertEq(address(nounSeek).balance, 2);

        vm.prank(user1);
        vm.expectCall(address(user1), 1, "");
        bool remove1 = nounSeek.remove(requestId1);

        assertEq(remove1, true);

        assertEq(nounSeek.requests(requestId1).seeker, address(0));
        assertEq(nounSeek.requests(requestId1).amount, 0);
        assertEq(nounSeek.requests(requestId1).seekId, 0);

        assertEq(nounSeek.seekCount(), 1);
        assertEq(nounSeek.requestCount(), 2);

        assertEq(nounSeek.seeks(seekId).amount, 1);
        assertEq(address(nounSeek).balance, 1);

        vm.prank(user2);
        vm.expectCall(address(user2), 1, "");
        bool remove2 = nounSeek.remove(requestId2);

        assertEq(remove2, true);

        assertEq(nounSeek.requests(requestId2).seeker, address(0));
        assertEq(nounSeek.requests(requestId2).amount, 0);
        assertEq(nounSeek.requests(requestId2).seekId, 0);

        assertEq(nounSeek.seekCount(), 1);
        assertEq(nounSeek.requestCount(), 2);

        assertEq(nounSeek.seeks(seekId).body, 0);
        assertEq(nounSeek.seeks(seekId).accessory, 0);
        assertEq(nounSeek.seeks(seekId).head, 0);
        assertEq(nounSeek.seeks(seekId).glasses, 0);
        assertEq(nounSeek.seeks(seekId).nounId, 0);
        assertEq(nounSeek.seeks(seekId).onlyAuctionedNoun, false);
        assertEq(nounSeek.seeks(seekId).amount, 0);
        assertEq(address(nounSeek).balance, 0);
    }

    function test_REMOVE_failsWhenNotRequester() public {
        _resetToRequestWindow();
        (uint256 requestId, ) = _addSeek(user1, 1);
        vm.prank(user2);
        vm.expectRevert(bytes("Not authorized"));
        nounSeek.remove(requestId);
        vm.stopPrank();
    }

    function test_REMOVE_failsWhenAlreadyProcessed() public {
        _resetToRequestWindow();
        (uint256 requestId, ) = _addSeek(user1, 1);
        vm.startPrank(user1);
        nounSeek.remove(requestId);
        vm.expectRevert(bytes("Not authorized"));
        nounSeek.remove(requestId);
        vm.stopPrank();
    }

    function test_REMOVE_failsWhenBeforeStartWindow() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setStartTime(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp + AUCTION_START_LIMIT + 1);
        (uint256 requestId, ) = _addSeek(user1, 1);

        vm.warp(timestamp);
        vm.expectRevert("Too soon");
        nounSeek.remove(requestId);

        vm.warp(timestamp + AUCTION_START_LIMIT);
        vm.expectRevert("Too soon");
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenAfterEndWindow() public {
        uint256 timestamp = 9999999999;
        uint256 endTime = timestamp + 24 hours;
        mockAuctionHouse.setStartTime(timestamp);
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(endTime - AUCTION_END_LIMIT - 1);
        (uint256 requestId, ) = _addSeek(user1, 1);

        vm.warp(endTime - AUCTION_END_LIMIT);
        vm.expectRevert("Too late");
        nounSeek.remove(requestId);

        vm.warp(endTime);
        vm.expectRevert("Too late");
        nounSeek.remove(requestId);
    }

    function test_ADD_NO_PREFERENCENouNIdSetsOnlyAuctionedNounCorrectly()
        public
    {
        _resetToRequestWindow();
        vm.prank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            5,
            5,
            5,
            5,
            NO_PREFERENCE,
            true
        );
        NounSeek.Seek memory seek = nounSeek.seeks(seekId);
        assertEq(seek.onlyAuctionedNoun, true);

        (receiptId, seekId) = nounSeek.add{value: 1}(
            5,
            5,
            5,
            5,
            NO_PREFERENCE,
            false
        );
        seek = nounSeek.seeks(seekId);
        assertEq(seek.onlyAuctionedNoun, false);
    }

    function test_ADD_NounIdOnlyAuctionedNounCorrectly() public {
        _resetToRequestWindow();
        vm.prank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            5,
            5,
            5,
            5,
            11,
            false
        );

        NounSeek.Seek memory seek = nounSeek.seeks(seekId);
        assertEq(seek.onlyAuctionedNoun, true);
    }

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

    function test_SEEKMATCHESTRAITS_body_anyId_anyNounType() public {
        vm.startPrank(user1);
        _resetToRequestWindow();
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
            0,
            11,
            0,
            0,
            0
        );
        // Correct Seed, Auctioned Noun
        assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
        // Correct Seed, Non-Auctioned Noun
        assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

        // Incorrect Seed, Auctioned Noun
        assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
        // Incorrect Seed, Non-Auctioned Noun
        assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    }

    function test_SEEKMATCHESTRAITS_body_specificId_nonAuctioned() public {
        _resetToRequestWindow();
        vm.startPrank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            20,
            true // sets only Auctioned Noun to true, contract wll set it to false
        );

        INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
            0,
            11,
            0,
            0,
            0
        );
        // Correct Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(5, seed1, seekId));
        // Correct Seed, matching Id
        assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

        // Incorrect Seed,  non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
        // Incorrect Seed, matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    }

    function test_SEEKMATCHESTRAITS_body_specificId_Auctioned() public {
        _resetToRequestWindow();
        vm.startPrank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            5,
            false // sets only Auctioned Noun to false, contract wll set it to true
        );

        INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
            0,
            11,
            0,
            0,
            0
        );
        // Correct Seed, matching Id
        assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
        // Correct Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed1, seekId));

        // Incorrect Seed,  matching Id
        assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
        // Incorrect Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    }

    function test_SEEKMATCHESTRAITS_body_head_anyId_Auctioned() public {
        vm.startPrank(user1);
        _resetToRequestWindow();
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            true
        );

        INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );
        INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        // Correct Seed, matching id
        assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
        // Correct Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed1, seekId));

        // Incorrect Seed,  matching Id
        assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
        // Incorrect Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    }

    function test_SEEKMATCHESTRAITS_body_head_anyId_nonAuctioned() public {
        vm.startPrank(user1);
        _resetToRequestWindow();
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        INounsSeederLike.Seed memory seed1 = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );
        INounsSeederLike.Seed memory seed2 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        // Correct Seed, matching id
        assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
        // Correct Seed, matching Id
        assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

        // Incorrect Seed,  matching Id
        assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
        // Incorrect Seed, non-matching Id
        assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    }

    function test_SEEKMATCHESTRAITS_alreadyFound() public {
        vm.startPrank(user1);
        _resetToRequestWindow();
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );
        mockAuctionHouse.setNounId(6);
        mockNouns.setSeed(seed, 6);

        // Before match
        assertEq(true, nounSeek.seekMatchesTraits(5, seed, seekId));

        // Match
        _resetToMatchWindow();
        uint256[] memory seekIds = new uint256[](1);
        seekIds[0] = seekId;
        assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);

        // After match
        assertEq(false, nounSeek.seekMatchesTraits(5, seed, seekId));
    }

    function test_MATCHWITHCURRENT_anyId_onlyAuctioned() public {
        _resetToRequestWindow();

        vm.prank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1}(
            10,
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            true
        );

        uint256[] memory seekIds = new uint256[](1);
        seekIds[0] = seekId;
        mockAuctionHouse.setNounId(11);

        _resetToMatchWindow();

        vm.startPrank(user2);

        // Seed does not match, Id does not match
        assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);

        assertEq(address(0), nounSeek.seeks(seekId).finder);
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );

        // Set matching seed for non-auctioned Noun
        mockNouns.setSeed(seed, 10);

        // Seed matches, Id does not match
        assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);
        assertEq(address(0), nounSeek.seeks(seekId).finder);

        // Set current auctioned noun to correct seed
        seed.background = 1;
        mockNouns.setSeed(seed, 11);
        // Seed matches, Id matches
        assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);

        assertEq(address(user2), nounSeek.seeks(seekId).finder);

        vm.stopPrank();

        vm.prank(user3);
        // Attempt to match again
        assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);
        assertEq(address(user2), nounSeek.seeks(seekId).finder);
    }

    function test_MATCHWITHCURRENT_anyId_nonAuctioned() public {
        _resetToRequestWindow();

        vm.prank(user1);
        (, uint256 seekId1) = nounSeek.add{value: 1}(
            10,
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        uint256[] memory seekIds1 = new uint256[](1);
        seekIds1[0] = seekId1;
        mockAuctionHouse.setNounId(11);

        // Seek2 with similar matching traits
        (, uint256 seekId2) = nounSeek.add{value: 1}(
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        uint256[] memory seekIds2 = new uint256[](1);
        seekIds2[0] = seekId2;

        mockAuctionHouse.setNounId(11);

        _resetToMatchWindow();

        vm.startPrank(user2);

        // Seed does not match, Id does not match
        assertEq(false, nounSeek.matchWithCurrent(seekIds1)[0]);

        assertEq(address(0), nounSeek.seeks(seekId1).finder);
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );

        // Set matching seed for non-auctioned Noun
        mockNouns.setSeed(seed, 10);

        // Seed matches, Id does not match
        assertEq(true, nounSeek.matchWithCurrent(seekIds1)[0]);
        assertEq(address(user2), nounSeek.seeks(seekId1).finder);

        // Set current auctioned noun to auctioned noun seed
        seed.background = 1;
        mockNouns.setSeed(seed, 11);

        // Seed matches, Id matches, already matched
        assertEq(false, nounSeek.matchWithCurrent(seekIds1)[0]);
        assertEq(address(user2), nounSeek.seeks(seekId1).finder);

        // Seed matches, Id matches, seek2 has not been matched
        assertEq(true, nounSeek.matchWithCurrent(seekIds2)[0]);
        assertEq(address(user2), nounSeek.seeks(seekId2).finder);

        vm.stopPrank();
    }

    function test_MATCHWITHCURRENT_twoSeeksOneFails() public {
        _resetToRequestWindow();
        vm.startPrank(user1);
        (, uint256 seekId1) = nounSeek.add{value: 1}(
            10,
            10,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );
        (, uint256 seekId2) = nounSeek.add{value: 1}(
            11,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );
        vm.stopPrank();

        assertEq(address(0), nounSeek.seeks(seekId1).finder);
        assertEq(address(0), nounSeek.seeks(seekId2).finder);

        mockAuctionHouse.setNounId(11);

        uint256[] memory seekIds = new uint256[](2);
        seekIds[0] = seekId1;
        seekIds[1] = seekId2;

        vm.startPrank(user2);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );
        mockNouns.setSeed(seed, 10);

        _resetToMatchWindow();

        bool[] memory matches = nounSeek.matchWithCurrent(seekIds);

        assertEq(true, matches[0]);
        assertEq(false, matches[1]);
        assertEq(address(user2), nounSeek.seeks(seekId1).finder);
        assertEq(address(0), nounSeek.seeks(seekId2).finder);
    }

    function test_finderWITHDRAW() public {
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            10,
            0,
            0
        );
        _resetToRequestWindow();
        vm.prank(user1);
        (uint256 receiptId, uint256 seekId) = nounSeek.add{value: 1 ether}(
            seed.body,
            seed.accessory,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            true
        );

        // Sanity check on balance
        assertEq(1 ether, address(nounSeek).balance);
        assertEq(1 ether, nounSeek.seeks(seekId).amount);

        uint256[] memory seekIds = new uint256[](1);
        seekIds[0] = seekId;

        // Jump to start of auction to allow `find()`
        vm.warp(mockAuctionHouse.auction().startTime);
        mockNouns.setSeed(seed, 9);
        mockAuctionHouse.setNounId(9);

        vm.prank(user2);
        assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);
        assertEq(address(user2), nounSeek.seeks(seekId).finder);

        vm.prank(user3);
        vm.expectRevert(bytes("Not finder"));
        nounSeek.withdraw(seekId);

        vm.startPrank(user2);

        vm.expectCall(address(user2), 1 ether, "");
        assertEq(true, nounSeek.withdraw(seekId));
        assertEq(nounSeek.seeks(seekId).amount, 0);
        assertEq(address(nounSeek).balance, 0);

        // user2 attempts to withdraw again, 0 is sent
        vm.expectCall(address(user2), 0, "");
        assertEq(true, nounSeek.withdraw(seekId));
    }

    function test_MATCHWITHNEXTANDSETTLE_happyCase() public {
        _resetToRequestWindow();
        INounsSeederLike.Seed memory seed10 = INounsSeederLike.Seed(
            0,
            0,
            0,
            0,
            0
        );
        INounsSeederLike.Seed memory seed11 = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );

        vm.prank(user1);
        (, uint256 seekId) = nounSeek.add{value: 1 ether}(
            seed11.body,
            seed11.accessory,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        mockSeeder.setSeed(seed10, 10);
        mockSeeder.setSeed(seed11, 11);
        mockAuctionHouse.setNounId(9);

        uint256[] memory seekIds = new uint256[](1);
        seekIds[0] = seekId;

        vm.startPrank(user2);
        nounSeek.matchWithNextAndSettle(seekIds);
        assertEq(address(user2), nounSeek.seeks(seekId).finder);

        vm.expectRevert(bytes("No match"));
        nounSeek.matchWithNextAndSettle(seekIds);
    }

    function test_MATCHWITHNEXTANDSETTLE_failsIfAnySeekIdDoesNotMatch() public {
        _resetToRequestWindow();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            10,
            0,
            0,
            0
        );

        vm.prank(user1);
        (, uint256 seekId1) = nounSeek.add{value: 1 ether}(
            seed.body,
            seed.accessory,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );
        (, uint256 seekId2) = nounSeek.add{value: 1 ether}(
            99,
            99,
            NO_PREFERENCE,
            NO_PREFERENCE,
            NO_PREFERENCE,
            false
        );

        mockSeeder.setSeed(seed, 12);
        mockAuctionHouse.setNounId(11);

        uint256[] memory seekIds = new uint256[](2);
        seekIds[0] = seekId1;
        seekIds[1] = seekId2;

        vm.startPrank(user2);
        vm.expectRevert(bytes("No match"));
        nounSeek.matchWithNextAndSettle(seekIds);
        assertEq(address(0), nounSeek.seeks(seekId1).finder);
        assertEq(address(0), nounSeek.seeks(seekId2).finder);
    }
}
