// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {LzReceiver} from "./LzReceiver.sol";
import {CustomProxyAdmin} from "./CustomProxyAdmin.sol";

contract Counter is Initializable, LzReceiver {
    modifier onlyCalledFromThis() {
        require(
            msg.sender == address(this),
            "Counter: could only be called from this contract itself with low level call"
        );
        _;
    }

    constructor(
        uint32 _exocoreChainId, address _endpoint
    ) LzReceiver(_exocoreChainId, _endpoint) {
        _disableInitializers();
    }

    function initialize(
        uint256 _number,
        address _customProxyAdmin,
        address _newImplementation,
        bytes calldata _data
    ) public initializer {
        number = _number;
        upgraded = false;
        customProxyAdmin = _customProxyAdmin;
        newImplementation = _newImplementation;
        data = _data;
        // We did not initialize `secondNumber` in ImplementationOne.
        secondNumber = 0;
        whiteListFunctionSelectors[Action.UPGRADE] = this.upgrade.selector;
    }

    function increment() public {
        number++;
    }

    // We didn't add the `decrement` function, which will be added in ImplementationTwo.
    // We will let the contract upgrade itself to ImplementationTwo.

    function upgrade() public onlyCalledFromThis {
        CustomProxyAdmin(customProxyAdmin).changeImplementation(
            address(this), newImplementation, data
        );
    }

}