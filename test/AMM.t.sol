// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/amm/AMM.sol";
import "../src/token/AKToken.sol";

contract AMMTest is Test {
    AMM public amm;
    AKToken public token0;
    AKToken public token1;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        token0 = new AKToken(INITIAL_SUPPLY);
        token1 = new AKToken(INITIAL_SUPPLY);

        // Deploy AMM
        amm = new AMM(address(token0), address(token1));

        // Fund Alice and Bob
        token0.transfer(alice, 10_000 * 1e18);
        token1.transfer(alice, 10_000 * 1e18);
        token0.transfer(bob, 10_000 * 1e18);
        token1.transfer(bob, 10_000 * 1e18);
        vm.stopPrank();

        // Approvals
        vm.prank(alice);
        token0.approve(address(amm), type(uint256).max);
        vm.prank(alice);
        token1.approve(address(amm), type(uint256).max);

        vm.prank(bob);
        token0.approve(address(amm), type(uint256).max);
        vm.prank(bob);
        token1.approve(address(amm), type(uint256).max);
    }

    function test_InitialState() public view {
        assertEq(address(amm.token0()), address(token0));
        assertEq(address(amm.token1()), address(token1));
    }

    function test_AddLiquidity() public {
        uint256 amount0 = 1000 * 1e18;
        uint256 amount1 = 1000 * 1e18;

        // Alice funds the contract
        vm.startPrank(alice);
        token0.transfer(address(amm), amount0);
        token1.transfer(address(amm), amount1);

        // Alice mints LP tokens
        uint256 liquidity = amm.mint(alice);
        vm.stopPrank();

        // Verify reserves
        (uint112 reserve0, uint112 reserve1, ) = amm.getReserves();
        assertEq(reserve0, amount0);
        assertEq(reserve1, amount1);

        // Verify LP tokens minted
        // First mist locks MINIMUM_LIQUIDITY
        assertEq(liquidity, (amount0) - 1000);
        assertEq(amm.balanceOf(alice), liquidity);
    }

    function test_Swap() public {
        // 1. Setup Liquidity (1000 : 1000)
        uint256 amount0 = 1000 * 1e18;
        uint256 amount1 = 1000 * 1e18;

        vm.startPrank(alice);
        token0.transfer(address(amm), amount0);
        token1.transfer(address(amm), amount1);
        amm.mint(alice);
        vm.stopPrank();

        // 2. Bob swaps 10 Token0 -> Token1
        uint256 swapAmountIn = 10 * 1e18;

        vm.startPrank(bob);
        token0.transfer(address(amm), swapAmountIn);

        // Calculate expected output
        // (x + dx) * (y - dy) = k
        // y - dy = k / (x + dx)
        // dy = y - (k / (x + dx))
        // With 0.3% fee: amountInWithFee = amountIn * 997
        uint256 amountInWithFee = swapAmountIn * 997;
        uint256 numerator = amountInWithFee * amount1;
        uint256 denominator = (amount0 * 1000) + amountInWithFee;
        uint256 expectedOut = numerator / denominator;

        uint256 bobBalBefore = token1.balanceOf(bob);
        amm.swap(0, expectedOut, bob); // swap(amount0Out, amount1Out, to)
        uint256 bobBalAfter = token1.balanceOf(bob);

        assertEq(bobBalAfter - bobBalBefore, expectedOut);
    }

    function test_RemoveLiquidity() public {
        // 1. Setup Liquidity
        uint256 amount0 = 1000 * 1e18;
        uint256 amount1 = 1000 * 1e18;

        vm.startPrank(alice);
        token0.transfer(address(amm), amount0);
        token1.transfer(address(amm), amount1);
        uint256 liquidity = amm.mint(alice);

        // 2. Remove Liquidity
        amm.approve(address(amm), liquidity); // Approve burning
        amm.transfer(address(amm), liquidity); // Send LP to contract
        amm.burn(alice); // Burn

        // Assert almost all funds returned (minus MINIMUM_LIQUIDITY)
        uint256 aliceBal0 = token0.balanceOf(alice);
        // Initial 10000 - 1000 sent + ~1000 returned
        assertEq(aliceBal0, 10000 * 1e18 - 1000); // 1000 wei locked permanently
    }
}
