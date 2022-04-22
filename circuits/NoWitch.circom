pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/mux2.circom";

include "./HandUtils.circom";

template NoWitch() 
{
	// private
    signal input CitizenCount[4];
    signal input WitchPresent[4];

    signal input HandSalt;

	// public
    signal input ExpectedHash;
    signal input WitchAlive[4]; 
    signal input citizenType;

	// convert citizenType to binary for the muxes
	component citizenTypeToBinary = Num2Bits(2);
	citizenTypeToBinary.in <== citizenType;

	// use MUXes to do array indexing 
	component WitchPresentMux = Mux2();
	WitchPresentMux.c[0] <== WitchPresent[0];
	WitchPresentMux.c[1] <== WitchPresent[1];
	WitchPresentMux.c[2] <== WitchPresent[2];
	WitchPresentMux.c[3] <== WitchPresent[3];

    WitchPresentMux.s[0] <== citizenTypeToBinary.out[0];
    WitchPresentMux.s[1] <== citizenTypeToBinary.out[1];

    // use MUXes to do array indexing 
	component WitchAliveMux = Mux2();
	WitchAliveMux.c[0] <== WitchAlive[0];
	WitchAliveMux.c[1] <== WitchAlive[1];
	WitchAliveMux.c[2] <== WitchAlive[2];
	WitchAliveMux.c[3] <== WitchAlive[3];

    WitchAliveMux.s[0] <== citizenTypeToBinary.out[0];
    WitchAliveMux.s[1] <== citizenTypeToBinary.out[1];

    component witchPresentAndAlive = AND();
    witchPresentAndAlive.a <== WitchPresentMux.out;
    witchPresentAndAlive.b <== WitchAliveMux.out;

    component hh = HandHash();
    hh.CitizenCount[0] <== CitizenCount[0];
    hh.CitizenCount[1] <== CitizenCount[1];
    hh.CitizenCount[2] <== CitizenCount[2];
    hh.CitizenCount[3] <== CitizenCount[3];

    hh.WitchPresent[0] <== WitchPresent[0];
    hh.WitchPresent[1] <== WitchPresent[1];
    hh.WitchPresent[2] <== WitchPresent[2];
    hh.WitchPresent[3] <== WitchPresent[3];

    hh.HandSalt <== HandSalt;

    hh.Hash === ExpectedHash;
    witchPresentAndAlive.out === 0;
}

component main {public [ExpectedHash, WitchAlive, citizenType, CitizenCount]} = NoWitch();