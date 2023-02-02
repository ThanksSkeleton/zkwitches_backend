import 'dotenv/config';
import {HardhatUserConfig} from 'hardhat/types';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-gas-reporter';
import '@typechain/hardhat';

const { testkey, productionkey } = require("./private_keys.json");

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        hardhat: {
            gas: 100000000,
            blockGasLimit: 0x1fffffffffffff,
			chainId: 1337,
        },
        testnet: {
            url: "https://goerli.optimism.io",
            chainId: 420,
            accounts: [`${testkey}`]
        },
        mainnet: {
            url: "https://optimism-mainnet.public.blastapi.io",
            chainId: 10,
            accounts: [`${productionkey}`]
        },
    },
    namedAccounts: {
        deployer: 0,
    },
    paths: {
        deploy: "deploy",
        deployments: "deployments",
    },
    mocha: {
        timeout: 1000000
    }
};
export default config;