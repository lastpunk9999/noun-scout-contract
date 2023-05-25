# INounsAuctionHouseLike
[Git Source](https://github.com/lastpunk9999/noun-seek/blob/2a1069cba492fbace5a3f84c7e864724ea278be4/src/Interfaces.sol)


## Functions
### auction


```solidity
function auction() external view returns (Auction memory);
```

### settleCurrentAndCreateNewAuction


```solidity
function settleCurrentAndCreateNewAuction() external;
```

## Structs
### Auction

```solidity
struct Auction {
    uint256 nounId;
    uint256 amount;
    uint256 startTime;
    uint256 endTime;
    address payable bidder;
    bool settled;
}
```

