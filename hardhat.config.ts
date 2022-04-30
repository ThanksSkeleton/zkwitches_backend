import '@typechain/hardhat'
import ('@nomiclabs/hardhat-ethers')
import ('@nomiclabs/hardhat-waffle')
import ("hardhat-deploy");
import ("hardhat-gas-reporter");
import ('fs');
const { testkey, productionkey } = require("./private_keys.json");

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
            accounts: [`${testkey}`]
        },
        mainnet: {
            url: "https://api.s0.t.hmny.io",
            chainId: 1666600000,
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
