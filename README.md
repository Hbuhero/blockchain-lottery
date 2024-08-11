# Blockchain Lottery System

This project is a **Blockchain Lottery System** developed as a proof of skill in utilizing Foundry, Chainlink tools like VRF (Verifiable Random Function), and Solidity. The project was built step to step from Cyfrin Updraft Foundry Fundamental Course, and it serves as a comprehensive demonstration of my understanding and proficiency in smart contract development.

## Overview

The Blockchain Lottery System is a decentralized application (dApp) that allows participants to enter a lottery by paying an entry fee. A winner is selected at random using Chainlink VRF, ensuring fairness and transparency. The project is designed to showcase the integration of key blockchain development tools and concepts.

### Key Features
- **Random Winner Selection**: The winner is selected using Chainlink VRF, providing verifiable randomness.
- **Automated Lottery Cycle**: The lottery runs on a cycle, automatically selecting a winner and resetting after each round.
- **Secure and Transparent**: All transactions are recorded on the blockchain, ensuring transparency and security.

## Tools and Technologies

- **Foundry**: A fast and efficient Ethereum development environment used for testing and deploying the smart contract.
- **Solidity**: The smart contract programming language used to develop the lottery system.
- **Chainlink VRF**: Provides a secure and verifiable source of randomness, crucial for selecting the lottery winner in a fair manner.

## How It Works

1. **Participants Enter the Lottery**: Users enter the lottery by sending a specified amount of cryptocurrency to the smart contract.
2. **Random Number Generation**: Once the entry period ends, the smart contract requests a random number from Chainlink VRF.
3. **Winner Selection**: The random number is used to select a winner from the list of participants.
4. **Prize Distribution**: The entire pool of funds is transferred to the winner's address.
5. **Lottery Reset**: The contract resets, allowing for a new round of the lottery to begin.

## Project Structure

- `contracts/`: Contains the Solidity smart contracts.
- `scripts/`: Deployment scripts used with Foundry.
- `test/`: Unit tests written in Solidity to ensure the correctness of the contract.

## Prerequisites

- **Foundry**: Make sure you have Foundry installed for testing and deployment.

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/blockchain-lottery.git
   cd blockchain-lottery
