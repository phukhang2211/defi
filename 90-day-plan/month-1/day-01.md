# Day 1: Welcome to DeFi - Setting Up Your Foundation

## 🎯 Learning Objective
Understand the basics of blockchain technology and set up your development environment for DeFi development.

## ⏰ Time Estimate
4-6 hours

## 📋 Tasks

### Task 1: Understanding Blockchain Basics (1 hour)
**What to do:**
- Read the introduction section of Module 1 (Blockchain Fundamentals)
- Watch: "What is Blockchain?" by 3Blue1Brown (15 min)
- Take notes on key concepts: blocks, hashes, consensus, decentralization

**Resources:**
- [3Blue1Brown: What is Blockchain?](https://www.youtube.com/watch?v=bBC-nXj3Ng4)
- [Ethereum.org: What is Ethereum?](https://ethereum.org/en/what-is-ethereum/)

**Success Criteria:**
- [ ] Can explain blockchain in simple terms
- [ ] Understand the difference between centralized and decentralized systems
- [ ] Know what a hash function is

### Task 2: Install Development Tools (1 hour)
**What to do:**
- Install Node.js (v16 or higher)
- Install Git
- Install VS Code with Solidity extension
- Install MetaMask browser extension

**Commands to run:**
```bash
# Check Node.js installation
node --version
npm --version

# Check Git installation
git --version

# Create your DeFi project directory
mkdir defi-learning
cd defi-learning
git init
```

**Success Criteria:**
- [ ] Node.js v16+ installed
- [ ] Git configured with your details
- [ ] VS Code with Solidity extension installed
- [ ] MetaMask installed and set up

### Task 3: Set Up Hardhat Development Environment (1 hour)
**What to do:**
- Initialize npm project
- Install Hardhat and dependencies
- Create basic Hardhat configuration

**Commands to run:**
```bash
# Initialize npm project
npm init -y

# Install Hardhat and dependencies
npm install --save-dev hardhat @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers
npm install --save-dev @openzeppelin/contracts dotenv

# Initialize Hardhat
npx hardhat

# Choose "Create a JavaScript project"
# This will create the basic project structure
```

**Success Criteria:**
- [ ] Hardhat project initialized
- [ ] All dependencies installed
- [ ] Can run `npx hardhat compile` successfully

### Task 4: Configure MetaMask for Development (30 minutes)
**What to do:**
- Add localhost network to MetaMask
- Import test account from Hardhat
- Get some test ETH

**Steps:**
1. Open MetaMask
2. Add network: Localhost 8545
3. Copy private key from Hardhat output
4. Import account to MetaMask
5. Verify you have 10,000 ETH

**Success Criteria:**
- [ ] Localhost network added to MetaMask
- [ ] Test account imported with 10,000 ETH
- [ ] Can see account balance in MetaMask

### Task 5: Deploy Your First Contract (1 hour)
**What to do:**
- Create a simple "Hello World" smart contract
- Compile and deploy it
- Interact with it through Hardhat console

**Create file: `contracts/HelloWorld.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;
    
    constructor() {
        message = "Hello, DeFi World!";
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
}
```

**Commands to run:**
```bash
# Compile the contract
npx hardhat compile

# Start local blockchain
npx hardhat node

# In new terminal, deploy contract
npx hardhat run scripts/deploy.js --network localhost

# Interact with contract
npx hardhat console --network localhost
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Contract deployed to localhost
- [ ] Can call getMessage() and get "Hello, DeFi World!"
- [ ] Can call setMessage() to change the message

### Task 6: Join DeFi Communities (30 minutes)
**What to do:**
- Join Discord: Ethereum Development
- Join Reddit: r/defi, r/ethereum
- Follow 5 DeFi developers on Twitter
- Create GitHub account if you don't have one

**Success Criteria:**
- [ ] Joined 3+ DeFi communities
- [ ] Following DeFi developers on social media
- [ ] GitHub account ready for projects

## 📚 Additional Resources
- [Ethereum Whitepaper](https://ethereum.org/en/whitepaper/)
- [Hardhat Documentation](https://hardhat.org/docs/)
- [MetaMask Documentation](https://docs.metamask.io/)

## 🎯 Reflection Questions
1. What surprised you most about blockchain technology?
2. How does blockchain compare to traditional databases you've worked with?
3. What challenges do you anticipate in learning Solidity?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 2 - Understanding Smart Contracts and Solidity Basics 