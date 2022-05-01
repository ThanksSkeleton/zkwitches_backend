import { expect } from "chai";
import chai = require("chai");

import { ethers } from "hardhat";
import * as fs from "fs";
import { ContractFactory, Contract, Signer } from "ethers";
import { Verifier as HCVerifier } from "../typechain-types/HandCommitment_verifier.sol";
import { Verifier as NWVerifier } from "../typechain-types/NoWitch_verifier.sol";
import { Verifier as VMVerifier } from "../typechain-types/ValidMove_verifier.sol";
import { ZkWitches } from "../typechain-types/zkWitches.sol";
import chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);

describe("zkWitches Contract - Joined Game", function () {

    let hc_Verifier: HCVerifier;
    let vm_Verifier: VMVerifier;
    let nw_Verifier: NWVerifier;
    let zkWitches: ZkWitches;

    // Players
    let p1 : Signer;
    let p2 : Signer;
    let p3 : Signer;
    let p4 : Signer;

    // Not a player
    let stranger : Signer;

    beforeEach(async function () {
        let fact = await ethers.getContractFactory("contracts/HandCommitment_verifier.sol:Verifier");
        hc_Verifier = await fact.deploy() as HCVerifier;
        await hc_Verifier.deployed();

        let fact2 = await ethers.getContractFactory("contracts/ValidMove_verifier.sol:Verifier"); 
        vm_Verifier = await fact2.deploy() as VMVerifier;
        await vm_Verifier.deployed();

        let fact3 = await ethers.getContractFactory("contracts/NoWitch_verifier.sol:Verifier"); 
        nw_Verifier = await fact3.deploy() as NWVerifier;
        await nw_Verifier.deployed();

        let fact4 = await ethers.getContractFactory("zkWitches");
        zkWitches = await fact4.deploy(hc_Verifier.address, vm_Verifier.address, nw_Verifier.address) as ZkWitches;
        await zkWitches.deployed();

        const [owner, px1, px2, px3, px4, px5] = await ethers.getSigners();
        p1 = px1;
        p2 = px2;
        p3 = px3;
        p4 = px4;
        stranger = px5;

        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        for(let player of [p1, p2, p3, p4]) 
        {
            await zkWitches.connect(player).JoinGame(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3]);
        }
        // balance = await signers[0].getBalance();
    });
	

    const hccall = "./circuits/build/HandCommitment/call.txt";
    const vmcall = "./circuits/build/ValidMove/call.txt";
    const nwcall = "./circuits/build/NoWitch/call.txt";

    it("Everyone can join", async function() 
    {
    });

    it("5th player cannot join", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        await expect(zkWitches.connect(stranger).JoinGame(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.be.rejected;
    });

    it("Player 1 can make an proof based action", async function() 
    {
        var vmcall_array = JSON.parse("[" + fs.readFileSync(vmcall) + "]");
        await expect(zkWitches.connect(p1).ActionWithProof(0,0, vmcall_array[0], vmcall_array[1], vmcall_array[2], vmcall_array[3])).to.not.be.rejected;        
    });

    it("Player 1 can make an normal action", async function() 
    {
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
    });
});