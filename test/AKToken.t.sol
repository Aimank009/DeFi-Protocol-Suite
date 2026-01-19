// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/token/AKToken.sol";

contract AKTokenTest is Test {
    AKToken public token;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 public constant CAP = 100_000_000 * 1e18;

    event TokensMinted(address indexed _to, uint256 _amount);
    event TokensBurned(address indexed _from, uint256 _amount);
    event ContractPaused(address indexed _by);
    event ContractUnpaused(address indexed _by);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.prank(owner);
        token = new AKToken(INITIAL_SUPPLY);
    }

    function test_InitialState() public view {
        assertEq(token.name(), "AKToken");
        assertEq(token.symbol(), "AKT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.cap(), CAP);
    }

    function test_OwnerHasAllRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(token.hasRole(token.MINTER_ROLE(), owner));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), owner));
    }

    function test_Transfer() public {
        uint256 amount = 1000 * 1e18;

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function test_Approve_And_TransferFrom() public {
        uint256 amount = 500 * 1e18;

        vm.prank(owner);
        token.approve(alice, amount);

        assertEq(token.allowance(owner, alice), amount);

        vm.prank(alice);
        token.transferFrom(owner, bob, amount);

        assertEq(token.balanceOf(bob), amount);
    }

    function test_Mint_Success() public {
        uint256 mintAmount = 5000 * 1e18;

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(alice, mintAmount);
        token.mint(alice, mintAmount);

        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_Mint_RevertWithoutRole() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, 1000 * 1e18);
    }

    function test_Burn_Success() public {
        uint256 burnAmount = 1000 * 1e18;

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokensBurned(owner, burnAmount);
        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    function test_BurnFrom() public {
        uint256 burnAmount = 500 * 1e18;

        vm.prank(owner);
        token.approve(alice, burnAmount);

        vm.prank(alice);
        token.burnFrom(owner, burnAmount);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
    }

    function test_Pause_Success() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit ContractPaused(owner);
        token.pause();

        assertTrue(token.paused());
    }

    function test_Pause_RevertWithoutRole() public {
        vm.prank(alice);
        vm.expectRevert();
        token.pause();
    }

    function test_Transfer_RevertsWhenPaused() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        vm.expectRevert();
        token.transfer(alice, 100 * 1e18);
    }

    function test_Unpause_Success() public {
        vm.startPrank(owner);
        token.pause();

        vm.expectEmit(true, false, false, false);
        emit ContractUnpaused(owner);
        token.unpause();
        vm.stopPrank();

        assertFalse(token.paused());
    }

    function test_Transfer_WorksAfterUnpause() public {
        vm.startPrank(owner);
        token.pause();
        token.unpause();
        token.transfer(alice, 100 * 1e18);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 100 * 1e18);
    }

    function test_Cap_CannotExceed() public {
        uint256 mintToMax = CAP - INITIAL_SUPPLY;

        vm.prank(owner);
        token.mint(alice, mintToMax);

        vm.prank(owner);
        vm.expectRevert();
        token.mint(alice, 1);
    }

    function test_FlashFee() public view {
        uint256 amount = 10000 * 1e18;
        uint256 expectedFee = (amount * 10) / 10000;

        assertEq(token.flashFee(address(token), amount), expectedFee);
    }

    function test_GrantRole() public {
        bytes32 minterRole = token.MINTER_ROLE();

        vm.prank(owner);
        token.grantRole(minterRole, alice);

        assertTrue(token.hasRole(minterRole, alice));

        vm.prank(alice);
        token.mint(bob, 1000 * 1e18);

        assertEq(token.balanceOf(bob), 1000 * 1e18);
    }

    function test_RevokeRole() public {
        vm.startPrank(owner);
        token.grantRole(token.MINTER_ROLE(), alice);
        token.revokeRole(token.MINTER_ROLE(), alice);
        vm.stopPrank();

        assertFalse(token.hasRole(token.MINTER_ROLE(), alice));
    }

    function test_Delegate_VotingPower() public {
        vm.prank(owner);
        token.transfer(alice, 1000 * 1e18);

        vm.prank(alice);
        token.delegate(alice);

        assertEq(token.getVotes(alice), 1000 * 1e18);
    }

    function test_Delegate_ToOther() public {
        vm.prank(owner);
        token.transfer(alice, 1000 * 1e18);

        vm.prank(alice);
        token.delegate(bob);

        assertEq(token.getVotes(bob), 1000 * 1e18);
        assertEq(token.getVotes(alice), 0);
    }

    function test_Nonces() public view {
        assertEq(token.nonces(alice), 0);
    }

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_Mint(uint256 amount) public {
        uint256 maxMint = CAP - INITIAL_SUPPLY;
        amount = bound(amount, 1, maxMint);

        vm.prank(owner);
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }
}
