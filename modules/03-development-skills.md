# Module 3: Development Skills

## 🎯 Learning Objectives
- Master Solidity programming language
- Develop and deploy smart contracts
- Build frontend applications with Web3 integration
- Implement comprehensive testing strategies
- Deploy to mainnet safely

## 🔧 Solidity Programming: From Python to Solidity

### Language Comparison

| Python (Odoo) | Solidity | Purpose |
|---------------|----------|---------|
| `def function()` | `function function()` | Function definition |
| `self.variable` | `this.variable` | Instance reference |
| `@property` | `view` functions | Read-only access |
| `try/except` | `require/revert` | Error handling |
| `class Model` | `contract Contract` | Data structure |

### Basic Solidity Syntax
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicContract {
    // State variables (like Odoo model fields)
    string public name;
    uint256 public balance;
    address public owner;
    
    // Events (like Odoo logging)
    event BalanceUpdated(address indexed user, uint256 newBalance);
    
    // Constructor (like Odoo __init__)
    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }
    
    // Modifier (like Odoo security rules)
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    // Function (like Odoo method)
    function updateBalance(uint256 _newBalance) external {
        balance = _newBalance;
        emit BalanceUpdated(msg.sender, _newBalance);
    }
    
    // View function (like Odoo computed field)
    function getBalance() external view returns (uint256) {
        return balance;
    }
}
```

## 🏗️ Smart Contract Development Patterns

### 1. Access Control Pattern
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControlExample is Ownable {
    mapping(address => bool) public operators;
    
    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }
    
    function addOperator(address _operator) external onlyOwner {
        operators[_operator] = true;
    }
    
    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
    }
    
    function sensitiveFunction() external onlyOperator {
        // Only operators or owner can call this
    }
}
```

### 2. Factory Pattern (Like Odoo's Model Creation)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenFactory {
    address[] public deployedTokens;
    
    function createToken(string memory name, string memory symbol) external {
        Token newToken = new Token(name, symbol, msg.sender);
        deployedTokens.push(address(newToken));
    }
    
    function getDeployedTokens() external view returns (address[] memory) {
        return deployedTokens;
    }
}

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    
    constructor(string memory _name, string memory _symbol, address _owner) {
        name = _name;
        symbol = _symbol;
        owner = _owner;
    }
}
```

## 🧪 Testing Smart Contracts

### Testing Framework Setup
```javascript
// test/Token.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Token Contract", function () {
    let Token;
    let token;
    let owner;
    let addr1;
    let addr2;
    
    beforeEach(async function () {
        Token = await ethers.getContractFactory("Token");
        [owner, addr1, addr2] = await ethers.getSigners();
        token = await Token.deploy("Test Token", "TST");
        await token.deployed();
    });
    
    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await token.owner()).to.equal(owner.address);
        });
        
        it("Should assign the total supply to the owner", async function () {
            const ownerBalance = await token.balanceOf(owner.address);
            expect(await token.totalSupply()).to.equal(ownerBalance);
        });
    });
    
    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
            await token.transfer(addr1.address, 50);
            const addr1Balance = await token.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(50);
        });
    });
});
```

## 🌐 Frontend Development with Web3

### React + Web3 Integration
```javascript
// components/Web3Provider.js
import React, { createContext, useContext, useState, useEffect } from 'react';
import Web3 from 'web3';

const Web3Context = createContext();

export function Web3Provider({ children }) {
    const [web3, setWeb3] = useState(null);
    const [account, setAccount] = useState(null);
    const [contracts, setContracts] = useState({});
    
    const connectWallet = async () => {
        if (window.ethereum) {
            try {
                await window.ethereum.request({ method: 'eth_requestAccounts' });
                const web3Instance = new Web3(window.ethereum);
                setWeb3(web3Instance);
                
                const accounts = await web3Instance.eth.getAccounts();
                setAccount(accounts[0]);
                
                // Load contracts
                await loadContracts(web3Instance);
            } catch (error) {
                console.error('User denied account access');
            }
        } else {
            console.log('Please install MetaMask!');
        }
    };
    
    const loadContracts = async (web3Instance) => {
        // Load contract ABIs and addresses
        const tokenABI = require('../contracts/Token.json').abi;
        const ammABI = require('../contracts/SimpleAMM.json').abi;
        
        const tokenContract = new web3Instance.eth.Contract(
            tokenABI, 
            'CONTRACT_ADDRESS'
        );
        
        const ammContract = new web3Instance.eth.Contract(
            ammABI, 
            'AMM_CONTRACT_ADDRESS'
        );
        
        setContracts({ token: tokenContract, amm: ammContract });
    };
    
    return (
        <Web3Context.Provider value={{ 
            web3, 
            account, 
            contracts, 
            connectWallet 
        }}>
            {children}
        </Web3Context.Provider>
    );
}

export const useWeb3 = () => useContext(Web3Context);
```

## 🔒 Security Best Practices

### 1. Reentrancy Protection
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Update state before external call
        balances[msg.sender] -= amount;
        
        // External call (potential reentrancy point)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

### 2. Access Control
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureAccess is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function sensitiveFunction() external onlyRole(OPERATOR_ROLE) {
        // Only operators can call this
    }
}
```

## 🚀 Deployment Process

### 1. Hardhat Configuration
```javascript
// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    hardhat: {
      chainId: 1337
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

### 2. Deployment Script
```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
    // Deploy Token
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy("My Token", "MTK");
    await token.deployed();
    console.log("Token deployed to:", token.address);
    
    // Deploy AMM
    const AMM = await hre.ethers.getContractFactory("SimpleAMM");
    const amm = await AMM.deploy(token.address, "WETH_ADDRESS");
    await amm.deployed();
    console.log("AMM deployed to:", amm.address);
    
    // Verify contracts on Etherscan
    if (hre.network.name !== "hardhat") {
        await hre.run("verify:verify", {
            address: token.address,
            constructorArguments: ["My Token", "MTK"],
        });
        
        await hre.run("verify:verify", {
            address: amm.address,
            constructorArguments: [token.address, "WETH_ADDRESS"],
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

### 3. Environment Variables
```bash
# .env file
INFURA_PROJECT_ID=your_infura_project_id
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 📊 Gas Optimization

### Gas-Efficient Patterns
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasOptimized {
    // Pack related variables together
    struct User {
        uint128 balance;  // 16 bytes
        uint64 lastUpdate; // 8 bytes
        uint64 userId;     // 8 bytes
    } // Total: 32 bytes (1 slot)
    
    // Use events instead of storage for historical data
    event UserAction(address indexed user, uint256 action, uint256 timestamp);
    
    // Use external for functions only called externally
    function externalFunction() external {
        // More gas efficient than public
    }
    
    // Use view/pure when possible
    function calculateValue(uint256 input) public pure returns (uint256) {
        return input * 2;
    }
}
```

## 🎯 Key Takeaways

1. **Solidity is similar to Python** - but with strict typing and gas considerations
2. **Testing is crucial** - always test thoroughly before deployment
3. **Security first** - use established patterns and libraries
4. **Gas optimization matters** - every operation costs money
5. **Frontend integration** - Web3.js connects everything together

## 📚 Additional Resources

- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)
- [Hardhat Documentation](https://hardhat.org/docs/)
- [Web3.js Documentation](https://web3js.org/)

## 🚀 Next Steps

1. Complete the hands-on exercises
2. Deploy your first contract to testnet
3. Build a complete DeFi application
4. Move to Module 4: Advanced DeFi

---

*Ready for advanced concepts? Let's explore protocol development and cross-chain solutions in the next module.* 