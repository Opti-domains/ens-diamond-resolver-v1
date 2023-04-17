//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import {ENS} from "../registry/ENS.sol";
import {INameWrapper} from "../wrapper/INameWrapper.sol";

interface INameWrapperRegistry {
  function ens() external view returns(ENS);
  function forward(INameWrapper wrapper) external view returns(INameWrapper);
  function backward(INameWrapper wrapper) external view returns(INameWrapper);
  function isNameWrapper(address wrapper) external view returns(bool);

  function upgrade(INameWrapper _old, INameWrapper _new) external;
}

interface IHasNameWrapperRegistry {
  function registry() external view returns(INameWrapperRegistry);
}