// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./Interfaces.sol";
import "forge-std/console2.sol";

contract NounSeek is Ownable2Step, Pausable {
    error TooLate();
    error MatchFound(Traits trait, uint16 traitId, uint16 nounId);
    error DoneeNotFound();
    error InactiveDonee();
    error NonExistentTraitId();
    error NotRequester();
    error IneligibleNounId();

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
    uint256 public constant AUCTION_END_LIMIT = 5 minutes;

    /// @notice 1% of donated funds are sent to the address performing a match
    uint256 public reimbursementBPS = 100;

    /// @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID
    uint16 public constant ANY_ID = 0;

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    Donee[] public _donees;

    /// Cumulative amount for hash(trait traitId nounId) doneeId
    mapping(bytes32 => mapping(uint16 => uint256)) internal _amountsByDonee;

    /// Incremented nonce for hash(trait, traitId, nounId)
    mapping(bytes32 => uint16) internal _nonces;

    // mapping(bytes32 => uint256) internal _totalAmounts;

    mapping(address => Request[]) internal _userRequests;

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
        _donees.push(Donee({name: name, to: to, active: true}));
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param id Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 id) external onlyOwner {
        Donee memory donee = _donees[id];
        if (donee.to == address(0)) revert DoneeNotFound();
        donee.active = !donee.active;
        _donees[id] = donee;
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
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function amountForDoneeByTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public view returns (uint256) {
        bytes32 hash = _traitPath(trait, traitId, nounId);
        return _amountsByDonee[hash][doneeId];
    }

    function donationForAllTraits(Traits trait, uint16 nounId)
        public
        view
        returns (uint256[][] memory)
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

        uint256 doneesLength = _donees.length;
        uint256[][] memory donations = new uint256[][](traitCount);

        bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);

        for (uint16 traitId; traitId < traitCount; traitId++) {
            bytes32 hash = _traitPath(trait, traitId, nounId);
            bytes32 anyIdHash = processAnyId
                ? _traitPath(trait, traitId, ANY_ID)
                : bytes32("");
            // if (_totalAmounts[hash] == 0) {
            //     continue;
            // }
            donations[traitId] = new uint256[](doneesLength);
            for (uint16 doneeId; doneeId < doneesLength; doneeId++) {
                uint256 anyIdAmount = processAnyId
                    ? _amountsByDonee[anyIdHash][doneeId]
                    : 0;
                donations[traitId][doneeId] =
                    _amountsByDonee[hash][doneeId] +
                    anyIdAmount;
            }
        }

        return donations;
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
        nextNonAuctionedId = type(uint16).max;

        if (_isNonAuctionedNoun(nextAuctionedId)) {
            nextNonAuctionedId = nextAuctionedId;
            nextAuctionedId++;
        }

        nextAuctionDonations = donationForAllTraits(trait, nextAuctionedId);

        if (nextNonAuctionedId < nextAuctionedId) {
            nextNonAuctionDonations = donationForAllTraits(
                trait,
                nextNonAuctionedId
            );
        }
    }

    /// @notice Fetches a request based on its ID (index within the requests set)
    /// @dev Fetching a request based on its ID/index within the requests sets is zero indexed.
    /// @param requester requester
    /// @param requestId the ID to fetch based on its index within the requests sets
    function requests(address requester, uint256 requestId)
        public
        view
        returns (Request memory)
    {
        return _userRequests[requester][requestId];
    }

    /// @notice Fetch a Donee based on its ID (index within the donees set)
    /// @param id the ID to fetch based on its index within the Donees set
    function doneesById(uint16 id) public view returns (Donee memory) {
        return _donees[id];
    }

    function donees() public view returns (Donee[] memory) {
        return _donees;
    }

    /// @notice Evaluate if the provided request Noun Trait matches the specified Noun ID
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
        // If a specific Noun Id is part of the request, but is not the target Noun id, can exit
        if (requestNounId != ANY_ID && requestNounId != nounId) {
            return false;
        }

        // No Preference Noun Id can only apply to auctioned Nouns
        if (requestNounId == ANY_ID && _isNonAuctionedNoun(nounId)) {
            return false;
        }

        uint16 targetTraitId;
        if (requestTrait == Traits.BACKGROUND) {
            targetTraitId = uint16(nouns.seeds(nounId).background);
        } else if (requestTrait == Traits.BODY) {
            targetTraitId = uint16(nouns.seeds(nounId).body);
        } else if (requestTrait == Traits.ACCESSORY) {
            targetTraitId = uint16(nouns.seeds(nounId).accessory);
        } else if (requestTrait == Traits.HEAD) {
            targetTraitId = uint16(nouns.seeds(nounId).head);
        } else if (requestTrait == Traits.GLASSES) {
            targetTraitId = uint16(nouns.seeds(nounId).glasses);
        }

        return requestTraitId == targetTraitId;
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      WRITE FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

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
        if (msg.value == 0) {
            revert();
        }

        if (!_donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = _traitPath(trait, traitId, nounId);
        uint16 nonce = _nonces[hash];

        _amountsByDonee[hash][doneeId] += msg.value;

        // _totalAmounts[hash] = msg.value;

        _userRequests[msg.sender].push(
            Request({
                nonce: nonce,
                doneeId: doneeId,
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                requester: msg.sender,
                amount: msg.value
            })
        );

        return _userRequests[msg.sender].length - 1;
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

        Request memory request = _userRequests[msg.sender][requestId];

        if (request.requester != msg.sender) {
            revert NotRequester();
        }

        if (request.amount == 0) {
            revert();
        }

        // Cannot remove a request if
        // 1) The current Noun on auction has the requested traits
        // 2) The previous Noun to the one on auction has the requested traits
        // 3) A Non-Auctioned Noun which matches the request.nounId is the previous Noun

        uint16 nounId = uint16(auctionHouse.auction().nounId);
        _revertRemoveIfRequestParamsMatchNounParams(
            request.trait,
            request.traitId,
            request.nounId,
            nounId
        );

        _revertRemoveIfRequestParamsMatchNounParams(
            request.trait,
            request.traitId,
            request.nounId,
            nounId - 1
        );

        // If two auctioned Nouns aren't consecutive
        // Check the previous, previous Noun
        if (_isNonAuctionedNoun(nounId - 1)) {
            _revertRemoveIfRequestParamsMatchNounParams(
                request.trait,
                request.traitId,
                request.nounId,
                nounId - 2
            );
        }

        bytes32 hash = _traitPath(
            request.trait,
            request.traitId,
            request.nounId
        );

        uint16 nonce = _nonces[hash];

        /// Funds can be returned if request has yet to be matched
        if (nonce == request.nonce) {
            _amountsByDonee[hash][request.doneeId] -= request.amount;
            // _totalAmounts[hash] -= request.amount;
        }

        /// Delete the record regardless
        delete _userRequests[msg.sender][requestId];

        if (nonce == request.nonce) {
            _safeTransferETHWithFallback(request.requester, request.amount);
        }
    }

    /// @notice Match up to the specified number of requests for the specified Noun ID and specific trait. Will send donation funds.
    /// @param nounId The Noun ID to match requests against
    /// @param trait The Trait type to enumerate requests for (see Traits enum)
    function matchAndDonate(uint16 nounId, Traits trait) public {
        uint16 eligibleNounId = uint16(auctionHouse.auction().nounId) - 1;
        uint16 prevEligibleNounId = eligibleNounId - 1;

        if (nounId != eligibleNounId && nounId != prevEligibleNounId) {
            revert IneligibleNounId();
        }

        if (
            _isAuctionedNoun(eligibleNounId) &&
            _isAuctionedNoun(prevEligibleNounId) &&
            nounId == prevEligibleNounId
        ) {
            revert IneligibleNounId();
        }

        uint256 reimbursement;
        uint256 doneesLength = _donees.length;
        uint256[] memory donations = new uint256[](doneesLength);

        uint16 traitId;
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

        // Match specify Noun Id requests
        (donations, reimbursement) = _getAmountsAndDeleteRequests(
            trait,
            traitId,
            nounId,
            donations,
            reimbursement
        );

        // If the Noun was auctioned, match open Noun ID requests by passing `ANY_ID` as `nounId`
        // if (_isAuctionedNoun(nounId)) {
        //     (donations, reimbursement) = _getAmountsAndDeleteRequests(
        //         trait,
        //         traitId,
        //         ANY_ID,
        //         donations,
        //         reimbursement
        //     );
        // }

        if (reimbursement == 0) revert();

        for (uint256 i; i < doneesLength; i++) {
            if (donations[i] == 0) continue;
            _safeTransferETHWithFallback(_donees[i].to, donations[i]);
        }
        _safeTransferETHWithFallback(msg.sender, reimbursement);
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice The canonical path for requests that target the same `trait`, `traitId`, and `nounId`
    /// @dev Used to group requests by their parameters in the `_requestsIdsForTraits` mapping
    function _path(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    function _traitPath(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    function _amountPath(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId,
        uint16 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(trait, traitId, nounId, doneeId, nonce));
    }

    /// @notice Was the specified Noun ID not auctioned
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 == 0 && nounId <= 1820;
    }

    /// @notice Was the specified Noun ID auctioned
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 != 0 || nounId > 1820;
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
        bytes32 hash = _traitPath(trait, traitId, nounId);
        bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);

        bytes32 anyIdHash;
        if (processAnyId) anyIdHash = _traitPath(trait, traitId, ANY_ID);
        // if (_totalAmounts[hash] == 0) return (donations, reimbursement);

        // delete _totalAmounts[hash];

        _nonces[hash]++;
        if (processAnyId) _nonces[anyIdHash]++;

        uint16 doneesLength = uint16(_donees.length);

        for (uint16 doneeId; doneeId < doneesLength; doneeId++) {
            uint256 anyIdAmount = processAnyId
                ? _amountsByDonee[anyIdHash][doneeId]
                : 0;
            uint256 amount = _amountsByDonee[hash][doneeId] + anyIdAmount;
            uint256 donation = (amount * (10000 - reimbursementBPS)) / 10000;
            reimbursement += amount - donation;
            donations[doneeId] += donation;

            delete _amountsByDonee[hash][doneeId];
            if (processAnyId) delete _amountsByDonee[anyIdHash][doneeId];
        }

        return (donations, reimbursement);
    }

    function _revertRemoveIfRequestParamsMatchNounParams(
        Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 nounId
    ) internal view {
        if (
            requestParamsMatchNounParams(
                requestTrait,
                requestTraitId,
                requestNounId,
                nounId
            )
        ) revert MatchFound(requestTrait, requestTraitId, nounId);
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
