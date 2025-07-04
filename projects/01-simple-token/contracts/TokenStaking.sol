// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenStaking
 * @dev A comprehensive staking contract for earning rewards
 * 
 * Features:
 * - Multiple staking pools with different rewards
 * - Flexible reward rates and lock periods
 * - Early withdrawal penalties
 * - Compound interest options
 * - Emergency pause functionality
 * - Comprehensive analytics
 * 
 * Use cases:
 * - Yield farming
 * - Governance token staking
 * - Long-term holder incentives
 * - Protocol participation rewards
 */
contract TokenStaking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    
    struct StakingPool {
        uint256 id;
        string name;
        uint256 rewardRate; // Rewards per second per token
        uint256 lockPeriod; // Minimum staking period
        uint256 earlyWithdrawalPenalty; // Penalty in basis points
        uint256 totalStaked;
        uint256 totalRewardsDistributed;
        bool isActive;
        uint256 createdAt;
    }
    
    struct UserStake {
        uint256 poolId;
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 accumulatedRewards;
        bool isActive;
    }
    
    struct UserInfo {
        uint256 totalStaked;
        uint256 totalRewardsEarned;
        uint256 totalRewardsClaimed;
        uint256[] activeStakes;
    }
    
    // Pool management
    mapping(uint256 => StakingPool) public stakingPools;
    uint256 public nextPoolId;
    
    // User stakes
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => UserStake)) public userStakes;
    
    // Global variables
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;
    bool public paused;
    
    // Events
    event PoolCreated(
        uint256 indexed poolId,
        string name,
        uint256 rewardRate,
        uint256 lockPeriod,
        uint256 earlyWithdrawalPenalty,
        uint256 timestamp
    );
    
    event PoolUpdated(
        uint256 indexed poolId,
        uint256 newRewardRate,
        uint256 newLockPeriod,
        uint256 newPenalty,
        uint256 timestamp
    );
    
    event Staked(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    
    event Withdrawn(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount,
        uint256 penalty,
        uint256 timestamp
    );
    
    event RewardsClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    
    event RewardsAdded(
        uint256 amount,
        uint256 timestamp
    );
    
    event StakingPaused(bool paused, uint256 timestamp);
    
    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Staking is paused");
        _;
    }
    
    modifier poolExists(uint256 poolId) {
        require(stakingPools[poolId].isActive, "Pool does not exist");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }
    
    modifier validBasisPoints(uint256 basisPoints) {
        require(basisPoints <= 10000, "Invalid basis points (max 100%)");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _stakingToken Address of the token to be staked
     * @param _rewardToken Address of the reward token
     */
    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");
        
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    /**
     * @dev Create a new staking pool
     * @param name Pool name
     * @param rewardRate Rewards per second per token (in wei)
     * @param lockPeriod Minimum staking period in seconds
     * @param earlyWithdrawalPenalty Penalty for early withdrawal in basis points
     */
    function createPool(
        string memory name,
        uint256 rewardRate,
        uint256 lockPeriod,
        uint256 earlyWithdrawalPenalty
    ) external onlyOwner validBasisPoints(earlyWithdrawalPenalty) returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(rewardRate > 0, "Reward rate must be positive");
        
        uint256 poolId = nextPoolId++;
        
        stakingPools[poolId] = StakingPool({
            id: poolId,
            name: name,
            rewardRate: rewardRate,
            lockPeriod: lockPeriod,
            earlyWithdrawalPenalty: earlyWithdrawalPenalty,
            totalStaked: 0,
            totalRewardsDistributed: 0,
            isActive: true,
            createdAt: block.timestamp
        });
        
        emit PoolCreated(
            poolId,
            name,
            rewardRate,
            lockPeriod,
            earlyWithdrawalPenalty,
            block.timestamp
        );
        
        return poolId;
    }
    
    /**
     * @dev Stake tokens in a specific pool
     * @param poolId ID of the staking pool
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 poolId, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        poolExists(poolId) 
        validAmount(amount) 
    {
        StakingPool storage pool = stakingPools[poolId];
        UserInfo storage user = userInfo[msg.sender];
        UserStake storage userStake = userStakes[msg.sender][poolId];
        
        // Update rewards before staking
        if (userStake.isActive) {
            _updateRewards(msg.sender, poolId);
        }
        
        // Transfer tokens from user to contract
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        
        if (userStake.isActive) {
            // Add to existing stake
            userStake.amount = userStake.amount.add(amount);
        } else {
            // Create new stake
            userStake.poolId = poolId;
            userStake.amount = amount;
            userStake.startTime = block.timestamp;
            userStake.lastRewardTime = block.timestamp;
            userStake.accumulatedRewards = 0;
            userStake.isActive = true;
            
            user.activeStakes.push(poolId);
        }
        
        // Update global and pool statistics
        user.totalStaked = user.totalStaked.add(amount);
        pool.totalStaked = pool.totalStaked.add(amount);
        totalStaked = totalStaked.add(amount);
        
        emit Staked(poolId, msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Withdraw staked tokens from a pool
     * @param poolId ID of the staking pool
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 poolId, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        poolExists(poolId) 
        validAmount(amount) 
    {
        StakingPool storage pool = stakingPools[poolId];
        UserInfo storage user = userInfo[msg.sender];
        UserStake storage userStake = userStakes[msg.sender][poolId];
        
        require(userStake.isActive, "No active stake");
        require(userStake.amount >= amount, "Insufficient staked amount");
        
        // Update rewards before withdrawal
        _updateRewards(msg.sender, poolId);
        
        uint256 penalty = 0;
        uint256 actualWithdrawal = amount;
        
        // Check if early withdrawal penalty applies
        if (block.timestamp < userStake.startTime.add(pool.lockPeriod)) {
            penalty = amount.mul(pool.earlyWithdrawalPenalty).div(10000);
            actualWithdrawal = amount.sub(penalty);
        }
        
        // Update stake
        userStake.amount = userStake.amount.sub(amount);
        
        // Remove stake if fully withdrawn
        if (userStake.amount == 0) {
            userStake.isActive = false;
            _removeStakeFromUser(msg.sender, poolId);
        }
        
        // Update statistics
        user.totalStaked = user.totalStaked.sub(amount);
        pool.totalStaked = pool.totalStaked.sub(amount);
        totalStaked = totalStaked.sub(amount);
        
        // Transfer tokens
        require(
            stakingToken.transfer(msg.sender, actualWithdrawal),
            "Token transfer failed"
        );
        
        // Burn penalty tokens if any
        if (penalty > 0) {
            // Penalty tokens are burned (sent to zero address)
            require(
                stakingToken.transfer(address(0), penalty),
                "Penalty transfer failed"
            );
        }
        
        emit Withdrawn(poolId, msg.sender, amount, penalty, block.timestamp);
    }
    
    /**
     * @dev Claim accumulated rewards
     */
    function claimRewards() external nonReentrant whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        uint256 totalRewards = 0;
        
        // Update rewards for all active stakes
        for (uint256 i = 0; i < user.activeStakes.length; i++) {
            uint256 poolId = user.activeStakes[i];
            if (userStakes[msg.sender][poolId].isActive) {
                _updateRewards(msg.sender, poolId);
                totalRewards = totalRewards.add(userStakes[msg.sender][poolId].accumulatedRewards);
                userStakes[msg.sender][poolId].accumulatedRewards = 0;
            }
        }
        
        require(totalRewards > 0, "No rewards to claim");
        
        user.totalRewardsClaimed = user.totalRewardsClaimed.add(totalRewards);
        totalRewardsDistributed = totalRewardsDistributed.add(totalRewards);
        
        require(
            rewardToken.transfer(msg.sender, totalRewards),
            "Reward transfer failed"
        );
        
        emit RewardsClaimed(msg.sender, totalRewards, block.timestamp);
    }
    
    /**
     * @dev Add rewards to the contract (owner only)
     * @param amount Amount of reward tokens to add
     */
    function addRewards(uint256 amount) external onlyOwner validAmount(amount) {
        require(
            rewardToken.transferFrom(msg.sender, address(this), amount),
            "Reward transfer failed"
        );
        
        emit RewardsAdded(amount, block.timestamp);
    }
    
    /**
     * @dev Update pool parameters (owner only)
     * @param poolId ID of the pool to update
     * @param newRewardRate New reward rate
     * @param newLockPeriod New lock period
     * @param newPenalty New early withdrawal penalty
     */
    function updatePool(
        uint256 poolId,
        uint256 newRewardRate,
        uint256 newLockPeriod,
        uint256 newPenalty
    ) external onlyOwner poolExists(poolId) validBasisPoints(newPenalty) {
        StakingPool storage pool = stakingPools[poolId];
        
        uint256 oldRewardRate = pool.rewardRate;
        uint256 oldLockPeriod = pool.lockPeriod;
        uint256 oldPenalty = pool.earlyWithdrawalPenalty;
        
        pool.rewardRate = newRewardRate;
        pool.lockPeriod = newLockPeriod;
        pool.earlyWithdrawalPenalty = newPenalty;
        
        emit PoolUpdated(poolId, newRewardRate, newLockPeriod, newPenalty, block.timestamp);
    }
    
    /**
     * @dev Pause/unpause staking operations
     * @param _paused Whether to pause or unpause
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit StakingPaused(_paused, block.timestamp);
    }
    
    /**
     * @dev Emergency withdraw (bypasses lock period and penalties)
     * @param poolId ID of the staking pool
     */
    function emergencyWithdraw(uint256 poolId) external nonReentrant poolExists(poolId) {
        UserStake storage userStake = userStakes[msg.sender][poolId];
        require(userStake.isActive, "No active stake");
        
        uint256 amount = userStake.amount;
        userStake.amount = 0;
        userStake.isActive = false;
        userStake.accumulatedRewards = 0;
        
        _removeStakeFromUser(msg.sender, poolId);
        
        // Update statistics
        userInfo[msg.sender].totalStaked = userInfo[msg.sender].totalStaked.sub(amount);
        stakingPools[poolId].totalStaked = stakingPools[poolId].totalStaked.sub(amount);
        totalStaked = totalStaked.sub(amount);
        
        require(
            stakingToken.transfer(msg.sender, amount),
            "Token transfer failed"
        );
        
        emit Withdrawn(poolId, msg.sender, amount, 0, block.timestamp);
    }
    
    // ========== INTERNAL FUNCTIONS ==========
    
    /**
     * @dev Update rewards for a user's stake
     * @param user Address of the user
     * @param poolId ID of the pool
     */
    function _updateRewards(address user, uint256 poolId) internal {
        UserStake storage userStake = userStakes[user][poolId];
        StakingPool storage pool = stakingPools[poolId];
        
        if (!userStake.isActive || userStake.amount == 0) {
            return;
        }
        
        uint256 timeElapsed = block.timestamp.sub(userStake.lastRewardTime);
        if (timeElapsed == 0) {
            return;
        }
        
        uint256 rewards = userStake.amount.mul(pool.rewardRate).mul(timeElapsed);
        userStake.accumulatedRewards = userStake.accumulatedRewards.add(rewards);
        userStake.lastRewardTime = block.timestamp;
        
        userInfo[user].totalRewardsEarned = userInfo[user].totalRewardsEarned.add(rewards);
    }
    
    /**
     * @dev Remove a stake from user's active stakes array
     * @param user Address of the user
     * @param poolId ID of the pool
     */
    function _removeStakeFromUser(address user, uint256 poolId) internal {
        UserInfo storage userInfo = userInfo[user];
        uint256[] storage activeStakes = userInfo.activeStakes;
        
        for (uint256 i = 0; i < activeStakes.length; i++) {
            if (activeStakes[i] == poolId) {
                activeStakes[i] = activeStakes[activeStakes.length - 1];
                activeStakes.pop();
                break;
            }
        }
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev Get pending rewards for a user across all pools
     * @param user Address of the user
     */
    function getPendingRewards(address user) external view returns (uint256) {
        UserInfo storage userInfo = userInfo[user];
        uint256 totalPending = 0;
        
        for (uint256 i = 0; i < userInfo.activeStakes.length; i++) {
            uint256 poolId = userInfo.activeStakes[i];
            UserStake storage userStake = userStakes[user][poolId];
            StakingPool storage pool = stakingPools[poolId];
            
            if (userStake.isActive && userStake.amount > 0) {
                uint256 timeElapsed = block.timestamp.sub(userStake.lastRewardTime);
                uint256 rewards = userStake.amount.mul(pool.rewardRate).mul(timeElapsed);
                totalPending = totalPending.add(userStake.accumulatedRewards).add(rewards);
            }
        }
        
        return totalPending;
    }
    
    /**
     * @dev Get user's stake information for a specific pool
     * @param user Address of the user
     * @param poolId ID of the pool
     */
    function getUserStake(address user, uint256 poolId) 
        external 
        view 
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 lastRewardTime,
            uint256 accumulatedRewards,
            bool isActive,
            uint256 pendingRewards
        ) 
    {
        UserStake storage userStake = userStakes[user][poolId];
        StakingPool storage pool = stakingPools[poolId];
        
        amount = userStake.amount;
        startTime = userStake.startTime;
        lastRewardTime = userStake.lastRewardTime;
        accumulatedRewards = userStake.accumulatedRewards;
        isActive = userStake.isActive;
        
        if (isActive && amount > 0) {
            uint256 timeElapsed = block.timestamp.sub(lastRewardTime);
            uint256 rewards = amount.mul(pool.rewardRate).mul(timeElapsed);
            pendingRewards = accumulatedRewards.add(rewards);
        }
    }
    
    /**
     * @dev Get staking statistics
     */
    function getStakingStats() external view returns (
        uint256 _totalStaked,
        uint256 _totalRewardsDistributed,
        uint256 _totalPools,
        uint256 _totalUsers,
        uint256 _contractBalance
    ) {
        uint256 _totalPools = 0;
        uint256 _totalUsers = 0;
        
        for (uint256 i = 0; i < nextPoolId; i++) {
            if (stakingPools[i].isActive) {
                _totalPools = _totalPools.add(1);
            }
        }
        
        return (
            totalStaked,
            totalRewardsDistributed,
            _totalPools,
            _totalUsers,
            stakingToken.balanceOf(address(this))
        );
    }
    
    /**
     * @dev Get pool information
     * @param poolId ID of the pool
     */
    function getPoolInfo(uint256 poolId) 
        external 
        view 
        returns (
            string memory name,
            uint256 rewardRate,
            uint256 lockPeriod,
            uint256 earlyWithdrawalPenalty,
            uint256 totalStaked,
            uint256 totalRewardsDistributed,
            bool isActive
        ) 
    {
        StakingPool storage pool = stakingPools[poolId];
        return (
            pool.name,
            pool.rewardRate,
            pool.lockPeriod,
            pool.earlyWithdrawalPenalty,
            pool.totalStaked,
            pool.totalRewardsDistributed,
            pool.isActive
        );
    }
} 