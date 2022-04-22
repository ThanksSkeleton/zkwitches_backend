#!/bin/bash

#export NODE_OPTIONS="--max-old-space-size=16384"

cd circuits
mkdir -p build

if [ -f ./powersOfTau28_hez_final_14.ptau ]; then
    echo "powersOfTau28_hez_final_14.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_14.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_14.ptau
fi

echo "Compiling: zkWitches..."

mkdir -p build/zkWitches

# compile circuit

if [ -f ./build/zkWitches.r1cs ]; then
    echo "Circuit already compiled. Skipping."
else
    circom zkWitches.circom --r1cs --wasm --sym -o build
    snarkjs r1cs info build/zkWitches.r1cs
fi

# Start a new zkey and make a contribution

if [ -f ./build/zkWitches/verification_key.json ]; then
    echo "verification_key.json already exists. Skipping."
else
    snarkjs groth16 setup build/zkWitches.r1cs powersOfTau28_hez_final_14.ptau build/zkWitches/circuit_0000.zkey
    snarkjs zkey contribute build/zkWitches/circuit_0000.zkey build/zkWitches/circuit_final.zkey --name="1st Contributor Name" -v -e="random text"
    snarkjs zkey export verificationkey build/zkWitches/circuit_final.zkey build/zkWitches/verification_key.json
fi

# generate solidity contract
snarkjs zkey export solidityverifier build/zkWitches/circuit_final.zkey ../contracts/verifier.sol