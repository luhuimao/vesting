import { exec } from 'child_process';
// import * as hre from 'hardhat';
const hre = require("hardhat");

import { network } from 'hardhat';
import { TestNFT } from '../typechain/TestNFT';
import { Vesting1 } from '../typechain/Vesting1';
import { Vesting2 } from '../typechain/Vesting2';
import { ERC20PresetFixedSupply } from '../typechain/ERC20PresetFixedSupply';
import * as config from '../.config';
import { Contract, ethers } from 'ethers';
import * as boutils from './boutils';
import Web3 from "web3";

let main = async () => {
    console.log('network:', network.name, (await hre.ethers.provider.getNetwork()).chainId);
    let user;
    let owner = new hre.ethers.Wallet(process.env.RINKEBY_TEST_PRIVATE_KEY, hre.ethers.provider);
    [, user] = await hre.ethers.getSigners();

    console.log('deploy account:', owner.address, hre.ethers.utils.formatEther((await owner.getBalance()).toString()));

    let gasprice = (await owner.getGasPrice()).add(1);
    let blockGaslimit0 = (await hre.ethers.provider.getBlock('latest')).gasLimit;
    let blockGaslimit = blockGaslimit0.div(4);
    if (network.name == 'devnet') {
        gasprice = gasprice.sub(gasprice).add(1);
        blockGaslimit = blockGaslimit0;
    }
    let blockNumber = await hre.ethers.provider.getBlockNumber();
    console.log('gasPrice:', blockNumber, gasprice.toString(), hre.ethers.utils.formatEther(gasprice));
    console.log(
        'gasLimit:',
        blockNumber,
        blockGaslimit0.toString(),
        blockGaslimit.toString(),
        hre.ethers.utils.formatEther(blockGaslimit.mul(gasprice))
    );
    //Deploy Vesting1
    const vesting1Address = config.getVesting1AddressByNetwork(network.name);
    let instanceVesting1: Vesting1;
    if (vesting1Address) {
        instanceVesting1 = (await hre.ethers.getContractFactory('Vesting1')).connect(owner).attach(vesting1Address) as Vesting1;
        console.log('reuse Vesting1 address:', instanceVesting1.address);
    } else {
        let Vesting1ContractFactory = await hre.ethers.getContractFactory('Vesting1');
        instanceVesting1 = (await Vesting1ContractFactory.connect(owner).deploy({
            gasLimit: await hre.ethers.provider.estimateGas(Vesting1ContractFactory.getDeployTransaction()),
        })) as Vesting1;
        console.log('new Vesting1 address:', instanceVesting1.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'VESTING1_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceVesting1.address + '"; ' + flag);
    }

    //Deploy Vesting2
    const vesting2Address = config.getVesting2AddressByNetwork(network.name);
    let instanceVesting2: Vesting2;
    if (vesting2Address) {
        instanceVesting2 = (await hre.ethers.getContractFactory('Vesting2')).connect(owner).attach(vesting2Address) as Vesting2;
        console.log('reuse Vesting2 address:', instanceVesting2.address);
    } else {
        let Vesting2ContractFactory = await hre.ethers.getContractFactory('Vesting2');
        instanceVesting2 = (await Vesting2ContractFactory.connect(owner).deploy({
            gasLimit: await hre.ethers.provider.estimateGas(Vesting2ContractFactory.getDeployTransaction()),
        })) as Vesting2;
        console.log('new Vesting2 address:', instanceVesting2.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'VESTING2_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceVesting2.address + '"; ' + flag);
    }



    let instanceTestNFT: TestNFT;
    const testERC721Address = config.getTESTERC721AddressByNetwork(network.name);
    if (testERC721Address) {
        instanceTestNFT = (await hre.ethers.getContractFactory('TestNFT')).connect(owner).attach(testERC721Address) as TestNFT;
        console.log('reuse TestNFT address:', instanceTestNFT.address);
    } else {
        const testNFTContractFactory = await hre.ethers.getContractFactory("TestNFT");
        instanceTestNFT = await testNFTContractFactory.connect(owner).deploy('TEST ERC721', 'TE721', 100, {
            gasLimit: blockGaslimit,
        }) as TestNFT;
        await instanceTestNFT.connect(owner).deployed();
        console.log("TestNFT deployed to:", instanceTestNFT.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TEST_ERC721_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceTestNFT.address + '"; ' + flag);
    }

    let instanceERC20PresetFixedSupply: ERC20PresetFixedSupply;
    const testERC20ddress = config.getTESTERC20AddressByNetwork(network.name);
    if (testERC20ddress) {
        instanceERC20PresetFixedSupply = (await hre.ethers.getContractFactory('ERC20PresetFixedSupply')).connect(owner).attach(testERC20ddress) as ERC20PresetFixedSupply;
        console.log('reuse TestERC20 address:', instanceERC20PresetFixedSupply.address);
    } else {
        const ERC20PresetFixedSupplyContractFactory = await hre.ethers.getContractFactory("ERC20PresetFixedSupply");
        instanceERC20PresetFixedSupply = await ERC20PresetFixedSupplyContractFactory.connect(owner).deploy("VESTING TEST TOKEN", "VestingTT", "10000000000000000000000000000", owner.address, {
            gasLimit: blockGaslimit,
        }) as ERC20PresetFixedSupply;
        await instanceERC20PresetFixedSupply.connect(owner).deployed();
        console.log("TestToken deployed to:", instanceERC20PresetFixedSupply.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TEST_ERC20_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceERC20PresetFixedSupply.address + '"; ' + flag);
    }

    console.log("/*****************************************************************************************/");
    console.log("/************************************************createStream2*****************************/");
    console.log("/*****************************************************************************************/");

    let blocktimestamp = (await hre.ethers.provider.getBlock("latest")).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 1000;
    const stopTime = startTime + 2000;

    let tmpr = await instanceVesting2.createStream2(
        2000,
        instanceERC20PresetFixedSupply.address,
        startTime,
        stopTime,
        instanceTestNFT.address,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]
        , {
            gasPrice: gasprice,
            gasLimit: 7000000,
        }
    );
    const rel = await instanceVesting2.getStream2(200000);
    console.log(`sender:${rel.sender}`);
    console.log(`sender:${rel.tokenAddress}`);
    console.log(`sender:${rel.startTime}`);
    console.log(`sender:${rel.stopTime}`);
    console.log(`sender:${rel.remainingBalance}`);
    console.log(`sender:${rel.ratePerSecond}`);
    console.log(`sender:${rel.erc721Address}`);
    // let latest_block = await hre.ethers.providers.getBlockNumber();
    // let historical_block = latest_block - 100;
    // const data_events = await instanceVesting2.getPastEvents(
    //     'CreateStream2', // change if your looking for a different event
    //     { fromBlock: historical_block, toBlock: 'latest' }
    // );
    // let stream2id = 0;
    // if (data_events) {
    //     for (var i = 0; i < data_events.length; i++) {
    //         stream2id = data_events[i]['returnValues']['stream2Id'];
    //         console.log(`stream2id: ${stream2id.toString()}`);
    //     }
    // }

    // await boutils.Sleep(10000);

    let chainId = (await hre.ethers.provider.getNetwork()).chainId;
};

main();
