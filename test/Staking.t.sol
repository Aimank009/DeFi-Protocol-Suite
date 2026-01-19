// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/staking/Staking.sol";
import "../src/token/AKToken.sol";

contract StakingTest is Test {
    Staking public staking;
    AKToken public stakingToken;
    AKToken public rewardsToken;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 public constant REWARD_AMOUNT = 7000 * 1e18;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 penalty);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        stakingToken = new AKToken(INITIAL_SUPPLY);
        rewardsToken = new AKToken(INITIAL_SUPPLY);
        staking = new Staking(address(stakingToken), address(rewardsToken));

        stakingToken.transfer(alice, 10000 * 1e18);
        stakingToken.transfer(bob, 10000 * 1e18);

        rewardsToken.approve(address(staking), type(uint256).max);
        vm.stopPrank();

        vm.prank(alice);
        stakingToken.approve(address(staking), type(uint256).max);

        vm.prank(bob);
        stakingToken.approve(address(staking), type(uint256).max);
    }

    function test_InitialState() public view {
        assertEq(address(staking.stakingToken()), address(stakingToken));
        assertEq(address(staking.rewardsToken()), address(rewardsToken));
        assertEq(staking.treasury(), owner);
        assertEq(staking.lockDuration(), 7 days);
        assertEq(staking.earlyWithdrawFee(), 1000);
    }

    function test_Stake() public {
        uint256 amount = 100 * 1e18;

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Staked(alice, amount);
        staking.stake(amount);

        (uint256 userAmount, , , ) = staking.userInfo(alice);
        assertEq(userAmount, amount);
        assertEq(staking.totalSupply(), amount);
    }

    function test_Stake_RevertBelowMinimum() public {
        vm.prank(alice);
        vm.expectRevert();
        staking.stake(0.5 * 1e18);
    }

    function test_Withdraw_AfterLockPeriod() public {
        uint256 amount = 100 * 1e18;

        vm.prank(alice);
        staking.stake(amount);

        vm.warp(block.timestamp + 8 days);

        uint256 balanceBefore = stakingToken.balanceOf(alice);

        vm.prank(alice);
        staking.withdraw(amount);

        uint256 balanceAfter = stakingToken.balanceOf(alice);
        assertEq(balanceAfter - balanceBefore, amount);
    }

    function test_Withdraw_EarlyWithPenalty() public {
        uint256 amount = 100 * 1e18;

        vm.prank(alice);
        staking.stake(amount);

        vm.warp(block.timestamp + 3 days);

        uint256 treasuryBefore = stakingToken.balanceOf(owner);
        uint256 aliceBefore = stakingToken.balanceOf(alice);

        vm.prank(alice);
        staking.withdraw(amount);

        uint256 penalty = (amount * 1000) / 10000;
        uint256 aliceAfter = stakingToken.balanceOf(alice);
        uint256 treasuryAfter = stakingToken.balanceOf(owner);

        assertEq(aliceAfter - aliceBefore, amount - penalty);
        assertEq(treasuryAfter - treasuryBefore, penalty);
    }

    function test_GetReward() public {
        vm.prank(owner);
        staking.notifyRewardAmount(REWARD_AMOUNT);

        vm.prank(alice);
        staking.stake(100 * 1e18);

        vm.warp(block.timestamp + 1 days);

        uint256 earnedBefore = staking.earned(alice);
        assertTrue(earnedBefore > 0);

        uint256 balanceBefore = rewardsToken.balanceOf(alice);

        vm.prank(alice);
        staking.getReward();

        uint256 balanceAfter = rewardsToken.balanceOf(alice);
        assertTrue(balanceAfter > balanceBefore);
    }

    function test_Exit() public {
        vm.prank(owner);
        staking.notifyRewardAmount(REWARD_AMOUNT);

        vm.prank(alice);
        staking.stake(100 * 1e18);

        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        staking.exit();

        (uint256 userAmount, , , ) = staking.userInfo(alice);
        assertEq(userAmount, 0);
    }

    function test_NotifyRewardAmount() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RewardAdded(REWARD_AMOUNT);
        staking.notifyRewardAmount(REWARD_AMOUNT);

        assertTrue(staking.rewardRate() > 0);
        assertEq(staking.periodFinish(), block.timestamp + 7 days);
    }

    function test_Pause() public {
        vm.prank(owner);
        staking.pause();

        vm.prank(alice);
        vm.expectRevert();
        staking.stake(100 * 1e18);
    }

    function test_SetLockDuration() public {
        vm.prank(owner);
        staking.setLockDuration(14 days);

        assertEq(staking.lockDuration(), 14 days);
    }

    function test_SetEarlyWithdrawFee() public {
        vm.prank(owner);
        staking.setEarlyWithdrawFee(500);

        assertEq(staking.earlyWithdrawFee(), 500);
    }

    function test_SetTreasury() public {
        address newTreasury = makeAddr("treasury");

        vm.prank(owner);
        staking.setTreasury(newTreasury);

        assertEq(staking.treasury(), newTreasury);
    }

    function test_RewardDistribution_MultipleStakers() public {
        vm.prank(owner);
        staking.notifyRewardAmount(REWARD_AMOUNT);

        vm.prank(alice);
        staking.stake(100 * 1e18);

        vm.warp(block.timestamp + 1 days);

        vm.prank(bob);
        staking.stake(100 * 1e18);

        vm.warp(block.timestamp + 1 days);

        uint256 aliceEarned = staking.earned(alice);
        uint256 bobEarned = staking.earned(bob);

        assertTrue(aliceEarned > bobEarned);
    }

    function testFuzz_Stake(uint256 amount) public {
        amount = bound(amount, 1e18, 1000 * 1e18);

        vm.prank(alice);
        staking.stake(amount);

        (uint256 userAmount, , , ) = staking.userInfo(alice);
        assertEq(userAmount, amount);
    }
}
