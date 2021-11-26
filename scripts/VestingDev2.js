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
    await instanceTestNFT.mint(10);
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
    const stopTime = startTime + 20;

    console.log("/*****************************************************************************************/");
    console.log("/************************************************createStream2*****************************/");
    console.log("/*****************************************************************************************/");
    let tmpr = await instanceVesting2.createStream2(
        2000,
        instanceTESTERC20.address,
        startTime,
        stopTime,
        instanceTestNFT.address,
        [
            { tokenid: 0, share: 1000 },
            { tokenid: 1, share: 2000 },
            { tokenid: 2, share: 3000 },
            { tokenid: 3, share: 4000 },
            { tokenid: 4, share: 5000 },
            { tokenid: 5, share: 6000 },
            { tokenid: 6, share: 7000 },
            { tokenid: 7, share: 8000 },
            { tokenid: 8, share: 9000 },
            { tokenid: 9, share: 10000 },
            { tokenid: 10, share: 6000 },
            { tokenid: 11, share: 7000 },
            { tokenid: 12, share: 8000 },
            { tokenid: 13, share: 9000 },
            { tokenid: 14, share: 10000 }
        ]
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
    console.log(`streamInfo: ${streamInfo}`);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    let ownerBalance = await instanceVesting2.balanceOf2(200000, owner.address);
    let user1Balance = await instanceVesting2.balanceOf2(200000, user1.address);
    let user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("owenrVestingBalance: ", ownerBalance.toString());
    console.log("user1VestingBalance: ", user1Balance.toString());
    console.log("user2VestingBalance: ", user2Balance.toString());

    let senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderBalance: ${senderBalance.toString()}`);

    let ownerTESTERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance.toString());

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);

    await instanceVesting2.connect(owner).withdrawFromStream2(200000);
    ownerTESTERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance.toString());

    streamInfo = await instanceVesting2.getStream2(200000);
    console.log(`streamInfo: ${streamInfo}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from owner to user1*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.transferFrom(owner.address, user1.address, 0);

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

    let user1TESTERC20Balance = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1TestERC20Balance1: ", user1TESTERC20Balance.toString());

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);

    await instanceVesting2.connect(user1).withdrawFromStream2(200000);
    user1TESTERC20Balance = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1TestERC20Balance2: ", user1TESTERC20Balance.toString());

    streamInfo = await instanceVesting2.getStream2(200000);
    console.log(`streamInfo: ${streamInfo}`);

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
    console.log("/*************************withdraw user2*****************************/");
    console.log("/*****************************************************************************************/");
    let user2TESTERC20Balance = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`before withdraw user2TESTERC20Balance: ${user2TESTERC20Balance.toString()}`);

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);

    let vestingTESTERC20Balance = await instanceTESTERC20.balanceOf(instanceVesting2.address);
    console.log("vestingTESTERC20Balance:", vestingTESTERC20Balance.toString());

    user2Balance = await instanceVesting2.balanceOf2(200000, user2.address);
    console.log("user2VestingBalance: ", user2Balance.toString());
    rel = await instanceVesting2.connect(user2).withdrawFromStream2(200000);
    user2TESTERC20Balance = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`after withdraw user2TESTERC20Balance: ${user2TESTERC20Balance.toString()}`);

    streamInfo = await instanceVesting2.getStream2(200000);
    console.log(`streamInfo: ${streamInfo}`);

    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    console.log("/*****************************************************************************************/")
    console.log("/*************************sender withdraw*****************************/");
    console.log("/*****************************************************************************************/");
    senderBalance = await instanceVesting2.balanceOfSender2(200000);
    console.log(`senderVestingBalance: ${senderBalance.toString()}`);

    ownerTESTERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance1: ", ownerTESTERC20Balance.toString());
    await instanceVesting2.senderWithdrawFromStream2(200000);
    ownerTESTERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTESTERC20Balance2: ", ownerTESTERC20Balance.toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    // .then(() => process.exit(0))
    // .catch((error) => {
    //     console.error(error);
    //     process.exit(1);
    // });