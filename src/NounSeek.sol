// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./NounsInterfaces.sol";
import "forge-std/console2.sol";

contract NounSeek {
    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice Time limit after an auction starts
    uint256 public constant AUCTION_START_LIMIT = 1 hours;

    /// @notice Time limit before an auction ends
    uint256 public constant AUCTION_END_LIMIT = 5 minutes;

    uint256 public constant REIMBURSMENT_BPS = 250;

    uint16 public constant NO_PREFERENCE = type(uint16).max;

    /// @notice Stores deposited value with the addresses that sent it
    struct Request {
        uint16 id;
        uint16 seekIndex;
        Traits trait;
        uint16 traitId;
        uint8 doneeId;
        uint16 nounId;
        uint16 minNounId;
        address requester;
        uint256 amount;
    }

    struct Donee {
        string name;
        address to;
        bool active;
    }

    enum Traits {
        BACKGROUND,
        BODY,
        ACCESSORY,
        HEAD,
        GLASSES
    }

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    Donee[] public _donees;

    mapping(bytes32 => uint16[]) internal _seeks;

    mapping(uint16 => Request) internal _requests;

    error TooSoon();
    error TooLate();
    error NoAmountSent();
    error NoPreferences();
    error OnlySeeker();
    error OnlyFinder();
    error AlreadyFound();
    error NoMatch(uint96 seekId);
    error BlockHashMismatch();

    /**
    -----------------------------
    --------- MODIFIERS ---------
    -----------------------------
     */

    /// @notice Modified function must be called {AUCTION_START_LIMIT} after auction start time and {AUCTION_END_LIMIT} before auction end time
    modifier withinRequestWindow() {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        // Cannot executed within a time from an auction's start
        if (block.timestamp - auction.startTime <= AUCTION_START_LIMIT) {
            revert TooSoon();
        }

        // Cannot executed within a time period from an auction's end
        if (auction.endTime - block.timestamp <= AUCTION_END_LIMIT) {
            revert TooLate();
        }
        _;
    }

    /// @notice Modified function must be called within {AUCTION_START_LIMIT} of the auction start time
    modifier withinMatchCurrentWindow() {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        if (block.timestamp - auction.startTime > AUCTION_START_LIMIT) {
            revert TooLate();
        }
        _;
    }

    constructor(INounsTokenLike _nouns, INounsAuctionHouseLike _auctionHouse) {
        nouns = _nouns;
        auctionHouse = _auctionHouse;
        updateTraitCounts();
    }

    /**
    ----------------------------------
    --------- VIEW FUNCTIONS ---------
    ----------------------------------
     */

    function seekHash(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    function requests(uint16 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function donees(uint8 id) public view returns (Donee memory) {
        return _donees[id];
    }

    function requestIdsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16[] memory) {
        return _seeks[seekHash(trait, traitId, nounId)];
    }

    function requestsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256 max
    ) public view returns (Request[] memory) {
        bytes32 hash = seekHash(trait, traitId, nounId);
        uint256 seeksLength = _seeks[hash].length;

        if (max > seeksLength) max = seeksLength;

        Request[] memory traitRequests = new Request[](max);

        for (uint256 i = 0; i < max; i++) {
            traitRequests[i] = (_requests[_seeks[hash][i]]);
        }
        return traitRequests;
    }

    // /**
    // -----------------------------------
    // --------- WRITE FUNCTIONS ---------
    // -----------------------------------
    //  */

    function updateTraitCounts() public {
        INounsDescriptorLike descriptor = INounsDescriptorLike(
            nouns.descriptor()
        );

        backgroundCount = uint16(descriptor.backgroundCount());
        bodyCount = uint16(descriptor.bodyCount());
        accessoryCount = uint16(descriptor.accessoryCount());
        headCount = uint16(descriptor.headCount());
        glassesCount = uint16(descriptor.glassesCount());
    }

    function addDonee(string calldata name, address to) public {
        _donees.push(Donee({name: name, to: to, active: true}));
    }

    function toggleDoneeActive(uint256 id) public {
        Donee memory donee = _donees[id];
        if (donee.to == address(0)) revert();
        donee.active = !donee.active;
        _donees[id] = donee;
    }

    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint8 doneeId
    ) public payable returns (uint16) {
        if (trait == Traits.HEAD && traitId >= headCount) {
            revert("1");
        }
        if (!_donees[doneeId].active) {
            revert();
        }

        uint16 minNounId = uint16(auctionHouse.auction().nounId) + 1;
        if (nounId < minNounId) {
            revert();
        }

        bytes32 hash = seekHash(trait, traitId, nounId);

        // length of all requests for specific head
        uint16 seekIndex = uint16(_seeks[hash].length);

        uint16 requestId = ++requestCount;

        _requests[requestId] = Request({
            id: requestId,
            seekIndex: seekIndex,
            doneeId: doneeId,
            trait: trait,
            traitId: traitId,
            nounId: nounId,
            minNounId: minNounId,
            requester: msg.sender,
            amount: msg.value
        });

        _seeks[hash].push(requestId);

        return requestId;
    }

    function remove(uint16 requestId) public {
        address requester = _requests[requestId].requester;
        if (requester != msg.sender) {
            revert();
        }
        uint16 seekIndex = _requests[requestId].seekIndex;
        Traits trait = _requests[requestId].trait;
        uint16 traitId = _requests[requestId].traitId;
        uint16 nounId = _requests[requestId].nounId;

        bytes32 hash = seekHash(trait, traitId, nounId);
        uint256 lastIndex = _seeks[hash].length - 1;

        if (seekIndex < lastIndex) {
            uint16 lastId = _seeks[hash][lastIndex];
            _requests[lastId].seekIndex = seekIndex;
            _seeks[hash][seekIndex] = lastId;
        }

        _seeks[hash].pop();
        delete _requests[requestId];
    }

    /*     function matchAndSendAll(uint16 nounId) public {
        return matchAndSendWithMax(nounId, 10**18);
    }

    function matchAndSendWithMax(uint16 nounId, uint256 max) public {
        // Must specify a Noun Id
        if (nounId >= NO_PREFERENCE) revert("1");

        // Cannot match a future Noun
        if (nounId > uint16(auctionHouse.auction().nounId)) revert("2");

        uint16 headId = uint16(nouns.seeds(nounId).head);

        Request[] memory matchedRequests = headRequestsForNounWithMax(
            headId,
            nounId,
            max
        );
        uint256 matchedRequestsLength = matchedRequests.length;

        if (matchedRequestsLength == 0) revert("3");
        uint256 doneesLength = _donees.length;
        uint256[] memory donations = new uint256[](doneesLength);
        uint256 reimbursement;

        for (uint256 i; i < matchedRequestsLength; i++) {
            Request memory request = matchedRequests[i];
            uint256 donation = (request.amount * (10000 - REIMBURSMENT_BPS)) /
                10000;
            reimbursement += request.amount - donation;
            donations[request.doneeId] += donation;
            delete _requests[matchedRequests[i].id];
        }

        uint256 headRequestsLength = _seeks[headId].length;

        if (headRequestsLength - matchedRequestsLength == 0) {
            _seeks[headId] = new uint16[](0);
        } else {
            uint16 unmatchedRequestsLength = uint16(
                headRequestsLength - matchedRequestsLength
            );

            uint16[] memory unmatchedRequests = new uint16[](
                unmatchedRequestsLength
            );

            uint16 insertedCount;

            for (uint256 i = 0; i < headRequestsLength; i++) {
                if (insertedCount == unmatchedRequestsLength) continue;

                bool prevMatch = false;

                for (
                    uint256 j = 0;
                    j < matchedRequestsLength && !prevMatch;
                    j++
                ) {
                    if (matchedRequests[j].seekIndex != i) continue;

                    prevMatch = true;

                    matchedRequests[j] = matchedRequests[
                        matchedRequestsLength - 1
                    ];

                    matchedRequestsLength -= 1;
                }

                if (!prevMatch) {
                    uint16 id = _seeks[headId][i];
                    unmatchedRequests[insertedCount] = id;
                    _requests[id].seekIndex = insertedCount;
                    insertedCount++;
                }
            }
            _seeks[headId] = unmatchedRequests;
        }

        for (uint256 i; i < doneesLength; i++) {
            if (donations[i] == 0) continue;
            (bool success, ) = _donees[i].to.call{
                value: donations[i],
                gas: 10_000
            }("");
        }
        (bool success, ) = msg.sender.call{value: reimbursement, gas: 10_000}(
            ""
        );
    } */
}
