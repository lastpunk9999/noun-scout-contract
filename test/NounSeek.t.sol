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
    uint16 NO_PREFERENCE;
    uint16 MAX;
    NounSeek.Traits BACKGROUND = NounSeek.Traits.BACKGROUND;
    NounSeek.Traits HEAD = NounSeek.Traits.HEAD;
    NounSeek.Traits GLASSES = NounSeek.Traits.GLASSES;
    NounSeek.Traits ACCESSORY = NounSeek.Traits.ACCESSORY;

    function setUp() public {
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse);

        AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
        AUCTION_START_LIMIT = nounSeek.AUCTION_START_LIMIT();
        NO_PREFERENCE = nounSeek.NO_PREFERENCE();
        MAX = NO_PREFERENCE;
        nounSeek.addDonee("donee1", donee1);
        nounSeek.addDonee("donee2", donee2);
        nounSeek.addDonee("donee3", donee3);
        nounSeek.addDonee("donee4", donee4);
        nounSeek.addDonee("donee5", donee5);

        mockDescriptor.setHeadCount(99);
        mockDescriptor.setGlassesCount(98);
        mockDescriptor.setAccessoryCount(97);
        mockDescriptor.setBodyCount(96);
        mockDescriptor.setBackgroundCount(95);
        nounSeek.updateTraitCounts();
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

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounSeek.nouns()));
        assertEq(nounSeek.headCount(), 99);
        assertEq(nounSeek.glassesCount(), 98);
        assertEq(nounSeek.accessoryCount(), 97);
        assertEq(nounSeek.bodyCount(), 96);
        assertEq(nounSeek.backgroundCount(), 95);
    }

    function test_ADD_happyCase() public {
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        NounSeek.Request memory request = nounSeek.requests(requestId);

        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );
        assertEq(headRequestIds.length, 1);
        assertEq(headRequestIds[0], requestId);

        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests.length, 1);
        assertEq(headRequests[0].requester, request.requester);
        assertEq(headRequests[0].seekIndex, 0);

        assertEq(request.seekIndex, 0);
        assertEq(uint8(request.trait), uint8(HEAD));
        assertEq(request.traitId, 9);
        assertEq(request.doneeId, 1);

        // assertEq(request.minNounId, 100);
        assertEq(request.nounId, NO_PREFERENCE);
        assertEq(request.requester, address(user1));
        assertEq(request.amount, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 0);

        NounSeek.Request memory request2 = nounSeek.requests(requestId2);
        uint16[] memory headRequestIds2 = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );

        assertEq(headRequestIds2.length, 2, "headRequestIds2.length");
        assertEq(headRequestIds2[1], requestId2);

        NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests2.length, 2, "headRequests2.length");
        assertEq(headRequests2[0].requester, request.requester);
        assertEq(headRequests2[1].requester, request2.requester);
        assertEq(headRequests2[0].seekIndex, 0);
        assertEq(headRequests2[1].seekIndex, 1);

        assertEq(request2.seekIndex, 1, "seekIndex");
        assertEq(request2.traitId, 9);
        assertEq(request2.doneeId, 0);

        // assertEq(request2.minNounId, 100);
        assertEq(request2.requester, address(user2));
        assertEq(request2.amount, 1);

        // Same head, but with Noun Id
        vm.prank(user3);
        uint16 requestId3 = nounSeek.add{value: 2}(HEAD, 9, 100, 2);

        NounSeek.Request memory request3 = nounSeek.requests(requestId3);

        uint16[] memory headRequestIds3 = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            100
        );
        assertEq(headRequestIds3.length, 1);
        assertEq(headRequestIds3[0], requestId3);

        NounSeek.Request[] memory headRequests3 = nounSeek.requestsForTrait(
            HEAD,
            9,
            100,
            NO_PREFERENCE
        );
        assertEq(headRequests3.length, 1);
        assertEq(headRequests3[0].requester, request3.requester);
        assertEq(headRequests3[0].seekIndex, 0);

        assertEq(request3.seekIndex, 0);
        assertEq(uint8(request3.trait), uint8(HEAD));
        assertEq(request3.traitId, 9);
        assertEq(request3.doneeId, 2);

        // assertEq(request3.minNounId, 100);
        assertEq(request3.nounId, 100);
        assertEq(request3.requester, address(user3));
        assertEq(request3.amount, 2);
    }

    function test_REMOVE_happyCaseFIFO() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 0);

        vm.prank(user1);
        vm.expectRevert();
        nounSeek.remove(requestId2);

        vm.expectCall(address(user1), 1, "");
        vm.prank(user1);
        nounSeek.remove(requestId);
        assertEq(address(nounSeek).balance, 1);
        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );

        assertEq(headRequestIds.length, 1);
        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests.length, 1);
        assertEq(headRequests[0].id, requestId2);
        assertEq(headRequests[0].seekIndex, 0);
        assertEq(headRequests[0].requester, address(user2));

        vm.expectCall(address(user2), 1, "");

        vm.prank(user2);
        nounSeek.remove(requestId2);

        assertEq(address(nounSeek).balance, 0);

        uint16[] memory headRequestIds2 = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );

        assertEq(headRequestIds2.length, 0);
        NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests2.length, 0);

        vm.prank(user2);
        vm.expectRevert();
        nounSeek.remove(requestId2);
    }

    function test_REMOVE_happyCaseLIFO() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 0);

        vm.expectCall(address(user2), 1, "");
        vm.prank(user2);
        nounSeek.remove(requestId2);
        assertEq(address(nounSeek).balance, 1);
        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );

        assertEq(headRequestIds.length, 1);
        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests.length, 1);
        assertEq(headRequests[0].id, requestId);
        assertEq(headRequests[0].seekIndex, 0);
        assertEq(headRequests[0].requester, address(user1));

        vm.expectCall(address(user1), 1, "");
        vm.prank(user1);

        nounSeek.remove(requestId);

        assertEq(address(nounSeek).balance, 0);

        uint16[] memory headRequestIds2 = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            NO_PREFERENCE
        );

        assertEq(headRequestIds2.length, 0);
        NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );
        assertEq(headRequests2.length, 0);
    }

    function test_REMOVE_failsWhenTraitMatchesCurrentNounNoPrefId() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 109);
        mockAuctionHouse.setNounId(109);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                109
            )
        );

        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesPreviousNounNoPrefId() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 108);
        mockAuctionHouse.setNounId(109);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                108
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesPreviousNounWhenNonConsecutiveNoPrefId()
        public
    {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, NO_PREFERENCE, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 199);
        mockAuctionHouse.setNounId(201);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                199
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesCurrentNounWithPrefId() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 109, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 109);
        mockAuctionHouse.setNounId(109);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                109
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesPreviousNounWithPrefId() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 108, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 108);
        mockAuctionHouse.setNounId(109);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                108
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesPreviousNounWhenNonConsecutiveWithPrefId()
        public
    {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 199, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 199);
        mockAuctionHouse.setNounId(201);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                199
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenTraitMatchesNonAuctionedNoun() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 200, 1);

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );

        // Current auctioned Noun has seed
        mockNouns.setSeed(seed, 200);
        mockAuctionHouse.setNounId(201);

        vm.expectRevert(
            abi.encodeWithSelector(
                NounSeek.MatchFound.selector,
                NounSeek.Traits.HEAD,
                9,
                200
            )
        );
        vm.prank(user1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenNotWithinAuctionEndWindow() public {
        vm.startPrank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 200, 1);

        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + AUCTION_END_LIMIT);
        vm.warp(timestamp);

        vm.expectRevert(NounSeek.TooLate.selector);
        nounSeek.remove(requestId);
        vm.warp(timestamp - 1);
        nounSeek.remove(requestId);
    }

    function test_REMOVE_failsWhenAuctionIsOver() public {
        vm.startPrank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, 200, 1);

        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp);
        vm.warp(timestamp);

        vm.expectRevert(NounSeek.TooLate.selector);
        nounSeek.remove(requestId);
    }

    function test_matchPreviousNounAndDonate_NonAuctionedNounHappyCase()
        public
    {
        vm.startPrank(user1);
        uint256 totalRequests = 100;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: 1000 wei}(
                HEAD,
                9,
                i % 2 == 0 ? 101 : 100,
                uint8(i % 2)
            );
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
        mockAuctionHouse.setNounId(102);
        vm.prank(user2);
        nounSeek.matchPreviousNounAndDonate(HEAD, MAX);
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            101,
            MAX
        );
        assertEq(
            noPrefRequests.length,
            totalRequests / 2,
            "noPrefRequests.length"
        );
        for (uint256 i = 0; i < noPrefRequests.length; i++) {
            NounSeek.Request memory request = noPrefRequests[i];
            assertEq(request.id, 2 * i + 1, "request.id");
            assertEq(request.seekIndex, i, "request.seekIndex");
        }
        NounSeek.Request[] memory nounIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            100,
            MAX
        );

        assertEq(nounIdRequests.length, 0, "nounIdRequests.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i % 2 == 1 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(
                uint16(nounSeek.requests(i).nounId),
                i % 2 == 1 ? 101 : 0,
                "nounSeek.requests(i).nounId"
            );
            assertEq(request.id, i % 2 == 1 ? i : 0, "request.id");
        }
    }

    function test_matchPreviousNounAndDonate_auctionedNounOnlyNoPreferenceMatchesHappyCase()
        public
    {
        vm.startPrank(user1);
        uint256 totalRequests = 100;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: 1000 wei}(
                HEAD,
                9,
                i % 2 == 0 ? 102 : NO_PREFERENCE,
                uint8(i % 2)
            );
        }
        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(102);
        vm.prank(user2);
        nounSeek.matchPreviousNounAndDonate(HEAD, MAX);
        NounSeek.Request[] memory nounIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            102,
            MAX
        );
        assertEq(
            nounIdRequests.length,
            totalRequests / 2,
            "nounIdRequests.length"
        );
        for (uint256 i = 0; i < nounIdRequests.length; i++) {
            NounSeek.Request memory request = nounIdRequests[i];
            assertEq(request.id, 2 * i + 1);
            assertEq(request.seekIndex, i);
        }
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            MAX
        );

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i % 2 == 1 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(
                uint16(nounSeek.requests(i).nounId),
                i % 2 == 1 ? 102 : 0,
                "nounSeek.requests(i).nounId"
            );
            assertEq(request.id, i % 2 == 1 ? i : 0, "request.id");
        }
    }

    function test_matchPreviousNounAndDonate_auctionedNounNounIdAndNoPreferenceMatchesHappyCase()
        public
    {
        vm.startPrank(user1);
        uint256 totalRequests = 100;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: 1000 wei}(
                HEAD,
                9,
                i % 2 == 0 ? 101 : NO_PREFERENCE,
                uint8(i % 2)
            );
        }
        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 101);
        mockAuctionHouse.setNounId(102);
        vm.prank(user2);
        nounSeek.matchPreviousNounAndDonate(HEAD, NO_PREFERENCE);
        NounSeek.Request[] memory nounIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            102,
            NO_PREFERENCE
        );
        assertEq(nounIdRequests.length, 0);

        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            NO_PREFERENCE,
            NO_PREFERENCE
        );

        assertEq(noPrefRequests.length, 0);

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(uint16(nounSeek.requests(i).trait), uint16(BACKGROUND));
            assertEq(uint16(nounSeek.requests(i).nounId), 0);
            assertEq(request.id, 0);
        }
    }
}
