#!/bin/bash

mkdir -p export
mkdir -p export/src/import
mkdir -p export/public/import

# Export js folders + zkeys
mkdir -p export/public/import/HandCommitment
cp circuits/build/HandCommitment_js/*.wasm export/public/import/HandCommitment
cp circuits/build/HandCommitment/circuit_final.zkey export/public/import/HandCommitment/circuit_final.zkey

mkdir -p export/public/import/NoWitch
cp circuits/build/NoWitch_js/*.wasm export/public/import/NoWitch
cp circuits/build/NoWitch/circuit_final.zkey export/public/import/NoWitch/circuit_final.zkey

mkdir -p export/public/import/ValidMove
cp circuits/build/ValidMove_js/*.wasm export/public/import/ValidMove
cp circuits/build/ValidMove/circuit_final.zkey export/public/import/ValidMove/circuit_final.zkey
# export circuit input types
cp circuits/*.ts export/src/import
cp circuits/*.json export/src/import

# export solidity generated typescript bindings
mkdir -p export/src/import/contracts
mkdir -p export/src/import/contracts/ZkWitches
cp typechain-types/contracts/zkWitches.sol/ZkWitches.ts export/src/import/contracts/ZkWitches/ZkWitches.ts
cp typechain-types/common.ts export/src/import/common.ts

# export ABI
cp artifacts/contracts/zkWitches.sol/zkWitches.json export/src/import/zkWitches.json