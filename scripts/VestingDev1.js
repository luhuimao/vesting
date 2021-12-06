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
    let [owner, user1, user2] = await hre.ethers.getSigners();
    console.log('owner addr: ', owner.address.toString());
    var blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;

    var blockGaslimit = blockGaslimit0.div(4);
    // We get the contract to deploy

    /*****************************************************************************************/
    /*******************************Deploy Vesting1******************************************/
    /*****************************************************************************************/
    const Vesting1 = await hre.ethers.getContractFactory("Vesting1");
    instanceVesting1 = await Vesting1.connect(owner).deploy();
    // instanceConfigAddress = BoredApeYachtClub.connect(owner).attach(tmpaddr) as ConfigAddress;
    await instanceVesting1.connect(owner).deployed();
    console.log("Vesting1 deployed to:", instanceVesting1.address);

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
    await instanceTestNFT.mint(100);
    let ownerERC721Balance = await instanceTestNFT.balanceOf(owner.address);
    console.log("ownerERC721Balance: ", ownerERC721Balance.toString());

    let ownerTestERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTestERC20Balance: ", ownerTestERC20Balance.toString());
    // nftOwner1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    await instanceTESTERC20.approve(instanceVesting1.address, approve_amount);

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 1;
    const stopTime = startTime + 20;

    console.log("/*****************************************************************************************/");
    console.log("/************************************************createStream*****************************/");
    console.log("/*****************************************************************************************/");
    let tmpr = await instanceVesting1.createStream(
        20000,
        instanceTESTERC20.address,
        startTime,
        stopTime,
        instanceTestNFT.address
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

    let streamInfo = await instanceVesting1.getStream(100000);
    console.log(`streamInfo.deposit: ${streamInfo.deposit}`);
    console.log(`streamInfo.remainingBalance: ${streamInfo.remainingBalance}`);
    console.log(`streamInfo.ratePerSecond: ${streamInfo.ratePerSecond}`);
    console.log(`streamInfo.nftTotalSupply: ${streamInfo.nftTotalSupply}`);


    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    let ownerBalance = await instanceVesting1.balanceOf(100000, owner.address);
    let user1Balance = await instanceVesting1.balanceOf(100000, user1.address);
    let user2Balance = await instanceVesting1.balanceOf(100000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    let senderBalance = await instanceVesting1.balanceOfSender(100000);
    console.log(`senderBalance: ${senderBalance}`);

    let ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance1.toString());

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp}`);

    console.log('///////////////////////////////////////owner withdraw///////////////////////////////////////////////');
    await instanceVesting1.connect(owner).withdrawFromStream(100000);
    ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance2.toString());

    console.log("owner withdraw amount: ", ownerTESTERC20Balance2 - ownerTESTERC20Balance1);
    streamInfo = await instanceVesting1.getStream(100000);
    console.log(`streamInfo.remainingBalance: ${streamInfo.remainingBalance}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from owner to user1*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.transferFrom(owner.address, user1.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    ownerBalance = await instanceVesting1.balanceOf(100000, owner.address);
    user1Balance = await instanceVesting1.balanceOf(100000, user1.address);
    user2Balance = await instanceVesting1.balanceOf(100000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    let user1TestERC20Balance1 = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1TestERC20Balance1: ", user1TestERC20Balance1.toString());

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);

    console.log('///////////////////////////////////////user1 withdraw///////////////////////////////////////////////');
    await instanceVesting1.connect(user1).withdrawFromStream(100000);
    user1TestERC20Balance2 = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1TestERC20Balance2: ", user1TestERC20Balance2.toString());
    console.log("use1 withdraw amount: ", user1TestERC20Balance2 - user1TestERC20Balance1);

    senderBalance = await instanceVesting1.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    streamInfo = await instanceVesting1.getStream(100000);
    console.log(`streamInfo.remainingBalance: ${streamInfo.remainingBalance}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from user1 to user2*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.connect(user1).transferFrom(user1.address, user2.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    ownerBalance = await instanceVesting1.balanceOf(100000, owner.address);
    user1Balance = await instanceVesting1.balanceOf(100000, user1.address);
    user2Balance = await instanceVesting1.balanceOf(100000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    senderBalance = await instanceVesting1.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************withdraw user2*****************************/");
    console.log("/*****************************************************************************************/");
    let user2TESTERC20Balance1 = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`before withdraw user2TESTERC20Balance: ${user2TESTERC20Balance1.toString()}`);
    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);

    console.log('///////////////////////////////////////user2 withdraw///////////////////////////////////////////////');
    rel = await instanceVesting1.connect(user2).withdrawFromStream(100000);
    user2TESTERC20Balance2 = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`after withdraw user2TESTERC20Balance: ${user2TESTERC20Balance2.toString()}`);
    console.log("user2 withdraw amount: ", user2TESTERC20Balance2 - user2TESTERC20Balance1);

    senderBalance = await instanceVesting1.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    streamInfo = await instanceVesting1.getStream(100000);
    console.log(`streamInfo.remainingBalance: ${streamInfo.remainingBalance}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************sender withdraw*****************************/");
    console.log("/*****************************************************************************************/");
    senderBalance = await instanceVesting1.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance1.toString());
    await instanceVesting1.senderWithdrawFromStream(100000);
    ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance2.toString());
    console.log("sender withdraw amount: ", ownerTESTERC20Balance2 - ownerTESTERC20Balance1);

    streamInfo = await instanceVesting1.getStream(100000);
    console.log(`streamInfo.remainingBalance: ${streamInfo.remainingBalance}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    // .then(() => process.exit(0))
    // .catch((error) => {
    //     console.error(error);
    //     process.exit(1);
    // });