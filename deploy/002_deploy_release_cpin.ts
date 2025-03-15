import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { CPINToken } from '../typechain';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deployer } = await getNamedAccounts();

  const cpinToken: CPINToken = await ethers.getContract('CPINToken', deployer);

  await deployments.deploy('ReleaseCpin', {
    from: deployer,
    args: [
      deployer, // address owner_,
      cpinToken.address, // address cpin_token_,
      ethers.utils.parseEther('60000000'), // uint256 amount_,
      getEpoch('2024-04-15T12:00:00Z'), // uint64 startTime_,
      getEpoch('2024-05-15T12:00:00Z'), // uint64 cliffEndTime_,
      getEpoch('2025-02-09T12:00:00Z'), // uint64 endTime_,
      30 * 86400, // uint64 interval_
    ],
    log: true,
    autoMine: true,
  });
};

function getEpoch(dateStr: string) {
  return Math.floor(new Date(dateStr).valueOf() / 1000);
}

export default func;

func.id = 'deploy_release_cpin'; // id required to prevent reexecution
func.tags = ['ReleaseCpin'];
