# Day 2: Smart Contracts and Solidity Basics

## 🎯 Learning Objective
Understand smart contracts and learn the fundamentals of Solidity programming language.

## ⏰ Time Estimate
5-6 hours

## 📋 Tasks

### Task 1: Understanding Smart Contracts (1 hour)
**What to do:**
- Read Module 1 section on Smart Contracts
- Watch: "Smart Contracts" by Finematics (10 min)
- Compare smart contracts to Odoo modules

**Resources:**
- [Finematics: Smart Contracts](https://www.youtube.com/watch?v=ZE2HxTmxfrI)
- [Ethereum.org: Smart Contracts](https://ethereum.org/en/developers/docs/smart-contracts/)

**Key Concepts to Understand:**
- Smart contracts are programs that run on blockchain
- They are immutable once deployed
- They can hold and transfer value
- They execute automatically when conditions are met

**Success Criteria:**
- [ ] Can explain what a smart contract is
- [ ] Understand the difference between smart contracts and traditional software
- [ ] Know why smart contracts are "trustless"

### Task 2: Solidity Syntax Basics (1.5 hours)
**What to do:**
- Learn basic Solidity syntax
- Understand data types
- Practice with simple examples

**Create file: `contracts/SolidityBasics.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SolidityBasics {
    // State variables (like Odoo model fields)
    string public name;
    uint256 public age;
    bool public isActive;
    address public owner;
    
    // Events (like Odoo logging)
    event PersonAdded(string name, uint256 age);
    event StatusChanged(bool newStatus);
    
    // Constructor (like Odoo __init__)
    constructor() {
        owner = msg.sender;
        name = "Default";
        age = 0;
        isActive = false;
    }
    
    // Function modifiers (like Odoo security rules)
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    // Functions (like Odoo methods)
    function addPerson(string memory _name, uint256 _age) public {
        name = _name;
        age = _age;
        isActive = true;
        
        emit PersonAdded(_name, _age);
    }
    
    function toggleStatus() public onlyOwner {
        isActive = !isActive;
        emit StatusChanged(isActive);
    }
    
    // View function (like Odoo computed field)
    function getPersonInfo() public view returns (string memory, uint256, bool) {
        return (name, age, isActive);
    }
}
```

**Success Criteria:**
- [ ] Understand basic data types (string, uint256, bool, address)
- [ ] Know how to declare state variables
- [ ] Understand function modifiers
- [ ] Know how to emit events

### Task 3: Practice with Remix IDE (1 hour)
**What to do:**
- Go to [remix.ethereum.org](https://remix.ethereum.org)
- Create a new file called `Practice.sol`
- Copy and paste the SolidityBasics contract
- Compile and deploy it
- Test all functions

**Steps in Remix:**
1. Create new file: `Practice.sol`
2. Paste the contract code
3. Compile (Ctrl+S or click Compile)
4. Deploy to JavaScript VM
5. Test each function:
   - Call `addPerson` with your name and age
   - Call `getPersonInfo` to see the result
   - Try `toggleStatus` (should fail if not owner)
   - Switch accounts and try `toggleStatus` again

**Success Criteria:**
- [ ] Contract compiles without errors in Remix
- [ ] Can deploy contract successfully
- [ ] Can call functions and see results
- [ ] Understand why some functions fail with different accounts

### Task 4: Understanding Gas and Transactions (1 hour)
**What to do:**
- Learn about gas fees and transaction costs
- Understand the difference between view and state-changing functions
- Practice gas estimation

**Key Concepts:**
- **Gas**: Unit of computational work
- **Gas Price**: Price per unit of gas (in wei)
- **Transaction Cost**: Gas used × Gas price
- **View Functions**: Free to call, don't change state
- **State Functions**: Cost gas, change blockchain state

**Experiment in Remix:**
1. Deploy your contract
2. Call `getPersonInfo()` (view function) - notice no gas cost
3. Call `addPerson()` (state function) - notice gas cost
4. Try different gas prices and see the difference

**Success Criteria:**
- [ ] Understand what gas is and why it's needed
- [ ] Know the difference between view and state functions
- [ ] Can estimate gas costs for simple operations

### Task 5: Build a Simple Calculator Contract (1 hour)
**What to do:**
- Create a calculator contract with basic operations
- Practice with different data types and functions

**Create file: `contracts/Calculator.sol`**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
    uint256 public lastResult;
    uint256 public operationCount;
    
    event Calculation(uint256 a, uint256 b, string operation, uint256 result);
    
    function add(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = a + b;
        lastResult = result;
        operationCount++;
        
        emit Calculation(a, b, "add", result);
        return result;
    }
    
    function subtract(uint256 a, uint256 b) public returns (uint256) {
        require(a >= b, "Cannot subtract larger number from smaller");
        
        uint256 result = a - b;
        lastResult = result;
        operationCount++;
        
        emit Calculation(a, b, "subtract", result);
        return result;
    }
    
    function multiply(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = a * b;
        lastResult = result;
        operationCount++;
        
        emit Calculation(a, b, "multiply", result);
        return result;
    }
    
    function divide(uint256 a, uint256 b) public returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        
        uint256 result = a / b;
        lastResult = result;
        operationCount++;
        
        emit Calculation(a, b, "divide", result);
        return result;
    }
    
    function getStats() public view returns (uint256, uint256) {
        return (lastResult, operationCount);
    }
}
```

**Test the Calculator:**
1. Deploy in Remix
2. Test each operation with different numbers
3. Check the events tab to see emitted events
4. Call `getStats()` to see the last result and operation count

**Success Criteria:**
- [ ] Calculator contract works correctly
- [ ] Can perform all basic operations
- [ ] Events are emitted properly
- [ ] Error handling works (division by zero, subtraction)

### Task 6: Compare with Odoo (30 minutes)
**What to do:**
- Think about how this compares to Odoo development
- Write down similarities and differences

**Comparison Exercise:**
| Odoo Concept | Solidity Equivalent | Similarities | Differences |
|-------------|-------------------|-------------|-------------|
| Model Fields | State Variables | Store data | Immutable once set |
| Methods | Functions | Business logic | Gas costs |
| Security Rules | Modifiers | Access control | More restrictive |
| Computed Fields | View Functions | Read-only data | Free to call |
| Logging | Events | Track changes | Stored on blockchain |

**Success Criteria:**
- [ ] Can identify at least 5 similarities between Odoo and Solidity
- [ ] Understand key differences in deployment and execution
- [ ] See how your Odoo experience translates to smart contracts

## 📚 Additional Resources
- [Solidity Documentation](https://docs.soliditylang.org/)
- [CryptoZombies Tutorial](https://cryptozombies.io/) (interactive Solidity learning)
- [Remix IDE Documentation](https://remix-ide.readthedocs.io/)

## 🎯 Reflection Questions
1. How does Solidity's immutability compare to Odoo's module updates?
2. What challenges do you see in debugging smart contracts vs Odoo modules?
3. How might gas costs affect your development approach?

## 📝 Notes Section
Use this space to write down important concepts, questions, and insights from today's learning:

---

**Tomorrow**: Day 3 - ERC-20 Tokens and Your First Token Contract 