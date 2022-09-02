# NounSeek v1
### Summary
Allows anyone to put up a reward for minting any combination Noun trait and distributes the reward if the current or next Noun is minted with the desired traits.
### Flow
**Creating a Seek**
-  `1 hour` after the start of a Noun auction or up to `5 minutes` before the ending of a Noun auction, a user creates a `Seek` by sending in funds and a list of traits that will unlock the reward. The traits are any combination of `head`, `accessory`, `glasses`, `body`.
- A `Seek` can be scoped to a specific `nounId` or explicitly prevented from matching a non-auctioned Noun by specifying a `onlyAuctionedNoun` flag.
- Another user can add funds to an existing `Seek` by specifying the same combination of `head`, `accessory`, `glasses`, `body`, `nounId`, and `onlyAuctionedNoun` flag.

**Matching a Seek to the Noun currently on auction**
-  If a Noun with traits that match the `Seek` are minted outside of this contract, anyone has `1 hour` after mint to match the `Seek` to the current Noun and be set as the `Seek`'s `finder`.
-  A `Seek` may match the currently auctioned Noun or the previous Noun if it was not auctioned.

**Settling and Matching the Next Noun(s)**
- If a Noun with traits that match a `Seek` are minted using this contract, the `finder` is automatically the sender.
- If the next Noun to be minted will not be auctioned, a `Seek` will match against it and the next Noun to be auctioned.

**Withdrawing Finder's Funds**
- The `Seek` finder can withdraw their reward any time after a match.

**Removing a Seek**
- A `seeker` may choose to keep their `Seek` active forever
- A `seeker` can remove their funds if their `Seek` has not been found, but only after `1 hour` from the start of a Noun auction or up to `5 minutes` before the ending a Noun auction.