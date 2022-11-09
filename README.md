# Account Binary Search Tree

[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![CI Status](https://github.com/gretzke/account-binary-search-tree/actions/workflows/tests.yml/badge.svg)](https://github.com/gretzke/account-binary-search-tree/actions)

This project demonstrates an implementation of a self balancing binary search tree for use cases where accounts need to be sorted by their balance. This could be used inside of a game where players are sorted by their points or a staking implementation where stakers need to be sorted by their stake.

If an array or linked list was used for such a use case the insertion and deletion cost would be `O(n)` worst case which is not suitable for a smart contract implementation. With this self balancing binary implementation the insertion and deletion cost can be reduced to `O(log n)`. This library is based on [Rob Hitchens's (B9Labs) order statistics tree](https://github.com/rob-Hitchens/OrderStatisticsTree).

Dor more information on red-black trees see https://en.wikipedia.org/wiki/Red%E2%80%93black_tree

## Build and Test

On the project root, run:

```bash
$ npm i                 # install dependencies
$ npm run compile       # compile contracts and generate typechain
$ npm test              # run contract tests
```

To run foundry tests for the library:

```bash
$ forge build           # compile contracts
$ forge test            # run library tests
```

optional:

```bash
$ npm run coverage      # run test coverage tool
```

## Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Goerli.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Infura API key, and the mnemonic phrase of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
npx hardhat run scripts/deploy.ts --network goerli
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network goerli DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
