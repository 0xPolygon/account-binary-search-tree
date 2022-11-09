# Sample Hardhat Project

[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![CI Status](https://github.com/gretzke/hardhat-typescript-template/actions/workflows/tests.yml/badge.svg)](https://github.com/gretzke/hardhat-typescript-template/actions)
[![Coverage Status](https://coveralls.io/repos/github/gretzke/hardhat-typescript-template/badge.svg?branch=main&t=ZTUm69)](https://coveralls.io/github/gretzke/hardhat-typescript-template?branch=main)

This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

## Build and Test

On the project root, run:

```
$ npm i                 # install dependencies
$ npm run compile       # compile contracts and generate typechain
$ npm test              # run tests
```

optional:

```
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
