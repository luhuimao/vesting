// import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import { task } from "hardhat/config";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      // allowUnlimitedContractSize: true,
      // blockGasLimit: 0x1ffffffff,
    },
    rinkeby: {
      // allowUnlimitedContractSize: true,
      url: 'https://rinkeby.infura.io/v3/04dd3493f83c48de9735b4b29f108b84'
    },
    xDaiTestNet: {
      url: 'https://xdai.poanetwork.dev/'
    }
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './build/cache',
    artifacts: './build/artifacts',
  },
  solidity: {
    compilers: [
      {
        version: "0.5.5",
      },
      {
        version: "0.6.7",
        settings: {},
      },
      {
        version: "0.8.4",
      },
      { version: "0.5.17" }
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  // typechain: {
  //   outDir: "src/types",
  //   target: "ethers-v5",
  // },
};