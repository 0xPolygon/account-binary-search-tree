// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IAccount
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 */

/**
 * @notice data type representing an account, more variables can be added here
 * @param balance that is used for maintaining an order
 */
struct Account {
    uint256 balance;
    bool isActive;
}

/**
 * @notice data type for nodes in the red-black account tree
 * @param parent address of the parent of this node
 * @param left the node in the tree to the left of this one
 * @param right the node in the tree to the right of this one
 * @param red bool denoting color of node for balancing
 */
struct Node {
    address parent;
    address left;
    address right;
    bool red;
    Account account;
}

/**
 * @notice data type for the red-black account tree
 * @param root
 * @param count amount of nodes in the tree
 * @param totalBalance total amount of balances by nodes of the tree
 * @param nodes address to node mapping
 */
struct AccountTree {
    address root;
    uint256 count;
    uint256 totalBalance;
    mapping(address => Node) nodes;
}
