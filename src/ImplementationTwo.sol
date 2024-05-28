// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {LzReceiver} from "./LzReceiver.sol";

// OOPS: we forgot the `decrement` function, which will be added in ImplementationTwo.
contract Counter is Initializable, OwnableUpgradeable, LzReceiver {
    constructor(
        uint32 _exocoreChainId, address _endpoint
    ) LzReceiver(_exocoreChainId, _endpoint) {
        _disableInitializers();
    }

    function initialize(uint256 _secondNumber, address _owner) public reinitializer(2) {
        // make no edits to inboundNonce, so that this address can still
        // receive messages from the Exocore network
        upgraded = true;
        secondNumber = _secondNumber;
        // allow no more upgrades
        delete whiteListFunctionSelectors[Action.UPGRADE];
        delete customProxyAdmin;
        delete newImplementation;
        delete data;
        __Ownable_init_unchained(_owner);
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }
}