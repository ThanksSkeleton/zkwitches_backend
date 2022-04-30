import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import { ContractFactory, Contract } from "ethers";
import { Verifier as HCVerifier } from "../typechain-types/HandCommitment_verifier.sol";
import { Verifier as NWVerifier } from "../typechain-types/NoWitch_verifier.sol";
import { Verifier as VMVerifier } from "../typechain-types/ValidMove_verifier.sol";
import { ZkWitches } from "../typechain-types/zkWitches.sol";

/*
describe("Verifier Contract", function () {
    let Verifier;
    let verifier;

    beforeEach(async function () {
        Verifier = await ethers.getContractFactory("Verifier");
        verifier = await Verifier.deploy();
        await verifier.deployed();
    });

    it("Should return true for correct proofs", async function () {
        for (var i = 0; i < 16; i++) {
            var array = JSON.parse("[" + fs.readFileSync("./circuits/build/zkWitches/" + i.toString() + "/call.json") + "]");
            expect(await verifier.verifyProof(array[0], array[1], array[2], array[3])).to.be.true;
        }
    });
    it("Should return false for invalid proof", async function () {
        let a = [0, 0];
        let b = [[0, 0], [0, 0]];
        let c = [0, 0];
        let d = Array(65).fill(0);
        expect(await verifier.verifyProof(a, b, c, d)).to.be.false;
    });
});
*/
describe("zkWitches Contract2", function () {
    // let a = [];
    // let b = [];
    // let c = [];
    // let d = [];
    // let signers;
    // let balance;
    // let tx;

    // for (var i = 0; i < 16; i++) {
    //     var array = JSON.parse("[" + fs.readFileSync("./circuits/build/zkWitches/" + i.toString() + "/call.json") + "]");
    //     a.push(array[0]);
    //     b.push(array[1]);
    //     c.push(array[2]);
    //     d.push(array[3]);
    // };

    let hc_Verifier: HCVerifier;
    let vm_Verifier: VMVerifier;
    let nw_Verifier: NWVerifier;
    let zkWitches: ZkWitches;

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

        // signers = await ethers.getSigners();
        // balance = await signers[0].getBalance();
    });
	

    const hccall = "./circuits/build/HandCommitment/call.txt";
    const vmcall = "./circuits/build/ValidMove/call.txt";
    const nwcall = "./circuits/build/NoWitch/call.txt";

	// Basic Deployment

    it("Should be able to deploy", async function() 
    {
    });
	
	// Verifier Tests
	
	it("HCVerifier Verifies Correctly", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        expect(await hc_Verifier.verifyProof(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.be.true;
    }); 
	
	it("VMVerifier Verifies Correctly", async function() 
    {
        var vmcall_array = JSON.parse("[" + fs.readFileSync(vmcall) + "]");
        expect(await vm_Verifier.verifyProof(vmcall_array[0], vmcall_array[1], vmcall_array[2], vmcall_array[3])).to.be.true;
    }); 

	it("NWVerifier Verifies Correctly", async function() 
    {
        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");
        expect(await nw_Verifier.verifyProof(nwcall_array[0], nwcall_array[1], nwcall_array[2], nwcall_array[3])).to.be.true;
    }); 

	it("HC Verifier REJECTS incorrect proof", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");

        expect(await hc_Verifier.verifyProof(hccall_array[0], hccall_array[1], nwcall_array[2], hccall_array[3])).to.be.false;
    }); 
	
	// ZKWitches Contract Tests
	
	it("ZKWitches: can join new empty game", async function() 
    {
    }); 
	
	// a lot more needed.

});