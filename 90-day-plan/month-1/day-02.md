---
layout: day
title: Solidity Basics - Day 2
day: 2
date: 2024-01-02
---

# Solidity Basics - Day 2

## 🎯 Today's Learning Objectives

- Understand Solidity syntax and structure
- Learn about data types and variables
- Create your first ERC-20 token contract
- Understand gas optimization basics

## 📚 Solidity Fundamentals

### Basic Contract Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstContract {
    // State variables
    string public name;
    uint256 public value;
    
    // Constructor
    constructor(string memory _name) {
        name = _name;
        value = 0;
    }
    
    // Functions
    function setValue(uint256 _newValue) public {
        value = _newValue;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}
```

### Key Concepts

**Data Types**:
- `uint256`: Unsigned integer (0 to 2^256-1)
- `int256`: Signed integer
- `bool`: Boolean (true/false)
- `address`: Ethereum address (20 bytes)
- `string`: Dynamic string
- `bytes`: Dynamic byte array

**Function Types**:
- `public`: Can be called externally and internally
- `private`: Only callable within the contract
- `internal`: Callable within contract and inherited contracts
- `external`: Only callable externally
- `view`: Read-only function (no state changes)
- `pure`: No state reads or writes

## 🛠️ Your First ERC-20 Token

Create `contracts/MyToken.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
        Ownable(msg.sender) 
    {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
```

## 🧪 Testing Your Token

Create `test/MyToken.test.js`:

```javascript
const { expect } = require("chai");

describe("MyToken", function () {
  let MyToken, myToken, owner, addr1, addr2;

  beforeEach(async function () {
    MyToken = await ethers.getContractFactory("MyToken");
    [owner, addr1, addr2] = await ethers.getSigners();
    myToken = await MyToken.deploy("MyToken", "MTK");
    await myToken.deployed();
  });

  it("Should have correct name and symbol", async function () {
    expect(await myToken.name()).to.equal("MyToken");
    expect(await myToken.symbol()).to.equal("MTK");
  });

  it("Should assign initial balance to owner", async function () {
    const ownerBalance = await myToken.balanceOf(owner.address);
    expect(await myToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Should allow minting by owner", async function () {
    await myToken.mint(addr1.address, 1000);
    expect(await myToken.balanceOf(addr1.address)).to.equal(1000);
  });
});
```

## 🚀 Deploy and Test

```bash
# Install OpenZeppelin contracts
npm install @openzeppelin/contracts

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost
```

## 📝 Success Criteria

- [ ] Understand basic Solidity syntax
- [ ] Create and deploy ERC-20 token
- [ ] Write comprehensive tests
- [ ] Understand gas optimization basics
- [ ] Complete token minting and burning functions

## 🔗 Odoo Comparison

| **Odoo Concept** | **Solidity Equivalent** |
|------------------|------------------------|
| Model Fields | State Variables |
| Model Methods | Contract Functions |
| Computed Fields | View/Pure Functions |
| Constraints | Modifiers |
| Inheritance | Contract Inheritance |

## 🎯 Tomorrow's Preview

Tomorrow we'll explore DeFi fundamentals and build a simple AMM (Automated Market Maker).

---

**💡 Pro Tip**: Use Remix IDE (remix.ethereum.org) for quick Solidity testing and debugging! 