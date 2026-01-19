// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../events/AKTokenEvents.sol";

contract AKToken is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Permit,
    ERC20Votes,
    ERC20Capped,
    ERC20FlashMint,
    AccessControl,
    AKTokenEvents
{
    address public owner;
    uint256 public initialSupply;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant FLASH_LOAN_FEE = 10;

    constructor(
        uint256 _initialSupply
    )
        ERC20("AKToken", "AKT")
        ERC20Capped(100_000_000 * 1e18)
        ERC20Permit("AKToken")
    {
        owner = msg.sender;
        initialSupply = _initialSupply;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal override(ERC20, ERC20Capped, ERC20Pausable, ERC20Votes) {
        super._update(_from, _to, _value);
    }

    function nonces(
        address _owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(_owner);
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);

        emit TokensMinted(_to, _amount);
    }

    function burn(uint256 _amount) public override {
        super.burn(_amount);

        emit TokensBurned(msg.sender, _amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();

        emit ContractPaused(msg.sender);
    }
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();

        emit ContractUnpaused(msg.sender);
    }
    function _flashFee(
        address,
        uint256 _amount
    ) internal pure override returns (uint256) {
        uint256 flashFee = (_amount * FLASH_LOAN_FEE) / 10000;
        return flashFee;
    }
}
