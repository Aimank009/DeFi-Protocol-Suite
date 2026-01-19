// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/vault/Vault.sol";
import "../src/token/AKToken.sol";

contract VaultTest is Test {
    Vault public vault;
    AKToken public token;

    address public owner;
    address public alice;
    address public bob;

    event VaultPaused(address indexed _by);
    event VaultUnpaused(address indexed _by);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        token = new AKToken(1_000_000 * 1e18);
        vault = new Vault(token);

        token.transfer(alice, 1000 * 1e18);
        token.transfer(bob, 1000 * 1e18);
        vm.stopPrank();

        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        token.approve(address(vault), type(uint256).max);
    }

    function test_InitialState() public view {
        assertEq(vault.asset(), address(token));
        assertEq(vault.name(), "VaultAKToken");
        assertEq(vault.symbol(), "vAKT");
        assertEq(vault.totalAssets(), 0);
    }

    function test_Deposit() public {
        uint256 amount = 100 * 1e18;

        vm.prank(alice);
        uint256 shares = vault.deposit(amount, alice);

        assertEq(shares, amount); // 1:1 ratio initially
        assertEq(vault.balanceOf(alice), amount);
        assertEq(vault.totalAssets(), amount);
        assertEq(token.balanceOf(address(vault)), amount);
    }

    function test_Withdraw() public {
        uint256 amount = 100 * 1e18;

        vm.startPrank(alice);
        vault.deposit(amount, alice);

        uint256 assets = vault.withdraw(amount, alice, alice);
        vm.stopPrank();

        assertEq(assets, amount);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function test_Mint() public {
        uint256 shares = 100 * 1e18;

        vm.prank(alice);
        uint256 assets = vault.mint(shares, alice);

        assertEq(assets, shares);
        assertEq(vault.balanceOf(alice), shares);
    }

    function test_Redeem() public {
        uint256 amount = 100 * 1e18;

        vm.startPrank(alice);
        vault.deposit(amount, alice);

        uint256 assets = vault.redeem(amount, alice, alice);
        vm.stopPrank();

        assertEq(assets, amount);
        assertEq(vault.balanceOf(alice), 0);
    }

    function test_YieldAccumulation() public {
        vm.prank(alice);
        vault.deposit(100 * 1e18, alice);

        vm.prank(owner);
        token.transfer(address(vault), 10 * 1e18);

        // Bob deposits - gets fewer shares
        vm.prank(bob);
        uint256 bobShares = vault.deposit(110 * 1e18, bob);

        // Formula: shares = assets * totalSupply / totalAssets
        // shares = 110 * 100 / 110 = 100
        assertEq(bobShares, 100 * 1e18);
    }

    function test_Pause_Success() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit VaultPaused(owner);
        vault.pause();

        assertTrue(vault.paused());
    }

    function test_Deposit_RevertWhenPaused() public {
        vm.prank(owner);
        vault.pause();

        vm.prank(alice);
        vm.expectRevert();
        vault.deposit(100 * 1e18, alice);
    }

    function test_Withdraw_RevertWhenPaused() public {
        vm.prank(alice);
        vault.deposit(100 * 1e18, alice);

        vm.prank(owner);
        vault.pause();

        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(100 * 1e18, alice, alice);
    }

    function test_Unpause_Success() public {
        vm.startPrank(owner);
        vault.pause();

        vm.expectEmit(true, false, false, false);
        emit VaultUnpaused(owner);
        vault.unpause();
        vm.stopPrank();

        assertFalse(vault.paused());
    }
}
