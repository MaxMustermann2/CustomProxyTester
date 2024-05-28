// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OAppCoreUpgradeable} from "./lzApp/OAppCoreUpgradeable.sol";
import {
    OAppReceiverUpgradeable,
    OAppUpgradeable,
    Origin,
    MessagingFee,
    MessagingReceipt
} from "./lzApp/OAppUpgradeable.sol";
import {CommonStorage} from "./CommonStorage.sol";

import "@layerzero-v2/protocol/contracts/libs/AddressCast.sol";

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OptionsBuilder} from "@layerzero-v2/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {ILayerZeroReceiver} from "@layerzero-v2/protocol/contracts/interfaces/ILayerZeroReceiver.sol";

import {CLIENT_CHAINS_PRECOMPILE_ADDRESS, IClientChains} from "./interfaces/IClientChains.sol";

contract Upgrader is Initializable, OwnableUpgradeable, OAppUpgradeable {
    event MessageSent(CommonStorage.Action indexed act, bytes32 packetId, uint64 nonce, uint256 nativeFee);
    mapping(uint32 eid => mapping(bytes32 sender => uint64 nonce)) public inboundNonce;

    uint128 public constant DESTINATION_GAS_LIMIT = 500000;
    uint128 public constant DESTINATION_MSG_VALUE = 0;

    using OptionsBuilder for bytes;
    using AddressCast for address;

    constructor(address _endpoint) OAppUpgradeable(_endpoint) {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init_unchained(owner);
    }

    function upgradeOnOtherChain() public payable {
        (bool success, bytes memory result) = CLIENT_CHAINS_PRECOMPILE_ADDRESS.staticcall(
            abi.encodeWithSelector(IClientChains.getClientChains.selector)
        );
        require(success, "Upgrader: failed to get client chain ids");
        (bool ok, uint16[] memory clientChainIds) = abi.decode(result, (bool, uint16[]));
        require(ok, "Upgrader: failed to decode client chain ids");
        for (uint256 i = 0; i < clientChainIds.length; i++) {
            uint16 sepoliaChainId = clientChainIds[i];
            _sendInterchainMsg(uint32(sepoliaChainId), CommonStorage.Action.UPGRADE, "");
        }
    }

    receive() external payable {}

    function _sendInterchainMsg(uint32 srcChainId, CommonStorage.Action act, bytes memory actionArgs) internal {
        bytes memory payload = abi.encodePacked(act, actionArgs);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(
            DESTINATION_GAS_LIMIT, DESTINATION_MSG_VALUE
        ).addExecutorOrderedExecutionOption();
        MessagingFee memory fee = _quote(srcChainId, payload, options, false);

        MessagingReceipt memory receipt =
            _lzSend(srcChainId, payload, options, MessagingFee(fee.nativeFee, 0), address(this), true);
        emit MessageSent(act, receipt.guid, receipt.nonce, receipt.fee.nativeFee);
    }

    function quote(uint32 srcChainid, bytes memory _message) public view returns (uint256 nativeFee) {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(
            DESTINATION_GAS_LIMIT, DESTINATION_MSG_VALUE
        ).addExecutorOrderedExecutionOption();
        MessagingFee memory fee = _quote(srcChainid, _message, options, false);
        return fee.nativeFee;
    }

    function nextNonce(uint32 srcEid, bytes32 sender)
        public
        view
        virtual
        override(OAppReceiverUpgradeable)
        returns (uint64)
    {
        return inboundNonce[srcEid][sender] + 1;
    }

    function _consumeInboundNonce(uint32 srcEid, bytes32 sender, uint64 nonce) internal {
        inboundNonce[srcEid][sender] += 1;
        require(nonce == inboundNonce[srcEid][sender], "Upgrader: invalid nonce");
    }

    function _lzReceive(
        Origin calldata, bytes calldata
    ) internal virtual override {
        revert("Upgrader: invalid action");
    }
}