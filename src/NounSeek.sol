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

    /// @notice Number used to signify "any value" or "no preference"
    /// @dev Noun traits are 0-indexed so the Solidity default of 0 cannot be used
    uint16 public constant NO_PREFERENCE = 54321;

    /// @notice Stored to save gas
    uint16 private constant NULL_VALUE = type(uint16).max;

    /// @notice Stores deposited value with the addresses that sent it
    struct Request {
        uint16 headRequestIndex;
        uint16 headId;
        uint16 doneeId;
        uint16 nounId;
        uint16 nounIdAtRequest;
        address requester;
        uint256 amount;
    }

    uint256 public doneeCount;
    uint256 public requestCount;

    uint16 public headCount;

    address[] public donees;
    mapping(uint16 => uint256[]) internal _headRequests;

    mapping(uint256 => Request) internal _requests;

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

    function requests(uint256 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function headRequestIds(uint16 headId)
        public
        view
        returns (uint256[] memory)
    {
        return _headRequests[headId];
    }

    function headRequests(uint16 headId)
        public
        view
        returns (Request[] memory)
    {
        Request[] memory requests = new Request[](_headRequests[headId].length);
        for (uint256 i = 0; i < _headRequests[headId].length; i++) {
            requests[i] = (_requests[_headRequests[headId][i]]);
        }
        return requests;
    }

    // function headRequests(uint16 headId)
    //     public
    //     view
    //     returns (Request[] memory)
    // {
    //     return headRequestsForNoun(headId, NO_PREFERENCE);
    // }

    // function headRequestsForNoun(uint16 headId, uint16 nounId)
    //     public
    //     view
    //     returns (Request[] memory)
    // {
    //     uint256 headRequestLength = _headRequests[headId].length;

    //     uint256[] memory requestIds = new uint256[](headRequestLength);
    //     uint256[] memory filteredRequestIds = new uint256[](headRequestLength);
    //     uint256 filteredRequestCount;

    //     requestIds = _headRequests[headId];

    //     for (uint256 i = 0; i < headRequestLength; i++) {
    //         uint256 requestId = requestIds[i];
    //         Request memory request = _requests[requestId];
    //         if (
    //             nounId == NO_PREFERENCE ||
    //             request.nounId == nounId ||
    //             request.nounId == NO_PREFERENCE
    //         ) {
    //             filteredRequestIds[i] = requestId;
    //             filteredRequestCount++;
    //         } else {
    //             filteredRequestIds[i] = NULL_VALUE;
    //         }
    //     }

    //     Request[] memory filteredRequests = new Request[](filteredRequestCount);
    //     for (uint256 i = 0; i < headRequestLength; i++) {
    //         if (requestIds[i] == NULL_VALUE) continue;
    //         filteredRequests[i] = _requests[requestIds[i]];
    //     }
    //     return filteredRequests;
    // }

    // /**
    //  * @notice Determines if a desired set of traits in a Seek are found to match the combination of Noun seed and id
    //  * @param seed Struct of Noun trait ids
    //  * @param nounId The Noun Id that contains the seed traits
    //  * @param seekId The seek Id to match against the Noun parameters
    //  */
    // function seekMatchesTraits(
    //     uint16 nounId,
    //     INounsSeederLike.Seed memory seed,
    //     uint96 seekId
    // ) public view returns (bool) {
    //     Seek memory seek = _seeks[seekId];

    //     // The Seek has been previously matched
    //     if (seek.finder != address(0)) {
    //         return false;
    //     }

    //     // The seek has a Noun Id preference and nounId parameter does not match
    //     if (seek.nounId != NO_PREFERENCE && seek.nounId != nounId) {
    //         return false;
    //     }

    //     // The seek requests only auctioned Nouns, but the Noun Id is divisible by 10 and was not auctioned
    //     if (nounId % 10 == 0 && seek.onlyAuctionedNoun) {
    //         return false;
    //     }

    //     if (seek.body != NO_PREFERENCE && seek.body != seed.body) {
    //         return false;
    //     }

    //     if (
    //         seek.accessory != NO_PREFERENCE && seek.accessory != seed.accessory
    //     ) {
    //         return false;
    //     }

    //     if (seek.head != NO_PREFERENCE && seek.head != seed.head) {
    //         return false;
    //     }

    //     if (seek.glasses != NO_PREFERENCE && seek.glasses != seed.glasses) {
    //         return false;
    //     }

    //     return true;
    // }

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

    function addDonee(address donee) public {
        donees.push(donee);
    }

    function add(
        uint16 headId,
        uint16 doneeId,
        uint16 nounId
    ) public payable returns (uint256) {
        if (headId >= headCount) {
            revert("1");
        }
        if (donees[doneeId] == address(0)) {
            revert();
        }

        uint16 nounIdAtRequest = uint16(auctionHouse.auction().nounId);

        if (nounId <= nounIdAtRequest) {
            revert();
        }

        console2.log(
            "BEFORE _headRequests[headId].length",
            _headRequests[headId].length
        );
        // length of all requests for specific head
        uint16 headRequestIndex = uint16(_headRequests[headId].length);

        uint256 requestId = ++requestCount;

        _requests[requestId] = Request({
            headRequestIndex: headRequestIndex,
            doneeId: doneeId,
            headId: headId,
            nounId: nounId,
            nounIdAtRequest: nounIdAtRequest,
            requester: msg.sender,
            amount: msg.value
        });

        _headRequests[headId].push(requestId);

        console2.log(
            "AFTER_headRequests[headId].length",
            _headRequests[headId].length
        );

        return requestId;
    }

    function remove(uint256 requestId) public {
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

    // /**
    //  * @notice Adds a reward for finding a Noun with specific attributes. Must be called within a specific time window.
    //  * @dev If a Seek already exists to target those attributes, msg.value is added to it, otherwise a new Seek is created
    //  * @param body Trait id of sought after body
    //  * @param accessory Trait id of sought after accessory
    //  * @param head Trait id of sought after head
    //  * @param glasses Trait id of sought after glasses
    //  * @param nounId The previous traits can only be found in this Noun id
    //  * @param onlyAuctionedNoun If `true` traits can match against a non-auctioned Noun. If a `nounId` parameter is specified, this parameter is overriden appropriately.
    //  * @return uint256 This request's unique id
    //  * @return uint256 The seek id that this request generated or contributed to
    //  */
    // function add(
    //     uint16 body,
    //     uint16 accessory,
    //     uint16 head,
    //     uint16 glasses,
    //     uint16 nounId,
    //     bool onlyAuctionedNoun
    // ) public payable withinRequestWindow returns (uint96, uint96) {
    //     if (
    //         uint256(body) +
    //             uint256(accessory) +
    //             uint256(head) +
    //             uint256(glasses) ==
    //         uint256(NO_PREFERENCE) * 4
    //     ) {
    //         revert NoPreferences();
    //     }

    //     if (msg.value == 0) {
    //         revert NoAmountSent();
    //     }

    //     // if `nounId` is specified, set correct value for `onlyAuctionedNoun`;
    //     if (nounId % 10 == 0) {
    //         onlyAuctionedNoun = false;
    //     } else if (nounId < NO_PREFERENCE) {
    //         onlyAuctionedNoun = true;
    //     }
    //     // Look up seek Id by its paramater hash
    //     (uint96 seekId, bytes32 traitsHash) = traitsToSeekIdAndHash(
    //         body,
    //         accessory,
    //         head,
    //         glasses,
    //         nounId,
    //         onlyAuctionedNoun
    //     );

    //     Counter memory counter = _counter;
    //     Seek memory seek = _seeks[seekId];
    //     uint256 amount = seek.amount;

    //     // If lookup doesn't find a Seek or the Seek has been found, reset paramaters and create a new Seek
    //     if (seekId == 0 || seek.finder != address(0)) {
    //         seekId = ++counter.seekCount;
    //         seek.onlyAuctionedNoun = onlyAuctionedNoun;
    //         seek.nounId = nounId;
    //         seek.body = body;
    //         seek.accessory = accessory;
    //         seek.head = head;
    //         seek.glasses = glasses;
    //         seek.finder = address(0);
    //         amount = 0;
    //         traitsHashToSeekId[traitsHash] = seekId;

    //         emit SeekAdded(
    //             seekId,
    //             body,
    //             accessory,
    //             head,
    //             glasses,
    //             nounId,
    //             onlyAuctionedNoun
    //         );
    //     }
    //     amount += msg.value;
    //     seek.amount = amount;
    //     _seeks[seekId] = seek;
    //     _requests[++counter.requestCount] = Request({
    //         seeker: msg.sender,
    //         seekId: seekId,
    //         amount: msg.value
    //     });

    //     _counter = counter;
    //     emit SeekAmountUpdated(seekId, amount);

    //     emit RequestAdded(counter.requestCount, seekId, msg.sender, msg.value);

    //     return (counter.requestCount, seekId);
    // }

    // /**
    //  * @notice Removes a reward. Must be called within a specific time window. Cannot be called if the requeste traits have been matched.
    //  @param requestId The unique id of the request
    //  @return bool The success status of the returned funds
    //  */
    // function remove(uint96 requestId)
    //     public
    //     withinRequestWindow
    //     returns (bool)
    // {
    //     Request memory request = _requests[requestId];
    //     if (request.seeker != msg.sender) {
    //         revert OnlySeeker();
    //     }

    //     Seek memory seek = _seeks[request.seekId];

    //     if (seek.finder != address(0)) {
    //         revert AlreadyFound();
    //     }

    //     seek.amount -= request.amount;

    //     delete _requests[requestId];

    //     if (seek.amount > 0) {
    //         _seeks[request.seekId] = seek;
    //         emit SeekAmountUpdated(request.seekId, seek.amount);
    //     } else {
    //         (, bytes32 traitsHash) = traitsToSeekIdAndHash(seek);
    //         delete _seeks[request.seekId];
    //         delete traitsHashToSeekId[traitsHash];
    //         emit SeekRemoved(request.seekId);
    //     }

    //     emit RequestRemoved(requestId);

    //     (bool success, ) = msg.sender.call{value: request.amount, gas: 10_000}(
    //         ""
    //     );

    //     return success;
    // }

    // /**
    //  * @notice Matches the currently auctioned Noun (and/or the previous Noun if it is a non-auctioned Noun) with a set of Seeks in order to claim their reward. This must be called within a specified window of time after the aution has started.
    //  * @dev Will not revert if there is no match on any seekId
    //  * @param seekIds An array of seekIds that might match the current Noun and/or the previous Noun if it was not auctioned
    //  * @return bool[] The match status of each seekId
    //  */
    // function matchWithCurrent(uint96[] memory seekIds)
    //     public
    //     withinMatchCurrentWindow
    //     returns (bool[] memory)
    // {
    //     INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

    //     // The set of 2 Noun ids to be checked and used to retreive seeds
    //     // The first is from the Noun currently on auction
    //     // The value `NULL_VALUE` is used because Noun Ids are 0-indexed and so the solidity default of 0 can be confused with a valid Noun id
    //     uint16[2] memory nounIds = [uint16(auction.nounId), NULL_VALUE];

    //     // The set of 2 Noun seeds to be checked
    //     INounsSeederLike.Seed[2] memory nounSeeds;
    //     nounSeeds[0] = nouns.seeds(nounIds[0]);

    //     // If the previous Noun was not auctioned, add its id and seed to test if it matches
    //     if ((nounIds[0] - 1) % 10 == 0) {
    //         nounIds[1] = nounIds[0] - 1;
    //         nounSeeds[1] = nouns.seeds(nounIds[1]);
    //     }

    //     return _matchAndSetFinder(nounIds, nounSeeds, seekIds);
    // }

    // /**
    //  * @notice Settles the Noun auction and matches the next minted Nouns (and/or the the following Noun the next mint will not be auctioned) with a set of Seeks.
    //  * @dev Will revert if the previous blockhash does not match the target. This allows certainty that the Seek(s) will match the next minted Noun(s)
    //  * @param targetBlockHash The blockhash that will produce Noun(s) which match the Seek(s)
    //  * @param seekIds An array of seekIds that match the next Noun(s)
    //  */
    // function settleAndMatch(bytes32 targetBlockHash, uint96[] memory seekIds)
    //     public
    //     returns (bool[] memory)
    // {
    //     if (targetBlockHash != blockhash(block.number - 1)) {
    //         revert BlockHashMismatch();
    //     }

    //     auctionHouse.settleCurrentAndCreateNewAuction();

    //     return matchWithCurrent(seekIds);
    // }

    // /**
    //  * @notice Allows a Seek finder to withdraw their reward
    //  * @param seekId The id of the Seek msg.sender matched
    //  * @return bool Success
    //  */
    // function withdraw(uint96 seekId) public returns (bool) {
    //     Seek memory seek = _seeks[seekId];

    //     if (seek.finder != msg.sender) {
    //         revert OnlyFinder();
    //     }

    //     _seeks[seekId].amount = 0;

    //     emit FinderWithdrew(seekId, msg.sender, seek.amount);

    //     (bool success, ) = msg.sender.call{value: seek.amount, gas: 10_000}("");
    //     return success;
    // }

    // /**
    // --------------------------------------
    // --------- INTERNAL FUNCTIONS ---------
    // --------------------------------------
    //  */

    // /**
    //  * @notice Runs matching algorithm for each seekId against Noun ids and seeds.
    //  * @dev If a match is found, Seek.finder parameter is set to msg.sender to allow that address to withdraw reward funds
    //  * @param nounIds 1 or 2 Noun ids to match
    //  * @param nounSeeds 1 or 2 Noun seeds to match
    //  * @param seekIds any number of Seeks to match against Noun ids and seeds
    //  */
    // function _matchAndSetFinder(
    //     uint16[2] memory nounIds,
    //     INounsSeederLike.Seed[2] memory nounSeeds,
    //     uint96[] memory seekIds
    // ) internal returns (bool[] memory) {
    //     uint256 _length = seekIds.length;
    //     bool[] memory matched = new bool[](_length);

    //     for (uint256 i = 0; i < _length; i++) {
    //         // Two Nouns can be minted during settlement, so both must be checked for a match
    //         // A Seek can only be matched once
    //         for (uint256 n = 0; n < 2; n++) {
    //             // Seek has already been matched or there is no Noun to check,

    //             if (matched[i] || nounIds[n] == NULL_VALUE) continue;

    //             matched[i] = seekMatchesTraits(
    //                 nounIds[n],
    //                 nounSeeds[n],
    //                 seekIds[i]
    //             );

    //             if (matched[i]) {
    //                 _seeks[seekIds[i]].finder = msg.sender;
    //                 emit SeekMatched(seekIds[i], nounIds[n], msg.sender);
    //             }
    //         }
    //     }

    //     return matched;
    // }
}
