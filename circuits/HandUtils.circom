pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";

// TODO Include the other logic stuff

template HandHash() 
{    
    signal input CitizenCount[4];
    signal input WitchPresent[4];

    signal input HandSalt;

    signal output Hash;

    component poseidon = Poseidon(9);

    for (var i = 0; i < 4; i++) 
    {         
        poseidon.inputs[i*2] <== CitizenCount[i];
        poseidon.inputs[i*2+1] <== WitchPresent[i];
    }

    poseidon.inputs[8] <== HandSalt;

    Hash <== poseidon.out;
}

template HandValid() {

    signal input CitizenCount[4];
    signal input WitchPresent[4];

    // Citizen Counts + Witch Counts == 8 inputs
    component AllValid = MultiAND(8);

    // must be declared outside of loop
    component citizen_gates[4];
    component witch_gates[4];

    for (var i = 0; i < 4; i++) 
    {         
        citizen_gates[i] = LessThan(3);
        citizen_gates[i].in[0] <== CitizenCount[i];
        citizen_gates[i].in[1] <== 4;
        AllValid.in[i*2] <== citizen_gates[i].out;
        witch_gates[i] = LessThan(1);
        witch_gates[i].in[0] <== WitchPresent[i];
        witch_gates[i].in[1] <== 2;
        AllValid.in[i*2+1] <== witch_gates[i].out;
    }

    // TODO Assert?
    CitizenCount[0] + WitchPresent[0] + CitizenCount[1] + WitchPresent[1] + CitizenCount[2] + WitchPresent[2] + CitizenCount[3] + WitchPresent[3] === 9;
    AllValid.out === 1;
}