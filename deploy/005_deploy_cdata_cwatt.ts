import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  await deployments.deploy('CDATAToken', {
    from: deployer,
    args: [deployer],
    log: true,
    autoMine: true,
  });

  await deployments.deploy('CWATTToken', {
    from: deployer,
    args: [deployer],
    log: true,
    autoMine: true,
  });
};

export default func;

func.id = 'deploy_cdata_cwatt'; // id required to prevent reexecution
func.tags = ['CdataCwattTokens'];
