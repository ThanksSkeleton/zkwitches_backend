const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const tokenURI = require("./token.json");
const { toHex } = require("web3-utils");
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
describe("zkWitches Contract", function () {
    let zkWitches;
    let zkWitches;
    let a = [];
    let b = [];
    let c = [];
    let d = [];
    let signers;
    let balance;
    let tx;

    for (var i = 0; i < 16; i++) {
        var array = JSON.parse("[" + fs.readFileSync("./circuits/build/zkWitches/" + i.toString() + "/call.json") + "]");
        a.push(array[0]);
        b.push(array[1]);
        c.push(array[2]);
        d.push(array[3]);
    };

    beforeEach(async function () {
        let Verifier = await ethers.getContractFactory("Verifier");
        let verifier = await Verifier.deploy();
        await verifier.deployed();
        zkWitches = await ethers.getContractFactory("zkWitches");
        zkWitches = await zkWitches.deploy(verifier.address);
        await zkWitches.deployed();

        signers = await ethers.getSigners();
        balance = await signers[0].getBalance();

        // let txn = await zkWitches.mint(tokenURI.name, tokenURI.description, tokenURI.image, a, b, c, d);
        // tx = await txn.wait();
    });
});