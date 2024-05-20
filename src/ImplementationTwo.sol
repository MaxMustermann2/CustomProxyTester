// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {CommonStorage} from "./CommonStorage.sol";

// OOPS: we forgot the `decrement` function, which will be added in ImplementationTwo.
contract Counter is Initializable, CommonStorage {
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _secondNumber) public reinitializer(2) {
        upgraded = true;
        secondNumber = _secondNumber;
        customProxyAdmin = address(0);
        newImplementation = address(0);
        data = "";
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }
}