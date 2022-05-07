import { expect } from "chai";
import chai = require("chai");

import { ethers } from "hardhat";
import * as fs from "fs";
import { ContractFactory, Contract, Signer } from "ethers";
import { Verifier as HCVerifier } from "../typechain-types/contracts/HandCommitment_verifier.sol";
import { Verifier as NWVerifier } from "../typechain-types/contracts/NoWitch_verifier.sol";
import { Verifier as VMVerifier } from "../typechain-types/contracts/ValidMove_verifier.sol";
import { ZkWitches } from "../typechain-types/contracts/zkWitches.sol";
import chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);
chai.config.includeStack = true;

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

        await AllJoin();

        // balance = await signers[0].getBalance();
    });
	
    async function AllJoin()
    {       
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
    }

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

    it("Players can go in order", async function() 
    {        
        let p_players : Signer[]= [p1, p2, p3, p4, p1];
        for (let i = 0; i< p_players.length; i++)
        {
            await expect(zkWitches.connect(p_players[i]).ActionNoProof(0,0,0)).to.not.be.rejected;        
        }
    });

    it("Players can't go out of order", async function() 
    {
        // Not their turns
        await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.be.rejected;
        await expect(zkWitches.connect(p3).ActionNoProof(0,0,0)).to.be.rejected;        
        // His turn
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
        // Now their turns
        await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.not.be.rejected;
        await expect(zkWitches.connect(p3).ActionNoProof(0,0,0)).to.not.be.rejected;  
    });

    it("3 Players can surrender and the game ends", async function() 
    {
        let p_surrenders : Signer[]= [p2, p3, p4];
        for (let i = 0; i< p_surrenders.length; i++)
        {
            await expect(zkWitches.connect(p_surrenders[i]).Surrender()).to.not.be.rejected;        
        }

        let tgs = await zkWitches.connect(p1).GetTGS();
        expect(tgs.shared.stateEnum).to.equal(0);   

        await expect(zkWitches.connect(p1).Surrender()).to.be.rejected;
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.be.rejected;          
    });

    it("Game continues when a player surrenders on their turn", async function() 
    {
        await expect(zkWitches.connect(p1).Surrender()).to.not.be.rejected;        
        await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.not.be.rejected;        
    });

    it("Game ends due to resources", async function() 
    {
        // They leave
        await expect(zkWitches.connect(p3).Surrender()).to.not.be.rejected;        
        await expect(zkWitches.connect(p4).Surrender()).to.not.be.rejected; 

        // start (2,2), (2,2)
        // both farm 8 food ((10, 2), (10, 2))
        for (let i = 0; i< 8; i++)
        {
            await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
            await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.not.be.rejected; 
        }

        // p1 farm 8 food, p2 gets 8 lumber ((18, 2), (10, 10))
        for (let i = 0; i< 8; i++)
        {
            await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
            await expect(zkWitches.connect(p2).ActionNoProof(1,0,0)).to.not.be.rejected; 
        }
        // p2 is the winner at the end of his turn

        let tgs = await zkWitches.connect(p1).GetTGS();        
        expect(tgs.shared.stateEnum).to.equal(0);
        
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.be.rejected;        
    });

    it("Witch Accusation Duel with events", async function() 
    {
        // They leave
        await expect(zkWitches.connect(p3).Surrender()).to.not.be.rejected;        
        await expect(zkWitches.connect(p4).Surrender()).to.not.be.rejected; 

        // Gather some resources
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
        await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.not.be.rejected; 
        await expect(zkWitches.connect(p1).ActionNoProof(1,0,0)).to.not.be.rejected;        
        await expect(zkWitches.connect(p2).ActionNoProof(1,0,0)).to.not.be.rejected; 
        // (3,3), (3,3)
        // I, p1, accuse p2 of having a farmer witch
        await expect(zkWitches.connect(p1).ActionNoProof(3,1,0)).to.not.be.rejected;   

        var nwcall_array = JSON.parse("[" + fs.readFileSync(nwcall) + "]");
        // I, p2 prove that I don't
        await expect(zkWitches.connect(p2).RespondAccusation_NoWitch(nwcall_array[0], nwcall_array[1], nwcall_array[2], nwcall_array[3])).to.not.be.rejected;

        // I, p2, accuse p1 of having a lumberjack witch
        await expect(zkWitches.connect(p2).ActionNoProof(3,0,1)).to.not.be.rejected;
        // I, p1, have to admit it.
        await expect(zkWitches.connect(p1).RespondAccusation_YesWitch()).to.not.be.rejected;   
   
        // Game Over.
        let tgs = await zkWitches.connect(p1).GetTGS();        
        expect(tgs.shared.stateEnum).to.equal(0);       
        
        // Check events
        let filter = zkWitches.filters.AccusationResponse(0);
        let accusationResponses = await zkWitches.queryFilter(filter);

        let p2_success_to_p1_accusation = accusationResponses.filter((v,i,a) => v.args.slot == 1);
        expect(p2_success_to_p1_accusation[0].args.innocent).to.be.true;

        let p1_fail_to_p2_accusation = accusationResponses.filter((v,i,a) => v.args.slot == 0);
        expect(p1_fail_to_p2_accusation[0].args.innocent).to.be.false;
    });

    it("Join Events", async function() 
    {
        let filter = zkWitches.filters.Join(0);
        let joinEvents = await zkWitches.queryFilter(filter);

        expect(joinEvents.length).equals(4);
    });

    it("Action Events", async function() 
    {
        await expect(zkWitches.connect(p1).ActionNoProof(0,0,0)).to.not.be.rejected;        
        await expect(zkWitches.connect(p2).ActionNoProof(0,0,0)).to.not.be.rejected;        

        let filter = zkWitches.filters.Action(0);
        let joinEvents = await zkWitches.queryFilter(filter);

        expect(joinEvents.length).equals(2);
    });

    it("Loss Event", async function() 
    {
        await expect(zkWitches.connect(p1).Surrender()).to.not.be.rejected;        

        let filter = zkWitches.filters.VictoryLoss(0);
        let joinEvents = await zkWitches.queryFilter(filter);

        expect(joinEvents.length).equals(1);
    });

    // uint8 constant LOSS_SURRENDER = 0;
    // uint8 constant LOSS_KICK = 1;
    // uint8 constant LOSS_INQUISITION = 2;
    // uint8 constant LOSS_RESOURCES = 3;
    // uint8 constant VICTORY_RESOURCES = 4;
    // uint8 constant VICTORY_ELIMINATED = 5;

    it("Two Games with events", async function() 
    {
        {
            await expect(zkWitches.connect(p1).Surrender()).to.not.be.rejected;        
            await expect(zkWitches.connect(p2).Surrender()).to.not.be.rejected;        
            await expect(zkWitches.connect(p3).Surrender()).to.not.be.rejected;        

            let filter = zkWitches.filters.VictoryLoss(0);
            let victoryLossEvents = await zkWitches.queryFilter(filter);

            expect(victoryLossEvents.length).equals(4);

            let expectedWinEvent = victoryLossEvents.filter((v,i,a) => v.args.victoryLossType == 5)[0];
            let expectedLossEvents = victoryLossEvents.filter((v,i,a) => v.args.victoryLossType == 0);

            expect(expectedWinEvent.args.slot).to.equal(3);
            expect(expectedLossEvents.length).to.equal(3);
        }

        // second game begins
        {
            await expect(AllJoin()).to.not.be.rejected;

            await expect(zkWitches.connect(p1).Surrender()).to.not.be.rejected;        
            await expect(zkWitches.connect(p2).Surrender()).to.not.be.rejected;

            await expect(zkWitches.connect(p4).Surrender()).to.not.be.rejected;        

            let filter = zkWitches.filters.VictoryLoss(1);
            let victoryLossEvents = await zkWitches.queryFilter(filter);

            expect(victoryLossEvents.length).equals(4);

            let expectedWinEvent = victoryLossEvents.filter((v,i,a) => v.args.victoryLossType == 5)[0];
            let expectedLossEvents = victoryLossEvents.filter((v,i,a) => v.args.victoryLossType == 0);

            expect(expectedWinEvent.args.slot).to.equal(2);
            expect(expectedLossEvents.length).to.equal(3);
        }
    });
});