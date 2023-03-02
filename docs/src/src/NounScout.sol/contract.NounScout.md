# NounScout
[Git Source](https://github.com/lastpunk9999/noun-seek/blob/0cd1461637462dabb3d6ad0c144d61fa23626851/src/NounScout.sol)

**Inherits:**
Ownable2Step, Pausable


## State Variables
### nouns
Retreives historical mapping of Noun ID -> seed


```solidity
INounsTokenLike public immutable nouns;
```


### auctionHouse
Retreives the current auction data


```solidity
INounsAuctionHouseLike public immutable auctionHouse;
```


### weth
The address of the WETH contract


```solidity
IWETH public immutable weth;
```


### AUCTION_END_LIMIT
Time limit before an auction ends; requests cannot be removed during this time


```solidity
uint16 public constant AUCTION_END_LIMIT = 5 minutes;
```


### ANY_AUCTION_ID
The value of "open auctioned Noun ID" which allows trait matches to be performed against any auctioned Noun ID


```solidity
uint16 public constant ANY_AUCTION_ID = 0;
```


### ANY_NON_AUCTION_ID
The value of "open non-auctioned Noun ID" which allows trait matches to be performed against any non-auctioned Noun ID


```solidity
uint16 public constant ANY_NON_AUCTION_ID = 1;
```


### UINT16_MAX
used as `null` value for Noun ID


```solidity
uint16 private constant UINT16_MAX = type(uint16).max;
```


### baseReimbursementBPS
A portion of donated funds are sent to the address performing a match

*Owner can update*


```solidity
uint16 public baseReimbursementBPS = 250;
```


### minReimbursement
minimum reimbursement for settling

*The default attempts to cover 10 recipient matches each sent the default minimimum value (150_000 gas at 20 Gwei/gas)
Owner can update*


```solidity
uint256 public minReimbursement = 0.003 ether;
```


### maxReimbursement
maximum reimbursement for settling; with default BPS value, this is reached at 4 ETH total pledges

*Owner can update*


```solidity
uint256 public maxReimbursement = 0.1 ether;
```


### minValue
The minimum pledged value

*Owner can update*


```solidity
uint256 public minValue = 0.01 ether;
```


### messageValue
The cost to register a message

*Owner can update*


```solidity
uint256 public messageValue = 10 ether;
```


### _recipients
Array of Recipient details


```solidity
Recipient[] internal _recipients;
```


### backgroundCount
the total number of background traits

*Fetched and cached via `updateTraitCounts()`*


```solidity
uint16 public backgroundCount;
```


### bodyCount
the total number of body traits

*Fetched and cached via `updateTraitCounts()`*


```solidity
uint16 public bodyCount;
```


### accessoryCount
the total number of accessory traits

*Fetched and cached via `updateTraitCounts()`*


```solidity
uint16 public accessoryCount;
```


### headCount
the total number of head traits,

*Ftched and cached via `updateTraitCounts()`*


```solidity
uint16 public headCount;
```


### glassesCount
the total number of glasses traits

*Fetched and cached via `updateTraitCounts()`*


```solidity
uint16 public glassesCount;
```


### pledgeGroups
Cumulative funds to be sent to a specific recipient scoped to trait type, trait ID, and  Noun ID.

*The first mapping key is can be generated with the `traitsHash` function
and the second is recipientId.
`id` tracks which group of pledges have been sent. When a pledge is sent, the ID is incremented. See `_combineAmountsAndDelete()`*


```solidity
mapping(bytes32 => mapping(uint16 => PledgeGroup)) public pledgeGroups;
```


### _requests
Array of requests against the address that created the request


```solidity
mapping(address => Request[]) internal _requests;
```


## Functions
### constructor


```solidity
constructor(INounsTokenLike _nouns, INounsAuctionHouseLike _auctionHouse, IWETH _weth);
```

### recipients

All recipients as Recipient structs


```solidity
function recipients() public view returns (Recipient[] memory);
```

### requestsByAddress

Get requests, augemented with status, for non-removed Requests

*Removes Requests marked as REMOVED, and includes Requests that have been previously matched.
Do not rely on array index; use `request.id` to specify a Request when calling `remove()`
See { _getRequestStatusAndParams } for calculations*


```solidity
function requestsByAddress(address requester) public view returns (RequestWithStatus[] memory requests);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requester`|`address`|The address of the requester|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`RequestWithStatus[]`|An array of RequestWithStatus Structs|


### traitHash

The canonical key for requests that target the same `trait`, `traitId`, and `nounId`

*Used to group requests by their parameters in the `amounts` mapping*


```solidity
function traitHash(Traits trait, uint16 traitId, uint16 nounId) public pure returns (bytes32 hash);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|The trait enum|
|`traitId`|`uint16`|The ID of the trait|
|`nounId`|`uint16`|The Noun ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`hash`|`bytes32`|The hashed value|


### effectiveBPSAndReimbursementForPledgeTotal

Given a pledge total, derive the reimbursement fee and basis points used to calculate it


```solidity
function effectiveBPSAndReimbursementForPledgeTotal(uint256 total)
    public
    view
    returns (uint256 effectiveBPS, uint256 reimbursement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`total`|`uint256`|A pledge amount|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`effectiveBPS`|`uint256`|The basis point used to cacluate the reimbursement fee|
|`reimbursement`|`uint256`|The reimbursement amount|


### requestMatchesNoun

Evaluate if the provided Request matches the specified on-chain Noun


```solidity
function requestMatchesNoun(Request memory request, uint16 nounId) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`request`|`Request`|The Request to compare|
|`nounId`|`uint16`|Noun ID to fetch the seed and compare against the given request parameters|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|boolean True if the specified Noun has the specified trait and the request Noun ID matches the given Noun ID|


### pledgesForNounId

For a given Noun ID, get cumulative pledge amounts for each Recipient scoped by Trait Type and Trait ID.

*The pledges array is a nested structure of 3 arrays of Trait Type, Trait ID, and Recipient ID.
The length of the first array is 5 (five) representing all Trait Types.
The length of the second is dependant on the number of traits for that trait type (e.g. 242 for Trait Type 3 aka heads).
The length of the third is dependant on the number of recipients added to this contract.
Example lengths:
- `pledges[0].length` == 2 representing the two traits possible for a background `cool` (Trait ID 0) and `warm` (Trait ID 1)
- `pledges[0][0].length` == the size of the number of recipients that have been added to this contract. Each value is the amount that has been pledged to a specific recipient, indexed by its ID, if a Noun is minted with a cool background.
Calling `pledgesForNounId(101) returns cumulative matching pledges for each Trait Type, Trait ID and Recipient ID such that:`
- the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)
- the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)*


```solidity
function pledgesForNounId(uint16 nounId, bool includeAnyId) public view returns (uint256[][][5] memory pledges);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nounId`|`uint16`|The ID of the Noun requests should match.|
|`includeAnyId`|`bool`|If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledges`|`uint256[][][5]`|Cumulative amounts pledged for each Recipient, indexed by Trait Type, Trait ID and Recipient ID|


### pledgesForNounIdByTrait

Get cumulative pledge amounts scoped to Noun ID and Trait Type.

*Example: `pledgesForNounIdByTrait(3, 25)` accumulates all pledged pledges amounts for heads and Noun ID 25.
The returned value in `pledges[5][2]` is in the total amount that has been pledged to Recipient ID 2 if Noun ID 25 is minted with a head of Trait ID 5*


```solidity
function pledgesForNounIdByTrait(Traits trait, uint16 nounId, bool includeAnyId)
    public
    view
    returns (uint256[][] memory pledgesByTraitId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|The trait type to scope requests to (See `Traits` Enum)|
|`nounId`|`uint16`|The Noun ID to scope requests to|
|`includeAnyId`|`bool`|If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledgesByTraitId`|`uint256[][]`|Cumulative amounts pledged for each Recipient, indexed by Trait ID and Recipient ID|


### pledgesForNounIdByTraitId

Get cumulative pledge amounts scoped to Noun ID, Trait Type, and Trait ID

*Example: `pledgesForNounIdByTraitId(0, 1, 25)` accumulates all pledged pledge amounts for background (Trait Type 0) with Trait ID 1 for Noun ID 25. The value in `pledges[2]` is in the total amount that has been pledged to Recipient ID 2*


```solidity
function pledgesForNounIdByTraitId(Traits trait, uint16 traitId, uint16 nounId, bool includeAnyId)
    public
    view
    returns (uint256[] memory pledges);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|The trait type to scope requests to (See `Traits` Enum)|
|`traitId`|`uint16`|The trait ID  of the trait to scope requests|
|`nounId`|`uint16`|The Noun ID to scope requests to|
|`includeAnyId`|`bool`|If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledges`|`uint256[]`|Cumulative amounts pledged for each Recipient, indexed by Recipient ID|


### pledgesForOnChainNoun

For an existing on-chain Noun, use its seed to find matching pledges

*Example: `noun.seeds(1)` returns a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
Calling `pledgesForOnChainNoun(1)` returns cumulative matching pledges for each trait that matches the seed such that:
- `pledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 for Noun ID 1. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2*


```solidity
function pledgesForOnChainNoun(uint16 nounId, bool includeAnyId) public view returns (uint256[][5] memory pledges);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nounId`|`uint16`|Noun ID of an existing on-chain Noun|
|`includeAnyId`|`bool`|If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledges`|`uint256[][5]`|Cumulative amounts pledged for each Recipient that matches the on-chain Noun seed indexed by Trait Type and Recipient ID|


### pledgesForUpcomingNoun

Use the next auctioned Noun Id (and non-auctioned Noun Id that may be minted in the same block) to get cumulative pledge amounts for each Recipient scoped by possible Trait Type and Trait ID. Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.

*See { pledgesForNounId } for detailed documentation of the nested array structure*


```solidity
function pledgesForUpcomingNoun()
    public
    view
    returns (
        uint16 nextAuctionId,
        uint16 nextNonAuctionId,
        uint256[][][5] memory nextAuctionPledges,
        uint256[][][5] memory nextNonAuctionPledges
    );
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nextAuctionId`|`uint16`|The ID of the next Noun that will be auctioned|
|`nextNonAuctionId`|`uint16`|If two Nouns are due to be minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)|
|`nextAuctionPledges`|`uint256[][][5]`|Total pledges for the next auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID|
|`nextNonAuctionPledges`|`uint256[][][5]`|If two Nouns are due to be minted, this will contain the total pledges for the next non-auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID|


### pledgesForNounOnAuction

For the Noun that is currently on auction (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts pledged for each Recipient using requests that match the Noun's seed.  Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.

*Example: The Noun on auction has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
Calling `pledgesForNounOnAuction()` returns cumulative matching pledges for each trait that matches the seed such that:
- `currentAuctionPledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2.
If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `prevNonAuctionPledges` would be populated*


```solidity
function pledgesForNounOnAuction()
    public
    view
    returns (
        uint16 currentAuctionId,
        uint16 prevNonAuctionId,
        uint256[][5] memory currentAuctionPledges,
        uint256[][5] memory prevNonAuctionPledges
    );
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentAuctionId`|`uint16`|The ID of the Noun that is currently being auctioned|
|`prevNonAuctionId`|`uint16`|If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)|
|`currentAuctionPledges`|`uint256[][5]`|Total pledges for the current auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID|
|`prevNonAuctionPledges`|`uint256[][5]`|If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID|


### pledgesForMatchableNoun

For the Noun that is eligible to be settled (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts for each Recipient using requests that match the Noun's seed. Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.

*Example:
- The Noun that is eligible to match has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
- Calling `pledgesForMatchableNoun()` returns cumulative matching pledges for each trait that matches the seed.
- `auctionedNounPledges[0]` returns the cumulative donations amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2.
- If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `nonAuctionedNounPledges` would be populated
- Cases for eligible matched Nouns:
- `Current Noun ID | Eligible Noun ID`
- `----------------|-------------------`
- `            101 | 99 (*skips 100)`
- `            102 | 101, 100 (*includes 100)`
- `            103 | 102`*


```solidity
function pledgesForMatchableNoun()
    public
    view
    returns (
        uint16 auctionedNounId,
        uint16 nonAuctionedNounId,
        uint256[][5] memory auctionedNounPledges,
        uint256[][5] memory nonAuctionedNounPledges,
        uint256[5] memory auctionNounTotalReimbursement,
        uint256[5] memory nonAuctionNounTotalReimbursement
    );
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`auctionedNounId`|`uint16`|The ID of the Noun that is was auctioned|
|`nonAuctionedNounId`|`uint16`|If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)|
|`auctionedNounPledges`|`uint256[][5]`|Total pledges for the eligible auctioned Noun as a nested arrays in the order Trait Type and Recipient ID|
|`nonAuctionedNounPledges`|`uint256[][5]`|If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays in the order Trait Type and Recipient ID|
|`auctionNounTotalReimbursement`|`uint256[5]`|An array of settler's reimbursement that will be sent if a Trait Type is matched to the auctioned Noun, indexed by Trait Type|
|`nonAuctionNounTotalReimbursement`|`uint256[5]`|An array of settler's reimbursement that will be sent if a Trait Type is matched to the non-auctioned Noun, indexed by Trait Type|


### rawRequestsByAddress

The Noun ID of the previous to the current Noun on auction
Setup a parameter to detect if a non-auctioned Noun should be matched
If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
Example:
Current Noun: 101
Previous Noun: 100
`auctionedNounId` should be 99
Example:
Current Noun: 102
Previous Noun: 101
`nonAuctionedNounId` should be 100

Get all raw Requests (without status, includes deleted Requests)

*Exists for low-level queries. The function { requestsByAddress } is better in most use-cases*


```solidity
function rawRequestsByAddress(address requester) public view returns (Request[] memory requests);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requester`|`address`|The address of the requester|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`Request[]`|An array of Request structs|


### rawRequestById

Get a specific raw Request (without status, includes deleted Requests)

*Exists for low-level queries. The function { requestsByAddress } is better in most use-cases*


```solidity
function rawRequestById(address requester, uint256 requestId) public view returns (Request memory request);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requester`|`address`||
|`requestId`|`uint256`|The ID of the request|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`request`|`Request`|The Request struct|


### add

Create a request for the specific trait and specific or open Noun ID payable to the specified Recipient.

*`msg.value` is used as the pledged Request amount*


```solidity
function add(Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId)
    public
    payable
    whenNotPaused
    returns (uint256 requestId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|Trait Type the request is for (see `Traits` Enum)|
|`traitId`|`uint16`|ID of the specified Trait that the request is for|
|`nounId`|`uint16`|the Noun ID the request is targeted for. Can be (1) any specific Noun ID, (2) the value of `ANY_AUCTION_ID` if the pledge can target any auctioned Noun, or (3) the value of `ANY_NON_AUCTION_ID` if the pledge can target any non-auctioned Noun|
|`recipientId`|`uint16`|the ID of the Recipient that should receive the pledged amount if a Noun matching the parameters is minted|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|The ID of this requests for msg.sender's address|


### addWithMessage

Create a request with a logged message for the specific trait and specific or open Noun ID payable to the specified Recipient. `messageValue` is sent immediately to the recipient and cannot be refunded.

*The message cost is subtracted from `msg.value` and transfered immediately to the specified Recipient.
The remaining value is stored as the pledged Request amount.*


```solidity
function addWithMessage(Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId, string memory message)
    public
    payable
    whenNotPaused
    returns (uint256 requestId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|Trait Type the request is for (see `Traits` Enum)|
|`traitId`|`uint16`|ID of the specified Trait that the request is for|
|`nounId`|`uint16`|the Noun ID the request is targeted for. Can be (1) any specific Noun ID, (2) the value of `ANY_AUCTION_ID` if the pledge can target any auctioned Noun, or (3) the value of `ANY_NON_AUCTION_ID` if the pledge can target any non-auctioned Noun|
|`recipientId`|`uint16`|the ID of the Recipient that should receive the pledge if a Noun matching the parameters is minted|
|`message`|`string`|The message to log|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|The ID of this requests for msg.sender's address|


### remove

Remove the specified request and return the associated amount.

*Must be called by the Requester's address.
If the Request has already been settled/donation was sent to the Recipient or the current auction is ending soon, this will revert (See { _getRequestStatusAndParams } for calculations)
If the Recipient of the Request is marked as inactive, the funds can be returned immediately*


```solidity
function remove(uint256 requestId) public returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|Request Id|


### settle

Sends pledged amounts to recipients by matching a requested trait to an eligible Noun. A portion of the pledged amount is sent to `msg.sender` to offset the gas costs of settling.

*
- Only eligible Noun Ids are accepted. An eligible Noun Id is for the immediately preceeding auctioned Noun, or non-auctioned Noun if it was minted at the same time.
- Specifying a Noun Id for an auctioned Noun will match requests for `ANY_AUCTION_ID` in addition to requests for `nounId`.
- Specifying a Noun Id for a non-auctioned Noun will match requests for `ANY_NON_AUCTION_ID` in addition to requests for `nounId`.
- Cases for eligible matched Nouns:
- `Current Noun ID | Eligible Noun ID`
- `----------------|-------------------`
- `            101 | 99 (*skips 100), ANY_AUCTION_ID`
- `            102 | 101, 100 (*includes 100),  ANY_AUCTION_ID, ANY_NON_AUCTION_ID`
- `            103 | 102, ANY_AUCTION_ID`*


```solidity
function settle(Traits trait, bool matchAuctionedNoun, uint16[] memory recipientIds)
    public
    whenNotPaused
    returns (uint256 total, uint256 reimbursement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|The Trait Type to fetch from an eligible Noun (see `Traits` Enum)|
|`matchAuctionedNoun`|`bool`|If `true` fetch the trait from the previous auctioned Noun. If `false` fetch the trait from the previous non-auctioned Noun.|
|`recipientIds`|`uint16[]`|An array of recipient IDs that have been pledged an amount if a Noun matches the specified trait.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`total`|`uint256`|Total donated funds before reimbursement|
|`reimbursement`|`uint256`|Reimbursement amount|


### updateTraitCounts

The Noun ID of the previous to the current Noun on auction
If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
Example:
Current Noun on Auction: 101
`nounId`: 100
`nounId` should be 99
If the previous Noun is non-auctioned, it's ineligible because it was minted at the same time as the current Noun
Example:
Current Noun on Auction: 101
`nounId`: 100
Get the previous, previous Noun ID
If this Noun is auctioned, then there is no non-auctioned Noun that can be matched.

Update local Trait counts based on Noun Descriptor totals


```solidity
function updateTraitCounts() public;
```

### addRecipient

Add a Recipient by specifying the name and address funds should be sent to

*Adds a Recipient to the recipients set and activates the Recipient*


```solidity
function addRecipient(string calldata name, address to, string calldata description) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|The Recipient's name that should be displayed to users/consumers|
|`to`|`address`|Address that funds should be sent to in order to fund the Recipient|
|`description`|`string`||


### setRecipientActive

Toggles a Recipient's active state by its index within the set, reverts if Recipient is not configured

*If the Done is not configured, a revert will be triggered*


```solidity
function setRecipientActive(uint256 recipientId, bool active) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipientId`|`uint256`|Recipient id based on its index within the recipients set|
|`active`|`bool`|Active state|


### setMinValue

Sets the minium value that can be pledged


```solidity
function setMinValue(uint256 newMinValue) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMinValue`|`uint256`|new minimum value|


### setMessageValue

Sets the cost of registering a message


```solidity
function setMessageValue(uint256 newMessageValue) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMessageValue`|`uint256`|new message cost|


### setReimbursementBPS

Sets the standard reimbursement basis points


```solidity
function setReimbursementBPS(uint16 newReimbursementBPS) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newReimbursementBPS`|`uint16`|new basis point value|


### setMinReimbursement

BPS cannot be less than 0.1% or greater than 10%

Sets the minium reimbursement amount when settling


```solidity
function setMinReimbursement(uint256 newMinReimbursement) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMinReimbursement`|`uint256`|new minimum value|


### setMaxReimbursement

Sets the maximum reimbursement amount when settling


```solidity
function setMaxReimbursement(uint256 newMaxReimbursement) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMaxReimbursement`|`uint256`|new maximum value|


### pause

Pauses the NounScout contract. Pausing can be reversed by unpausing.


```solidity
function pause() external onlyOwner;
```

### unpause

Unpauses (resumes) the NounScout contract. Unpausing can be reversed by pausing.


```solidity
function unpause() external onlyOwner;
```

### _add

Creates a Request

*logs `RequestAdded`*


```solidity
function _add(Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId, uint256 amount, string memory message)
    internal
    returns (uint256 requestId);
```

### _remove

Deletes a Request

*Sends funds
Logs `RequestRemoved`*


```solidity
function _remove(Request memory request, uint256 requestId, bytes32 hash) internal returns (uint256 amount);
```

### _combineAmountsAndDelete

Retrieves requests with params `trait`, `traitId`, and `nounId` to calculate pledge and reimubersement amounts, sets a new PledgeGroup record with amount set to 0 and pledgeGroupId increased by 1.


```solidity
function _combineAmountsAndDelete(
    Traits trait,
    uint16 traitId,
    uint16 nounId,
    uint16[] memory recipientIds,
    bool matchAuctionedNoun
) internal returns (uint256[] memory pledges, uint256 total);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trait`|`Traits`|The trait type requests should match (see `Traits` Enum)|
|`traitId`|`uint16`|Specific trait ID|
|`nounId`|`uint16`|Specific Noun ID|
|`recipientIds`|`uint16[]`|Specific set of recipients|
|`matchAuctionedNoun`|`bool`|If `true` matching Noun is auctioned. If `false` matching Noun is non-auctioned.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pledges`|`uint256[]`|Mutated pledges array|
|`total`|`uint256`|total|


### _pledgesForNounIdByTraitId

Get cumulative pledge amounts for each Recipient scoped by Noun Id, Trait Type, and Trait Id


```solidity
function _pledgesForNounIdByTraitId(
    Traits trait,
    uint16 traitId,
    uint16 nounId,
    bool includeAnyId,
    uint256 recipientsCount
) internal view returns (uint256[] memory pledges);
```

### _pledgesForOnChainNoun

For an on-chain Noun, get cumulative pledge amounts that would match its seed


```solidity
function _pledgesForOnChainNoun(uint16 nounId, bool includeAnyId, uint256 recipientsCount)
    internal
    view
    returns (uint256[][5] memory pledges);
```

### _getRequestStatusAndParams

Generates a RequestStatus based on state of the Request, match data, and auction data

*RequestStatus calculations:
- REMOVED: the request amount is 0
- PLEDGE_SENT: A Noun was minted with the Request parameters and has been matched
- AUCTION_ENDING_SOON: The auction end time falls within the AUCTION_END_LIMIT
- MATCH_FOUND: The current or previous Noun matches the Request parameters
- MATCH_FOUND Case 1) The current Noun on auction has the requested traits
- MATCH_FOUND Case 2) The previous Noun has the requested traits
- MATCH_FOUND Case 2b) If the previous Noun is non-auctioned, the previous previous has the requested traits
- MATCH_FOUND: Case 3) A Non-Auctioned Noun which matches the request.nounId is the previous previous Noun
```
Case # | Example Noun ID | Ineligible Noun ID
-------|---------|-------------------
1,3 |     101 | 101, 99 (*skips 100)
1,2,2b|     102 | 102, 101, 100 (*includes 100)
1,2 |     103 | 103, 102
```
- CAN_REMOVE: Recipient is inactive and Request has not been matched
- OR Request has not been matched and auction is not ending
- OR Request has not been matched, auction is not ending, and the current or prevous Noun does not match the Request parameters
//*


```solidity
function _getRequestStatusAndParams(Request memory request)
    internal
    view
    returns (RequestStatus requestStatus, bytes32 hash, uint16 nounId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`request`|`Request`|Request to analyze|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestStatus`|`RequestStatus`|RequestStatus Enum|
|`hash`|`bytes32`|generated trait hash to minimize gas ussage|
|`nounId`|`uint16`|nounId|


### _isNonAuctionedNoun

Is the specified Noun ID not eligible to be auctioned


```solidity
function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool);
```

### _isAuctionedNoun

Is the specified Noun ID eligible to be auctioned


```solidity
function _isAuctionedNoun(uint16 nounId) internal pure returns (bool);
```

### _fetchOnChainNounTraitId

Get the specified on-chain Noun's seed and return the Trait ID for a Trait Type


```solidity
function _fetchOnChainNounTraitId(Traits trait, uint16 nounId) internal view returns (uint16 traitId);
```

### _effectiveHighPrecisionBPSForPledgeTotal

Calculate the reimbursement amount and the basis point value for a total, bound to the maximum and minimum reimbursement amount.

*Use the `baseReimbursementBPS` to calculate a reimbursement amount.
If the amount is above the maximum reimbursement allowed, or below the minimum reimbursement allowed,
set the the reimbursement amount to the max or min, and calculate the required basis point value to achieve the reimbursement*


```solidity
function _effectiveHighPrecisionBPSForPledgeTotal(uint256 total)
    internal
    view
    returns (uint256 effectiveBPS, uint256 reimbursement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`total`|`uint256`|The total amount reimbursement should be based on|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`effectiveBPS`|`uint256`|The basis point value used to calculate the reimbursement given the total|
|`reimbursement`|`uint256`|The amount to reimburse based on the total and effectiveBPS|


### _mapRecipientActive

Add 2 digits extra precision to better derive `effectiveBPS` from total
Extra precision basis point = 10_000 * 100 = 1_000_000

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


### _safeTransferETHWithFallback

Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.


```solidity
function _safeTransferETHWithFallback(address to, uint256 amount) internal;
```

### _safeTransferETH

Transfer ETH and return the success status.

*This function forwards 10,000 gas to the callee.*


```solidity
function _safeTransferETH(address to, uint256 value) internal returns (bool);
```

## Events
### RequestAdded
Emitted when a Request is added


```solidity
event RequestAdded(
    uint256 requestId,
    address indexed requester,
    Traits trait,
    uint16 traitId,
    uint16 recipientId,
    uint16 indexed nounId,
    uint16 pledgeGroupId,
    bytes32 indexed traitsHash,
    uint256 amount,
    string message
);
```

### RequestRemoved
Emitted when a Request is removed


```solidity
event RequestRemoved(
    uint256 requestId,
    address indexed requester,
    Traits trait,
    uint16 traitId,
    uint16 indexed nounId,
    uint16 pledgeGroupId,
    uint16 recipientId,
    bytes32 indexed traitsHash,
    uint256 amount
);
```

### RecipientAdded
Emitted when a Recipient is added


```solidity
event RecipientAdded(uint256 recipientId, string name, address to, string description);
```

### RecipientActiveStatusChanged
Emitted when a Recipient status has changed


```solidity
event RecipientActiveStatusChanged(uint256 recipientId, bool active);
```

### Matched
Emitted when an eligible Noun matches one or more Requests

*Used to update and/or invalidate Requests stored off-chain for these parameters*


```solidity
event Matched(Traits indexed trait, uint16 traitId, uint16 indexed nounId, bytes32 indexed traitsHash);
```

### Donated
Emitted when an eligible Noun matches one or more Requests


```solidity
event Donated(uint256[] donations);
```

### Reimbursed
Emitted when an eligible Noun matches one or more Requests


```solidity
event Reimbursed(address indexed settler, uint256 amount);
```

### MinValueChanged
Emitted when the minValue changes


```solidity
event MinValueChanged(uint256 newMinValue);
```

### MessageValueChanged
Emitted when the messageValue changes


```solidity
event MessageValueChanged(uint256 newMessageValue);
```

### ReimbursementBPSChanged
Emitted when the baseReimbursementBPS changes


```solidity
event ReimbursementBPSChanged(uint256 newReimbursementBPS);
```

### MinReimbursementChanged
Emitted when the minReimbursement changes


```solidity
event MinReimbursementChanged(uint256 newMinReimbursement);
```

### MaxReimbursementChanged
Emitted when the maxReimbursement changes


```solidity
event MaxReimbursementChanged(uint256 newMaxReimbursement);
```

## Errors
### AuctionEndingSoon
Thrown when an attempting to remove a Request within `AUCTION_END_LIMIT` (5 minutes) of auction end.


```solidity
error AuctionEndingSoon();
```

### MatchFound
Thrown when an attempting to remove a Request that matches the current or previous Noun


```solidity
error MatchFound(uint16 nounId);
```

### PledgeSent
Thrown when an attempting to remove a Request that was previously matched (donation was sent)


```solidity
error PledgeSent();
```

### AlreadyRemoved
Thrown when attempting to remove a Request that was previously removed.


```solidity
error AlreadyRemoved();
```

### NoMatch
Thrown when attempting to settle the eligible Noun that has no matching Requests for the specified Trait Type and Trait ID


```solidity
error NoMatch();
```

### IneligibleNounId
Thrown when attempting to match an eligible Noun. Can only match a Noun previous to the current on auction


```solidity
error IneligibleNounId();
```

### InactiveRecipient
Thrown when an attempting to add a Request that pledges an amount to an inactive Recipient


```solidity
error InactiveRecipient();
```

### ValueTooLow
Thrown when an attempting to add a Request with value below `minValue`


```solidity
error ValueTooLow();
```

## Structs
### Request
Stores pledged value, requested traits, pledge target


```solidity
struct Request {
    Traits trait;
    uint16 traitId;
    uint16 recipientId;
    uint16 nounId;
    uint16 pledgeGroupId;
    uint128 amount;
}
```

### RequestWithStatus
Request with additional `id` and `status` parameters; Returned by `requestsByAddress()`


```solidity
struct RequestWithStatus {
    uint256 id;
    Traits trait;
    uint16 traitId;
    uint16 recipientId;
    uint16 nounId;
    uint128 amount;
    RequestStatus status;
}
```

### PledgeGroup
Used to track cumlitive amounts for a recipient . `id` is incremented when pledged amounts are sent; See `pledgeGroups` variable and `_combineAmountsAndDelete` function


```solidity
struct PledgeGroup {
    uint240 amount;
    uint16 id;
}
```

### Recipient
Name, address, and active status where funds can be donated


```solidity
struct Recipient {
    string name;
    address to;
    bool active;
}
```

## Enums
### Traits
Noun traits in the order they appear on the NounSeeder.Seed struct


```solidity
enum Traits {
    BACKGROUND,
    BODY,
    ACCESSORY,
    HEAD,
    GLASSES
}
```

### RequestStatus
Removal status types for a Request

*See { _getRequestStatusAndParams } for calculations
A Request can only be removed if `status == CAN_REMOVE`*


```solidity
enum RequestStatus {
    CAN_REMOVE,
    REMOVED,
    PLEDGE_SENT,
    AUCTION_ENDING_SOON,
    MATCH_FOUND
}
```

