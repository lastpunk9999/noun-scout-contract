# NounSeek
### Summary
Allows anyone to put up a reward for minting a Noun with a specific trait and donates the funds to a charity/public good chosen by the requester from an approved list of addresses.
### Flow
**Creating a Request**
-  A user creates a `Request` by sending in funds along with data about the specific `trait` (e.g. Head), `traitId` (e.g. 54 aka 'Cone'), and charity/public good to donate to.
- A `Request` can be scoped to a specific `nounId` or set to `ANY_ID`.
- `ANY_ID` will never match to an on-auctioned Noun.
 - *Example:*
   - A 1 ETH request is made to mint a Noun with a squid head, for any Noun Id, with funds being donated to the Marine Conservation Institute

**Adding to a Request**
- Another user can create the same `Request` for `trait` and `traitId` combination, and specify the same charity or another.
- Adding can be done at any time before a Noun with specific traits is minted, or during the auction of a matched Noun which allows others to contribute to the donation during the auction time window.
 - *Example:*
   - A 1 ETH request is made to mint a Noun with a Panda head, with funds being donated to the World Wildlife Foundation
   - Noun 34 is minted with a Panda head
   - Another user adds 1 ETH to the Panda head request
   - Noun 34 settles and Noun 35 is minted
   - A match between Noun 34 and Panda head requests is made
   - 2 ETH is sent to the World Wildlife Foundation

**Matching Requests to a Noun and sending the cumulative donations**
- If a Noun was minted that matches one more more `Requests`, the match can only be made after its auction has been settled, and at any time during the auction of the next Noun.
 - *Example:*
   - A 1 ETH request is made to mint a Noun with Hip-rose glasses
   - Noun 34 is minted with Hip-rose glasses
   - Noun 34 settles and Noun 35 is minted
   - A match between Noun 34 and Hip-rose glasses Requests

**Reimbursement for `matchers`**
- To incintivize matching, a user who matches a Noun to a set of `Requests` will be automatically sent 1% of the total donations made to charity/public goods.

**Removing a Request**
- A `request` may choose to keep their `Request` active forever
- A `requester` can remove their funds their `Request` if the current Noun on auction or the previously auctioned Noun does not match their requested `trait` and `traitId.` This allows 24 hours for a `matcher` to match requests to a Noun
 - *Example:*
   - A 1 ETH request is made to mint a Noun with Hip-rose glasses
   - Noun 34 is minted with Hip-rose glasses
   - Request cannont be removed
   - Noun 34 settles and Noun 35 is minted
   - Request cannot be removed
   - Noun 35 settles and Noun 36 is minted
   - Request can be removed
- If the current or previous Noun does not match a `Request`, the `Request` can be removed any time up until `5 minutes` before an auction ends