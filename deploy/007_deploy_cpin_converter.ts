import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { IERC20 } from '../typechain';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deployer } = await getNamedAccounts();

  const cpin: IERC20 = await ethers.getContract('CPINToken', deployer);
  const cdata: IERC20 = await ethers.getContract('CDATAToken', deployer);
  const cwatt: IERC20 = await ethers.getContract('CWATTToken', deployer);

  await deployments.deploy('CpinConverter', {
    from: deployer,
    args: [
      cpin.address, // IERC20 _CPINToken,
      cdata.address, //IERC20 _CDATAToken,
      cwatt.address, //IERC20 _CWATTToken,
      1_000, //uint256 _cdataExchangeRate,
      10_000, //uint256 _cwattExchangeRate
    ],
    log: true,
    autoMine: true,
  });
};

export default func;

func.id = 'deploy_cpin_converter'; // id required to prevent reexecution
func.tags = ['CpinConverter'];
