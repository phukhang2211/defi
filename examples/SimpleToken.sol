// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title SimpleToken
 * @dev A simple ERC-20 token with minting, burning, and pausing capabilities
 * 
 * Features:
 * - Standard ERC-20 functionality
 * - Minting (owner only)
 * - Burning (anyone can burn their own tokens)
 * - Pausing (emergency stop)
 * - Capped supply
 */
contract SimpleToken is ERC20, Ownable, Pausable {
    uint256 public maxSupply;
    uint256 public mintPrice;
    bool public mintingEnabled;
    
    // Events
    event TokensMinted(address indexed to, uint256 amount, uint256 cost);
    event TokensBurned(address indexed from, uint256 amount);
    event MintingToggled(bool enabled);
    event MintPriceUpdated(uint256 newPrice);
    
    /**
     * @dev Constructor sets up the token with initial parameters
     * @param name Token name
     * @param symbol Token symbol
     * @param _maxSupply Maximum supply of tokens
     * @param _mintPrice Price per token in wei
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC20(name, symbol) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintingEnabled = true;
    }
    
    /**
     * @dev Mint tokens by paying ETH
     * @param amount Number of tokens to mint
     */
    function mint(uint256 amount) external payable whenNotPaused {
        require(mintingEnabled, "Minting is disabled");
        require(amount > 0, "Amount must be positive");
        require(msg.value >= mintPrice * amount, "Insufficient payment");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount, msg.value);
    }
    
    /**
     * @dev Burn tokens (anyone can burn their own tokens)
     * @param amount Number of tokens to burn
     */
    function burn(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Owner can mint tokens for free (for airdrops, etc.)
     * @param to Recipient address
     * @param amount Number of tokens to mint
     */
    function mintFor(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _mint(to, amount);
        emit TokensMinted(to, amount, 0);
    }
    
    /**
     * @dev Toggle minting on/off
     */
    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
        emit MintingToggled(mintingEnabled);
    }
    
    /**
     * @dev Update mint price
     * @param newPrice New price per token in wei
     */
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
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
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        payable(owner()).transfer(balance);
    }
    
    /**
     * @dev Get contract ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get remaining mintable tokens
     */
    function getRemainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }
    
    /**
     * @dev Override transfer function to include pausing
     */
    function transfer(address to, uint256 amount) 
        public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom function to include pausing
     */
    function transferFrom(address from, address to, uint256 amount) 
        public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
} 