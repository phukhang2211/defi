# Project 1: Simple Token Contract

## 🎯 Project Overview

Build your first ERC-20 token contract and learn the fundamentals of token creation, distribution, and management.

## 📋 Learning Objectives

- Understand ERC-20 token standards
- Implement basic token functionality
- Learn about token economics
- Practice deployment and testing

## 🏗️ Project Structure

```
01-simple-token/
├── contracts/
│   ├── SimpleToken.sol
│   └── TokenVesting.sol
├── test/
│   └── SimpleToken.test.js
├── scripts/
│   └── deploy.js
├── hardhat.config.js
└── README.md
```

## 🔧 Implementation

### 1. Basic ERC-20 Token

```solidity
// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken is ERC20, Ownable {
    uint256 public maxSupply;
    uint256 public mintPrice;
    
    event TokensMinted(address indexed to, uint256 amount, uint256 cost);
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC20(name, symbol) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
    }
    
    function mint(uint256 amount) external payable {
        require(msg.value >= mintPrice * amount, "Insufficient payment");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount, msg.value);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
```

### 2. Token Vesting Contract

```solidity
// contracts/TokenVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenVesting is ReentrancyGuard {
    IERC20 public token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        bool isActive;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration
    ) external {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount > 0, "Amount must be positive");
        require(startTime >= block.timestamp, "Start time must be in future");
        require(duration > 0, "Duration must be positive");
        require(!vestingSchedules[beneficiary].isActive, "Vesting already exists");
        
        token.transferFrom(msg.sender, address(this), amount);
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTime: startTime,
            duration: duration,
            isActive: true
        });
        
        emit VestingCreated(beneficiary, amount, startTime, duration);
    }
    
    function release() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.isActive, "No vesting schedule");
        
        uint256 releasable = getReleasableAmount(msg.sender);
        require(releasable > 0, "No tokens to release");
        
        schedule.releasedAmount += releasable;
        token.transfer(msg.sender, releasable);
        
        emit TokensReleased(msg.sender, releasable);
    }
    
    function getReleasableAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (!schedule.isActive) return 0;
        
        if (block.timestamp < schedule.startTime) return 0;
        
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 totalVestingTime = schedule.duration;
        
        if (timeElapsed >= totalVestingTime) {
            return schedule.totalAmount - schedule.releasedAmount;
        } else {
            uint256 vestedAmount = (schedule.totalAmount * timeElapsed) / totalVestingTime;
            return vestedAmount - schedule.releasedAmount;
        }
    }
}
```

## 🧪 Testing

```javascript
// test/SimpleToken.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleToken", function () {
    let SimpleToken;
    let simpleToken;
    let owner;
    let addr1;
    let addr2;
    
    beforeEach(async function () {
        SimpleToken = await ethers.getContractFactory("SimpleToken");
        [owner, addr1, addr2] = await ethers.getSigners();
        
        simpleToken = await SimpleToken.deploy(
            "My Token",
            "MTK",
            ethers.utils.parseEther("1000000"), // 1M max supply
            ethers.utils.parseEther("0.001")    // 0.001 ETH per token
        );
        await simpleToken.deployed();
    });
    
    describe("Deployment", function () {
        it("Should set the right name and symbol", async function () {
            expect(await simpleToken.name()).to.equal("My Token");
            expect(await simpleToken.symbol()).to.equal("MTK");
        });
        
        it("Should set the right max supply and mint price", async function () {
            expect(await simpleToken.maxSupply()).to.equal(ethers.utils.parseEther("1000000"));
            expect(await simpleToken.mintPrice()).to.equal(ethers.utils.parseEther("0.001"));
        });
    });
    
    describe("Minting", function () {
        it("Should mint tokens when payment is sufficient", async function () {
            const mintAmount = 100;
            const mintCost = mintAmount * 0.001;
            
            await simpleToken.connect(addr1).mint(mintAmount, {
                value: ethers.utils.parseEther(mintCost.toString())
            });
            
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                ethers.utils.parseEther(mintAmount.toString())
            );
        });
        
        it("Should fail when payment is insufficient", async function () {
            const mintAmount = 100;
            const insufficientCost = 0.05; // Less than required
            
            await expect(
                simpleToken.connect(addr1).mint(mintAmount, {
                    value: ethers.utils.parseEther(insufficientCost.toString())
                })
            ).to.be.revertedWith("Insufficient payment");
        });
    });
    
    describe("Burning", function () {
        it("Should burn tokens correctly", async function () {
            // First mint some tokens
            await simpleToken.connect(addr1).mint(100, {
                value: ethers.utils.parseEther("0.1")
            });
            
            const initialBalance = await simpleToken.balanceOf(addr1.address);
            const burnAmount = ethers.utils.parseEther("50");
            
            await simpleToken.connect(addr1).burn(burnAmount);
            
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                initialBalance.sub(burnAmount)
            );
        });
    });
});
```

## 🚀 Deployment

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
    // Deploy SimpleToken
    const SimpleToken = await hre.ethers.getContractFactory("SimpleToken");
    const simpleToken = await SimpleToken.deploy(
        "My DeFi Token",
        "MDT",
        hre.ethers.utils.parseEther("1000000"), // 1M max supply
        hre.ethers.utils.parseEther("0.001")    // 0.001 ETH per token
    );
    await simpleToken.deployed();
    
    console.log("SimpleToken deployed to:", simpleToken.address);
    
    // Deploy TokenVesting
    const TokenVesting = await hre.ethers.getContractFactory("TokenVesting");
    const tokenVesting = await TokenVesting.deploy(simpleToken.address);
    await tokenVesting.deployed();
    
    console.log("TokenVesting deployed to:", tokenVesting.address);
    
    // Verify contracts on Etherscan (if not on hardhat network)
    if (hre.network.name !== "hardhat") {
        console.log("Waiting for block confirmations...");
        await simpleToken.deployTransaction.wait(6);
        await tokenVesting.deployTransaction.wait(6);
        
        await hre.run("verify:verify", {
            address: simpleToken.address,
            constructorArguments: [
                "My DeFi Token",
                "MDT",
                hre.ethers.utils.parseEther("1000000"),
                hre.ethers.utils.parseEther("0.001")
            ],
        });
        
        await hre.run("verify:verify", {
            address: tokenVesting.address,
            constructorArguments: [simpleToken.address],
        });
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

## 📊 Token Economics

### Token Distribution
- **Total Supply**: 1,000,000 tokens
- **Mint Price**: 0.001 ETH per token
- **Vesting**: 20% for team (2-year linear vesting)
- **Liquidity**: 30% for DEX liquidity
- **Community**: 50% for public minting

### Use Cases
1. **Governance**: Token holders can vote on protocol decisions
2. **Staking**: Earn rewards by staking tokens
3. **Liquidity Mining**: Provide liquidity to earn tokens
4. **Access**: Special access to premium features

## 🎯 Key Learnings

1. **ERC-20 Standard**: Understanding the basic token interface
2. **Token Economics**: Designing sustainable token models
3. **Vesting**: Managing token distribution over time
4. **Testing**: Comprehensive testing of token functionality
5. **Deployment**: Safe deployment practices

## 🚀 Next Steps

1. Deploy to testnet (Goerli/Sepolia)
2. Add more advanced features (minting limits, pause functionality)
3. Integrate with DEX for trading
4. Build a frontend for token management

---

*Ready for the next project? Let's build a DEX in Project 2!* 