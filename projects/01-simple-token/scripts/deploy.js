const hre = require("hardhat");

/**
 * @title SimpleToken Deployment Script
 * @dev Deploys the complete SimpleToken ecosystem including:
 * - SimpleToken (main token contract)
 * - TokenVesting (vesting contract)
 * - TokenStaking (staking contract)
 * 
 * This script demonstrates a complete DeFi token deployment
 * with all necessary components for a production-ready token.
 */
async function main() {
    console.log("🚀 Starting SimpleToken deployment...");
    
    // Get deployer account
    const [deployer] = await ethers.getSigners();
    console.log("📋 Deploying contracts with account:", deployer.address);
    console.log("💰 Account balance:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");
    
    // Token parameters
    const TOKEN_NAME = "My DeFi Token";
    const TOKEN_SYMBOL = "MDT";
    const MAX_SUPPLY = ethers.utils.parseEther("1000000"); // 1M tokens
    const MINT_PRICE = ethers.utils.parseEther("0.001"); // 0.001 ETH per token
    const BURN_RATE = 500; // 5% burn rate (500 basis points)
    const TRANSFER_FEE = 200; // 2% transfer fee (200 basis points)
    
    // Vesting parameters
    const VESTING_START_TIME = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const VESTING_DURATION = 365 * 24 * 3600; // 1 year
    const VESTING_CLIFF = 30 * 24 * 3600; // 30 days cliff
    
    // Staking parameters
    const STAKING_REWARD_RATE = ethers.utils.parseEther("0.000001"); // Rewards per second per token
    const STAKING_LOCK_PERIOD = 7 * 24 * 3600; // 7 days lock
    const STAKING_PENALTY = 1000; // 10% early withdrawal penalty
    
    console.log("\n📊 Token Configuration:");
    console.log("   Name:", TOKEN_NAME);
    console.log("   Symbol:", TOKEN_SYMBOL);
    console.log("   Max Supply:", ethers.utils.formatEther(MAX_SUPPLY), "tokens");
    console.log("   Mint Price:", ethers.utils.formatEther(MINT_PRICE), "ETH");
    console.log("   Burn Rate:", BURN_RATE / 100, "%");
    console.log("   Transfer Fee:", TRANSFER_FEE / 100, "%");
    
    // ========== DEPLOY SIMPLETOKEN ==========
    console.log("\n🔨 Deploying SimpleToken...");
    
    const SimpleToken = await hre.ethers.getContractFactory("SimpleToken");
    const simpleToken = await SimpleToken.deploy(
        TOKEN_NAME,
        TOKEN_SYMBOL,
        MAX_SUPPLY,
        MINT_PRICE,
        BURN_RATE,
        TRANSFER_FEE
    );
    
    await simpleToken.deployed();
    console.log("✅ SimpleToken deployed to:", simpleToken.address);
    
    // ========== DEPLOY TOKENVESTING ==========
    console.log("\n🔨 Deploying TokenVesting...");
    
    const TokenVesting = await hre.ethers.getContractFactory("TokenVesting");
    const tokenVesting = await TokenVesting.deploy(simpleToken.address);
    
    await tokenVesting.deployed();
    console.log("✅ TokenVesting deployed to:", tokenVesting.address);
    
    // ========== DEPLOY TOKENSTAKING ==========
    console.log("\n🔨 Deploying TokenStaking...");
    
    const TokenStaking = await hre.ethers.getContractFactory("TokenStaking");
    const tokenStaking = await TokenStaking.deploy(simpleToken.address, simpleToken.address);
    
    await tokenStaking.deployed();
    console.log("✅ TokenStaking deployed to:", tokenStaking.address);
    
    // ========== INITIAL SETUP ==========
    console.log("\n⚙️  Performing initial setup...");
    
    // Approve vesting contract to spend tokens
    const vestingAllocation = MAX_SUPPLY.mul(20).div(100); // 20% for vesting
    await simpleToken.approve(tokenVesting.address, vestingAllocation);
    console.log("✅ Approved vesting contract for", ethers.utils.formatEther(vestingAllocation), "tokens");
    
    // Approve staking contract to spend tokens
    const stakingAllocation = MAX_SUPPLY.mul(30).div(100); // 30% for staking rewards
    await simpleToken.approve(tokenStaking.address, stakingAllocation);
    console.log("✅ Approved staking contract for", ethers.utils.formatEther(stakingAllocation), "tokens");
    
    // Create vesting schedules for team members (example)
    const teamMembers = [
        "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6", // Example address 1
        "0x1234567890123456789012345678901234567890", // Example address 2
        "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"  // Example address 3
    ];
    
    const teamAllocation = vestingAllocation.div(teamMembers.length);
    
    for (let i = 0; i < teamMembers.length; i++) {
        await tokenVesting.createVestingSchedule(
            teamMembers[i],
            teamAllocation,
            VESTING_START_TIME,
            VESTING_DURATION,
            VESTING_CLIFF,
            true // Revocable
        );
        console.log(`✅ Created vesting schedule for team member ${i + 1}`);
    }
    
    // Create staking pools
    const poolNames = ["Flexible Pool", "Locked Pool", "Premium Pool"];
    const poolRewardRates = [
        STAKING_REWARD_RATE,
        STAKING_REWARD_RATE.mul(2), // 2x rewards
        STAKING_REWARD_RATE.mul(3)  // 3x rewards
    ];
    const poolLockPeriods = [
        0, // No lock
        STAKING_LOCK_PERIOD,
        STAKING_LOCK_PERIOD.mul(2) // 2x lock period
    ];
    const poolPenalties = [
        0, // No penalty
        STAKING_PENALTY,
        STAKING_PENALTY.mul(2) // 2x penalty
    ];
    
    for (let i = 0; i < poolNames.length; i++) {
        await tokenStaking.createPool(
            poolNames[i],
            poolRewardRates[i],
            poolLockPeriods[i],
            poolPenalties[i]
        );
        console.log(`✅ Created staking pool: ${poolNames[i]}`);
    }
    
    // Add rewards to staking contract
    await simpleToken.transfer(tokenStaking.address, stakingAllocation);
    console.log("✅ Added", ethers.utils.formatEther(stakingAllocation), "tokens to staking rewards");
    
    // ========== VERIFICATION ==========
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
        console.log("\n🔍 Waiting for block confirmations...");
        
        // Wait for 6 block confirmations
        await simpleToken.deployTransaction.wait(6);
        await tokenVesting.deployTransaction.wait(6);
        await tokenStaking.deployTransaction.wait(6);
        
        console.log("\n✅ Verifying contracts on Etherscan...");
        
        try {
            // Verify SimpleToken
            await hre.run("verify:verify", {
                address: simpleToken.address,
                constructorArguments: [
                    TOKEN_NAME,
                    TOKEN_SYMBOL,
                    MAX_SUPPLY,
                    MINT_PRICE,
                    BURN_RATE,
                    TRANSFER_FEE
                ],
            });
            console.log("✅ SimpleToken verified on Etherscan");
        } catch (error) {
            console.log("⚠️  SimpleToken verification failed:", error.message);
        }
        
        try {
            // Verify TokenVesting
            await hre.run("verify:verify", {
                address: tokenVesting.address,
                constructorArguments: [simpleToken.address],
            });
            console.log("✅ TokenVesting verified on Etherscan");
        } catch (error) {
            console.log("⚠️  TokenVesting verification failed:", error.message);
        }
        
        try {
            // Verify TokenStaking
            await hre.run("verify:verify", {
                address: tokenStaking.address,
                constructorArguments: [simpleToken.address, simpleToken.address],
            });
            console.log("✅ TokenStaking verified on Etherscan");
        } catch (error) {
            console.log("⚠️  TokenStaking verification failed:", error.message);
        }
    }
    
    // ========== DEPLOYMENT SUMMARY ==========
    console.log("\n🎉 Deployment completed successfully!");
    console.log("\n📋 Contract Addresses:");
    console.log("   SimpleToken:", simpleToken.address);
    console.log("   TokenVesting:", tokenVesting.address);
    console.log("   TokenStaking:", tokenStaking.address);
    
    console.log("\n📊 Token Distribution:");
    console.log("   Initial Supply (Owner):", ethers.utils.formatEther(await simpleToken.balanceOf(deployer.address)), "tokens");
    console.log("   Vesting Allocation:", ethers.utils.formatEther(vestingAllocation), "tokens");
    console.log("   Staking Rewards:", ethers.utils.formatEther(stakingAllocation), "tokens");
    console.log("   Remaining for Public:", ethers.utils.formatEther(await simpleToken.getRemainingSupply()), "tokens");
    
    console.log("\n🔗 Next Steps:");
    console.log("   1. Test the contracts on testnet");
    console.log("   2. Deploy to mainnet when ready");
    console.log("   3. Set up frontend integration");
    console.log("   4. Configure monitoring and analytics");
    console.log("   5. Launch marketing campaign");
    
    // Save deployment info to file
    const deploymentInfo = {
        network: hre.network.name,
        deployer: deployer.address,
        contracts: {
            simpleToken: simpleToken.address,
            tokenVesting: tokenVesting.address,
            tokenStaking: tokenStaking.address
        },
        parameters: {
            tokenName: TOKEN_NAME,
            tokenSymbol: TOKEN_SYMBOL,
            maxSupply: MAX_SUPPLY.toString(),
            mintPrice: MINT_PRICE.toString(),
            burnRate: BURN_RATE,
            transferFee: TRANSFER_FEE
        },
        deploymentTime: new Date().toISOString()
    };
    
    const fs = require('fs');
    fs.writeFileSync(
        'deployment-info.json',
        JSON.stringify(deploymentInfo, null, 2)
    );
    console.log("\n💾 Deployment info saved to deployment-info.json");
}

/**
 * @dev Error handling for deployment
 */
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    }); 