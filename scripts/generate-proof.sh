#!/bin/bash

cd circuits
mkdir -p build

for k in {0..15}; do
    echo "Slice ${k}"
    mkdir -p build/zkWitches/
    mkdir -p build/zkWitches/${k}

    # generate witness
    node "build/zkWitches_js/generate_witness.js" build/zkWitches_js/zkWitches.wasm ../image/slice${k}.json build/zkWitches/${k}/witness.wtns
        
    # generate proof
    snarkjs groth16 prove build/zkWitches/circuit_final.zkey build/zkWitches/${k}/witness.wtns build/zkWitches/${k}/proof.json build/zkWitches/${k}/public.json

    # verify proof
    snarkjs groth16 verify build/zkWitches/verification_key.json build/zkWitches/${k}/public.json build/zkWitches/${k}/proof.json

    # generate call
    snarkjs zkey export soliditycalldata build/zkWitches/${k}/public.json build/zkWitches/${k}/proof.json > build/zkWitches/${k}/call.json
done 
