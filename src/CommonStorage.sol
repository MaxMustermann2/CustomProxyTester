// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CommonStorage {
    uint256 public number;
    bool public upgraded;
    uint256 public secondNumber;

    address public customProxyAdmin;
    address public newImplementation;
    bytes public data;
}