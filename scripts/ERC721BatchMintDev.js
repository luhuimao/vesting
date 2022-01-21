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
    const instanceAllocation = await (await hre.ethers.getContractFactory("TokenAllocation")).connect(owner).deploy();
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
            TokenAllocation: instanceAllocation.address
        },
    });
    instanceStreamV3 = await StreamV3.connect(owner).deploy(instanceERC721BatchMint.address);
    await instanceStreamV3.connect(owner).deployed();
    console.log("StreamV3 deployed to:", instanceStreamV3.address);


    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    await instanceTESTERC20.approve(instanceStreamV3.address, approve_amount);

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(colors.magenta(`current timestamp: ${blocktimestamp.toString()}`));

    const startTime = blocktimestamp + 8;
    const stopTime = startTime + 50;

    /*****************************************************************************************/
    /**************************************create Stream***************************************/
    /*****************************************************************************************/
    console.log("##############################create Stream#################################");
    await instanceStreamV3.createStream(
        [
            hre.ethers.utils.parseEther("200000"),
            startTime,
            stopTime
        ],
        instanceTESTERC20.address,
        [
            10,
            20,
            30
        ],
        [
            hre.ethers.utils.parseEther("100"),
            hre.ethers.utils.parseEther("200"),
            hre.ethers.utils.parseEther("300")
        ]
    );


    allocInfo = await instanceStreamV3.getAllocationInfo(100000, 0);
    console.log("allocation share: ", hre.ethers.utils.formatEther(allocInfo.share));
    console.log("allocation size: ", allocInfo.size.toString());
    console.log("allocation ratePerSecond: ", hre.ethers.utils.formatEther(allocInfo.ratePerSecond));

    allocInfo = await instanceStreamV3.getAllocationInfo(100000, 200);
    console.log("allocation ratePerSecond: ", hre.ethers.utils.formatEther(allocInfo.ratePerSecond));
    console.log("allocation share: ", hre.ethers.utils.formatEther(allocInfo.share));
    console.log("allocation size: ", allocInfo.size.toString());

    allocInfo = await instanceStreamV3.getAllocationInfo(100000, 400);
    console.log("allocation ratePerSecond: ", hre.ethers.utils.formatEther(allocInfo.ratePerSecond));
    console.log("allocation share: ", hre.ethers.utils.formatEther(allocInfo.share));
    console.log("allocation size: ", allocInfo.size.toString());

    /*****************************************************************************************/
    /********************************user1 mint Batch By StreamId********************************/
    /*****************************************************************************************/
    console.log("##############################user1 mint Batch By StreamId#################################");

    await instanceERC721BatchMint.mintBatchByStreamId(instanceStreamV3.address, 100000, 0, user1.address);

    tokenBalance = await instanceERC721BatchMint.balanceOf(user1.address);
    console.log("tokenBalance: ", tokenBalance.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user1.address, 0)
    console.log("tokenId of index 0: ", tokenId.toString());


    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user1.address, 9)
    console.log("tokenId of index 9: ", tokenId.toString());

    let totalMinted = await instanceERC721BatchMint.totalSupply();
    console.log("totalMinted: ", totalMinted.toString());


    /*****************************************************************************************/
    /********************************add New Edition********************************/
    /*****************************************************************************************/
    console.log("##############################add New Edition#################################");

    await instanceStreamV3.addNewEdition(
        100000,
        hre.ethers.utils.parseEther("500000"),
        [
            100,
            200
        ],
        [
            hre.ethers.utils.parseEther("1000"),
            hre.ethers.utils.parseEther("2000")
        ]);


    allocInfo = await instanceStreamV3.getAllocationInfo(100000, 600);
    console.log("allocation share: ", hre.ethers.utils.formatEther(allocInfo.share));
    console.log("allocation size: ", allocInfo.size.toString());
    console.log("allocation ratePerSecond: ", hre.ethers.utils.formatEther(allocInfo.ratePerSecond));

    allocInfo = await instanceStreamV3.getAllocationInfo(100000, 800);
    console.log("allocation ratePerSecond: ", hre.ethers.utils.formatEther(allocInfo.ratePerSecond));
    console.log("allocation share: ", hre.ethers.utils.formatEther(allocInfo.share));
    console.log("allocation size: ", allocInfo.size.toString());


    let allocations = await instanceStreamV3.getAllAllocations(100000);
    console.log("stream allocations: ", allocations);

    /*****************************************************************************************/
    /********************************user2 mint Batch By StreamId********************************/
    /*****************************************************************************************/
    console.log("##############################user2 mint Batch By StreamId#################################");
    await instanceERC721BatchMint.mintBatchByStreamId(instanceStreamV3.address, 100000, 200, user2.address);
    tokenBalance = await instanceERC721BatchMint.balanceOf(user2.address);
    console.log("tokenBalance of user2: ", tokenBalance.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user2.address, 0)
    console.log("user2 tokenId of index 0: ", tokenId.toString());

    tokenId = await instanceERC721BatchMint.tokenOfOwnerByIndex(user2.address, 19)
    console.log("user2 tokenId of index 19: ", tokenId.toString());


    /*****************************************************************************************/
    /*****************************************revoke******************************************/
    /*****************************************************************************************/
    console.log("##############################revoke#################################");
    ownerERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log(`Owner TestERC20 Balance before revoke: ${hre.ethers.utils.formatEther(ownerERC20Balance.toString())}`);

    let streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance before revoke: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    await instanceStreamV3.revokeStream(100000, 600, 50);
    console.log("nfts 600-649 revoked........................");

    ownerERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log(`Owner TestERC20 Balance after revoke: ${hre.ethers.utils.formatEther(ownerERC20Balance.toString())}`);
    // let allocInfo = await instanceStreamV3.getAllocationInfo(100000, 0);
    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance after revoke: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    let revoked = await instanceStreamV3.checkIfRevoked(100000, 600);
    console.log("token #600 revoked:", revoked);
    revoked = await instanceStreamV3.checkIfRevoked(100000, 699);
    console.log("token #699 revoked:", revoked);

    console.log("mint token #650......");
    await instanceERC721BatchMint.mint(650, owner.address);
    console.log("token #650 minted.....");

    await instanceStreamV3.revokeStream(100000, 600, 49);
    console.log("nfts 651-699 revoked........................");

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance after second revoke: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    revoked = await instanceStreamV3.checkIfRevoked(100000, 650);
    console.log("token #650 revoked:", revoked);

    revoked = await instanceStreamV3.checkIfRevoked(100000, 651);
    console.log("token #651 revoked:", revoked);

    revoked = await instanceStreamV3.checkIfRevoked(100000, 699);
    console.log("token #699 revoked:", revoked);
    ownerERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log(`Owner TestERC20 Balance after second revoke: ${hre.ethers.utils.formatEther(ownerERC20Balance.toString())}`);

    console.log("mint token #699......");
    await instanceERC721BatchMint.mint(699, owner.address);
    console.log("token #699 minted.....");
    let tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 699);
    console.log("token #699 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    let tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 699);
    console.log("token #699 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));
    /*****************************************************************************************/
    /*****************************************token #0 balance********************************/
    /*****************************************************************************************/
    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(colors.magenta(`current timestamp: ${blocktimestamp.toString()}`));
    tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 0);
    console.log("token #0 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 0);
    console.log("token #0 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));


    /*****************************************************************************************/
    /*****************************************token #200 balance********************************/
    /*****************************************************************************************/
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 200);
    console.log("token #200 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 200);
    console.log("token #200 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));

    /*****************************************************************************************/
    /*****************************************token withdraw**********************************/
    /*****************************************************************************************/
    console.log("##############################token withdraw#################################");
    let user1ERC20Balace = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 ERC20 Balace: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));
    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user1 withdraw token #0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    user1ERC20Balace = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 ERC20 Balace before withdraw: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));

    await instanceStreamV3.connect(user1).withdrawFromStreamByTokenId(100000, 0);
    user1ERC20Balace = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 ERC20 Balace after withdraw: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user1 withdraw all~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    user1ERC20Balace = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 ERC20 Balace before withdraw: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));

    await instanceStreamV3.connect(user1).withdrawAllFromStream(100000, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    user1ERC20Balace = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 ERC20 Balace after withdraw: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20Balace: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));
    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user2 withdraw token #200~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balace before withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    await instanceStreamV3.connect(user2).withdrawFromStreamByTokenId(100000, 200);
    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balace after withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));

    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user2 withdraw all~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balace before withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    await instanceStreamV3.connect(user2).withdrawAllFromStream(100000, [
        200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210,
        211, 212, 213, 214, 215, 216, 217, 218, 219, 209, 210
    ]);
    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balace after withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));


    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(colors.magenta(`current timestamp: ${blocktimestamp.toString()}`));


    /*****************************************************************************************/
    /******************transfer token #0 from user1 to user2**********************************/
    /*****************************************************************************************/
    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~transfer token #0 to user2~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));

    await instanceERC721BatchMint.connect(user1).transferFrom(user1.address, user2.address, 0);

    tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 0);
    console.log("token #0 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 0);
    console.log("token #0 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));

    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user2 withdraw token #0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balance before withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    await instanceStreamV3.connect(user2).withdrawFromStreamByTokenId(100000, 0);

    user2ERC20Balace = await instanceTESTERC20.balanceOf(user2.address);
    console.log("user2 ERC20 Balance after withdraw: ", hre.ethers.utils.formatEther(user2ERC20Balace.toString()));

    tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 0);
    console.log("token #0 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 0);
    console.log("token #0 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));

    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));


    /*****************************************************************************************/
    /*******************************sender withdraw******************************************/
    /*****************************************************************************************/
    for (var i = 0; i < 30; i++) {
        await instanceTESTERC20.transfer(user1.address, 1);
        await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    }

    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(colors.magenta(`current timestamp: ${blocktimestamp.toString()}`));

    ownerERC20Balace = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner ERC20Balace: ", hre.ethers.utils.formatEther(ownerERC20Balace.toString()));
    console.log(colors.green(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sender withdraw~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`));
    await instanceStreamV3.senderWithdrawFromStream(100000);
    ownerERC20Balace = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner ERC20Balace: ", hre.ethers.utils.formatEther(ownerERC20Balace.toString()));
    streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });