[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# 🛂 Passport voting contracts

**Fully decentralized voting platform by Rarimo.**

## What

This repository hosts a set of smart contracts that are built on top of [Rarimo Decentralized Identity Issuance](https://github.com/rarimo/passport-contracts) protocol and are needed to create and run decentralized polls.

- The protocol owner may create polls with various configuration settings.
- Multiple questions per poll and multiple options per question are supported.
- The project's architecture allows for maximal level of flexibility and forward-compatibility.
- No points of centralization thanks to the Rarimo passports infrastructure.

## How to use

We distribute the smart contracts as the NPM package:

```bash
npm install @rarimo/passport-voting-contracts
```

Afterwards, you will be able to create polls via `ProposalsState` and vote on them via `Voting` smart contracts.

> [!NOTE]
> This is experimental, state of the art software. Behold and use at your own risk.

## License

The smart contracts are released under the MIT License.

