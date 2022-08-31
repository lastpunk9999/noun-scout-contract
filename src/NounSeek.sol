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
        if (seeksLength > max) seeksLength = max;
        Request[] memory traitRequests = new Request[](seeksLength);

        for (uint256 i = 0; i < seeksLength; i++) {
            traitRequests[i] = (_requests[_seeks[hash][i]]);
        }
        return traitRequests;
    }

    /**
    -----------------------------------
    --------- WRITE FUNCTIONS ---------
    -----------------------------------
     */

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
            revert("a1");
        }
        if (!_donees[doneeId].active) {
            revert("a2");
        }

        uint16 minNounId = uint16(auctionHouse.auction().nounId) + 1;
        if (nounId < minNounId) {
            revert("a3");
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

    function matchCurrentNounAndDonate(Traits trait, uint256 max) public {
        uint16 nounId = uint16(auctionHouse.auction().nounId);
        uint16 prevNounId = nounId - 1;

        uint16 traitId;

        uint256 reimbursement;
        uint256 doneesLength = _donees.length;
        uint256[] memory donations = new uint256[](doneesLength);

        console2.log("nounId", nounId);
        console2.log("prevNounId", prevNounId);
        console2.log("max1", max);
        (donations, reimbursement, max) = _calcFundsAndDelete(
            trait,
            nounId,
            nounId,
            max,
            donations,
            reimbursement
        );

        console2.log(
            "_isNonAuctionedNoun(prevNounId)",
            _isNonAuctionedNoun(prevNounId)
        );
        if (max > 0 && _isNonAuctionedNoun(prevNounId)) {
            (donations, reimbursement, max) = _calcFundsAndDelete(
                trait,
                prevNounId,
                prevNounId,
                max,
                donations,
                reimbursement
            );
        }
        console2.log("max2", max);
        console2.log("_isAuctionedNoun(nounId)", _isAuctionedNoun(nounId));
        // Only auctioned Nouns can match "NO_PREFERENCE"
        if (max > 0 && _isAuctionedNoun(nounId)) {
            (donations, reimbursement, max) = _calcFundsAndDelete(
                trait,
                nounId,
                NO_PREFERENCE,
                max,
                donations,
                reimbursement
            );
        }
        console2.log("max3", max);
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

    /**
    -----------------------------------
    ------- INTERNAL FUNCTIONS --------
    -----------------------------------
     */
    function _isNonAuctionedNoun(uint256 nounId) internal returns (bool) {
        return nounId % 10 == 0 && nounId <= 1820;
    }

    function _isAuctionedNoun(uint16 nounId) internal returns (bool) {
        return nounId % 10 != 0 || nounId > 1820;
    }

    function _calcFundsAndDelete(
        Traits trait,
        uint16 currentNounId,
        uint16 seekNounId,
        uint256 max,
        uint256[] memory donations,
        uint256 reimbursement
    )
        internal
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        if (max == 0) {
            return (donations, reimbursement, max);
        }
        console2.log("");
        uint16 traitId;
        if (trait == Traits.BACKGROUND) {
            traitId = uint16(nouns.seeds(currentNounId).background);
        } else if (trait == Traits.BODY) {
            traitId = uint16(nouns.seeds(currentNounId).body);
        } else if (trait == Traits.ACCESSORY) {
            traitId = uint16(nouns.seeds(currentNounId).accessory);
        } else if (trait == Traits.HEAD) {
            traitId = uint16(nouns.seeds(currentNounId).head);
        } else if (trait == Traits.GLASSES) {
            traitId = uint16(nouns.seeds(currentNounId).glasses);
        } else {
            revert();
        }
        Request[] memory nounIdRequests = requestsForTrait(
            trait,
            traitId,
            seekNounId,
            max
        );
        uint256 nounIdRequestsLength = nounIdRequests.length;

        console2.log("Trait", uint16(trait));
        console2.log("traitId", traitId);
        console2.log("seekNounId", seekNounId);
        console2.log("currentNounId", currentNounId);
        console2.log("nounIdRequestsLength", nounIdRequestsLength);

        if (nounIdRequestsLength == 0) {
            return (donations, reimbursement, max);
        }

        if (nounIdRequestsLength > max) {
            nounIdRequestsLength = max;
        }

        for (uint256 i; i < nounIdRequestsLength; i++) {
            Request memory request;
            request = nounIdRequests[i];

            uint256 donation = (request.amount * (10000 - REIMBURSMENT_BPS)) /
                10000;
            reimbursement += request.amount - donation;
            donations[request.doneeId] += donation;
            delete _requests[request.id];
        }

        if (nounIdRequestsLength > 0) {
            bytes32 hash = seekHash(trait, traitId, seekNounId);
            delete _seeks[hash];
        }

        return (donations, reimbursement, max - nounIdRequestsLength);
    }
}
