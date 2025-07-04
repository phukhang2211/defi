const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleToken", function () {
    let SimpleToken;
    let simpleToken;
    let owner;
    let addr1;
    let addr2;
    let addr3;
    
    const TOKEN_NAME = "My DeFi Token";
    const TOKEN_SYMBOL = "MDT";
    const MAX_SUPPLY = ethers.utils.parseEther("1000000"); // 1M tokens
    const MINT_PRICE = ethers.utils.parseEther("0.001"); // 0.001 ETH per token
    const BURN_RATE = 500; // 5% burn rate
    const TRANSFER_FEE = 200; // 2% transfer fee
    
    beforeEach(async function () {
        SimpleToken = await ethers.getContractFactory("SimpleToken");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        
        simpleToken = await SimpleToken.deploy(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            MAX_SUPPLY,
            MINT_PRICE,
            BURN_RATE,
            TRANSFER_FEE
        );
        await simpleToken.deployed();
    });
    
    describe("Deployment", function () {
        it("Should set the correct token parameters", async function () {
            expect(await simpleToken.name()).to.equal(TOKEN_NAME);
            expect(await simpleToken.symbol()).to.equal(TOKEN_SYMBOL);
            expect(await simpleToken.maxSupply()).to.equal(MAX_SUPPLY);
            expect(await simpleToken.mintPrice()).to.equal(MINT_PRICE);
            expect(await simpleToken.burnRate()).to.equal(BURN_RATE);
            expect(await simpleToken.transferFee()).to.equal(TRANSFER_FEE);
            expect(await simpleToken.mintingEnabled()).to.equal(true);
        });
        
        it("Should mint initial supply to owner", async function () {
            const initialSupply = MAX_SUPPLY.mul(10).div(100); // 10% of max supply
            expect(await simpleToken.balanceOf(owner.address)).to.equal(initialSupply);
            expect(await simpleToken.totalSupply()).to.equal(initialSupply);
        });
        
        it("Should set owner as fee collector", async function () {
            expect(await simpleToken.feeCollector()).to.equal(owner.address);
        });
    });
    
    describe("Minting", function () {
        it("Should mint tokens when payment is sufficient", async function () {
            const mintAmount = 100;
            const mintCost = MINT_PRICE.mul(mintAmount);
            
            await simpleToken.connect(addr1).mint(mintAmount, {
                value: mintCost
            });
            
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                ethers.utils.parseEther(mintAmount.toString())
            );
        });
        
        it("Should fail when payment is insufficient", async function () {
            const mintAmount = 100;
            const insufficientCost = MINT_PRICE.mul(mintAmount).sub(ethers.utils.parseEther("0.001"));
            
            await expect(
                simpleToken.connect(addr1).mint(mintAmount, {
                    value: insufficientCost
                })
            ).to.be.revertedWith("Insufficient payment");
        });
        
        it("Should fail when minting exceeds max supply", async function () {
            const largeAmount = MAX_SUPPLY.add(ethers.utils.parseEther("1"));
            
            await expect(
                simpleToken.connect(addr1).mint(largeAmount, {
                    value: MINT_PRICE.mul(largeAmount)
                })
            ).to.be.revertedWith("Exceeds max supply");
        });
        
        it("Should fail when minting is disabled", async function () {
            await simpleToken.toggleMinting();
            
            await expect(
                simpleToken.connect(addr1).mint(100, {
                    value: MINT_PRICE.mul(100)
                })
            ).to.be.revertedWith("Minting is disabled");
        });
        
        it("Should refund excess payment", async function () {
            const mintAmount = 100;
            const mintCost = MINT_PRICE.mul(mintAmount);
            const excessPayment = ethers.utils.parseEther("0.1");
            
            const initialBalance = await addr1.getBalance();
            
            await simpleToken.connect(addr1).mint(mintAmount, {
                value: mintCost.add(excessPayment)
            });
            
            const finalBalance = await addr1.getBalance();
            const gasUsed = ethers.utils.parseEther("0.001"); // Approximate gas cost
            
            // Check that excess payment was refunded (accounting for gas)
            expect(finalBalance).to.be.closeTo(
                initialBalance.sub(mintCost).sub(gasUsed),
                ethers.utils.parseEther("0.01") // Allow for gas estimation variance
            );
        });
        
        it("Should allow owner to mint for free", async function () {
            const amount = ethers.utils.parseEther("1000");
            
            await simpleToken.mintFor(addr1.address, amount);
            
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(amount);
        });
        
        it("Should fail when non-owner tries to mint for free", async function () {
            const amount = ethers.utils.parseEther("1000");
            
            await expect(
                simpleToken.connect(addr1).mintFor(addr2.address, amount)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
    
    describe("Burning", function () {
        beforeEach(async function () {
            // Give addr1 some tokens to burn
            await simpleToken.mintFor(addr1.address, ethers.utils.parseEther("1000"));
        });
        
        it("Should burn tokens correctly", async function () {
            const burnAmount = ethers.utils.parseEther("100");
            const initialBalance = await simpleToken.balanceOf(addr1.address);
            const initialTotalSupply = await simpleToken.totalSupply();
            
            await simpleToken.connect(addr1).burn(burnAmount);
            
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                initialBalance.sub(burnAmount)
            );
            expect(await simpleToken.totalSupply()).to.equal(
                initialTotalSupply.sub(burnAmount)
            );
        });
        
        it("Should fail when burning more than balance", async function () {
            const burnAmount = ethers.utils.parseEther("2000"); // More than balance
            
            await expect(
                simpleToken.connect(addr1).burn(burnAmount)
            ).to.be.revertedWith("Insufficient balance");
        });
        
        it("Should fail when burning zero amount", async function () {
            await expect(
                simpleToken.connect(addr1).burn(0)
            ).to.be.revertedWith("Amount must be positive");
        });
    });
    
    describe("Transfers with Fees and Burns", function () {
        beforeEach(async function () {
            // Give addr1 tokens to transfer
            await simpleToken.mintFor(addr1.address, ethers.utils.parseEther("1000"));
        });
        
        it("Should transfer tokens with correct fee and burn calculations", async function () {
            const transferAmount = ethers.utils.parseEther("100");
            const initialBalance = await simpleToken.balanceOf(addr1.address);
            const initialRecipientBalance = await simpleToken.balanceOf(addr2.address);
            const initialFeeCollectorBalance = await simpleToken.balanceOf(owner.address);
            const initialTotalSupply = await simpleToken.totalSupply();
            
            await simpleToken.connect(addr1).transfer(addr2.address, transferAmount);
            
            // Calculate expected amounts
            const burnAmount = transferAmount.mul(BURN_RATE).div(10000); // 5% burn
            const feeAmount = transferAmount.mul(TRANSFER_FEE).div(10000); // 2% fee
            const actualTransferAmount = transferAmount.sub(burnAmount).sub(feeAmount);
            
            // Check balances
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                initialBalance.sub(transferAmount)
            );
            expect(await simpleToken.balanceOf(addr2.address)).to.equal(
                initialRecipientBalance.add(actualTransferAmount)
            );
            expect(await simpleToken.balanceOf(owner.address)).to.equal(
                initialFeeCollectorBalance.add(feeAmount)
            );
            
            // Check total supply (should be reduced by burn amount)
            expect(await simpleToken.totalSupply()).to.equal(
                initialTotalSupply.sub(burnAmount)
            );
        });
        
        it("Should handle transferFrom with fees and burns", async function () {
            const transferAmount = ethers.utils.parseEther("100");
            
            // Approve addr3 to spend addr1's tokens
            await simpleToken.connect(addr1).approve(addr3.address, transferAmount);
            
            const initialBalance = await simpleToken.balanceOf(addr1.address);
            const initialRecipientBalance = await simpleToken.balanceOf(addr2.address);
            const initialTotalSupply = await simpleToken.totalSupply();
            
            await simpleToken.connect(addr3).transferFrom(addr1.address, addr2.address, transferAmount);
            
            // Calculate expected amounts
            const burnAmount = transferAmount.mul(BURN_RATE).div(10000);
            const feeAmount = transferAmount.mul(TRANSFER_FEE).div(10000);
            const actualTransferAmount = transferAmount.sub(burnAmount).sub(feeAmount);
            
            // Check balances
            expect(await simpleToken.balanceOf(addr1.address)).to.equal(
                initialBalance.sub(transferAmount)
            );
            expect(await simpleToken.balanceOf(addr2.address)).to.equal(
                initialRecipientBalance.add(actualTransferAmount)
            );
            
            // Check total supply
            expect(await simpleToken.totalSupply()).to.equal(
                initialTotalSupply.sub(burnAmount)
            );
        });
    });
    
    describe("Admin Functions", function () {
        it("Should allow owner to toggle minting", async function () {
            expect(await simpleToken.mintingEnabled()).to.equal(true);
            
            await simpleToken.toggleMinting();
            expect(await simpleToken.mintingEnabled()).to.equal(false);
            
            await simpleToken.toggleMinting();
            expect(await simpleToken.mintingEnabled()).to.equal(true);
        });
        
        it("Should allow owner to update mint price", async function () {
            const newPrice = ethers.utils.parseEther("0.002");
            
            await simpleToken.updateMintPrice(newPrice);
            expect(await simpleToken.mintPrice()).to.equal(newPrice);
        });
        
        it("Should allow owner to update burn rate", async function () {
            const newBurnRate = 1000; // 10%
            
            await simpleToken.updateBurnRate(newBurnRate);
            expect(await simpleToken.burnRate()).to.equal(newBurnRate);
        });
        
        it("Should allow owner to update transfer fee", async function () {
            const newFee = 500; // 5%
            
            await simpleToken.updateTransferFee(newFee);
            expect(await simpleToken.transferFee()).to.equal(newFee);
        });
        
        it("Should allow owner to update fee collector", async function () {
            await simpleToken.updateFeeCollector(addr1.address);
            expect(await simpleToken.feeCollector()).to.equal(addr1.address);
        });
        
        it("Should fail when non-owner calls admin functions", async function () {
            await expect(
                simpleToken.connect(addr1).toggleMinting()
            ).to.be.revertedWith("Ownable: caller is not the owner");
            
            await expect(
                simpleToken.connect(addr1).updateMintPrice(ethers.utils.parseEther("0.002"))
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
    
    describe("Pausing", function () {
        it("Should pause and unpause correctly", async function () {
            expect(await simpleToken.paused()).to.equal(false);
            
            await simpleToken.pause();
            expect(await simpleToken.paused()).to.equal(true);
            
            await simpleToken.unpause();
            expect(await simpleToken.paused()).to.equal(false);
        });
        
        it("Should prevent transfers when paused", async function () {
            await simpleToken.mintFor(addr1.address, ethers.utils.parseEther("100"));
            await simpleToken.pause();
            
            await expect(
                simpleToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("10"))
            ).to.be.revertedWith("Pausable: paused");
        });
        
        it("Should prevent minting when paused", async function () {
            await simpleToken.pause();
            
            await expect(
                simpleToken.connect(addr1).mint(100, {
                    value: MINT_PRICE.mul(100)
                })
            ).to.be.revertedWith("Pausable: paused");
        });
    });
    
    describe("View Functions", function () {
        it("Should return correct token statistics", async function () {
            const stats = await simpleToken.getTokenStats();
            
            expect(stats._totalSupply).to.equal(await simpleToken.totalSupply());
            expect(stats._maxSupply).to.equal(MAX_SUPPLY);
            expect(stats._totalMinted).to.be.gt(0);
            expect(stats._totalBurned).to.equal(0);
            expect(stats._burnRate).to.equal(BURN_RATE);
            expect(stats._transferFee).to.equal(TRANSFER_FEE);
        });
        
        it("Should calculate burn amount correctly", async function () {
            const amount = ethers.utils.parseEther("100");
            const expectedBurnAmount = amount.mul(BURN_RATE).div(10000);
            
            expect(await simpleToken.calculateBurnAmount(amount)).to.equal(expectedBurnAmount);
        });
        
        it("Should calculate transfer fee correctly", async function () {
            const amount = ethers.utils.parseEther("100");
            const expectedFee = amount.mul(TRANSFER_FEE).div(10000);
            
            expect(await simpleToken.calculateTransferFee(amount)).to.equal(expectedFee);
        });
        
        it("Should calculate actual transfer amount correctly", async function () {
            const amount = ethers.utils.parseEther("100");
            const burnAmount = amount.mul(BURN_RATE).div(10000);
            const feeAmount = amount.mul(TRANSFER_FEE).div(10000);
            const expectedActualAmount = amount.sub(burnAmount).sub(feeAmount);
            
            expect(await simpleToken.calculateActualTransferAmount(amount)).to.equal(expectedActualAmount);
        });
    });
    
    describe("Edge Cases", function () {
        it("Should handle zero burn rate correctly", async function () {
            // Deploy new token with zero burn rate
            const zeroBurnToken = await SimpleToken.deploy(
                "Zero Burn Token",
                "ZBT",
                MAX_SUPPLY,
                MINT_PRICE,
                0, // Zero burn rate
                TRANSFER_FEE
            );
            
            await zeroBurnToken.mintFor(addr1.address, ethers.utils.parseEther("100"));
            
            const transferAmount = ethers.utils.parseEther("50");
            const initialTotalSupply = await zeroBurnToken.totalSupply();
            
            await zeroBurnToken.connect(addr1).transfer(addr2.address, transferAmount);
            
            // Total supply should remain the same (no burning)
            expect(await zeroBurnToken.totalSupply()).to.equal(initialTotalSupply);
        });
        
        it("Should handle zero transfer fee correctly", async function () {
            // Deploy new token with zero transfer fee
            const zeroFeeToken = await SimpleToken.deploy(
                "Zero Fee Token",
                "ZFT",
                MAX_SUPPLY,
                MINT_PRICE,
                BURN_RATE,
                0 // Zero transfer fee
            );
            
            await zeroFeeToken.mintFor(addr1.address, ethers.utils.parseEther("100"));
            
            const transferAmount = ethers.utils.parseEther("50");
            const initialFeeCollectorBalance = await zeroFeeToken.balanceOf(owner.address);
            
            await zeroFeeToken.connect(addr1).transfer(addr2.address, transferAmount);
            
            // Fee collector balance should remain the same (no fees)
            expect(await zeroFeeToken.balanceOf(owner.address)).to.equal(initialFeeCollectorBalance);
        });
        
        it("Should handle maximum basis points correctly", async function () {
            // Test with 100% burn rate and transfer fee
            await expect(
                SimpleToken.deploy(
                    "Max Token",
                    "MAX",
                    MAX_SUPPLY,
                    MINT_PRICE,
                    10001, // Exceeds 100%
                    TRANSFER_FEE
                )
            ).to.be.revertedWith("Invalid basis points (max 100%)");
            
            await expect(
                SimpleToken.deploy(
                    "Max Token",
                    "MAX",
                    MAX_SUPPLY,
                    MINT_PRICE,
                    BURN_RATE,
                    10001 // Exceeds 100%
                )
            ).to.be.revertedWith("Invalid basis points (max 100%)");
        });
    });
    
    describe("Events", function () {
        it("Should emit correct events on minting", async function () {
            const mintAmount = 100;
            const mintCost = MINT_PRICE.mul(mintAmount);
            
            await expect(
                simpleToken.connect(addr1).mint(mintAmount, { value: mintCost })
            ).to.emit(simpleToken, "TokensMinted")
              .withArgs(addr1.address, ethers.utils.parseEther(mintAmount.toString()), mintCost, await time());
        });
        
        it("Should emit correct events on burning", async function () {
            await simpleToken.mintFor(addr1.address, ethers.utils.parseEther("100"));
            
            const burnAmount = ethers.utils.parseEther("50");
            
            await expect(
                simpleToken.connect(addr1).burn(burnAmount)
            ).to.emit(simpleToken, "TokensBurned")
              .withArgs(addr1.address, burnAmount, await time());
        });
        
        it("Should emit correct events on admin changes", async function () {
            await expect(simpleToken.toggleMinting())
                .to.emit(simpleToken, "MintingToggled")
                .withArgs(false, await time());
                
            await expect(simpleToken.updateMintPrice(ethers.utils.parseEther("0.002")))
                .to.emit(simpleToken, "MintPriceUpdated")
                .withArgs(MINT_PRICE, ethers.utils.parseEther("0.002"), await time());
        });
    });
});

// Helper function to get current timestamp
async function time() {
    return (await ethers.provider.getBlock("latest")).timestamp;
} 