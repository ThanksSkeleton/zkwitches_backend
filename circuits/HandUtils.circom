pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
// TODO Include the other logic stuff

template HandHash() 
{    
    signal input[4] CitizenCount;
    signal input[4] WitchPresent;

    signal input HandSalt;

    signal output Hash;

    component poseidon = Poseidon(9);

    for (var i = 0; i < 4; i++) 
    {         
        poseidon.in[i*2] <== CitizenCount[i];
        poseidon.in[i*2+1] <== WitchPresent[i];
    }

    poseidon.in[8] <== HandSalt;

    Hash <== poseidon.out;
}

template HandValid() {

    signal input[4] CitizenCount;
    signal input[4] WitchPresent;

    // Citizen Counts + Witch Counts == 8 inputs
    component AllValid = MultiAND(8);

    for (var i = 0; i < 4; i++) 
    {         
        component citizen_gate = LessThan(3);
        citizen_gate.in[0] <== CitizenCount[i];
        citizen_gate.in[1] <== 4;
        AllValid.in[i*2] <== citizen_gate.out;
        component witch_gate = LessThan(1);
        witch_gate.in[0] <== WitchPresent[i];
        witch_gate.in[1] <== 2;
        AllValid.in[i*2+1] <== witch_gate.out;
    }

    // TODO Assert?
    CitizenCount[0] + WitchPresent[0] + CitizenCount[1] + WitchPresent[1] + CitizenCount[2] + WitchPresent[2] + CitizenCount[3] + WitchPresent[3] === 9
    AllValid.out === 1;
}