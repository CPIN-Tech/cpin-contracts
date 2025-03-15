import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction, DeployResult } from 'hardhat-deploy/types';
import { CpinVirtualPanel, CpinSppStaking } from '../typechain';
import exec from '../utils/exec';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deployer, tertiary } = await getNamedAccounts();

  const nft: CpinVirtualPanel = await ethers.getContract('CpinVirtualPanel', deployer);
  const cdata = await ethers.getContract('CDATAToken', deployer);
  const cwatt = await ethers.getContract('CWATTToken', deployer);

  const deployResult: DeployResult = await deployments.deploy('CpinSppStaking', {
    contract: 'CpinSppStaking',
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            deployer, // address defaultAdmin,
            nft.address, // ICpinVirtualPanel _nft,
            cdata.address, // IERC20 _CDATAToken,
            cwatt.address, // IERC20 _CWATTToken
          ],
        },
        /*onUpgrade: {
          methodName: 'initialize',
          args: [
            tokenAddress,
            tokenAddress,
          ],
        },*/
      },
    },
    log: true,
  });

  if (deployResult.newlyDeployed) {
    const sppStaking: CpinSppStaking = await ethers.getContract('CpinSppStaking', deployer);
    await exec('grant role', sppStaking.grantRole(await sppStaking.DATA_UPDATER_ROLE(), tertiary));
  }
};

export default func;

func.id = 'deploy_cpin_spp_staking'; // id required to prevent reexecution
func.tags = ['CpinSppStaking'];
