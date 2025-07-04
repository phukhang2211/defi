# Module 2: DeFi Core Concepts

## 🎯 Learning Objectives
- Understand DeFi protocols and their mechanisms
- Master liquidity pools and Automated Market Makers (AMMs)
- Learn yield farming and staking strategies
- Implement risk management in DeFi

## 🏦 What is DeFi?

**DeFi (Decentralized Finance)** is the ecosystem of financial applications built on blockchain technology that operate without intermediaries.

### Traditional Finance vs DeFi

| Traditional Finance | DeFi |
|-------------------|------|
| Banks as intermediaries | Smart contracts as intermediaries |
| Centralized control | Decentralized governance |
| Geographic restrictions | Global access |
| Limited transparency | Full transparency |
| Slow settlement | Near-instant settlement |

## 🔗 From Odoo ERP to DeFi Protocols

### Business Process Comparison

| Odoo Module | DeFi Protocol | Purpose |
|-------------|---------------|---------|
| Accounting | Lending Protocols | Financial management |
| Inventory | DEX/AMM | Asset exchange |
| CRM | Yield Aggregators | Customer value optimization |
| Manufacturing | Liquidity Mining | Production incentives |

## 🏊‍♂️ Liquidity Pools & AMMs (Automated Market Makers)

### What is a Liquidity Pool?

A liquidity pool is a collection of tokens locked in a smart contract that enables trading without traditional order books.

### AMM Formula: Constant Product Formula
```
x * y = k
```
Where:
- `x` = amount of token A
- `y` = amount of token B  
- `k` = constant product

### Simple AMM Implementation
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleAMM {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    // Add liquidity
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");
        
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        reserveA += amountA;
        reserveB += amountB;
    }
    
    // Swap tokenA for tokenB
    function swapAForB(uint256 amountAIn) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Amount must be positive");
        
        // Calculate output using constant product formula
        amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        
        require(amountBOut > 0, "Insufficient output amount");
        
        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;
        
        // Transfer tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);
    }
}
```

### Odoo Parallel: Inventory Management
```python
# Odoo inventory management (simplified)
class StockMove(models.Model):
    _name = 'stock.move'
    
    def _compute_available_qty(self):
        # Similar to AMM reserve calculation
        for move in self:
            available = move.product_id.qty_available
            reserved = move.product_id.virtual_available
            move.available_qty = available - reserved
```

## 🌾 Yield Farming & Staking

### What is Yield Farming?

Yield farming is the practice of earning rewards by providing liquidity or participating in DeFi protocols.

### Staking Contract Example
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingContract is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    
    uint256 public rewardRate = 100; // tokens per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        
        stakingToken.transfer(msg.sender, amount);
    }
    
    function getReward() external nonReentrant {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }
    }
}
```

### Odoo Parallel: Employee Incentive System
```python
# Odoo employee incentive system
class EmployeeIncentive(models.Model):
    _name = 'employee.incentive'
    
    def calculate_bonus(self, employee, period):
        # Similar to yield farming calculation
        base_salary = employee.salary
        performance_score = employee.performance_rating
        bonus_rate = 0.1  # 10% bonus rate
        
        bonus = base_salary * performance_score * bonus_rate
        return bonus
```

## 🏦 Lending Protocols

### How DeFi Lending Works

1. **Depositors** provide assets to earn interest
2. **Borrowers** use collateral to borrow assets
3. **Smart contracts** manage liquidation and interest rates

### Simple Lending Contract
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleLending {
    IERC20 public asset;
    IERC20 public collateral;
    
    uint256 public totalBorrowed;
    uint256 public totalDeposited;
    uint256 public interestRate = 500; // 5% annual rate
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;
    mapping(address => uint256) public collateralDeposited;
    
    constructor(address _asset, address _collateral) {
        asset = IERC20(_asset);
        collateral = IERC20(_collateral);
    }
    
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        
        deposits[msg.sender] += amount;
        totalDeposited += amount;
        
        asset.transferFrom(msg.sender, address(this), amount);
    }
    
    function borrow(uint256 amount, uint256 collateralAmount) external {
        require(amount > 0, "Amount must be positive");
        require(collateralAmount > 0, "Collateral must be positive");
        
        // Simple collateralization ratio check (150%)
        require(
            collateralAmount * 100 >= amount * 150,
            "Insufficient collateral"
        );
        
        borrows[msg.sender] += amount;
        collateralDeposited[msg.sender] += collateralAmount;
        totalBorrowed += amount;
        
        collateral.transferFrom(msg.sender, address(this), collateralAmount);
        asset.transfer(msg.sender, amount);
    }
    
    function repay(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(borrows[msg.sender] >= amount, "Insufficient borrow balance");
        
        borrows[msg.sender] -= amount;
        totalBorrowed -= amount;
        
        asset.transferFrom(msg.sender, address(this), amount);
    }
}
```

## ⚠️ Risk Management in DeFi

### Common DeFi Risks

1. **Smart Contract Risk**
   - Code bugs and vulnerabilities
   - Upgrade risks
   - Oracle failures

2. **Market Risk**
   - Impermanent loss in AMMs
   - Price volatility
   - Liquidation risk

3. **Protocol Risk**
   - Governance attacks
   - Economic attacks
   - Centralization risks

### Risk Management Strategies

#### 1. Diversification
```javascript
// Portfolio allocation example
const portfolio = {
    stablecoins: 0.4,    // 40% stable assets
    blueChip: 0.3,       // 30% established protocols
    emerging: 0.2,       // 20% new protocols
    cash: 0.1            // 10% emergency fund
};
```

#### 2. Position Sizing
```solidity
// Risk-adjusted position sizing
function calculateMaxPosition(uint256 capital, uint256 riskPerTrade) 
    public pure returns (uint256) {
    // Never risk more than 2% per trade
    return capital * riskPerTrade / 100;
}
```

#### 3. Stop-Loss Implementation
```solidity
// Automated stop-loss
function setStopLoss(uint256 tokenAmount, uint256 minPrice) external {
    require(msg.sender == owner, "Not authorized");
    
    stopLossAmount = tokenAmount;
    stopLossPrice = minPrice;
}

function executeStopLoss() external {
    if (getCurrentPrice() <= stopLossPrice) {
        // Execute emergency sell
        sellTokens(stopLossAmount);
    }
}
```

## 🧪 Hands-On Exercise: Build a Simple DeFi Dashboard

### Frontend Integration with Web3
```javascript
// React component for DeFi dashboard
import React, { useState, useEffect } from 'react';
import Web3 from 'web3';

function DeFiDashboard() {
    const [web3, setWeb3] = useState(null);
    const [account, setAccount] = useState('');
    const [balance, setBalance] = useState(0);
    
    useEffect(() => {
        connectWallet();
    }, []);
    
    const connectWallet = async () => {
        if (window.ethereum) {
            const web3Instance = new Web3(window.ethereum);
            setWeb3(web3Instance);
            
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });
            setAccount(accounts[0]);
            
            const balance = await web3Instance.eth.getBalance(accounts[0]);
            setBalance(web3Instance.utils.fromWei(balance, 'ether'));
        }
    };
    
    return (
        <div className="defi-dashboard">
            <h2>DeFi Dashboard</h2>
            <div className="wallet-info">
                <p>Account: {account}</p>
                <p>Balance: {balance} ETH</p>
            </div>
            {/* Add more DeFi components here */}
        </div>
    );
}

export default DeFiDashboard;
```

## 📊 DeFi Analytics: Key Metrics

### TVL (Total Value Locked)
```javascript
// Calculate TVL for a protocol
async function calculateTVL(protocolAddress) {
    const balance = await web3.eth.getBalance(protocolAddress);
    const tokenBalances = await getTokenBalances(protocolAddress);
    
    const totalValue = web3.utils.fromWei(balance, 'ether') * ethPrice;
    tokenBalances.forEach(token => {
        totalValue += token.balance * token.price;
    });
    
    return totalValue;
}
```

### APY Calculation
```javascript
// Calculate APY from daily yield
function calculateAPY(dailyYield) {
    return Math.pow(1 + dailyYield, 365) - 1;
}

// Example: 0.1% daily yield = 44.2% APY
const apy = calculateAPY(0.001);
console.log(`APY: ${(apy * 100).toFixed(2)}%`);
```

## 🎯 Key Takeaways

1. **DeFi protocols are like financial modules** - each serves a specific purpose
2. **Liquidity pools enable trading** - similar to Odoo's inventory management
3. **Yield farming rewards participation** - like employee incentive programs
4. **Risk management is crucial** - always diversify and size positions properly
5. **Smart contracts automate everything** - no manual intervention needed

## 📚 Additional Resources

- [DeFi Pulse Index](https://defipulse.com/)
- [DeFi Llama](https://defillama.com/)
- [Uniswap Documentation](https://docs.uniswap.org/)
- [Aave Documentation](https://docs.aave.com/)

## 🚀 Next Steps

1. Deploy the AMM contract on testnet
2. Implement the staking contract
3. Build the DeFi dashboard
4. Move to Module 3: Development Skills

---

*Ready to code? Let's dive into Solidity programming and smart contract development in the next module.* 