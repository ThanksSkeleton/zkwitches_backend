require('@typechain/hardhat')
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require("hardhat-deploy");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require('fs');
const { test, production } = require("./private_keys.json");

module.exports = {
    solidity: {
        version: "0.8.4",
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    networks: {
        hardhat: {
            gas: 100000000,
            blockGasLimit: 0x1fffffffffffff,
			chainId: 1337,
        },
        testnet: {
            url: "https://api.s0.b.hmny.io",
            chainId: 1666700000,
            accounts: [`${test}`]
        },
        mainnet: {
            url: "https://api.s0.t.hmny.io",
            chainId: 1666600000,
            accounts: [`${production}`]
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
