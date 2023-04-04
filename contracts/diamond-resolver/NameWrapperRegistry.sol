//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@solidstate/contracts/interfaces/IERC165.sol";
import "./INameWrapperRegistry.sol";

contract NameWrapperRegistry is INameWrapperRegistry, Ownable, IERC165 {
    ENS public immutable ens;
    INameWrapper public nameWrapper;
    mapping(INameWrapper => INameWrapper) public forward;
    mapping(INameWrapper => INameWrapper) public backward;

    constructor(ENS _ens, INameWrapper _nameWrapper) {
        ens = _ens;
        nameWrapper = _nameWrapper;
    }

    event NameWrapperUpgraded(
        address indexed oldNameWrapper,
        address indexed newNameWrapper
    );

    function upgrade(INameWrapper _old, INameWrapper _new) external onlyOwner {
        require(isNameWrapper(address(_old)), "Old Not NameWrapper");
        require(
            _new.supportsInterface(type(INameWrapper).interfaceId),
            "New Not NameWrapper"
        );

        if (_old == nameWrapper || forward[_old] == nameWrapper) {
            nameWrapper = _new;
        }

        if (forward[_old] != INameWrapper(address(0))) {
            delete forward[forward[_old]];
            delete backward[forward[_old]];
        }

        forward[_old] = _new;
        backward[_new] = _old;

        emit NameWrapperUpgraded(address(_old), address(_new));
    }

    function isNameWrapper(address wrapper) public view returns (bool) {
        return
            INameWrapper(wrapper).supportsInterface(type(INameWrapper).interfaceId) &&
            (wrapper == address(nameWrapper) ||
                forward[INameWrapper(wrapper)] != INameWrapper(address(0)));
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override(IERC165) returns (bool) {
        return interfaceID == type(INameWrapperRegistry).interfaceId;
    }
}
