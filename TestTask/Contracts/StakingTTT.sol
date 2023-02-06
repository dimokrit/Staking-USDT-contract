// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * Contract allows to stake USDT token
 * Every 24 hours after the start stake period, users are awarded a reward (TTT token)
 * The reward is awarded in direct proportion to the amount of money per day
 * The reward can be received every 24 hours after the steak
 * The reward is accumulative (you can take reward every day or 1 time in the last day)
 * You need to approve USDT before call stake function
 */
contract StakingTTT is Ownable {

    IERC20 tokenTTT;// Token TTT interface
    IERC20 tokenUSDT;// Token USDT interface

    uint public startStakeTime;// Start time of staking period in UNIX
    uint public finishStakeTime;// Finish time of staking period in UNIX
    uint dayUNIX = 86400;// One day in UNIX
    uint public totalStaked;// Total staked
    mapping(uint => uint) totalStakedInDay;// Total staked at the end of a certain day

    struct User {
        uint stakedAmount;// Active staked token amount
        uint firstStakeTime;// Time of the first stake in UNIX (reset to zero after unstake)
        uint firstStakeDay;// Day of the first stake (reset to zero after unstake)
        uint lastStakeTime;// Time of the last stake in UNIX
        uint receivedRewardAmount;// Amount of received reward
        uint numOfReceivedRewards;// The number of days for which user received the reward (internal)
        uint savedReward;// Saved reward after unstake
        uint[] stakingDays;// The days in which user staked
        uint[] stakesSumm;// Sum of all past stakes
    }

    mapping(address => User) public users;// User structure

    event Staked(address indexed userAddress, uint indexed amount, uint indexed day, uint time);
    event Unstaked(address indexed userAddress, uint indexed amount, uint indexed day, uint rewardAmount, uint time);
    event PromoActivated(address indexed holderAddress, uint indexed amount);
    
    constructor(address _tokenTTT) {
        tokenTTT = IERC20(_tokenTTT);
        tokenUSDT = IERC20(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd);
    }

    /// @notice stake receives USDT, and registers stake
    /// @param amount staked amount
    function stake(uint amount) external {
        address user = _msgSender();
        // Prohibits users from staking outside the staking period 
        require(block.timestamp > startStakeTime, "Staking period is not started");
        require(block.timestamp < finishStakeTime, "Staking period is ended");
        require(tokenUSDT.balanceOf(user) >= amount, "Token balance exceeded");
        // Prohibits users from staking more than once every 3 minutes, protecting against attacks
        require(block.timestamp - users[user].lastStakeTime > 180, "The break between the stakes should be 3 minutes");
        tokenUSDT.transferFrom(user, address(this), amount);
        uint dayNumber = getDayNumber(); // Uses function getDayNumber() to get correct today's number
        // Checking the first stake
        if (users[user].stakedAmount == 0) {
            users[user].firstStakeTime = block.timestamp;
            users[user].firstStakeDay = dayNumber;
        }
        users[user].stakedAmount += amount;
        uint numOfStakes = users[user].stakingDays.length;// Stores user number of stakes in local var

        // Checking the first stake and the last day of stake
        // If the last day of stake equals today's number we don't create new array element, but set new stake amount in the last array element
        if (numOfStakes > 0 && users[user].stakingDays[numOfStakes - 1] == dayNumber)
            users[user].stakesSumm[numOfStakes - 1] = users[user].stakedAmount;
        else {
        // Creates new array element with stake 
            users[user].stakingDays.push(dayNumber);
            users[user].stakesSumm.push(users[user].stakedAmount);
        }

        totalStaked += amount;// Increases total staked amount
        totalStakedInDay[dayNumber] = totalStaked;// Saves total staked for today
        emit Staked(user, amount, dayNumber, block.timestamp);
    }

    /// @notice getReward allows users get them reward
    function getReward() external {
        address user = _msgSender();
        require(users[user].lastStakeTime > 0, "You've never had a stake");// Removes users who have never been staking
        uint rewardAmount = availableReward(user);// Uses function availableReward() to get correct amount of available reward
        require (rewardAmount != 0, "You don't have available reward");// Removes users who don't have reward

        uint numOfRewards = getNumOfReward(user);// Uses function getNumOfReward(user) to get number of days for which user received the reward
        // Checking whether the user has a saved reward after unstake
        // The description of the variable is in the function unstake()
        if (users[user].savedReward != 0)
            users[user].savedReward = 0;// Resets to zero, because it was accrued in function awailableReward()
        users[user].receivedRewardAmount += rewardAmount;// Increases received reward amount
        users[user].numOfReceivedRewards += numOfRewards;// Increases number of days for which user received the reward
        
        tokenTTT.transfer(user, rewardAmount);// Transfers TTT token to user
    }

    /**
      * @notice unstake transfer all user's staked USDT tokens to his wallet address
      * @notice After unstake all user's awailable rewards (TTT tokens) will be transfered to his wallet address
      * @notice User could unstake before his last accruet reward have become available
      * @notice This remains is saved in "users[user].savedReward" variable
      */
    function unstake() external {
        address user = _msgSender();
        uint _stakedAmount = users[user].stakedAmount; // Stores amount of stake in local var
        require(_stakedAmount != 0, "You do not have staked tokens");
        uint rewardAmount = availableReward(user) + users[user].savedReward;// Counts awailable reward
        uint dayNumber = getDayNumber();
        if (dayNumber <= 31 && block.timestamp < users[user].firstStakeTime + (dayNumber - 1) * dayUNIX)// Checking whether the user has not awailable reward
            users[user].savedReward = (users[user].stakesSumm[users[user].stakesSumm.length - 1] * 1000 * 10**18)/totalStaked;// Saves reward

        // Reset to zero user's variables
        users[user].receivedRewardAmount = 0;
        users[user].stakedAmount = 0;
        users[user].firstStakeTime = 0;

        // Change total staked variables
        totalStaked -= _stakedAmount;
        totalStakedInDay[dayNumber] = totalStaked;

        tokenTTT.transfer(user, rewardAmount);// Transer TTT token to user
        tokenUSDT.transfer(user, _stakedAmount);// Transfer USDT token to user

        emit Unstaked(user, _stakedAmount, dayNumber, block.timestamp, rewardAmount);
    }

    /// @notice setStartStakeTime set stake period
    /// @param _startStakeTime start time of stake period in UNIX 
    function setStartStakeTime(uint _startStakeTime) external onlyOwner {
        startStakeTime = _startStakeTime;
        finishStakeTime = startStakeTime + (dayUNIX  * 30);
    }

    ///@param userAddress user address
    ///@return The number of days for which user could get reward 
    function getNumOfReward(address userAddress) internal view returns(uint) {
        // Checking moment of calling funtion is after 31 day after start stake period
        uint nowTime = block.timestamp > finishStakeTime + dayUNIX ? finishStakeTime + dayUNIX : block.timestamp;
        uint numOfRewards;
        if (users[userAddress].firstStakeTime != 0)
            numOfRewards = (nowTime - users[userAddress].firstStakeTime)/dayUNIX - users[userAddress].numOfReceivedRewards;
        return numOfRewards;
    }

    ///@param userAddress user address
    ///@return amount awailable user's amount of reward
    function availableReward(address userAddress) public view returns(uint amount) {
        uint stakeIndex;// Index of user's stakes
        uint rewardAmount;
        uint _firstStakeDay = users[userAddress].firstStakeDay;
        uint numOfRewards = getNumOfReward(userAddress);

        // The cycle passes the number of circles equal to the number of user's available rewards at the moment
        // Starting from the last reward received or from the first stack (if he has not yet collected the reward)
        for (uint i = _firstStakeDay + users[userAddress].numOfReceivedRewards; i < _firstStakeDay + numOfRewards; i++) {
            // Checking what the stake amount need to use in day "i"
            // If user's stake was after day "i", checks next stake
            while (users[userAddress].stakingDays[stakeIndex] > i || users[userAddress].stakingDays[stakeIndex] < _firstStakeDay)
                stakeIndex++;

            // Checking what the total stake amount need to use in day "i"
            // If on some day no one staked, unstake and took the reward, "totalStakedInDay[day]" in this day will be equal to 0
            // So we take total stake amount in the previous day
            uint day = i;
            while (totalStakedInDay[day] == 0)
                day--;
            uint _totalStaked = totalStakedInDay[day];

            rewardAmount += (users[userAddress].stakesSumm[stakeIndex] * 1000)/_totalStaked;// Adds amount of reward value proportional to the user's stake
        }
        rewardAmount += users[userAddress].savedReward;
        return rewardAmount;
    }
    ///@return Day number of the stake period
    function getDayNumber() public view returns(uint){
        uint correctDay = (block.timestamp - startStakeTime)/dayUNIX + 1;
        return correctDay;
    }
}