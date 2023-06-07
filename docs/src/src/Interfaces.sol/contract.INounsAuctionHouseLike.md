# INounsAuctionHouseLike
[Git Source](https://github.com/lastpunk9999/noun-scout-contract/blob/35d91103a3dce165da6a021dcddb4dd110704601/src/Interfaces.sol)


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

