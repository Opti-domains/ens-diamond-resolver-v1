// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@solidstate/contracts/access/ownable/IOwnable.sol";

error Ownable__NotOwner();

contract DiamondOwnerAuth {
  modifier onlyDiamondOwner(address target) {
    if (target != IOwnable(address(this)).owner()) {
      revert Ownable__NotOwner();
    }

    _;
  }
}