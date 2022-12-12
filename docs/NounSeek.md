---
description:
---

# NounSeek.sol


## Methods


### *ANY_ID*

```solidity title="Solidity"
function ANY_ID() external view returns (uint16)
```
The value of &quot;open Noun ID&quot; which allows trait matches to be performed against any Noun ID except non-auctioned Nouns

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | Set to zero (0) |


---

### *AUCTION_END_LIMIT*

```solidity title="Solidity"
function AUCTION_END_LIMIT() external view returns (uint16)
```
Time limit before an auction ends; requests cannot be removed during this time

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | Set to 5 minutes |


---

### *acceptOwnership*

```solidity title="Solidity"
function acceptOwnership() external nonpayable
```

##### Details
> The new owner accepts the ownership transfer.

---

### *accessoryCount*

```solidity title="Solidity"
function accessoryCount() external view returns (uint16)
```
the total number of accessory traits, fetched and cached via `updateTraitCounts()`

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | accessoryCount |


---

### *add*

```solidity title="Solidity"
function add(enum NounSeek.Traits trait, uint16 traitId, uint16 nounId, uint16 doneeId) external payable returns (uint256 requestId)
```
Create a request for the specific trait and specific or open Noun ID payable to the specified Donee.
##### Details
> `msg.value` is used as the pledged Request amount

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | Trait Type the request is for (see `Traits` Enum) |
| traitId | uint16 | ID of the specified Trait that the request is for |
| nounId | uint16 | the Noun ID the request is targeted for (or the value of ANY_ID for open requests) |
| doneeId | uint16 | the ID of the Donee that should receive the donation if a Noun matching the parameters is minted |
#### Returns
| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of this requests for msg.sender&#39;s address |


---

### *addDonee*

```solidity title="Solidity"
function addDonee(string name, address to, string description) external nonpayable
```
Add a Donee by specifying the name and address funds should be sent to
##### Details
> Adds a Donee to the donees set and activates the Donee

#### Parameters
| Name | Type | Description |
|---|---|---|
| name | string | The Donee&#39;s name that should be displayed to users/consumers |
| to | address | Address that funds should be sent to in order to fund the Donee |
| description | string | undefined |
---

### *addWithMessage*

```solidity title="Solidity"
function addWithMessage(enum NounSeek.Traits trait, uint16 traitId, uint16 nounId, uint16 doneeId, string message) external payable returns (uint256 requestId)
```
Create a request with a logged message for the specific trait and specific or open Noun ID payable to the specified Donee.
##### Details
> The message cost is subtracted from `msg.value` and transfered immediately to the specified Donee. The remaining value is stored as the pledged Request amount request.

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | Trait Type the request is for (see `Traits` Enum) |
| traitId | uint16 | ID of the specified Trait that the request is for |
| nounId | uint16 | the Noun ID the request is targeted for (or the value of ANY_ID for open requests) |
| doneeId | uint16 | the ID of the Donee that should receive the donation if a Noun matching the parameters is minted |
| message | string | The message to log |
#### Returns
| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of this requests for msg.sender&#39;s address |


---

### *amounts*

```solidity title="Solidity"
function amounts(bytes32, uint16) external view returns (uint256)
```
Cumulative funds for trait parameters send to a specific donee. The first mapping key is can be generated with the `traitsHash` function and the second is doneeId

#### Parameters
| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |
| _1 | uint16 | undefined |
#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |


---

### *auctionHouse*

```solidity title="Solidity"
function auctionHouse() external view returns (contract INounsAuctionHouseLike)
```
Retreives the current auction data

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | contract INounsAuctionHouseLike | auctionHouse contract address |


---

### *backgroundCount*

```solidity title="Solidity"
function backgroundCount() external view returns (uint16)
```
the total number of background traits, fetched and cached via `updateTraitCounts()`

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | backgroundCount |


---

### *baseReimbursementBPS*

```solidity title="Solidity"
function baseReimbursementBPS() external view returns (uint16)
```
A portion of donated funds are sent to the address performing a match; owner can update

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | baseReimbursementBPS |


---

### *bodyCount*

```solidity title="Solidity"
function bodyCount() external view returns (uint16)
```
the total number of body traits, fetched and cached via `updateTraitCounts()`

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | bodyCount |


---

### *donationsForMatchableNoun*

```solidity title="Solidity"
function donationsForMatchableNoun() external view returns (uint16 auctionedNounId, uint16 nonAuctionedNounId, uint256[][5] auctionedNounDonations, uint256[][5] nonAuctionedNounDonations, uint256[5] totalDonationsPerTrait, uint256[5] reimbursementPerTrait)
```
For the Noun that is eligible to be matched with pledged donations (and the previous non-auctioned Noun if it was minted at the same time), get cumulative donation amounts for each Donee using requests that match the Noun&#39;s seed.
##### Details
> Example: The Noun that is eligible to match has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `donationsForMatchableNoun()` returns cumulative matching donations for each trait that matches the seed. `auctionedNounDonations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2. If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `nonAuctionedNounDonations` would be populated See the documentation in the function body for the cases used to match eligible Nouns

#### Returns
| Name | Type | Description |
|---|---|---|
| auctionedNounId | uint16 | The ID of the Noun that is was auctioned |
| nonAuctionedNounId | uint16 | If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535) |
| auctionedNounDonations | uint256[][5] | Total donations for the eligible auctioned Noun as a nested arrays in the order Trait Type and Donee ID |
| nonAuctionedNounDonations | uint256[][5] | If two Nouns were minted, this will contain the total donations for the previous non-auctioned Noun as a nested arrays in the order Trait Type and Donee ID |
| totalDonationsPerTrait | uint256[5] | An array of total donation pledged minus reimbursement across all Donees, indexed by Trait Type |
| reimbursementPerTrait | uint256[5] | An array of matcher&#39;s reimbursement that will be sent if a Trait Type is matched, indexed by Trait Type |


---

### *donationsForNounId*

```solidity title="Solidity"
function donationsForNounId(uint16 nounId) external view returns (uint256[][][5] donations)
```
For a given Noun ID, get cumulative donation amounts for each Donee scoped by Trait Type and Trait ID.
##### Details
> The donations array is a nested structure of 3 arrays of Trait Type, Trait ID, and Donee ID. The length of the first array is 5 (five) representing all Trait Types. The length of the second is dependant on the number of traits for that trait type (e.g. 242 for Trait Type 3 aka heads). The length of the third is dependant on the number of donees added to this contract. Example lengths: - `donations[0].length` == 2 representing the two traits possible for a background `cool` (Trait ID 0) and `warm` (Trait ID 1) - `donations[0][0].length` == the size of the number of donees that have been added to this contract. Each value is the amount that has been pledged to a specific donee, indexed by its ID, if a Noun is minted with a cool background. Calling `donationsForNounId(101) returns cumulative matching donations for each Trait Type, Trait ID and Donee ID such that:` - the value at `donations[0][1][2]` is in the total amount that has been pledged to Donee ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1) - the value at `donations[0][1][2]` is in the total amount that has been pledged to Donee ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1) Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations. E.g. `donationsForNounId(101)` fetches all donations for the open ID value `ANY_ID` as well as specified donations for Noun ID 101.

#### Parameters
| Name | Type | Description |
|---|---|---|
| nounId | uint16 | The ID of the Noun requests should match. |
#### Returns
| Name | Type | Description |
|---|---|---|
| donations | uint256[][][5] | Cumulative amounts pledged for each Donee, indexed by Trait Type, Trait ID and Donee ID |


---

### *donationsForNounIdByTrait*

```solidity title="Solidity"
function donationsForNounIdByTrait(enum NounSeek.Traits trait, uint16 nounId) external view returns (uint256[][] donationsByTraitId)
```
Get cumulative donation amounts scoped to Noun ID and Trait Type.
##### Details
> Example: `donationsForNounIdByTrait(3, 25)` accumulates all pledged donations amounts for heads and Noun ID 25. The returned value in `donations[5][2]` is in the total amount that has been pledged to Donee ID 2 if Noun ID 25 is minted with a head of Trait ID 5 Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | The trait type to scope requests to (See `Traits` Enum) |
| nounId | uint16 | The Noun ID to scope requests to |
#### Returns
| Name | Type | Description |
|---|---|---|
| donationsByTraitId | uint256[][] | Cumulative amounts pledged for each Donee, indexed by Trait ID and Donee ID |


---

### *donationsForNounIdByTraitId*

```solidity title="Solidity"
function donationsForNounIdByTraitId(enum NounSeek.Traits trait, uint16 traitId, uint16 nounId) external view returns (uint256[] donations)
```
Get cumulative donation amounts scoped to Noun ID, Trait Type, and Trait ID
##### Details
> Example: `donationsForNounIdByTraitId(0, 1, 25)` accumulates all pledged donation amounts for background (Trait Type 0) with Trait ID 1 for Noun ID 25. The value in `donations[2]` is in the total amount that has been pledged to Donee ID 2 Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | The trait type to scope requests to (See `Traits` Enum) |
| traitId | uint16 | The trait ID  of the trait to scope requests |
| nounId | uint16 | The Noun ID to scope requests to |
#### Returns
| Name | Type | Description |
|---|---|---|
| donations | uint256[] | Cumulative amounts pledged for each Donee, indexed by Donee ID |


---

### *donationsForNounOnAuction*

```solidity title="Solidity"
function donationsForNounOnAuction() external view returns (uint16 currentAuctionId, uint16 prevNonAuctionId, uint256[][5] currentAuctionDonations, uint256[][5] prevNonAuctionDonations)
```
For the Noun that is currently on auction (and the previous non-auctioned Noun if it was minted at the same time), get cumulative donation amounts pledged for each Donee using requests that match the Noun&#39;s seed.
##### Details
> Example: The Noun on auction has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `donationsForNounOnAuction()` returns cumulative matching donations for each trait that matches the seed such that: - `currentAuctionDonations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2. If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `prevNonAuctionDonations` would be populated

#### Returns
| Name | Type | Description |
|---|---|---|
| currentAuctionId | uint16 | The ID of the Noun that is currently being auctioned |
| prevNonAuctionId | uint16 | If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535) |
| currentAuctionDonations | uint256[][5] | Total donations for the current auctioned Noun as a nested arrays indexed by Trait Type and Donee ID |
| prevNonAuctionDonations | uint256[][5] | If two Nouns were minted, this will contain the total donations for the previous non-auctioned Noun as a nested arrays indexed by Trait Type and Donee ID |


---

### *donationsForOnChainNoun*

```solidity title="Solidity"
function donationsForOnChainNoun(uint16 nounId) external view returns (uint256[][5] donations)
```
For an existing on-chain Noun, use its seed to find matching donations
##### Details
> Example: `noun.seeds(1)` returns a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs. Calling `donationsForOnChainNoun(1)` returns cumulative matching donations for each trait that matches the seed such that: - `donations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 for Noun ID 1. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2 Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations

#### Parameters
| Name | Type | Description |
|---|---|---|
| nounId | uint16 | Noun ID of an existing on-chain Noun |
#### Returns
| Name | Type | Description |
|---|---|---|
| donations | uint256[][5] | Cumulative amounts pledged for each Donee that matches the on-chain Noun seed indexed by Trait Type and Donee ID |


---

### *donationsForUpcomingNoun*

```solidity title="Solidity"
function donationsForUpcomingNoun() external view returns (uint16 nextAuctionId, uint16 nextNonAuctionId, uint256[][][5] nextAuctionDonations, uint256[][][5] nextNonAuctionDonations)
```
Use the next auctioned Noun Id (and non-auctioned Noun Id that may be minted in the same block) to get cumulative donation amounts for each Donee scoped by possible Trait Type and Trait ID.
##### Details
> See { donationsForNounId } for detailed documentation of the nested array structure

#### Returns
| Name | Type | Description |
|---|---|---|
| nextAuctionId | uint16 | The ID of the next Noun that will be auctioned |
| nextNonAuctionId | uint16 | If two Nouns are due to be minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535) |
| nextAuctionDonations | uint256[][][5] | Total donations for the next auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Donee ID |
| nextNonAuctionDonations | uint256[][][5] | If two Nouns are due to be minted, this will contain the total donations for the next non-auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Donee ID |


---

### *donees*

```solidity title="Solidity"
function donees() external view returns (struct NounSeek.Donee[])
```
All donees as Donee structs

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | NounSeek.Donee[] | undefined |


---

### *effectiveBPSAndReimbursementForDonationTotal*

```solidity title="Solidity"
function effectiveBPSAndReimbursementForDonationTotal(uint256 total) external view returns (uint256 effectiveBPS, uint256 reimbursement)
```
Given a donation total, derive the reimbursement fee and basis points used to calculate it

#### Parameters
| Name | Type | Description |
|---|---|---|
| total | uint256 | A donation amount |
#### Returns
| Name | Type | Description |
|---|---|---|
| effectiveBPS | uint256 | The basis point used to cacluate the reimbursement fee |
| reimbursement | uint256 | The reimbursement amount |


---

### *glassesCount*

```solidity title="Solidity"
function glassesCount() external view returns (uint16)
```
the total number of glasses traits, fetched and cached via `updateTraitCounts()`

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | glassesCount |


---

### *headCount*

```solidity title="Solidity"
function headCount() external view returns (uint16)
```
the total number of head traits, fetched and cached via `updateTraitCounts()`

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | headCount |


---

### *settle*

```solidity title="Solidity"
function settle(enum NounSeek.Traits trait) external nonpayable returns (uint256 total, uint256 reimbursement)
```
Match and send all pledged amounts for the previous Noun(s).
##### Details
> Matches will made against the previously auctioned Noun using requests that have an open ID (ANY_ID) or specific ID. If immediately preceeding Noun to the previously auctioned Noun is non-auctioned, only specific ID requests will match

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | The Trait Type to match with the previous Noun (see `Traits` Enum) |
#### Returns
| Name | Type | Description |
|---|---|---|
| total | uint256 | Total donated funds before reimbursement |
| reimbursement | uint256 | Reimbursement amount |


---

### *maxReimbursement*

```solidity title="Solidity"
function maxReimbursement() external view returns (uint256)
```
maximum reimbursement for matching; with default BPS value, this is reached at 4 ETH total donations; owner can update

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint256 | maxReimbursement |


---

### *minReimbursement*

```solidity title="Solidity"
function minReimbursement() external view returns (uint256)
```
minimum reimbursement for matching; targets up to 150_000 gas at 20 Gwei/gas; owner can update

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint256 | minReimbursement |


---

### *minValue*

```solidity title="Solidity"
function minValue() external view returns (uint256)
```
The minimum donation value; owner can update

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint256 | minValue |


---

### *nonces*

```solidity title="Solidity"
function nonces(bytes32) external view returns (uint16)
```
Keep track of matched trait parameters using a nonce. When a match is made the nonce is incremented nonce to invalidate request removal. The key can be generated with the `traitsHash` function

#### Parameters
| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |
#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |


---

### *nouns*

```solidity title="Solidity"
function nouns() external view returns (contract INounsTokenLike)
```
Retreives historical mapping of Noun ID -&gt; seed

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | contract INounsTokenLike | nouns contract address |


---

### *owner*

```solidity title="Solidity"
function owner() external view returns (address)
```

##### Details
> Returns the address of the current owner.

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |


---

### *pause*

```solidity title="Solidity"
function pause() external nonpayable
```
Pauses the NounSeek contract. Pausing can be reversed by unpausing.

---

### *paused*

```solidity title="Solidity"
function paused() external view returns (bool)
```

##### Details
> Returns true if the contract is paused, and false otherwise.

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |


---

### *pendingOwner*

```solidity title="Solidity"
function pendingOwner() external view returns (address)
```

##### Details
> Returns the address of the pending owner.

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |


---

### *rawRequestById*

```solidity title="Solidity"
function rawRequestById(address requester, uint256 requestId) external view returns (struct NounSeek.Request request)
```
Get a specific raw Request (without status, includes deleted Requests)
##### Details
> Exists for low-level queries. The function { requestsByAddress } is better in most use-cases

#### Parameters
| Name | Type | Description |
|---|---|---|
| requester | address | undefined |
| requestId | uint256 | The ID of the request |
#### Returns
| Name | Type | Description |
|---|---|---|
| request | NounSeek.Request | The Request struct |


---

### *rawRequestsByAddress*

```solidity title="Solidity"
function rawRequestsByAddress(address requester) external view returns (struct NounSeek.Request[] requests)
```
Get all raw Requests (without status, includes deleted Requests)
##### Details
> Exists for low-level queries. The function { requestsByAddress } is better in most use-cases

#### Parameters
| Name | Type | Description |
|---|---|---|
| requester | address | The address of the requester |
#### Returns
| Name | Type | Description |
|---|---|---|
| requests | NounSeek.Request[] | An array of Request structs |


---

### *remove*

```solidity title="Solidity"
function remove(uint256 requestId) external nonpayable returns (uint256 amount)
```
Remove the specified request and return the associated amount.
##### Details
> Must be called by the Requester&#39;s address. If the Request has already been matched/sent to the Donee or the current auction is ending soon, this will revert (See { _getRequestStatusAndParams } for calculations) If the Donee of the Request is marked as inactive, the funds can be returned immediately

#### Parameters
| Name | Type | Description |
|---|---|---|
| requestId | uint256 | Request Id |
#### Returns
| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |


---

### *renounceOwnership*

```solidity title="Solidity"
function renounceOwnership() external nonpayable
```

##### Details
> Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.

---

### *requestMatchesNoun*

```solidity title="Solidity"
function requestMatchesNoun(NounSeek.Request request, uint16 nounId) external view returns (bool)
```


#### Parameters
| Name | Type | Description |
|---|---|---|
| request | NounSeek.Request | undefined |
| nounId | uint16 | undefined |
#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |


---

### *requestsByAddress*

```solidity title="Solidity"
function requestsByAddress(address requester) external view returns (struct NounSeek.RequestWithStatus[] requests)
```
Get requests, augemented with status, for non-removed Requests
##### Details
> Removes Requests marked as REMOVED, and includes Requests that have been previously matched. Do not rely on array index; use `request.id` to specify a Request when calling `remove()` See { _getRequestStatusAndParams } for calculations

#### Parameters
| Name | Type | Description |
|---|---|---|
| requester | address | The address of the requester |
#### Returns
| Name | Type | Description |
|---|---|---|
| requests | NounSeek.RequestWithStatus[] | An array of RequestWithStatus Structs |


---

### *setDoneeActive*

```solidity title="Solidity"
function setDoneeActive(uint256 doneeId, bool active) external nonpayable
```
Toggles a Donee&#39;s active state by its index within the set, reverts if Donee is not configured
##### Details
> If the Done is not configured, a revert will be triggered

#### Parameters
| Name | Type | Description |
|---|---|---|
| doneeId | uint256 | Donee id based on its index within the donees set |
| active | bool | Active state |
---

### *setMaxReimbursement*

```solidity title="Solidity"
function setMaxReimbursement(uint256 newMaxReimbursement) external nonpayable
```
Sets the maximum reimbursement amount when matching

#### Parameters
| Name | Type | Description |
|---|---|---|
| newMaxReimbursement | uint256 | new maximum value |
---

### *setMinReimbursement*

```solidity title="Solidity"
function setMinReimbursement(uint256 newMinReimbursement) external nonpayable
```
Sets the minium reimbursement amount when matching

#### Parameters
| Name | Type | Description |
|---|---|---|
| newMinReimbursement | uint256 | new minimum value |
---

### *setMinValue*

```solidity title="Solidity"
function setMinValue(uint256 newMinValue) external nonpayable
```
Sets the minium value that can be pledged

#### Parameters
| Name | Type | Description |
|---|---|---|
| newMinValue | uint256 | new minimum value |
---

### *setReimbursementBPS*

```solidity title="Solidity"
function setReimbursementBPS(uint16 newReimbursementBPS) external nonpayable
```
Sets the standard reimbursement basis points

#### Parameters
| Name | Type | Description |
|---|---|---|
| newReimbursementBPS | uint16 | new basis point value |
---

### *traitHash*

```solidity title="Solidity"
function traitHash(enum NounSeek.Traits trait, uint16 traitId, uint16 nounId) external pure returns (bytes32 hash)
```
The canonical key for requests that target the same `trait`, `traitId`, and `nounId`
##### Details
> Used to (1) group requests by their parameters in the `amounts` mapping and (2)keep track of matched requests in the `nonces` mapping

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait | enum NounSeek.Traits | The trait enum |
| traitId | uint16 | The ID of the trait |
| nounId | uint16 | The Noun ID |
#### Returns
| Name | Type | Description |
|---|---|---|
| hash | bytes32 | The hashed value |


---

### *transferOwnership*

```solidity title="Solidity"
function transferOwnership(address newOwner) external nonpayable
```

##### Details
> Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.

#### Parameters
| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |
---

### *unpause*

```solidity title="Solidity"
function unpause() external nonpayable
```
Unpauses (resumes) the NounSeek contract. Unpausing can be reversed by pausing.

---

### *updateTraitCounts*

```solidity title="Solidity"
function updateTraitCounts() external nonpayable
```
Update local Trait counts based on Noun Descriptor totals

---

### *weth*

```solidity title="Solidity"
function weth() external view returns (contract IWETH)
```
The address of the WETH contract

#### Returns
| Name | Type | Description |
|---|---|---|
| _0 | contract IWETH | WETH contract address |


---


## Events

### *Donated*

```solidity title="Solidity"
event Donated(uint256[] donations)
```
Emitted when an eligible Noun matches one or more Requests


#### Parameters
| Name | Type | Description |
|---|---|---|
| donations  | uint256[] |
The array of amounts indexed by Donee ID sent to donees |
---
### *DoneeActiveStatusChanged*

```solidity title="Solidity"
event DoneeActiveStatusChanged(uint256 doneeId, bool active)
```
Emitted when a Donee status has changed


#### Parameters
| Name | Type | Description |
|---|---|---|
| doneeId  | uint256 |
undefined |
| active  | bool |
undefined |
---
### *DoneeAdded*

```solidity title="Solidity"
event DoneeAdded(uint256 doneeId, string name, address to, string description)
```
Emitted when a Donee is added


#### Parameters
| Name | Type | Description |
|---|---|---|
| doneeId  | uint256 |
undefined |
| name  | string |
undefined |
| to  | address |
undefined |
| description  | string |
undefined |
---
### *Matched*

```solidity title="Solidity"
event Matched(enum NounSeek.Traits indexed trait, uint16 traitId, uint16 indexed nounId, bytes32 indexed traitsHash, uint16 newNonce)
```
Emitted when an eligible Noun matches one or more Requests

##### Details
> Used to update and/or invalidate Requests stored off-chain for these parameters

#### Parameters
| Name | Type | Description |
|---|---|---|
| trait `indexed` | enum NounSeek.Traits |
Trait Type that matched |
| traitId  | uint16 |
Trait ID that matched |
| nounId `indexed` | uint16 |
Noun Id that matched |
| traitsHash `indexed` | bytes32 |
Hash of trait, traitId, nounId |
| newNonce  | uint16 |
new incremented nonce; used to invalidated Requests with the prior nonce |
---
### *MaxReimbursementChanged*

```solidity title="Solidity"
event MaxReimbursementChanged(uint256 newMaxReimbursement)
```
Emitted when the maxReimbursement changes


#### Parameters
| Name | Type | Description |
|---|---|---|
| newMaxReimbursement  | uint256 |
undefined |
---
### *MinReimbursementChanged*

```solidity title="Solidity"
event MinReimbursementChanged(uint256 newMinReimbursement)
```
Emitted when the minReimbursement changes


#### Parameters
| Name | Type | Description |
|---|---|---|
| newMinReimbursement  | uint256 |
undefined |
---
### *MinValueChanged*

```solidity title="Solidity"
event MinValueChanged(uint256 newMinValue)
```
Emitted when the minValue changes


#### Parameters
| Name | Type | Description |
|---|---|---|
| newMinValue  | uint256 |
undefined |
---
### *OwnershipTransferStarted*

```solidity title="Solidity"
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)
```



#### Parameters
| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address |
undefined |
| newOwner `indexed` | address |
undefined |
---
### *OwnershipTransferred*

```solidity title="Solidity"
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```



#### Parameters
| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address |
undefined |
| newOwner `indexed` | address |
undefined |
---
### *Paused*

```solidity title="Solidity"
event Paused(address account)
```



#### Parameters
| Name | Type | Description |
|---|---|---|
| account  | address |
undefined |
---
### *Reimbursed*

```solidity title="Solidity"
event Reimbursed(address indexed matcher, uint256 amount)
```
Emitted when an eligible Noun matches one or more Requests


#### Parameters
| Name | Type | Description |
|---|---|---|
| matcher `indexed` | address |
The addressed that performed the matching function |
| amount  | uint256 |
The reimbursement amount |
---
### *ReimbursementBPSChanged*

```solidity title="Solidity"
event ReimbursementBPSChanged(uint256 newReimbursementBPS)
```
Emitted when the baseReimbursementBPS changes


#### Parameters
| Name | Type | Description |
|---|---|---|
| newReimbursementBPS  | uint256 |
undefined |
---
### *RequestAdded*

```solidity title="Solidity"
event RequestAdded(uint256 requestId, address indexed requester, enum NounSeek.Traits trait, uint16 traitId, uint16 doneeId, uint16 indexed nounId, bytes32 indexed traitsHash, uint256 amount, uint16 nonce, string message)
```
Emitted when a Request is added


#### Parameters
| Name | Type | Description |
|---|---|---|
| requestId  | uint256 |
undefined |
| requester `indexed` | address |
undefined |
| trait  | enum NounSeek.Traits |
undefined |
| traitId  | uint16 |
undefined |
| doneeId  | uint16 |
undefined |
| nounId `indexed` | uint16 |
undefined |
| traitsHash `indexed` | bytes32 |
undefined |
| amount  | uint256 |
undefined |
| nonce  | uint16 |
undefined |
| message  | string |
undefined |
---
### *RequestRemoved*

```solidity title="Solidity"
event RequestRemoved(uint256 requestId, address indexed requester, enum NounSeek.Traits trait, uint16 traitId, uint16 indexed nounId, uint16 doneeId, bytes32 indexed traitsHash, uint256 amount)
```
Emitted when a Request is removed


#### Parameters
| Name | Type | Description |
|---|---|---|
| requestId  | uint256 |
undefined |
| requester `indexed` | address |
undefined |
| trait  | enum NounSeek.Traits |
undefined |
| traitId  | uint16 |
undefined |
| nounId `indexed` | uint16 |
undefined |
| doneeId  | uint16 |
undefined |
| traitsHash `indexed` | bytes32 |
undefined |
| amount  | uint256 |
undefined |
---
### *Unpaused*

```solidity title="Solidity"
event Unpaused(address account)
```



#### Parameters
| Name | Type | Description |
|---|---|---|
| account  | address |
undefined |
---


## Errors

### *AlreadyRemoved*

```solidity title="Solidity"
error AlreadyRemoved()
```
Thrown when attempting to remove a Request that was previously removed.



---
### *AuctionEndingSoon*

```solidity title="Solidity"
error AuctionEndingSoon()
```
Thrown when an attempting to remove a Request within `AUCTION_END_LIMIT` (5 minutes) of auction end.



---
### *DonationAlreadySent*

```solidity title="Solidity"
error DonationAlreadySent()
```
Thrown when an attempting to remove a Request that was previously matched



---
### *InactiveDonee*

```solidity title="Solidity"
error InactiveDonee()
```
Thrown when an attempting to add a Request that pledges an amount to an inactive Donee



---
### *MatchFound*

```solidity title="Solidity"
error MatchFound(uint16 nounId)
```
Thrown when an attempting to remove a Request that matches the current or previous Noun



#### Parameters
| Name | Type | Description |
|---|---|---|
| nounId | uint16 | undefined |
---
### *NoMatch*

```solidity title="Solidity"
error NoMatch()
```
Thrown when an attempting to match the eligible Noun that has no matching Requests for the specified Trait Type and Trait ID



---
### *ValueTooLow*

```solidity title="Solidity"
error ValueTooLow()
```
Thrown when an attempting to add a Request with value below `minValue`



---

