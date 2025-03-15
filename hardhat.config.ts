import 'dotenv/config';
import './utils/decrypt-env-vars';

import { HardhatUserConfig } from 'hardhat/types';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-gas-reporter';
import '@typechain/hardhat';
import 'solidity-coverage';
import 'hardhat-deploy-tenderly';
import { accounts, addForkConfiguration } from './utils/network';
import { task } from 'hardhat/config';

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('named-accounts', 'Prints the named accounts', async (taskArgs, hre) => {
  const accounts = await hre.getNamedAccounts();
  console.log(accounts);
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.23',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: 3,
    secondary: 4,
    tertiary: 5,
    test1: 6,
    test2: 7,
    test3: 8,
  },
  networks: addForkConfiguration({
    hardhat: {
      initialBaseFeePerGas: 0, // to fix : https://github.com/sc-forks/solidity-coverage/issues/652, see https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136
      saveDeployments: true,
    },
    localhost: {
      url: 'http://localhost:8545',
      accounts: accounts(),
    },
    eth_mainnet: {
      url: 'https://rpc.ankr.com/eth',
      chainId: 1,
      accounts: accounts('eth_mainnet'),
    },
    eth_goerli: {
      url: 'https://rpc.ankr.com/eth_goerli',
      chainId: 5,
      accounts: accounts('eth_goerli'),
    },
    polygon_mainnet: {
      url: 'https://polygon-rpc.com',
      chainId: 137,
      accounts: accounts('polygon_mainnet'),
    },
    polygon_mumbai: {
      url: 'https://gateway.tenderly.co/public/polygon-mumbai',
      chainId: 80001,
      accounts: accounts('polygon_mumbai'),
    },
    polygon_amoy: {
      url: 'https://rpc-amoy.polygon.technology',
      chainId: 80002,
      accounts: accounts('polygon_amoy'),
    },
    peaq_agung: {
      url: 'https://rpcpc1-qa.agung.peaq.network',
      chainId: 9990,
      accounts: accounts('peaq_agung'),
    },
    peaq_mainnet: {
      url: 'https://peaq-rpc.publicnode.com',
      chainId: 3338,
      accounts: accounts('peaq_mainnet'),
    },
  }),
  paths: {
    sources: 'contracts',
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 100,
    enabled: process.env.REPORT_GAS ? true : false,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    maxMethodDiff: 10,
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
  mocha: {
    timeout: 0,
  },
  external: process.env.HARDHAT_FORK
    ? {
        deployments: {
          // process.env.HARDHAT_FORK will specify the network that the fork is made from.
          // these lines allow it to fetch the deployments from the network being forked from both for node and deploy task
          hardhat: ['deployments/' + process.env.HARDHAT_FORK],
          localhost: ['deployments/' + process.env.HARDHAT_FORK],
        },
      }
    : undefined,

  tenderly: {
    project: 'template-ethereum-contracts',
    username: process.env.TENDERLY_USERNAME as string,
  },
};

export default config;
