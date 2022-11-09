// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccountStorageLib, AmountZero, Exists, NotFound} from "contracts/lib/AccountStorage.sol";
import {Account, Node, AccountTree} from "contracts/interfaces/IAccount.sol";

import "./TestPlus.sol";

abstract contract EmptyState is TestPlus {
    address accountAddr;
    Account account;

    AccountStorageLibUser accountStorageLibUser;

    function setUp() public virtual {
        accountAddr = makeAddr("accountAddr");
        account = _createAccount(1 ether);
        accountStorageLibUser = new AccountStorageLibUser();
    }
}

contract AccountStorageTest_EmptyState is EmptyState {
    function testCannotInsert_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        accountStorageLibUser.insert(address(0), account);
    }

    function testCannotInsert_Exists() public {
        accountStorageLibUser.insert(accountAddr, account);

        vm.expectRevert(abi.encodeWithSelector(Exists.selector, accountAddr));
        accountStorageLibUser.insert(accountAddr, account);
    }

    function testInsert(uint128[] memory amounts) public {
        uint256 accountCount;
        uint256 totalBalance;

        // insert in tree
        for (uint256 i; i < amounts.length; ++i) {
            address tmpAccountAddr = vm.addr(i + 1);
            uint128 amount = amounts[i];
            Account memory _account;
            if (amount > 0) {
                _account = _createAccount(amount);
                ++accountCount;
            } else {
                // if amount is 0, set isActive to true so we can assert insertion
                _account.isActive = true; // + 1 guarantees uniqueness
            }

            accountStorageLibUser.insert(tmpAccountAddr, _account);
            totalBalance += amount;

            // accounts with no balance
            if (amount == 0) {
                assertEq(accountStorageLibUser.get(tmpAccountAddr), _account, "Accounts with no balance");
            }
        }
        vm.assume(accountCount > 0);
        address _accountAddr = accountStorageLibUser.first();
        address prevAccount;

        // tree balance
        assertNotEq(accountStorageLibUser.balanceOf(_accountAddr), 0); // accounts with no balance should not be included
        while (accountStorageLibUser.next(_accountAddr) != address(0)) {
            prevAccount = _accountAddr;
            _accountAddr = accountStorageLibUser.next(_accountAddr);

            assertNotEq(accountStorageLibUser.balanceOf(_accountAddr), 0);
            assertGe(
                accountStorageLibUser.balanceOf(_accountAddr),
                accountStorageLibUser.balanceOf(prevAccount),
                "Tree balance"
            );
        }
        // account count
        assertEq(accountStorageLibUser.countGetter(), accountCount, "Account count");
        // total balance
        assertEq(accountStorageLibUser.totalBalanceGetter(), totalBalance, "Total balance");
    }
}

abstract contract NonEmptyState is EmptyState {
    // saved data for assertion
    address[] accounts;
    mapping(address => uint128) amountOf;
    address firstAccount;
    address lastAccount;

    function setUp() public virtual override {
        super.setUp();
    }

    /// @notice Populate tree with unique accounts
    /// @dev Use in fuzz tests
    function _populateTree(uint128[] memory amounts) internal {
        uint256 accountCount;
        for (uint256 i; i < amounts.length; ) {
            address _accountAddr = vm.addr(i + 1);
            uint128 amount = amounts[i];
            Account memory _account = _createAccount(amount);
            accounts.push(_accountAddr);
            amountOf[_accountAddr] = amount;
            if (amount > 0) {
                ++accountCount;
                // initialize saved data
                if (accountCount == 1) {
                    firstAccount = _accountAddr;
                    lastAccount = _accountAddr;
                }
                // update saved data
                if (amount < amountOf[firstAccount]) firstAccount = _accountAddr;
                if (amount >= amountOf[lastAccount]) lastAccount = _accountAddr;
            }
            accountStorageLibUser.insert(_accountAddr, _account);

            unchecked {
                ++i;
            }
        }
        vm.assume(accountCount > 0);
    }
}

contract AccountStorageTest_NonEmptyState is NonEmptyState {
    function testGet_EmptyAccount() public {
        Account memory _account;

        assertEq(accountStorageLibUser.get(accountAddr), _account);
    }

    function testGet(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _accountAddr = accounts[i];
            Account memory _account = _createAccount(amountOf[_accountAddr]);

            assertEq(accountStorageLibUser.get(_accountAddr), _account);
        }
    }

    function testBalanceOf(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _accountAddr = accounts[i];

            assertEq(accountStorageLibUser.balanceOf(_accountAddr), amountOf[_accountAddr]);
        }
    }

    function testFirst(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(accountStorageLibUser.first(), firstAccount);
    }

    function testLast(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(accountStorageLibUser.last(), lastAccount);
    }

    function testCannotNext_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        accountStorageLibUser.next(address(0));
    }

    function testNext(uint128[] memory amounts) public {
        _populateTree(amounts);
        address prevAccount;
        address _accountAddr = firstAccount;

        while (accountStorageLibUser.next(_accountAddr) != address(0)) {
            prevAccount = _accountAddr;
            _accountAddr = accountStorageLibUser.next(_accountAddr);

            // balance and order
            assertEq(accountStorageLibUser.balanceOf(_accountAddr), amountOf[_accountAddr], "Balance");
            assertGe(amountOf[_accountAddr], amountOf[prevAccount], "Balance order");
        }
        // end address
        assertEq(_accountAddr, lastAccount, "End address");
    }

    function testCannotPrev_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        accountStorageLibUser.prev(address(0));
    }

    function testPrev(uint128[] memory amounts) public {
        _populateTree(amounts);
        address nextAccount;
        accountAddr = lastAccount;

        while (accountStorageLibUser.prev(accountAddr) != address(0)) {
            nextAccount = accountAddr;
            accountAddr = accountStorageLibUser.prev(accountAddr);

            // balance and order
            assertEq(accountStorageLibUser.balanceOf(accountAddr), amountOf[accountAddr], "Balance");
            assertLe(amountOf[accountAddr], amountOf[nextAccount], "Balance order");
        }
        // end address
        assertEq(accountAddr, firstAccount, "End address");
    }

    function testExists(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _accountAddr = accounts[i];

            if (amountOf[_accountAddr] > 0)
                assertTrue(accountStorageLibUser.exists(_accountAddr), "Accounts with balance");
            else assertFalse(accountStorageLibUser.exists(_accountAddr), "Accounts with no balance");
        }
    }

    function testIsEmpty() public {
        assertTrue(accountStorageLibUser.isEmpty(address(0)), "Zero address");
        assertFalse(accountStorageLibUser.isEmpty(accountAddr), "Non-zero address");
    }

    function testCannotGetNode_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, accountAddr));
        accountStorageLibUser.getNode(accountAddr);
    }

    function testGetNode(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToLookUp = accounts[i % accounts.length];
        vm.assume(amountOf[accountToLookUp] > 0);

        (address returnKey, address parent, address left, address right, bool red) = accountStorageLibUser.getNode(
            accountToLookUp
        );
        Node memory node = Node(parent, left, right, red, _createAccount(amountOf[returnKey]));

        assertEq(node, accountStorageLibUser.nodesGetter(accountToLookUp));
    }

    function testCannotRemove_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        accountStorageLibUser.remove(address(0));
    }

    function testCannotRemove_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, accountAddr));
        accountStorageLibUser.remove(accountAddr);
    }

    function testRemove(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToRemove = accounts[i % accounts.length];
        vm.assume(amountOf[accountToRemove] > 0);
        // expected values
        uint256 accountCount = accountStorageLibUser.countGetter() - 1;
        uint256 totalBalance = accountStorageLibUser.totalBalanceGetter() - amountOf[accountToRemove];

        // remove from tree
        accountStorageLibUser.remove(accountToRemove);

        address _accountAddr = accountStorageLibUser.first();
        address prevAccount;
        // tree balance
        if (accountCount > 0) {
            while (accountStorageLibUser.next(_accountAddr) != address(0)) {
                prevAccount = _accountAddr;
                _accountAddr = accountStorageLibUser.next(_accountAddr);

                assertGe(amountOf[_accountAddr], amountOf[prevAccount], "Tree balance");
            }
        }
        // account count
        assertEq(accountStorageLibUser.countGetter(), accountCount, "Account count");
        // total balance
        assertEq(accountStorageLibUser.totalBalanceGetter(), totalBalance, "Total balance");
    }

    function testRemove_All(uint128[] memory amounts) public {
        _populateTree(amounts);

        // remove from tree
        for (uint256 i; i < accounts.length; ++i) {
            address _accountAddr = accounts[i];
            if (amountOf[_accountAddr] > 0) accountStorageLibUser.remove(_accountAddr);
        }

        // no root
        assertEq(accountStorageLibUser.rootGetter(), address(0), "Root");
        // account count
        assertEq(accountStorageLibUser.countGetter(), 0, "Account count");
        // total balance
        assertEq(accountStorageLibUser.totalBalanceGetter(), 0, "Total balance");
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPERS
//////////////////////////////////////////////////////////////////////////*/

function _createAccount(uint256 amount) pure returns (Account memory account) {
    account.balance = amount;
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract AccountStorageLibUser {
    AccountTree tree;

    constructor() {}

    function get(address account) external view returns (Account memory) {
        Account memory r = AccountStorageLib.get(tree, account);
        return r;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 r = AccountStorageLib.balanceOf(tree, account);
        return r;
    }

    function first() external view returns (address) {
        address r = AccountStorageLib.first(tree);
        return r;
    }

    function last() external view returns (address) {
        address r = AccountStorageLib.last(tree);
        return r;
    }

    function next(address target) external view returns (address) {
        address r = AccountStorageLib.next(tree, target);
        return r;
    }

    function prev(address target) external view returns (address) {
        address r = AccountStorageLib.prev(tree, target);
        return r;
    }

    function exists(address key) external view returns (bool) {
        bool r = AccountStorageLib.exists(tree, key);
        return r;
    }

    function isEmpty(address key) external pure returns (bool) {
        bool r = AccountStorageLib.isEmpty(key);
        return r;
    }

    function getNode(address key) external view returns (address, address, address, address, bool) {
        (address a, address b, address c, address d, bool e) = AccountStorageLib.getNode(tree, key);
        return (a, b, c, d, e);
    }

    function insert(address key, Account memory account) external {
        AccountStorageLib.insert(tree, key, account);
    }

    function remove(address key) external {
        AccountStorageLib.remove(tree, key);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function rootGetter() external view returns (address) {
        return tree.root;
    }

    function countGetter() external view returns (uint256) {
        return tree.count;
    }

    function totalBalanceGetter() external view returns (uint256) {
        return tree.totalBalance;
    }

    function nodesGetter(address a) external view returns (Node memory) {
        return tree.nodes[a];
    }
}
