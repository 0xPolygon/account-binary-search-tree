# Account Binary Search Tree

[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![CI Status](https://github.com/gretzke/account-binary-search-tree/actions/workflows/tests.yml/badge.svg)](https://github.com/gretzke/account-binary-search-tree/actions)

## Contents

- [Description](#description)
- [Usage](#usage)
- [API](#api)
- [Build and Test](#build-and-test)
- [Etherscan Verification](#etherscan-verification)
- [Performance Optimizations](#performance-optimizations)

## Description

This project demonstrates an implementation of a self balancing red-black binary search tree for usecases where accounts/addresses need to be sorted by their balance. This could be used inside of a game where players are sorted by their points or a staking implementation where stakers need to be sorted by their stake.

If an array or linked list was used for such a use case the insertion and deletion cost would be `O(n)` worst case which is not suitable for a smart contract implementation. With this self balancing binary implementation the insertion and deletion cost can be reduced to `O(log n)`. This library is based on [Rob Hitchens's (B9Labs) order statistics tree](https://github.com/rob-Hitchens/OrderStatisticsTree).

Dor more information on red-black trees see https://en.wikipedia.org/wiki/Red%E2%80%93black_tree

## Usage

These contracts were originally developed for Polygon's [Core Contracts](https://github.com/0xPolygon/core-contracts), where they are used to maintain the list of validators and sort them by stake. You can read more about this implementation [here](https://github.com/0xPolygon/core-contracts/tree/main/contracts/libs#queue-pool-and-tree-libs-in-more-detail).

As you can see in both the example implementation in this repo and in Polygon's Core Contracts, you will generally use a two-contract approach, using `AccountStorage.sol` as a lib inside of a queue implemented to use it. (In the case of this repo, `DemoContract.sol`.)

In addition, the structs used throughout the tree are located in `contracts/interfaces/IAccount.sol`.

The example in this repo sorts accounts in a tree based on the amount of native asset (e.g. ETH on Ethereum mainnet) staked in the `DemoContract.sol` contract. We hope this example also helps illustrate how the tree could be used easily for ERC20 tokens or NFTs.

There are also basic tests to demonstrate basic usage.

## API

All structs and functions have detailed natspec, more detail on these can be found there. This will be a brief overview of the function API for `AccountStorage`. Note that all functions are `internal`. This contract is meant to be consumed as a library. Here is the function API:

- `function get(AccountTree storage self, address account) returns (Account storage)`
- `function balanceOf(AccountTree storage self, address account) returns (uint256 balance)`
- `function first(AccountTree storage self) returns (address _key)`
- `function last(AccountTree storage self) returns (address _key)`
- `function next(AccountTree storage self, address target) returns (address cursor)`
- `function prev(AccountTree storage self, address target) returns (address cursor)`
- `function exists(AccountTree storage self, address key) returns (bool)`
- `function isEmpty(address key) returns (bool)`
- `function getNode(AccountTree storage self, address key) returns (address _returnKey, address _parent, address _left, address _right, bool _red)`
- `function insert(AccountTree storage self, address key, Account memory account)`
- `function remove(AccountTree storage self, address key)`
- `function treeMinimum(AccountTree storage self, address key) returns (address)`
- `function treeMaximum(AccountTree storage self, address key) returns (address)`
- `function rotateLeft(AccountTree storage self, address key)`
- `function rotateRight(AccountTree storage self, address key)`
- `function insertFixup(AccountTree storage self, address key)`
- `function replaceParent(AccountTree storage self, address a, address b)`
- `function removeFixup(AccountTree storage self, address key)`

In addition, the struct API for `Account`, used in `insert()` is:

```
struct Account {
  uint256 balance;
  bool isActive;
}
```

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
