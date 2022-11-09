// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TestContract is Ownable {
    uint256 public x;

    constructor(uint256 _x) {
        x = _x;
    }

    function increase(uint256 _x) public onlyOwner {
        require(_x > x, "ONLY_INCREASE");
        x = _x;
    }
}
