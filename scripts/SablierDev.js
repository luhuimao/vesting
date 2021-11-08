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
    /*******************************Deploy Sablier******************************************/
    /*****************************************************************************************/
    const Sablier = await hre.ethers.getContractFactory("Sablier");
    instanceSablier = await Sablier.connect(owner).deploy();
    // instanceConfigAddress = BoredApeYachtClub.connect(owner).attach(tmpaddr) as ConfigAddress;
    await instanceSablier.connect(owner).deployed();
    console.log("Sablier deployed to:", instanceSablier.address);

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
    instanceTestNFT = await TestNFT.connect(owner).deploy('TEST ERC721', 'TE721');
    await instanceTestNFT.connect(owner).deployed();
    console.log("ERC721 deployed to:", instanceTestNFT.address);

    /*****************************************************************************************/
    /*******************************mint 10 ERC721 Token To owner*****************************/
    /*****************************************************************************************/
    await instanceTestNFT.mint(10);
    let ownerERC721Balance = await instanceTestNFT.balanceOf(owner.address);
    console.log("ownerERC721Balance: ", ownerERC721Balance.toString());

    let flag = '\\/\\/REPLACE_FLAG';
    let key = 'NFT_ADDRESS_' + network.name.toUpperCase();
    ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceSablier.address + '"; ' + flag);
    key = 'DEPLOY_ACCOUNT_' + network.name.toUpperCase();
    ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + owner.address + '"; ' + flag);

    const ownerTestERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTestERC20Balance: ", ownerTestERC20Balance.toString());
    nftOwner1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    await instanceTESTERC20.approve(instanceSablier.address, 1000);

    const blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    const startTime = blocktimestamp + 1;
    const stopTime = startTime + 1000;

    console.log("/*****************************************************************************************/");
    console.log("/************************************************createStream*****************************/");
    console.log("/*****************************************************************************************/");
    let tmpr = await instanceSablier.createStream(
        1000,
        instanceTESTERC20.address,
        startTime,
        stopTime,
        instanceTestNFT.address,
        0
    );

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    var rel = await tmpr.wait(1);
    // console.log("rel: ", rel);

    const streamInfo = await instanceSablier.getStream(100000);
    console.log(`streamInfo: ${streamInfo}`);

    var historiesOwners = await instanceSablier.getERC721HistoriesOwners(100000);
    console.log(`historiesOwners: ${historiesOwners}`);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    let user1Balance = await instanceSablier.balanceOf(100000, user1.address);
    let user2Balance = await instanceSablier.balanceOf(100000, user2.address);
    console.log("user1Balance: ", user1Balance.toString());
    console.log("user2Balance: ", user2Balance.toString());

    // var myFunc01 = function () {
    //     var i = 0;
    //     while (i < 5) {
    //         (function (i) {
    //             setTimeout(async () => {
    //                 await instanceTESTERC20.transfer(user1.address, 1);
    //                 await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    //                 // const senderBalance = await instanceSablier.balanceOf(100000, owner.address);
    //                 const user1Balance = await instanceSablier.balanceOf(100000, user1.address);
    //                 const user2Balance = await instanceSablier.balanceOf(100000, user2.address);

    //                 // console.log("senderBalance: ", senderBalance.toString());
    //                 console.log("user1Balance: ", user1Balance.toString());
    //                 console.log("user2Balance: ", user2Balance.toString());

    //             }, 1000 * i)
    //         })(i++)
    //     }
    // };
    // myFunc01();

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from owner to user1*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.transferFrom(owner.address, user1.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);


    user1Balance = await instanceSablier.balanceOf(100000, user1.address);
    user2Balance = await instanceSablier.balanceOf(100000, user2.address);
    console.log("user1Balance: ", user1Balance.toString());
    console.log("user2Balance: ", user2Balance.toString());


    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer NFT #0 from user1 to user2*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT.connect(user1).transferFrom(user1.address, user2.address, 0);

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    user1Balance = await instanceSablier.balanceOf(100000, user1.address);
    user2Balance = await instanceSablier.balanceOf(100000, user2.address);
    console.log("user1Balance: ", user1Balance.toString());
    console.log("user2Balance: ", user2Balance.toString());


    console.log("/*****************************************************************************************/")
    console.log("/*************************withdraw user1*****************************/");
    console.log("/*****************************************************************************************/");
    let user1TESTERC20Balance = await instanceTESTERC20.balanceOf(user1.address);
    console.log(`before withdraw user1TESTERC20Balance: ${user1TESTERC20Balance.toString()}`);
    rel = await instanceSablier.connect(user1).withdrawFromStream(100000, user1Balance);
    user1TESTERC20Balance = await instanceTESTERC20.balanceOf(user1.address);
    console.log(`after withdraw user1TESTERC20Balance: ${user1TESTERC20Balance.toString()}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    // .then(() => process.exit(0))
    // .catch((error) => {
    //     console.error(error);
    //     process.exit(1);
    // });