![BOBC Protocol banner](https://raw.githubusercontent.com/rafael-abuawad/bob-stablecoin/refs/heads/main/assets/images/banner.png "BOBC")

### **Overcollateralized Stablecoin Pegged to BOB**

The BOBC Protocol is an overcollateralized stablecoin system pegged to the BOB currency. This decentralized protocol allows users to mint BOBC stablecoins by depositing WETH as collateral. The protocol ensures that the system is always at least 200% overcollateralized, guaranteeing the stability of BOBC. It uses **Chainlink** data feeds for USD pricing, though the protocol maintains a fixed exchange rate between USD and BOB.

- [Video presentation](https://youtu.be/TTNQ3m35QOs)
- [Live Demo](https://bob-stablecoin-kj68.vercel.app/)

## **Table of Contents**
- [Introduction](#introduction)
- [Key Features](#key-features)
- [Contracts](#contracts)
- [How It Works](#how-it-works)
  - [Collateralization & Minting](#collateralization--minting)
  - [Liquidation](#liquidation)
- [Development](#development)
  - [Requirements](#requirements)
  - [Setup](#setup)
- [Security](#security)
- [License](#license)

## **Introduction**
BOBC is an innovative, overcollateralized stablecoin pegged to the BOB, with a fixed exchange rate of approximately 1 USD = 7 BOB. The protocol leverages Chainlink's decentralized oracles to fetch USD prices, but all core protocol logic is handled entirely on-chain through Vyper smart contracts. This ensures that the system is decentralized, transparent, and secure.

The system consists of two main contracts:
1. `token.vy`: The BOBC stablecoin contract, managed 100% by the protocol with no owner.
2. `engine.vy`: The engine contract, which facilitates minting, burning, collateral management, and liquidation functions.

## **Key Features**
- **Overcollateralization**: Users must maintain a collateralization ratio of at least 200%.
- **Decentralized Price Oracle**: The protocol uses Chainlink oracles for USD/ETH pricing to assess collateral value.
- **Liquidation**: If a user's health factor drops below 1 (i.e., undercollateralized), other users can liquidate their position and profit from the difference.
- **Fully On-Chain**: All operations, including liquidation, are handled entirely on-chain using Vyper smart contracts.

![App screenshot](https://raw.githubusercontent.com/rafael-abuawad/bob-stablecoin/refs/heads/main/client/assets/images/screenshot.png "App")

## **Contracts**

1. **`token.vy`**:
   - The BOBC stablecoin contract.
   - BOBC is minted when users deposit WETH as collateral.
   - There is no owner; the contract is entirely managed by the `engine.vy`.
   - [WETH](https://sepolia.basescan.org/address/0xec915716AE8cC0359A88c24E214792f6A12c192b)
   - [BOBC](https://sepolia.basescan.org/address/0x947eA44Bd6560476819a91F2a5DBf030C43dee26)

2. **`engine.vy`**:
   - This contract is the core of the protocol.
   - It manages:
     - Collateral deposits and withdrawals.
     - Minting and burning of BOBC.
     - Liquidations, allowing users to liquidate undercollateralized positions.
   - [Engine](https://sepolia.basescan.org/address/0xA7e9D84133936Ab2599BB8ec5B29caa9Df4A9bD1)

## **How It Works**

### **Collateralization & Minting**

- Users deposit WETH as collateral to mint BOBC.
- The protocol is designed to be overcollateralized by at least 200%. For example:
  - If a user deposits $200 worth of ETH, they can mint up to 100 BOBC.
  - Chainlink data feeds are used to determine the value of ETH in USD, ensuring real-time collateral valuation.
  
### **Liquidation**

- If a user's health factor falls below 1 (collateral value is less than the value of the minted BOBC), they become eligible for liquidation.
- A liquidator can repay the debt of the undercollateralized user and profit from the difference.
- This mechanism ensures the system stays solvent and overcollateralized at all times.

## **Development**

### **Requirements**

- **Vyper**: Ensure you have Vyper installed on your machine.
- **Apeworx**: Apeworx is used as the development framework for testing, deployment, and contract management.

### **Setup**

1. Clone the repository:
   ```bash
   git clone https://github.com/rafael-abuawad/bob-stablecoin
   cd bob-stablecoin
   ```

2. Install Apeworx:
   ```bash
   pip install eth-ape
   ```

3. Install all the plugins:
   ```bash
   ape install plugins .
   ```

4. Compile the contracts:
   ```bash
   ape compile
   ```

5. Run tests:
   ```bash
   ape test
   ```

## **Security**
- The protocol is designed with security in mind by requiring overcollateralization at all times.
- Liquidation ensures that undercollateralized positions do not affect the stability of BOBC.
- Chainlink’s decentralized oracles provide secure and reliable price data for ETH.

### **Disclaimer**
- This code is provided as-is and has not undergone formal audits. Use at your own risk.

## **License**
This project is licensed under the GNU AFFERO GENERAL PUBLIC License.

