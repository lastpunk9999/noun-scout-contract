# INounsAuctionHouseLike
[Git Source](https://github.com/lastpunk9999/noun-scout-contract/blob/4931ca85f3f8c4a5eb8112a354fc4bbc71b200a3/src/Interfaces.sol)


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

