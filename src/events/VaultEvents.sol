// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VaultEvents {
    event VaultPaused(address indexed _by);
    event VaultUnpaused(address indexed _by);
}
