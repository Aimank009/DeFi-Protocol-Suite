// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Staking is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;
    IERC20 public rewardsToken;

    uint256 public rewardRate;
    uint256 public rewardsDuration = 7 days;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public accRewardPerToken;
    uint256 public totalSupply;

    uint256 public lockDuration = 7 days;
    uint256 public earlyWithdrawFee = 1000;
    uint256 public minStakeAmount = 1e18;

    struct UserInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardPerTokenPaid;
        uint256 unclaimedRewards;
    }

    mapping(address => UserInfo) public userInfo;

    error InvalidAddress();

    constructor(address _stakingToken, address _rewardsToken) {
        if (_stakingToken == address(0)) revert InvalidAddress();
        if (_rewardsToken == address(0)) revert InvalidAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }
}
