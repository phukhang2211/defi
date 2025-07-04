# Day 3: ERC-20 Tokens and Your First Token Contract

## 🎯 Learning Objective
Understand ERC-20 token standard and create your first token contract.

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding ERC-20 Standard (1 hour)
**What to do:**
- Learn about ERC-20 token standard
- Understand why standards are important
- Compare tokens to traditional currencies

**Resources:**
- [Ethereum.org: ERC-20](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/)
- [OpenZeppelin: ERC-20](https://docs.openzeppelin.com/contracts/4.x/erc20)

**Key Concepts:**
- **ERC-20**: Standard interface for fungible tokens
- **Fungible**: Each token is identical and interchangeable
- **Standard Functions**: transfer, approve, transferFrom, balanceOf, totalSupply
- **Events**: Transfer, Approval events for tracking

**Success Criteria:**
- [ ] Can explain what ERC-20 is
- [ ] Understand why token standards matter
- [ ] Know the basic ERC-20 functions

### Task 2: Study ERC-20 Interface (1 hour)
**What to do:**
- Examine the ERC-20 interface
- Understand each function's purpose
- Compare to Odoo model methods

**ERC-20 Interface:**
```solidity
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

**Function Analysis:**
| Function | Purpose | Odoo Equivalent |
|----------|---------|-----------------|
| `totalSupply()` | Get total tokens in existence | Model record count |
| `balanceOf()` | Get user's token balance | User's record count |
| `transfer()` | Send tokens to another address | Record assignment |
| `approve()` | Allow another address to spend your tokens | User permissions |
| `transferFrom()` | Transfer tokens on behalf of another user | Proxy actions |
| `allowance()` | Check how many tokens a spender can use | Permission check |

**Success Criteria:**
- [ ] Understand each ERC-20 function
- [ ] Can explain the approval mechanism
- [ ] See parallels with Odoo user management

### Task 3: Create Your First Token Contract (1.5 hours)
**What to do:**
- Build a simple ERC-20 token using OpenZeppelin
- Deploy and test it

**Create file: `contracts/MyFirstToken.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyFirstToken is ERC20, Ownable {
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
        
        // Mint initial supply to owner (10% of max supply)
        uint256 initialSupply = _maxSupply * 10 / 100;
        _mint(msg.sender, initialSupply);
    }
    
    function mint(uint256 amount) external payable {
        require(msg.value >= mintPrice * amount, "Insufficient payment");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount, msg.value);
    }
    
    function mintFor(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount, 0);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function getTokenInfo() external view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint256 currentSupply,
        uint256 maximumSupply,
        uint256 currentPrice
    ) {
        return (name(), symbol(), totalSupply(), maxSupply, mintPrice);
    }
}
```

**Success Criteria:**
- [ ] Contract compiles without errors
- [ ] Can deploy token with custom name and symbol
- [ ] Can mint tokens by paying ETH
- [ ] Can burn tokens
- [ ] Owner can mint tokens for free

### Task 4: Deploy and Test Your Token (1 hour)
**What to do:**
- Deploy your token to local network
- Test all functions
- Create a deployment script

**Create file: `scripts/deploy-token.js`**
```javascript
const hre = require("hardhat");

async function main() {
    const MyFirstToken = await hre.ethers.getContractFactory("MyFirstToken");
    
    const token = await MyFirstToken.deploy(
        "My DeFi Token",           // Name
        "MDT",                     // Symbol
        hre.ethers.utils.parseEther("1000000"),  // Max supply: 1M tokens
        hre.ethers.utils.parseEther("0.001")     // Mint price: 0.001 ETH
    );
    
    await token.deployed();
    
    console.log("MyFirstToken deployed to:", token.address);
    
    // Get token info
    const info = await token.getTokenInfo();
    console.log("Token Name:", info.tokenName);
    console.log("Token Symbol:", info.tokenSymbol);
    console.log("Current Supply:", hre.ethers.utils.formatEther(info.currentSupply));
    console.log("Max Supply:", hre.ethers.utils.formatEther(info.maximumSupply));
    console.log("Mint Price:", hre.ethers.utils.formatEther(info.currentPrice), "ETH");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

**Deploy and Test:**
```bash
# Deploy to local network
npx hardhat run scripts/deploy-token.js --network localhost

# Interact with contract
npx hardhat console --network localhost

# In console:
const Token = await ethers.getContractFactory("MyFirstToken")
const token = await Token.attach("DEPLOYED_CONTRACT_ADDRESS")

# Check balance
const balance = await token.balanceOf("YOUR_ADDRESS")
console.log("Balance:", ethers.utils.formatEther(balance))

# Mint tokens
await token.mint(100, {value: ethers.utils.parseEther("0.1")})

# Check new balance
const newBalance = await token.balanceOf("YOUR_ADDRESS")
console.log("New Balance:", ethers.utils.formatEther(newBalance))
```

**Success Criteria:**
- [ ] Token deployed successfully
- [ ] Can mint tokens by paying ETH
- [ ] Can check token balances
- [ ] Can burn tokens
- [ ] Token info displayed correctly

### Task 5: Token Economics and Use Cases (1 hour)
**What to do:**
- Learn about token economics
- Understand different token use cases
- Design your own token model

**Token Use Cases:**
1. **Utility Tokens**: Used within a platform (like your DeFi token)
2. **Governance Tokens**: Voting rights in DAOs
3. **Security Tokens**: Represent real-world assets
4. **Stablecoins**: Pegged to fiat currencies
5. **Reward Tokens**: Given for participation

**Token Economics Design Exercise:**
Design a token for a DeFi platform:

| Aspect | Your Design |
|--------|-------------|
| **Total Supply** | 1,000,000 tokens |
| **Initial Distribution** | 10% to team, 20% to investors, 70% to community |
| **Minting Mechanism** | Public minting with ETH payment |
| **Burning Mechanism** | 5% burn on transfers |
| **Use Cases** | Staking rewards, governance voting, platform fees |
| **Vesting** | Team tokens locked for 2 years |

**Success Criteria:**
- [ ] Understand different token types
- [ ] Can design basic token economics
- [ ] Know how tokens are used in DeFi

### Task 6: Compare with Odoo Currency/Product Management (30 minutes)
**What to do:**
- Think about how tokens compare to Odoo currencies
- Consider how token transfers compare to inventory movements

**Comparison Exercise:**
| Odoo Concept | Token Equivalent | Similarities | Differences |
|-------------|-----------------|-------------|-------------|
| Multi-currency | Multi-token | Different units of value | Tokens are programmable |
| Product variants | Token standards | Different types of items | Tokens can have logic |
| Inventory transfers | Token transfers | Moving items between locations | Global, permissionless |
| User permissions | Token approvals | Access control | More granular control |
| Price lists | Token exchanges | Different prices | Real-time, automated |

**Success Criteria:**
- [ ] Can identify parallels between Odoo and token systems
- [ ] Understand how tokens extend traditional currency concepts
- [ ] See how your ERP experience applies to token economics

## 📚 Additional Resources
- [OpenZeppelin ERC-20 Implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
- [Token Economics Guide](https://consensys.net/blog/blockchain-explained/token-economics/)
- [DeFi Token Standards](https://ethereum.org/en/developers/docs/standards/tokens/)

## 🎯 Reflection Questions
1. How do ERC-20 tokens compare to traditional currencies you've worked with in Odoo?
2. What advantages do programmable tokens offer over traditional currencies?
3. How might token economics affect your DeFi protocol design?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 4 - DeFi Fundamentals and AMM Concepts 