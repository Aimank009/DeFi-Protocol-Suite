# 🏰 DeFi Protocol Suite

A comprehensive, production-grade DeFi ecosystem built with Solidity and Foundry. This suite includes a feature-rich ERC20 token, an ERC-4626 Yield Vault, a Synthetix-style Staking contract, and a Constant Product AMM (DEX).

## 🧩 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DeFi Protocol Suite                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   AKToken    │───▶│    Vault     │───▶│   Staking    │       │
│  │   (ERC20)    │    │  (ERC-4626)  │    │  (Synthetix) │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                                       ▲               │
│         │                                       │               │
│         ▼                                       │               │
│  ┌──────────────┐                               │               │
│  │     AMM      │───────────────────────────────┘               │
│  │    (DEX)     │      (Provide Liquidity)                      │
│  └──────────────┘                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Components

### 1. AKToken (The Core Asset)

An advanced ERC20 token with built-in governance and safety features.

- **Features**: Mintable, Burnable, Pausable, Votes (Governance), FlashMint (Flash Loans).
- **Security**: Capped supply (100M), AccessControl (RBAC).

### 2. Vault (Yield Aggregator)

A standard ERC-4626 Tokenized Vault.

- **Function**: Users deposit assets (AKToken) to receive shares (vAKT).
- **Yield**: The vault accumulates yield, increasing the value of shares over time.

### 3. Staking (Rewards System)

A robust staking contract based on the industry-standard Synthetix algorithm.

- **Math**: O(1) reward distribution using `rewardPerToken` accumulators.
- **Features**:
  - **Lock Periods**: Configurable lock-up (e.g., 7 days).
  - **Early Exit Penalty**: 10% penalty for withdrawing early (sent to treasury).
  - **Pausable**: Emergency stop mechanism.

### 4. AMM (Decentralized Exchange)

A Constant Product Automated Market Maker (`x * y = k`).

- **Trading**: Swap between tokens with a 0.3% fee.
- **Liquidity**: Provide liquidity to mint LP tokens; burn to withdraw.
- **Oracles**: Includes time-weighted average price (TWAP) oracle support hooks.

## 🛠️ Tech Stack

- **Language**: Solidity ^0.8.20
- **Framework**: Foundry (Forge)
- **Libraries**: OpenZeppelin Contracts

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```bash
git clone https://github.com/Aimank009/DeFi-Protocol-Suite.git
cd DeFi-Protocol-Suite
forge install
```

### Build

```bash
forge build
```

### Test

Run the comprehensive test suite (50+ tests):

```bash
forge test
```

**Test Coverage:**

- `AKToken`: 22 tests (Governance, FlashMint, Roles)
- `Vault`: 10 tests (Deposit, Redeem, Yield)
- `Staking`: 14 tests (Rewards, Penalties, Admin)
- `AMM`: 4 tests (Swap, Liquidity, Fees)

## 📄 License

MIT
