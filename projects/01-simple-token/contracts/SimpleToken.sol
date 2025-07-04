// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title SimpleToken
 * @dev A comprehensive ERC-20 token implementation for DeFi learning
 * 
 * This contract demonstrates key concepts:
 * - ERC-20 standard compliance
 * - Access control and ownership
 * - Emergency pause functionality
 * - Minting and burning mechanisms
 * - Fee collection and distribution
 * - Event logging for transparency
 * 
 * Features:
 * - Standard ERC-20 functionality (transfer, approve, etc.)
 * - Public minting with ETH payment
 * - Owner-only free minting for airdrops
 * - Token burning (deflationary mechanism)
 * - Emergency pause/unpause
 * - Fee collection and withdrawal
 * - Supply cap management
 * - Comprehensive event logging
 */
contract SimpleToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    
    // Token configuration
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public burnRate; // Percentage of tokens burned on transfer (basis points)
    bool public mintingEnabled;
    
    // Fee management
    uint256 public transferFee; // Fee on transfers (basis points)
    address public feeCollector;
    
    // Statistics
    uint256 public totalMinted;
    uint256 public totalBurned;
    uint256 public totalFeesCollected;
    
    // Events for transparency
    event TokensMinted(address indexed to, uint256 amount, uint256 cost, uint256 timestamp);
    event TokensBurned(address indexed from, uint256 amount, uint256 timestamp);
    event MintingToggled(bool enabled, uint256 timestamp);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event BurnRateUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);
    event TransferFeeUpdated(uint256 oldFee, uint256 newFee, uint256 timestamp);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event FeesWithdrawn(address indexed collector, uint256 amount, uint256 timestamp);
    
    // Modifiers
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }
    
    modifier validBasisPoints(uint256 basisPoints) {
        require(basisPoints <= 10000, "Invalid basis points (max 100%)");
        _;
    }
    
    /**
     * @dev Constructor initializes the token with basic parameters
     * @param name Token name (e.g., "My DeFi Token")
     * @param symbol Token symbol (e.g., "MDT")
     * @param _maxSupply Maximum total supply of tokens
     * @param _mintPrice Price per token in wei (0 for free minting)
     * @param _burnRate Burn rate in basis points (0-10000, where 10000 = 100%)
     * @param _transferFee Transfer fee in basis points (0-10000)
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _burnRate,
        uint256 _transferFee
    ) ERC20(name, symbol) validBasisPoints(_burnRate) validBasisPoints(_transferFee) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        burnRate = _burnRate;
        transferFee = _transferFee;
        mintingEnabled = true;
        feeCollector = msg.sender;
        
        // Mint initial supply to owner (10% of max supply)
        uint256 initialSupply = _maxSupply.mul(10).div(100);
        _mint(msg.sender, initialSupply);
        totalMinted = totalMinted.add(initialSupply);
        
        emit TokensMinted(msg.sender, initialSupply, 0, block.timestamp);
    }
    
    /**
     * @dev Public minting function - users pay ETH to mint tokens
     * @param amount Number of tokens to mint
     */
    function mint(uint256 amount) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
        validAmount(amount) 
    {
        require(mintingEnabled, "Minting is disabled");
        require(totalSupply().add(amount) <= maxSupply, "Exceeds max supply");
        
        uint256 requiredPayment = mintPrice.mul(amount);
        require(msg.value >= requiredPayment, "Insufficient payment");
        
        _mint(msg.sender, amount);
        totalMinted = totalMinted.add(amount);
        
        // Refund excess payment
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value.sub(requiredPayment));
        }
        
        emit TokensMinted(msg.sender, amount, requiredPayment, block.timestamp);
    }
    
    /**
     * @dev Owner can mint tokens for free (for airdrops, team allocation, etc.)
     * @param to Recipient address
     * @param amount Number of tokens to mint
     */
    function mintFor(address to, uint256 amount) 
        external 
        onlyOwner 
        whenNotPaused 
        validAddress(to) 
        validAmount(amount) 
    {
        require(totalSupply().add(amount) <= maxSupply, "Exceeds max supply");
        
        _mint(to, amount);
        totalMinted = totalMinted.add(amount);
        
        emit TokensMinted(to, amount, 0, block.timestamp);
    }
    
    /**
     * @dev Burn tokens (anyone can burn their own tokens)
     * @param amount Number of tokens to burn
     */
    function burn(uint256 amount) 
        external 
        whenNotPaused 
        validAmount(amount) 
    {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _burn(msg.sender, amount);
        totalBurned = totalBurned.add(amount);
        
        emit TokensBurned(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Override transfer function to include burn rate and transfer fees
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transfer(address to, uint256 amount) 
        public 
        virtual 
        override 
        whenNotPaused 
        validAddress(to) 
        validAmount(amount) 
        returns (bool) 
    {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;
        uint256 transferAmount = amount;
        
        // Calculate burn amount
        if (burnRate > 0) {
            burnAmount = amount.mul(burnRate).div(10000);
            transferAmount = transferAmount.sub(burnAmount);
        }
        
        // Calculate transfer fee
        if (transferFee > 0) {
            feeAmount = amount.mul(transferFee).div(10000);
            transferAmount = transferAmount.sub(feeAmount);
        }
        
        // Execute transfers
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
            totalBurned = totalBurned.add(burnAmount);
            emit TokensBurned(msg.sender, burnAmount, block.timestamp);
        }
        
        if (feeAmount > 0) {
            _transfer(msg.sender, feeCollector, feeAmount);
            totalFeesCollected = totalFeesCollected.add(feeAmount);
        }
        
        if (transferAmount > 0) {
            _transfer(msg.sender, to, transferAmount);
        }
        
        return true;
    }
    
    /**
     * @dev Override transferFrom function to include burn rate and transfer fees
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        virtual 
        override 
        whenNotPaused 
        validAddress(from) 
        validAddress(to) 
        validAmount(amount) 
        returns (bool) 
    {
        require(balanceOf(from) >= amount, "Insufficient balance");
        require(allowance(from, msg.sender) >= amount, "Insufficient allowance");
        
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;
        uint256 transferAmount = amount;
        
        // Calculate burn amount
        if (burnRate > 0) {
            burnAmount = amount.mul(burnRate).div(10000);
            transferAmount = transferAmount.sub(burnAmount);
        }
        
        // Calculate transfer fee
        if (transferFee > 0) {
            feeAmount = amount.mul(transferFee).div(10000);
            transferAmount = transferAmount.sub(feeAmount);
        }
        
        // Execute transfers
        if (burnAmount > 0) {
            _burn(from, burnAmount);
            totalBurned = totalBurned.add(burnAmount);
            emit TokensBurned(from, burnAmount, block.timestamp);
        }
        
        if (feeAmount > 0) {
            _transfer(from, feeCollector, feeAmount);
            totalFeesCollected = totalFeesCollected.add(feeAmount);
        }
        
        if (transferAmount > 0) {
            _transfer(from, to, transferAmount);
        }
        
        _approve(from, msg.sender, allowance(from, msg.sender).sub(amount));
        
        return true;
    }
    
    // ========== ADMIN FUNCTIONS ==========
    
    /**
     * @dev Toggle minting on/off
     */
    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
        emit MintingToggled(mintingEnabled, block.timestamp);
    }
    
    /**
     * @dev Update mint price
     * @param newPrice New price per token in wei
     */
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        uint256 oldPrice = mintPrice;
        mintPrice = newPrice;
        emit MintPriceUpdated(oldPrice, newPrice, block.timestamp);
    }
    
    /**
     * @dev Update burn rate
     * @param newRate New burn rate in basis points
     */
    function updateBurnRate(uint256 newRate) external onlyOwner validBasisPoints(newRate) {
        uint256 oldRate = burnRate;
        burnRate = newRate;
        emit BurnRateUpdated(oldRate, newRate, block.timestamp);
    }
    
    /**
     * @dev Update transfer fee
     * @param newFee New transfer fee in basis points
     */
    function updateTransferFee(uint256 newFee) external onlyOwner validBasisPoints(newFee) {
        uint256 oldFee = transferFee;
        transferFee = newFee;
        emit TransferFeeUpdated(oldFee, newFee, block.timestamp);
    }
    
    /**
     * @dev Update fee collector address
     * @param newCollector New fee collector address
     */
    function updateFeeCollector(address newCollector) external onlyOwner validAddress(newCollector) {
        address oldCollector = feeCollector;
        feeCollector = newCollector;
        emit FeeCollectorUpdated(oldCollector, newCollector);
    }
    
    /**
     * @dev Pause all token transfers
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause all token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Withdraw ETH from contract
     */
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        payable(owner()).transfer(balance);
    }
    
    /**
     * @dev Withdraw collected fees
     */
    function withdrawFees() external {
        require(msg.sender == feeCollector, "Only fee collector can withdraw fees");
        
        uint256 balance = balanceOf(feeCollector);
        require(balance > 0, "No fees to withdraw");
        
        _transfer(feeCollector, msg.sender, balance);
        emit FeesWithdrawn(msg.sender, balance, block.timestamp);
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev Get contract ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get remaining mintable tokens
     */
    function getRemainingSupply() external view returns (uint256) {
        return maxSupply.sub(totalSupply());
    }
    
    /**
     * @dev Get token statistics
     */
    function getTokenStats() external view returns (
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _totalMinted,
        uint256 _totalBurned,
        uint256 _totalFeesCollected,
        uint256 _burnRate,
        uint256 _transferFee
    ) {
        return (
            totalSupply(),
            maxSupply,
            totalMinted,
            totalBurned,
            totalFeesCollected,
            burnRate,
            transferFee
        );
    }
    
    /**
     * @dev Calculate burn amount for a given transfer amount
     * @param amount Transfer amount
     */
    function calculateBurnAmount(uint256 amount) external view returns (uint256) {
        return amount.mul(burnRate).div(10000);
    }
    
    /**
     * @dev Calculate transfer fee for a given transfer amount
     * @param amount Transfer amount
     */
    function calculateTransferFee(uint256 amount) external view returns (uint256) {
        return amount.mul(transferFee).div(10000);
    }
    
    /**
     * @dev Calculate actual transfer amount after fees and burns
     * @param amount Original transfer amount
     */
    function calculateActualTransferAmount(uint256 amount) external view returns (uint256) {
        uint256 burnAmount = amount.mul(burnRate).div(10000);
        uint256 feeAmount = amount.mul(transferFee).div(10000);
        return amount.sub(burnAmount).sub(feeAmount);
    }
} 