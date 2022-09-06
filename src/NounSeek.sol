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
    error NonExistantTraitId();
    error UnsupportedTraitType();
    error NotRequester();
    error IneligibleNounId();

    /// @notice Stores deposited value, requested traits, donation target with the addresses that sent it
    struct Request {
        uint16 id;
        uint16 seekIndex;
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

    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice The address of the WETH contract
    IWETH public immutable weth;

    /// @notice Time limit before an auction ends
    uint256 public constant AUCTION_END_LIMIT = 5 minutes;

    uint256 public constant REIMBURSMENT_BPS = 100;

    uint16 public constant ANY_ID = 0;

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    Donee[] public _donees;

    mapping(bytes32 => uint16[]) internal _seeks;

    mapping(uint16 => Request) internal _requests;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      MODIFIERS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    modifier beforeAuctionEndWindow() {
        uint256 endTime = auctionHouse.auction().endTime;
        if (endTime <= block.timestamp) {
            revert TooLate();
        }

        // Cannot executed within a time period from an auction's end
        if (endTime - block.timestamp <= AUCTION_END_LIMIT) {
            revert TooLate();
        }
        _;
    }

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
    function addDonee(string calldata name, address to) external onlyOwner {
        _donees.push(Donee({name: name, to: to, active: true}));
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param id Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 id) external onlyOwner {
        Donee memory donee = _donees[id]; // q: can this call donees(id)?
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

    /// @notice Fetches a request based on its ID (index within the requests set)
    /// @dev Fetching a request based on its ID/index within the requests sets is zero indexed.
    /// @param requestId the ID to fetch based on its index within the requests sets
    function requests(uint16 requestId) public view returns (Request memory) { // q/nit: request(uint16)?
        return _requests[requestId];
    }

    /// @notice Fetch a Donee based on its ID (index within the donees set)
    /// @param id the ID to fetch based on its index within the Donees set
    function donees(uint16 id) public view returns (Donee memory) { //q/nit: donee(uint16)?
        return _donees[id];
    }

    /// @notice Fetch all request IDs for the given Trait type, Trait ID, and Noun ID pattern.
    /// Note that a request that specifies a NounID and a request that has an open NounID, will be in different sets.
    /// @param trait The trait type to fetch requests for
    /// @param traitId The trait ID (within the trait type) to fetch requests matching
    /// @param nounId The NoundID or "any Noun" to fetch requests matching. See Note regarding NounIDs.
    function requestIdsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16[] memory) {
        return _seeks[_seekHash(trait, traitId, nounId)];
    }

    /// @notice Fetch requests for the given Trait type, Trait ID, and Noun ID patern up to a max count.
    /// @param trait The trait type to fetch requests for
    /// @param traitId The trait ID (within the trait type) to fetch requests matching
    /// @param nounId The NoundID or "any Noun" to fetch requests matching. See Note regarding NounIDs.
    /// @param max The maximum number of requests to resolve and return
    function requestsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256 max
        // q: an `offset` parameter would be useful here
    ) public view returns (Request[] memory) {
        bytes32 hash = _seekHash(trait, traitId, nounId);
        uint256 seeksLength = _seeks[hash].length;
        if (seeksLength > max) seeksLength = max;
        Request[] memory traitRequests = new Request[](seeksLength);

        for (uint256 i = 0; i < seeksLength; i++) {
            traitRequests[i] = (_requests[_seeks[hash][i]]);
        }
        return traitRequests;
    }

    /// @notice Evaluate if the provided request Noun Trait matches the specified Noun ID
    /// @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
    /// @param requestTrait The trait type to compare the given Noun ID with
    /// @param requestTraitId The ID of the provided trait type to compare the given Noun ID with
    /// @param requestNounId The NounID parameter from a Noun Seek Request (may be ANY_ID)
    /// @param nounId Noun ID to fetch the attributes of to compare against the given request properties
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
        } else {
            revert UnsupportedTraitType();
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

    /// @notice Create and add a Trait request for the provided trait and NounID payable to the specified Donee. Request amount is tied to the sent value.
    /// @param trait Trait type the request is for
    /// @param traitId ID of the specified Trait that the request is for
    /// @param nounId the Noun ID the request is targeted for (or ANY_ID for open requests)
    /// @param doneeId the ID of the Donee that should receive the donation if a Noun matching the parameters is minted
    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public payable whenNotPaused returns (uint16) {
        if (trait == Traits.BACKGROUND && traitId >= backgroundCount) {
            revert NonExistantTraitId();
        } else if (trait == Traits.BODY && traitId >= bodyCount) {
            revert NonExistantTraitId();
        } else if (trait == Traits.ACCESSORY && traitId >= accessoryCount) {
            revert NonExistantTraitId();
        } else if (trait == Traits.HEAD && traitId >= headCount) {
            revert NonExistantTraitId();
        } else if (trait == Traits.GLASSES && traitId >= glassesCount) {
            revert NonExistantTraitId();
        } else if (
            // q: is this helpful?
            trait != Traits.BACKGROUND &&
            trait != Traits.BODY &&
            trait != Traits.ACCESSORY &&
            trait != Traits.HEAD &&
            trait != Traits.GLASSES
        ) {
            revert UnsupportedTraitType();
        }

        if (!_donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = _seekHash(trait, traitId, nounId);

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
            requester: msg.sender,
            amount: msg.value
        });

        _seeks[hash].push(requestId);

        return requestId;
    }

    /// @notice Remove the specified request and return the associated ETH. Must be called by the creator and before AuctionEndWindow
    function remove(uint16 requestId) public beforeAuctionEndWindow {
        Request memory request = _requests[requestId];

        if (request.requester != msg.sender) {
            revert NotRequester();
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

        bytes32 hash = _seekHash(
            request.trait,
            request.traitId,
            request.nounId
        );
        uint256 lastIndex = _seeks[hash].length - 1;

        /// Swap the ID currently at the end of the set with selected index, allowing for a "pop"
        /// to remove the desired value (N). [..., N, ..., M] -> [..., M, ..., N] -> pop -> [..., M, ...]
        ///                                         <----->
        if (request.seekIndex < lastIndex) {
            uint16 lastId = _seeks[hash][lastIndex];
            _requests[lastId].seekIndex = request.seekIndex;
            _seeks[hash][request.seekIndex] = lastId;
        }

        _seeks[hash].pop();
        delete _requests[requestId];

        _safeTransferETH(request.requester, request.amount);
    }

    /// @notice Match and up to the specified number of requests for the specified NounID and Trait types. Will send donation funds.
    /// @param nounId The NounID to match requests against
    /// @param trait The Trait type to enumerate requests for
    /// @param max The maximum number of requests to process
    function matchAndDonate(
        uint16 nounId,
        Traits trait,
        uint256 max
    ) public {
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
        } else {
            revert UnsupportedTraitType();
        }

        // Match specify Noun Id requests
        (donations, reimbursement, max) = _getAmountsAndDeleteRequests(
            trait,
            traitId,
            nounId,
            donations,
            reimbursement,
            max
        );

        // If the Noun was auctioned, match ANY_ID requesets
        if (_isAuctionedNoun(nounId)) {
            (donations, reimbursement, max) = _getAmountsAndDeleteRequests(
                trait,
                traitId,
                ANY_ID,
                donations,
                reimbursement,
                max
            );
        }

        for (uint256 i; i < doneesLength; i++) {
            if (donations[i] == 0) continue;
            _safeTransferETH(_donees[i].to, donations[i]);
        }
        _safeTransferETH(msg.sender, reimbursement);
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     @notice The canonical path for requests that target the same `trait`, `traitId`, and `nounId`
     Used to store similar requests in the `_seeks` mapping
    */
    function _seekHash(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    // q: should this be !_isAuctionedNoun(uint256)?
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 == 0 && nounId <= 1820;
    }

    /// @notice Was the specified NounID auctioned (a non-Nounder Noun)
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 != 0 || nounId > 1820;
    }

    /**
    @notice Looks up requests that with params `trait`, `traitId`, and `nounId` to calculate donation and reimubesement amounts then removes the requests from storage.
    @param trait Trait enum
    @param traitId Specific trait Id
    @param nounId Specific Noun Id
    @param max Maximum number of returned amounts
    @param donations Donations array to be mutated and returned
    @param reimbursement Reimbursement amount to be mutated and returne
    @return donations Mutated donations array
    @return reimbursement Mutated reimursement amount
    @return max Maximum remaining after request lookup
     */
    function _getAmountsAndDeleteRequests(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256[] memory donations,
        uint256 reimbursement,
        uint256 max
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

        Request[] memory nounIdRequests = requestsForTrait(
            trait,
            traitId,
            nounId,
            max
        );

        uint256 nounIdRequestsLength = nounIdRequests.length;

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

        /// @TODO: Bug here - all Request are deleted but should only be up to max
        if (nounIdRequestsLength > 0) {
            bytes32 hash = _seekHash(trait, traitId, nounId);
            delete _seeks[hash];
        }

        return (donations, reimbursement, max - nounIdRequestsLength);
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

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            weth.deposit{value: amount}();
            weth.transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 10,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 10_000}("");
        return success;
    }
}
