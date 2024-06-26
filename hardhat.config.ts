import * as dotenv from 'dotenv';

import { HardhatUserConfig } from 'hardhat/config';
import "@nomicfoundation/hardhat-foundry";
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

import './tasks/deploy';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
  version:'0.8.4',
  settings:{
    optimizer:{
      enabled:true,
      runs:200,

    }
  },
},
  
  paths: {
    artifacts: './frontend/src/artifacts'
  },
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 1000
      }
    },
    sepolia: {
      url: process.env.SEPOLIA_API_URL || '',
      accounts:
        process.env.SEPOLIA_PRIVATE_KEY !== undefined
          ? [process.env.SEPOLIA_PRIVATE_KEY]
          : []
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD'
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

export default config;
