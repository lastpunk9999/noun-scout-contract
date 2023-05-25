# NounScoutViewUtils
[Git Source](https://github.com/lastpunk9999/noun-seek/blob/2a1069cba492fbace5a3f84c7e864724ea278be4/src/NounScoutViewUtils.sol)


## State Variables
### nounScout

```solidity
NounScout public immutable nounScout;
```


### nouns

```solidity
INounsTokenLike public immutable nouns;
```


### auctionHouse

```solidity
INounsAuctionHouseLike public immutable auctionHouse;
```


### ANY_AUCTION_ID

```solidity
uint16 public immutable ANY_AUCTION_ID;
```


### UINT16_MAX

```solidity
uint16 private constant UINT16_MAX = type(uint16).max;
```


## Functions
### constructor


```solidity
constructor(NounScout _nounScout);
```

### pledgesForUpcomingNounByTrait


```solidity
function pledgesForUpcomingNounByTrait(NounScout.Traits trait)
    public
    view
    returns (
        uint16 nextAuctionId,
        uint16 nextNonAuctionId,
        uint256[][] memory nextAuctionPledges,
        uint256[][] memory nextNonAuctionPledges
    );
```

### pledgesForNounOnAuctionByTrait


```solidity
function pledgesForNounOnAuctionByTrait(NounScout.Traits trait)
    public
    view
    returns (
        uint16 currentAuctionId,
        uint16 prevNonAuctionId,
        uint256[] memory currentAuctionPledges,
        uint256[] memory prevNonAuctionPledges
    );
```

### pledgesForMatchableNounByTrait


```solidity
function pledgesForMatchableNounByTrait(NounScout.Traits trait)
    public
    view
    returns (
        uint16 auctionedNounId,
        uint16 nonAuctionedNounId,
        uint256[] memory auctionedNounPledges,
        uint256[] memory nonAuctionedNounPledges,
        uint256 totalPledges,
        uint256 reimbursement
    );
```

### requestParamsMatchNounParams

Cases for eligible matched Nouns:
Current | Eligible
Noun Id | Noun Id
--------|-------------------
101 | 99 (*skips 100)
102 | 101, 100 (*includes 100)
103 | 102
The Noun ID of the previous to the current Noun on auction
Setup a parameter to detect if a non-auctioned Noun should  be matched
If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
Example:
Current Noun: 101
Previous Noun: 100
`auctionedNounId` should be 99
Example:
Current Noun: 102
Previous Noun: 101
`nonAuctionedNounId` should be 100

Evaluate if the provided Request parameters matches the specified Noun


```solidity
function requestParamsMatchNounParams(
    NounScout.Traits requestTrait,
    uint16 requestTraitId,
    uint16 requestNounId,
    uint16 onChainNounId
) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestTrait`|`Traits.NounScout`|The trait type to compare the given Noun ID with|
|`requestTraitId`|`uint16`|The ID of the provided trait type to compare the given Noun ID with|
|`requestNounId`|`uint16`|The NounID parameter from a Noun Seek Request (may be ANY_AUCTION_ID)|
|`onChainNounId`|`uint16`|Noun ID to fetch the attributes of to compare against the given request properties|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID|


### amountForRecipientByTrait

The amount a given recipient will receive (before fees) if a Noun with specific trait parameters is minted


```solidity
function amountForRecipientByTrait(NounScout.Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId)
    public
    view
    returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits.NounScout`|The trait enum|
|`traitId`|`uint16`|The ID of the trait|
|`nounId`|`uint16`|The Noun ID|
|`recipientId`|`uint16`|The recipient ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount before fees|


### pledgeGroupIdForRecipientByTrait

The current pledge group ID for a given recipient


```solidity
function pledgeGroupIdForRecipientByTrait(NounScout.Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId)
    public
    view
    returns (uint16 pledgeGroupId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits.NounScout`|The trait enum|
|`traitId`|`uint16`|The ID of the trait|
|`nounId`|`uint16`|The Noun ID|
|`recipientId`|`uint16`|The recipient ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledgeGroupId`|`uint16`|The amount before fees|


### _isNonAuctionedNoun

Was the specified Noun ID not auctioned


```solidity
function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool);
```

### _isAuctionedNoun

Was the specified Noun ID auctioned


```solidity
function _isAuctionedNoun(uint16 nounId) internal pure returns (bool);
```

### _fetchTraitId


```solidity
function _fetchTraitId(NounScout.Traits trait, uint16 nounId) internal view returns (uint16 traitId);
```

### _mapRecipientActive

Maps array of Recipients to array of active status booleans


```solidity
function _mapRecipientActive(uint256 recipientsCount) internal view returns (bool[] memory isActive);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipientsCount`|`uint256`|Cached length of _recipients array|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isActive`|`bool[]`|Array of active status booleans|


