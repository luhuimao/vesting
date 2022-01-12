import { exec } from 'child_process';
// import * as hre from 'hardhat';
const hre = require("hardhat");
import { ethers, network, artifacts } from 'hardhat';
import { TestNFT } from '../typechain/TestNFT';
import { Vesting1 } from '../typechain/Vesting1';
import { Vesting2 } from '../typechain/Vesting2';
import { Stream1MultiNFTV2 } from '../typechain/Stream1MultiNFTV2';
import { TokenAllocation, ERC721BatchMint, StreamV3 } from '../typechain';
import { ERC20PresetFixedSupply } from '../typechain/ERC20PresetFixedSupply';
import * as config from '../.config';
import * as boutils from './boutils';
import { getOwnerPrivateKey } from '../.privatekey';

let main = async () => {
    console.log('network:', network.name, (await ethers.provider.getNetwork()).chainId);
    // let user;
    let owner = new ethers.Wallet(await getOwnerPrivateKey(network.name), ethers.provider);
    // [, user] = await ethers.getSigners();

    console.log('deploy account:', owner.address, ethers.utils.formatEther((await owner.getBalance()).toString()));

    let gasprice = (await owner.getGasPrice()).add(1);
    let blockGaslimit0 = (await ethers.provider.getBlock('latest')).gasLimit;
    let blockGaslimit = blockGaslimit0.div(4);
    if (network.name == 'devnet') {
        gasprice = gasprice.sub(gasprice).add(1);
        blockGaslimit = blockGaslimit0;
    }
    let blockNumber = await ethers.provider.getBlockNumber();
    console.log('gasPrice:', blockNumber, gasprice.toString(), ethers.utils.formatEther(gasprice));
    console.log(
        'gasLimit:',
        blockNumber,
        blockGaslimit0.toString(),
        blockGaslimit.toString(),
        ethers.utils.formatEther(blockGaslimit.mul(gasprice))
    );
    ///////////////////////////////////////Deploy Vesting1 ///////////////////////////////////////
    // const vesting1Address = config.getVesting1AddressByNetwork(network.name);
    // let instanceVesting1: Vesting1;
    // if (vesting1Address) {
    //     instanceVesting1 = (await ethers.getContractFactory('Vesting1')).connect(owner).attach(vesting1Address) as Vesting1;
    //     console.log('reuse Vesting1 address:', instanceVesting1.address);
    // } else {
    //     let Vesting1ContractFactory = await ethers.getContractFactory('Vesting1');
    //     instanceVesting1 = (await Vesting1ContractFactory.connect(owner).deploy({
    //         gasLimit: await ethers.provider.estimateGas(Vesting1ContractFactory.getDeployTransaction()),
    //     })) as Vesting1;
    //     console.log('new Vesting1 address:', instanceVesting1.address);

    //     let flag = '\\/\\/REPLACE_FLAG';
    //     let key = 'VESTING1_ADDRESS_' + network.name.toUpperCase();
    //     boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceVesting1.address + '"; ' + flag);
    // }

    ///////////////////////////////////////Deploy Vesting2 ///////////////////////////////////////
    // const vesting2Address = config.getVesting2AddressByNetwork(network.name);
    // let instanceVesting2: Vesting2;
    // if (vesting2Address) {
    //     instanceVesting2 = (await ethers.getContractFactory('Vesting2')).connect(owner).attach(vesting2Address) as Vesting2;
    //     console.log('reuse Vesting2 address:', instanceVesting2.address);
    // } else {
    //     let Vesting2ContractFactory = await ethers.getContractFactory('Vesting2');
    //     instanceVesting2 = (await Vesting2ContractFactory.connect(owner).deploy({
    //         gasLimit: await ethers.provider.estimateGas(Vesting2ContractFactory.getDeployTransaction()),
    //     })) as Vesting2;
    //     console.log('new Vesting2 address:', instanceVesting2.address);

    //     let flag = '\\/\\/REPLACE_FLAG';
    //     let key = 'VESTING2_ADDRESS_' + network.name.toUpperCase();
    //     boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceVesting2.address + '"; ' + flag);
    // }

    /*****************************************************************************************/
    /*******************************Deploy Stream1LibV2******************************************/
    /*****************************************************************************************/
    // const instanceStream1LibV2 = await (await ethers.getContractFactory("Stream1LibV2")).connect(owner).deploy();

    ///////////////////////////////////////Deploy Stream1MultiNFTV2///////////////////////////////////////
    // const streammultiNFTV2Address = config.getStream1MultiNFTV2AddressByNetwork(network.name);
    // let instanceStream1MultiNFTV2: Stream1MultiNFTV2;
    // if (streammultiNFTV2Address) {
    //     instanceStream1MultiNFTV2 = (await ethers.getContractFactory('Stream1MultiNFTV2')).connect(owner).attach(streammultiNFTV2Address) as Stream1MultiNFTV2;
    //     console.log('reuse Stream1MultiNFTV2 address:', instanceStream1MultiNFTV2.address);
    // } else {
    //     let Stream1MultiNFTV2ContractFactory = await ethers.getContractFactory('Stream1MultiNFTV2');
    //     instanceStream1MultiNFTV2 = (
    //         await Stream1MultiNFTV2ContractFactory.connect(owner).deploy(
    //             // { gasLimit: await ethers.provider.estimateGas(Stream1MultiNFTV2ContractFactory.getDeployTransaction()), }
    //         )
    //     ) as Stream1MultiNFTV2;
    //     console.log('new Stream1MultiNFTV2 address:', instanceStream1MultiNFTV2.address);

    //     let flag = '\\/\\/REPLACE_FLAG';
    //     let key = 'STREAM1MULTINFTV2_ADDRESS_' + network.name.toUpperCase();
    //     boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceStream1MultiNFTV2.address + '"; ' + flag);
    // }

    ///////////////////////////////////////Deploy TokenAllocation///////////////////////////////////////
    const TokenAllocationAddress = config.getTokenAllocLibV3AddressByNetwork(network.name);
    let instanceTokenAllocation: TokenAllocation;
    if (TokenAllocationAddress) {
        instanceTokenAllocation = (await ethers.getContractFactory('TokenAllocation')).connect(owner).attach(TokenAllocationAddress) as TokenAllocation;
        console.log('reuse TokenAllocation address:', instanceTokenAllocation.address);
    } else {
        let TokenAllocationContractFactory = await ethers.getContractFactory('TokenAllocation');
        instanceTokenAllocation = (await TokenAllocationContractFactory.connect(owner).deploy({
            gasLimit: await ethers.provider.estimateGas(TokenAllocationContractFactory.getDeployTransaction()),
        })) as TokenAllocation;
        console.log('new TokenAllocation address:', instanceTokenAllocation.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TOKENALLOCLIBV3_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceTokenAllocation.address + '"; ' + flag);
    }


    ///////////////////////////////////////Deploy ERC721BatchMint///////////////////////////////////////
    const ERC721BatchMintAddress = config.getERC721BatchMintAddressByNetwork(network.name);
    let instanceERC721BatchMint: ERC721BatchMint;
    if (ERC721BatchMintAddress) {
        instanceERC721BatchMint = (await ethers.getContractFactory('ERC721BatchMint'))
            .connect(owner).attach(ERC721BatchMintAddress) as ERC721BatchMint;
        console.log('reuse ERC721BatchMint address:', instanceERC721BatchMint.address);
    } else {
        let ERC721BatchMintContractFactory = await ethers.getContractFactory('ERC721BatchMint');
        instanceERC721BatchMint = (await ERC721BatchMintContractFactory.connect(owner).deploy("StreamV3 NFT", "SV3", {
            gasLimit: await ethers.provider.estimateGas(ERC721BatchMintContractFactory.getDeployTransaction("StreamV3 NFT", "SV3")),
        })) as ERC721BatchMint;
        console.log('new ERC721BatchMint address:', instanceERC721BatchMint.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'ERC721BATCHMINT_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceERC721BatchMint.address + '"; ' + flag);
    }

    ///////////////////////////////////////Deploy StreamV3 ///////////////////////////////////////
    const streamV3Address = config.getStreamV3AddressByNetwork(network.name);
    let instanceStreamV3: StreamV3;
    if (streamV3Address) {
        instanceStreamV3 = (await ethers.getContractFactory('StreamV3',
            { libraries: { TokenAllocation: instanceTokenAllocation.address } }))
            .connect(owner).attach(streamV3Address) as StreamV3;
        console.log('reuse StreamV3 address:', instanceStreamV3.address);
    } else {
        let StreamV3ContractFactory = await ethers.getContractFactory("StreamV3",
            { libraries: { TokenAllocation: instanceTokenAllocation.address } });
        instanceStreamV3 = (await StreamV3ContractFactory.connect(owner).deploy(instanceERC721BatchMint.address, {
            gasLimit: await ethers.provider.estimateGas(StreamV3ContractFactory.getDeployTransaction(instanceERC721BatchMint.address)),
        })) as StreamV3;
        console.log('new StreamV3 address:', instanceStreamV3.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'STREAMV3_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceStreamV3.address + '"; ' + flag);
    }


    ///////////////////////////////////////Deploy TestNFT///////////////////////////////////////
    // let instanceTestNFT: TestNFT;
    // const testERC721Address = config.getTESTERC721AddressByNetwork(network.name);
    // if (testERC721Address) {
    //     instanceTestNFT = (await ethers.getContractFactory('TestNFT')).connect(owner).attach(testERC721Address) as TestNFT;
    //     console.log('reuse TestNFT address:', instanceTestNFT.address);
    // } else {
    //     const testNFTContractFactory = await ethers.getContractFactory("TestNFT");
    //     instanceTestNFT = await testNFTContractFactory.connect(owner).deploy('TEST ERC721', 'TE721', 100, {
    //         gasLimit: blockGaslimit,
    //     }) as TestNFT;
    //     await instanceTestNFT.connect(owner).deployed();
    //     console.log("TestNFT deployed to:", instanceTestNFT.address);

    //     let flag = '\\/\\/REPLACE_FLAG';
    //     let key = 'TEST_ERC721_ADDRESS_' + network.name.toUpperCase();
    //     boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceTestNFT.address + '"; ' + flag);
    // }

    ///////////////////////////////////////Deploy ERC20PresetFixedSupply///////////////////////////////////////
    let instanceERC20PresetFixedSupply: ERC20PresetFixedSupply;
    const testERC20ddress = config.getTESTERC20AddressByNetwork(network.name);
    if (testERC20ddress) {
        instanceERC20PresetFixedSupply = (await ethers.getContractFactory('ERC20PresetFixedSupply')).connect(owner).attach(testERC20ddress) as ERC20PresetFixedSupply;
        console.log('reuse TestERC20 address:', instanceERC20PresetFixedSupply.address);
    } else {
        const ERC20PresetFixedSupplyContractFactory = await ethers.getContractFactory("ERC20PresetFixedSupply");
        instanceERC20PresetFixedSupply = await ERC20PresetFixedSupplyContractFactory.connect(owner).deploy("VESTING TEST TOKEN", "VestingTT", "10000000000000000000000000000", owner.address, {
            gasLimit: blockGaslimit,
        }) as ERC20PresetFixedSupply;
        await instanceERC20PresetFixedSupply.connect(owner).deployed();
        console.log("TestToken deployed to:", instanceERC20PresetFixedSupply.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TEST_ERC20_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceERC20PresetFixedSupply.address + '"; ' + flag);
    }

    let ownerTestTokenBalance = await instanceERC20PresetFixedSupply.balanceOf(owner.address);
    console.log("owner TestToken Balance: ", ethers.utils.formatEther(ownerTestTokenBalance.toString()));

    // console.log("/*****************************************************************************************/");
    // console.log("/************************************************createStream2*****************************/");
    // console.log("/*****************************************************************************************/");

    // let blocktimestamp = (await ethers.provider.getBlock("latest")).timestamp;
    // console.log(`current timestamp: ${blocktimestamp.toString()}`);
    // let startTime = blocktimestamp + 1000;
    // let stopTime = startTime + 2000;

    // let tmpr = await instanceVesting2.createStream2(
    //     2000,
    //     instanceERC20PresetFixedSupply.address,
    //     startTime,
    //     stopTime,
    //     instanceTestNFT.address,
    //     [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    //     [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]
    //     , {
    //         gasPrice: gasprice,
    //         gasLimit: 7000000,
    //     }
    // );
    // let rel = await instanceVesting2.getStream2(200000);
    // console.log(`sender:${rel.sender}`);
    // console.log(`sender:${rel.tokenAddress}`);
    // console.log(`sender:${rel.startTime}`);
    // console.log(`sender:${rel.stopTime}`);
    // console.log(`sender:${rel.remainingBalance}`);
    // console.log(`sender:${rel.ratePerSecond}`);
    // console.log(`sender:${rel.erc721Address}`);


    // await boutils.Sleep(10000);


    console.log("/*****************************************************************************************/");
    console.log("/************************************************create StreamV3*****************************/");
    console.log("/*****************************************************************************************/");

    let blocktimestamp = (await ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    let startTime = blocktimestamp + 1000;
    let stopTime = startTime + 2000;

    //unlimited Approval for ERC20 token
    let approve_amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    // await instanceERC20PresetFixedSupply.approve(instanceStreamV3.address, approve_amount);

    // let tx = await instanceStreamV3.createStream(
    //     [
    //         ethers.utils.parseEther("200000"),
    //         startTime,
    //         stopTime,
    //     ],
    //     instanceERC20PresetFixedSupply.address,
    //     [10, 10, 20],
    //     [
    //         ethers.utils.parseEther("100"),
    //         ethers.utils.parseEther("200"),
    //         ethers.utils.parseEther("300")
    //     ],
    //     {
    //         gasPrice: ethers.utils.parseUnits("10", "gwei"),
    //         gasLimit: blockGaslimit
    //     }
    // );
    // console.log(tx);

    let rel = await instanceStreamV3.getStreamInfo(100000);
    console.log(`sender:${rel.sender}`);
    console.log(`tokenAddress:${rel.tokenAddress}`);
    console.log(`startTime:${rel.startTime}`);
    console.log(`stopTime:${rel.stopTime}`);
    console.log(`remainingBalance:${ethers.utils.formatEther(rel.remainingBalance)}`);

    ///////////////////////////////////////batch mint nft///////////////////////////////////////
    // await instanceERC721BatchMint.mintBatchByStreamId(instanceStreamV3.address, 100000, 0, owner.address);

    let tokenBalance = await instanceERC721BatchMint.balanceOf(owner.address);
    console.log("owner test nft Balance: ", tokenBalance.toString());
    // let chainId = (await ethers.provider.getNetwork()).chainId;

    let tokenAvailableBalance = await instanceStreamV3.availableBalanceForTokenId(100000, 0);
    console.log("token #0 Available Balance: ", hre.ethers.utils.formatEther(tokenAvailableBalance.toString()));

    let tokenRemainingBalance = await instanceStreamV3.remainingBalanceByTokenId(100000, 0);
    console.log("token #0 Remaining Balance: ", hre.ethers.utils.formatEther(tokenRemainingBalance.toString()));

    ///////////////////////////////////////withdraw From Stream By TokenId///////////////////////////////////////
    let user1ERC20Balace = await instanceERC20PresetFixedSupply.balanceOf(owner.address);
    console.log("owner ERC20 Balace: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));
    console.log(`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~user1 withdraw token #0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`);
    // await instanceStreamV3.connect(owner).withdrawFromStreamByTokenId(100000, 0);
    user1ERC20Balace = await instanceERC20PresetFixedSupply.balanceOf(owner.address);
    console.log("owner ERC20 Balace: ", hre.ethers.utils.formatEther(user1ERC20Balace.toString()));

    let streamInfo = await instanceStreamV3.getStreamInfo(100000);
    console.log("pool remaining Balance: ", hre.ethers.utils.formatEther(streamInfo.remainingBalance.toString()));
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
