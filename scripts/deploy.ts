require('dotenv').config();
import { ethers, network, upgrades } from 'hardhat';

let num: number;

if (network.name === 'mainnet') {
  num = 1;
} else if (network.name === 'goerli') {
  num = 2;
} else {
  throw new Error('Unsupported network');
}

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contract with account:', deployer.address);
  const factory = await ethers.getContractFactory('TestContract');
  const contract = await factory.deploy(num);
  console.log('Contract address:', contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
