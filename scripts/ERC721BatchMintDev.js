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
const colors = require('colors/safe');

async function main() {


    let [owner, user1, user2] = await hre.ethers.getSigners();
    console.log('owner addr: ', owner.address);
    var blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;

    var blockGaslimit = blockGaslimit0.div(4);
    // We get the contract to deploy

    /*****************************************************************************************/
    /*******************************Deploy ERC721BatchMint******************************************/
    /*****************************************************************************************/
    const ERC721BatchMint = await hre.ethers.getContractFactory("ERC721BatchMint");
    instanceERC721BatchMint = await ERC721BatchMint.connect(owner).deploy('TEST ERC721', 'TE721');
    await instanceERC721BatchMint.connect(owner).deployed();
    console.log("ERC721BatchMint deployed to:", instanceERC721BatchMint.address);

    /*****************************************************************************************/
    /*******************************Deploy Libraries******************************************/
    /*****************************************************************************************/
    const instanceAllocation = await (await hre.ethers.getContractFactory("Allocation")).connect(owner).deploy();
    console.log('new Allocation address:', instanceAllocation.address);
    const instanceStreamLibV3 = await (await hre.ethers.getContractFactory("StreamLibV3")).connect(owner).deploy();
    console.log('new StreamLibV3 address:', instanceStreamLibV3.address);

    /*****************************************************************************************/
    /*******************************Deploy TestERC20******************************************/
    /*****************************************************************************************/
    const TestERC20 = await hre.ethers.getContractFactory("ERC20PresetFixedSupply");
    instanceTESTERC20 = await TestERC20.connect(owner).deploy("TEST TOKEN", "TT", hre.ethers.utils.parseEther('100000000000000000'), owner.address);
    await instanceTESTERC20.connect(owner).deployed();
    let ownerERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("TestERC20 deployed to:", instanceTESTERC20.address);
    console.log(`Owner TestERC20 Balance: ${hre.ethers.utils.formatEther(ownerERC20Balance.toString())}`);


    /*****************************************************************************************/
    /*******************************Deploy StreamV3******************************************/
    /*****************************************************************************************/
    const StreamV3 = await hre.ethers.getContractFactory("StreamV3", {
        libraries: {
            // StreamLibV3: instanceStreamV3.address,
            Allocation: instanceAllocation.address
        },
    });
    instanceStreamV3 = await StreamV3.connect(owner).deploy(instanceERC721BatchMint.address);
    await instanceStreamV3.connect(owner).deployed();
    console.log("StreamV3 deployed to:", instanceStreamV3.address);


    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    await instanceTESTERC20.approve(instanceStreamV3.address, approve_amount);

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 1;
    const stopTime = startTime + 40;

    console.log("/*****************************************************************************************/");
    console.log("/**************************************createStream***************************************/");
    console.log("/*****************************************************************************************/");
    await instanceStreamV3.createStream(
        [
            hre.ethers.utils.parseEther("200000"),
            startTime,
            stopTime
        ],
        instanceTESTERC20.address,
        [10, 20, 30],
        [hre.ethers.utils.parseEther("100"), hre.ethers.utils.parseEther("200"), hre.ethers.utils.parseEther("300")]
    );


    console.log("/*****************************************************************************************/");
    console.log("/**************************************mintBatch NFT***************************************/");
    console.log("/*****************************************************************************************/");
    await instanceERC721BatchMint.mintBatch(10, 10, owner.address);
    let tokenBalance = await instanceERC721BatchMint.balanceOf(owner.address);
    console.log("tokenBalance: ", tokenBalance.toString());

    // await instanceERC721BatchMint.mint(owner.address);
    // tokenBalance = await instanceERC721BatchMint.balanceOf(owner.address);
    // console.log("tokenBalance: ", tokenBalance.toString());


    let tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 0)
    console.log("tokenId of index 0: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 1)
    console.log("tokenId of index 1: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 2)
    console.log("tokenId of index 2: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 3)
    console.log("tokenId of index 3: ", tokenId.toString());


    tokenId = await instanceERC721BatchMint.tokenByIndex(2);
    console.log("tokenId of index 2: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(3);
    console.log("tokenId of index 3: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(4);
    console.log("tokenId of index 4: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(5);
    console.log("tokenId of index 5: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(6);
    console.log("tokenId of index 6: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(7);
    console.log("tokenId of index 7: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(8);
    console.log("tokenId of index 8: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenByIndex(9);
    console.log("tokenId of index 9: ", tokenId.toString());

    console.log("/*****************************************************************************************/");
    console.log("/**************************************mintBatchByStreamId********************************/");
    console.log("/*****************************************************************************************/");
    await instanceERC721BatchMint.mintBatchByStreamId(instanceStreamV3.address, 100000, 0, owner.address);

    tokenBalance = await instanceERC721BatchMint.balanceOf(owner.address);
    console.log("tokenBalance: ", tokenBalance.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 0)
    console.log("tokenId of index 0: ", tokenId.toString());


    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(owner.address, 9)
    console.log("tokenId of index 9: ", tokenId.toString());

    let totalMinted = await instanceERC721BatchMint.totalSupply();
    console.log("totalMinted: ", totalMinted.toString());

    await instanceERC721BatchMint.mintBatchByStreamId(instanceStreamV3.address,100000, 200, user1.address);
    tokenBalance = await instanceERC721BatchMint.balanceOf(user1.address);
    console.log("tokenBalance of user1: ", tokenBalance.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user1.address, 0)
    console.log("user1 tokenId of index 0: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user1.address, 19)
    console.log("user1 tokenId of index 19: ", tokenId.toString());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });