// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "contracts/interfaces/IAccount.sol";

abstract contract TestPlus is Test {
    function assertNotEq(uint256 a, uint256 b) internal virtual {
        if (a == b) {
            emit log("Error: a != b not satisfied [uint]");
            emit log_named_uint("Not expected", b);
            emit log_named_uint("      Actual", a);
            fail();
        }
    }

    function assertEq(Account memory a, Account memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [Account]");
            fail();
        }
    }

    function assertEq(Account memory a, Account memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(Node memory a, Node memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [Node]");
            fail();
        }
    }
}
