// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CLIENT_CHAINS_PRECOMPILE_ADDRESS, IClientChains} from "./interfaces/IClientChains.sol";

contract SampleContract {
    event EmitValue(uint32 value);

    constructor() {}

    function runWithStaticCallWithEvent() public returns (bool success, uint32[] memory) {
        (bool ok, bytes memory result) = address(CLIENT_CHAINS_PRECOMPILE_ADDRESS).staticcall(
            abi.encodeWithSelector(IClientChains.getClientChains.selector)
        );
        if (ok) {
            uint32[] memory res = abi.decode(result, (uint32[]));
            if (res.length > 0) {
                emit EmitValue(res[0]);
            }
            return (true, res);
        } else {
            return (false, new uint32[](0));
        }
    }

    function runWithStaticCallWithoutEvent() public view returns (bool success, uint32[] memory) {
        (bool ok, bytes memory result) = address(CLIENT_CHAINS_PRECOMPILE_ADDRESS).staticcall(
            abi.encodeWithSelector(IClientChains.getClientChains.selector)
        );
        if (ok) {
            uint32[] memory res = abi.decode(result, (uint32[]));
            return (true, res);
        } else {
            return (false, new uint32[](0));
        }
    }

    function runWithCallWithEvent() public returns (bool success, uint32[] memory) {
        (bool ok, bytes memory result) = address(CLIENT_CHAINS_PRECOMPILE_ADDRESS).call(
            abi.encodeWithSelector(IClientChains.getClientChains.selector)
        );
        if (ok) {
            uint32[] memory res = abi.decode(result, (uint32[]));
            if (res.length > 0) {
                emit EmitValue(res[0]);
            }
            return (true, res);
        } else {
            return (false, new uint32[](0));
        }
    }

    function runWithCallWithoutEvent() public returns (bool success, uint32[] memory) {
        (bool ok, bytes memory result) = address(CLIENT_CHAINS_PRECOMPILE_ADDRESS).call(
            abi.encodeWithSelector(IClientChains.getClientChains.selector)
        );
        if (ok) {
            uint32[] memory res = abi.decode(result, (uint32[]));
            return (true, res);
        } else {
            return (false, new uint32[](0));
        }
    }

}
