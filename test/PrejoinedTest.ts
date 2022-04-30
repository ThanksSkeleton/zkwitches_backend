import { expect } from "chai";
import chai = require("chai");

import { ethers } from "hardhat";
import * as fs from "fs";
import { ContractFactory, Contract } from "ethers";
import { Verifier as HCVerifier } from "../typechain-types/HandCommitment_verifier.sol";
import { Verifier as NWVerifier } from "../typechain-types/NoWitch_verifier.sol";
import { Verifier as VMVerifier } from "../typechain-types/ValidMove_verifier.sol";
import { ZkWitches  } from "../typechain-types/zkWitches.sol";
import chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);

describe("zkWitches Contract - Pre Joined Game", function () {

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
        await expect(hc_Verifier.verifyProof(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.be.eventually.true;
    }); 
	
	it("VMVerifier Verifies Correctly", async function() 
    {
        var vmcall_array = JSON.parse("[" + fs.readFileSync(vmcall) + "]");
        await expect(vm_Verifier.verifyProof(vmcall_array[0], vmcall_array[1], vmcall_array[2], vmcall_array[3])).to.be.eventually.true;
    }); 

	it("NWVerifier Verifies Correctly", async function() 
    {
        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");
        await expect(nw_Verifier.verifyProof(nwcall_array[0], nwcall_array[1], nwcall_array[2], nwcall_array[3])).to.be.eventually.true;
    }); 

	it("HC Verifier REJECTS incorrect proof", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");

        await expect(hc_Verifier.verifyProof(hccall_array[0], hccall_array[1], nwcall_array[2], hccall_array[3])).to.be.eventually.false;
    }); 
	
	// ZKWitches Contract Tests
	
	it("Can join new empty game", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        await expect(zkWitches.JoinGame(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.not.be.rejected;
    }); 
	
	it("Cannot Join with incorrect proof", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");

        await expect(zkWitches.JoinGame(hccall_array[0], hccall_array[1], nwcall_array[2], hccall_array[0][0])).to.be.rejected;
    }); 

	it("Cannot join the same game twice", async function() 
    {
        var hccall_array = JSON.parse("[" + fs.readFileSync(hccall) + "]");
        await expect(zkWitches.JoinGame(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.not.be.rejected;
        await expect(zkWitches.JoinGame(hccall_array[0], hccall_array[1], hccall_array[2], hccall_array[3])).to.be.rejected;
    }); 

    it("Empty Fetch TotalGameState", async function() 
    {
        await expect(zkWitches.GetTGS()).to.not.be.rejected;
    }); 

    it("TotalGameState Set and Fetch", async function() 
    {
        let inputTGS : ZkWitches.TotalGameStateStruct = {
            shared: {
                stateEnum: 1,
                playerSlotWaiting: 0,
                currentNumberOfPlayers: 0,
                playerAccusing: 0,
                accusationWitchType: 0,
                previous_action_game_block: 0,
                current_block: 0,
                current_sequence_number: 0
            },
            addresses: ["0x8ba1f109551bd432803012645ac136ddd64dba72","0x8ba1f109551bd432803012645ac136ddd64dba71","0x8ba1f109551bd432803012645ac136ddd64dba70", "0x8ba1f109551bd432803012645ac136ddd64dba69"],
            players: [
            {
                isAlive: false,
                handCommitment: 0,
                food: 0,
                lumber: 0,
                WitchAlive: [1,1,1,1]
            },
            {
                isAlive: false,
                handCommitment: 0,
                food: 0,
                lumber: 0,
                WitchAlive: [1,1,1,1]
            },
            {
                isAlive: false,
                handCommitment: 0,
                food: 0,
                lumber: 0,
                WitchAlive: [1,1,1,1]
            },
            {
                isAlive: false,
                handCommitment: 0,
                food: 0,
                lumber: 0,
                WitchAlive: [1,1,1,1]
            }
            ]
        };

        await expect(zkWitches.DEBUG_SetGameState(inputTGS)).to.not.be.rejected;
        await expect(zkWitches.GetTGS()).to.not.be.rejected;
        let fetched = await zkWitches.GetTGS();
        expect(fetched.shared.stateEnum).to.be.eq(1);
    }); 
});