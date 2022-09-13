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
    error NotRequester();
    error IneligibleNounId();
    error ValueTooLow();

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
      EVENTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    event RequestAdded(
        uint16 requestId,
        Traits trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 nounId,
        address requester,
        uint256 amount
    );
    event RequestRemoved(uint16 requestId);
    event Matched(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16[] removedRequestIds
    );
    event Donated(uint256 doneeId, address to, uint256 amount);
    event DoneeAdded(
        uint256 doneeId,
        string name,
        address to,
        string description
    );
    event DoneeActiveStatusChanged(uint256 doneeId, bool active);

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

    /// @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID
    uint16 public constant ANY_ID = 0;

    uint16 public requestCount;
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    /// @notice % of donated funds are sent to the address performing a match. Default is 1%
    uint16 public reimbursementBPS = 100;

    uint256 public minValue = 0.02 ether;

    Donee[] public _donees;

    mapping(bytes32 => uint16[]) internal _requestsIdsForTraits;

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
    function addDonee(
        string calldata name,
        address to,
        string calldata description
    ) public onlyOwner {
        _donees.push(Donee({name: name, to: to, active: true}));
        emit DoneeAdded(_donees.length - 1, name, to, description);
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param id Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 id) external onlyOwner {
        /// @dev If the id is larger than the donee set, will revert `Index out of bounds` error
        Donee memory donee = _donees[id];
        donee.active = !donee.active;
        _donees[id] = donee;
        emit DoneeActiveStatusChanged(id, donee.active);
    }

    /// @notice Pauses the NounSeek contract. Pausing can be reversed by unpausing.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses (resumes) the NounSeek contract. Unpausing can be reversed by pausing.
    function unpause() external onlyOwner {
        _unpause();
    }

    function setReimbursementBPS(uint16 newBPS) external onlyOwner {
        /// BPS cannot be less than 0.1% or greater than 10%
        if (newBPS < 10 || newBPS > 1000) revert();
        reimbursementBPS = newBPS;
    }

    function setMinValue(uint256 value) external onlyOwner {
        minValue = value;
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function allHeadRequestsForNoun(uint16 nounId)
        public
        view
        returns (
            Request[][] memory anyIdRequests,
            Request[][] memory nounIdRequests
        )
    {
        return allTraitRequestsForNoun(Traits.HEAD, nounId);
    }

    function allTraitRequestsForNoun(Traits trait, uint16 nounId)
        public
        view
        returns (
            Request[][] memory anyIdRequests,
            Request[][] memory nounIdRequests
        )
    {
        nounIdRequests = _allTraitRequestsForSpecificNounId(trait, nounId);

        if (_isAuctionedNoun(nounId)) {
            anyIdRequests = _allTraitRequestsForSpecificNounId(trait, ANY_ID);
        }
    }

    function _allTraitRequestsForSpecificNounId(Traits trait, uint16 nounId)
        internal
        view
        returns (Request[][] memory)
    {
        uint16 max = type(uint16).max;
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

        Request[][] memory nounIdRequests = new Request[][](traitCount);
        for (uint16 traitId; traitId < traitCount; traitId++) {
            (nounIdRequests[traitId], ) = _requestsForTrait(
                trait,
                traitId,
                nounId,
                max
            );
        }

        return nounIdRequests;
    }

    function allHeadRequestsForNextNoun()
        public
        view
        returns (
            uint16 anyId,
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            Request[][] memory anyIdRequests,
            Request[][] memory nextAuctionedRequests,
            Request[][] memory nextNonAuctionedRequests
        )
    {
        return allTraitRequestsForNextNoun(Traits.HEAD);
    }

    function allTraitRequestsForNextNoun(Traits trait)
        public
        view
        returns (
            uint16 anyId,
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            Request[][] memory anyIdRequests,
            Request[][] memory nextAuctionedRequests,
            Request[][] memory nextNonAuctionedRequests
        )
    {
        anyId = ANY_ID;
        nextAuctionedId = uint16(auctionHouse.auction().nounId) + 1;
        nextNonAuctionedId = type(uint16).max;

        if (_isNonAuctionedNoun(nextAuctionedId)) {
            nextNonAuctionedId = nextAuctionedId;
            nextAuctionedId++;
        }

        (anyIdRequests, nextAuctionedRequests) = allTraitRequestsForNoun(
            trait,
            nextAuctionedId
        );

        if (nextNonAuctionedId < nextAuctionedId) {
            nextNonAuctionedRequests = _allTraitRequestsForSpecificNounId(
                trait,
                nextNonAuctionedId
            );
        }
    }

    /// @notice Fetches a request based on its ID (index within the requests set)
    /// @dev Fetching a request based on its ID/index within the requests sets is zero indexed.
    /// @param requestId the ID to fetch based on its index within the requests sets
    function requests(uint16 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    /// @notice Fetch a Donee based on its ID (index within the donees set)
    /// @param id the ID to fetch based on its index within the Donees set
    function donees(uint16 id) public view returns (Donee memory) {
        return _donees[id];
    }

    /// @notice Fetch all request IDs for the given Trait type, Trait ID, and Noun ID pattern.
    /// Note that a request that specifies a Noun ID and a request that has an open Noun ID (the value `ANY_ID`), will be in different sets.
    /// @param trait The trait type to fetch requests for (see Traits enum)
    /// @param traitId The trait ID (within the trait type) to fetch requests matching
    /// @param nounId The Noun ID or `ANY_ID` to fetch requests matching. See Note regarding Noun IDs.
    function requestIdsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16[] memory) {
        return _requestsIdsForTraits[_path(trait, traitId, nounId)];
    }

    /// @notice Fetch requests for the given Trait type, Trait ID, and Noun ID pattern up to a max count.
    /// @param trait The trait type to fetch requests for (see Traits enum)
    /// @param traitId The trait ID (within the trait type) to fetch requests matching
    /// @param nounId The NoundID or "any Noun" to fetch requests matching. See Note regarding NounIDs.
    /// @param max The maximum number of requests to resolve and return
    function requestsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256 max
    ) public view returns (Request[] memory) {
        (Request[] memory traitRequests, , ) = _requestsForTrait(
            trait,
            traitId,
            nounId,
            max
        );
        return traitRequests;
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

    /// @notice Maps a list of request ids to stored Request
    /// @param ids List of request ids
    /// @return Request[] List of matched Requests
    function requestIdsToRequests(uint16[] memory ids)
        public
        view
        returns (Request[] memory)
    {
        Request[] memory requestsArr = new Request[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            requestsArr[i] = _requests[ids[i]];
        }
        return requestsArr;
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
    ) public payable whenNotPaused returns (uint16) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        /// @dev If the id is larger than the donee set, will revert `Index out of bounds` error
        if (!_donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = _path(trait, traitId, nounId);

        // length of all requests for specific head
        uint16 seekIndex = uint16(_requestsIdsForTraits[hash].length);

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

        _requestsIdsForTraits[hash].push(requestId);

        emit RequestAdded(
            requestId,
            trait,
            traitId,
            doneeId,
            nounId,
            msg.sender,
            msg.value
        );

        return requestId;
    }

    /// @notice Remove the specified request and return the associated ETH. Must be called by the requester and before AuctionEndWindow
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

        bytes32 hash = _path(request.trait, request.traitId, request.nounId);
        uint256 lastIndex = _requestsIdsForTraits[hash].length - 1;

        /// Swap the ID currently at the end of the set with selected index, allowing for a "pop"
        /// to remove the desired value (N). [..., N, ..., M] -> [..., M, ..., M] -> pop -> [..., M, ...]
        ///                                         <----->
        if (request.seekIndex < lastIndex) {
            uint16 lastId = _requestsIdsForTraits[hash][lastIndex];
            _requests[lastId].seekIndex = request.seekIndex;
            _requestsIdsForTraits[hash][request.seekIndex] = lastId;
        }

        _requestsIdsForTraits[hash].pop();
        delete _requests[requestId];

        emit RequestRemoved(requestId);

        _safeTransferETHWithFallback(request.requester, request.amount);
    }

    /// @notice Match up to the specified number of requests for the specified Noun ID and specific trait. Will send donation funds.
    /// @param nounId The Noun ID to match requests against
    /// @param trait The Trait type to enumerate requests for (see Traits enum)
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

        // If the Noun was auctioned, match open Noun ID requests by passing `ANY_ID` as `nounId`
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
            address to = _donees[i].to;
            _safeTransferETHWithFallback(to, donations[i]);
            emit Donated(i, to, donations[i]);
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

        /// get non-empty Requests filtered by trait parameters, maximum along with the total length of all request ids including empty requests
        (
            Request[] memory traitRequests,
            uint16[] memory removedRequestIds,
            uint256 allTraitRequestIdsLength
        ) = _requestsForTrait(trait, traitId, nounId, max);

        uint256 traitRequestsLength = traitRequests.length;

        if (traitRequestsLength == 0) {
            return (donations, reimbursement, max);
        }

        bytes32 hash = _path(trait, traitId, nounId);

        /// When the maximum is less than the total number of requests, only a subset will be returned
        bool isSubset = max < allTraitRequestIdsLength;

        for (uint256 i; i < traitRequestsLength; i++) {
            Request memory request;
            request = traitRequests[i];

            uint256 donation = (request.amount * (10000 - reimbursementBPS)) /
                10000;
            reimbursement += request.amount - donation;
            donations[request.doneeId] += donation;
            delete _requests[request.id];

            /// delete specific request ids in the array if only a subset or requests will be returned
            if (isSubset) delete _requestsIdsForTraits[hash][request.seekIndex];
        }

        /// if all requests will be returned, delete all members of the array
        if (!isSubset) {
            delete _requestsIdsForTraits[hash];
        }

        emit Matched(trait, traitId, nounId, removedRequestIds);

        return (donations, reimbursement, max - traitRequestsLength);
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

    function _requestsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256 max
    )
        internal
        view
        returns (
            Request[] memory,
            uint16[] memory,
            uint256
        )
    {
        /// Get the complete array of request ids grouped by trait parameters
        uint16[] memory requestIds = _requestsIdsForTraits[
            _path(trait, traitId, nounId)
        ];
        uint256 requestIdsLength = requestIds.length;
        uint256 subsetCount;

        /// Create an array to potentially hold a subset of requestIds
        uint16[] memory tempRequestIds = new uint16[](requestIdsLength);

        /// Copy non-zero ids to the temporary array
        for (uint256 i = 0; i < requestIdsLength && subsetCount < max; i++) {
            if (requestIds[i] > 0) {
                tempRequestIds[subsetCount] = requestIds[i];
                subsetCount++;
            }
        }

        /// If all ids exist in the temporary array, return the mapped Requests
        if (subsetCount == requestIdsLength) {
            return (
                requestIdsToRequests(requestIds),
                requestIds,
                requestIdsLength
            );
        }

        /// Create a new array for the subset of request ids
        uint16[] memory subsetRequestIds = new uint16[](subsetCount);
        for (uint256 i = 0; i < subsetCount; i++) {
            subsetRequestIds[i] = tempRequestIds[i];
        }

        // return the subset of Requests
        return (
            requestIdsToRequests(subsetRequestIds),
            subsetRequestIds,
            requestIdsLength
        );
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
