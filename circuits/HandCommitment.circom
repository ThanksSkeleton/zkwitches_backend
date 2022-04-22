pragma circom 2.0.0;

include "./HandUtils.circom";

template HandCommitment() 
{
    signal input CitizenCount[4];
    signal input WitchPresent[4];

    signal input HandSalt;

    signal output Hash;

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

    component hv = HandValid();
    hv.CitizenCount[0] <== CitizenCount[0];
    hv.CitizenCount[1] <== CitizenCount[1];
    hv.CitizenCount[2] <== CitizenCount[2];
    hv.CitizenCount[3] <== CitizenCount[3];

    hv.WitchPresent[0] <== WitchPresent[0];
    hv.WitchPresent[1] <== WitchPresent[1];
    hv.WitchPresent[2] <== WitchPresent[2];
    hv.WitchPresent[3] <== WitchPresent[3];

    Hash <== hh.Hash;
}

// TODO: Mechanic to reconfigure your hand 

// template HandSwap()
// {
//     signal input[4] OldCitizenCount;
//     signal input[4] NewCitizenCount;
// 
//     signal input[4] WitchPresent;
// 
//     signal input HandSalt;
// 
//     public signal input OldHash;
// 
//     signal output NewHash;
// 
//     component oldhash = HandHash();
// 
//     oldhash.Hash === OldHash;
// 
//     component newCommitment = HandCommitment();
// 
//     NewHash <== newCommitment.Hash;
// }
// Initial Commitment for Hand

component main = HandCommitment();