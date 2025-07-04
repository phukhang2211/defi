# Day 6: Lending and Borrowing Protocols

## 🎯 Learning Objective
Understand DeFi lending protocols and build a simple lending contract.

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding DeFi Lending (1 hour)
**What to do:**
- Learn about DeFi lending protocols
- Understand collateralization and liquidation
- Study interest rate models

**Resources:**
- [Aave Documentation](https://docs.aave.com/)
- [Compound Documentation](https://docs.compound.finance/)

**Key Concepts:**
- **Collateral**: Assets deposited to secure a loan
- **Collateralization Ratio**: Value of collateral vs borrowed amount
- **Liquidation**: Forced sale of collateral when ratio falls below threshold
- **Interest Rate Models**: How borrowing rates are calculated
- **Flash Loans**: Borrow without collateral (must be repaid in same transaction)

**Success Criteria:**
- [ ] Can explain how DeFi lending works
- [ ] Understand collateralization concepts
- [ ] Know the difference from traditional lending

### Task 2: Build a Simple Lending Contract (2 hours)
**What to do:**
- Create a basic lending protocol
- Implement deposit, borrow, and repay functions
- Add liquidation mechanism

**Create file: `contracts/SimpleLending.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleLending is ReentrancyGuard, Ownable {
    IERC20 public collateralToken;
    IERC20 public borrowToken;
    
    uint256 public constant COLLATERALIZATION_RATIO = 150; // 150%
    uint256 public constant LIQUIDATION_THRESHOLD = 125; // 125%
    uint256 public constant LIQUIDATION_BONUS = 5; // 5%
    
    uint256 public borrowRate = 10; // 10% annual
    uint256 public lastUpdateTime;
    
    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowBalance;
    mapping(address => uint256) public lastBorrowTime;
    
    uint256 public totalCollateral;
    uint256 public totalBorrowed;
    
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 collateralAmount);
    
    constructor(address _collateralToken, address _borrowToken) {
        collateralToken = IERC20(_collateralToken);
        borrowToken = IERC20(_borrowToken);
        lastUpdateTime = block.timestamp;
    }
    
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        
        collateralBalance[msg.sender] += amount;
        totalCollateral += amount;
        
        collateralToken.transferFrom(msg.sender, address(this), amount);
        
        emit Deposited(msg.sender, amount);
    }
    
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(canBorrow(msg.sender, amount), "Insufficient collateral");
        
        borrowBalance[msg.sender] += amount;
        totalBorrowed += amount;
        lastBorrowTime[msg.sender] = block.timestamp;
        
        borrowToken.transfer(msg.sender, amount);
        
        emit Borrowed(msg.sender, amount);
    }
    
    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(borrowBalance[msg.sender] >= amount, "Insufficient borrow balance");
        
        uint256 interest = calculateInterest(msg.sender);
        uint256 principal = amount > interest ? amount - interest : 0;
        
        if (principal > 0) {
            borrowBalance[msg.sender] -= principal;
            totalBorrowed -= principal;
        }
        
        borrowToken.transferFrom(msg.sender, address(this), amount);
        
        emit Repaid(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(collateralBalance[msg.sender] >= amount, "Insufficient collateral");
        require(canWithdraw(msg.sender, amount), "Would make position unsafe");
        
        collateralBalance[msg.sender] -= amount;
        totalCollateral -= amount;
        
        collateralToken.transfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function liquidate(address user) external nonReentrant {
        require(isLiquidatable(user), "Position not liquidatable");
        
        uint256 borrowAmount = borrowBalance[user];
        uint256 collateralAmount = collateralBalance[user];
        
        // Calculate liquidation bonus
        uint256 bonus = (collateralAmount * LIQUIDATION_BONUS) / 100;
        uint256 totalCollateralToLiquidator = collateralAmount + bonus;
        
        // Transfer collateral to liquidator
        collateralBalance[user] = 0;
        collateralBalance[msg.sender] += totalCollateralToLiquidator;
        totalCollateral -= bonus;
        
        // Transfer borrow debt to liquidator
        borrowBalance[msg.sender] += borrowAmount;
        borrowBalance[user] = 0;
        lastBorrowTime[msg.sender] = block.timestamp;
        
        // Transfer borrow tokens from liquidator to protocol
        borrowToken.transferFrom(msg.sender, address(this), borrowAmount);
        
        emit Liquidated(user, msg.sender, collateralAmount);
    }
    
    function canBorrow(address user, uint256 amount) public view returns (bool) {
        uint256 currentBorrow = borrowBalance[user] + amount;
        uint256 collateralValue = collateralBalance[user];
        
        return (collateralValue * 100) >= (currentBorrow * COLLATERALIZATION_RATIO);
    }
    
    function canWithdraw(address user, uint256 amount) public view returns (bool) {
        uint256 remainingCollateral = collateralBalance[user] - amount;
        uint256 borrowValue = borrowBalance[user];
        
        return (remainingCollateral * 100) >= (borrowValue * COLLATERALIZATION_RATIO);
    }
    
    function isLiquidatable(address user) public view returns (bool) {
        uint256 collateralValue = collateralBalance[user];
        uint256 borrowValue = borrowBalance[user];
        
        return (collateralValue * 100) < (borrowValue * LIQUIDATION_THRESHOLD);
    }
    
    function calculateInterest(address user) public view returns (uint256) {
        if (borrowBalance[user] == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastBorrowTime[user];
        return (borrowBalance[user] * borrowRate * timeElapsed) / (365 days * 100);
    }
    
    function getPosition(address user) external view returns (
        uint256 collateral,
        uint256 borrowed,
        uint256 interest,
        bool liquidatable
    ) {
        return (
            collateralBalance[user],
            borrowBalance[user],
            calculateInterest(user),
            isLiquidatable(user)
        );
    }
}
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Can deposit collateral
- [ ] Can borrow against collateral
- [ ] Can repay loans
- [ ] Can liquidate unsafe positions

### Task 3: Test Your Lending Contract (1 hour)
**What to do:**
- Deploy and test lending functionality
- Test liquidation scenarios

**Create file: `test/Lending.test.js`**
```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Simple Lending", function () {
    let SimpleLending, simpleLending;
    let CollateralToken, collateralToken;
    let BorrowToken, borrowToken;
    let owner, user1, user2, liquidator;
    
    beforeEach(async function () {
        [owner, user1, user2, liquidator] = await ethers.getSigners();
        
        // Deploy tokens
        CollateralToken = await ethers.getContractFactory("MyFirstToken");
        collateralToken = await CollateralToken.deploy("Collateral", "COL", ethers.utils.parseEther("1000000"), 0);
        
        BorrowToken = await ethers.getContractFactory("MyFirstToken");
        borrowToken = await BorrowToken.deploy("Borrow", "BOR", ethers.utils.parseEther("1000000"), 0);
        
        // Deploy lending contract
        SimpleLending = await ethers.getContractFactory("SimpleLending");
        simpleLending = await SimpleLending.deploy(collateralToken.address, borrowToken.address);
        
        // Mint tokens
        await collateralToken.mintFor(user1.address, ethers.utils.parseEther("1000"));
        await borrowToken.mintFor(simpleLending.address, ethers.utils.parseEther("10000"));
        await borrowToken.mintFor(liquidator.address, ethers.utils.parseEther("1000"));
    });
    
    it("Should deposit collateral correctly", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        
        await collateralToken.connect(user1).approve(simpleLending.address, depositAmount);
        await simpleLending.connect(user1).deposit(depositAmount);
        
        const position = await simpleLending.getPosition(user1.address);
        expect(position.collateral).to.equal(depositAmount);
    });
    
    it("Should borrow against collateral", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        const borrowAmount = ethers.utils.parseEther("50");
        
        await collateralToken.connect(user1).approve(simpleLending.address, depositAmount);
        await simpleLending.connect(user1).deposit(depositAmount);
        
        await simpleLending.connect(user1).borrow(borrowAmount);
        
        const position = await simpleLending.getPosition(user1.address);
        expect(position.borrowed).to.equal(borrowAmount);
    });
    
    it("Should prevent over-borrowing", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        const borrowAmount = ethers.utils.parseEther("100"); // Too much
        
        await collateralToken.connect(user1).approve(simpleLending.address, depositAmount);
        await simpleLending.connect(user1).deposit(depositAmount);
        
        await expect(
            simpleLending.connect(user1).borrow(borrowAmount)
        ).to.be.revertedWith("Insufficient collateral");
    });
});
```

**Success Criteria:**
- [ ] All tests pass
- [ ] Can deposit and borrow correctly
- [ ] Collateralization checks work

### Task 4: Compare with Odoo Accounting (30 minutes)
**What to do:**
- Think about how DeFi lending compares to traditional accounting
- Consider the similarities and differences

**Comparison Exercise:**
| Odoo Accounting | DeFi Lending | Similarities | Differences |
|----------------|-------------|-------------|-------------|
| Accounts receivable | Borrowed amounts | Track money owed | Real-time updates |
| Collateral management | Collateralization | Asset backing | Automated enforcement |
| Interest calculations | Dynamic rates | Time-based accrual | Market-driven rates |

**Success Criteria:**
- [ ] Can identify parallels between accounting and DeFi lending
- [ ] Understand how smart contracts automate lending processes

## 📚 Additional Resources
- [Aave Whitepaper](https://github.com/aave/aave-protocol/blob/master/docs/Aave_Protocol_Whitepaper_v1_0.pdf)
- [Compound Whitepaper](https://compound.finance/documents/Compound.Whitepaper.pdf)

## 🎯 Reflection Questions
1. How do DeFi lending protocols compare to traditional banks?
2. What advantages do collateral-based lending offer?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 7 - Security and Best Practices 