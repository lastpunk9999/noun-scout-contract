---
description:
---

# NounScout.sol

## Methods

### _ANY_ID_

```solidity title="Solidity"
function ANY_ID() external view returns (uint16)
```

The value of "open Noun ID" which allows trait matches to be performed against any Noun ID except non-auctioned Nouns

#### Returns

| Name | Type   | Description     |
| ---- | ------ | --------------- |
| \_0  | uint16 | Set to zero (0) |

---

### _AUCTION_END_LIMIT_

```solidity title="Solidity"
function AUCTION_END_LIMIT() external view returns (uint16)
```

Time limit before an auction ends; requests cannot be removed during this time

#### Returns

| Name | Type   | Description      |
| ---- | ------ | ---------------- |
| \_0  | uint16 | Set to 5 minutes |

---

### _acceptOwnership_

```solidity title="Solidity"
function acceptOwnership() external nonpayable
```

##### Details

> The new owner accepts the ownership transfer.

---

### _accessoryCount_

```solidity title="Solidity"
function accessoryCount() external view returns (uint16)
```

the total number of accessory traits

##### Details

> Fetched and cached via `updateTraitCounts()`

#### Returns

| Name | Type   | Description    |
| ---- | ------ | -------------- |
| \_0  | uint16 | accessoryCount |

---

### _add_

```solidity title="Solidity"
function add(enum NounScout.Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId) external payable returns (uint256 requestId)
```

Create a request for the specific trait and specific or open Noun ID payable to the specified Recipient.

##### Details

> `msg.value` is used as the pledged Request amount

#### Parameters

| Name        | Type                  | Description                                                                                                |
| ----------- | --------------------- | ---------------------------------------------------------------------------------------------------------- |
| trait       | enum NounScout.Traits | Trait Type the request is for (see `Traits` Enum)                                                          |
| traitId     | uint16                | ID of the specified Trait that the request is for                                                          |
| nounId      | uint16                | the Noun ID the request is targeted for (or the value of ANY_ID for open requests)                         |
| recipientId | uint16                | the ID of the Recipient that should receive the pledged amount if a Noun matching the parameters is minted |

#### Returns

| Name      | Type    | Description                                      |
| --------- | ------- | ------------------------------------------------ |
| requestId | uint256 | The ID of this requests for msg.sender's address |

---

### _addRecipient_

```solidity title="Solidity"
function addRecipient(string name, address to, string description) external nonpayable
```

Add a Recipient by specifying the name and address funds should be sent to

##### Details

> Adds a Recipient to the recipients set and activates the Recipient

#### Parameters

| Name        | Type    | Description                                                         |
| ----------- | ------- | ------------------------------------------------------------------- |
| name        | string  | The Recipient's name that should be displayed to users/consumers    |
| to          | address | Address that funds should be sent to in order to fund the Recipient |
| description | string  | Description of the recipient                                        |

---

### _addWithMessage_

```solidity title="Solidity"
function addWithMessage(enum NounScout.Traits trait, uint16 traitId, uint16 nounId, uint16 recipientId, string message) external payable returns (uint256 requestId)
```

Create a request with a logged message for the specific trait and specific or open Noun ID payable to the specified Recipient.

##### Details

> The message cost is subtracted from `msg.value` and transfered immediately to the specified Recipient. The remaining value is stored as the pledged Request amount.

#### Parameters

| Name        | Type                  | Description                                                                                        |
| ----------- | --------------------- | -------------------------------------------------------------------------------------------------- |
| trait       | enum NounScout.Traits | Trait Type the request is for (see `Traits` Enum)                                                  |
| traitId     | uint16                | ID of the specified Trait that the request is for                                                  |
| nounId      | uint16                | the Noun ID the request is targeted for (or the value of ANY_ID for open requests)                 |
| recipientId | uint16                | the ID of the Recipient that should receive the pledge if a Noun matching the parameters is minted |
| message     | string                | The message to log                                                                                 |

#### Returns

| Name      | Type    | Description                                      |
| --------- | ------- | ------------------------------------------------ |
| requestId | uint256 | The ID of this requests for msg.sender's address |

---

### _auctionHouse_

```solidity title="Solidity"
function auctionHouse() external view returns (contract INounsAuctionHouseLike)
```

Retreives the current auction data

#### Returns

| Name | Type                            | Description                   |
| ---- | ------------------------------- | ----------------------------- |
| \_0  | contract INounsAuctionHouseLike | auctionHouse contract address |

---

### _backgroundCount_

```solidity title="Solidity"
function backgroundCount() external view returns (uint16)
```

the total number of background traits

##### Details

> Fetched and cached via `updateTraitCounts()`

#### Returns

| Name | Type   | Description     |
| ---- | ------ | --------------- |
| \_0  | uint16 | backgroundCount |

---

### _baseReimbursementBPS_

```solidity title="Solidity"
function baseReimbursementBPS() external view returns (uint16)
```

A portion of donated funds are sent to the address performing a match

##### Details

> Owner can update

#### Returns

| Name | Type   | Description          |
| ---- | ------ | -------------------- |
| \_0  | uint16 | baseReimbursementBPS |

---

### _bodyCount_

```solidity title="Solidity"
function bodyCount() external view returns (uint16)
```

the total number of body traits

##### Details

> Fetched and cached via `updateTraitCounts()`

#### Returns

| Name | Type   | Description |
| ---- | ------ | ----------- |
| \_0  | uint16 | bodyCount   |

---

### _effectiveBPSAndReimbursementForPledgeTotal_

```solidity title="Solidity"
function effectiveBPSAndReimbursementForPledgeTotal(uint256 total) external view returns (uint256 effectiveBPS, uint256 reimbursement)
```

Given a pledge total, derive the reimbursement fee and basis points used to calculate it

#### Parameters

| Name  | Type    | Description     |
| ----- | ------- | --------------- |
| total | uint256 | A pledge amount |

#### Returns

| Name          | Type    | Description                                            |
| ------------- | ------- | ------------------------------------------------------ |
| effectiveBPS  | uint256 | The basis point used to cacluate the reimbursement fee |
| reimbursement | uint256 | The reimbursement amount                               |

---

### _glassesCount_

```solidity title="Solidity"
function glassesCount() external view returns (uint16)
```

the total number of glasses traits

##### Details

> Fetched and cached via `updateTraitCounts()`

#### Returns

| Name | Type   | Description  |
| ---- | ------ | ------------ |
| \_0  | uint16 | glassesCount |

---

### _headCount_

```solidity title="Solidity"
function headCount() external view returns (uint16)
```

the total number of head traits,

##### Details

> Ftched and cached via `updateTraitCounts()`

#### Returns

| Name | Type   | Description |
| ---- | ------ | ----------- |
| \_0  | uint16 | headCount   |

---

### _maxReimbursement_

```solidity title="Solidity"
function maxReimbursement() external view returns (uint256)
```

maximum reimbursement for settling; with default BPS value, this is reached at 4 ETH total pledges

##### Details

> Owner can update

#### Returns

| Name | Type    | Description      |
| ---- | ------- | ---------------- |
| \_0  | uint256 | maxReimbursement |

---

### _messageValue_

```solidity title="Solidity"
function messageValue() external view returns (uint256)
```

The cost to register a message

##### Details

> Owner can update

#### Returns

| Name | Type    | Description  |
| ---- | ------- | ------------ |
| \_0  | uint256 | messageValue |

---

### _minReimbursement_

```solidity title="Solidity"
function minReimbursement() external view returns (uint256)
```

minimum reimbursement for settling

##### Details

> The default attempts to cover 10 recipient matches each sent the default minimimum value (150_000 gas at 20 Gwei/gas) Owner can update

#### Returns

| Name | Type    | Description      |
| ---- | ------- | ---------------- |
| \_0  | uint256 | minReimbursement |

---

### _minValue_

```solidity title="Solidity"
function minValue() external view returns (uint256)
```

The minimum pledged value

##### Details

> Owner can update

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | minValue    |

---

### _nouns_

```solidity title="Solidity"
function nouns() external view returns (contract INounsTokenLike)
```

Retreives historical mapping of Noun ID -&gt; seed

#### Returns

| Name | Type                     | Description            |
| ---- | ------------------------ | ---------------------- |
| \_0  | contract INounsTokenLike | nouns contract address |

---

### _owner_

```solidity title="Solidity"
function owner() external view returns (address)
```

##### Details

> Returns the address of the current owner.

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

---

### _pause_

```solidity title="Solidity"
function pause() external nonpayable
```

Pauses the NounScout contract. Pausing can be reversed by unpausing.

---

### _paused_

```solidity title="Solidity"
function paused() external view returns (bool)
```

##### Details

> Returns true if the contract is paused, and false otherwise.

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

---

### _pendingOwner_

```solidity title="Solidity"
function pendingOwner() external view returns (address)
```

##### Details

> Returns the address of the pending owner.

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

---

### _pledgeGroups_

```solidity title="Solidity"
function pledgeGroups(bytes32, uint16) external view returns (uint240 amount, uint16 id)
```

Cumulative funds to be sent to a specific recipient scoped to trait type, trait ID, and Noun ID.

##### Details

> The first mapping key is can be generated with the `traitsHash` function and the second is recipientId. `id` tracks which group of pledges have been sent. When a pledge is sent, the ID is incremented. See `_combineAmountsAndDelete()`

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | bytes32 | undefined   |
| \_1  | uint16  | undefined   |

#### Returns

| Name   | Type    | Description |
| ------ | ------- | ----------- |
| amount | uint240 | undefined   |
| id     | uint16  | undefined   |

---

### _pledgesForMatchableNoun_

```solidity title="Solidity"
function pledgesForMatchableNoun() external view returns (uint16 auctionedNounId, uint16 nonAuctionedNounId, uint256[][5] auctionedNounPledges, uint256[][5] nonAuctionedNounPledges, uint256[5] auctionNounTotalReimbursement, uint256[5] nonAuctionNounTotalReimbursement)
```

For the Noun that is eligible to be matched with pledged pledges (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts for each Recipient using requests that match the Noun's seed.

##### Details

> Example: The Noun that is eligible to match has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `pledgesForMatchableNoun()` returns cumulative matching pledges for each trait that matches the seed. `auctionedNounPledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2. If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `nonAuctionedNounPledges` would be populated See the documentation in the function body for the cases used to match eligible Nouns

#### Returns

| Name                             | Type         | Description                                                                                                                                                   |
| -------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| auctionedNounId                  | uint16       | The ID of the Noun that is was auctioned                                                                                                                      |
| nonAuctionedNounId               | uint16       | If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)                                                        |
| auctionedNounPledges             | uint256[][5] | Total pledges for the eligible auctioned Noun as a nested arrays in the order Trait Type and Recipient ID                                                     |
| nonAuctionedNounPledges          | uint256[][5] | If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays in the order Trait Type and Recipient ID |
| auctionNounTotalReimbursement    | uint256[5]   | An array of settler's reimbursement that will be sent if a Trait Type is matched to the auctioned Noun, indexed by Trait Type                                 |
| nonAuctionNounTotalReimbursement | uint256[5]   | An array of settler's reimbursement that will be sent if a Trait Type is matched to the non-auctioned Noun, indexed by Trait Type                             |

---

### _pledgesForNounId_

```solidity title="Solidity"
function pledgesForNounId(uint16 nounId) external view returns (uint256[][][5] pledges)
```

For a given Noun ID, get cumulative pledge amounts for each Recipient scoped by Trait Type and Trait ID.

##### Details

> The pledges array is a nested structure of 3 arrays of Trait Type, Trait ID, and Recipient ID. The length of the first array is 5 (five) representing all Trait Types. The length of the second is dependant on the number of traits for that trait type (e.g. 242 for Trait Type 3 aka heads). The length of the third is dependant on the number of recipients added to this contract. Example lengths: - `pledges[0].length` == 2 representing the two traits possible for a background `cool` (Trait ID 0) and `warm` (Trait ID 1) - `pledges[0][0].length` == the size of the number of recipients that have been added to this contract. Each value is the amount that has been pledged to a specific recipient, indexed by its ID, if a Noun is minted with a cool background. Calling `pledgesForNounId(101) returns cumulative matching pledges for each Trait Type, Trait ID and Recipient ID such that:` - the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1) - the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1) Note: When accessing a Noun ID for an auctioned Noun, pledges for the open ID value `ANY_ID` will be added to total pledges. E.g. `pledgesForNounId(101)` fetches all pledges for the open ID value `ANY_ID` as well as specified pledges for Noun ID 101.

#### Parameters

| Name   | Type   | Description                               |
| ------ | ------ | ----------------------------------------- |
| nounId | uint16 | The ID of the Noun requests should match. |

#### Returns

| Name    | Type           | Description                                                                                     |
| ------- | -------------- | ----------------------------------------------------------------------------------------------- |
| pledges | uint256[][][5] | Cumulative amounts pledged for each Recipient, indexed by Trait Type, Trait ID and Recipient ID |

---

### _pledgesForNounIdByTrait_

```solidity title="Solidity"
function pledgesForNounIdByTrait(enum NounScout.Traits trait, uint16 nounId) external view returns (uint256[][] pledgesByTraitId)
```

Get cumulative pledge amounts scoped to Noun ID and Trait Type.

##### Details

> Example: `pledgesForNounIdByTrait(3, 25)` accumulates all pledged pledges amounts for heads and Noun ID 25. The returned value in `pledges[5][2]` is in the total amount that has been pledged to Recipient ID 2 if Noun ID 25 is minted with a head of Trait ID 5 Note: When accessing a Noun ID for an auctioned Noun, pledges for the open ID value `ANY_ID` will be added to total pledges

#### Parameters

| Name   | Type                  | Description                                             |
| ------ | --------------------- | ------------------------------------------------------- |
| trait  | enum NounScout.Traits | The trait type to scope requests to (See `Traits` Enum) |
| nounId | uint16                | The Noun ID to scope requests to                        |

#### Returns

| Name             | Type        | Description                                                                         |
| ---------------- | ----------- | ----------------------------------------------------------------------------------- |
| pledgesByTraitId | uint256[][] | Cumulative amounts pledged for each Recipient, indexed by Trait ID and Recipient ID |

---

### _pledgesForNounIdByTraitId_

```solidity title="Solidity"
function pledgesForNounIdByTraitId(enum NounScout.Traits trait, uint16 traitId, uint16 nounId) external view returns (uint256[] pledges)
```

Get cumulative pledge amounts scoped to Noun ID, Trait Type, and Trait ID

##### Details

> Example: `pledgesForNounIdByTraitId(0, 1, 25)` accumulates all pledged pledge amounts for background (Trait Type 0) with Trait ID 1 for Noun ID 25. The value in `pledges[2]` is in the total amount that has been pledged to Recipient ID 2 Note: When accessing a Noun ID for an auctioned Noun, pledges for the open ID value `ANY_ID` will be added to total pledges

#### Parameters

| Name    | Type                  | Description                                             |
| ------- | --------------------- | ------------------------------------------------------- |
| trait   | enum NounScout.Traits | The trait type to scope requests to (See `Traits` Enum) |
| traitId | uint16                | The trait ID of the trait to scope requests             |
| nounId  | uint16                | The Noun ID to scope requests to                        |

#### Returns

| Name    | Type      | Description                                                            |
| ------- | --------- | ---------------------------------------------------------------------- |
| pledges | uint256[] | Cumulative amounts pledged for each Recipient, indexed by Recipient ID |

---

### _pledgesForNounOnAuction_

```solidity title="Solidity"
function pledgesForNounOnAuction() external view returns (uint16 currentAuctionId, uint16 prevNonAuctionId, uint256[][5] currentAuctionPledges, uint256[][5] prevNonAuctionPledges)
```

For the Noun that is currently on auction (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts pledged for each Recipient using requests that match the Noun's seed.

##### Details

> Example: The Noun on auction has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `pledgesForNounOnAuction()` returns cumulative matching pledges for each trait that matches the seed such that: - `currentAuctionPledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2. If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `prevNonAuctionPledges` would be populated

#### Returns

| Name                  | Type         | Description                                                                                                                                                 |
| --------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| currentAuctionId      | uint16       | The ID of the Noun that is currently being auctioned                                                                                                        |
| prevNonAuctionId      | uint16       | If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)                                                      |
| currentAuctionPledges | uint256[][5] | Total pledges for the current auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID                                                      |
| prevNonAuctionPledges | uint256[][5] | If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID |

---

### _pledgesForOnChainNoun_

```solidity title="Solidity"
function pledgesForOnChainNoun(uint16 nounId) external view returns (uint256[][5] pledges)
```

For an existing on-chain Noun, use its seed to find matching pledges

##### Details

> Example: `noun.seeds(1)` returns a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `pledgesForOnChainNoun(1)` returns cumulative matching pledges for each trait that matches the seed such that: - `pledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 for Noun ID 1. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2 Note: When accessing a Noun ID for an auctioned Noun, pledges for the open ID value `ANY_ID` will be added to total pledges

#### Parameters

| Name   | Type   | Description                          |
| ------ | ------ | ------------------------------------ |
| nounId | uint16 | Noun ID of an existing on-chain Noun |

#### Returns

| Name    | Type         | Description                                                                                                              |
| ------- | ------------ | ------------------------------------------------------------------------------------------------------------------------ |
| pledges | uint256[][5] | Cumulative amounts pledged for each Recipient that matches the on-chain Noun seed indexed by Trait Type and Recipient ID |

---

### _pledgesForUpcomingNoun_

```solidity title="Solidity"
function pledgesForUpcomingNoun() external view returns (uint16 nextAuctionId, uint16 nextNonAuctionId, uint256[][][5] nextAuctionPledges, uint256[][][5] nextNonAuctionPledges)
```

Use the next auctioned Noun Id (and non-auctioned Noun Id that may be minted in the same block) to get cumulative pledge amounts for each Recipient scoped by possible Trait Type and Trait ID.

##### Details

> See { pledgesForNounId } for detailed documentation of the nested array structure

#### Returns

| Name                  | Type           | Description                                                                                                                                                                   |
| --------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| nextAuctionId         | uint16         | The ID of the next Noun that will be auctioned                                                                                                                                |
| nextNonAuctionId      | uint16         | If two Nouns are due to be minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)                                                               |
| nextAuctionPledges    | uint256[][][5] | Total pledges for the next auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID                                                              |
| nextNonAuctionPledges | uint256[][][5] | If two Nouns are due to be minted, this will contain the total pledges for the next non-auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID |

---

### _rawRequestById_

```solidity title="Solidity"
function rawRequestById(address requester, uint256 requestId) external view returns (struct NounScout.Request request)
```

Get a specific raw Request (without status, includes deleted Requests)

##### Details

> Exists for low-level queries. The function { requestsByAddress } is better in most use-cases

#### Parameters

| Name      | Type    | Description           |
| --------- | ------- | --------------------- |
| requester | address | undefined             |
| requestId | uint256 | The ID of the request |

#### Returns

| Name    | Type              | Description        |
| ------- | ----------------- | ------------------ |
| request | NounScout.Request | The Request struct |

---

### _rawRequestsByAddress_

```solidity title="Solidity"
function rawRequestsByAddress(address requester) external view returns (struct NounScout.Request[] requests)
```

Get all raw Requests (without status, includes deleted Requests)

##### Details

> Exists for low-level queries. The function { requestsByAddress } is better in most use-cases

#### Parameters

| Name      | Type    | Description                  |
| --------- | ------- | ---------------------------- |
| requester | address | The address of the requester |

#### Returns

| Name     | Type                | Description                 |
| -------- | ------------------- | --------------------------- |
| requests | NounScout.Request[] | An array of Request structs |

---

### _recipients_

```solidity title="Solidity"
function recipients() external view returns (struct NounScout.Recipient[])
```

All recipients as Recipient structs

#### Returns

| Name | Type                  | Description |
| ---- | --------------------- | ----------- |
| \_0  | NounScout.Recipient[] | undefined   |

---

### _remove_

```solidity title="Solidity"
function remove(uint256 requestId) external nonpayable returns (uint256 amount)
```

Remove the specified request and return the associated amount.

##### Details

> Must be called by the Requester's address. If the Request has already been settled/donation was sent to the Recipient or the current auction is ending soon, this will revert (See { \_getRequestStatusAndParams } for calculations) If the Recipient of the Request is marked as inactive, the funds can be returned immediately

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| requestId | uint256 | Request Id  |

#### Returns

| Name   | Type    | Description |
| ------ | ------- | ----------- |
| amount | uint256 | undefined   |

---

### _renounceOwnership_

```solidity title="Solidity"
function renounceOwnership() external nonpayable
```

##### Details

> Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.

---

### _requestMatchesNoun_

```solidity title="Solidity"
function requestMatchesNoun(NounScout.Request request, uint16 nounId) external view returns (bool)
```

#### Parameters

| Name    | Type              | Description |
| ------- | ----------------- | ----------- |
| request | NounScout.Request | undefined   |
| nounId  | uint16            | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

---

### _requestsByAddress_

```solidity title="Solidity"
function requestsByAddress(address requester) external view returns (struct NounScout.RequestWithStatus[] requests)
```

Get requests, augemented with status, for non-removed Requests

##### Details

> Removes Requests marked as REMOVED, and includes Requests that have been previously matched. Do not rely on array index; use `request.id` to specify a Request when calling `remove()` See { \_getRequestStatusAndParams } for calculations

#### Parameters

| Name      | Type    | Description                  |
| --------- | ------- | ---------------------------- |
| requester | address | The address of the requester |

#### Returns

| Name     | Type                          | Description                           |
| -------- | ----------------------------- | ------------------------------------- |
| requests | NounScout.RequestWithStatus[] | An array of RequestWithStatus Structs |

---

### _setMaxReimbursement_

```solidity title="Solidity"
function setMaxReimbursement(uint256 newMaxReimbursement) external nonpayable
```

Sets the maximum reimbursement amount when settling

#### Parameters

| Name                | Type    | Description       |
| ------------------- | ------- | ----------------- |
| newMaxReimbursement | uint256 | new maximum value |

---

### _setMessageValue_

```solidity title="Solidity"
function setMessageValue(uint256 newMessageValue) external nonpayable
```

Sets the cost of registering a message

#### Parameters

| Name            | Type    | Description      |
| --------------- | ------- | ---------------- |
| newMessageValue | uint256 | new message cost |

---

### _setMinReimbursement_

```solidity title="Solidity"
function setMinReimbursement(uint256 newMinReimbursement) external nonpayable
```

Sets the minium reimbursement amount when settling

#### Parameters

| Name                | Type    | Description       |
| ------------------- | ------- | ----------------- |
| newMinReimbursement | uint256 | new minimum value |

---

### _setMinValue_

```solidity title="Solidity"
function setMinValue(uint256 newMinValue) external nonpayable
```

Sets the minium value that can be pledged

#### Parameters

| Name        | Type    | Description       |
| ----------- | ------- | ----------------- |
| newMinValue | uint256 | new minimum value |

---

### _setRecipientActive_

```solidity title="Solidity"
function setRecipientActive(uint256 recipientId, bool active) external nonpayable
```

Toggles a Recipient's active state by its index within the set, reverts if Recipient is not configured

##### Details

> If the Done is not configured, a revert will be triggered

#### Parameters

| Name        | Type    | Description                                               |
| ----------- | ------- | --------------------------------------------------------- |
| recipientId | uint256 | Recipient id based on its index within the recipients set |
| active      | bool    | Active state                                              |

---

### _setReimbursementBPS_

```solidity title="Solidity"
function setReimbursementBPS(uint16 newReimbursementBPS) external nonpayable
```

Sets the standard reimbursement basis points

#### Parameters

| Name                | Type   | Description           |
| ------------------- | ------ | --------------------- |
| newReimbursementBPS | uint16 | new basis point value |

---

### _settle_

```solidity title="Solidity"
function settle(enum NounScout.Traits trait, uint16 nounId, uint16[] recipientIds) external nonpayable returns (uint256 total, uint256 reimbursement)
```

Sends pledged amounts to recipients by matching a requested trait to an eligible Noun. A portion of the pledged amount is sent to `msg.sender` to offset the gas costs of settling.

##### Details

> Only eligible Noun Ids are accepted. An eligible Noun Id is for the immediately preceeding auctioned Noun, or non-auctioned Noun if it was minted at the same time. Specifying a Noun Id for an auctioned Noun will matches against requests that have an open ID (ANY_ID) as well as specific ID. If immediately preceeding Noun to the previously auctioned Noun is non-auctioned, only specific ID requests will match. See function body for examples.

#### Parameters

| Name         | Type                  | Description                                                                                                                                       |
| ------------ | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| trait        | enum NounScout.Traits | The Trait Type to fetch from an eligible Noun (see `Traits` Enum)                                                                                 |
| nounId       | uint16                | The Noun to fetch the trait from. Must be the previous auctioned Noun ID or the previous non-auctioned Noun ID if it was minted at the same time. |
| recipientIds | uint16[]              | An array of recipient IDs that have been pledged an amount if a Noun matches the specified trait.                                                 |

#### Returns

| Name          | Type    | Description                              |
| ------------- | ------- | ---------------------------------------- |
| total         | uint256 | Total donated funds before reimbursement |
| reimbursement | uint256 | Reimbursement amount                     |

---

### _traitHash_

```solidity title="Solidity"
function traitHash(enum NounScout.Traits trait, uint16 traitId, uint16 nounId) external pure returns (bytes32 hash)
```

The canonical key for requests that target the same `trait`, `traitId`, and `nounId`

##### Details

> Used to group requests by their parameters in the `amounts` mapping

#### Parameters

| Name    | Type                  | Description         |
| ------- | --------------------- | ------------------- |
| trait   | enum NounScout.Traits | The trait enum      |
| traitId | uint16                | The ID of the trait |
| nounId  | uint16                | The Noun ID         |

#### Returns

| Name | Type    | Description      |
| ---- | ------- | ---------------- |
| hash | bytes32 | The hashed value |

---

### _transferOwnership_

```solidity title="Solidity"
function transferOwnership(address newOwner) external nonpayable
```

##### Details

> Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| newOwner | address | undefined   |

---

### _unpause_

```solidity title="Solidity"
function unpause() external nonpayable
```

Unpauses (resumes) the NounScout contract. Unpausing can be reversed by pausing.

---

### _updateTraitCounts_

```solidity title="Solidity"
function updateTraitCounts() external nonpayable
```

Update local Trait counts based on Noun Descriptor totals

---

### _weth_

```solidity title="Solidity"
function weth() external view returns (contract IWETH)
```

The address of the WETH contract

#### Returns

| Name | Type           | Description           |
| ---- | -------------- | --------------------- |
| \_0  | contract IWETH | WETH contract address |

---

## Events

### _Donated_

```solidity title="Solidity"
event Donated(uint256[] donations)
```

Emitted when an eligible Noun matches one or more Requests

#### Parameters

| Name                                                            | Type      | Description |
| --------------------------------------------------------------- | --------- | ----------- |
| donations                                                       | uint256[] |
| The array of amounts indexed by Recipient ID sent to recipients |

---

### _Matched_

```solidity title="Solidity"
event Matched(enum NounScout.Traits indexed trait, uint16 traitId, uint16 indexed nounId, bytes32 indexed traitsHash)
```

Emitted when an eligible Noun matches one or more Requests

##### Details

> Used to update and/or invalidate Requests stored off-chain for these parameters

#### Parameters

| Name                           | Type                  | Description |
| ------------------------------ | --------------------- | ----------- |
| trait `indexed`                | enum NounScout.Traits |
| Trait Type that matched        |
| traitId                        | uint16                |
| Trait ID that matched          |
| nounId `indexed`               | uint16                |
| Noun Id that matched           |
| traitsHash `indexed`           | bytes32               |
| Hash of trait, traitId, nounId |

---

### _MaxReimbursementChanged_

```solidity title="Solidity"
event MaxReimbursementChanged(uint256 newMaxReimbursement)
```

Emitted when the maxReimbursement changes

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| newMaxReimbursement | uint256 |
| undefined           |

---

### _MessageValueChanged_

```solidity title="Solidity"
event MessageValueChanged(uint256 newMessageValue)
```

Emitted when the messageValue changes

#### Parameters

| Name            | Type    | Description |
| --------------- | ------- | ----------- |
| newMessageValue | uint256 |
| undefined       |

---

### _MinReimbursementChanged_

```solidity title="Solidity"
event MinReimbursementChanged(uint256 newMinReimbursement)
```

Emitted when the minReimbursement changes

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| newMinReimbursement | uint256 |
| undefined           |

---

### _MinValueChanged_

```solidity title="Solidity"
event MinValueChanged(uint256 newMinValue)
```

Emitted when the minValue changes

#### Parameters

| Name        | Type    | Description |
| ----------- | ------- | ----------- |
| newMinValue | uint256 |
| undefined   |

---

### _OwnershipTransferStarted_

```solidity title="Solidity"
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)
```

#### Parameters

| Name                    | Type    | Description |
| ----------------------- | ------- | ----------- |
| previousOwner `indexed` | address |
| undefined               |
| newOwner `indexed`      | address |
| undefined               |

---

### _OwnershipTransferred_

```solidity title="Solidity"
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```

#### Parameters

| Name                    | Type    | Description |
| ----------------------- | ------- | ----------- |
| previousOwner `indexed` | address |
| undefined               |
| newOwner `indexed`      | address |
| undefined               |

---

### _Paused_

```solidity title="Solidity"
event Paused(address account)
```

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| account   | address |
| undefined |

---

### _RecipientActiveStatusChanged_

```solidity title="Solidity"
event RecipientActiveStatusChanged(uint256 recipientId, bool active)
```

Emitted when a Recipient status has changed

#### Parameters

| Name        | Type    | Description |
| ----------- | ------- | ----------- |
| recipientId | uint256 |
| undefined   |
| active      | bool    |
| undefined   |

---

### _RecipientAdded_

```solidity title="Solidity"
event RecipientAdded(uint256 recipientId, string name, address to, string description)
```

Emitted when a Recipient is added

#### Parameters

| Name        | Type    | Description |
| ----------- | ------- | ----------- |
| recipientId | uint256 |
| undefined   |
| name        | string  |
| undefined   |
| to          | address |
| undefined   |
| description | string  |
| undefined   |

---

### _Reimbursed_

```solidity title="Solidity"
event Reimbursed(address indexed settler, uint256 amount)
```

Emitted when an eligible Noun matches one or more Requests

#### Parameters

| Name                                               | Type    | Description |
| -------------------------------------------------- | ------- | ----------- |
| settler `indexed`                                  | address |
| The addressed that performed the settling function |
| amount                                             | uint256 |
| The reimbursement amount                           |

---

### _ReimbursementBPSChanged_

```solidity title="Solidity"
event ReimbursementBPSChanged(uint256 newReimbursementBPS)
```

Emitted when the baseReimbursementBPS changes

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| newReimbursementBPS | uint256 |
| undefined           |

---

### _RequestAdded_

```solidity title="Solidity"
event RequestAdded(uint256 requestId, address indexed requester, enum NounScout.Traits trait, uint16 traitId, uint16 recipientId, uint16 indexed nounId, uint16 pledgeGroupId, bytes32 indexed traitsHash, uint256 amount, string message)
```

Emitted when a Request is added

#### Parameters

| Name                 | Type                  | Description |
| -------------------- | --------------------- | ----------- |
| requestId            | uint256               |
| undefined            |
| requester `indexed`  | address               |
| undefined            |
| trait                | enum NounScout.Traits |
| undefined            |
| traitId              | uint16                |
| undefined            |
| recipientId          | uint16                |
| undefined            |
| nounId `indexed`     | uint16                |
| undefined            |
| pledgeGroupId        | uint16                |
| undefined            |
| traitsHash `indexed` | bytes32               |
| undefined            |
| amount               | uint256               |
| undefined            |
| message              | string                |
| undefined            |

---

### _RequestRemoved_

```solidity title="Solidity"
event RequestRemoved(uint256 requestId, address indexed requester, enum NounScout.Traits trait, uint16 traitId, uint16 indexed nounId, uint16 pledgeGroupId, uint16 recipientId, bytes32 indexed traitsHash, uint256 amount)
```

Emitted when a Request is removed

#### Parameters

| Name                 | Type                  | Description |
| -------------------- | --------------------- | ----------- |
| requestId            | uint256               |
| undefined            |
| requester `indexed`  | address               |
| undefined            |
| trait                | enum NounScout.Traits |
| undefined            |
| traitId              | uint16                |
| undefined            |
| nounId `indexed`     | uint16                |
| undefined            |
| pledgeGroupId        | uint16                |
| undefined            |
| recipientId          | uint16                |
| undefined            |
| traitsHash `indexed` | bytes32               |
| undefined            |
| amount               | uint256               |
| undefined            |

---

### _Unpaused_

```solidity title="Solidity"
event Unpaused(address account)
```

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| account   | address |
| undefined |

---

## Errors

### _AlreadyRemoved_

```solidity title="Solidity"
error AlreadyRemoved()
```

Thrown when attempting to remove a Request that was previously removed.

---

### _AuctionEndingSoon_

```solidity title="Solidity"
error AuctionEndingSoon()
```

Thrown when an attempting to remove a Request within `AUCTION_END_LIMIT` (5 minutes) of auction end.

---

### _InactiveRecipient_

```solidity title="Solidity"
error InactiveRecipient()
```

Thrown when an attempting to add a Request that pledges an amount to an inactive Recipient

---

### _IneligibleNounId_

```solidity title="Solidity"
error IneligibleNounId()
```

Thrown when attempting to match an eligible Noun. Can only match a Noun previous to the current on auction

---

### _MatchFound_

```solidity title="Solidity"
error MatchFound(uint16 nounId)
```

Thrown when an attempting to remove a Request that matches the current or previous Noun

#### Parameters

| Name   | Type   | Description |
| ------ | ------ | ----------- |
| nounId | uint16 | undefined   |

---

### _NoMatch_

```solidity title="Solidity"
error NoMatch()
```

Thrown when attempting to settle the eligible Noun that has no matching Requests for the specified Trait Type and Trait ID

---

### _PledgeSent_

```solidity title="Solidity"
error PledgeSent()
```

Thrown when an attempting to remove a Request that was previously matched (donation was sent)

---

### _ValueTooLow_

```solidity title="Solidity"
error ValueTooLow()
```

Thrown when an attempting to add a Request with value below `minValue`

---