pragma solidity ^0.8.19;

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// This contract is not upgradeable intentionally, since doing so would produce a lot of risk.
contract CustomProxyAdmin is ProxyAdmin {
    address public selfUpgradingProxy;

    constructor() ProxyAdmin(msg.sender) {}

    function setSelfUpgradingProxy(address proxy) public {
        require(
            selfUpgradingProxy == address(0),
            "CustomProxyAdmin: selfUpgradingProxy already set"
        );
        require(
            proxy != address(0),
            "CustomProxyAdmin: selfUpgradingProxy cannot be the zero address"
        );
        selfUpgradingProxy = proxy;
    }

    function changeImplementation(
        address proxy,
        address implementation,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == selfUpgradingProxy,
            "CustomProxyAdmin: sender must be the selfUpgradingProxy"
        );
        require(
            msg.sender == proxy,
            "CustomProxyAdmin: sender must be the proxy itself"
        );
        ITransparentUpgradeableProxy(proxy).upgradeToAndCall(implementation, data);
        // clear the selfUpgradeableProxy after the upgrade to prevent further upgrades
        selfUpgradingProxy = address(0);
    }
}