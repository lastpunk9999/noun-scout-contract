// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./NounsInterfaces.sol";
import "./ReentrancyGuard.sol";

contract NounSeek is ReentrancyGuard {
    /// @notice Retreives historical mapping of nounId -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Generates a seed from blockhash, Noun Id, and descriptor's trait counts
    INounsSeederLike public seeder;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice Descriptor holds trait count information used to generate a seed
    INounsDescriptorLike public descriptor;

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
    uint256 public immutable NO_PREFERENCE = 256256;

    /// @notice Stored to save gas
    uint256 private immutable NO_NOUN_ID = type(uint256).max;

    /// @notice Stores the traits that a Noun must have along with an accumulated reward for finding a Noun with those traits
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

    mapping(uint256 => Seek) public seeks;
    mapping(uint256 => Request) public requests;
    mapping(bytes32 => uint256) public traitsHashToSeekId;

    /**
    -----------------------------
    --------- MODIFIERS ---------
    -----------------------------
     */

    /// @notice Modified function must be called {AUCTION_START_LIMIT} after auction start time and {AUCTION_END_LIMIT} before auction end time
    modifier withinRequestWindow() {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        // Cannot executed within a time from an auction's start
        require(
            block.timestamp - auction.startTime >= AUCTION_START_LIMIT,
            "Too soon"
        );

        // Cannot executed within a time period from an auction's end
        require(
            auction.endTime - block.timestamp >= AUCTION_END_LIMIT,
            "Too late"
        );
        _;
    }

    /// @notice Modified function must be called within {AUCTION_START_LIMIT} of the auction start time
    modifier withinMatchCurrentWindow() {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        require(
            block.timestamp - auction.startTime < AUCTION_START_LIMIT,
            "Too  late"
        );
        _;
    }

    constructor(INounsTokenLike _nouns, INounsAuctionHouseLike _auctionHouse) {
        nouns = _nouns;
        seeder = _nouns.seeder();
        auctionHouse = _auctionHouse;
        descriptor = _nouns.descriptor();
    }

    /// @notice Re-initializes the `seeder` and `descriptor` from the Nouns token contract
    function updateSeederAndDescriptor() public {
        seeder = nouns.seeder();
        descriptor = nouns.descriptor();
    }

    /**
    ----------------------------------
    --------- VIEW FUNCTIONS ---------
    ----------------------------------
     */

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
        Seek memory seek = seeks[seekId];

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
        // if `nounId` is specified, set correct value for `onlyAuctionedNoun`;
        if (nounId % 10 == 0) {
            onlyAuctionedNoun = false;
        } else if (nounId < NO_PREFERENCE) {
            onlyAuctionedNoun = true;
        }
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

        // Look up seek Id by its paramater hash
        uint256 seekId = traitsHashToSeekId[traitsHash];
        Seek memory seek = seeks[seekId];

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
            seek.amount = 0;
            traitsHashToSeekId[traitsHash] = seekId;
        }
        seek.amount += msg.value;
        seeks[seekId] = seek;
        requests[++requestCount] = Request({
            seeker: msg.sender,
            seekId: seekId,
            amount: msg.value
        });

        // emit events
        return (requestCount, seekCount);
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
        Request memory request = requests[requestId];
        require(request.seeker == msg.sender, "Not authorized");
        require(seeks[request.seekId].finder == address(0), "Already found");

        seeks[request.seekId].amount -= request.amount;

        delete requests[requestId];

        (bool success, ) = msg.sender.call{value: request.amount, gas: 30_000}(
            new bytes(0)
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

        return _matchAndSetFinder(nounIds, nounSeeds, seekIds, false);
    }

    /**
     * @notice Matches the next minted Noun (and/or the the following Noun the next mint will not be auctioned) with a set of Seeks and settles the current auction.
     * @dev Will revert if there is no match on any seekId.
     * @dev nonReentrancy is needed because malicious contract can re-enter on Nouns settlement after the auction id has been incremented with a new set of Seeks
     * @param seekIds An array of seekIds that might match the current Noun and/or the previous Noun if it was not auctioned
     */
    function matchWithNextAndSettle(uint256[] memory seekIds)
        public
        nonReentrant
    {
        INounsAuctionHouseLike.Auction memory auction = auctionHouse.auction();

        // The set of 2 Noun ids to be checked and used to retreive seeds
        // The first is from the next minted Noun
        // The value `NO_NOUN_ID` is used because Noun Ids are 0-indexed and so the solidity default of 0 can be confused with a valid Noun id
        uint256[2] memory nounIds = [auction.nounId + 1, NO_NOUN_ID];

        INounsSeederLike.Seed[2] memory nounSeeds;
        nounSeeds[0] = seeder.generateSeed(nounIds[0], descriptor);

        // If the next minted Noun will not be auctioned, add the closest auctioned Noun id and seed
        if (nounIds[0] % 10 == 0) {
            nounIds[1] = nounIds[0] + 1;
            nounSeeds[1] = seeder.generateSeed(nounIds[1], descriptor);
        }

        // throw if any Seeks to not match
        _matchAndSetFinder(nounIds, nounSeeds, seekIds, true);

        auctionHouse.settleCurrentAndCreateNewAuction();
    }

    /**
     * @notice Allows a Seek finder to withdraw their reward
     * @param seekId The id of the Seek msg.sender matched
     * @return bool Success
     */
    function withdraw(uint256 seekId) public returns (bool) {
        Seek memory seek = seeks[seekId];
        require(seek.finder == msg.sender, "Not finder");
        seeks[seekId].amount = 0;
        (bool success, ) = msg.sender.call{value: seek.amount, gas: 30_000}(
            new bytes(0)
        );
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
     * @param shouldRevert If a match is not found for any seed, passing `true` will cause a revert
     */
    function _matchAndSetFinder(
        uint256[2] memory nounIds,
        INounsSeederLike.Seed[2] memory nounSeeds,
        uint256[] memory seekIds,
        bool shouldRevert
    ) internal returns (bool[] memory) {
        uint256 _length = seekIds.length;
        bool[] memory matched = new bool[](_length);

        // Two Nouns can be minted during settlement, so both must be checked for a match. Only one set of traits can match a Seek
        for (uint256 i = 0; i < _length; i++) {
            matched[i] = seekMatchesTraits(
                nounIds[0],
                nounSeeds[0],
                seekIds[i]
            );
            // No more Noun Ids to check or there's already a match
            if (nounIds[1] == NO_NOUN_ID || matched[i]) continue;
            matched[i] = seekMatchesTraits(
                nounIds[1],
                nounSeeds[1],
                seekIds[i]
            );
        }

        for (uint256 i = 0; i < _length; i++) {
            if (matched[i]) {
                seeks[seekIds[i]].finder = msg.sender;
                continue;
            }
            require(!shouldRevert, "No match");
        }

        return matched;
    }
}
