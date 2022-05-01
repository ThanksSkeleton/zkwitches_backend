import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import {parseEther} from 'ethers/lib/utils';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();
	
    const hcverifier = await deploy('', {
        from: deployer,
        contract: 'contracts/HandCommitment_verifier.sol:Verifier',
        log: true
    });

    console.log("Deploying vm");

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
export default func;
func.tags = ['zkWitches'];