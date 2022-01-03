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
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');
    // let owner = new hre.ethers.Wallet('af43652256977c85d2e39d57258ed7a5a774c41ccc02c8c6fc8f709d316ddc55', ethers.provider);
    let [owner, user1, user2] = await hre.ethers.getSigners();
    console.log('owner addr: ', owner.address.toString());
    console.log('user1 addr: ', user1.address.toString());
    console.log('user2 addr: ', user2.address.toString());
    var blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;

    var blockGaslimit = blockGaslimit0.div(4);
    // We get the contract to deploy

    /*****************************************************************************************/
    /*******************************Deploy TestNFT1******************************************/
    /*****************************************************************************************/
    const TestNFT = await hre.ethers.getContractFactory("ERC721Stream1V2");
    instanceTestNFT1 = await TestNFT.connect(owner).deploy('TEST ERC721 1', 'TT1');
    await instanceTestNFT1.connect(owner).deployed();
    console.log("TestNFT1 deployed to:", instanceTestNFT1.address);


    /*****************************************************************************************/
    /*******************************Deploy TestNFT2******************************************/
    /*****************************************************************************************/
    instanceTestNFT2 = await TestNFT.connect(owner).deploy('TEST ERC721 2', 'TT2');
    await instanceTestNFT2.connect(owner).deployed();
    console.log("TestNFT2 deployed to:", instanceTestNFT2.address);

    /*****************************************************************************************/
    /*******************************Deploy TestNFT3******************************************/
    /*****************************************************************************************/
    instanceTestNFT3 = await TestNFT.connect(owner).deploy('TEST ERC721 3', 'TT3');
    await instanceTestNFT3.connect(owner).deployed();
    console.log("TestNFT3 deployed to:", instanceTestNFT3.address);

    /*****************************************************************************************/
    /*******************************Deploy Stream1LibV2******************************************/
    /*****************************************************************************************/
    const instanceStream1LibV2 = await (await hre.ethers.getContractFactory("Stream1LibV2")).connect(owner).deploy();
    console.log('new Stream1LibV2 address:', instanceStream1LibV2.address);

    /*****************************************************************************************/
    /*******************************Deploy Stream1MultiNFTV2******************************************/
    /*****************************************************************************************/
    const Stream1MultiNFTV2 = await hre.ethers.getContractFactory("Stream1MultiNFTV2", {
        libraries: { Stream1LibV2: instanceStream1LibV2.address },
    });
    instanceStream1MultiNFTV2 = await Stream1MultiNFTV2.connect(owner).deploy(instanceTestNFT1.address);
    // instanceConfigAddress = BoredApeYachtClub.connect(owner).attach(tmpaddr) as ConfigAddress;
    await instanceStream1MultiNFTV2.connect(owner).deployed();
    console.log("Stream1MultiNFTV2 deployed to:", instanceStream1MultiNFTV2.address);

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
    /*******************************mint 100 TestNFT1 To owner*****************************/
    /*****************************************************************************************/
    // await instanceTestNFT1.mint(100, owner.address);
    // ownerERC721Balance = await instanceTestNFT1.balanceOf(owner.address);
    // console.log("owner TestNFT1 Balance: ", ownerERC721Balance.toString());

    /*****************************************************************************************/
    /*******************************mint 100 TestNFT2 To owner*****************************/
    /*****************************************************************************************/
    // await instanceTestNFT2.mint(100);
    // ownerERC721Balance = await instanceTestNFT2.balanceOf(owner.address);
    // console.log("owner TestNFT2 Balance: ", ownerERC721Balance.toString());


    /*****************************************************************************************/
    /*******************************mint 100 TestNFT3 To owner*****************************/
    /*****************************************************************************************/
    // await instanceTestNFT3.mint(100);
    // ownerERC721Balance = await instanceTestNFT3.balanceOf(owner.address);
    // console.log("owner TestNFT3 Balance: ", ownerERC721Balance.toString());

    let ownerTestERC20Balance = await instanceTESTERC20.balanceOf(owner.address);
    console.log("ownerTestERC20Balance: ", hre.ethers.utils.formatEther(ownerTestERC20Balance.toString()));

    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    await instanceTESTERC20.approve(instanceStream1MultiNFTV2.address, approve_amount);

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 1;
    const stopTime = startTime + 40;

    console.log("/*****************************************************************************************/");
    console.log("/**************************************createStream1***************************************/");
    console.log("/*****************************************************************************************/");
    let tmpr = await instanceStream1MultiNFTV2.createMultiNFTStream(
        [
            hre.ethers.utils.parseEther("200000"),
            startTime,
            stopTime
            // hre.ethers.utils.parseEther("100"),
            // 10
        ],
        instanceTESTERC20.address,
        [10, 20, 30],
        [hre.ethers.utils.parseEther("100"), hre.ethers.utils.parseEther("200"), hre.ethers.utils.parseEther("300")]
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

    ownerERC721Balance = await instanceTestNFT1.balanceOf(owner.address);
    console.log("owner TestNFT1 Balance: ", ownerERC721Balance.toString());

    user1ERC721Balance = await instanceTestNFT1.balanceOf(user1.address);
    console.log("user1 TestNFT1 Balance: ", user1ERC721Balance.toString());

    user2ERC721Balance = await instanceTestNFT1.balanceOf(user2.address);
    console.log("user2 TestNFT1 Balance: ", user2ERC721Balance.toString());

    let streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    const initStreamRemainingBalance = streamInfo.remainingBalance;
    console.log(`streamInfo.deposit: ${hre.ethers.utils.formatEther(streamInfo.deposit)}`);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)}`);
    console.log(`streamInfo.sender: ${streamInfo.sender}`);
    console.log(`streamInfo.tokenAddress: ${streamInfo.tokenAddress}`);
    console.log(`streamInfo.startTime: ${streamInfo.startTime}`);
    console.log(`streamInfo.stopTime: ${streamInfo.stopTime}`);

    const tokenIds = await instanceStream1MultiNFTV2.getStreamSupportedTokenIds(100000);
    console.log("supported tokenIds of TestNFT1 amount: ", tokenIds.length)


    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    const delta = await instanceStream1MultiNFTV2.deltaOf(100000);
    console.log("delta: ", delta.toString());

    let token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(`TestNFT1 token0 available Balance: ${hre.ethers.utils.formatEther(token0Balance)}`);

    let token0RemainingBalance = await instanceStream1MultiNFTV2.remainingBalanceByTokenId(100000, 0);
    console.log(`TestNFT1 token0 remaning Balance: ${hre.ethers.utils.formatEther(token0RemainingBalance)}`);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        owner.address,
        [
            1, 2, 7, 8, 9, 0, 3, 4, 5, 6,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );

    let ownerBalance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000, owner.address);


    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user1.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    let user1Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000, user1.address);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user2.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );

    let user2Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000, user2.address);

    console.log(`owenr all VestingBalance: ${hre.ethers.utils.formatEther(ownerBalance)}`);
    console.log("user1 all VestingBalance: ", hre.ethers.utils.formatEther(user1Balance.toString()));
    console.log("user2 all VestingBalance: ", hre.ethers.utils.formatEther(user2Balance.toString()));

    let senderBalance = await instanceStream1MultiNFTV2.balanceOfSender(100000);
    console.log(`sender Balance: ${hre.ethers.utils.formatEther(senderBalance)}`);

    let ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner TESTERC20 Balance1: ", hre.ethers.utils.formatEther(ownerTESTERC20Balance1.toString()));

    // blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${blocktimestamp}`);


    console.log('///////////////////////////////////////owner withdraw TestNFT1 tokenid #0///////////////////////////////////////////////');
    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(`TestNFT1 token0 available Balance: ${hre.ethers.utils.formatEther(token0Balance)}`);
    token0RemainingBalance1 = await instanceStream1MultiNFTV2.remainingBalanceByTokenId(100000, 0);
    console.log(`TestNFT1 token0 Remaining Balance1: ${hre.ethers.utils.formatEther(token0RemainingBalance1)}`);
    streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)}`);

    ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log(`owner test token balance1: ${hre.ethers.utils.formatEther(ownerTESTERC20Balance1)}`);

    console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~owner withdraw TestNFT1 tokenid #0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp}`);

    console.log(`duration: ${blocktimestamp - startTime}`);
    let tokenRatePerSec = await instanceStream1MultiNFTV2.getTokenRatePerSec(100000, 0);
    console.log(`expected token0 withdrawable balance: ${hre.ethers.utils.formatEther(
        (hre.ethers.BigNumber.from(blocktimestamp).sub(hre.ethers.BigNumber.from(startTime)))
            .mul(hre.ethers.BigNumber.from(tokenRatePerSec))
    )
        } `);
    await instanceStream1MultiNFTV2.connect(owner).withdrawFromStreamByTokenId(100000, 0);
    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(`TestNFT1 token0 available Balance: ${hre.ethers.utils.formatEther(token0Balance)} `);
    let token0RemainingBalance2 = await instanceStream1MultiNFTV2.remainingBalanceByTokenId(100000, 0);
    console.log(`TestNFT1 token0 Remaining Balance2: ${hre.ethers.utils.formatEther(token0RemainingBalance2)} `);

    let ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log(`owner test token balance2: ${hre.ethers.utils.formatEther(ownerTESTERC20Balance2)} `);
    // let withdrawAmount = ownerTESTERC20Balance2 - ownerTESTERC20Balance1;

    ownerTestTokenChanged = hre.ethers.BigNumber.from(ownerTESTERC20Balance2).sub(hre.ethers.BigNumber.from(ownerTESTERC20Balance1))
    console.log(colors.magenta(`owner TestToken Changed: ${hre.ethers.utils.formatEther(ownerTestTokenChanged.toString())} `));
    // console.log(`owner withdrawAmount: ${ hre.ethers.utils.formatEther(withdrawAmount.toString()) } `);

    let token0WithdrawAmount = hre.ethers.BigNumber.from(token0RemainingBalance1).sub(hre.ethers.BigNumber.from(token0RemainingBalance2));
    console.log(colors.magenta(`token0 RemainingBalance changed: ${hre.ethers.utils.formatEther(token0WithdrawAmount.toString())} `));

    streamInfo2 = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    let streamRemainingBalance = streamInfo2.remainingBalance;
    // console.log(`streamInfo.remainingBalance: ${ hre.ethers.utils.formatEther(streamRemainingBalance) } `);
    // console.log(`streamInfo.initStreamRemainingBalance: ${ hre.ethers.utils.formatEther(initStreamRemainingBalance) } `);
    console.log(colors.magenta(
        `stream remainingBalance changed:${hre.ethers.utils.formatEther((
            hre.ethers.BigNumber.from(initStreamRemainingBalance).sub(hre.ethers.BigNumber.from(streamRemainingBalance))
        ).toString())} `
    ));
    // if (withdrawAmount != token0WithdrawAmount || token0WithdrawAmount != (initStreamRemainingBalance - streamRemainingBalance)) {
    //     console.error("owner withdraw token0 failed");
    //     return;
    // }

    blocktimestamp1 = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp1} `);

    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(colors.green(`TestNFT1 token0 available Balance: ${hre.ethers.utils.formatEther(token0Balance.toString())} `));

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);


    blocktimestamp2 = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp2} `);

    console.log(colors.cyan(`duration: ${blocktimestamp2 - blocktimestamp1} `));


    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(colors.yellow(`TestNFT1 token0 available Balance: ${hre.ethers.utils.formatEther(token0Balance.toString())} `));

    // console.log('\x1b[36m%s\x1b[0m', 'I am cyan');  //cyan
    console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~owner withdraw all~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner TESTERC20 Balance1: ", hre.ethers.utils.formatEther(ownerTESTERC20Balance1.toString()));

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        owner.address,
        [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    let ownerAllWithdrawableBalance1 = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        owner.address);
    console.log(`owner All Withdrawable Balance1 ${hre.ethers.utils.formatEther((ownerAllWithdrawableBalance1.toString()))} `);

    console.log(colors.yellow("#################withdraw AllFrom Stream#################"));
    await instanceStream1MultiNFTV2.connect(owner).withdrawAllFromStream(
        100000,
        [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );


    ownerAllWithdrawableBalance2 = await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        owner.address,
        [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    ownerAllWithdrawableBalance2 = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        owner.address);
    console.log(`owner All Withdrawable Balance2 ${hre.ethers.utils.formatEther((ownerAllWithdrawableBalance2.toString()))} `);

    ownerAllWithdrawableBalanceChanged = hre.ethers.BigNumber.from(ownerAllWithdrawableBalance1).sub(hre.ethers.BigNumber.from(ownerAllWithdrawableBalance2))
    ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner TESTERC20 Balance2: ", hre.ethers.utils.formatEther(ownerTESTERC20Balance2.toString()));
    ownerTestTokenChanged = hre.ethers.BigNumber.from(ownerTESTERC20Balance2).sub(hre.ethers.BigNumber.from(ownerTESTERC20Balance1))
    streamInfo3 = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo3.remainingBalance)} `);
    console.log(colors.yellow(`owner All Withdrawable Balance changed: ${hre.ethers.utils.formatEther(ownerAllWithdrawableBalanceChanged)} `));
    console.log(colors.green(`owner TestToken Changed: ${hre.ethers.utils.formatEther(ownerTestTokenChanged.toString())} `));
    console.log(colors.magenta(`streamInfo.remainingBalance changed: ${hre.ethers.utils.formatEther((
        hre.ethers.BigNumber.from(streamInfo2.remainingBalance).sub(hre.ethers.BigNumber.from(streamInfo3.remainingBalance))
    ).toString())
        } `));

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer TestNFT1 #0 from owner to user1*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT1.transferFrom(owner.address, user1.address, 0);

    ownerERC721Balance = await instanceTestNFT1.balanceOf(owner.address);
    console.log("owner TestNFT1 Balance: ", ownerERC721Balance.toString());

    user1ERC721Balance = await instanceTestNFT1.balanceOf(user1.address);
    console.log("user1 TestNFT1 Balance: ", user1ERC721Balance.toString());

    user2ERC721Balance = await instanceTestNFT1.balanceOf(user2.address);
    console.log("user2 TestNFT1 Balance: ", user2ERC721Balance.toString());

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        owner.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    ownerBalance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        owner.address);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user1.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    user1Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        user1.address);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user2.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    user2Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        user1.address);

    console.log("owenrVestingBalance: ", hre.ethers.utils.formatEther(ownerBalance.toString()));
    console.log("user1VestingBalance: ", hre.ethers.utils.formatEther(user1Balance.toString()));
    console.log("user2VestingBalance: ", hre.ethers.utils.formatEther(user2Balance.toString()));

    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log("token0 Withdrawable Balance: ", hre.ethers.utils.formatEther(token0Balance.toString()));

    let user1TestERC20Balance1 = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 TestERC20 Balance1: ", hre.ethers.utils.formatEther(user1TestERC20Balance1.toString()));

    // blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${ blocktimestamp.toString() } `);

    console.log('///////////////////////////////////////user1 withdraw///////////////////////////////////////////////');
    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(`token0 Balance: ${hre.ethers.utils.formatEther(token0Balance)} `);
    token0RemainingBalance1 = await instanceStream1MultiNFTV2.remainingBalanceByTokenId(100000, 0);
    console.log(`token0 Remaining Balance: ${hre.ethers.utils.formatEther(token0RemainingBalance1)} `);

    await instanceStream1MultiNFTV2.connect(user1).withdrawAllFromStream(
        100000,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]);

    token0Balance = await instanceStream1MultiNFTV2.availableBalanceForTokenId(100000, 0);
    console.log(`token0Balance: ${hre.ethers.utils.formatEther(token0Balance)} `);
    token0RemainingBalance2 = await instanceStream1MultiNFTV2.remainingBalanceByTokenId(100000, 0);
    console.log(`token0 Remaining Balance: ${hre.ethers.utils.formatEther(token0RemainingBalance2)} `);

    user1TestERC20Balance2 = await instanceTESTERC20.balanceOf(user1.address);
    console.log("user1 TestERC20 Balance2: ", hre.ethers.utils.formatEther(user1TestERC20Balance2.toString()));
    console.log("use1 withdraw amount: ", hre.ethers.utils.formatEther(hre.ethers.BigNumber.from(user1TestERC20Balance2).sub(hre.ethers.BigNumber.from(user1TestERC20Balance1))));

    console.log(colors.green(`TESTNFT1 token0 remaining balance changned: ${hre.ethers.utils.formatEther(
        hre.ethers.BigNumber.from(token0RemainingBalance1).sub(hre.ethers.BigNumber.from(token0RemainingBalance2))
    )
        } `));

    console.log(colors.magenta(`user1 TestERC20  balance changned: ${hre.ethers.utils.formatEther(
        hre.ethers.BigNumber.from(user1TestERC20Balance2).sub(hre.ethers.BigNumber.from(user1TestERC20Balance1))
    )
        } `));

    senderBalance = await instanceStream1MultiNFTV2.balanceOfSender(100000);
    console.log(`sender Vesting Balance: ${hre.ethers.utils.formatEther(senderBalance.toString())} `);

    streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)} `);

    console.log("/*****************************************************************************************/")
    console.log("/*************************transfer TESTNFT1 #0 from user1 to user2*****************************/");
    console.log("/*****************************************************************************************/");
    await instanceTestNFT1.connect(user1).transferFrom(user1.address, user2.address, 0);

    ownerERC721Balance = await instanceTestNFT1.balanceOf(owner.address);
    console.log("owner TestNFT1 Balance: ", ownerERC721Balance.toString());

    user1ERC721Balance = await instanceTestNFT1.balanceOf(user1.address);
    console.log("user1 TestNFT1 Balance: ", user1ERC721Balance.toString());

    user2ERC721Balance = await instanceTestNFT1.balanceOf(user2.address);
    console.log("user2 TestNFT1 Balance: ", user2ERC721Balance.toString());

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        owner.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]);
    ownerBalance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(
        100000,
        owner.address);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user1.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]);

    user1Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(
        100000,
        user1.address);

    await instanceStream1MultiNFTV2.availableBalanceForAllNft(
        100000,
        user2.address,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]);

    user2Balance = await instanceStream1MultiNFTV2.getUserAllAvailableBalance(100000,
        user2.address);

    console.log("owenrVestingBalance: ", hre.ethers.utils.formatEther(ownerBalance.toString()));
    console.log("user1VestingBalance: ", hre.ethers.utils.formatEther(user1Balance.toString()));
    console.log("user2VestingBalance: ", hre.ethers.utils.formatEther(user2Balance.toString()));

    // token0Balance = await instanc hre.ethers.BigNumber.from(
    senderBalance = await instanceStream1MultiNFTV2.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${hre.ethers.utils.formatEther(senderBalance.toString())} `);

    console.log("/*****************************************************************************************/")
    console.log("/*************************withdraw user2*****************************/");
    console.log("/*****************************************************************************************/");
    let user2TESTERC20Balance1 = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`before withdraw user2TESTERC20Balance: ${hre.ethers.utils.formatEther(user2TESTERC20Balance1.toString())} `);
    blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()} `);

    console.log('///////////////////////////////////////user2 withdraw///////////////////////////////////////////////');
    rel = await instanceStream1MultiNFTV2.connect(user2).withdrawAllFromStream(
        100000,
        [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9
        ]
    );
    user2TESTERC20Balance2 = await instanceTESTERC20.balanceOf(user2.address);
    console.log(`after withdraw user2TESTERC20Balance: ${hre.ethers.utils.formatEther(user2TESTERC20Balance2.toString())} `);
    console.log(colors.gray(`user2 withdraw amount: ${hre.ethers.utils.formatEther(
        hre.ethers.BigNumber.from(user2TESTERC20Balance2).sub(hre.ethers.BigNumber.from(user2TESTERC20Balance1))
    )
        } `));

    senderBalance = await instanceStream1MultiNFTV2.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${hre.ethers.utils.formatEther(senderBalance.toString())} `);

    streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)} `);

    console.log("/*****************************************************************************************/")
    console.log("/*************************sender withdraw*****************************/");
    console.log("/*****************************************************************************************/");
    senderBalance = await instanceStream1MultiNFTV2.balanceOfSender(100000);
    console.log(`senderVestingBalance: ${hre.ethers.utils.formatEther(senderBalance.toString())} `);

    ownerTESTERC20Balance1 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner TESTERC20 Balance1: ", hre.ethers.utils.formatEther(ownerTESTERC20Balance1.toString()));

    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);
    await instanceTESTERC20.transfer(user1.address, 1);
    await instanceTESTERC20.connect(user1).transfer(owner.address, 1);


    await instanceStream1MultiNFTV2.senderWithdrawFromStream(100000);

    ownerTESTERC20Balance2 = await instanceTESTERC20.balanceOf(owner.address);
    console.log("owner TESTERC20 Balance2: ", hre.ethers.utils.formatEther(ownerTESTERC20Balance2.toString()));

    console.log(colors.cyan(`sender withdraw amount: ${hre.ethers.utils.formatEther(
        hre.ethers.BigNumber.from(ownerTESTERC20Balance2).sub(hre.ethers.BigNumber.from(ownerTESTERC20Balance1))
    )}`));

    streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)} `);


    // console.log("/*****************************************************************************************/")
    // console.log("/*****************************************deposit tokens**********************************/");
    // console.log("/*****************************************************************************************/");

    // streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    // console.log(`streamInfo.deposit: ${hre.ethers.utils.formatEther(streamInfo.deposit)} `);
    // console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)} `);

    // await instanceStream1MultiNFTV2.depositToken(100000, hre.ethers.utils.parseEther("10000"))

    // console.log("/*****************************************deposited**********************************/");
    // streamInfo = await instanceStream1MultiNFTV2.getStreamInfo(100000);
    // console.log(`streamInfo.deposit: ${hre.ethers.utils.formatEther(streamInfo.deposit)} `);
    // console.log(`streamInfo.remainingBalance: ${hre.ethers.utils.formatEther(streamInfo.remainingBalance)} `);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    // .then(() => process.exit(0))
    // .catch((error) => {
    //     console.error(error);
    //     process.exit(1);
    // });