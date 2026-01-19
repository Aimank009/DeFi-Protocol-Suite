// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626, AccessControl, Pausable {
    constructor(IERC20 _asset) ERC4626(_asset) ERC20("VaultAKToken", "vAKT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }
    function unPause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function deposit(
        uint256 _assets,
        address _receiver
    ) public override whenNotPaused returns (uint256) {
        return super.deposit(_assets, _receiver);
    }
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) public override whenNotPaused returns (uint256) {
        return super.withdraw(_assets, _receiver, _owner);
    }

    function mint(
        uint256 _shares,
        address _receiver
    ) public override whenNotPaused returns (uint256) {
        return super.mint(_shares, _receiver);
    }

    function redeem(
        uint256 _assets,
        address _receiver,
        address _owner
    ) public override whenNotPaused returns (uint256) {
        return super.redeem(_assets, _receiver, _owner);
    }
}
