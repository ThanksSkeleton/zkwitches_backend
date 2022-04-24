#!/bin/bash

cd circuits
mkdir -p build    
mkdir -p build/$1/

# generate witness
node "build/$1_js/generate_witness.js" build/$1_js/$1.wasm ./$1_input.json build/$1/witness.wtns
	
# generate proof
snarkjs groth16 prove build/$1/circuit_final.zkey build/$1/witness.wtns build/$1/proof.json build/$1/public.json

# verify proof
snarkjs groth16 verify build/$1/verification_key.json build/$1/public.json build/$1/proof.json

# generate call
snarkjs zkey export soliditycalldata build/$1/public.json build/$1/proof.json > build/$1/call.json
