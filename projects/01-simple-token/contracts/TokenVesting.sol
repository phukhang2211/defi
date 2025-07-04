// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A comprehensive token vesting contract for managing token distribution over time
 * 
 * Features:
 * - Multiple vesting schedules per beneficiary
 * - Linear and cliff vesting options
 * - Revocable and irrevocable vesting
 * - Batch operations for efficiency
 * - Comprehensive event logging
 * - Emergency pause functionality
 * 
 * Use cases:
 * - Team token allocation
 * - Advisor token distribution
 * - Investor token unlocks
 * - Employee stock options
 */
contract TokenVesting is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    IERC20 public token;
    
    struct VestingSchedule {
        uint256 id;
        address beneficiary;
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 cliffDuration;
        bool isRevocable;
        bool isRevoked;
        bool isActive;
        uint256 createdAt;
    }
    
    // Mapping from beneficiary to their vesting schedules
    mapping(address => VestingSchedule[]) public vestingSchedules;
    
    // Mapping from schedule ID to schedule
    mapping(uint256 => VestingSchedule) public schedulesById;
    
    // Global variables
    uint256 public nextScheduleId;
    bool public paused;
    
    // Events
    event VestingScheduleCreated(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration,
        uint256 cliffDuration,
        bool isRevocable,
        uint256 timestamp
    );
    
    event TokensReleased(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount,
        uint256 timestamp
    );
    
    event VestingRevoked(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 unreleasedAmount,
        uint256 timestamp
    );
    
    event VestingPaused(bool paused, uint256 timestamp);
    
    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Vesting is paused");
        _;
    }
    
    modifier onlyBeneficiary(uint256 scheduleId) {
        require(schedulesById[scheduleId].beneficiary == msg.sender, "Not the beneficiary");
        _;
    }
    
    modifier scheduleExists(uint256 scheduleId) {
        require(schedulesById[scheduleId].isActive, "Schedule does not exist");
        _;
    }
    
    modifier notRevoked(uint256 scheduleId) {
        require(!schedulesById[scheduleId].isRevoked, "Schedule is revoked");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _token Address of the token to be vested
     */
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }
    
    /**
     * @dev Create a new vesting schedule
     * @param beneficiary Address that will receive the tokens
     * @param totalAmount Total amount of tokens to be vested
     * @param startTime Start time of the vesting period
     * @param duration Duration of the vesting period
     * @param cliffDuration Cliff duration (tokens are locked until cliff ends)
     * @param isRevocable Whether the vesting can be revoked by owner
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration,
        uint256 cliffDuration,
        bool isRevocable
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(totalAmount > 0, "Amount must be positive");
        require(startTime >= block.timestamp, "Start time must be in future");
        require(duration > 0, "Duration must be positive");
        require(cliffDuration <= duration, "Cliff cannot exceed duration");
        
        // Transfer tokens to this contract
        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );
        
        uint256 scheduleId = nextScheduleId++;
        
        VestingSchedule memory schedule = VestingSchedule({
            id: scheduleId,
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: startTime,
            duration: duration,
            cliffDuration: cliffDuration,
            isRevocable: isRevocable,
            isRevoked: false,
            isActive: true,
            createdAt: block.timestamp
        });
        
        vestingSchedules[beneficiary].push(schedule);
        schedulesById[scheduleId] = schedule;
        
        emit VestingScheduleCreated(
            scheduleId,
            beneficiary,
            totalAmount,
            startTime,
            duration,
            cliffDuration,
            isRevocable,
            block.timestamp
        );
        
        return scheduleId;
    }
    
    /**
     * @dev Create multiple vesting schedules in batch
     * @param beneficiaries Array of beneficiary addresses
     * @param amounts Array of token amounts
     * @param startTimes Array of start times
     * @param durations Array of durations
     * @param cliffDurations Array of cliff durations
     * @param revocable Array of revocable flags
     */
    function createVestingSchedulesBatch(
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256[] calldata startTimes,
        uint256[] calldata durations,
        uint256[] calldata cliffDurations,
        bool[] calldata revocable
    ) external onlyOwner whenNotPaused {
        require(
            beneficiaries.length == amounts.length &&
            amounts.length == startTimes.length &&
            startTimes.length == durations.length &&
            durations.length == cliffDurations.length &&
            cliffDurations.length == revocable.length,
            "Array lengths must match"
        );
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
        }
        
        // Transfer total amount to this contract
        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );
        
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Invalid beneficiary");
            require(amounts[i] > 0, "Amount must be positive");
            require(startTimes[i] >= block.timestamp, "Start time must be in future");
            require(durations[i] > 0, "Duration must be positive");
            require(cliffDurations[i] <= durations[i], "Cliff cannot exceed duration");
            
            uint256 scheduleId = nextScheduleId++;
            
            VestingSchedule memory schedule = VestingSchedule({
                id: scheduleId,
                beneficiary: beneficiaries[i],
                totalAmount: amounts[i],
                releasedAmount: 0,
                startTime: startTimes[i],
                duration: durations[i],
                cliffDuration: cliffDurations[i],
                isRevocable: revocable[i],
                isRevoked: false,
                isActive: true,
                createdAt: block.timestamp
            });
            
            vestingSchedules[beneficiaries[i]].push(schedule);
            schedulesById[scheduleId] = schedule;
            
            emit VestingScheduleCreated(
                scheduleId,
                beneficiaries[i],
                amounts[i],
                startTimes[i],
                durations[i],
                cliffDurations[i],
                revocable[i],
                block.timestamp
            );
        }
    }
    
    /**
     * @dev Release tokens from a specific vesting schedule
     * @param scheduleId ID of the vesting schedule
     */
    function release(uint256 scheduleId) 
        external 
        nonReentrant 
        whenNotPaused 
        scheduleExists(scheduleId) 
        notRevoked(scheduleId) 
    {
        VestingSchedule storage schedule = schedulesById[scheduleId];
        require(schedule.beneficiary == msg.sender, "Not the beneficiary");
        
        uint256 releasable = getReleasableAmount(scheduleId);
        require(releasable > 0, "No tokens to release");
        
        schedule.releasedAmount = schedule.releasedAmount.add(releasable);
        
        require(
            token.transfer(schedule.beneficiary, releasable),
            "Token transfer failed"
        );
        
        emit TokensReleased(scheduleId, schedule.beneficiary, releasable, block.timestamp);
    }
    
    /**
     * @dev Release tokens from all schedules for a beneficiary
     * @param beneficiary Address of the beneficiary
     */
    function releaseAll(address beneficiary) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        require(beneficiary != address(0), "Invalid beneficiary");
        
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];
        uint256 totalReleased = 0;
        
        for (uint256 i = 0; i < schedules.length; i++) {
            if (schedules[i].isActive && !schedules[i].isRevoked) {
                uint256 releasable = getReleasableAmount(schedules[i].id);
                if (releasable > 0) {
                    schedules[i].releasedAmount = schedules[i].releasedAmount.add(releasable);
                    totalReleased = totalReleased.add(releasable);
                    
                    emit TokensReleased(
                        schedules[i].id,
                        beneficiary,
                        releasable,
                        block.timestamp
                    );
                }
            }
        }
        
        if (totalReleased > 0) {
            require(
                token.transfer(beneficiary, totalReleased),
                "Token transfer failed"
            );
        }
    }
    
    /**
     * @dev Revoke a vesting schedule (owner only, if revocable)
     * @param scheduleId ID of the vesting schedule
     */
    function revoke(uint256 scheduleId) 
        external 
        onlyOwner 
        scheduleExists(scheduleId) 
        notRevoked(scheduleId) 
    {
        VestingSchedule storage schedule = schedulesById[scheduleId];
        require(schedule.isRevocable, "Schedule is not revocable");
        
        uint256 unreleased = schedule.totalAmount.sub(schedule.releasedAmount);
        
        schedule.isRevoked = true;
        schedule.isActive = false;
        
        // Return unreleased tokens to owner
        if (unreleased > 0) {
            require(
                token.transfer(owner(), unreleased),
                "Token transfer failed"
            );
        }
        
        emit VestingRevoked(scheduleId, schedule.beneficiary, unreleased, block.timestamp);
    }
    
    /**
     * @dev Pause/unpause all vesting operations
     * @param _paused Whether to pause or unpause
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit VestingPaused(_paused, block.timestamp);
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev Get the releasable amount for a specific schedule
     * @param scheduleId ID of the vesting schedule
     */
    function getReleasableAmount(uint256 scheduleId) 
        public 
        view 
        scheduleExists(scheduleId) 
        notRevoked(scheduleId) 
        returns (uint256) 
    {
        VestingSchedule storage schedule = schedulesById[scheduleId];
        
        if (block.timestamp < schedule.startTime) {
            return 0;
        }
        
        uint256 timeElapsed = block.timestamp.sub(schedule.startTime);
        
        // Check if cliff period has passed
        if (timeElapsed < schedule.cliffDuration) {
            return 0;
        }
        
        // Calculate vested amount
        uint256 totalVestingTime = schedule.duration;
        uint256 vestedAmount;
        
        if (timeElapsed >= totalVestingTime) {
            vestedAmount = schedule.totalAmount;
        } else {
            vestedAmount = schedule.totalAmount.mul(timeElapsed).div(totalVestingTime);
        }
        
        return vestedAmount.sub(schedule.releasedAmount);
    }
    
    /**
     * @dev Get all vesting schedules for a beneficiary
     * @param beneficiary Address of the beneficiary
     */
    function getVestingSchedules(address beneficiary) 
        external 
        view 
        returns (VestingSchedule[] memory) 
    {
        return vestingSchedules[beneficiary];
    }
    
    /**
     * @dev Get a specific vesting schedule by ID
     * @param scheduleId ID of the vesting schedule
     */
    function getVestingSchedule(uint256 scheduleId) 
        external 
        view 
        returns (VestingSchedule memory) 
    {
        return schedulesById[scheduleId];
    }
    
    /**
     * @dev Get total vested amount for a beneficiary across all schedules
     * @param beneficiary Address of the beneficiary
     */
    function getTotalVestedAmount(address beneficiary) 
        external 
        view 
        returns (uint256) 
    {
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];
        uint256 totalVested = 0;
        
        for (uint256 i = 0; i < schedules.length; i++) {
            if (schedules[i].isActive && !schedules[i].isRevoked) {
                totalVested = totalVested.add(schedules[i].releasedAmount);
            }
        }
        
        return totalVested;
    }
    
    /**
     * @dev Get total releasable amount for a beneficiary across all schedules
     * @param beneficiary Address of the beneficiary
     */
    function getTotalReleasableAmount(address beneficiary) 
        external 
        view 
        returns (uint256) 
    {
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];
        uint256 totalReleasable = 0;
        
        for (uint256 i = 0; i < schedules.length; i++) {
            if (schedules[i].isActive && !schedules[i].isRevoked) {
                totalReleasable = totalReleasable.add(getReleasableAmount(schedules[i].id));
            }
        }
        
        return totalReleasable;
    }
    
    /**
     * @dev Get vesting statistics
     */
    function getVestingStats() external view returns (
        uint256 totalSchedules,
        uint256 activeSchedules,
        uint256 revokedSchedules,
        uint256 totalTokensVested,
        uint256 totalTokensReleased
    ) {
        uint256 _activeSchedules = 0;
        uint256 _revokedSchedules = 0;
        uint256 _totalTokensVested = 0;
        uint256 _totalTokensReleased = 0;
        
        for (uint256 i = 0; i < nextScheduleId; i++) {
            VestingSchedule storage schedule = schedulesById[i];
            if (schedule.isActive) {
                if (schedule.isRevoked) {
                    _revokedSchedules = _revokedSchedules.add(1);
                } else {
                    _activeSchedules = _activeSchedules.add(1);
                }
                _totalTokensVested = _totalTokensVested.add(schedule.totalAmount);
                _totalTokensReleased = _totalTokensReleased.add(schedule.releasedAmount);
            }
        }
        
        return (
            nextScheduleId,
            _activeSchedules,
            _revokedSchedules,
            _totalTokensVested,
            _totalTokensReleased
        );
    }
} 