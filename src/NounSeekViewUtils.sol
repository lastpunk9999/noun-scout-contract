// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
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

    function donationsForUpcomingNounByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        )
    {
        unchecked {
            nextAuctionId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionId = UINT16_MAX;

            if (_isNonAuctionedNoun(nextAuctionId)) {
                nextNonAuctionId = nextAuctionId;
                nextAuctionId++;
            }

            nextAuctionDonations = nounSeek.donationsForNounIdByTrait(
                trait,
                nextAuctionId
            );

            if (nextNonAuctionId < UINT16_MAX) {
                nextNonAuctionDonations = nounSeek.donationsForNounIdByTrait(
                    trait,
                    nextNonAuctionId
                );
            }
        }
    }

    function donationsForNounOnAuctionByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 currentAuctionId,
            uint16 prevNonAuctionId,
            uint256[] memory currentAuctionDonations,
            uint256[] memory prevNonAuctionDonations
        )
    {
        unchecked {
            currentAuctionId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionId = UINT16_MAX;

            uint16 currentTraitId;
            uint16 prevTraitId;

            currentTraitId = _fetchTraitId(trait, currentAuctionId);

            uint256 doneesCount = nounSeek.donees().length;

            currentAuctionDonations = _donationsForNounIdWithTraitId(
                trait,
                currentTraitId,
                currentAuctionId,
                true,
                doneesCount
            );

            if (_isNonAuctionedNoun(currentAuctionId - 1)) {
                prevNonAuctionId = currentAuctionId - 1;
                prevTraitId = _fetchTraitId(trait, prevNonAuctionId);
                prevNonAuctionDonations = _donationsForNounIdWithTraitId(
                    trait,
                    prevTraitId,
                    prevNonAuctionId,
                    false,
                    doneesCount
                );
            }
        }
    }

    function donationsForMatchableNounByTrait(NounSeek.Traits trait)
        public
        view
        returns (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounDonations,
            uint256[] memory nonAuctionedNounDonations,
            uint256 totalDonations,
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

        uint256 doneesCount = nounSeek.donees().length;

        auctionedNounDonations = _donationsForNounIdWithTraitId({
            trait: trait,
            traitId: _fetchTraitId(trait, auctionedNounId),
            nounId: auctionedNounId,
            processAnyId: true,
            doneesCount: doneesCount
        });

        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;

        if (includeNonAuctionedNoun) {
            nonAuctionedNounDonations = _donationsForNounIdWithTraitId({
                trait: trait,
                traitId: _fetchTraitId(trait, nonAuctionedNounId),
                nounId: nonAuctionedNounId,
                processAnyId: false,
                doneesCount: doneesCount
            });
        }

        for (uint256 doneeId; doneeId < doneesCount; doneeId++) {
            uint256 nonAuctionedNounDonation;
            if (includeNonAuctionedNoun) {
                nonAuctionedNounDonation = nonAuctionedNounDonations[doneeId];
            }
            totalDonations +=
                auctionedNounDonations[doneeId] +
                nonAuctionedNounDonation;
        }
        (, reimbursement) = nounSeek
            .effectiveBPSAndReimbursementForDonationTotal(totalDonations);
        totalDonations -= reimbursement;
    }

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

    function _donationsForNounIdWithTraitId(
        NounSeek.Traits trait,
        uint16 traitId,
        uint16 nounId,
        bool processAnyId,
        uint256 doneesCount
    ) internal view returns (uint256[] memory donations) {
        unchecked {
            bool[] memory isActive = _mapDoneeActive(doneesCount);

            bytes32 hash = nounSeek.traitHash(trait, traitId, nounId);
            bytes32 anyIdHash;
            if (processAnyId) {
                anyIdHash = nounSeek.traitHash(trait, traitId, ANY_ID);
            }
            donations = new uint256[](doneesCount);
            for (uint16 doneeId; doneeId < doneesCount; doneeId++) {
                if (!isActive[doneeId]) continue;
                uint256 anyIdAmount = processAnyId
                    ? nounSeek.amounts(anyIdHash, doneeId)
                    : 0;
                donations[doneeId] =
                    nounSeek.amounts(hash, doneeId) +
                    anyIdAmount;
            }
        }
    }

    /**
     * @notice Maps array of Donees to array of active status booleans
     * @param doneesCount Cached length of _donees array
     * @return isActive Array of active status booleans
     */
    function _mapDoneeActive(uint256 doneesCount)
        internal
        view
        returns (bool[] memory isActive)
    {
        unchecked {
            isActive = new bool[](doneesCount);
            NounSeek.Donee[] memory donees = nounSeek.donees();
            for (uint256 i; i < doneesCount; i++) {
                isActive[i] = donees[i].active;
            }
        }
    }
}
