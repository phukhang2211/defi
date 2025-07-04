# Day 4: DeFi Fundamentals and AMM Concepts

## 🎯 Learning Objective
Understand DeFi fundamentals and learn about Automated Market Makers (AMMs).

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding DeFi (1 hour)
**What to do:**
- Learn what DeFi is and why it matters
- Understand the difference between CeFi and DeFi
- Study the DeFi ecosystem

**Resources:**
- [DeFi Pulse: What is DeFi?](https://defipulse.com/blog/what-is-defi/)
- [Ethereum.org: DeFi](https://ethereum.org/en/defi/)

**Key Concepts:**
- **DeFi**: Decentralized Finance - financial services without intermediaries
- **CeFi vs DeFi**: Centralized vs Decentralized Finance
- **Permissionless**: Anyone can use DeFi protocols
- **Composability**: DeFi protocols can be combined like LEGO blocks

**DeFi Categories:**
1. **DEXs**: Decentralized Exchanges (Uniswap, SushiSwap)
2. **Lending**: Borrow and lend assets (Aave, Compound)
3. **Yield Farming**: Earn rewards by providing liquidity
4. **Stablecoins**: Cryptocurrencies pegged to fiat (USDC, DAI)
5. **Derivatives**: Options, futures, and synthetic assets

**Success Criteria:**
- [ ] Can explain what DeFi is
- [ ] Understand the difference between CeFi and DeFi
- [ ] Know the main DeFi categories

### Task 2: Understanding AMMs (1.5 hours)
**What to do:**
- Learn about Automated Market Makers
- Understand the constant product formula
- Study how Uniswap works

**Resources:**
- [Uniswap Documentation](https://docs.uniswap.org/concepts/protocol-overview)
- [AMM Explained](https://finematics.com/automated-market-maker-amm-explained/)

**Key Concepts:**
- **AMM**: Automated Market Maker - algorithm that provides liquidity
- **Liquidity Pool**: Collection of tokens locked in a smart contract
- **Constant Product Formula**: x * y = k (Uniswap V2)
- **Impermanent Loss**: Loss from providing liquidity vs holding tokens

**AMM vs Traditional Exchanges:**
| Traditional Exchange | AMM |
|-------------------|-----|
| Order books | Liquidity pools |
| Market makers | Automated algorithms |
| Centralized | Decentralized |
| Complex matching | Simple formulas |

**Success Criteria:**
- [ ] Understand how AMMs work
- [ ] Know the constant product formula
- [ ] Understand impermanent loss

### Task 3: Build a Simple AMM (2 hours)
**What to do:**
- Create a basic AMM contract
- Implement the constant product formula
- Test token swaps

**Create file: `contracts/SimpleAMM.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SimpleAMM is ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant FEE_NUMERATOR = 3; // 0.3% fee
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event TokenSwap(address indexed user, address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");
        
        // Calculate optimal amounts if this is the first liquidity
        if (reserveA == 0 && reserveB == 0) {
            // First liquidity provider sets the initial ratio
        } else {
            // Calculate optimal amountB based on current ratio
            uint256 optimalAmountB = (amountA * reserveB) / reserveA;
            require(amountB >= optimalAmountB, "Insufficient token B amount");
            
            if (amountB > optimalAmountB) {
                // Return excess tokens
                uint256 excessB = amountB - optimalAmountB;
                amountB = optimalAmountB;
                tokenB.transfer(msg.sender, excessB);
            }
        }
        
        // Transfer tokens from user to contract
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        // Update reserves
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    
    function removeLiquidity(uint256 liquidityTokens) external nonReentrant {
        require(liquidityTokens > 0, "Amount must be positive");
        
        // Calculate amounts to return based on share of total liquidity
        uint256 totalLiquidity = reserveA + reserveB;
        uint256 amountA = (liquidityTokens * reserveA) / totalLiquidity;
        uint256 amountB = (liquidityTokens * reserveB) / totalLiquidity;
        
        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens back to user
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }
    
    function swapAForB(uint256 amountAIn) external nonReentrant returns (uint256 amountBOut) {
        require(amountAIn > 0, "Amount must be positive");
        
        // Calculate output using constant product formula with fees
        uint256 amountAInWithFee = amountAIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
        amountBOut = (amountAInWithFee * reserveB) / (reserveA + amountAInWithFee);
        
        require(amountBOut > 0, "Insufficient output amount");
        require(amountBOut < reserveB, "Insufficient liquidity");
        
        // Transfer tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);
        
        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;
        
        emit TokenSwap(msg.sender, address(tokenA), amountAIn, amountBOut);
    }
    
    function swapBForA(uint256 amountBIn) external nonReentrant returns (uint256 amountAOut) {
        require(amountBIn > 0, "Amount must be positive");
        
        // Calculate output using constant product formula with fees
        uint256 amountBInWithFee = amountBIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
        amountAOut = (amountBInWithFee * reserveA) / (reserveB + amountBInWithFee);
        
        require(amountAOut > 0, "Insufficient output amount");
        require(amountAOut < reserveA, "Insufficient liquidity");
        
        // Transfer tokens
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);
        
        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;
        
        emit TokenSwap(msg.sender, address(tokenB), amountBIn, amountAOut);
    }
    
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        return (reserveA, reserveB);
    }
    
    function getSwapAmountOut(uint256 amountIn, bool swapAForB) external view returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be positive");
        
        if (swapAForB) {
            uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
            amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
        } else {
            uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
            amountOut = (amountInWithFee * reserveA) / (reserveB + amountInWithFee);
        }
        
        return amountOut;
    }
}
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Can add liquidity to the pool
- [ ] Can swap tokens using the AMM
- [ ] Understand how the constant product formula works

### Task 4: Test Your AMM (1 hour)
**What to do:**
- Deploy your AMM with two tokens
- Test adding liquidity and swapping
- Create a test script

**Create file: `test/AMM.test.js`**
```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleAMM", function () {
    let SimpleAMM, simpleAMM;
    let TokenA, tokenA;
    let TokenB, tokenB;
    let owner, addr1, addr2;
    
    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        
        // Deploy test tokens
        TokenA = await ethers.getContractFactory("MyFirstToken");
        tokenA = await TokenA.deploy("Token A", "TKA", ethers.utils.parseEther("1000000"), 0);
        
        TokenB = await ethers.getContractFactory("MyFirstToken");
        tokenB = await TokenB.deploy("Token B", "TKB", ethers.utils.parseEther("1000000"), 0);
        
        // Deploy AMM
        SimpleAMM = await ethers.getContractFactory("SimpleAMM");
        simpleAMM = await SimpleAMM.deploy(tokenA.address, tokenB.address);
        
        // Mint tokens to test accounts
        await tokenA.mintFor(addr1.address, ethers.utils.parseEther("1000"));
        await tokenB.mintFor(addr1.address, ethers.utils.parseEther("1000"));
    });
    
    describe("Liquidity", function () {
        it("Should add liquidity correctly", async function () {
            const amountA = ethers.utils.parseEther("100");
            const amountB = ethers.utils.parseEther("100");
            
            await tokenA.connect(addr1).approve(simpleAMM.address, amountA);
            await tokenB.connect(addr1).approve(simpleAMM.address, amountB);
            
            await simpleAMM.connect(addr1).addLiquidity(amountA, amountB);
            
            const reserves = await simpleAMM.getReserves();
            expect(reserves[0]).to.equal(amountA);
            expect(reserves[1]).to.equal(amountB);
        });
    });
    
    describe("Swapping", function () {
        beforeEach(async function () {
            // Add initial liquidity
            const amountA = ethers.utils.parseEther("1000");
            const amountB = ethers.utils.parseEther("1000");
            
            await tokenA.connect(addr1).approve(simpleAMM.address, amountA);
            await tokenB.connect(addr1).approve(simpleAMM.address, amountB);
            await simpleAMM.connect(addr1).addLiquidity(amountA, amountB);
        });
        
        it("Should swap A for B correctly", async function () {
            const swapAmount = ethers.utils.parseEther("10");
            const initialBalance = await tokenB.balanceOf(addr2.address);
            
            await tokenA.connect(addr2).approve(simpleAMM.address, swapAmount);
            await simpleAMM.connect(addr2).swapAForB(swapAmount);
            
            const finalBalance = await tokenB.balanceOf(addr2.address);
            expect(finalBalance).to.be.gt(initialBalance);
        });
        
        it("Should calculate correct output amount", async function () {
            const swapAmount = ethers.utils.parseEther("10");
            const expectedOut = await simpleAMM.getSwapAmountOut(swapAmount, true);
            
            await tokenA.connect(addr2).approve(simpleAMM.address, swapAmount);
            await simpleAMM.connect(addr2).swapAForB(swapAmount);
            
            const balance = await tokenB.balanceOf(addr2.address);
            expect(balance).to.equal(expectedOut);
        });
    });
});
```

**Run the tests:**
```bash
npx hardhat test test/AMM.test.js
```

**Success Criteria:**
- [ ] All tests pass
- [ ] Can add and remove liquidity
- [ ] Can swap tokens in both directions
- [ ] Output amounts are calculated correctly

### Task 5: Compare AMMs with Odoo Inventory Management (30 minutes)
**What to do:**
- Think about how AMMs compare to inventory management
- Consider the similarities and differences

**Comparison Exercise:**
| Odoo Inventory | AMM Liquidity | Similarities | Differences |
|---------------|---------------|-------------|-------------|
| Stock levels | Token reserves | Track quantities | Real-time updates |
| Reorder points | Liquidity thresholds | Minimum levels | Automated rebalancing |
| Cost methods | Price discovery | Valuation methods | Algorithmic pricing |
| Stock moves | Token swaps | Movement tracking | Permissionless |
| Warehouse locations | Liquidity pools | Storage locations | Global accessibility |

**Success Criteria:**
- [ ] Can identify parallels between inventory and liquidity management
- [ ] Understand how AMMs automate market making
- [ ] See how your ERP experience applies to DeFi

### Task 6: Study Real DeFi Protocols (30 minutes)
**What to do:**
- Visit Uniswap.org and explore the interface
- Look at DeFi Pulse to understand the ecosystem
- Read about recent DeFi developments

**Resources:**
- [Uniswap Interface](https://app.uniswap.org/)
- [DeFi Pulse](https://defipulse.com/)
- [DeFi Llama](https://defillama.com/)

**Success Criteria:**
- [ ] Can navigate Uniswap interface
- [ ] Understand TVL (Total Value Locked) concept
- [ ] Know the major DeFi protocols

## 📚 Additional Resources
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper-v2.pdf)
- [AMM Math](https://uniswap.org/whitepaper-v3.pdf)
- [DeFi Safety](https://defisafety.com/)

## 🎯 Reflection Questions
1. How do AMMs compare to traditional order book exchanges?
2. What advantages do automated market makers offer?
3. How might impermanent loss affect liquidity providers?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 5 - Yield Farming and Staking Mechanisms 