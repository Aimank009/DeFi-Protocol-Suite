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

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return accRewardPerToken;

        return
            accRewardPerToken +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalSupply);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function earned(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return
            ((user.amount * (rewardPerToken() - user.rewardPerTokenPaid)) /
                1e18) + user.unclaimedRewards;
    }

    modifier updateReward(address _user) {
        accRewardPerToken = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            userInfo[_user].unclaimedRewards = earned(_user);
            userInfo[_user].rewardPerTokenPaid = accRewardPerToken;
        }
        _;
    }
}
