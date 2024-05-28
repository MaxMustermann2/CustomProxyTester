// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {CustomProxyAdmin} from "../src/CustomProxyAdmin.sol";
import {Counter as ImplementationOne} from "../src/ImplementationOne.sol";
import {Counter as ImplementationTwo} from "../src/ImplementationTwo.sol";
import {Upgrader} from "../src/Upgrader.sol";
import {CLIENT_CHAINS_PRECOMPILE_ADDRESS} from "../src/interfaces/IClientChains.sol";

import "@layerzero-v2/protocol/contracts/libs/AddressCast.sol";

contract BaseScript is Script {
    using AddressCast for address;

    struct Player {
        uint256 privateKey;
        address addr;
    }

    Player sepoliaDeployer;
    Player exocoreDeployer;

    string sepoliaRPCURL;
    string exocoreRPCURL;

    uint32 constant SEPOLIA_CHAIN_ID = 40161;
    uint32 constant EXOCORE_CHAIN_ID = 40259;

    uint256 sepoliaChain;
    uint256 exocoreChain;

    address constant endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    function setUp() public virtual {
        sepoliaDeployer.privateKey = vm.envUint("SEPOLIA_DEPLOYER_PRIVATE_KEY");
        require(sepoliaDeployer.privateKey != 0, "SEPOLIA_DEPLOYER_PRIVATE_KEY not set");
        sepoliaDeployer.addr = vm.addr(sepoliaDeployer.privateKey);

        exocoreDeployer.privateKey = vm.envUint("EXOCORE_DEPLOYER_PRIVATE_KEY");
        require(exocoreDeployer.privateKey != 0, "EXOCORE_DEPLOYER_PRIVATE_KEY not set");
        exocoreDeployer.addr = vm.addr(exocoreDeployer.privateKey);

        sepoliaRPCURL = vm.envString("SEPOLIA_RPC_URL");
        require(bytes(sepoliaRPCURL).length != 0, "SEPOLIA_RPC_URL not set");
        exocoreRPCURL = vm.envString("EXOCORE_RPC_URL");
        require(bytes(exocoreRPCURL).length != 0, "EXOCORE_RPC_URL not set");

        sepoliaChain = vm.createSelectFork(sepoliaRPCURL);
        exocoreChain = vm.createSelectFork(exocoreRPCURL);
    }

    function run() public {
        vm.selectFork(sepoliaChain);
        vm.startBroadcast(sepoliaDeployer.privateKey);

        CustomProxyAdmin proxyAdmin = new CustomProxyAdmin();
        ImplementationOne logicOne = new ImplementationOne(
            EXOCORE_CHAIN_ID, endpoint
        );
        ImplementationTwo logicTwo = new ImplementationTwo(
            EXOCORE_CHAIN_ID, endpoint
        );

        bytes memory data = abi.encodeWithSelector(
            logicTwo.initialize.selector, 11, sepoliaDeployer.addr
        );

        ImplementationOne proxy = ImplementationOne(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(logicOne), address(proxyAdmin),
                        abi.encodeWithSelector(
                            logicOne.initialize.selector,
                            5, sepoliaDeployer.addr,
                            address(proxyAdmin), address(logicTwo), data
                        )
                    )
                )
            )
        );

        proxyAdmin.setSelfUpgradingProxy(address(proxy));
        vm.stopBroadcast();

        vm.selectFork(exocoreChain);
        vm.startBroadcast(exocoreDeployer.privateKey);
        ProxyAdmin exocoreProxyAdmin = new ProxyAdmin(exocoreDeployer.addr);
        Upgrader upgraderLogic = new Upgrader(endpoint);
        Upgrader upgrader = Upgrader(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(upgraderLogic), address(exocoreProxyAdmin),
                        abi.encodeWithSelector(
                            upgraderLogic.initialize.selector,
                            exocoreDeployer.addr
                        )
                    )
                )
            )
        );
        upgrader.setPeer(SEPOLIA_CHAIN_ID, address(proxy).toBytes32());
        vm.stopBroadcast();

        vm.selectFork(sepoliaChain);
        vm.startBroadcast(sepoliaDeployer.privateKey);
        proxy.setPeer(EXOCORE_CHAIN_ID, address(upgrader).toBytes32());
        vm.stopBroadcast();

        vm.selectFork(exocoreChain);
        vm.startBroadcast(exocoreDeployer.privateKey);
        bytes memory clientChainsMockCode = vm.getDeployedCode("ClientChainsMock.sol");
        vm.etch(CLIENT_CHAINS_PRECOMPILE_ADDRESS, clientChainsMockCode);
        require(exocoreDeployer.addr.balance > 1 ether, "Insufficient balance");
        upgrader.upgradeOnOtherChain{value: 1 ether}();
        vm.stopBroadcast();

        string memory deployedContracts = "deployedContracts";
        string memory sepoliaContracts = "sepoliaContracts";
        string memory exocoreContracts = "exocoreContracts";
        vm.serializeAddress(sepoliaContracts, "customProxyAdmin", address(proxyAdmin));
        vm.serializeAddress(sepoliaContracts, "logicOne", address(logicOne));
        vm.serializeAddress(sepoliaContracts, "logicTwo", address(logicTwo));
        string memory sepoliaContractsOutput = vm.serializeAddress(sepoliaContracts, "proxy", address(proxy));

        vm.serializeAddress(exocoreContracts, "proxyAdmin", address(exocoreProxyAdmin));
        vm.serializeAddress(exocoreContracts, "upgraderLogic", address(upgraderLogic));
        string memory exocoreContractsOutput = vm.serializeAddress(exocoreContracts, "upgrader", address(upgrader));

        vm.serializeString(deployedContracts, "sepolia", sepoliaContractsOutput);
        string memory res = vm.serializeString(deployedContracts, "exocore", exocoreContractsOutput);
        vm.writeJson(res, "script/deployedContracts.json");
    }
}