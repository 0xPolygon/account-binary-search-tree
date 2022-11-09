// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IAccount.sol";

error AmountZero();
error NotFound(address account);
error Exists(address account);

/**
 * @title Account Storage Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice implementation of red-black ordered tree to order accounts by a certain number
 *
 * for more information on red-black trees:
 * https://en.wikipedia.org/wiki/Red%E2%80%93black_tree
 * implementation draws on Rob Hitchens's (B9Labs) Order Statistics tree:
 * https://github.com/rob-Hitchens/OrderStatisticsTree
 * which in turn is based on BokkyPooBah's implementation
 * https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
 */
library AccountStorageLib {
    address private constant EMPTY = address(0);

    /**
     * @notice returns the Account struct of a specific account
     * @param self the AccountTree struct
     * @param account the address of the account to lookup
     * @return Account struct
     */
    function get(AccountTree storage self, address account) internal view returns (Account storage) {
        // return empty account object if account doesn't exist
        return self.nodes[account].account;
    }

    /**
     * @notice returns the balance of a specific account
     * @param self the AccountTree struct
     * @param account the address of the account to query the balance of
     * @return balance the balance of the account
     */
    function balanceOf(AccountTree storage self, address account) internal view returns (uint256 balance) {
        balance = self.nodes[account].account.balance;
    }

    /**
     * @notice returns the address of the first account in the tree
     * @dev the first node will be the account with the lowest balance
     * @param self the AccountTree struct
     * @return _key the address of the account
     */
    function first(AccountTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }

    /**
     * @notice returns the address of the last account in the tree
     * @dev the first node will be the account with the highest balance
     * @param self the AccountTree struct
     * @return _key the address of the account
     */
    function last(AccountTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }

    /**
     * @notice returns the next addr in the tree from a particular addr
     * @dev the "next" node is the account with the next highest balance
     * @param self the AccountTree struct
     * @param target the address to check the next account to
     * @return cursor the next account's address
     */
    // slither-disable-next-line dead-code
    function next(AccountTree storage self, address target) internal view returns (address cursor) {
        if (target == EMPTY) revert AmountZero();
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /**
     * @notice returns the prev addr in the tree from a particular addr
     * @dev the "next" node is the account with the next lowest balance
     * @param self the AccountTree struct
     * @param target the address to check the previous account to
     * @return cursor the previous account's address
     */
    function prev(AccountTree storage self, address target) internal view returns (address cursor) {
        if (target == EMPTY) revert AmountZero();
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /**
     * @notice checks if a specific address is in the tree with nonzero balance
     * @param self the AccountTree struct
     * @param key the address to check membership of
     * @return bool indicating if the address is in the tree (with balance >0) or not
     */
    function exists(AccountTree storage self, address key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    /**
     * @notice checks if an address is the zero address
     * @param key the address to check
     * @return bool indicating if the address is the zero addr or not
     */
    // slither-disable-next-line dead-code
    function isEmpty(address key) internal pure returns (bool) {
        return key == EMPTY;
    }

    /**
     * @notice returns the tree positioning of an address in the tree
     * @param self the AccountTree struct
     * @param key the address to return the position of
     * @return _returnKey the address input as an argument
     * @return _parent the parent address in the node
     * @return _left the address to the left in the tree
     * @return _right the address to the right in the tree
     * @return _red if the node is red or not
     */
    // slither-disable-next-line dead-code
    function getNode(
        AccountTree storage self,
        address key
    ) internal view returns (address _returnKey, address _parent, address _left, address _right, bool _red) {
        if (!exists(self, key)) revert NotFound(key);
        return (key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    /**
     * @notice inserts a account into the tree
     * @dev if balance of the account is zero, the data will be stored but it will not be inserted into the tree
     * @param self the AccountTree struct
     * @param key the address to add
     * @param account the Account struct of the address
     */
    function insert(AccountTree storage self, address key, Account memory account) internal {
        assert(key != EMPTY);
        if (exists(self, key)) revert Exists(key);
        if (account.balance == 0) {
            self.nodes[key].account = account;
            return;
        }
        address cursor = EMPTY;
        address probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (account.balance < self.nodes[probe].account.balance) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true, account: account});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (account.balance < self.nodes[cursor].account.balance) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
        self.count++;
        self.totalBalance += account.balance;
    }

    /**
     * @notice removes a account from the tree
     * @dev does not delete Account struct from storage
     * @param self the AccountTree struct
     * @param key the address to remove
     */
    function remove(AccountTree storage self, address key) internal {
        assert(key != EMPTY);
        if (!exists(self, key)) revert NotFound(key);
        address probe;
        address cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        address yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        self.nodes[cursor].parent = EMPTY;
        self.nodes[cursor].left = EMPTY;
        self.nodes[cursor].right = EMPTY;
        self.nodes[cursor].red = false;
        self.count--;
        self.totalBalance -= self.nodes[cursor].account.balance;
    }

    /**
     * @notice returns the left-most node from an address, using that address as the root of a subtree
     * @dev since left will not traverse to a parent, this will not necessarily return `first()`
     * @param self the AccountTree struct
     * @param key the address to check the left-most node from
     * @return address the left-most node from the input address
     */
    // slither-disable-next-line dead-code
    function treeMinimum(AccountTree storage self, address key) private view returns (address) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    /**
     * @notice returns the right-most node from an address in the tree, using that address as the root of a subtree
     * @dev since right will not traverse to a parent, this will not necessarily return `last()`
     * @param self the AccountTree struct
     * @param key the address to check the right-most node from
     * @return address the right-most node from the input address
     */
    function treeMaximum(AccountTree storage self, address key) private view returns (address) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return (key);
    }

    /**
     * @notice rebalances tree by rotating left
     * @param self the AccountTree struct
     * @param key the address to begin the rotation from
     */
    function rotateLeft(AccountTree storage self, address key) private {
        address cursor = self.nodes[key].right;
        address keyParent = self.nodes[key].parent;
        address cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }

    /**
     * @notice rebalances tree by rotating right
     * @param self the AccountTree struct
     * @param key the address to begin the rotation from
     */
    function rotateRight(AccountTree storage self, address key) private {
        address cursor = self.nodes[key].left;
        address keyParent = self.nodes[key].parent;
        address cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    /**
     * @notice private function for repainting tree on insert
     * @param self the AccountTree struct
     * @param key the address being inserted into the tree
     */
    function insertFixup(AccountTree storage self, address key) private {
        address cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            address keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    /**
     * @notice changes the parent node of a account's node in the tree
     * @param self the AccountTree struct
     * @param a the address to have the parent changed
     * @param b the parent will be changed to the parent of this addr
     */
    function replaceParent(AccountTree storage self, address a, address b) private {
        address bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    /**
     * @notice private function for repainting tree on remove
     * @param self the AccountTree struct
     * @param key the address being removed into the tree
     */
    function removeFixup(AccountTree storage self, address key) private {
        address cursor;
        while (key != self.root && !self.nodes[key].red) {
            address keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
