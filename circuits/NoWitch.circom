pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./HandUtils.circom"

// TODO Include the other logic stuff

template NoWitch() 
{
    signal input[4] CitizenCount;
    signal input[4] WitchPresent;

    signal input HandSalt;

    public signal input ExpectedHash;

    public signal input[4] WitchAlive; 

    public signal input citizenType;

    component witchPresentAndAlive = AND();
    witchPresentAndAlive.in[0] <== WitchPresent[citizenType];
    witchPresentAndAlive.in[1] <== WitchAlive[citizenType];

    component hh = HandHash();

    // TODO Assert?
    hh.out === ExpectedHash;
    witchPresentAndAlive.out === 0;
}

component main {public [ExpectedHash, WitchAlive, citizenType, citizenCount]} = NoWitch();