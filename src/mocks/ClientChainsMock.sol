pragma solidity >=0.8.17;

import {IClientChains} from "../interfaces/IClientChains.sol";

contract ClientChainsMock is IClientChains {
    function getClientChains() external pure returns (bool, uint16[] memory) {
        uint16[] memory chains = new uint16[](1);
        chains[0] = 40161;
        return (true, chains);
    }
}