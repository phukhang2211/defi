# Day 7: Security and Best Practices

## 🎯 Learning Objective
Learn about smart contract security, common vulnerabilities, and best practices.

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding Smart Contract Security (1 hour)
**What to do:**
- Learn about common smart contract vulnerabilities
- Understand the importance of security in DeFi
- Study famous hacks and their causes

**Resources:**
- [ConsenSys Smart Contract Security](https://consensys.net/diligence/)
- [OpenZeppelin Security](https://docs.openzeppelin.com/learn/)

**Key Vulnerabilities:**
- **Reentrancy**: Function called before previous execution completes
- **Integer Overflow/Underflow**: Numbers exceed maximum/minimum values
- **Access Control**: Unauthorized access to sensitive functions
- **Front-running**: Transactions executed before intended transaction
- **Oracle Manipulation**: Incorrect price data from external sources

**Famous Hacks:**
- **The DAO Hack (2016)**: $60M stolen due to reentrancy
- **Parity Wallet Bug (2017)**: $30M frozen due to access control
- **bZx Flash Loan Attack (2020)**: Oracle manipulation

**Success Criteria:**
- [ ] Can explain common vulnerabilities
- [ ] Understand why security is critical in DeFi
- [ ] Know examples of major hacks

### Task 2: Learn Security Best Practices (1 hour)
**What to do:**
- Study security best practices
- Learn about security tools and frameworks
- Understand the security development lifecycle

**Best Practices:**
1. **Use OpenZeppelin**: Battle-tested libraries
2. **Follow Checks-Effects-Interactions**: Prevent reentrancy
3. **Implement Access Control**: Restrict sensitive functions
4. **Use SafeMath**: Prevent overflow/underflow
5. **Test Thoroughly**: Comprehensive testing
6. **Audit Code**: Professional security audits
7. **Use Multi-sig**: Multiple signatures for critical operations

**Security Tools:**
- **Slither**: Static analysis tool
- **Mythril**: Symbolic execution
- **Echidna**: Fuzzing tool
- **Manticore**: Binary analysis

**Success Criteria:**
- [ ] Know security best practices
- [ ] Understand security tools
- [ ] Can identify security patterns

### Task 3: Build a Secure Contract (2 hours)
**What to do:**
- Create a secure version of a previous contract
- Implement security best practices
- Add access controls and safety checks

**Create file: `contracts/SecureVault.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SecureVault is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    
    IERC20 public token;
    
    mapping(address => uint256) private balances;
    mapping(address => uint256) private lastDepositTime;
    
    uint256 public constant LOCK_PERIOD = 7 days;
    uint256 public constant MAX_DEPOSIT = 1000 * 10**18; // 1000 tokens
    uint256 public constant MIN_DEPOSIT = 1 * 10**18; // 1 token
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }
    
    modifier onlyAfterLockPeriod(address user) {
        require(
            block.timestamp >= lastDepositTime[user].add(LOCK_PERIOD),
            "Lock period not expired"
        );
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount >= MIN_DEPOSIT, "Amount too small");
        require(amount <= MAX_DEPOSIT, "Amount too large");
        _;
    }
    
    function deposit(uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        validAmount(amount) 
    {
        // Checks
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(
            balances[msg.sender].add(amount) <= MAX_DEPOSIT,
            "Exceeds max deposit"
        );
        
        // Effects
        balances[msg.sender] = balances[msg.sender].add(amount);
        lastDepositTime[msg.sender] = block.timestamp;
        
        // Interactions
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyAfterLockPeriod(msg.sender) 
    {
        // Checks
        require(amount > 0, "Amount must be positive");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Effects
        balances[msg.sender] = balances[msg.sender].sub(amount);
        
        // Interactions
        require(
            token.transfer(msg.sender, amount),
            "Transfer failed"
        );
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function emergencyWithdraw() 
        external 
        nonReentrant 
        onlyOwner 
    {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        require(
            token.transfer(owner(), balance),
            "Transfer failed"
        );
        
        emit EmergencyWithdraw(owner(), balance);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getLockTime(address user) external view returns (uint256) {
        return lastDepositTime[user];
    }
    
    function canWithdraw(address user) external view returns (bool) {
        return block.timestamp >= lastDepositTime[user].add(LOCK_PERIOD);
    }
    
    function getVaultInfo() external view returns (
        uint256 totalDeposits,
        uint256 maxDeposit,
        uint256 minDeposit,
        uint256 lockPeriod,
        bool paused
    ) {
        return (
            token.balanceOf(address(this)),
            MAX_DEPOSIT,
            MIN_DEPOSIT,
            LOCK_PERIOD,
            paused()
        );
    }
}
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Implements security best practices
- [ ] Has proper access controls
- [ ] Uses SafeMath for calculations

### Task 4: Test Security Features (1 hour)
**What to do:**
- Test security features of your contract
- Try to exploit vulnerabilities
- Verify safety mechanisms work

**Create file: `test/Security.test.js`**
```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Secure Vault", function () {
    let SecureVault, secureVault;
    let Token, token;
    let owner, user1, user2, attacker;
    
    beforeEach(async function () {
        [owner, user1, user2, attacker] = await ethers.getSigners();
        
        // Deploy token
        Token = await ethers.getContractFactory("MyFirstToken");
        token = await Token.deploy("Test Token", "TEST", ethers.utils.parseEther("1000000"), 0);
        
        // Deploy secure vault
        SecureVault = await ethers.getContractFactory("SecureVault");
        secureVault = await SecureVault.deploy(token.address);
        
        // Mint tokens to users
        await token.mintFor(user1.address, ethers.utils.parseEther("1000"));
        await token.mintFor(user2.address, ethers.utils.parseEther("1000"));
    });
    
    it("Should deposit tokens securely", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        
        await token.connect(user1).approve(secureVault.address, depositAmount);
        await secureVault.connect(user1).deposit(depositAmount);
        
        const balance = await secureVault.getBalance(user1.address);
        expect(balance).to.equal(depositAmount);
    });
    
    it("Should prevent withdrawal before lock period", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        
        await token.connect(user1).approve(secureVault.address, depositAmount);
        await secureVault.connect(user1).deposit(depositAmount);
        
        await expect(
            secureVault.connect(user1).withdraw(depositAmount)
        ).to.be.revertedWith("Lock period not expired");
    });
    
    it("Should allow withdrawal after lock period", async function () {
        const depositAmount = ethers.utils.parseEther("100");
        
        await token.connect(user1).approve(secureVault.address, depositAmount);
        await secureVault.connect(user1).deposit(depositAmount);
        
        // Fast forward time
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // 7 days
        await ethers.provider.send("evm_mine");
        
        await secureVault.connect(user1).withdraw(depositAmount);
        
        const balance = await secureVault.getBalance(user1.address);
        expect(balance).to.equal(0);
    });
    
    it("Should prevent deposits when paused", async function () {
        await secureVault.connect(owner).pause();
        
        const depositAmount = ethers.utils.parseEther("100");
        await token.connect(user1).approve(secureVault.address, depositAmount);
        
        await expect(
            secureVault.connect(user1).deposit(depositAmount)
        ).to.be.revertedWith("Pausable: paused");
    });
    
    it("Should prevent non-owner from pausing", async function () {
        await expect(
            secureVault.connect(user1).pause()
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    
    it("Should enforce deposit limits", async function () {
        const tooLargeAmount = ethers.utils.parseEther("2000"); // Exceeds max
        
        await token.connect(user1).approve(secureVault.address, tooLargeAmount);
        
        await expect(
            secureVault.connect(user1).deposit(tooLargeAmount)
        ).to.be.revertedWith("Amount too large");
    });
});
```

**Success Criteria:**
- [ ] All security tests pass
- [ ] Lock period enforcement works
- [ ] Access controls function properly
- [ ] Deposit limits are enforced

### Task 5: Compare with Odoo Security (30 minutes)
**What to do:**
- Think about how smart contract security compares to Odoo security
- Consider the similarities and differences

**Comparison Exercise:**
| Odoo Security | Smart Contract Security | Similarities | Differences |
|---------------|------------------------|-------------|-------------|
| User permissions | Access controls | Role-based access | Immutable once deployed |
| Data validation | Input validation | Prevent bad data | Public verification |
| Audit trails | Events and logs | Track changes | On-chain transparency |
| Backup systems | Emergency functions | Recovery mechanisms | No rollback possible |

**Success Criteria:**
- [ ] Can identify parallels between Odoo and smart contract security
- [ ] Understand unique challenges of blockchain security

### Task 6: Study Security Tools (30 minutes)
**What to do:**
- Learn about security analysis tools
- Understand how to use them
- Practice with your contracts

**Tools to Explore:**
- **Slither**: `pip install slither-analyzer`
- **Mythril**: `pip install mythril`
- **Remix Security**: Built into Remix IDE
- **Hardhat Security**: Hardhat plugins

**Success Criteria:**
- [ ] Know how to use basic security tools
- [ ] Can run security analysis on contracts
- [ ] Understand security report output

## 📚 Additional Resources
- [ConsenSys Diligence](https://consensys.net/diligence/)
- [OpenZeppelin Security](https://docs.openzeppelin.com/learn/)
- [SWC Registry](https://swcregistry.io/)

## 🎯 Reflection Questions
1. How does smart contract security differ from traditional software security?
2. What unique challenges does DeFi security present?
3. How can your Odoo security experience help in DeFi?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Week 1 Complete!** You've built a solid foundation in DeFi development. Next week focuses on advanced concepts and real-world projects. 