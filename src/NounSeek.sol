// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./Interfaces.sol";
import "forge-std/console2.sol";

contract NounSeek is Ownable2Step, Pausable {
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERROR
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    error TooLate();
    error MatchFound(uint16 nounId);
    error NoMatch();
    error InactiveDonee();
    error ValueTooLow();

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    event RequestAdded(
        uint256 requestId,
        address indexed requester,
        Traits indexed trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 nounId,
        uint256 amount,
        uint16 nonce
    );
    event RequestRemoved(
        uint256 requestId,
        address indexed requester,
        Traits indexed trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 nounId,
        uint256 amounts
    );
    event DoneeAdded(
        uint256 doneeId,
        string name,
        address to,
        string description
    );
    event DoneeActiveStatusChanged(uint256 doneeId, bool active);
    event Matched(Traits trait, uint16 traitId, uint16 nounId, uint16 newNonce);
    // event Donated(uint256 doneeId, address to, uint256 amount);
    event Donated(uint256[] donations);
    event Reimbursed(address matcher, uint256 amount);
    event MinValueChanged(uint256 newMinValue);
    event ReimbursementBPSChanged(uint256 newReimbursementBPS);

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CUSTOM TYPES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Stores deposited value, requested traits, donation target with the addresses that sent it
    struct Request {
        uint16 nonce;
        Traits trait;
        uint16 traitId;
        uint16 doneeId;
        uint16 nounId;
        uint128 amount;
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
      CONSTANTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Retreives historical mapping of Noun ID -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice The address of the WETH contract
    IWETH public immutable weth;

    /// @notice minimum reimbursement for matching; targets up to 150_000 gas at 20 Gwei/gas
    uint256 public constant MIN_REIMBURSEMENT = 0.003 ether;

    /// @notice maximum reimbursement for matching; with default value this is reached at 4 ETH total donations
    uint256 public constant MAX_REIMBURSEMENT = 0.1 ether;

    /// @notice Time limit before an auction ends
    uint16 public constant AUCTION_END_LIMIT = 5 minutes;

    /// @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID
    uint16 public constant ANY_ID = 0;

    /// @notice cheaper to store than calculate
    uint16 private constant UINT16_MAX = type(uint16).max;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice A portion of donated funds are sent to the address performing a match
    uint16 public maxReimbursementBPS = 250;

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    uint256 public minValue = 0.01 ether;

    Donee[] public donees;

    /// Cumulative amount for hash(trait traitId nounId) doneeId
    mapping(bytes32 => mapping(uint16 => uint256)) public amounts;

    /// Incremented nonce for hash(trait, traitId, nounId)
    mapping(bytes32 => uint16) public nonces;

    mapping(address => Request[]) internal _requests;

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

    function requestsByAddress(address requester)
        public
        view
        returns (Request[] memory)
    {
        return _requests[requester];
    }

    function requestsById(address requester, uint256 requestId)
        public
        view
        returns (Request memory)
    {
        return _requests[requester][requestId];
    }

    function amountForDoneeByTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public view returns (uint256) {
        bytes32 hash = traitHash(trait, traitId, nounId);
        return amounts[hash][doneeId];
    }

    function donationsForNounByTrait(Traits trait, uint16 nounId)
        public
        view
        returns (uint256[][] memory donationsByTraitId)
    {
        unchecked {
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
    }

    function donationsForNextNounByTrait(Traits trait)
        public
        view
        returns (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        )
    {
        unchecked {
            nextAuctionedId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionedId = UINT16_MAX;

            if (_isNonAuctionedNoun(nextAuctionedId)) {
                nextNonAuctionedId = nextAuctionedId;
                nextAuctionedId++;
            }

            nextAuctionDonations = donationsForNounByTrait(
                trait,
                nextAuctionedId
            );

            if (nextNonAuctionedId < UINT16_MAX) {
                nextNonAuctionDonations = donationsForNounByTrait(
                    trait,
                    nextNonAuctionedId
                );
            }
        }
    }

    function donationsForCurrentNounByTrait(Traits trait)
        public
        view
        returns (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[][] memory currentAuctionDonations,
            uint256[][] memory prevNonAuctionDonations
        )
    {
        unchecked {
            currentAuctionedId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionedId = UINT16_MAX;

            if (_isNonAuctionedNoun(currentAuctionedId - 1)) {
                prevNonAuctionedId = currentAuctionedId - 1;
            }

            currentAuctionDonations = donationsForNounByTrait(
                trait,
                currentAuctionedId
            );

            if (prevNonAuctionedId < UINT16_MAX) {
                prevNonAuctionDonations = donationsForNounByTrait(
                    trait,
                    prevNonAuctionedId
                );
            }
        }
    }

    function effectiveBPSForDonationTotal(uint256 total)
        public
        view
        returns (uint256 effectiveBPS)
    {
        effectiveBPS = _effectiveHighPrecisionBPSForDonationTotal(total) / 100;
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

    function nonceForTraits(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16) {
        return nonces[traitHash(trait, traitId, nounId)];
    }

    function noncesForTraits(
        Traits[] calldata traits,
        uint16[] calldata traitIds,
        uint16[] calldata nounIds
    ) public view returns (uint16[] memory noncesList) {
        uint256 length = traits.length;
        noncesList = new uint16[](length);
        for (uint256 i; i < length; i++) {
            noncesList[i] = nonceForTraits(traits[i], traitIds[i], nounIds[i]);
        }
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
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        if (!donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = traitHash(trait, traitId, nounId);
        uint16 nonce = nonces[hash];

        amounts[hash][doneeId] += msg.value;

        requestId = _requests[msg.sender].length;

        _requests[msg.sender].push(
            Request({
                nonce: nonce,
                doneeId: doneeId,
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                amount: uint128(msg.value)
            })
        );

        emit RequestAdded(
            requestId,
            msg.sender,
            trait,
            traitId,
            doneeId,
            nounId,
            msg.value,
            nonce
        );
    }

    /// @notice Remove the specified request and return the associated ETH. Must be called by the requester and before AuctionEndWindow
    function remove(uint256 requestId) public returns (uint256 amount) {
        // Cannot executed within a time period from an auction's end
        if (
            block.timestamp + AUCTION_END_LIMIT >=
            auctionHouse.auction().endTime
        ) {
            revert TooLate();
        }

        Request memory request = _requests[msg.sender][requestId];

        if (request.amount < 1) revert ValueTooLow();

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

        delete _requests[msg.sender][requestId];

        bytes32 hash = traitHash(
            request.trait,
            request.traitId,
            request.nounId
        );

        /// Funds can be returned if request has yet to be matched
        amount = nonces[hash] == request.nonce ? request.amount : 0;

        emit RequestRemoved(
            requestId,
            msg.sender,
            request.trait,
            request.traitId,
            request.doneeId,
            request.nounId,
            amount
        );

        if (amount > 0) {
            amounts[hash][request.doneeId] -= amount;
            _safeTransferETHWithFallback(msg.sender, amount);
        }
    }

    /// @notice Match all trait requests for the previous Noun(s).
    /// @dev Matches will made against the previously auctioned Noun using requests that have an open ID (ANY_ID) or specific ID. If immediately preceeding Noun to the previously auctioned Noun is non-auctioned, only specific ID requests will match
    /// @param trait The Trait type to match with the previous Noun (see Traits enum)
    function matchAndDonate(Traits trait)
        public
        returns (uint256 total, uint256 reimbursement)
    {
        /// The Noun ID of the previous Noun to the current Noun on auction
        uint16 auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        /// Setup a parameter to detect if a non-auctioned Noun should  be matched
        uint16 nonAuctionedNounId = UINT16_MAX;

        /// If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
        /// Example:
        ///   Current Noun: 101
        ///   Previous Noun: 100
        ///   `auctionedNounId` should be 99
        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }
        // If the previous Noun to the previous auctioned Noun is non-auctioned, set the non-auctioned Noun ID to the preceeding Noun
        /// Example:
        ///   Current Noun: 102
        ///   Previous Noun: 101
        ///   `nonAuctionedNounId` should be 100
        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint16[] memory traitIds = new uint16[](
            nonAuctionedNounId < UINT16_MAX ? 3 : 2
        );
        uint16[] memory nounIds = new uint16[](
            nonAuctionedNounId < UINT16_MAX ? 3 : 2
        );

        nounIds[0] = auctionedNounId;
        nounIds[1] = ANY_ID;
        traitIds[0] = _fetchTraitId(trait, auctionedNounId);
        traitIds[1] = traitIds[0];

        if (nonAuctionedNounId < UINT16_MAX) {
            nounIds[2] = nonAuctionedNounId;
            traitIds[2] = _fetchTraitId(trait, nonAuctionedNounId);
        }

        uint256[] memory donations;
        (donations, total) = _combineAmountsAndDelete(trait, traitIds, nounIds);

        if (total < 1) revert NoMatch();

        uint256 effectiveBPS = _effectiveHighPrecisionBPSForDonationTotal(
            total
        );

        uint256 doneesLength = donees.length;
        for (uint256 i; i < doneesLength; i++) {
            uint256 amount = donations[i];
            if (amount < 1) continue;
            uint256 donation = (amount * (1_000_000 - effectiveBPS)) /
                1_000_000;
            reimbursement += amount - donation;
            donations[i] = donation;
            _safeTransferETHWithFallback(donees[i].to, donation);
        }
        emit Donated(donations);

        _safeTransferETHWithFallback(msg.sender, reimbursement);
        emit Reimbursed(msg.sender, reimbursement);
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
        uint16 doneeId = uint16(donees.length);
        donees.push(Donee({name: name, to: to, active: true}));
        emit DoneeAdded(doneeId, name, to, description);
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param doneeId Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 doneeId) external onlyOwner {
        bool active = !donees[doneeId].active;
        donees[doneeId].active = active;
        emit DoneeActiveStatusChanged(doneeId, active);
    }

    function setMinValue(uint256 newMinValue) external onlyOwner {
        minValue = newMinValue;
        emit MinValueChanged(newMinValue);
    }

    function setReimbursementBPS(uint16 newReimbursementBPS)
        external
        onlyOwner
    {
        /// BPS cannot be less than 0.1% or greater than 10%
        if (newReimbursementBPS < 10 || newReimbursementBPS > 1000) revert();
        maxReimbursementBPS = newReimbursementBPS;
        emit ReimbursementBPSChanged(newReimbursementBPS);
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
    @param traitIds Specific trait Id
    @param nounIds Specific Noun Id
    @return donations Mutated donations array
    @return total total
     */
    function _combineAmountsAndDelete(
        Traits trait,
        uint16[] memory traitIds,
        uint16[] memory nounIds
    ) internal returns (uint256[] memory donations, uint256 total) {
        uint16 doneesLength = uint16(donees.length);

        donations = new uint256[](doneesLength);

        uint256 nounIdsLength = nounIds.length;

        for (uint16 i; i < nounIdsLength; i++) {
            bytes32 hash = traitHash(trait, traitIds[i], nounIds[i]);
            uint256 traitTotal;
            for (uint16 doneeId; doneeId < doneesLength; doneeId++) {
                uint256 amount = amounts[hash][doneeId];
                if (amount < 1) continue;
                traitTotal += amount;
                total += amount;
                donations[doneeId] += amount;

                delete amounts[hash][doneeId];
            }

            if (traitTotal < 1) continue;

            nonces[hash]++;

            emit Matched(trait, traitIds[i], nounIds[i], nonces[hash]);
        }
    }

    function _revertIfRequestMatchesNoun(Request memory request, uint16 nounId)
        internal
        view
    {
        if (requestMatchesNoun(request, nounId)) revert MatchFound(nounId);
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

    function _effectiveHighPrecisionBPSForDonationTotal(uint256 total)
        internal
        view
        returns (uint256 effectiveBPS)
    {
        /// Add 2 digits extra precision to better derive `effectiveBPS` from total
        /// Extra precision basis point = 10_000 * 100 = 1_000_000
        effectiveBPS = maxReimbursementBPS * 100;
        uint256 projectedReimbursement = (total * effectiveBPS) / 1_000_000;

        if (projectedReimbursement > MAX_REIMBURSEMENT) {
            effectiveBPS = (MAX_REIMBURSEMENT * 1_000_000) / total;
        } else if (projectedReimbursement < MIN_REIMBURSEMENT) {
            effectiveBPS = (MIN_REIMBURSEMENT * 1_000_000) / total;
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
