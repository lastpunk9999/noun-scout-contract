// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/NounsInterfaces.sol";

contract MockNouns is INounsTokenLike {
    mapping(uint256 => INounsSeederLike.Seed) private _seeds;

    function setSeed(INounsSeederLike.Seed memory seed, uint256 nounId) public {
        _seeds[nounId] = seed;
    }

    function seeds(uint256 nounId)
        external
        view
        returns (INounsSeederLike.Seed memory)
    {
        return _seeds[nounId];
    }
}

contract MockAuctionHouse is INounsAuctionHouseLike {
    INounsAuctionHouseLike.Auction private _auction;

    function startAuction(uint256 nounId) public {
        _auction.nounId = nounId;
        _auction.startTime = block.timestamp;
        _auction.endTime = block.timestamp + 24 hours;
    }

    function setNounId(uint256 nounId) public {
        _auction.nounId = nounId;
    }

    function setStartTime(uint256 startTime) public {
        _auction.startTime = startTime;
    }

    function setEndTime(uint256 endTime) public {
        _auction.endTime = endTime;
    }

    function setSettled(bool settled) public {
        _auction.settled = settled;
    }

    function auction()
        external
        view
        returns (INounsAuctionHouseLike.Auction memory)
    {
        return _auction;
    }

    function settleCurrentAndCreateNewAuction() public {
        startAuction(
            _auction.nounId % 10 == 9
                ? _auction.nounId + 2
                : _auction.nounId + 1
        );
    }
}
