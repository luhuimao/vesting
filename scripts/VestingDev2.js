// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// const { web3 } = require("hardhat");
const hre = require("hardhat");
// require("@nomiclabs/hardhat-web3");
const { ReplaceLine } = require('./boutils');
// require('../typechain')
// import { ethers, network, artifacts } from 'hardhat';

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');
    // let owner = new hre.ethers.Wallet('af43652256977c85d2e39d57258ed7a5a774c41ccc02c8c6fc8f709d316ddc55', ethers.provider);
    let [owner, user1, user2, user3] = await hre.ethers.getSigners();
    console.log('owner addr: ', owner.address.toString());
    console.log('user1 addr: ', user1.address.toString());
    console.log('user2 addr: ', user2.address.toString());
    console.log('user3 addr: ', user3.address.toString());

    var blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;

    var blockGaslimit = blockGaslimit0.div(4);
    // We get the contract to deploy

    /*****************************************************************************************/
    /*******************************Deploy Vesting2******************************************/
    /*****************************************************************************************/
    const Vesting2 = await hre.ethers.getContractFactory("Vesting2");
    instanceVesting2 = await Vesting2.connect(owner).deploy();
    // instanceConfigAddress = BoredApeYachtClub.connect(owner).attach(tmpaddr) as ConfigAddress;
    await instanceVesting2.connect(owner).deployed();
    console.log("Vesting deployed to:", instanceVesting2.address);

    /*****************************************************************************************/
    /*******************************Deploy TestERC20******************************************/
    /*****************************************************************************************/
    const TestERC20 = await hre.ethers.getContractFactory("ERC20PresetFixedSupply");
    instanceTESTERC20 = await TestERC20.connect(owner).deploy("TEST TOKEN", "TT", 100000000, owner.address);
    await instanceTESTERC20.connect(owner).deployed();
    let ownerERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("TestERC20 deployed to:", instanceTESTERC20.address);
    console.log(`Owner TestERC20 Balance: ${ownerERC20Balance.toString()}`);

    /*****************************************************************************************/
    /*******************************Deploy TestNFT******************************************/
    /*****************************************************************************************/
    const TestNFT = await hre.ethers.getContractFactory("TestNFT");
    instanceTestNFT = await TestNFT.connect(owner).deploy('TEST ERC721', 'TE721', 100);
    await instanceTestNFT.connect(owner).deployed();
    console.log("ERC721 deployed to:", instanceTestNFT.address);

    /*****************************************************************************************/
    /*******************************mint 10 ERC721 Token To owner*****************************/
    /*****************************************************************************************/
    await instanceTestNFT.mint(2);
    let ownerERC721Balance = await instanceTestNFT.balanceOf(owner.address);
    console.log("ownerERC721Balance: ", ownerERC721Balance.toString());

    // let flag = '\\/\\/REPLACE_FLAG';
    // let key = 'NFT_ADDRESS_' + network.name.toUpperCase();
    // ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceSablier.address + '"; ' + flag);
    // key = 'DEPLOY_ACCOUNT_' + network.name.toUpperCase();
    // ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + owner.address + '"; ' + flag);

    let ownerTestERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTestERC20Balance: ", ownerTestERC20Balance.toString());
    // nftOwner1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    await instanceTESTERC20.approve(instanceVesting2.address, approve_amount);

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 1;
    const stopTime = startTime + 30;

    console.log("/*****************************************************************************************/");
    console.log("/***********************************************createStream2*****************************/");
    console.log("/*****************************************************************************************/");
    let tmpr = await instanceVesting2.createStream2(
        20000,
        instanceTESTERC20.address,
        startTime,
        stopTime,
        instanceTestNFT.address,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [
            1, 2, 3, 4,
            5, 6, 7, 8,
            9, 10
        ],
    );

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    // console.log(tmpr);
    if (!tmpr.gasPrice) {
        var rel = await tmpr.wait(1);
        // console.log(`stream create result: ${rel}`);
    } else {
        // console.log("result", tmpr)
    }
    // console.log("rel: ", rel);

    let streamInfo = await instanceVesting2.getStream2(200000);
    // console.log(`streamInfo: ${streamInfo}`);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    let duration = (await hre.ethers.provider.getBlock("latest")).timestamp - streamInfo.startTime;
    console.log("duration:", duration.toString());
    console.log("ratePerSecond:", streamInfo.ratePerSecond.toString());
    console.log("whole balance:", duration * streamInfo.ratePerSecond);
    console.log("stream remainingBalance:", streamInfo.remainingBalance.toString());

    let ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    let user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    let user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    let senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderBalance: ${senderBalance.toString()}`);

    let ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance1.toString());

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${blocktimestamp.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/****************************************owner withdraw***********************************/");
    console.log("/*****************************************************************************************/");

    duration = (await hre.ethers.provider.getBlock("latest")).timestamp - streamInfo.startTime;
    console.log("duration:", duration.toString());
    console.log("ratePerSecond:", streamInfo.ratePerSecond.toString());
    console.log("whole balance:", duration * streamInfo.ratePerSecond);
    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);

    let token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
    console.log(`token0 available balance: ${token0Balance}`);

    let token0RemainingBalance = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
    console.log(`token0 remainning balance: ${token0RemainingBalance}`);

    if (token0Balance > 0) {
        console.log("//////////////////////////////withdraw token0/////////////////////////////////");
        await instanceVesting2.connect(owner).withdrawFromStream2ByTokenId(200000, 0);
        ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
        console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance2.toString());
        console.log("withdraw amount: ", ownerTESTERC20Balance2 - ownerTESTERC20Balance1);

        token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
        console.log(`token0 available balance: ${token0Balance}`);

        token0RemainingBalance = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
        console.log(`token0 remainning balance: ${token0RemainingBalance}`);

        streamInfo = await instanceVesting2.getStream2(200000);
        console.log(`stream2 remainingBalance: ${streamInfo.remainingBalance}`);
    }
    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);

    if (ownerBalance > 0) {
        console.log("//////////////////////////////withdraw all/////////////////////////////////");
        console.log(`owner all available balance: ${ownerBalance}`);

        token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
        console.log(`token0 available balance: ${token0Balance}`);

        token1Balance = await instanceVesting2.balanceForTokenId(200000, 1);
        console.log(`token1 available balance: ${token1Balance}`);

        token0RemainingBalance1 = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
        console.log(`token0 remainning balance: ${token0RemainingBalance1}`);

        token1RemainingBalance1 = await instanceVesting2.remainingBalanceByTokenId(200000, 1);
        console.log(`token1 remainning balance: ${token1RemainingBalance1}`);

        ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
        await instanceVesting2.connect(owner).withdrawFromStream2(200000);
        ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
        console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance2.toString());
        console.log("withdraw amount: ", ownerTESTERC20Balance2 - ownerTESTERC20Balance1);
        streamInfo = await instanceVesting2.getStream2(200000);
        console.log(`stream2 remainingBalance: ${streamInfo.remainingBalance}`);
        // console.log("withdraw amount:", streamInfo.deposit - streamInfo.remainingBalance);

        token0RemainingBalance2 = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
        console.log(`token0 remainning balance: ${token0RemainingBalance2}`);
        token0_withdraw_amount = token0RemainingBalance1 - token0RemainingBalance2;
        console.log(`token0 withdraw amount: ${token0_withdraw_amount}`);

        token1RemainingBalance2 = await instanceVesting2.remainingBalanceByTokenId(200000, 1);
        console.log(`token1 remainning balance: ${token1RemainingBalance2}`);
        token1_withdraw_amount = token1RemainingBalance1 - token1RemainingBalance2;
        console.log(`token1 withdraw amount: ${token1_withdraw_amount}`);

        if ((token0_withdraw_amount + token1_withdraw_amount) != (ownerTESTERC20Balance2 - ownerTESTERC20Balance1)) {
            console.error("error: withdraw all failed");
            return;
        }
    }

    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from owner to user1*****************************/");
    console.log("/*****************************************************************************************/");
    token0RemainingBalance2 = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
    console.log(`token0 remainning balance: ${token0RemainingBalance2}`);
    token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
    console.log(`token0 available balance: ${token0Balance}`);

    await instanceTestNFT.transferFrom(owner.address, user1.address, 0);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
    console.log(`token0 available balance: ${token0Balance}`);
    token0RemainingBalance1 = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
    console.log(`token0 remainning balance: ${token0RemainingBalance1}`);

    duration = (await hre.ethers.provider.getBlock("latest")).timestamp - streamInfo.startTime;
    console.log("duration:", duration.toString());
    // console.log("ratePerSecond:", streamInfo.ratePerSecond.toString());
    // console.log("whole balance:", duration * streamInfo.ratePerSecond);

    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    let user1TESTERC20Balance1 = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1TestERC20Balance1: ", user1TESTERC20Balance1.toString());

    // blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${blocktimestamp.toString()}`);

    user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    if (user1Balance > 0) {
        await instanceVesting2.connect(user1).withdrawFromStream2(200000);
        user1TESTERC20Balance2 = await instanceTESTERC20.balanceOf(user1.address);
        console.log("user1TestERC20Balance2: ", user1TESTERC20Balance2.toString());

        token0Balance = await instanceVesting2.balanceForTokenId(200000, 0);
        console.log(`token0 available balance: ${token0Balance}`);
        token0RemainingBalance2 = await instanceVesting2.remainingBalanceByTokenId(200000, 0);
        console.log(`token0 remainning balance: ${token0RemainingBalance2}`);

        if ((token0RemainingBalance1 - token0RemainingBalance2) != (user1TESTERC20Balance2 - user1TESTERC20Balance1)) {
            console.error("user1 withdraw failed");
            return;
        }
    }

    streamInfo = await instanceVesting2.getStream2(200000);
    console.log(`stream remainingBalance: ${streamInfo.remainingBalance}`);

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from user1 to user2*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.connect(user1).transferFrom(user1.address, user2.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from user2 to user3*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.connect(user2).transferFrom(user2.address, user3.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    user3Balance = await instanceVesting2.balanceOf2(200000, user3.address);

    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());
    console.log("user3VestingBalance: ", user3Balance.toString());

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/************************************user3 withdraw***************************************/");
    console.log("/*****************************************************************************************/");
    let user3TESTERC20Balance = await instanceTESTERC20.balanceOf(user3.address);
    console.log(`before withdraw user3TESTERC20Balance: ${user3TESTERC20Balance.toString()}`);

    // blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${blocktimestamp.toString()}`);

    // let vestingTESTERC20Balance = await instanceTESTERC20.balanceOf(instanceVesting2.address);
    // console.log("vestingTESTERC20Balance:", vestingTESTERC20Balance.toString());

    user3Balance = await instanceVesting2.balanceOf2(200000, user3.address);
    console.log("user3VestingBalance: ", user3Balance.toString());
    if (user3Balance > 0) {
        rel = await instanceVesting2.connect(user3).withdrawFromStream2(200000);
        user3TESTERC20Balance = await instanceTESTERC20.balanceOf(user3.address);
        console.log(`after withdraw user3TESTERC20Balance: ${user3TESTERC20Balance.toString()}`);
    }

    streamInfo = await instanceVesting2.getStream2(200000);
    console.log(`streamInfo: ${streamInfo}`);

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/***************************************sender withdraw***********************************/");
    console.log("/*****************************************************************************************/");
    ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance1.toString());
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);
    if (senderBalance > 0) {
        await instanceVesting2.senderWithdrawFromStream2(200000);
    }
    ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance2.toString());
    console.log("Remaining: ", ownerTESTERC20Balance2 - ownerTESTERC20Balance1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    // .then(() => process.exit(0))
    // .catch((error) => {
    //     console.error(error);
    //     process.exit(1);
    // });