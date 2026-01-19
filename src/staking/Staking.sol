// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../events/StakingEvents.sol";

contract Staking is ReentrancyGuard, Pausable, AccessControl, StakingEvents {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;
    IERC20 public rewardsToken;
    address public treasury;

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
    error InsufficientAmount();
    error BelowMinimumStake();
    error TransferFailed();
    error InsufficientBalance();

    constructor(address _stakingToken, address _rewardsToken) {
        if (_stakingToken == address(0)) revert InvalidAddress();
        if (_rewardsToken == address(0)) revert InvalidAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        treasury = msg.sender;
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

    function stake(
        uint256 _amount
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        if (_amount == 0) revert InsufficientAmount();
        if (_amount < minStakeAmount) revert BelowMinimumStake();

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        totalSupply += _amount;
        userInfo[msg.sender].amount += _amount;
        userInfo[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function withdraw(
        uint256 _amount
    ) public nonReentrant updateReward(msg.sender) {
        if (_amount == 0) revert InsufficientAmount();
        if (
            userInfo[msg.sender].amount == 0 ||
            _amount > userInfo[msg.sender].amount
        ) revert InsufficientBalance();

        uint256 penalty = 0;
        uint256 timeElapsed = userInfo[msg.sender].startTime + lockDuration;
        if (block.timestamp < timeElapsed) {
            penalty = (_amount * earlyWithdrawFee) / 10000;
        }

        totalSupply -= _amount;
        userInfo[msg.sender].amount -= _amount;
        uint256 amountAfterPenalty = _amount - penalty;
        stakingToken.safeTransfer(msg.sender, amountAfterPenalty);

        if (penalty > 0) {
            stakingToken.safeTransfer(treasury, penalty);
        }

        emit Withdrawn(msg.sender, _amount, penalty);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = userInfo[msg.sender].unclaimedRewards;
        if (reward > 0) {
            userInfo[msg.sender].unclaimedRewards = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    function exit() external {
        withdraw(userInfo[msg.sender].amount);
        getReward();
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = _amount / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_amount + leftover) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        rewardsToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(_amount);
    }
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    function setLockDuration(
        uint256 _duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockDuration = _duration;

        emit LockDurationUpdated(_duration);
    }
    function setEarlyWithdrawFee(
        uint256 _fee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        earlyWithdrawFee = _fee;

        emit EarlyWithdrawFeeUpdated(_fee);
    }
    function setTreasury(
        address _treasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasury == address(0)) revert InvalidAddress();
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }
    function setMinStakeAmount(
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minStakeAmount = _amount;
    }

    function recoverERC20(
        address _token,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _token != address(stakingToken) && _token != address(rewardsToken),
            "Cannot recover"
        );
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}
