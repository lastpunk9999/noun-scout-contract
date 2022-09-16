// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./Interfaces.sol";
import "forge-std/console2.sol";

contract NounSeek is Ownable2Step, Pausable {
    error TooLate();
    error MatchFound(Traits trait, uint16 traitId, uint16 nounId);
    error NoMatch();
    error InactiveDonee();
    error NotRequester();
    error ValueTooLow();

    /// @notice Stores deposited value, requested traits, donation target with the addresses that sent it
    struct Request {
        uint16 nonce;
        Traits trait;
        uint16 traitId;
        uint16 doneeId;
        uint16 nounId;
        address requester;
        uint256 amount;
    }

    /// @notice Name, address, and active status where funds can be donated
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

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Retreives historical mapping of Noun ID -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice The address of the WETH contract
    IWETH public immutable weth;

    /// @notice Time limit before an auction ends
    uint16 public constant AUCTION_END_LIMIT = 5 minutes;

    /// @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID
    uint16 public constant ANY_ID = 0;

    /// @notice cheaper to store than calculate
    uint16 private constant UINT16_MAX = type(uint16).max;

    /// @notice 1% of donated funds are sent to the address performing a match
    uint16 public reimbursementBPS = 100;

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    uint256 public minValue = 0.02 ether;

    Donee[] public donees;

    /// Cumulative amount for hash(trait traitId nounId) doneeId
    mapping(bytes32 => mapping(uint16 => uint256)) public amounts;

    /// Incremented nonce for hash(trait, traitId, nounId)
    mapping(bytes32 => uint16) public nonces;

    mapping(uint256 => Request) public requests;

    constructor(
        INounsTokenLike _nouns,
        INounsAuctionHouseLike _auctionHouse,
        IWETH _weth
    ) {
        nouns = _nouns;
        auctionHouse = _auctionHouse;
        weth = _weth;
        updateTraitCounts();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function amountForDoneeByTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public view returns (uint256) {
        bytes32 hash = traitHash(trait, traitId, nounId);
        return amounts[hash][doneeId];
    }

    function allDonationsForTrait(Traits trait, uint16 nounId)
        public
        view
        returns (uint256[][] memory donationsByTraitId)
    {
        uint16 traitCount;
        if (trait == Traits.BACKGROUND) {
            traitCount = backgroundCount;
        } else if (trait == Traits.BODY) {
            traitCount = bodyCount;
        } else if (trait == Traits.ACCESSORY) {
            traitCount = accessoryCount;
        } else if (trait == Traits.HEAD) {
            traitCount = headCount;
        } else if (trait == Traits.GLASSES) {
            traitCount = glassesCount;
        }

        uint256 doneesLength = donees.length;
        donationsByTraitId = new uint256[][](traitCount);

        bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);

        for (uint16 traitId; traitId < traitCount; traitId++) {
            bytes32 hash = traitHash(trait, traitId, nounId);
            bytes32 anyIdHash;
            if (processAnyId) anyIdHash = traitHash(trait, traitId, ANY_ID);
            donationsByTraitId[traitId] = new uint256[](doneesLength);
            for (uint16 doneeId; doneeId < doneesLength; doneeId++) {
                uint256 anyIdAmount = processAnyId
                    ? amounts[anyIdHash][doneeId]
                    : 0;
                donationsByTraitId[traitId][doneeId] =
                    amounts[hash][doneeId] +
                    anyIdAmount;
            }
        }
    }

    function allDonationsForNextNoun(Traits trait)
        public
        view
        returns (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        )
    {
        nextAuctionedId = uint16(auctionHouse.auction().nounId) + 1;
        nextNonAuctionedId = UINT16_MAX;

        if (_isNonAuctionedNoun(nextAuctionedId)) {
            nextNonAuctionedId = nextAuctionedId;
            nextAuctionedId++;
        }

        nextAuctionDonations = allDonationsForTrait(trait, nextAuctionedId);

        if (nextNonAuctionedId < UINT16_MAX) {
            nextNonAuctionDonations = allDonationsForTrait(
                trait,
                nextNonAuctionedId
            );
        }
    }

    /// @notice Evaluate if the provided Request parameters matches the specified Noun
    /// @param requestTrait The trait type to compare the given Noun ID with
    /// @param requestTraitId The ID of the provided trait type to compare the given Noun ID with
    /// @param requestNounId The NounID parameter from a Noun Seek Request (may be ANY_ID)
    /// @param nounId Noun ID to fetch the attributes of to compare against the given request properties
    /// @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
    function requestParamsMatchNounParams(
        Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 nounId
    ) public view returns (bool) {
        return
            requestMatchesNoun(
                Request({
                    nonce: 0,
                    doneeId: 0,
                    trait: requestTrait,
                    traitId: requestTraitId,
                    nounId: requestNounId,
                    requester: address(0),
                    amount: 0
                }),
                nounId
            );
    }

    /// @notice Evaluate if the provided Request matches the specified Noun
    /// @param request The Request to compare
    /// @param nounId Noun ID to fetch the attributes of to compare against the given request properties
    /// @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
    function requestMatchesNoun(Request memory request, uint16 nounId)
        public
        view
        returns (bool)
    {
        // If a specific Noun Id is part of the request, but is not the target Noun id, can exit
        if (request.nounId != ANY_ID && request.nounId != nounId) {
            return false;
        }

        // No Preference Noun Id can only apply to auctioned Nouns
        if (request.nounId == ANY_ID && _isNonAuctionedNoun(nounId)) {
            return false;
        }

        return request.traitId == _fetchTraitId(request.trait, nounId);
    }

    /// @notice The canonical hash for requests that target the same `trait`, `traitId`, and `nounId`
    /// @dev Used to group requests by their parameters in the `_requestsIdsForTraits` mapping
    function traitHash(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      WRITE FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /// @notice Create a request for the specific trait and specific or open Noun ID payable to the specified Donee. Request amount is tied to the sent value.
    /// @param trait Trait type the request is for (see Traits enum)
    /// @param traitId ID of the specified Trait that the request is for
    /// @param nounId the Noun ID the request is targeted for (or the value of ANY_ID for open requests)
    /// @param doneeId the ID of the Donee that should receive the donation if a Noun matching the parameters is minted
    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public payable whenNotPaused returns (uint256) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        if (!donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = traitHash(trait, traitId, nounId);
        uint16 nonce = nonces[hash];

        amounts[hash][doneeId] += msg.value;

        uint256 requestId = requestCount++;

        requests[requestId] = Request({
            nonce: nonce,
            doneeId: doneeId,
            trait: trait,
            traitId: traitId,
            nounId: nounId,
            requester: msg.sender,
            amount: msg.value
        });

        return requestId;
    }

    /// @notice Remove the specified request and return the associated ETH. Must be called by the requester and before AuctionEndWindow
    function remove(uint256 requestId) public {
        // Cannot executed within a time period from an auction's end
        if (
            block.timestamp + AUCTION_END_LIMIT >=
            auctionHouse.auction().endTime
        ) {
            revert TooLate();
        }

        Request memory request = requests[requestId];

        if (request.requester != msg.sender) {
            revert NotRequester();
        }

        /* @dev
         * Cannot remove a request if:
         * 1) The current Noun on auction has the requested traits
         * 2) The previous Noun has the requested traits
         * 2b) If the previous Noun is non-auctioned, the previous previous has the requested traits
         * 3) A Non-Auctioned Noun which matches the request.nounId is the previous previous Noun

         * Case # | Example | Ineligible
         *        | Noun Id | Noun Id
         * -------|---------|-------------------
         *    1,3 |     101 | 101, 99 (*skips 100)
         *  1,2,2b|     102 | 102, 101, 100 (*includes 100)
         *    1,2 |     103 | 103, 102
        */
        uint16 nounId = uint16(auctionHouse.auction().nounId);

        // Case 1
        _revertIfRequestMatchesNoun(request, nounId);

        // Case 2
        if (_isAuctionedNoun(nounId - 1)) {
            _revertIfRequestMatchesNoun(request, nounId - 1);
            // Case 2b
            if (_isNonAuctionedNoun(nounId - 2)) {
                _revertIfRequestMatchesNoun(request, nounId - 2);
            }
        } else {
            // Case 3
            _revertIfRequestMatchesNoun(request, nounId - 2);
        }

        bytes32 hash = traitHash(
            request.trait,
            request.traitId,
            request.nounId
        );

        delete requests[requestId];

        /// Funds can be returned if request has yet to be matched
        if (nonces[hash] == request.nonce) {
            amounts[hash][request.doneeId] -= request.amount;
            _safeTransferETHWithFallback(request.requester, request.amount);
        }
    }

    /// @notice Match up to the specified number of requests for the specified Noun ID and specific trait. Will send donation funds.
    /// @param trait The Trait type to enumerate requests for (see Traits enum)
    function matchAndDonate(Traits trait) public {
        uint16 auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        uint16 nonAuctionedNounId = UINT16_MAX;

        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }

        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint256 reimbursement;
        uint256 doneesLength = donees.length;
        uint256[] memory donations = new uint256[](doneesLength);

        uint16 auctionedTraitId = _fetchTraitId(trait, auctionedNounId);

        // Match specify Noun Id requests
        (donations, reimbursement) = _getAmountsAndDeleteRequests(
            trait,
            auctionedTraitId,
            auctionedNounId,
            donations,
            reimbursement
        );

        uint16 nonAuctionedTraitId;
        if (nonAuctionedNounId < UINT16_MAX) {
            nonAuctionedTraitId = _fetchTraitId(trait, nonAuctionedNounId);
            (donations, reimbursement) = _getAmountsAndDeleteRequests(
                trait,
                nonAuctionedTraitId,
                nonAuctionedNounId,
                donations,
                reimbursement
            );
        }

        if (reimbursement < 1) revert NoMatch();

        for (uint256 i; i < doneesLength; i++) {
            if (donations[i] < 1) continue;
            _safeTransferETHWithFallback(donees[i].to, donations[i]);
        }
        _safeTransferETHWithFallback(msg.sender, reimbursement);
    }

    /// @notice Fetch the count of NounsDescriptor traits and update local counts
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

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      OWNER FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Add a Donee by specifying the name and address funds should be sent to
    /// @dev Adds a Donee to the donees set and activates the Donee
    /// @param name The Donee's name that should be displayed to users/consumers
    /// @param to Address that funds should be sent to in order to fund the Donee
    function addDonee(
        string calldata name,
        address to,
        string calldata description
    ) external onlyOwner {
        donees.push(Donee({name: name, to: to, active: true}));
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param id Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 id) external onlyOwner {
        donees[id].active = !donees[id].active;
    }

    function setMinValue(uint256 value) external onlyOwner {
        minValue = value;
    }

    function setReimbursementBPS(uint16 newBPS) external onlyOwner {
        /// BPS cannot be less than 0.1% or greater than 10%
        if (newBPS < 10 || newBPS > 1000) revert();
        reimbursementBPS = newBPS;
    }

    /// @notice Pauses the NounSeek contract. Pausing can be reversed by unpausing.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses (resumes) the NounSeek contract. Unpausing can be reversed by pausing.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /// @notice Was the specified Noun ID not auctioned
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 < 1 && nounId <= 1820;
    }

    /// @notice Was the specified Noun ID auctioned
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 > 0 || nounId > 1820;
    }

    /**
    @notice Retrieves requests with params `trait`, `traitId`, and `nounId` to calculate donation and reimubesement amounts, then removes the requests from storage.
    @param trait The trait type requests should match (see Traits enum)
    @param traitId Specific trait Id
    @param nounId Specific Noun Id
    @param donations Donations array to be mutated and returned
    @param reimbursement Reimbursement amount to be mutated and return
    @return donations Mutated donations array
    @return reimbursement Mutated reimursement amount
     */
    function _getAmountsAndDeleteRequests(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256[] memory donations,
        uint256 reimbursement
    ) internal returns (uint256[] memory, uint256) {
        bytes32 hash = traitHash(trait, traitId, nounId);
        bool processAnyId = _isAuctionedNoun(nounId);

        bytes32 anyIdHash;
        if (processAnyId) anyIdHash = traitHash(trait, traitId, ANY_ID);

        nonces[hash]++;
        if (processAnyId) nonces[anyIdHash]++;

        uint16 doneesLength = uint16(donees.length);

        for (uint16 doneeId; doneeId < doneesLength; doneeId++) {
            uint256 anyIdAmount = processAnyId
                ? amounts[anyIdHash][doneeId]
                : 0;
            uint256 amount = amounts[hash][doneeId] + anyIdAmount;
            uint256 donation = (amount * (10000 - reimbursementBPS)) / 10000;
            reimbursement += amount - donation;
            donations[doneeId] += donation;

            delete amounts[hash][doneeId];
            if (processAnyId) delete amounts[anyIdHash][doneeId];
        }

        return (donations, reimbursement);
    }

    function _revertIfRequestMatchesNoun(Request memory request, uint16 nounId)
        internal
        view
    {
        if (requestMatchesNoun(request, nounId))
            revert MatchFound(request.trait, request.traitId, nounId);
    }

    function _fetchTraitId(Traits trait, uint16 nounId)
        internal
        view
        returns (uint16 traitId)
    {
        if (trait == Traits.BACKGROUND) {
            traitId = uint16(nouns.seeds(nounId).background);
        } else if (trait == Traits.BODY) {
            traitId = uint16(nouns.seeds(nounId).body);
        } else if (trait == Traits.ACCESSORY) {
            traitId = uint16(nouns.seeds(nounId).accessory);
        } else if (trait == Traits.HEAD) {
            traitId = uint16(nouns.seeds(nounId).head);
        } else if (trait == Traits.GLASSES) {
            traitId = uint16(nouns.seeds(nounId).glasses);
        }
    }

    /// @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            weth.deposit{value: amount}();
            weth.transfer(to, amount);
        }
    }

    /// @notice Transfer ETH and return the success status.
    /// @dev This function only forwards 10,000 gas to the callee.
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 10_000}("");
        return success;
    }
}
