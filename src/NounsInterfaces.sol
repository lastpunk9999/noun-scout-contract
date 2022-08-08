// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INounsAuctionHouseLike {
    struct Auction {
        uint256 nounId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    function auction() external view returns (Auction memory);

    function settleCurrentAndCreateNewAuction() external;
}

interface INounsDescriptorLike {}

interface INounsSeederLike {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptorLike descriptor)
        external
        view
        returns (Seed memory);
}

interface INounsTokenLike {
    function seeder() external view returns (INounsSeederLike);

    function descriptor() external view returns (INounsDescriptorLike);

    function seeds(uint256 nounId)
        external
        view
        returns (INounsSeederLike.Seed memory);
}
