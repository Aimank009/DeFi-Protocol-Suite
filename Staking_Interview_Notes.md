# 🏰 Staking Contract Deep Dive - Interview Notes

## 1. Core Concept

Staking is an incentive mechanism where users lock tokens to earn rewards.

- **Protocol Goal**: Lock liquidity, reduce sell pressure, secure network.
- **User Goal**: Earn passive income (AP).

## 2. The Golden Algorithm (Synthetix Mechanism)

This is the industry standard for distributing rewards.

### The Problem it Solves

How to distribute rewards fairly to thousands of users without looping through all of them (which would cost infinite gas)?

### The Solution: `rewardPerToken`

Instead of updating every user, we track the global "Reward Per Token" over time.

**Formula:**

```
rewardPerToken += (rewardRate * timeElapsed * 1e18) / totalStaked
```

When a user stakes/unstakes, we calculate their earnings based on the _difference_ in `rewardPerToken` since they last interacted.

**User Earnings Formula:**

```
earned = (userBalance * (currentRewardPerToken - userRewardPerTokenPaid)) / 1e18 + rewards
```

_This allows O(1) complexity (constant gas cost) regardless of user count._

## 3. Key State Variables

| Variable                 | Description                                  |
| ------------------------ | -------------------------------------------- |
| `rewardRate`             | Tokens distributed per second                |
| `totalSupply`            | Total tokens currently staked in contract    |
| `rewardPerTokenStored`   | Snapshot of global reward value              |
| `lastUpdateTime`         | Timestamp of last interaction                |
| `userRewardPerTokenPaid` | Snippet of global value when user last acted |
| `rewards`                | Unclaimed rewards for each user              |

## 4. Critical Functions

### `stake(amount)`

1. Update global `rewardPerToken`.
2. Update user's `earned` rewards.
3. Transfer tokens FROM user TO contract.
4. Increase `totalSupply` and `balances[user]`.

### `withdraw(amount)`

1. Update rewards (same as stake).
2. Decrease `totalSupply` and `balances[user]`.
3. Transfer tokens FROM contract TO user.

### `getReward()`

1. Update rewards.
2. Transfer `rewards[user]` to user.
3. Reset `rewards[user]` to 0.

## 5. Security & Vulnerabilities (Interview Gold 🌟)

### ⚠️ A. The "Empty Stake" Bug

If `totalSupply` is 0, but `rewardRate` > 0, the math divides by zero or wastes rewards.
_Fix_: Ensure `totalSupply != 0` before updating global accumulator.

### ⚠️ B. Reward Dilution

If Admin adds rewards but doesn't notify/update duration properly, users might get rewards too fast or slow.

### ⚠️ C. Reentrancy

If `withdraw` sends tokens before updating balances.
_Fix_: Update state FIRST, then transfer. Use `ReentrancyGuard`.

## 6. Advanced Features (Our Contract)

### 🔒 Lock-Up Period

Users _can_ withdraw anytime, BUT if they withdraw before `lockEndTime`, they pay a penalty.

- **Mechanism**: Store `depositTime[user]`. Check `block.timestamp`.

### 💸 Early Exit Penalty

- Deduct X% from the principal.
- Burn the penalty to make token deflationary.
