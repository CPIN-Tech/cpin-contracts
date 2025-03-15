import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  await deployments.deploy('CPINToken', {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });
};

export default func;

func.id = 'deploy_cpin_token'; // id required to prevent reexecution
func.tags = ['CpinToken'];
