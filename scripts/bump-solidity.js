const fs = require("fs");
const solidityRegex = /pragma solidity \^\d+\.\d+\.\d+/

const contracts = [
"./contracts/HandCommitment_verifier.sol",
"./contracts/NoWitch_verifier.sol",
"./contracts/ValidMove_verifier.sol"
]

for (var i = 0; i < contracts.length; i++) {
    content = fs.readFileSync(contracts[i], { encoding: 'utf-8' });
    bumped = content.replace(solidityRegex, 'pragma solidity ^0.8.4');

    fs.writeFileSync(contracts[i], bumped);
}