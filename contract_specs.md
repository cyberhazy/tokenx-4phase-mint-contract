### Tokenomics & assets
* Total supply: 3428
  * 400 buyable with TokenY
  * 3000 buyable with MATIC
  * 28 reserved for team
* Tokens
  * Static, pre-generated and uploaded to **IPFS**
  * Combinations pre-generated randomly, with rarities defined from a configuration to be given by team
  * Token will be **ERC-721** (NFT standard)
* Layers:
  * Background
  * Background overlay
  * Ship cabin
  * Ship chair
  * Character skin (body)
  * Eyes
  * Mouth
  * Clothes
  * Headset
  * Hands
* 50 apes -- represented in same NFT contract with different traits

### Functionality

#### Pre-sale
* Set by controllable `blockHeight` to delay sale in case of issues
* Whitelist check based on allowlist addresses (static)
* Same whitelist mechanism for TokenY holders, will have separate check for that (static)
* Max purchase of 3 tokens per address

#### Public sale
* Set by controllable `blockHeight` to delay sale in case of issues
* Mints up to `maxSupply`
* Batch mint possible, from 1-20 per txn

#### Team claim
* Team will be onboarded to claim their PFPs
* Team check based on team allowlist addresses (static)

#### Insta-reveal mechanics with VRF
* The below will pertain to how Chainlink VRF works. Keep in mind there is a minimal risk of `rawFullfillRandomness` failing -- we will have an emergency mechanism in case it fails.
* User will request a `mint`, and then trigger a `requestRandomness` VRF function. At this point they paid the fee.
* `requestRandomness` will call `rawFullfillRandomness` (this is handled by Chainlink's implementation), which will then trigger the mint. It will emit `RequestMint(id)` just to trace back the request.
* `rawFullfillRandomness` will emit an event `FullfillMint(id, token)`, and mint the token to the requester.
* In case things go wrong, we will have `emergencyFulfill` which we can call with an `id` from `RequestMint`. Only the owner can call this to manually trigger the minting.

#### Ownership
* Will use standard implementation of `Ownable` so that only the owner of the contract can operate admin functions
* Devs will deploy, and then transfer ownership on demand if requested
  * Ideally recommend to transfer to a multi-sig, e.g. Gnosis safe

#### Functions
* Pausing transfers & mints: in case something goes wrong
* Typical NFT functionality: approvals, transfers, ownership checks, `supportsInterface`, `tokenURI`
* Extended NFT functionality
  * Burn function
  * `tokenByIndex` -> tokens will not be minted **sequentially** for insta-reveal mechanics. But this function can be used to check what is the token number of the first token minted, second and so on
  * `tokenOfOwnerByIndex` -> checks the 1st, 2nd, etc. token owned by an address
  * `tokensOwnedByOnwer` -> checks the total amount of tokens owned by an address

### Fees
* Sale funds will be withdrawable from contract by people added to the allowlist of withdrawers (to include multi-sig), or the owner << let me know which one you prefer >>
  * `withdraw` function for MATIC
  * `withdrawERC20` function for TokenY and LINK
* For maximum security of funds, ensure the owner is trustworthy, or you are using a multi-sig
* Fee distribution: <<should we send fees to treasury, or auto-distributed to team with claim?>>
* Opensea fees: sent to the Gnosis safe / owner for now. If we auto-distribute fees, then will make a quick contract to which the fees will be sent so that anyone can withdraw (who is allowed to) via the contract

### Emergency plan
* Keep in mind: smart contracts always pose risks, no matter who develops it. Always need extra people to check the code, but even then cannot always be 100% sure. We need to consider all possible fault scenarios and deal with them.
* Below are potential scenarios and what we can do about them:
    * **Sale exploits**: pause the contract, investigate and re-deploy the contract with migration for people that already minted
    * **Malicious internal team members (hopefully not)**: decide beforehand which trusted member to transfer ownership to, **consider using multi-sig safe** for maximum security!
    * **Funds stolen**: nothing we can do. Need to bulletproof test it, and need inputs from multiple people. Also should withdraw funds from the contract ASAP as a precaution.
    * **VRF fails**: call `emergencyFulfill`
    * **Sale/formal delays**: modify `blockHeight` to delay the sale

### Output
* 3428 TokenX pre-generated assets
* 1 TokenX NFT contract with the functionality outlined above
* Automated tests for NFT contract
* Deploying the contract to testnet, testing & help team verify everything works
* Deploying & executing the contract to mainnet
* WL setup for: NftTokenX, TokenY holders, team

### Requests for team (non-dev tasks)
* Organize assets:
  * Folders: name of folder should be the layer, contents of folder should be the trait names
  * Rarity descriptions: in JSON, YAML, CSV or text format (1 line at a time) -- coordinate with dev. Trait names and layers must match the folder structure for quick development
* Setup Pinata account (or other IPFS pinning service) and share the API key. Let the team members that own the most own this account so you are always in control of it.
  * Possible alternative: `nft.storage` instead of Pinata
* Provide list of whitelisted addresses as plain text (1 line - 1 address)
* Provide list of picked TokenY addresses as plain text (1 line - 1 address)
* Provide list of dev addresses as plain text
* Be there to test the contract in testnet
* Provide Opensea inputs
* Provide token info: name, symbol
* Give directions on who to give contract ownership to
* Fees to cover deploys, LINK for VRF
