# TokenX NFT
NFT contract with custom minting & sale phases built for a Polygon-based project.

The project-specific details have been anonymised under the name "TokenX" since the project did not end up using this contract. The NFT was meant to be integrated with ERC-20 "TokenY" to be able to buy NFTs using the different token.

## Features
* Phase 1 mint: team claim mint based on team whitelist
* Phase 2 mint: pre-sale with N randomly selected TokenY holders
* Phase 3 mint: pre-sale with whitelisted addresses
* Phase 4 mint: public sale with fixed MATIC price
* Chainlink VRF insta-reveal mint, powered by the same mechanism as [PolyBlade](https://github.com/cyberhazy/polyblade-contract)
* Sale controls: pre-sale/public sale blockheight settings and toggles
* Ability to withdraw ERC20s

