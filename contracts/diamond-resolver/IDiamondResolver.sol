//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import "./IMulticallable.sol";
import "../registry/ENS.sol";

interface IDiamondResolver is ISolidStateDiamond, IMulticallable {
  function ens() external view returns(ENS);
}