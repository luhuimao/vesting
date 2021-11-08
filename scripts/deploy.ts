import { exec } from 'child_process';
// import * as hre from 'hardhat';
const hre = require("hardhat");

import { network } from 'hardhat';
import { TestNFT } from '../typechain/TestNFT';
import { Sablier } from '../typechain/Sablier';
import { ERC20PresetFixedSupply } from '../typechain/ERC20PresetFixedSupply';
import * as config from '../.config';
import { Contract } from 'ethers';
import * as boutils from './boutils';

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

    const vestingAddress = config.getVestingAddressByNetwork(network.name);
    let instanceSablier: Sablier;
    if (vestingAddress) {
        instanceSablier = (await hre.ethers.getContractFactory('Sablier')).connect(owner).attach(vestingAddress) as Sablier;
        console.log('reuse Sablier address:', instanceSablier.address);
    } else {
        let sablierContractFactory = await hre.ethers.getContractFactory('Sablier');
        instanceSablier = (await sablierContractFactory.connect(owner).deploy({
            gasLimit: await hre.ethers.provider.estimateGas(sablierContractFactory.getDeployTransaction()),
        })) as Sablier;
        console.log('new Sablier address:', instanceSablier.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'VESTING_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceSablier.address + '"; ' + flag);
    }


    let instanceTestNFT: TestNFT;
    const testERC721Address = config.getTESTERC721AddressByNetwork(network.name);
    if (testERC721Address) {
        instanceTestNFT = (await hre.ethers.getContractFactory('TestNFT')).connect(owner).attach(testERC721Address) as TestNFT;
        console.log('reuse TestNFT address:', instanceTestNFT.address);
    } else {
        const testNFTContractFactory = await hre.ethers.getContractFactory("TestNFT");
        instanceTestNFT = await testNFTContractFactory.connect(owner).deploy('TEST ERC721', 'TE721', {
            gasLimit: blockGaslimit,
        }) as TestNFT;
        await instanceTestNFT.connect(owner).deployed();
        console.log("TestNFT deployed to:", instanceTestNFT.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TEST_ERC721_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceSablier.address + '"; ' + flag);
    }

    let instanceERC20PresetFixedSupply: ERC20PresetFixedSupply;
    const testERC20ddress = config.getTESTERC20AddressByNetwork(network.name);
    if (testERC20ddress) {
        instanceERC20PresetFixedSupply = (await hre.ethers.getContractFactory('ERC20PresetFixedSupply')).connect(owner).attach(testERC20ddress) as ERC20PresetFixedSupply;
        console.log('reuse TestERC20 address:', instanceERC20PresetFixedSupply.address);
    } else {
        const ERC20PresetFixedSupplyContractFactory = await hre.ethers.getContractFactory("ERC20PresetFixedSupply");
        instanceERC20PresetFixedSupply = await ERC20PresetFixedSupplyContractFactory.connect(owner).deploy("TEST TOKEN", "TT", 100000000, owner.address, {
            gasLimit: blockGaslimit,
        }) as ERC20PresetFixedSupply;
        await instanceERC20PresetFixedSupply.connect(owner).deployed();
        console.log("TestToken deployed to:", instanceERC20PresetFixedSupply.address);

        let flag = '\\/\\/REPLACE_FLAG';
        let key = 'TEST_ERC20_ADDRESS_' + network.name.toUpperCase();
        boutils.ReplaceLine('.config.ts', key + '.*' + flag, key + ' = "' + instanceSablier.address + '"; ' + flag);
    }


    // await boutils.Sleep(10000);

    let chainId = (await hre.ethers.provider.getNetwork()).chainId;
};

main();
