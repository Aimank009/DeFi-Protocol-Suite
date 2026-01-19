// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract StakingEvents {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 penalty);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event LockDurationUpdated(uint256 newDuration);
    event EarlyWithdrawFeeUpdated(uint256 newFee);
    event TreasuryUpdated(address newTreasury);
}
