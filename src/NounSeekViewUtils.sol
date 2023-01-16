// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./NounSeek.sol";
import "./Interfaces.sol";

contract NounSeekViewUtils {
    NounSeek public immutable nounSeek;
    INounsTokenLike public immutable nouns;
    INounsAuctionHouseLike public immutable auctionHouse;
    uint16 public immutable ANY_ID;
    uint16 private constant UINT16_MAX = type(uint16).max;

    constructor(NounSeek _nounSeek) {
        nounSeek = _nounSeek;
        nouns = INounsTokenLike(nounSeek.nouns());
        auctionHouse = INounsAuctionHouseLike(nounSeek.auctionHouse());
        ANY_ID = nounSeek.ANY_ID();
    }

    function pledgesForUpcomingNounByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][] memory nextAuctionPledges,
            uint256[][] memory nextNonAuctionPledges
        )
    {
        unchecked {
            nextAuctionId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionId = UINT16_MAX;
            if (_isNonAuctionedNoun(nextAuctionId)) {
                nextNonAuctionId = nextAuctionId;
                nextAuctionId++;
            }
            nextAuctionPledges = nounSeek.pledgesForNounIdByTrait(
                trait,
                nextAuctionId
            );
            if (nextNonAuctionId < UINT16_MAX) {
                nextNonAuctionPledges = nounSeek.pledgesForNounIdByTrait(
                    trait,
                    nextNonAuctionId
                );
            }
        }
    }

    function pledgesForNounOnAuctionByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 currentAuctionId,
            uint16 prevNonAuctionId,
            uint256[] memory currentAuctionPledges,
            uint256[] memory prevNonAuctionPledges
        )
    {
        unchecked {
            currentAuctionId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionId = UINT16_MAX;
            uint16 currentTraitId;
            uint16 prevTraitId;
            currentTraitId = _fetchTraitId(trait, currentAuctionId);
            currentAuctionPledges = nounSeek.pledgesForNounIdByTraitId(
                trait,
                currentTraitId,
                currentAuctionId
            );
            if (_isNonAuctionedNoun(currentAuctionId - 1)) {
                prevNonAuctionId = currentAuctionId - 1;
                prevTraitId = _fetchTraitId(trait, prevNonAuctionId);
                prevNonAuctionPledges = nounSeek.pledgesForNounIdByTraitId(
                    trait,
                    prevTraitId,
                    prevNonAuctionId
                );
            }
        }
    }

    function pledgesForMatchableNounByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounPledges,
            uint256[] memory nonAuctionedNounPledges,
            uint256 totalPledges,
            uint256 reimbursement
        )
    {
        /**
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun Id | Noun Id
         * --------|-------------------
         *     101 | 99 (*skips 100)
         *     102 | 101, 100 (*includes 100)
         *     103 | 102
         */
        /// The Noun ID of the previous to the current Noun on auction
        auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        /// Setup a parameter to detect if a non-auctioned Noun should  be matched
        nonAuctionedNounId = UINT16_MAX;
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
        uint256 recipientsCount = nounSeek.recipients().length;
        auctionedNounPledges = nounSeek.pledgesForNounIdByTraitId({
            trait: trait,
            traitId: _fetchTraitId(trait, auctionedNounId),
            nounId: auctionedNounId
        });
        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;
        if (includeNonAuctionedNoun) {
            nonAuctionedNounPledges = nounSeek.pledgesForNounIdByTraitId({
                trait: trait,
                traitId: _fetchTraitId(trait, nonAuctionedNounId),
                nounId: nonAuctionedNounId
            });
        }
        for (
            uint256 recipientId;
            recipientId < recipientsCount;
            recipientId++
        ) {
            uint256 nonAuctionedNounPledge;
            if (includeNonAuctionedNoun) {
                nonAuctionedNounPledge = nonAuctionedNounPledges[recipientId];
            }
            totalPledges +=
                auctionedNounPledges[recipientId] +
                nonAuctionedNounPledge;
        }
        (, reimbursement) = nounSeek.effectiveBPSAndReimbursementForPledgeTotal(
            totalPledges
        );
        totalPledges -= reimbursement;
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * UTILITY FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /**
     * @notice Evaluate if the provided Request parameters matches the specified Noun
     * @param requestTrait The trait type to compare the given Noun ID with
     * @param requestTraitId The ID of the provided trait type to compare the given Noun ID with
     * @param requestNounId The NounID parameter from a Noun Seek Request (may be ANY_ID)
     * @param onChainNounId Noun ID to fetch the attributes of to compare against the given request properties
     * @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
     */
    function requestParamsMatchNounParams(
        NounSeek.Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 onChainNounId
    ) public view returns (bool) {
        return
            nounSeek.requestMatchesNoun(
                NounSeek.Request({
                    recipientId: 0,
                    trait: requestTrait,
                    traitId: requestTraitId,
                    nounId: requestNounId,
                    nonce: 0,
                    amount: 0
                }),
                onChainNounId
            );
    }

    /**
     * @notice The amount a given recipient will receive (before fees) if a Noun with specific trait parameters is minted
     * @param trait The trait enum
     * @param traitId The ID of the trait
     * @param nounId The Noun ID
     * @param recipientId The recipient ID
     * @return amount The amount before fees
     */
    function amountForRecipientByTrait(
        NounSeek.Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 recipientId
    ) public view returns (uint256 amount) {
        bytes32 hash = nounSeek.traitHash(trait, traitId, nounId);
        (amount, ) = nounSeek.pledgeGroups(hash, recipientId);
    }

    /**
     * @notice The nonce for a given recipient pledge group
     * @param trait The trait enum
     * @param traitId The ID of the trait
     * @param nounId The Noun ID
     * @param recipientId The recipient ID
     * @return nonce The amount before fees
     */
    function nonceForRecipientByTrait(
        NounSeek.Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 recipientId
    ) public view returns (uint16 nonce) {
        bytes32 hash = nounSeek.traitHash(trait, traitId, nounId);
        (, nonce) = nounSeek.pledgeGroups(hash, recipientId);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * INTERNAL FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /**
     * @notice Was the specified Noun ID not auctioned
     */
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 < 1 && nounId <= 1820;
    }

    /**
     * @notice Was the specified Noun ID auctioned
     */
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 > 0 || nounId > 1820;
    }

    function _fetchTraitId(NounSeek.Traits trait, uint16 nounId)
        internal
        view
        returns (uint16 traitId)
    {
        if (trait == NounSeek.Traits.BACKGROUND) {
            traitId = uint16(nouns.seeds(nounId).background);
        } else if (trait == NounSeek.Traits.BODY) {
            traitId = uint16(nouns.seeds(nounId).body);
        } else if (trait == NounSeek.Traits.ACCESSORY) {
            traitId = uint16(nouns.seeds(nounId).accessory);
        } else if (trait == NounSeek.Traits.HEAD) {
            traitId = uint16(nouns.seeds(nounId).head);
        } else if (trait == NounSeek.Traits.GLASSES) {
            traitId = uint16(nouns.seeds(nounId).glasses);
        }
    }

    /**
     * @notice Maps array of Recipients to array of active status booleans
     * @param recipientsCount Cached length of _recipients array
     * @return isActive Array of active status booleans
     */
    function _mapRecipientActive(uint256 recipientsCount)
        internal
        view
        returns (bool[] memory isActive)
    {
        unchecked {
            isActive = new bool[](recipientsCount);
            NounSeek.Recipient[] memory recipients = nounSeek.recipients();
            for (uint256 i; i < recipientsCount; i++) {
                isActive[i] = recipients[i].active;
            }
        }
    }
}
