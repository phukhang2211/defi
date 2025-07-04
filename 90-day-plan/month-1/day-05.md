# Day 5: Yield Farming and Staking Mechanisms

## 🎯 Learning Objective
Understand yield farming, staking, and reward mechanisms in DeFi.

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding Yield Farming (1 hour)
**What to do:**
- Learn about yield farming and liquidity mining
- Understand how rewards are distributed
- Study different farming strategies

**Resources:**
- [Yield Farming Explained](https://finematics.com/yield-farming-explained/)
- [DeFi Pulse: Yield Farming](https://defipulse.com/blog/yield-farming/)

**Key Concepts:**
- **Yield Farming**: Earning rewards by providing liquidity or participating in protocols
- **Liquidity Mining**: Rewarding users for providing liquidity with protocol tokens
- **APY/APR**: Annual Percentage Yield/Rate - return on investment
- **Impermanent Loss**: Potential loss from providing liquidity vs holding tokens
- **Harvesting**: Claiming accumulated rewards

**Success Criteria:**
- [ ] Can explain what yield farming is
- [ ] Understand different farming strategies
- [ ] Know the risks involved in yield farming

### Task 2: Understanding Staking (1 hour)
**What to do:**
- Learn about staking and proof-of-stake
- Understand validator rewards
- Study staking pools

**Key Concepts:**
- **Staking**: Locking tokens to participate in network consensus
- **Validator**: Node that validates transactions and creates blocks
- **Delegator**: User who stakes tokens with a validator
- **Slashing**: Penalty for malicious behavior
- **Unbonding Period**: Time required to unstake tokens

**Success Criteria:**
- [ ] Understand the difference between staking and farming
- [ ] Know how validator rewards work
- [ ] Understand staking risks and benefits

### Task 3: Build a Staking Contract (2 hours)
**What to do:**
- Create a staking contract with rewards
- Implement staking and unstaking functions
- Add reward distribution mechanism

**Create file: `contracts/StakingContract.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingContract is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    
    uint256 public rewardRate = 100; // 100 tokens per day
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public stakedBalance;
    
    uint256 public totalStaked;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
            ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked
        );
    }
    
    function earned(address account) public view returns (uint256) {
        return (
            stakedBalance[account] * 
            (rewardPerToken() - userRewardPerTokenPaid[account])
        ) / 1e18 + rewards[account];
    }
    
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        
        // Update rewards
        uint256 rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (stakedBalance[msg.sender] > 0) {
            rewards[msg.sender] = earned(msg.sender);
        }
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        
        totalStaked += amount;
        stakedBalance[msg.sender] += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        
        // Update rewards
        uint256 rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        rewards[msg.sender] = earned(msg.sender);
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        
        totalStaked -= amount;
        stakedBalance[msg.sender] -= amount;
        stakingToken.transfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function getReward() external nonReentrant {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            userRewardPerTokenPaid[msg.sender] = rewardPerToken();
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function getStakingInfo(address user) external view returns (
        uint256 staked,
        uint256 earned,
        uint256 totalStakedTokens,
        uint256 currentRewardRate
    ) {
        return (
            stakedBalance[user],
            earned(user),
            totalStaked,
            rewardRate
        );
    }
}
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Can stake tokens and earn rewards
- [ ] Can withdraw staked tokens
- [ ] Can claim earned rewards

### Task 4: Test Your Staking Contract (1 hour)
**What to do:**
- Deploy and test staking functionality
- Create comprehensive tests

**Create file: `test/Staking.test.js`**
```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking Contract", function () {
    let StakingContract, stakingContract;
    let Token, token;
    let RewardToken, rewardToken;
    let owner, user1, user2;
    
    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        
        // Deploy tokens
        Token = await ethers.getContractFactory("MyFirstToken");
        token = await Token.deploy("Staking Token", "STK", ethers.utils.parseEther("1000000"), 0);
        
        RewardToken = await ethers.getContractFactory("MyFirstToken");
        rewardToken = await RewardToken.deploy("Reward Token", "RWD", ethers.utils.parseEther("1000000"), 0);
        
        // Deploy staking contract
        StakingContract = await ethers.getContractFactory("StakingContract");
        stakingContract = await StakingContract.deploy(token.address, rewardToken.address);
        
        // Mint tokens to users
        await token.mintFor(user1.address, ethers.utils.parseEther("1000"));
        await rewardToken.mintFor(stakingContract.address, ethers.utils.parseEther("10000"));
    });
    
    it("Should stake tokens correctly", async function () {
        const stakeAmount = ethers.utils.parseEther("100");
        
        await token.connect(user1).approve(stakingContract.address, stakeAmount);
        await stakingContract.connect(user1).stake(stakeAmount);
        
        const info = await stakingContract.getStakingInfo(user1.address);
        expect(info.staked).to.equal(stakeAmount);
    });
    
    it("Should earn rewards over time", async function () {
        const stakeAmount = ethers.utils.parseEther("100");
        
        await token.connect(user1).approve(stakingContract.address, stakeAmount);
        await stakingContract.connect(user1).stake(stakeAmount);
        
        // Fast forward time
        await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
        await ethers.provider.send("evm_mine");
        
        const earned = await stakingContract.earned(user1.address);
        expect(earned).to.be.gt(0);
    });
});
```

**Success Criteria:**
- [ ] All tests pass
- [ ] Staking works correctly
- [ ] Rewards are calculated accurately

### Task 5: Compare with Odoo Employee Rewards (30 minutes)
**What to do:**
- Think about how staking rewards compare to employee incentive programs
- Consider the similarities and differences

**Comparison Exercise:**
| Odoo HR | DeFi Staking | Similarities | Differences |
|---------|-------------|-------------|-------------|
| Employee contracts | Staking contracts | Lock-in periods | Automated execution |
| Performance bonuses | Yield rewards | Incentive mechanisms | Real-time calculation |
| Vesting schedules | Unbonding periods | Time-based restrictions | Smart contract enforced |

**Success Criteria:**
- [ ] Can identify parallels between HR and DeFi reward systems
- [ ] Understand how smart contracts automate reward distribution

## 📚 Additional Resources
- [Compound Protocol](https://compound.finance/)
- [Aave Protocol](https://aave.com/)

## 🎯 Reflection Questions
1. How do DeFi rewards compare to traditional investment returns?
2. What risks are unique to yield farming vs traditional investing?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 6 - Lending and Borrowing Protocols 