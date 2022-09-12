// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/NounSeek.sol";
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
    uint16 ANY_ID;
    uint16 MAX = 9999 wei;
    uint256 reimbursementBPS;
    NounSeek.Traits BACKGROUND = NounSeek.Traits.BACKGROUND;
    NounSeek.Traits HEAD = NounSeek.Traits.HEAD;
    NounSeek.Traits GLASSES = NounSeek.Traits.GLASSES;
    NounSeek.Traits ACCESSORY = NounSeek.Traits.ACCESSORY;

    function setUp() public {
        mockAuctionHouse = new MockAuctionHouse();
        mockDescriptor = new MockDescriptor();
        mockNouns = new MockNouns(address(mockDescriptor));
        nounSeek = new NounSeek(mockNouns, mockAuctionHouse, IWETH(address(0)));

        AUCTION_END_LIMIT = nounSeek.AUCTION_END_LIMIT();
        ANY_ID = nounSeek.ANY_ID();
        reimbursementBPS = nounSeek.reimbursementBPS();

        nounSeek.addDonee("donee1", donee1);
        nounSeek.addDonee("donee2", donee2);
        nounSeek.addDonee("donee3", donee3);
        nounSeek.addDonee("donee4", donee4);
        nounSeek.addDonee("donee5", donee5);

        mockDescriptor.setHeadCount(242);
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
    //             ANY_ID,
    //             ANY_ID,
    //             11,
    //             true
    //         );
    // }

    // function captureSnapshot() internal {
    //     cleanSnapshot = vm.snapshot();
    // }

    function testConstructor() public {
        assertEq(address(mockNouns), address(nounSeek.nouns()));
        assertEq(nounSeek.headCount(), 242);
        assertEq(nounSeek.glassesCount(), 98);
        assertEq(nounSeek.accessoryCount(), 97);
        assertEq(nounSeek.bodyCount(), 96);
        assertEq(nounSeek.backgroundCount(), 95);
    }

    function test_ALLTRAITREQUESTSFORUPCOMINGNOUN_nextNounIsNonAuctioned()
        public
    {
        // Current auctioned Noun is 99
        for (uint16 i; i < 33; i++) {
            for (uint16 j; j < 5; j++) {
                nounSeek.add{value: 1}(HEAD, i, ANY_ID, j);
            }
        }
        for (uint16 i; i < 33; i++) {
            for (uint16 j; j < 5; j++) {
                nounSeek.add{value: 1}(HEAD, i, 100, j);
            }
        }
        for (uint16 i; i < 34; i++) {
            for (uint16 j; j < 5; j++) {
                nounSeek.add{value: 1}(HEAD, i, 101, j);
            }
        }

        (
            uint16 any_id,
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            NounSeek.Request[][] memory anyIdRequests,
            NounSeek.Request[][] memory nextAuctionedRequests,
            NounSeek.Request[][] memory nextNonAuctionedRequests
        ) = nounSeek.allTraitRequestsForNextNoun(HEAD);

        assertEq(any_id, ANY_ID);
        assertEq(nextNonAuctionedId, 100);
        assertEq(nextAuctionedId, 101);
        assertEq(anyIdRequests.length, nounSeek.headCount());
        assertEq(nextAuctionedRequests.length, nounSeek.headCount());
        assertEq(nextNonAuctionedRequests.length, nounSeek.headCount());

        assertEq(anyIdRequests[0].length, 5);
        assertEq(anyIdRequests[32].length, 5);
        assertEq(anyIdRequests[0][0].id, 1);
        assertEq(anyIdRequests[33].length, 0);

        assertEq(nextNonAuctionedRequests[0].length, 5);
        assertEq(nextNonAuctionedRequests[32].length, 5);
        assertEq(nextNonAuctionedRequests[0][0].id, (33 * 5) + 1);
        assertEq(nextNonAuctionedRequests[33].length, 0);

        assertEq(nextAuctionedRequests[0].length, 5);
        assertEq(nextAuctionedRequests[33].length, 5);
        assertEq(nextAuctionedRequests[0][0].id, (33 * 5 * 2) + 1);
        assertEq(nextAuctionedRequests[34].length, 0);
    }

    function test_ALLTRAITREQUESTSFORNOUN() public {
        for (uint16 i; i < 20; i++) {
            for (uint16 j; j < 5; j++) {
                nounSeek.add{value: 1}(HEAD, i, ANY_ID, j);
            }
        }
        for (uint16 i; i < 20; i++) {
            for (uint16 j; j < 5; j++) {
                nounSeek.add{value: 1}(HEAD, i, 5, j);
            }
        }
        (
            NounSeek.Request[][] memory anyIdRequests,
            NounSeek.Request[][] memory nounIdRequests
        ) = nounSeek.allTraitRequestsForNoun(HEAD, 5);

        assertEq(anyIdRequests.length, nounSeek.headCount());
        assertEq(anyIdRequests[0].length, 5);
        assertEq(anyIdRequests[0][0].id, 1);
        assertEq(anyIdRequests[20].length, 0);

        assertEq(nounIdRequests.length, nounSeek.headCount());
        assertEq(nounIdRequests[0].length, 5);
        assertEq(nounIdRequests[0][0].id, 101);
        assertEq(nounIdRequests[20].length, 0);
    }

    function test_ADD_happyCase() public {
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

        NounSeek.Request memory request = nounSeek.requests(requestId);

        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );
        assertEq(headRequestIds.length, 1);
        assertEq(headRequestIds[0], requestId);

        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );
        assertEq(headRequests.length, 1);
        assertEq(headRequests[0].requester, request.requester);
        assertEq(headRequests[0].seekIndex, 0);

        assertEq(request.seekIndex, 0);
        assertEq(uint8(request.trait), uint8(HEAD));
        assertEq(request.traitId, 9);
        assertEq(request.doneeId, 1);

        // assertEq(request.minNounId, 100);
        assertEq(request.nounId, ANY_ID);
        assertEq(request.requester, address(user1));
        assertEq(request.amount, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 0);

        NounSeek.Request memory request2 = nounSeek.requests(requestId2);
        uint16[] memory headRequestIds2 = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );

        assertEq(headRequestIds2.length, 2, "headRequestIds2.length");
        assertEq(headRequestIds2[1], requestId2);

        NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
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
            MAX
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
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 0);

        vm.prank(user1);
        vm.expectRevert(NounSeek.NotRequester.selector);
        nounSeek.remove(requestId2);

        vm.expectCall(address(user1), 1, "");
        vm.prank(user1);
        nounSeek.remove(requestId);
        assertEq(address(nounSeek).balance, 1);
        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );

        assertEq(headRequestIds.length, 1);
        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );
        assertEq(headRequests.length, 1);
        assertEq(headRequests[0].id, requestId2);
        // assertEq(headRequests[0].seekIndex, 0);
        // assertEq(headRequests[0].requester, address(user2));

        // vm.expectCall(address(user2), 1, "");

        // vm.prank(user2);
        // nounSeek.remove(requestId2);

        // assertEq(address(nounSeek).balance, 0);

        // uint16[] memory headRequestIds2 = nounSeek.requestIdsForTrait(
        //     HEAD,
        //     9,
        //     ANY_ID
        // );

        // assertEq(headRequestIds2.length, 0);
        // NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
        //     HEAD,
        //     9,
        //     ANY_ID,
        //     ANY_ID
        // );
        // assertEq(headRequests2.length, 0);

        // vm.prank(user2);
        // vm.expectRevert();
        // nounSeek.remove(requestId2);
    }

    function test_REMOVE_happyCaseLIFO() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);
        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

        vm.prank(user2);
        uint16 requestId2 = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 0);

        vm.expectCall(address(user2), 1, "");
        vm.prank(user2);
        nounSeek.remove(requestId2);
        assertEq(address(nounSeek).balance, 1);
        uint16[] memory headRequestIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );

        assertEq(headRequestIds.length, 1);
        NounSeek.Request[] memory headRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
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
            ANY_ID
        );

        assertEq(headRequestIds2.length, 0);
        NounSeek.Request[] memory headRequests2 = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            ANY_ID
        );
        assertEq(headRequests2.length, 0);
    }

    function test_REMOVE_failsWhenTraitMatchesCurrentNounNoPrefId() public {
        uint256 timestamp = 9999999999;
        mockAuctionHouse.setEndTime(timestamp + 24 hours);
        vm.warp(timestamp);
        vm.prank(user1);

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

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

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

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

        uint16 requestId = nounSeek.add{value: 1}(HEAD, 9, ANY_ID, 1);

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

    function test_MATCHANDDONATE_auctionedSpecificIdNounHappyCase() public {
        vm.startPrank(user1);
        uint256 totalRequests = 4;
        uint256 value = 1000 wei;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: value}(
                HEAD,
                9,
                i % 2 == 0 ? 100 : 101,
                uint8(i % 4)
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

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;
        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(address(donee2), value - reimbursement_per_donation, "");
        vm.expectCall(address(donee4), value - reimbursement_per_donation, "");

        nounSeek.matchAndDonate(101, HEAD, MAX);
        NounSeek.Request[] memory ineligibleReqs = nounSeek.requestsForTrait(
            HEAD,
            9,
            100,
            MAX
        );
        assertEq(
            ineligibleReqs.length,
            totalRequests / 2,
            "ineligibleReqs.length"
        );
        for (uint256 i = 0; i < ineligibleReqs.length; i++) {
            NounSeek.Request memory request = ineligibleReqs[i];
            assertEq(request.id, 2 * i + 1, "request.id");
            assertEq(request.seekIndex, i, "request.seekIndex");
        }
        NounSeek.Request[] memory eligibleIdRequests = nounSeek
            .requestsForTrait(HEAD, 9, 101, MAX);

        assertEq(eligibleIdRequests.length, 0, "eligibleIdRequests.length");

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
                i % 2 == 1 ? 100 : 0,
                "nounSeek.requests(i).nounId"
            );
            assertEq(request.id, i % 2 == 1 ? i : 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_auctionedNounNoPreferenceMatchesHappyCase()
        public
    {
        vm.startPrank(user1);
        uint256 totalRequests = 4;
        uint256 value = 1000 wei;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: value}(
                HEAD,
                9,
                i % 2 == 0 ? 101 : ANY_ID,
                uint8(i % 4)
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

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;
        vm.expectCall(address(user2), reimbursement_per_donation * 4, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee3),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee4),
            (value - reimbursement_per_donation),
            ""
        );

        vm.prank(user2);
        nounSeek.matchAndDonate(101, HEAD, MAX);
        NounSeek.Request[] memory nounIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            101,
            MAX
        );
        assertEq(nounIdRequests.length, 0, "nounIdRequests.length");

        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(
                uint16(nounSeek.requests(i).nounId),
                0,
                "nounSeek.requests(i).nounId"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_auctionedAfterNonAuctionedNounAndNoPreferenceMatchesHappyCase()
        public
    {
        // current auction = 201
        // target noun = 199
        // (noun id 200 in between)
        vm.startPrank(user1);
        uint256 totalRequests = 4;
        uint256 value = 1000 wei;
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: value}(
                HEAD,
                9,
                i % 2 == 0 ? 199 : ANY_ID,
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
        mockNouns.setSeed(seed, 199);
        mockAuctionHouse.setNounId(201);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 4, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation) * 2,
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation) * 2,
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(199, HEAD, MAX);
        NounSeek.Request[] memory nounIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            199,
            MAX
        );
        assertEq(nounIdRequests.length, 0, "nounIdRequests.length");

        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(
                uint16(nounSeek.requests(i).nounId),
                0,
                "nounSeek.requests(i).nounId"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_nonAuctionedMatchesHappyCase() public {
        // current auction = 201
        // target noun = 200
        vm.startPrank(user1);
        uint256 totalRequests = 8;
        uint256 value = 1000 wei;
        // target = 200
        for (uint256 i; i < (totalRequests / 4); i++) {
            nounSeek.add{value: value}(HEAD, 9, 200, uint8(i % 2));
        }
        // target = 201
        for (uint256 i; i < (totalRequests / 4); i++) {
            nounSeek.add{value: value}(HEAD, 9, 201, uint8(i % 2));
        }
        // target = ANY_ID
        for (uint256 i; i < (totalRequests / 4); i++) {
            nounSeek.add{value: value}(HEAD, 9, ANY_ID, uint8(i % 2));
        }
        // target = 200
        // head = 10
        for (uint256 i; i < (totalRequests / 4); i++) {
            nounSeek.add{value: value}(HEAD, 10, 200, uint8(i % 2));
        }
        vm.stopPrank();
        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 200);
        mockNouns.setSeed(seed, 201);
        mockNouns.setSeed(seed, 199);
        mockAuctionHouse.setNounId(201);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(200, HEAD, MAX);
        NounSeek.Request[] memory matchIdRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            200,
            MAX
        );

        assertEq(matchIdRequests.length, 0, "matchIdRequests.length");

        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(
            noPrefRequests.length,
            totalRequests / 4,
            "noPrefRequests.length"
        );

        NounSeek.Request[] memory nonMatchingIdRequests = nounSeek
            .requestsForTrait(HEAD, 9, 201, MAX);

        assertEq(
            nonMatchingIdRequests.length,
            totalRequests / 4,
            "nonMatchingIdRequests.length"
        );

        NounSeek.Request[] memory nonMatchingHeadRequestIds = nounSeek
            .requestsForTrait(HEAD, 10, 200, MAX);

        assertEq(
            nonMatchingHeadRequestIds.length,
            totalRequests / 4,
            "nonMatchingHeadRequestIds.length"
        );

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests / 4 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            if (i > (totalRequests / 4) * 1 && i <= (totalRequests / 4) * 2) {
                assertEq(
                    uint16(nounSeek.requests(i).nounId),
                    201,
                    "nounSeek.requests(i).nounId"
                );
            }

            if (i > (totalRequests / 4) * 2 && i <= (totalRequests / 4) * 3) {
                assertEq(
                    uint16(nounSeek.requests(i).nounId),
                    ANY_ID,
                    "nounSeek.requests(i).nounId"
                );
            }

            if (i > (totalRequests / 4) * 3 && i <= (totalRequests / 4) * 4) {
                assertEq(
                    uint16(nounSeek.requests(i).nounId),
                    200,
                    "nounSeek.requests(i).nounId"
                );
            }

            assertEq(request.id, i > totalRequests / 4 ? i : 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_MaxAnyIdHappyCase() public {
        // current auction = 201
        // target noun = 200

        uint256 totalRequests = 4;
        uint256 value = 1000 wei;

        vm.startPrank(user1);
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: value}(HEAD, 9, ANY_ID, uint8(i % 2));
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 201);
        mockAuctionHouse.setNounId(202);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        uint16[] memory noPrefRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );
        assertEq(noPrefRequestsIds.length, totalRequests);
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(
            noPrefRequests.length,
            totalRequests / 2,
            "noPrefRequests.length2"
        );

        assertEq(noPrefRequests[0].id, totalRequests / 2 + 1);
        assertEq(noPrefRequests[1].id, (totalRequests / 2) + 2);

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests / 2 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, i > totalRequests / 2 ? i : 0, "request.id");
        }

        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        noPrefRequestsIds = nounSeek.requestIdsForTrait(HEAD, 9, ANY_ID);
        assertEq(noPrefRequestsIds.length, totalRequests);
        noPrefRequests = nounSeek.requestsForTrait(HEAD, 9, ANY_ID, MAX);

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length2");

        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_MaxSpecificHappyCase() public {
        // current auction = 201
        // target noun = 200

        uint256 totalRequests = 4;
        uint256 value = 1000 wei;

        vm.startPrank(user1);
        for (uint256 i; i < totalRequests; i++) {
            nounSeek.add{value: value}(HEAD, 9, 201, uint8(i % 2));
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 201);
        mockAuctionHouse.setNounId(202);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        uint16[] memory noPrefRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            201
        );
        assertEq(noPrefRequestsIds.length, totalRequests);
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            201,
            MAX
        );

        assertEq(
            noPrefRequests.length,
            totalRequests / 2,
            "noPrefRequests.length2"
        );

        assertEq(noPrefRequests[0].id, totalRequests / 2 + 1);
        assertEq(noPrefRequests[1].id, (totalRequests / 2) + 2);

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests / 2 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, i > totalRequests / 2 ? i : 0, "request.id");
        }

        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        noPrefRequestsIds = nounSeek.requestIdsForTrait(HEAD, 9, 201);
        assertEq(noPrefRequestsIds.length, totalRequests);
        noPrefRequests = nounSeek.requestsForTrait(HEAD, 9, 201, MAX);

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length2");

        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_MaxAllAnyThenSpecificHappyCase() public {
        // current auction = 201
        // target noun = 200

        uint256 totalRequests = 4;
        uint256 value = 1000 wei;

        vm.startPrank(user1);
        // ids [1, 2]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, ANY_ID, uint8(i % 2));
        }
        // ids [3, 4]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, 201, uint8(i % 2));
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 201);
        mockAuctionHouse.setNounId(202);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        uint16[] memory noPrefRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );
        assertEq(noPrefRequestsIds.length, totalRequests / 2);
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(
            noPrefRequests.length,
            totalRequests / 2,
            "noPrefRequests.length2"
        );

        assertEq(noPrefRequests[0].id, totalRequests / 2 - 1);
        assertEq(noPrefRequests[1].id, (totalRequests / 2) - 0);

        uint16[] memory specificRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            201
        );

        assertEq(specificRequestsIds.length, 0, "specificRequestsIds.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests / 2 ? uint16(BACKGROUND) : uint16(HEAD),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, i > totalRequests / 2 ? 0 : i, "request.id");
        }

        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        noPrefRequestsIds = nounSeek.requestIdsForTrait(HEAD, 9, ANY_ID);
        assertEq(noPrefRequestsIds.length, 0);
        noPrefRequests = nounSeek.requestsForTrait(HEAD, 9, ANY_ID, MAX);

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_MaxAllSpecificThenAnyHappyCase() public {
        // current auction = 201
        // target noun = 200

        uint256 totalRequests = 4;
        uint256 value = 1000 wei;

        vm.startPrank(user1);
        // ids [1, 2]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, 201, uint8(i % 2));
        }
        // ids [3, 4]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, ANY_ID, uint8(i % 2));
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 201);
        mockAuctionHouse.setNounId(202);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        vm.expectCall(address(user2), reimbursement_per_donation * 2, "");
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation),
            ""
        );
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        uint16[] memory noPrefRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );
        assertEq(
            noPrefRequestsIds.length,
            totalRequests / 2,
            "assert noPrefRequestsIds.length"
        );
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        assertEq(
            noPrefRequests.length,
            totalRequests / 2,
            "assert noPrefRequests.length"
        );

        assertEq(
            noPrefRequests[0].id,
            totalRequests / 2 + 1,
            "noPrefRequests[0].id"
        );
        assertEq(
            noPrefRequests[1].id,
            (totalRequests / 2) + 2,
            "noPrefRequests[1].id"
        );

        uint16[] memory specificRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            201
        );

        assertEq(specificRequestsIds.length, 0, "specificRequestsIds.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests / 2 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, i > totalRequests / 2 ? i : 0, "request.id");
        }

        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests / 2);

        noPrefRequestsIds = nounSeek.requestIdsForTrait(HEAD, 9, ANY_ID);
        assertEq(noPrefRequestsIds.length, 0);
        noPrefRequests = nounSeek.requestsForTrait(HEAD, 9, ANY_ID, MAX);

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, 0, "request.id");
        }
    }

    function test_MATCHANDDONATE_MaxMixedSpecificAndAnyHappyCase() public {
        // current auction = 201
        // target noun = 200

        uint256 totalRequests = 4;
        uint256 value = 1000 wei;

        vm.startPrank(user1);
        // ids [1, 2]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, 201, uint8(i % 2));
        }
        // ids [3, 4]
        for (uint256 i; i < totalRequests / 2; i++) {
            nounSeek.add{value: value}(HEAD, 9, ANY_ID, uint8(i % 2));
        }
        vm.stopPrank();

        INounsSeederLike.Seed memory seed = INounsSeederLike.Seed(
            0,
            0,
            0,
            9,
            0
        );
        mockNouns.setSeed(seed, 201);
        mockAuctionHouse.setNounId(202);

        uint256 reimbursement_per_donation = (value * reimbursementBPS) / 10000;

        // expecting 3 donation requests
        vm.expectCall(address(user2), reimbursement_per_donation * 3, "");
        // 2 donations to donee1
        vm.expectCall(
            address(donee1),
            (value - reimbursement_per_donation) * 2,
            ""
        );
        // 1 donation to donee2
        vm.expectCall(
            address(donee2),
            (value - reimbursement_per_donation),
            ""
        );
        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, totalRequests - 1);

        uint16[] memory noPrefRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            ANY_ID
        );
        // includes empty ids
        assertEq(noPrefRequestsIds.length, totalRequests / 2);
        NounSeek.Request[] memory noPrefRequests = nounSeek.requestsForTrait(
            HEAD,
            9,
            ANY_ID,
            MAX
        );

        // does not include empty ids
        assertEq(noPrefRequests.length, 1, "noPrefRequests.length2");

        assertEq(noPrefRequests[0].id, 4);

        uint16[] memory specificRequestsIds = nounSeek.requestIdsForTrait(
            HEAD,
            9,
            201
        );

        assertEq(specificRequestsIds.length, 0, "specificRequestsIds.length");

        // Check requests are deleted from mapping
        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                i > totalRequests - 1 ? uint16(HEAD) : uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, i > totalRequests - 1 ? i : 0, "request.id");
        }

        vm.prank(user2);
        nounSeek.matchAndDonate(201, HEAD, 99999);

        noPrefRequestsIds = nounSeek.requestIdsForTrait(HEAD, 9, ANY_ID);
        assertEq(noPrefRequestsIds.length, 0);
        noPrefRequests = nounSeek.requestsForTrait(HEAD, 9, ANY_ID, MAX);

        assertEq(noPrefRequests.length, 0, "noPrefRequests.length");

        for (uint16 i = 1; i <= totalRequests; i++) {
            NounSeek.Request memory request = nounSeek.requests(i);
            assertEq(
                uint16(nounSeek.requests(i).trait),
                uint16(BACKGROUND),
                "nounSeek.requests(i).trait"
            );
            assertEq(request.id, 0, "request.id");
        }
    }
}
