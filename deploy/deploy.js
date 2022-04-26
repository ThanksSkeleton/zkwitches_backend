module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
	
    const hcverifier = await deploy('contracts/HandCommitment_verifier.sol:Verifier', {
        from: deployer,
        log: true
    });
	const vmverifier = await deploy('contracts/ValidMove_verifier.sol:Verifier', {
        from: deployer,
        log: true
    });
	const nwverifier = await deploy('contracts/NoWitch_verifier.sol:Verifier', {
        from: deployer,
        log: true
    });
	
    await deploy('zkWitches', {
        from: deployer,
        log: true,
        args: [hcverifier.address, vmverifier.address, nwverifier.address]
    });
};
module.exports.tags = ['complete'];
