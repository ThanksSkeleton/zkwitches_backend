module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
	
    const hcverifier = await deploy('', {
        from: deployer,
        contract: 'contracts/HandCommitment_verifier.sol:Verifier',
        log: true
    });
	const vmverifier = await deploy('', {
        from: deployer,
        contract:'contracts/ValidMove_verifier.sol:Verifier',
        log: true
    });
	const nwverifier = await deploy('', {
        from: deployer,
        contract:'contracts/NoWitch_verifier.sol:Verifier',
        log: true
    });
	
    await deploy('zkWitches', {
        from: deployer,
        log: true,
        args: [hcverifier.address, vmverifier.address, nwverifier.address]
    });
};
module.exports.tags = ['complete'];
