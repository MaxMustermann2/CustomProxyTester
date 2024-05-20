// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {CommonStorage} from "./CommonStorage.sol";
import {CustomProxyAdmin} from "./CustomProxyAdmin.sol";

import {OAppReceiverUpgradeable, Origin} from "./lzApp/OAppReceiverUpgradeable.sol";

contract Counter is Initializable, CommonStorage, OAppReceiverUpgradeable {
    modifier onlyCalledFromThis() {
        require(
            msg.sender == address(this),
            "Counter: could only be called from this contract itself with low level call"
        );
        _;
    }

    constructor() {
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
        // OOPS, we forgot to initialize `secondNumber` in ImplementationOne.
        secondNumber = 0;
    }

    function increment() public {
        number++;
    }

    // OOPS: we forgot the `decrement` function, which will be added in ImplementationTwo.

    function upgrade() public onlyCalledFromThis {
        CustomProxyAdmin(customProxyAdmin).changeImplementation(
            address(this), newImplementation, data
        );
    }

    function _lzReceive(
        Origin calldata _origin, bytes calldata payload
    ) internal virtual override {
        if (_origin.srcEid != exocoreChainId) {
            revert UnexpectedSourceChain(_origin.srcEid);
        }
        _consumeInboundNonce(_origin.srcEid, _origin.sender, _origin.nonce);
        Action act = Action(uint8(payload[0]));
        require(act != Action.RESPOND, "BootstrapLzReceiver: invalid action");
        bytes4 selector_ = _whiteListFunctionSelectors[act];
        if (selector_ == bytes4(0)) {
            revert UnsupportedRequest(act);
        }
        (bool success, bytes memory reason) =
            address(this).call(abi.encodePacked(selector_, abi.encode(payload[1:])));
        if (!success) {
            revert RequestOrResponseExecuteFailed(act, _origin.nonce, reason);
        }
    }
}