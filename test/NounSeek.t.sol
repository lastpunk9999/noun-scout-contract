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
        uint16 requestId,
        uint256 seekId,
        address seeker,
        uint256 amount
    );
    event RequestRemoved(uint16 requestId);
    event SeekMatched(uint256 seekId, uint256 nounId, address finder);
    event FinderWithdrew(uint256 seekId, address finder, uint256 amount);

    address user1 = mkaddr("user1");
    address user2 = mkaddr("user2");
    address user3 = mkaddr("user3");
    address donee1 = mkaddr("donee1");
    address donee2 = mkaddr("donee2");
    address donee3 = mkaddr("donee3");
    address donee4 = mkaddr("donee4");
    address donee5 = mkaddr("donee5");

    uint256 cleanSnapshot;

    uint256 AUCTION_END_LIMIT;
    uint256 AUCTION_START_LIMIT;

    function setUp() public {
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse);

        AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
        AUCTION_START_LIMIT = nounSeek.AUCTION_START_LIMIT();

        nounSeek.addDonee(donee1);
        nounSeek.addDonee(donee2);
        nounSeek.addDonee(donee3);
        nounSeek.addDonee(donee4);
        nounSeek.addDonee(donee5);

        mockDescriptor.setHeadCount(99);
        nounSeek.updateHeadCount();
        mockAuctionHouse.setNounId(99);
    }

    // function _resetToRequestWindow() internal {
    //     vm.revertTo(cleanSnapshot);
    //     vm.warp(AUCTION_START_LIMIT * 3);
    //     mockAuctionHouse.setStartTime(
    //         block.timestamp - (AUCTION_START_LIMIT * 2) + 1
    //     );
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    // }

    // function _resetToMatchWindow() internal {
    //     mockAuctionHouse.setStartTime(block.timestamp);
    //     mockAuctionHouse.setEndTime(block.timestamp + 24 hours);
    // }

    // function _addSeek(address user, uint256 value)
    //     internal
    //     returns (uint96, uint96)
    // {
    //     vm.prank(user);
    //     return
    //         nounSeek.add{value: value}(
    //             5,
    //             5,
    //             NO_PREFERENCE,
    //             NO_PREFERENCE,
    //             11,
    //             true
    //         );
    // }

    // function captureSnapshot() internal {
    //     cleanSnapshot = vm.snapshot();
    // }

    // function testConstructor() public {
    //     assertEq(address(mockNouns), address(nounSeek.nouns()));
    //     assertEq(address(mockAuctionHouse), address(nounSeek.auctionHouse()));
    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = 1;
    //     captureSnapshot();
    // }

    function test_ADD_happyCase() public {
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(9, 1);

        NounSeek.Request memory request = nounSeek.requests(requestId);

        uint16[] memory headRequestIds = nounSeek.headRequestIds(9);
        assertEq(headRequestIds.length, 1);
        assertEq(headRequestIds[0], requestId);

        NounSeek.Request[] memory headToRequests = nounSeek.headToRequests(9);
        assertEq(headToRequests.length, 1);
        assertEq(headToRequests[0].requester, request.requester);

        assertEq(request.headRequestIndex, 0);
        assertEq(request.headId, 9);
        assertEq(request.doneeId, 1);

        assertEq(request.stampedNounId, 99);
        assertEq(request.requester, address(user1));
        assertEq(request.amount, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(9, 0);

        NounSeek.Request memory request2 = nounSeek.requests(requestId2);
        uint16[] memory headRequestIds2 = nounSeek.headRequestIds(9);

        assertEq(headRequestIds2.length, 2);
        assertEq(headRequestIds2[1], requestId2);

        NounSeek.Request[] memory headToRequests2 = nounSeek.headToRequests(9);
        assertEq(headToRequests2.length, 2);
        assertEq(headToRequests2[0].requester, request.requester);
        assertEq(headToRequests2[1].requester, request2.requester);

        assertEq(request2.headRequestIndex, 1, "headRequestIndex");
        assertEq(request2.headId, 9);
        assertEq(request2.doneeId, 0);

        assertEq(request2.stampedNounId, 99);
        assertEq(request2.requester, address(user2));
        assertEq(request2.amount, 1);
    }

    function test_REMOVE_happyCase() public {
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(9, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(9, 0);

        vm.prank(user1);
        vm.expectRevert();
        nounSeek.remove(requestId2);

        vm.prank(user2);
        nounSeek.remove(requestId2);

        uint16[] memory headRequestIds2 = nounSeek.headRequestIds(9);

        assertEq(headRequestIds2.length, 1);
        assertEq(headRequestIds2[0], requestId);

        NounSeek.Request[] memory headToRequests2 = nounSeek.headToRequests(9);
        assertEq(headToRequests2.length, 1);
        assertEq(headToRequests2[0].requester, address(user1));

        vm.prank(user2);
        vm.expectRevert();
        nounSeek.remove(requestId2);

        vm.prank(user1);
        nounSeek.remove(requestId);
        uint16[] memory headRequestIds = nounSeek.headRequestIds(9);

        assertEq(headRequestIds.length, 0);
        NounSeek.Request[] memory headToRequests = nounSeek.headToRequests(9);
        assertEq(headToRequests.length, 0);
    }

    function test_MATCHANDSEND_happyCase() public {
        vm.startPrank(user1);
        uint256 totalRequests = 100;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: 1000 wei}(9, uint16(i % 5), i % 2 == 0);
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        mockNouns.setSeed(seed, 100);

        vm.prank(user2);
        nounSeek.matchAndSendAll(100);

        NounSeek.Request[] memory headToRequests = nounSeek.headToRequests(9);

        assertEq(headToRequests.length, totalRequests / 2);

        for (uint256 i = 0; i < headToRequests.length; i++) {
            NounSeek.Request memory request = headToRequests[i];
            assertEq(request.id, 2 * i + 1);
        }
    }
    // function test_ADD_happyCaseNewSeek() public {
    //     vm.revertTo(cleanSnapshot);
    //     _resetToRequestWindow();

    //     (uint96 requestId, uint96 seekId) = _addSeek(user1, 1);

    //     assertEq(nounSeek.seekCount(), 1);
    //     assertEq(nounSeek.requestCount(), 1);

    //     NounSeek.Seek memory seek = nounSeek.seeks(seekId);

    //     assertEq(seek.body, 5);
    //     assertEq(seek.accessory, 5);
    //     assertEq(seek.head);
    //     assertEq(seek.glasses);

    //     assertEq(seek.onlyAuctionedNoun, true);
    //     assertEq(seek.amount, 1);
    //     assertEq(seek.finder, address(0));

    //     bytes32 traitsHash = keccak256(
    //         abi.encodePacked(
    //             uint16(5),
    //             uint16(5),
    //             NO_PREFERENCE,
    //             NO_PREFERENCE,
    //             uint16(11),
    //             true
    //         )
    //     );
    //     assertEq(nounSeek.traitsHashToSeekId(traitsHash), seekId);

    //     NounSeek.Request memory request = nounSeek.requests(requestId);

    //     assertEq(request.seeker, address(user1));
    //     assertEq(request.amount, 1);
    //     assertEq(request.seekId, 1);

    //     assertEq(address(nounSeek).balance, 1);
    //     // vm.revertTo(cleanSnapshot);
    // }

    // function test_ADD_happyCaseExistingSeek() public {
    //     // vm.revertTo(cleanSnapshot);
    //     _resetToRequestWindow();

    //     _addSeek(user1, 1);

    //     (uint16 requestId, uint256 seekId) = _addSeek(user2, 1);

    //     assertEq(nounSeek.seekCount(), 1);
    //     assertEq(nounSeek.requestCount(), 2);

    //     NounSeek.Seek memory seek = nounSeek.seeks(seekId);

    //     assertEq(seek.body, 5);
    //     assertEq(seek.accessory, 5);
    //     assertEq(seek.head);
    //     assertEq(seek.glasses);

    //     assertEq(seek.onlyAuctionedNoun, true);
    //     assertEq(seek.amount, 2);
    //     assertEq(seek.finder, address(0));

    //     bytes32 traitsHash = keccak256(
    //         abi.encodePacked(
    //             uint48(5),
    //             uint48(5),
    //             NO_PREFERENCE,
    //             NO_PREFERENCE,
    //             uint256(11),
    //             true
    //         )
    //     );
    //     assertEq(nounSeek.traitsHashToSeekId(traitsHash), seekId);

    //     NounSeek.Request memory request = nounSeek.requests(requestId);

    //     assertEq(request.seeker, address(user2));
    //     assertEq(request.amount, 1);
    //     assertEq(request.seekId, 1);

    //     assertEq(address(nounSeek).balance, 2);
    // }

    // function test_ADD_failsWhenBeforeStartWindow() public {
    //     uint256 timestamp = 9999999999;
    //     mockAuctionHouse.setStartTime(timestamp);
    //     mockAuctionHouse.setEndTime(timestamp + 24 hours);

    //     vm.warp(timestamp);
    //     vm.expectRevert(NounSeek.TooSoon.selector);
    //     _addSeek(user1, 1);

    //     vm.warp(timestamp + AUCTION_START_LIMIT);
    //     vm.expectRevert(NounSeek.TooSoon.selector);
    //     _addSeek(user1, 1);
    // }

    // function test_ADD_failsWhenAfterEndWindow() public {
    //     uint256 timestamp = 9999999999;
    //     uint256 endTime = timestamp + 24 hours;
    //     mockAuctionHouse.setStartTime(timestamp);
    //     mockAuctionHouse.setEndTime(timestamp + 24 hours);
    //     vm.warp(endTime - AUCTION_END_LIMIT);
    //     vm.expectRevert(NounSeek.TooLate.selector);
    //     _addSeek(user1, 1);

    //     vm.warp(endTime);
    //     vm.expectRevert(NounSeek.TooLate.selector);
    //     _addSeek(user1, 1);
    // }

    // function test_ADD_failsIfNoPreferences() public {
    //     vm.revertTo(cleanSnapshot);
    //     _resetToRequestWindow();
    //     vm.expectRevert(NounSeek.NoPreferences.selector);
    //     nounSeek.add{value: 1}(
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );
    // }

    // function test_REMOVE_happyCase() public {
    //     _resetToRequestWindow();
    //     (uint16 requestId1, uint256 seekId) = _addSeek(user1, 1);
    //     (uint16 requestId2, ) = _addSeek(user2, 1);

    //     assertEq(nounSeek.seeks(seekId).amount, 2);
    //     assertEq(address(nounSeek).balance, 2);

    //     vm.prank(user1);
    //     vm.expectCall(address(user1), 1, "");
    //     bool remove1 = nounSeek.remove(requestId1);

    //     assertEq(remove1, true);

    //     assertEq(nounSeek.requests(requestId1).seeker, address(0));
    //     assertEq(nounSeek.requests(requestId1).amount, 0);
    //     assertEq(nounSeek.requests(requestId1).seekId, 0);

    //     assertEq(nounSeek.seekCount(), 1);
    //     assertEq(nounSeek.requestCount(), 2);

    //     assertEq(nounSeek.seeks(seekId).amount, 1);
    //     assertEq(address(nounSeek).balance, 1);

    //     vm.prank(user2);
    //     vm.expectCall(address(user2), 1, "");
    //     bool remove2 = nounSeek.remove(requestId2);

    //     assertEq(remove2, true);

    //     assertEq(nounSeek.requests(requestId2).seeker, address(0));
    //     assertEq(nounSeek.requests(requestId2).amount, 0);
    //     assertEq(nounSeek.requests(requestId2).seekId, 0);

    //     assertEq(nounSeek.seekCount(), 1);
    //     assertEq(nounSeek.requestCount(), 2);

    //     assertEq(nounSeek.seeks(seekId).body, 0);
    //     assertEq(nounSeek.seeks(seekId).accessory, 0);
    //     assertEq(nounSeek.seeks(seekId).head, 0);
    //     assertEq(nounSeek.seeks(seekId).glasses, 0);

    //     assertEq(nounSeek.seeks(seekId).onlyAuctionedNoun, false);
    //     assertEq(nounSeek.seeks(seekId).amount, 0);
    //     assertEq(address(nounSeek).balance, 0);
    // }

    // function test_REMOVE_failsWhenNotRequester() public {
    //     _resetToRequestWindow();
    //     (uint16 requestId, ) = _addSeek(user1, 1);
    //     vm.prank(user2);
    //     vm.expectRevert(NounSeek.OnlySeeker.selector);
    //     nounSeek.remove(requestId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_failsWhenAlreadyProcessed() public {
    //     _resetToRequestWindow();
    //     (uint16 requestId, ) = _addSeek(user1, 1);
    //     vm.startPrank(user1);
    //     nounSeek.remove(requestId);
    //     vm.expectRevert(NounSeek.OnlySeeker.selector);
    //     nounSeek.remove(requestId);
    //     vm.stopPrank();
    // }

    // function test_REMOVE_failsAfterMatch() public {
    //     _resetToRequestWindow();

    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );

    //     mockAuctionHouse.setNounId(11);
    //     mockNouns.setSeed(seed, 11);

    //     vm.startPrank(user1);

    //     (uint16 requestId, uint256 seekId) = nounSeek.add{value: 1}(
    //         seed.body,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     _resetToMatchWindow();

    //     assertEq(nounSeek.matchWithCurrent(seekIds)[0], true);

    //     _resetToRequestWindow();
    //     vm.expectRevert(NounSeek.AlreadyFound.selector);
    //     nounSeek.remove(requestId);
    // }

    // function test_REMOVE_failsWhenBeforeStartWindow() public {
    //     uint256 timestamp = 9999999999;
    //     mockAuctionHouse.setStartTime(timestamp);
    //     mockAuctionHouse.setEndTime(timestamp + 24 hours);
    //     vm.warp(timestamp + AUCTION_START_LIMIT + 1);
    //     (uint16 requestId, ) = _addSeek(user1, 1);

    //     vm.warp(timestamp);
    //     vm.expectRevert(NounSeek.TooSoon.selector);
    //     nounSeek.remove(requestId);

    //     vm.warp(timestamp + AUCTION_START_LIMIT);
    //     vm.expectRevert(NounSeek.TooSoon.selector);
    //     nounSeek.remove(requestId);
    // }

    // function test_REMOVE_failsWhenAfterEndWindow() public {
    //     uint256 timestamp = 9999999999;
    //     uint256 endTime = timestamp + 24 hours;
    //     mockAuctionHouse.setStartTime(timestamp);
    //     mockAuctionHouse.setEndTime(timestamp + 24 hours);
    //     vm.warp(endTime - AUCTION_END_LIMIT - 1);
    //     (uint16 requestId, ) = _addSeek(user1, 1);

    //     vm.warp(endTime - AUCTION_END_LIMIT);
    //     vm.expectRevert(NounSeek.TooLate.selector);
    //     nounSeek.remove(requestId);

    //     vm.warp(endTime);
    //     vm.expectRevert(NounSeek.TooLate.selector);
    //     nounSeek.remove(requestId);
    // }

    // function test_ADD_NO_PREFERENCENouNIdSetsOnlyAuctionedNounCorrectly()
    //     public
    // {
    //     _resetToRequestWindow();
    //     vm.prank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         5,
    //         5,
    //         5,
    //         5,
    //         NO_PREFERENCE,
    //         true
    //     );
    //     NounSeek.Seek memory seek = nounSeek.seeks(seekId);
    //     assertEq(seek.onlyAuctionedNoun, true);

    //     (, seekId) = nounSeek.add{value: 1}(5, 5, 5, 5, false);
    //     seek = nounSeek.seeks(seekId);
    //     assertEq(seek.onlyAuctionedNoun, false);
    // }

    // function test_ADD_NounIdOnlyAuctionedNounCorrectly() public {
    //     _resetToRequestWindow();
    //     vm.prank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1}(5, 5, 5, 5, 11, false);

    //     NounSeek.Seek memory seek = nounSeek.seeks(seekId);
    //     assertEq(seek.onlyAuctionedNoun, true);
    // }

    // function test_SEEKMATCHESTRAITS_body_anyId_anyNounType() public {
    //     vm.startPrank(user1);
    //     _resetToRequestWindow();
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
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
    //     assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
    //     // Correct Seed, Non-Auctioned Noun
    //     assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

    //     // Incorrect Seed, Auctioned Noun
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
    //     // Incorrect Seed, Non-Auctioned Noun
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    // }

    // function test_SEEKMATCHESTRAITS_body_specificId_nonAuctioned() public {
    //     _resetToRequestWindow();
    //     vm.startPrank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
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
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed1, seekId));
    //     // Correct Seed, matching Id
    //     assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

    //     // Incorrect Seed,  non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
    //     // Incorrect Seed, matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    // }

    // function test_SEEKMATCHESTRAITS_body_specificId_Auctioned() public {
    //     _resetToRequestWindow();
    //     vm.startPrank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
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
    //     assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
    //     // Correct Seed, non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed1, seekId));

    //     // Incorrect Seed,  matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
    //     // Incorrect Seed, non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    // }

    // function test_SEEKMATCHESTRAITS_body_head_anyId_Auctioned() public {
    //     vm.startPrank(user1);
    //     _resetToRequestWindow();
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         true
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
    //     assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
    //     // Correct Seed, non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed1, seekId));

    //     // Incorrect Seed,  matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
    //     // Incorrect Seed, non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    // }

    // function test_SEEKMATCHESTRAITS_body_head_anyId_nonAuctioned() public {
    //     vm.startPrank(user1);
    //     _resetToRequestWindow();
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
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
    //     assertEq(true, nounSeek.seekMatchesTraits(5, seed1, seekId));
    //     // Correct Seed, matching Id
    //     assertEq(true, nounSeek.seekMatchesTraits(20, seed1, seekId));

    //     // Incorrect Seed,  matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed2, seekId));
    //     // Incorrect Seed, non-matching Id
    //     assertEq(false, nounSeek.seekMatchesTraits(20, seed2, seekId));
    // }

    // function test_SEEKMATCHESTRAITS_alreadyFound() public {
    //     vm.startPrank(user1);
    //     _resetToRequestWindow();
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
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
    //     mockNouns.setSeed(seed, 6);

    //     // Before match
    //     assertEq(true, nounSeek.seekMatchesTraits(5, seed, seekId));

    //     // Match
    //     _resetToMatchWindow();
    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;
    //     assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);

    //     // After match
    //     assertEq(false, nounSeek.seekMatchesTraits(5, seed, seekId));
    // }

    // function test_MATCHWITHCURRENT_anyId_onlyAuctioned() public {
    //     _resetToRequestWindow();

    //     vm.prank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         true
    //     );

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;
    //     mockAuctionHouse.setNounId(11);

    //     _resetToMatchWindow();

    //     vm.startPrank(user2);

    //     // Seed does not match, Id does not match
    //     assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);

    //     assertEq(address(0), nounSeek.seeks(seekId).finder);
    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );

    //     // Set matching seed for non-auctioned Noun
    //     mockNouns.setSeed(seed, 10);

    //     // Seed matches, Id does not match
    //     assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);
    //     assertEq(address(0), nounSeek.seeks(seekId).finder);

    //     // Set current auctioned noun to correct seed
    //     seed.background = 1;
    //     mockNouns.setSeed(seed, 11);
    //     // Seed matches, Id matches
    //     vm.expectCall(
    //         address(mockNouns),
    //         abi.encodeCall(mockNouns.seeds, (11))
    //     );
    //     assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);

    //     assertEq(address(user2), nounSeek.seeks(seekId).finder);

    //     vm.stopPrank();

    //     vm.prank(user3);
    //     // Attempt to match again
    //     assertEq(false, nounSeek.matchWithCurrent(seekIds)[0]);
    //     assertEq(address(user2), nounSeek.seeks(seekId).finder);
    // }

    // function test_MATCHWITHCURRENT_anyId_nonAuctioned() public {
    //     _resetToRequestWindow();

    //     vm.prank(user1);
    //     (, uint256 seekId1) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );

    //     uint256[] memory seekIds1 = new uint256[](1);
    //     seekIds1[0] = seekId1;
    //     mockAuctionHouse.setNounId(11);

    //     // Seek2 with similar matching traits
    //     (, uint256 seekId2) = nounSeek.add{value: 1}(
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );

    //     uint256[] memory seekIds2 = new uint256[](1);
    //     seekIds2[0] = seekId2;

    //     mockAuctionHouse.setNounId(11);

    //     _resetToMatchWindow();

    //     vm.startPrank(user2);

    //     // Seed does not match, Id does not match
    //     assertEq(false, nounSeek.matchWithCurrent(seekIds1)[0]);

    //     assertEq(address(0), nounSeek.seeks(seekId1).finder);
    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );

    //     // Set matching seed for non-auctioned Noun
    //     mockNouns.setSeed(seed, 10);

    //     // Seed matches, Id does not match
    //     assertEq(true, nounSeek.matchWithCurrent(seekIds1)[0]);
    //     assertEq(address(user2), nounSeek.seeks(seekId1).finder);

    //     // Set current auctioned noun to auctioned noun seed
    //     seed.background = 1;
    //     mockNouns.setSeed(seed, 11);

    //     // Seed matches, Id matches, already matched
    //     assertEq(false, nounSeek.matchWithCurrent(seekIds1)[0]);
    //     assertEq(address(user2), nounSeek.seeks(seekId1).finder);

    //     // Seed matches, Id matches, seek2 has not been matched
    //     assertEq(true, nounSeek.matchWithCurrent(seekIds2)[0]);
    //     assertEq(address(user2), nounSeek.seeks(seekId2).finder);

    //     vm.stopPrank();
    // }

    // function test_MATCHWITHCURRENT_outsideMatchWindow() public {
    //     _resetToRequestWindow();

    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );

    //     mockAuctionHouse.setNounId(11);
    //     mockNouns.setSeed(seed, 11);

    //     vm.prank(user1);

    //     (, uint256 seekId) = nounSeek.add{value: 1}(
    //         seed.body,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     vm.expectRevert(NounSeek.TooLate.selector);
    //     nounSeek.matchWithCurrent(seekIds);
    // }

    // function test_MATCHWITHCURRENT_twoSeeksOneFails() public {
    //     _resetToRequestWindow();
    //     vm.startPrank(user1);
    //     (, uint256 seekId1) = nounSeek.add{value: 1}(
    //         10,
    //         10,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );
    //     (, uint256 seekId2) = nounSeek.add{value: 1}(
    //         11,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );
    //     vm.stopPrank();

    //     assertEq(address(0), nounSeek.seeks(seekId1).finder);
    //     assertEq(address(0), nounSeek.seeks(seekId2).finder);

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

    //     _resetToMatchWindow();
    //     vm.expectCall(
    //         address(mockNouns),
    //         abi.encodeCall(mockNouns.seeds, (10))
    //     );
    //     vm.expectCall(
    //         address(mockNouns),
    //         abi.encodeCall(mockNouns.seeds, (11))
    //     );
    //     bool[] memory matches = nounSeek.matchWithCurrent(seekIds);

    //     assertEq(true, matches[0]);
    //     assertEq(false, matches[1]);
    //     assertEq(address(user2), nounSeek.seeks(seekId1).finder);
    //     assertEq(address(0), nounSeek.seeks(seekId2).finder);
    // }

    // function test_finderWITHDRAW() public {
    //     INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
    //         0,
    //         10,
    //         10,
    //         0,
    //         0
    //     );
    //     _resetToRequestWindow();
    //     vm.prank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1 ether}(
    //         seed.body,
    //         seed.accessory,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         true
    //     );

    //     // Sanity check on balance
    //     assertEq(1 ether, address(nounSeek).balance);
    //     assertEq(1 ether, nounSeek.seeks(seekId).amount);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     // Jump to start of auction to allow `find()`
    //     vm.warp(mockAuctionHouse.auction().startTime);
    //     mockNouns.setSeed(seed, 9);
    //     mockAuctionHouse.setNounId(9);

    //     vm.prank(user2);
    //     assertEq(true, nounSeek.matchWithCurrent(seekIds)[0]);
    //     assertEq(address(user2), nounSeek.seeks(seekId).finder);

    //     vm.prank(user3);
    //     vm.expectRevert(NounSeek.OnlyFinder.selector);
    //     nounSeek.withdraw(seekId);

    //     vm.startPrank(user2);

    //     vm.expectCall(address(user2), 1 ether, "");
    //     assertEq(true, nounSeek.withdraw(seekId));
    //     assertEq(nounSeek.seeks(seekId).amount, 0);
    //     assertEq(address(nounSeek).balance, 0);

    //     // user2 attempts to withdraw again, 0 is sent
    //     vm.expectCall(address(user2), 0, "");
    //     assertEq(true, nounSeek.withdraw(seekId));
    // }

    // function test_SETTLEANDMATCH_happyCase() public {
    //     _resetToRequestWindow();
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

    //     vm.prank(user1);
    //     (, uint256 seekId) = nounSeek.add{value: 1 ether}(
    //         seed11.body,
    //         seed11.accessory,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         NO_PREFERENCE,
    //         false
    //     );

    //     mockNouns.setSeed(seed10, 10);
    //     mockNouns.setSeed(seed11, 11);
    //     mockAuctionHouse.setNounId(9);

    //     uint256[] memory seekIds = new uint256[](1);
    //     seekIds[0] = seekId;

    //     vm.startPrank(user2);
    //     vm.expectCall(
    //         address(mockAuctionHouse),
    //         abi.encodeCall(
    //             mockAuctionHouse.settleCurrentAndCreateNewAuction,
    //             ()
    //         )
    //     );

    //     bytes32 forgeMockBlockHash = 0x290DECD9548B62A8D60345A988386FC84BA6BC95484008F6362F93160EF3E563;
    //     bool[] memory matches = nounSeek.settleAndMatch(
    //         forgeMockBlockHash,
    //         seekIds
    //     );

    //     assertEq(address(user2), nounSeek.seeks(seekId).finder);
    //     assertEq(matches[0], true);
    // }

    // function test_SETTLEANDMATCH_failBlockHashMismatch() public {
    //     uint256[] memory seekIds = new uint256[](1);
    //     vm.expectRevert(NounSeek.BlockHashMismatch.selector);
    //     nounSeek.settleAndMatch(0x0, seekIds);
    // }
}
