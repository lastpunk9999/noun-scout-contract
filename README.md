# Noun Scout

### Summary

Allows anyone to put up a reward for minting a Noun with a specific trait and donates the funds to a charity/public good chosen by the requester from an approved list of addresses.

### Contract Documentation

[NounScout.sol](/docs/src/src/NounScout.sol/contract.NounScout.md)

### Flow

**Creating a Request**

- A user creates a `Request` by sending in funds along with data about the specific `trait` (e.g. Head), `traitId` (e.g. 54 aka 'Cone'), and charity/public good to donate to.
- A `Request` can be scoped to a specific `nounId` or set to `ANY_ID`.
- `ANY_ID` will never match to an on-auctioned Noun.
- _Example:_
  - A 1 ETH request is made to mint a `computer` head Noun, for any Noun Id, with funds being donated to the Internet Archive

**Adding to a Request**

- Another user can create the same `Request` for `trait` and `traitId` combination, and specify the same charity or another.
- Adding can be done at any time before a Noun with specific traits is minted, or during the auction of a matched Noun which allows others to contribute to the pledge during the auction time window.
- _Example:_
  - Alice makes 1 ETH request is made to mint a `panda` head Noun, with funds being donated to the World Wildlife Foundation
  - Noun 34 is minted with a `panda` head
  - Bob adds a 1 ETH `panda` head request, with funds being donated to the World Wildlife Foundation
  - Charlie adds a 0.5 ETH `panda` head request, with funds being donated tothe Rainforest Foundation
  - Noun 34 settles and Noun 35 is minted
  - A match between Noun 34 and `panda` head requests is made
  - 1.98 ETH is sent to the World Wildlife Foundation
  - 0.495 ETH is sent to the Rainforest Foundation
  - 0.025 ETH is sent to the `matcher`

**Matching Requests to a Noun and sending the cumulative pledges**

- If a Noun was minted that matches one more more `Requests`, the match can only be made after its auction has been settled, and at any time during the auction of the next Noun.
- _Example:_
  - A 1 ETH request is made to mint a Noun with `blue` glasses, with funds donated to the Coral Restoration Foundation
  - Noun 34 is minted with `blue` glasses
  - Noun 34 settles and Noun 35 is minted
  - A match between Noun 34 and `blue` glasses requests is made
  - 0.99 ETH is sent to the Coral Restoration Foundation
  - 0.01 ETH is sent to the `matcher`

**Reimbursement for `matchers`**

- To incintivize matching, a user who matches a Noun to a set of `Requests` will be automatically sent 1% of the total pledges made to charity/public goods.

**Removing a Request**

- A `request` may choose to keep their `Request` active forever
- A `requester` can remove their funds their `Request` if the current Noun on auction or the previously auctioned Noun does not match their requested `trait` and `traitId.` This allows 24 hours for a `matcher` to match requests to a Noun
- _Example:_
  - A 1 ETH request is made to mint a Noun with `fries` accessory
  - Noun 34 is minted with `fries` accessory
  - Request cannont be removed
  - Noun 34 settles and Noun 35 is minted
  - Request cannot be removed
  - Noun 35 settles and Noun 36 is minted
  - Request can be removed
- If the current or previous Noun does not match a `Request`, the `Request` can be removed any time up until `5 minutes` before an auction ends
