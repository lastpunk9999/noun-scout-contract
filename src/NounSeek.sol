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

    /// @notice Stores deposited value with the addresses that sent it
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

    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    // The address of the WETH contract
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
    -----------------------------
    --------- MODIFIERS ---------
    -----------------------------
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

    function donees(uint16 id) public view returns (Donee memory) {
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

    function requestParamsMatchNounParams(
        Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 targetNounId
    ) public view returns (bool) {
        // If a specific Noun Id is part of the request, but is not the target Noun id, can exit
        if (requestNounId != ANY_ID && requestNounId != targetNounId) {
            return false;
        }

        // No Preference Noun Id can only apply to auctioned Nouns
        if (requestNounId == ANY_ID && _isNonAuctionedNoun(targetNounId)) {
            return false;
        }

        uint16 targetTraitId;
        if (requestTrait == Traits.BACKGROUND) {
            targetTraitId = uint16(nouns.seeds(targetNounId).background);
        } else if (requestTrait == Traits.BODY) {
            targetTraitId = uint16(nouns.seeds(targetNounId).body);
        } else if (requestTrait == Traits.ACCESSORY) {
            targetTraitId = uint16(nouns.seeds(targetNounId).accessory);
        } else if (requestTrait == Traits.HEAD) {
            targetTraitId = uint16(nouns.seeds(targetNounId).head);
        } else if (requestTrait == Traits.GLASSES) {
            targetTraitId = uint16(nouns.seeds(targetNounId).glasses);
        }

        return requestTraitId == targetTraitId;
    }

    /**
    -----------------------------------------------
    --------- AUTHORIZED WRITE FUNCTIONS ---------
    -----------------------------------
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
            requester: msg.sender,
            amount: msg.value
        });

        _seeks[hash].push(requestId);

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

        uint16 targetNounId = uint16(auctionHouse.auction().nounId);
        _revertRemoveIfRequestParamsMatchNounParams(
            request.trait,
            request.traitId,
            request.nounId,
            targetNounId
        );

        _revertRemoveIfRequestParamsMatchNounParams(
            request.trait,
            request.traitId,
            request.nounId,
            targetNounId - 1
        );

        // If two auctioned Nouns aren't consecutive
        // Check the previous, previous Noun
        if (_isNonAuctionedNoun(targetNounId - 1)) {
            _revertRemoveIfRequestParamsMatchNounParams(
                request.trait,
                request.traitId,
                request.nounId,
                targetNounId - 2
            );
        }

        bytes32 hash = seekHash(request.trait, request.traitId, request.nounId);
        uint256 lastIndex = _seeks[hash].length - 1;

        if (request.seekIndex < lastIndex) {
            uint16 lastId = _seeks[hash][lastIndex];
            _requests[lastId].seekIndex = request.seekIndex;
            _seeks[hash][request.seekIndex] = lastId;
        }

        _seeks[hash].pop();
        delete _requests[requestId];

        _safeTransferETH(request.requester, request.amount);
    }

    function matchAndDonate(
        uint16 targetNounId,
        Traits trait,
        uint256 max
    ) public {
        uint16 eligibleNounId = uint16(auctionHouse.auction().nounId) - 1;
        uint16 prevEligibleNounId = eligibleNounId - 1;

        if (
            targetNounId != eligibleNounId && targetNounId != prevEligibleNounId
        ) {
            revert IneligibleNounId();
        }

        if (
            _isAuctionedNoun(eligibleNounId) &&
            _isAuctionedNoun(prevEligibleNounId) &&
            targetNounId == prevEligibleNounId
        ) {
            revert IneligibleNounId();
        }

        uint256 reimbursement;
        uint256 doneesLength = _donees.length;
        uint256[] memory donations = new uint256[](doneesLength);

        // Match specify Noun Id requests
        (donations, reimbursement, max) = _calcFundsAndDelete(
            trait,
            targetNounId,
            targetNounId,
            max,
            donations,
            reimbursement
        );

        // If the Noun was auctioned, match NO PREFERENCE requesets
        if (_isAuctionedNoun(targetNounId)) {
            (donations, reimbursement, max) = _calcFundsAndDelete(
                trait,
                targetNounId,
                ANY_ID,
                max,
                donations,
                reimbursement
            );
        }

        for (uint256 i; i < doneesLength; i++) {
            if (donations[i] == 0) continue;
            _safeTransferETH(_donees[i].to, donations[i]);
        }
        _safeTransferETH(msg.sender, reimbursement);
    }

    /**
    -----------------------------------
    ------- INTERNAL FUNCTIONS --------
    -----------------------------------
     */
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 == 0 && nounId <= 1820;
    }

    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 != 0 || nounId > 1820;
    }

    function _calcFundsAndDelete(
        Traits trait,
        uint16 actualNounId,
        uint16 requestNounId,
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

        uint16 traitId;
        if (trait == Traits.BACKGROUND) {
            traitId = uint16(nouns.seeds(actualNounId).background);
        } else if (trait == Traits.BODY) {
            traitId = uint16(nouns.seeds(actualNounId).body);
        } else if (trait == Traits.ACCESSORY) {
            traitId = uint16(nouns.seeds(actualNounId).accessory);
        } else if (trait == Traits.HEAD) {
            traitId = uint16(nouns.seeds(actualNounId).head);
        } else if (trait == Traits.GLASSES) {
            traitId = uint16(nouns.seeds(actualNounId).glasses);
        }

        Request[] memory nounIdRequests = requestsForTrait(
            trait,
            traitId,
            requestNounId,
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

        if (nounIdRequestsLength > 0) {
            bytes32 hash = seekHash(trait, traitId, requestNounId);
            delete _seeks[hash];
        }

        return (donations, reimbursement, max - nounIdRequestsLength);
    }

    function _revertRemoveIfRequestParamsMatchNounParams(
        Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 targetNounId
    ) internal view {
        if (
            requestParamsMatchNounParams(
                requestTrait,
                requestTraitId,
                requestNounId,
                targetNounId
            )
        ) revert MatchFound(requestTrait, requestTraitId, targetNounId);
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
