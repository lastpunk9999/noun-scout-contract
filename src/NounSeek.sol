// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./NounsInterfaces.sol";
import "forge-std/console2.sol";

contract NounSeek {
    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice Retreives historical mapping of nounId -> seed
    INounsDescriptorLike public descriptor;

    /// @notice Time limit after an auction starts
    uint256 public constant AUCTION_START_LIMIT = 1 hours;

    /// @notice Time limit before an auction ends
    uint256 public constant AUCTION_END_LIMIT = 5 minutes;

    uint256 public constant REIMBURSMENT_BPS = 250;

    uint16 public constant NO_PREFERENCE = type(uint16).max;

    /// @notice Stores deposited value with the addresses that sent it
    struct Request {
        uint16 id;
        uint16 headRequestIndex;
        uint16 headId;
        uint16 doneeId;
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

    uint16 public requestCount;

    uint16 public headCount;

    Donee[] public _donees;

    mapping(uint16 => uint16[]) internal _headRequests;

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
        updateDescriptor();
        updateHeadCount();
    }

    /**
    ----------------------------------
    --------- VIEW FUNCTIONS ---------
    ----------------------------------
     */

    function requests(uint16 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function donees(uint256 id) public view returns (Donee memory) {
        return _donees[id];
    }

    function headRequestIds(uint16 headId)
        public
        view
        returns (uint16[] memory)
    {
        return _headRequests[headId];
    }

    function headRequests(uint16 headId)
        public
        view
        returns (Request[] memory)
    {
        return headRequestsForNounWithMax(headId, NO_PREFERENCE, NO_PREFERENCE);
    }

    function headRequestsForNoun(uint16 headId, uint16 nounId)
        public
        view
        returns (Request[] memory)
    {
        return headRequestsForNounWithMax(headId, nounId, NO_PREFERENCE);
    }

    function headRequestsForNounWithMax(
        uint16 headId,
        uint16 nounId,
        uint256 max
    ) public view returns (Request[] memory) {
        uint256 headRequestLength = _headRequests[headId].length;

        uint16[] memory requestIds = new uint16[](headRequestLength);
        uint16[] memory filteredRequestIds = new uint16[](headRequestLength);
        uint16 filteredRequestCount;

        requestIds = _headRequests[headId];

        for (uint16 i = 0; i < headRequestLength; i++) {
            if (filteredRequestCount >= max) {
                continue;
            }

            uint16 requestId = requestIds[i];
            Request memory request = _requests[requestId];

            // Specific nounId does not match
            if (
                request.nounId != NO_PREFERENCE &&
                nounId != NO_PREFERENCE &&
                nounId != request.nounId
            ) {
                continue;
            }

            // No preference, but Noun is non-auctioned
            if (
                request.nounId == NO_PREFERENCE &&
                nounId % 10 == 0 &&
                nounId <= 1820
            ) {
                continue;
            }

            // Cannot match with previously auctioned Noun
            if (nounId < request.minNounId) {
                continue;
            }
            filteredRequestIds[i] = requestId;
            filteredRequestCount++;
        }

        Request[] memory matchedRequests = new Request[](filteredRequestCount);
        filteredRequestCount = 0;
        for (
            uint256 i = 0;
            i < headRequestLength && filteredRequestCount <= max;
            i++
        ) {
            if (filteredRequestIds[i] == 0) continue;
            matchedRequests[filteredRequestCount] = _requests[requestIds[i]];
            filteredRequestCount++;
        }
        return matchedRequests;
    }

    // /**
    // -----------------------------------
    // --------- WRITE FUNCTIONS ---------
    // -----------------------------------
    //  */

    function updateHeadCount() public {
        headCount = uint16(descriptor.headCount());
    }

    function updateDescriptor() public {
        descriptor = INounsDescriptorLike(nouns.descriptor());
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

    function add(uint16 headId, uint16 doneeId)
        public
        payable
        returns (uint16)
    {
        return addWithNounId(headId, doneeId, NO_PREFERENCE);
    }

    function addWithNounId(
        uint16 headId,
        uint16 doneeId,
        uint16 nounId
    ) public payable returns (uint16) {
        if (headId >= headCount) {
            revert();
        }
        if (!_donees[doneeId].active) {
            revert();
        }

        uint16 minNounId = uint16(auctionHouse.auction().nounId) + 1;
        if (nounId < minNounId) {
            revert();
        }

        // length of all requests for specific head
        uint16 headRequestIndex = uint16(_headRequests[headId].length);

        uint16 requestId = ++requestCount;

        _requests[requestId] = Request({
            id: requestId,
            headRequestIndex: headRequestIndex,
            doneeId: doneeId,
            headId: headId,
            nounId: nounId,
            minNounId: minNounId,
            requester: msg.sender,
            amount: msg.value
        });

        _headRequests[headId].push(requestId);

        return requestId;
    }

    function remove(uint16 requestId) public {
        Request memory request = _requests[requestId];
        if (request.requester != msg.sender) {
            revert();
        }
        delete _requests[requestId];
        _headRequests[request.headId][request.headRequestIndex] = _headRequests[
            request.headId
        ][_headRequests[request.headId].length - 1];
        _headRequests[request.headId].pop();
    }

    function matchAndSendAll(uint16 nounId) public {
        return matchAndSendWithMax(nounId, 10**18);
    }

    function matchAndSendWithMax(uint16 nounId, uint256 max) public {
        // Must specify a Noun Id
        if (nounId >= NO_PREFERENCE) revert();

        // Cannot match a future Noun
        if (nounId > uint16(auctionHouse.auction().nounId)) revert();

        uint16 headId = uint16(nouns.seeds(nounId).head);

        Request[] memory matchedRequests = headRequestsForNounWithMax(
            headId,
            nounId,
            max
        );
        uint256 matchedRequestsLength = matchedRequests.length;

        if (matchedRequestsLength == 0) revert();
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

        uint256 headRequestsLength = _headRequests[headId].length;

        if (headRequestsLength - matchedRequestsLength == 0) {
            _headRequests[headId] = new uint16[](0);
        } else {
            uint256 unmatchedRequestsLength = headRequestsLength -
                matchedRequestsLength;

            uint16[] memory unmatchedRequests = new uint16[](
                unmatchedRequestsLength
            );

            uint256 insertedCount;

            for (uint256 i = 0; i < headRequestsLength; i++) {
                if (insertedCount == unmatchedRequestsLength) continue;

                bool prevMatch = false;

                for (
                    uint256 j = 0;
                    j < matchedRequestsLength && !prevMatch;
                    j++
                ) {
                    if (matchedRequests[j].headRequestIndex != i) continue;

                    prevMatch = true;

                    matchedRequests[j] = matchedRequests[
                        matchedRequestsLength - 1
                    ];

                    matchedRequestsLength -= 1;
                }

                if (!prevMatch) {
                    unmatchedRequests[insertedCount] = _headRequests[headId][i];
                    insertedCount++;
                }
            }
            _headRequests[headId] = unmatchedRequests;
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
    }
}
