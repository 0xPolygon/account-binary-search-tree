// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./lib/AccountStorage.sol";

contract DemoContract {
    using AccountStorageLib for AccountTree;
    AccountTree private _accounts;

    constructor() {}

    /**
     * @notice deposits native asset to the contract, places msg.sender into tree
     * (if they aren't already)
     */
    function deposit() external payable {
        Account storage account = _accounts.get(msg.sender);
        // if account already present in tree, remove and reinsert to maintain sort
        if (_accounts.exists(msg.sender)) {
            _accounts.remove(msg.sender);
        }
        account.balance += msg.value;
        account.isActive = true;
        _accounts.insert(msg.sender, account);
    }

    /**
     * @notice withdraws from deposited funds, rebalances tree
     */
    function withdraw() external {
        Account storage account = _accounts.get(msg.sender);
        uint256 balance = account.balance;
        _accounts.remove(msg.sender);
        account.balance = 0;
        account.isActive = false;
        (bool success, ) = msg.sender.call{value: balance}("");
        assert(success);
    }

    /**
     * @notice returns top `n` accounts in tree
     * @param n uint256 of how many accounts to return
     * @return sortedAddresses array of addresses
     */
    function sortedAccounts(uint256 n) public view returns (address[] memory) {
        uint256 length = n <= _accounts.count ? n : _accounts.count;
        address[] memory sortedAddresses = new address[](length);

        if (length == 0) return sortedAddresses;

        address tmpAccount = _accounts.last();
        sortedAddresses[0] = tmpAccount;

        for (uint256 i = 1; i < length; i++) {
            tmpAccount = _accounts.prev(tmpAccount);
            sortedAddresses[i] = tmpAccount;
        }

        return sortedAddresses;
    }
}
