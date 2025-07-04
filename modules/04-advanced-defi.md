# Module 4: Advanced DeFi

## 🎯 Learning Objectives
- Develop complete DeFi protocols
- Implement cross-chain solutions
- Master advanced DeFi analytics
- Understand MEV and flash loans
- Build governance systems

## 🏗️ Protocol Development: Building a Complete DeFi System

### 1. Governance Token Implementation
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceToken is ERC20, Ownable {
    mapping(address => uint256) public lastSnapshotIndex;
    mapping(uint256 => Snapshot) public snapshots;
    
    struct Snapshot {
        uint256 timestamp;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }
    
    uint256 public currentSnapshotId;
    
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
    
    function snapshot() external onlyOwner returns (uint256) {
        currentSnapshotId += 1;
        Snapshot storage currentSnapshot = snapshots[currentSnapshotId];
        currentSnapshot.timestamp = block.timestamp;
        currentSnapshot.totalSupply = totalSupply();
        
        return currentSnapshotId;
    }
    
    function balanceOfAt(address account, uint256 snapshotId) 
        external view returns (uint256) {
        require(snapshotId > 0 && snapshotId <= currentSnapshotId, "Invalid snapshot");
        return snapshots[snapshotId].balances[account];
    }
}
```

### 2. Governance Contract
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GovernanceToken.sol";

contract Governance {
    GovernanceToken public token;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;
    
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_THRESHOLD = 1000 * 10**18; // 1000 tokens
    
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    
    constructor(address _token) {
        token = GovernanceToken(_token);
    }
    
    function propose(string memory description) external returns (uint256) {
        require(
            token.balanceOf(msg.sender) >= PROPOSAL_THRESHOLD,
            "Insufficient tokens to propose"
        );
        
        proposalCount += 1;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalCount, msg.sender, description);
        return proposalCount;
    }
    
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        hasVoted[proposalId][msg.sender] = true;
        
        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit Voted(proposalId, msg.sender, support, weight);
    }
    
    function execute(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");
        
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
```

## 🌉 Cross-Chain Development

### 1. Bridge Implementation
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CrossChainBridge is ReentrancyGuard {
    IERC20 public token;
    mapping(bytes32 => bool) public processedHashes;
    mapping(address => bool) public validators;
    
    event TokensLocked(address indexed user, uint256 amount, string destinationChain);
    event TokensUnlocked(address indexed user, uint256 amount, bytes32 indexed txHash);
    
    constructor(address _token) {
        token = IERC20(_token);
        validators[msg.sender] = true;
    }
    
    function lockTokens(uint256 amount, string memory destinationChain) 
        external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(bytes(destinationChain).length > 0, "Invalid destination");
        
        token.transferFrom(msg.sender, address(this), amount);
        
        emit TokensLocked(msg.sender, amount, destinationChain);
    }
    
    function unlockTokens(
        address user,
        uint256 amount,
        bytes32 txHash,
        bytes memory signature
    ) external {
        require(validators[msg.sender], "Not a validator");
        require(!processedHashes[txHash], "Already processed");
        require(verifySignature(user, amount, txHash, signature), "Invalid signature");
        
        processedHashes[txHash] = true;
        token.transfer(user, amount);
        
        emit TokensUnlocked(user, amount, txHash);
    }
    
    function verifySignature(
        address user,
        uint256 amount,
        bytes32 txHash,
        bytes memory signature
    ) internal pure returns (bool) {
        // Signature verification logic
        bytes32 messageHash = keccak256(abi.encodePacked(user, amount, txHash));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        
        address signer = recoverSigner(ethSignedMessageHash, signature);
        return signer != address(0);
    }
    
    function recoverSigner(bytes32 hash, bytes memory signature) 
        internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid signature 'v' value");
        
        return ecrecover(hash, v, r, s);
    }
}
```

### 2. Layer 2 Integration
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Layer2Bridge {
    mapping(bytes32 => bool) public processedMessages;
    address public l1Bridge;
    
    event MessageProcessed(bytes32 indexed messageHash);
    
    modifier onlyL1Bridge() {
        require(msg.sender == l1Bridge, "Only L1 bridge can call");
        _;
    }
    
    function processMessage(
        bytes32 messageHash,
        address recipient,
        uint256 amount
    ) external onlyL1Bridge {
        require(!processedMessages[messageHash], "Message already processed");
        
        processedMessages[messageHash] = true;
        
        // Process the cross-chain message
        // This could involve minting tokens, executing calls, etc.
        
        emit MessageProcessed(messageHash);
    }
}
```

## ⚡ MEV and Flash Loans

### 1. MEV Bot Implementation
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MEVBot {
    address public owner;
    mapping(address => bool) public authorizedCallers;
    
    event ArbitrageExecuted(
        address indexed tokenA,
        address indexed tokenB,
        uint256 profit
    );
    
    constructor() {
        owner = msg.sender;
        authorizedCallers[msg.sender] = true;
    }
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Not authorized");
        _;
    }
    
    function executeArbitrage(
        address tokenA,
        address tokenB,
        address dex1,
        address dex2,
        uint256 amount
    ) external onlyAuthorized {
        // Flash loan to get tokens
        bytes memory data = abi.encode(tokenA, tokenB, dex1, dex2, amount);
        
        // Execute flash loan
        // This is a simplified example - real implementation would use Aave or dYdX
        _executeArbitrage(data);
    }
    
    function _executeArbitrage(bytes memory data) internal {
        (
            address tokenA,
            address tokenB,
            address dex1,
            address dex2,
            uint256 amount
        ) = abi.decode(data, (address, address, address, address, uint256));
        
        // 1. Borrow tokens via flash loan
        // 2. Swap on DEX1
        // 3. Swap on DEX2
        // 4. Repay flash loan
        // 5. Keep profit
        
        uint256 profit = 0; // Calculate actual profit
        
        emit ArbitrageExecuted(tokenA, tokenB, profit);
    }
}
```

### 2. Flash Loan Protection
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlashLoanProtected {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastActionBlock;
    
    modifier flashLoanProtected() {
        require(
            lastActionBlock[msg.sender] != block.number,
            "Flash loan detected"
        );
        lastActionBlock[msg.sender] = block.number;
        _;
    }
    
    function deposit() external payable flashLoanProtected {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) external flashLoanProtected {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## 📊 Advanced DeFi Analytics

### 1. Protocol Analytics Contract
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProtocolAnalytics {
    struct DailyStats {
        uint256 totalVolume;
        uint256 totalFees;
        uint256 uniqueUsers;
        uint256 timestamp;
    }
    
    mapping(uint256 => DailyStats) public dailyStats;
    mapping(address => uint256) public userFirstSeen;
    mapping(address => uint256) public userLastSeen;
    
    uint256 public currentDay;
    
    event StatsUpdated(
        uint256 indexed day,
        uint256 volume,
        uint256 fees,
        uint256 uniqueUsers
    );
    
    function updateStats(
        uint256 volume,
        uint256 fees,
        address user
    ) external {
        uint256 day = block.timestamp / 1 days;
        
        if (day != currentDay) {
            currentDay = day;
        }
        
        DailyStats storage stats = dailyStats[day];
        stats.totalVolume += volume;
        stats.totalFees += fees;
        stats.timestamp = block.timestamp;
        
        // Track unique users
        if (userFirstSeen[user] == 0) {
            userFirstSeen[user] = block.timestamp;
            stats.uniqueUsers += 1;
        }
        userLastSeen[user] = block.timestamp;
        
        emit StatsUpdated(day, stats.totalVolume, stats.totalFees, stats.uniqueUsers);
    }
    
    function getStats(uint256 day) external view returns (
        uint256 volume,
        uint256 fees,
        uint256 uniqueUsers,
        uint256 timestamp
    ) {
        DailyStats storage stats = dailyStats[day];
        return (stats.totalVolume, stats.totalFees, stats.uniqueUsers, stats.timestamp);
    }
}
```

### 2. Risk Assessment System
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RiskAssessment {
    struct RiskMetrics {
        uint256 volatility;
        uint256 liquidity;
        uint256 marketCap;
        uint256 riskScore;
    }
    
    mapping(address => RiskMetrics) public tokenRisks;
    mapping(address => bool) public riskAssessors;
    
    event RiskUpdated(address indexed token, uint256 riskScore);
    
    modifier onlyRiskAssessor() {
        require(riskAssessors[msg.sender], "Not a risk assessor");
        _;
    }
    
    function updateRiskMetrics(
        address token,
        uint256 volatility,
        uint256 liquidity,
        uint256 marketCap
    ) external onlyRiskAssessor {
        uint256 riskScore = calculateRiskScore(volatility, liquidity, marketCap);
        
        tokenRisks[token] = RiskMetrics({
            volatility: volatility,
            liquidity: liquidity,
            marketCap: marketCap,
            riskScore: riskScore
        });
        
        emit RiskUpdated(token, riskScore);
    }
    
    function calculateRiskScore(
        uint256 volatility,
        uint256 liquidity,
        uint256 marketCap
    ) internal pure returns (uint256) {
        // Simplified risk calculation
        // Higher volatility = higher risk
        // Lower liquidity = higher risk
        // Lower market cap = higher risk
        
        uint256 riskScore = (volatility * 100) / (liquidity + marketCap);
        return riskScore > 100 ? 100 : riskScore;
    }
    
    function getRiskLevel(address token) external view returns (string memory) {
        uint256 riskScore = tokenRisks[token].riskScore;
        
        if (riskScore < 20) return "Low";
        if (riskScore < 50) return "Medium";
        if (riskScore < 80) return "High";
        return "Very High";
    }
}
```

## 🔄 Automated Market Making (Advanced)

### 1. Concentrated Liquidity AMM
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConcentratedLiquidityAMM {
    struct Position {
        address owner;
        uint256 liquidity;
        uint256 lowerTick;
        uint256 upperTick;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }
    
    mapping(uint256 => Position) public positions;
    uint256 public nextPositionId;
    
    IERC20 public token0;
    IERC20 public token1;
    uint256 public fee;
    
    event PositionCreated(
        uint256 indexed positionId,
        address indexed owner,
        uint256 lowerTick,
        uint256 upperTick,
        uint256 liquidity
    );
    
    constructor(
        address _token0,
        address _token1,
        uint256 _fee
    ) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        fee = _fee;
    }
    
    function createPosition(
        uint256 lowerTick,
        uint256 upperTick,
        uint256 liquidity
    ) external returns (uint256 positionId) {
        require(lowerTick < upperTick, "Invalid tick range");
        require(liquidity > 0, "Liquidity must be positive");
        
        positionId = nextPositionId++;
        
        positions[positionId] = Position({
            owner: msg.sender,
            liquidity: liquidity,
            lowerTick: lowerTick,
            upperTick: upperTick,
            feeGrowthInside0LastX128: 0,
            feeGrowthInside1LastX128: 0,
            tokensOwed0: 0,
            tokensOwed1: 0
        });
        
        emit PositionCreated(positionId, msg.sender, lowerTick, upperTick, liquidity);
    }
    
    function swap(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut) {
        // Simplified swap implementation
        // Real implementation would include tick math and price calculations
        
        if (zeroForOne) {
            token0.transferFrom(msg.sender, address(this), amountIn);
            amountOut = calculateOutputAmount(amountIn, true);
            require(amountOut >= amountOutMinimum, "Insufficient output");
            token1.transfer(msg.sender, amountOut);
        } else {
            token1.transferFrom(msg.sender, address(this), amountIn);
            amountOut = calculateOutputAmount(amountIn, false);
            require(amountOut >= amountOutMinimum, "Insufficient output");
            token0.transfer(msg.sender, amountOut);
        }
    }
    
    function calculateOutputAmount(uint256 amountIn, bool zeroForOne) 
        internal pure returns (uint256) {
        // Simplified calculation - real implementation would use complex math
        return amountIn * 95 / 100; // 5% fee
    }
}
```

## 🎯 Key Takeaways

1. **Governance is crucial** - decentralized decision-making requires careful design
2. **Cross-chain bridges** - enable interoperability but introduce new risks
3. **MEV is inevitable** - design protocols to minimize its impact
4. **Analytics drive decisions** - comprehensive data collection is essential
5. **Advanced AMMs** - provide better capital efficiency than simple pools

## 📚 Additional Resources

- [Uniswap V3 Documentation](https://docs.uniswap.org/concepts/protocol-overview)
- [Aave Governance](https://docs.aave.com/developers/protocol-governance)
- [MEV Research](https://ethereum.org/en/developers/docs/mev/)
- [Cross-Chain Bridge Security](https://consensys.net/blog/blockchain-explained/cross-chain-bridges/)

## 🚀 Next Steps

1. Deploy a governance system
2. Implement cross-chain functionality
3. Build advanced analytics dashboard
4. Contribute to open-source DeFi protocols

---

*Congratulations! You've completed the comprehensive DeFi learning path. You're now ready to build and contribute to the DeFi ecosystem.* 