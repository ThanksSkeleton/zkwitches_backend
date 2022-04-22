pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./HandUtils.circom"
// TODO Include the other logic stuff

template HandCommitment() 
{
    signal input[4] CitizenCount;
    signal input[4] WitchPresent;

    signal input HandSalt;

    signal output Hash;

    component hh = HandHash();
    // TODO Wire up
    component hv = HandValid();
    // TODO Wire up

    Hash <== hh.Hash;
}

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
//     // TODO Wire up
// 
//     oldhash.Hash === OldHash;
// 
//     component newCommitment = HandCommitment();
//     // TODO Wire up
// 
//     NewHash <== newCommitment.Hash;
// }
// Initial Commitment for Hand
component main {} = HandCommitment();