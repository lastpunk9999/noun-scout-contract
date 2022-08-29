// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/NounsInterfaces.sol";

contract MockNouns is INounsTokenLike {
    address public _descriptor;

    mapping(uint256 => INounsSeederLike.Seed) private _seeds;

    constructor(address __descriptor) {
        _descriptor = __descriptor;
    }

    function descriptor() public view returns (address) {
        return _descriptor;
    }

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

contract MockDescriptor is INounsDescriptorLike {
    uint256 internal _backgroundCount = 1;
    uint256 internal _bodyCount = 1;
    uint256 internal _accessoryCount = 1;
    uint256 internal _headCount = 1;
    uint256 internal _glassesCount = 1;

    function setBackgroundCount(uint256 n) public {
        _backgroundCount = n;
    }

    function backgroundCount() public view returns (uint256) {
        return _backgroundCount;
    }

    function setBodyCount(uint256 n) public {
        _bodyCount = n;
    }

    function bodyCount() public view returns (uint256) {
        return _bodyCount;
    }

    function setAccessoryCount(uint256 n) public {
        _accessoryCount = n;
    }

    function accessoryCount() public view returns (uint256) {
        return _accessoryCount;
    }

    function setHeadCount(uint256 n) public {
        _headCount = n;
    }

    function headCount() public view returns (uint256) {
        return _headCount;
    }

    function setGlassesCount(uint256 n) public {
        _glassesCount = n;
    }

    function glassesCount() public view returns (uint256) {
        return _glassesCount;
    }
}
