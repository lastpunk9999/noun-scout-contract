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

    function addDonee(string calldata name, address to) external onlyOwner {
        _donees.push(Donee({name: name, to: to, active: true}));
    }

    function toggleDoneeActive(uint256 id) external onlyOwner {
        Donee memory donee = _donees[id];
        if (donee.to == address(0)) revert DoneeNotFound();
        donee.active = !donee.active;
        _donees[id] = donee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function requests(uint16 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function donees(uint16 id) public view returns (Donee memory) {
        return _donees[id];
    }

    function requestIdsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16[] memory) {
        return _requestsIdsForTraits[_path(trait, traitId, nounId)];
    }

    function requestsForTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint256 max
    ) public view returns (Request[] memory) {
        (Request[] memory traitRequests, ) = _requestsForTrait(
            trait,
            traitId,
            nounId,
            max
        );
        return traitRequests;
    }

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
        }

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

        return requestId;
    }

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

        if (request.seekIndex < lastIndex) {
            uint16 lastId = _requestsIdsForTraits[hash][lastIndex];
            _requests[lastId].seekIndex = request.seekIndex;
            _requestsIdsForTraits[hash][request.seekIndex] = lastId;
        }

        _requestsIdsForTraits[hash].pop();
        delete _requests[requestId];

        _safeTransferETHWithFallback(request.requester, request.amount);
    }

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
            _safeTransferETHWithFallback(_donees[i].to, donations[i]);
        }
        _safeTransferETHWithFallback(msg.sender, reimbursement);
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     @notice The canonical path for requests that target the same `trait`, `traitId`, and `nounId`
     Used to store similar requests in the `_requestsIdsForTraits` mapping
    */
    function _path(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 == 0 && nounId <= 1820;
    }

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

        /// get non-empty Requests filtered by trait parameters, maximum along with the total length of all request ids including empty requests
        (
            Request[] memory traitRequests,
            uint256 traitRequestIdsLength
        ) = _requestsForTrait(trait, traitId, nounId, max);

        uint256 traitRequestsLength = traitRequests.length;

        if (traitRequestsLength == 0) {
            return (donations, reimbursement, max);
        }

        bytes32 hash = _path(trait, traitId, nounId);

        /// When the maximum is less than the total number of requests, only a subset will be returned
        bool isSubset = max < traitRequestIdsLength;

        for (uint256 i; i < traitRequestsLength; i++) {
            Request memory request;
            request = traitRequests[i];

            uint256 donation = (request.amount * (10000 - REIMBURSMENT_BPS)) /
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
    ) internal view returns (Request[] memory, uint256) {
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
            return (requestIdsToRequests(requestIds), requestIdsLength);
        }

        /// Create a new array for the subset of request ids
        uint16[] memory subsetRequestIds = new uint16[](subsetCount);
        for (uint256 i = 0; i < subsetCount; i++) {
            subsetRequestIds[i] = tempRequestIds[i];
        }

        // return the subset of Requests
        return (requestIdsToRequests(subsetRequestIds), requestIdsLength);
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
