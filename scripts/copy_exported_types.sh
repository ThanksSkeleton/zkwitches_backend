#!/bin/bash

mkdir -p export

# Export js folders + zkeys
mkdir -p export/HandCommitment
cp circuits/build/HandCommitment_js/*.* export/HandCommitment
cp circuits/build/HandCommitment/circuit_final.zkey export/HandCommitment/circuit_final.zkey

mkdir -p export/NoWitch
cp circuits/build/NoWitch_js/*.* export/NoWitch
cp circuits/build/NoWitch/circuit_final.zkey export/NoWitch/circuit_final.zkey

mkdir -p export/ValidMove
cp circuits/build/ValidMove_js/*.* export/ValidMove
cp circuits/build/ValidMove/circuit_final.zkey export/ValidMove/circuit_final.zkey
# export circuit input types
cp circuits/*.ts export
cp circuits/*.json export

# export solidity generated types
mkdir -p export
cp typechain-types/zkWitches.sol/ZkWitches.ts export/ZkWitches.ts
cp typechain-types/common.ts export/common.ts