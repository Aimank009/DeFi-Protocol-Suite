// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract AKTokenEvents {
    event TokensMinted(address indexed _to, uint256 _amount);
    event TokensBurned(address indexed _from, uint256 _amount);
    event ContractPaused(address indexed _by);
    event ContractUnpaused(address indexed _by);
}
