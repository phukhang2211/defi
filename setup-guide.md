# DeFi Development Setup Guide

## 🛠️ Environment Setup

### Prerequisites
- **Node.js** (v16 or higher)
- **Git**
- **Code Editor** (VS Code recommended)
- **MetaMask** browser extension

### 1. Install Node.js Dependencies

```bash
# Install global packages
npm install -g hardhat
npm install -g truffle
npm install -g ganache-cli

# Verify installations
node --version
npm --version
hardhat --version
```

### 2. Project Setup

```bash
# Create project directory
mkdir defi-learning
cd defi-learning

# Initialize npm project
npm init -y

# Install development dependencies
npm install --save-dev hardhat @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers
npm install --save-dev @openzeppelin/contracts
npm install --save-dev dotenv
npm install --save-dev @nomiclabs/hardhat-etherscan

# Install runtime dependencies
npm install web3 ethers
```

### 3. Hardhat Configuration

```javascript
// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

### 4. Environment Variables

```bash
# .env file
INFURA_PROJECT_ID=your_infura_project_id
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
```

## 🔧 Development Tools Setup

### 1. MetaMask Configuration

1. **Install MetaMask** from [metamask.io](https://metamask.io)
2. **Create/Import Wallet**
3. **Add Test Networks**:
   - Goerli Testnet
   - Sepolia Testnet
   - Localhost 8545

### 2. Get Test ETH

- **Goerli Faucet**: [goerlifaucet.com](https://goerlifaucet.com)
- **Sepolia Faucet**: [sepoliafaucet.com](https://sepoliafaucet.com)
- **Alchemy Faucet**: [alchemy.com/faucets](https://alchemy.com/faucets)

### 3. IDE Setup (VS Code)

Install these extensions:
- **Solidity** by Juan Blanco
- **Hardhat Solidity** by NomicFoundation
- **Ethereum Remix** by Remix Project
- **Prettier** for code formatting

## 📁 Project Structure

```
defi-learning/
├── contracts/
│   ├── tokens/
│   ├── amm/
│   ├── lending/
│   └── governance/
├── test/
│   ├── unit/
│   └── integration/
├── scripts/
│   ├── deploy/
│   └── utils/
├── frontend/
│   ├── src/
│   ├── public/
│   └── package.json
├── docs/
├── hardhat.config.js
├── package.json
└── .env
```

## 🚀 Quick Start Commands

### Development
```bash
# Start local blockchain
npx hardhat node

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Run specific test
npx hardhat test test/Token.test.js

# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost

# Deploy to testnet
npx hardhat run scripts/deploy.js --network goerli
```

### Testing
```bash
# Run all tests
npm test

# Run with coverage
npx hardhat coverage

# Run gas estimation
npx hardhat test --gas
```

### Deployment
```bash
# Deploy to testnet
npx hardhat run scripts/deploy.js --network goerli

# Verify on Etherscan
npx hardhat verify --network goerli CONTRACT_ADDRESS "Constructor Arg 1" "Constructor Arg 2"

# Flatten contract for verification
npx hardhat flatten contracts/Token.sol > Token_flattened.sol
```

## 🔍 Debugging Tools

### 1. Hardhat Console
```bash
# Start interactive console
npx hardhat console --network localhost

# Example usage
const Token = await ethers.getContractFactory("Token")
const token = await Token.deploy("Test", "TST")
await token.deployed()
console.log("Token address:", token.address)
```

### 2. Hardhat Network
```bash
# Start with specific accounts
npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY

# Reset network
npx hardhat node --reset
```

### 3. Gas Profiling
```javascript
// In your test files
const gasUsed = await contract.functionName.estimateGas(params);
console.log("Gas used:", gasUsed.toString());
```

## 📊 Monitoring and Analytics

### 1. Etherscan Integration
```javascript
// scripts/verify.js
const hre = require("hardhat");

async function verify(contractAddress, constructorArguments) {
    try {
        await hre.run("verify:verify", {
            address: contractAddress,
            constructorArguments: constructorArguments,
        });
        console.log("Contract verified successfully");
    } catch (error) {
        console.error("Verification failed:", error);
    }
}

module.exports = { verify };
```

### 2. Event Monitoring
```javascript
// scripts/monitor.js
const { ethers } = require("hardhat");

async function monitorEvents() {
    const contract = await ethers.getContractAt("Token", "CONTRACT_ADDRESS");
    
    contract.on("Transfer", (from, to, amount, event) => {
        console.log(`Transfer: ${from} -> ${to}: ${ethers.utils.formatEther(amount)}`);
    });
    
    contract.on("Mint", (to, amount, event) => {
        console.log(`Mint: ${to}: ${ethers.utils.formatEther(amount)}`);
    });
}

monitorEvents();
```

## 🔒 Security Best Practices

### 1. Private Key Management
```bash
# Never commit private keys
echo ".env" >> .gitignore
echo "secrets.json" >> .gitignore
echo "*.key" >> .gitignore
```

### 2. Contract Security
```solidity
// Always use OpenZeppelin contracts
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Use modifiers for access control
modifier onlyOwner() {
    require(msg.sender == owner, "Not authorized");
    _;
}
```

### 3. Testing Security
```javascript
// Test for common vulnerabilities
describe("Security Tests", function () {
    it("Should prevent reentrancy attacks", async function () {
        // Test implementation
    });
    
    it("Should handle integer overflow", async function () {
        // Test implementation
    });
    
    it("Should restrict access to admin functions", async function () {
        // Test implementation
    });
});
```

## 🌐 Frontend Integration

### 1. React Setup
```bash
# Create React app
npx create-react-app frontend
cd frontend

# Install Web3 dependencies
npm install web3 @web3-react/core @web3-react/injected-connector
npm install ethers
```

### 2. Web3 Provider
```javascript
// src/providers/Web3Provider.js
import { Web3ReactProvider } from '@web3-react/core';
import { Web3Provider } from '@ethersproject/providers';

function getLibrary(provider) {
    const library = new Web3Provider(provider);
    library.pollingInterval = 12000;
    return library;
}

export function Web3Provider({ children }) {
    return (
        <Web3ReactProvider getLibrary={getLibrary}>
            {children}
        </Web3ReactProvider>
    );
}
```

### 3. Contract Integration
```javascript
// src/hooks/useContract.js
import { useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';
import TokenABI from '../contracts/Token.json';

export function useContract(address, ABI) {
    const { library, account } = useWeb3React();
    
    const contract = new ethers.Contract(address, ABI, library.getSigner(account));
    
    return contract;
}
```

## 📚 Learning Resources

### Documentation
- [Ethereum.org](https://ethereum.org/en/developers/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Hardhat Docs](https://hardhat.org/docs/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/)

### Tools
- [Remix IDE](https://remix.ethereum.org/)
- [Etherscan](https://etherscan.io/)
- [DeFi Pulse](https://defipulse.com/)
- [DeFi Llama](https://defillama.com/)

### Communities
- [Ethereum Stack Exchange](https://ethereum.stackexchange.com/)
- [Reddit r/defi](https://reddit.com/r/defi)
- [Discord DeFi communities](https://discord.gg/defi)

## 🎯 Next Steps

1. **Complete the setup** - Ensure all tools are working
2. **Run the first project** - Deploy a simple token
3. **Join communities** - Connect with other developers
4. **Start building** - Begin with the practical projects

---

*Your DeFi development environment is now ready! Let's start building.* 