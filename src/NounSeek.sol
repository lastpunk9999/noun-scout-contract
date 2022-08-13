// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./NounsInterfaces.sol";
import "forge-std/console2.sol";

contract NounSeek {
    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice A unique id based on the total number of Seeks generated
    uint256 public seekCount;

    /// @notice  A unique id based on the total number of Requests generated
    uint256 public requestCount;

    /// @notice Time limit after an auction starts
    uint256 public immutable AUCTION_START_LIMIT = 1 hours;

    /// @notice Time limit before an auction ends
    uint256 public immutable AUCTION_END_LIMIT = 5 minutes;

    /// @notice Number used to signify "any value" or "no preference"
    /// @dev Noun traits are 0-indexed so the Solidity default of 0 cannot be used
    uint48 public immutable NO_PREFERENCE = 256256;

    /// @notice Stored to save gas
    uint256 private immutable NO_NOUN_ID = type(uint256).max;

    /// @notice Stores the traits that a Noun must have along with an accumulated reward for finding a matching Noun
    struct Seek {
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
        uint256 nounId;
        bool onlyAuctionedNoun;
        uint256 amount;
        address finder;
    }

    /// @notice Stores deposited value with the addresses that sent it
    struct Request {
        address seeker;
        uint256 amount;
        uint256 seekId;
    }

    mapping(uint256 => Seek) internal _seeks;
    mapping(uint256 => Request) internal _requests;
    mapping(bytes32 => uint256) public traitsHashToSeekId;

    event SeekAdded(
        uint256 seekId,
        uint48 body,
        uint48 accessory,
        uint48 head,
        uint48 glasses,
        uint256 nounId,
        bool onlyAuctionedNoun
    );

    event SeekAmountUpdated(uint256 seekId, uint256 amount);
    event SeekRemoved(uint256 seekId);
    event RequestAdded(
        uint256 requestId,
        uint256 seekId,
        address seeker,
        uint256 amount
    );
    event RequestRemoved(uint256 requestId);
    event SeekMatched(uint256 seekId, uint256 nounId, address finder);
    event FinderWithdrew(uint256 seekId, address finder, uint256 amount);

    error TooSoon();
    error TooLate();
    error NoAmountSent();
    error NoPreferences();
    error OnlySeeker();
    error OnlyFinder();
    error AlreadyFound();
    error NoMatch(uint256 seekId);
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
    }

    /**
    ----------------------------------
    --------- VIEW FUNCTIONS ---------
    ----------------------------------
     */

    function seeks(uint256 seekId) public view returns (Seek memory) {
        return _seeks[seekId];
    }

    function requests(uint256 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function traitsHashToSeek(bytes32 traitsHash)
        public
        view
        returns (Seek memory)
    {
        return _seeks[traitsHashToSeekId[traitsHash]];
    }

    function traitsToSeekIdAndHash(
        uint48 body,
        uint48 accessory,
        uint48 head,
        uint48 glasses,
        uint256 nounId,
        bool onlyAuctionedNoun
    ) public view returns (uint256, bytes32) {
        // A unique identifier for Seek parameters
        bytes32 traitsHash = keccak256(
            abi.encodePacked(
                body,
                accessory,
                head,
                glasses,
                nounId,
                onlyAuctionedNoun
            )
        );

        return (traitsHashToSeekId[traitsHash], traitsHash);
    }

    function traitsToSeekIdAndHash(Seek memory seek)
        public
        view
        returns (uint256, bytes32)
    {
        // A unique identifier for Seek parameters
        bytes32 traitsHash = keccak256(
            abi.encodePacked(
                seek.body,
                seek.accessory,
                seek.head,
                seek.glasses,
                seek.nounId,
                seek.onlyAuctionedNoun
            )
        );

        return (traitsHashToSeekId[traitsHash], traitsHash);
    }

    /**
     * @notice Determines if a desired set of traits in a Seek are found to match the combination of Noun seed and id
     * @param seed Struct of Noun trait ids
     * @param nounId The Noun Id that contains the seed traits
     * @param seekId The seek Id to match against the Noun parameters
     */
    function seekMatchesTraits(
        uint256 nounId,
        INounsSeederLike.Seed memory seed,
        uint256 seekId
    ) public view returns (bool) {
        Seek memory seek = _seeks[seekId];

        // The Seek has been previously matched
        if (seek.finder != address(0)) {
            return false;
        }

        // The seek has a Noun Id preference and nounId parameter does not match
        if (seek.nounId != NO_PREFERENCE && seek.nounId != nounId) {
            return false;
        }

        // The seek requests only auctioned Nouns, but the Noun Id is divisible by 10 and was not auctioned
        if (nounId % 10 == 0 && seek.onlyAuctionedNoun) {
            return false;
        }

        if (seek.body != NO_PREFERENCE && seek.body != seed.body) {
            return false;
        }

        if (
            seek.accessory != NO_PREFERENCE && seek.accessory != seed.accessory
        ) {
            return false;
        }

        if (seek.head != NO_PREFERENCE && seek.head != seed.head) {
            return false;
        }

        if (seek.glasses != NO_PREFERENCE && seek.glasses != seed.glasses) {
            return false;
        }

        return true;
    }

    /**
    -----------------------------------
    --------- WRITE FUNCTIONS ---------
    -----------------------------------
     */

    /**
     * @notice Adds a reward for finding a Noun with specific attributes. Must be called within a specific time window.
     * @dev If a Seek already exists to target those attributes, msg.value is added to it, otherwise a new Seek is created
     * @param body Trait id of sought after body
     * @param accessory Trait id of sought after accessory
     * @param head Trait id of sought after head
     * @param glasses Trait id of sought after glasses
     * @param nounId The previous traits can only be found in this Noun id
     * @param onlyAuctionedNoun If `true` traits can match against a non-auctioned Noun. If a `nounId` parameter is specified, this parameter is overriden appropriately.
     * @return uint256 This request's unique id
     * @return uint256 The seek id that this request generated or contributed to
     */
    function add(
        uint48 body,
        uint48 accessory,
        uint48 head,
        uint48 glasses,
        uint256 nounId,
        bool onlyAuctionedNoun
    ) public payable withinRequestWindow returns (uint256, uint256) {
        if (body + accessory + head + glasses == NO_PREFERENCE * 4) {
            revert NoPreferences();
        }

        if (msg.value == 0) {
            revert NoAmountSent();
        }

        // if `nounId` is specified, set correct value for `onlyAuctionedNoun`;
        if (nounId % 10 == 0) {
            onlyAuctionedNoun = false;
        } else if (nounId < NO_PREFERENCE) {
            onlyAuctionedNoun = true;
        }
        // Look up seek Id by its paramater hash
        (uint256 seekId, bytes32 traitsHash) = traitsToSeekIdAndHash(
            body,
            accessory,
            head,
            glasses,
            nounId,
            onlyAuctionedNoun
        );
        Seek memory seek = _seeks[seekId];
        uint256 amount = seek.amount;

        // If lookup doesn't find a Seek or the Seek has been found, reset paramaters and create a new Seek
        if (seekId == 0 || seek.finder != address(0)) {
            seekId = ++seekCount;
            seek.onlyAuctionedNoun = onlyAuctionedNoun;
            seek.nounId = nounId;
            seek.body = body;
            seek.accessory = accessory;
            seek.head = head;
            seek.glasses = glasses;
            seek.finder = address(0);
            amount = 0;
            traitsHashToSeekId[traitsHash] = seekId;

            emit SeekAdded(
                seekId,
                body,
                accessory,
                head,
                glasses,
                nounId,
                onlyAuctionedNoun
            );
        }
        amount += msg.value;
        seek.amount = amount;
        _seeks[seekId] = seek;
        uint256 requestId = ++requestCount;
        _requests[requestId] = Request({
            seeker: msg.sender,
            seekId: seekId,
            amount: msg.value
        });

        emit SeekAmountUpdated(seekId, amount);

        emit RequestAdded(requestId, seekId, msg.sender, msg.value);

        return (requestId, seekId);
    }

    /**
     * @notice Removes a reward. Must be called within a specific time window. Cannot be called if the requeste traits have been matched.
     @param requestId The unique id of the request
     @return bool The success status of the returned funds
     */
    function remove(uint256 requestId)
        public
        withinRequestWindow
        returns (bool)
    {
        Request memory request = _requests[requestId];
        if (request.seeker != msg.sender) {
            revert OnlySeeker();
        }

        Seek memory seek = _seeks[request.seekId];

        if (seek.finder != address(0)) {
            revert AlreadyFound();
        }

        seek.amount -= request.amount;

        delete _requests[requestId];

        if (seek.amount > 0) {
            _seeks[request.seekId] = seek;
            emit SeekAmountUpdated(request.seekId, seek.amount);
        } else {
            (, bytes32 traitsHash) = traitsToSeekIdAndHash(seek);
            delete _seeks[request.seekId];
            delete traitsHashToSeekId[traitsHash];
            emit SeekRemoved(request.seekId);
        }

        emit RequestRemoved(requestId);

        (bool success, ) = msg.sender.call{value: request.amount, gas: 10_000}(
            ""
        );

        return success;
    }

    /**
     * @notice Matches the currently auctioned Noun (and/or the previous Noun if it is a non-auctioned Noun) with a set of Seeks in order to claim their reward. This must be called within a specified window of time after the aution has started.
     * @dev Will not revert if there is no match on any seekId
     * @param seekIds An array of seekIds that might match the current Noun and/or the previous Noun if it was not auctioned
     * @return bool[] The match status of each seekId
     */
    function matchWithCurrent(uint256[] memory seekIds)
        public
        withinMatchCurrentWindow
        returns (bool[] memory)
    {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        // The set of 2 Noun ids to be checked and used to retreive seeds
        // The first is from the Noun currently on auction
        // The value `NO_NOUN_ID` is used because Noun Ids are 0-indexed and so the solidity default of 0 can be confused with a valid Noun id
        uint256[2] memory nounIds = [auction.nounId, NO_NOUN_ID];

        // The set of 2 Noun seeds to be checked
        INounsSeederLike.Seed[2] memory nounSeeds;
        nounSeeds[0] = nouns.seeds(nounIds[0]);

        // If the previous Noun was not auctioned, add its id and seed to test if it matches
        if ((nounIds[0] - 1) % 10 == 0) {
            nounIds[1] = nounIds[0] - 1;
            nounSeeds[1] = nouns.seeds(nounIds[1]);
        }

        return _matchAndSetFinder(nounIds, nounSeeds, seekIds);
    }

    /**
     * @notice Settles the Noun auction and matches the next minted Nouns (and/or the the following Noun the next mint will not be auctioned) with a set of Seeks.
     * @dev Will revert if the previous blockhash does not match the target. This allows certainty that the Seek(s) will match the next minted Noun(s)
     * @param targetBlockHash The blockhash that will produce Noun(s) which match the Seek(s)
     * @param seekIds An array of seekIds that match the next Noun(s)
     */
    function settleAndMatch(bytes32 targetBlockHash, uint256[] memory seekIds)
        public
        returns (bool[] memory)
    {
        if (targetBlockHash != blockhash(block.number - 1)) {
            revert BlockHashMismatch();
        }

        auctionHouse.settleCurrentAndCreateNewAuction();

        return matchWithCurrent(seekIds);
    }

    /**
     * @notice Allows a Seek finder to withdraw their reward
     * @param seekId The id of the Seek msg.sender matched
     * @return bool Success
     */
    function withdraw(uint256 seekId) public returns (bool) {
        Seek memory seek = _seeks[seekId];

        if (seek.finder != msg.sender) {
            revert OnlyFinder();
        }

        _seeks[seekId].amount = 0;

        emit FinderWithdrew(seekId, msg.sender, seek.amount);

        (bool success, ) = msg.sender.call{value: seek.amount, gas: 10_000}("");
        return success;
    }

    /**
    --------------------------------------
    --------- INTERNAL FUNCTIONS ---------
    --------------------------------------
     */

    /**
     * @notice Runs matching algorithm for each seekId against Noun ids and seeds.
     * @dev If a match is found, Seek.finder parameter is set to msg.sender to allow that address to withdraw reward funds
     * @param nounIds 1 or 2 Noun ids to match
     * @param nounSeeds 1 or 2 Noun seeds to match
     * @param seekIds any number of Seeks to match against Noun ids and seeds
     */
    function _matchAndSetFinder(
        uint256[2] memory nounIds,
        INounsSeederLike.Seed[2] memory nounSeeds,
        uint256[] memory seekIds
    ) internal returns (bool[] memory) {
        uint256 _length = seekIds.length;
        bool[] memory matched = new bool[](_length);

        for (uint256 i = 0; i < _length; i++) {
            // Two Nouns can be minted during settlement, so both must be checked for a match
            // A Seek can only be matched once
            for (uint256 n = 0; n < 2; n++) {
                // Seek has already been matched or there is no Noun to check,

                if (matched[i] || nounIds[n] == NO_NOUN_ID) continue;

                matched[i] = seekMatchesTraits(
                    nounIds[n],
                    nounSeeds[n],
                    seekIds[i]
                );

                if (matched[i]) {
                    _seeks[seekIds[i]].finder = msg.sender;
                    emit SeekMatched(seekIds[i], nounIds[n], msg.sender);
                }
            }
        }

        return matched;
    }
}
