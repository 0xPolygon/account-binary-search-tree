import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { DemoContract } from '../typechain-types';

describe('Contract', () => {
  let accounts: SignerWithAddress[];
  let contract: DemoContract;
  let sortedAccounts: string[];

  before(async () => {
    accounts = await ethers.getSigners();
    const factory = await ethers.getContractFactory('DemoContract');
    contract = (await factory.deploy()) as DemoContract;
    sortedAccounts = accounts.map((account) => account.address);
  });

  it('should return empty list on initialization', async () => {
    expect(await contract.sortedAccounts(20)).to.deep.equal([]);
  });

  it('should get accounts in order of balances', async () => {
    for (let i = 0; i < accounts.length; i++) {
      await contract
        .connect(accounts[i])
        .deposit({ value: ethers.utils.parseEther((accounts.length - i + 1).toString()) });
    }
    expect(await contract.sortedAccounts(20)).to.deep.equal(sortedAccounts);
  });

  it('should update sorted accounts on balance increase', async () => {
    await contract.connect(accounts[2]).deposit({ value: ethers.utils.parseEther('1.5') });
    [sortedAccounts[2], sortedAccounts[1]] = [sortedAccounts[1], sortedAccounts[2]];
    expect(await contract.sortedAccounts(20)).to.deep.equal(sortedAccounts);
  });

  it('should update sorted accounts on removal', async () => {
    await contract.connect(accounts[7]).withdraw();
    sortedAccounts.splice(7, 1);
    expect(await (await contract.sortedAccounts(20)).length).to.equal(19);
    expect(await contract.sortedAccounts(20)).to.deep.equal(sortedAccounts);
  });
});
