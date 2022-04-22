pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./HandUtils.circom"

// TODO Include the other logic stuff

template ValidMove() 
{
    signal input[4] CitizenCount;
    signal input[4] WitchPresent;

    signal input HandSalt;

    public signal input ExpectedHash;

    public signal input[4] WitchAlive; 

    public signal input citizenType;
    public signal input citizenCount;

    component hh = HandHash();
    // Todo Wire Up;

    component citizenCountCheck = GreaterThan(3);
    citizenCountCheck.in[0] <== CitizenCount[citizenType];
    citizenCountCheck.in[1] <== citizenCount;

    component witchPresentAndAlive = AND();
    witchPresentAndAlive.in[0] <== WitchPresent[citizenType];
    witchPresentAndAlive.in[1] <== WitchAlive[citizenType];

    component citizenOrWitch = OR();
    citizenOrWitch.in[0] <== citizenCountCheck.out;
    citizenOrWitch.in[1] <== witchPresentAndAlive.out;

    // TODO Assert?
    hh.out === ExpectedHash;
    citizenOrWitch.out === 1;
}

component main {public [ExpectedHash, WitchAlive, citizenType, citizenCount]} = ValidMove();
