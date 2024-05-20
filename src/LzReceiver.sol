// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CommonStorage} from "./CommonStorage.sol";
import {OAppReceiverUpgradeable, Origin} from "./lzApp/OAppReceiverUpgradeable.sol";
import {OAppCoreUpgradeable} from "./lzApp/OAppCoreUpgradeable.sol";

contract LzReceiver is Initializable, CommonStorage, OAppReceiverUpgradeable {
    constructor(
        uint32 _exocoreChainId,
        address _endpoint
    ) CommonStorage(_exocoreChainId) OAppCoreUpgradeable(_endpoint) {
        _disableInitializers();
    }

    function _lzReceive(
        Origin calldata _origin, bytes calldata payload
    ) internal virtual override {
        require(
            _origin.srcEid == exocoreChainId,
            "Counter: invalid srcEid"
        );
        _consumeInboundNonce(
            _origin.srcEid, _origin.sender, _origin.nonce
        );
        Action act = Action(
            uint8(
                payload[0]
                )
            );
        require(
            act == Action.UPGRADE,
            "Counter: invalid action"
        );
        bytes4 selector_ = whiteListFunctionSelectors[act];
        require(
            selector_ != bytes4(0),
            "Counter: invalid selector"
        );
        (bool success, bytes memory reason) =
            address(this).call(
                abi.encodePacked(
                    selector_,
                    abi.encode(
                        payload[1:]
                    )
                )
            );
        require(
            success,
            string(reason)
        );
    }

    function _consumeInboundNonce(
        uint32 srcEid, bytes32 sender, uint64 nonce
    ) internal {
        inboundNonce[srcEid][sender] += 1;
        require(nonce == inboundNonce[srcEid][sender], "Counter: invalid nonce");
    }
}