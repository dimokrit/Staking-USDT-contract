<p align="center">
   <img src="https://img.shields.io/badge/Solidity-0.8.9-lightgrey" alt="Solidity Version">
   <img src="https://img.shields.io/badge/HardHat-2.9.7-red" alt="HardHat Version">
   <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

# About

## Token TTT
Token TTT using for "reward system" in the staking USDT contract.

Token has default ERC-20 methods. Max token amount = 30000, because staking contract is working within 30 days, end every day distributes 1000 tokens to holders.

## Staking
### How staking works
The staking contract works completely offline, and does not require calling any functions by the owner.
Before the start of the steak period, 30,000 TTT tokens must be screwed into the steak contract.
The user can stake and unstake an unlimited number of times.
To freeze USDT, you must first call approve() of the token in the token contract, and then call the stake() function.

The contract has a totalStakedInDay array to remember how many were all staked on a certain day,
this array is updated every time someone steaks or unstakes.

Each steak in the user's structure, the size of the steak at the moment is recorded in arrays, and on what day the steak was made,
this is necessary to check how much the user had by the end of a certain day.

When calculating the reward, the getAwailableReward() function uses for and while loops (with limited repetitions).
Global variables do not change inside the cycles, so the gas consumption (even with maximum repetitions) will be small.
Cycles cannot be manipulated for any kind of attack.

### Reward
The reward system is cumulative (you can take it at any time). 1000 TTT tokens are distributed to all users every day,
the reward is distributed in direct proportion to the users' stakes and is accrued every 24 hours from the launch.

Tokens become available according to the steak time (every 24 hours after the first steak).

After the unstake, the user is sent all his available rewards at the moment.

--------------------------------------------
**You can read more information in the contract's comments**

## Tests
Before launching, you need to install HardHat locally.
In the Test folder, run the command:

`npm install --save-dev hardhat `

To run the tests, use the command:

`npx hardhat test`

# Developers

- [dimokrit](https://github.com/dimokrit)

# Licence
Project is distributed under the MIT license
