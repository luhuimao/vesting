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
    console.log('owner addr: ', owner.toString());
    var blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;

    var blockGaslimit = blockGaslimit0.div(4);
    // We get the contract to deploy
    // const Greeter = await hre.ethers.getContractFactory("Greeter");
    // const greeter = await Greeter.deploy("Hello, Hardhat!");

    // await greeter.deployed();

    // console.log("Greeter deployed to:", greeter.address);
    // let instanceBoredApeYachtClub: ConfigAddress;

    const TestNFT = await hre.ethers.getContractFactory("TestNFT");
    instanceTestNFT = await TestNFT.connect(owner).deploy('TEST ERC721', 'TE721');

    // instanceConfigAddress = BoredApeYachtClub.connect(owner).attach(tmpaddr) as ConfigAddress;
    await instanceTestNFT.connect(owner).deployed();
    console.log("ERC721 deployed to:", instanceTestNFT.address);

    let flag = '\\/\\/REPLACE_FLAG';
    let key = 'NFT_ADDRESS_' + network.name.toUpperCase();
    ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceTestNFT.address + '"; ' + flag);
    key = 'DEPLOY_ACCOUNT_' + network.name.toUpperCase();
    ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + owner.address + '"; ' + flag);

    const ownerBalance1 = await instanceTestNFT.balanceOf(owner.address);
    console.log("ownerBalance1: ", ownerBalance1.toString());

    await instanceTestNFT.mint(10);

    let ownerBalance2 = await instanceTestNFT.balanceOf(owner.address);
    console.log("ownerBalance2: ", ownerBalance2.toString());
    const nftOwner = await instanceTestNFT.ownerOf(0);
    console.log("nftOwner1: ", nftOwner.toString());

    var ownerOwnedTimeStamp = await instanceTestNFT.getHistoriesOwnedTimeStamp(0, owner.address);
    console.log(`NFT #0 transferred to owner: ${owner.address}  startOwneredTimeStamp: ${ownerOwnedTimeStamp.startOwneredTimeStamp.toString()} endOwneredTimeStamp: ${ownerOwnedTimeStamp.endOwneredTimeStamp.toString()}`);

    let transferredCount = await instanceTestNFT.totalTransferredCount(0);
    console.log(`Token #0 Transferred Times: ${transferredCount}`);

    const user1Balance1 = await instanceTestNFT.balanceOf(user1.address);
    console.log("user1Balance1: ", user1Balance1.toString());


    console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ transfer token #0 from owner to user1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    await instanceTestNFT.transferFrom(owner.address, user1.address, 0)

    transferredCount = await instanceTestNFT.totalTransferredCount(0);
    console.log(`Token #0 Transferred Times: ${transferredCount}`);

    var user1OwnedTimeStamp = await instanceTestNFT.getHistoriesOwnedTimeStamp(0, user1.address);
    console.log(`NFT #0 transferred to user1: ${user1.address}  startOwneredTimeStamp: ${user1OwnedTimeStamp.startOwneredTimeStamp.toString()} endOwneredTimeStamp: ${user1OwnedTimeStamp.endOwneredTimeStamp.toString()}`);


    ownerOwnedTimeStamp = await instanceTestNFT.getHistoriesOwnedTimeStamp(0, owner.address);
    console.log(`NFT #0 transferred to owner: ${owner.address}  startOwneredTimeStamp: ${ownerOwnedTimeStamp.startOwneredTimeStamp.toString()} endOwneredTimeStamp: ${ownerOwnedTimeStamp.endOwneredTimeStamp.toString()}`);


    let user1Balance2 = await instanceTestNFT.balanceOf(user1.address);
    console.log("user1Balance2: ", user1Balance2.toString());

    const nftOwner1 = await instanceTestNFT.ownerOf(0);
    console.log("nftOwner1: ", nftOwner1.toString());

    ownerBalance2 = await instanceTestNFT.balanceOf(owner.address);
    for (i = 0; i < parseInt(ownerBalance2); i++) {
        const ownerofNFT = await instanceTestNFT.tokenOfOwnerByIndex(owner.address, i);
        console.log("Index Of Balance: ", i, " --> NFT ID: ", ownerofNFT.toString());
    }

    for (i = 0; i < parseInt(user1Balance2); i++) {
        const ownerofNFT = await instanceTestNFT.tokenOfOwnerByIndex(user1.address, i);
        console.log("Index Of Balance: ", i, " --> NFT ID: ", ownerofNFT.toString());
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });