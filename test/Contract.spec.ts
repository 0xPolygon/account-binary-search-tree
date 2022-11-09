import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { TestContract } from '../typechain-types';

describe('Contract', () => {
  let accounts: SignerWithAddress[];
  let contract: TestContract;

  before(async () => {
    accounts = await ethers.getSigners();
    const factory = await ethers.getContractFactory('TestContract');
    contract = (await factory.deploy(1)) as TestContract;
  });

  it('only owner should be able to increment', async () => {
    await expect(contract.connect(accounts[1]).increase(2)).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('should not be able to pass lower or equal number', async () => {
    await expect(contract.increase(1)).to.be.revertedWith('ONLY_INCREASE');
  });

  it('should be able to increase', async () => {
    const num = await contract.x();
    await contract.increase(2);
    const newNum = await contract.x();
    expect(num.lt(newNum)).to.be.true;
  });
});
