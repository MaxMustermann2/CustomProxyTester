// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CommonStorage {
    enum Action {
        UPGRADE
    }

    uint32 public immutable exocoreChainId;
    constructor(uint32 _exocoreChainId) {
        exocoreChainId = _exocoreChainId;
    }

    uint256 public number;
    bool public upgraded;
    uint256 public secondNumber;

    mapping(Action => bytes4) public whiteListFunctionSelectors;
    mapping(uint32 eid => mapping(bytes32 sender => uint64 nonce)) public inboundNonce;

    address public customProxyAdmin;
    address public newImplementation;
    bytes public data;
}