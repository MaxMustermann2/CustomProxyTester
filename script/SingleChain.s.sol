// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {SampleContract} from "../src/SampleContract.sol";
import {CLIENT_CHAINS_PRECOMPILE_ADDRESS} from "../src/interfaces/IClientChains.sol";

import "@layerzero-v2/protocol/contracts/libs/AddressCast.sol";

contract BaseScript is Script {
    using AddressCast for address;

    struct Player {
        uint256 privateKey;
        address addr;
    }

    Player exocoreDeployer;

    string exocoreRPCURL;

    uint32 constant EXOCORE_CHAIN_ID = 40259;

    uint256 exocoreChain;

    address constant endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    function setUp() public virtual {
        exocoreDeployer.privateKey = vm.envUint("EXOCORE_DEPLOYER_PRIVATE_KEY");
        require(exocoreDeployer.privateKey != 0, "EXOCORE_DEPLOYER_PRIVATE_KEY not set");
        exocoreDeployer.addr = vm.addr(exocoreDeployer.privateKey);

        exocoreRPCURL = vm.envString("EXOCORE_RPC_URL");
        require(bytes(exocoreRPCURL).length != 0, "EXOCORE_RPC_URL not set");

        exocoreChain = vm.createSelectFork(exocoreRPCURL);
    }

    function run() public {
        vm.selectFork(exocoreChain);
        vm.startBroadcast(exocoreDeployer.privateKey);
        SampleContract sampleContract = new SampleContract();

        bytes memory clientChainsMockCode = vm.getDeployedCode("ClientChainsMock.sol");
        vm.etch(CLIENT_CHAINS_PRECOMPILE_ADDRESS, clientChainsMockCode);
        (bool success, uint32[] memory res) = sampleContract.runWithCallWithEvent();
        vm.stopBroadcast();

        string memory exocoreContracts = "exocoreContracts";
        vm.serializeAddress(exocoreContracts, "sampleContract", address(sampleContract));
        string memory x;
        if (success) {
            vm.serializeBool(exocoreContracts, "success", true);
            x = vm.serializeUint(exocoreContracts, "res", uint256(res[0]));
        } else {
            x = vm.serializeBool(exocoreContracts, "success", false);
        }
        vm.writeJson(x, "script/singleChain.json");
    }
}