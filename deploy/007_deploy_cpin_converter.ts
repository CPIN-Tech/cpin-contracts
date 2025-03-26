import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction, DeployResult } from 'hardhat-deploy/types';
import { ERC20, CpinConverter } from '../typechain';
import exec from '../utils/exec';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deployer } = await getNamedAccounts();

  const cdata: ERC20 = await ethers.getContract('CDATAToken', deployer);
  const cwatt: ERC20 = await ethers.getContract('CWATTToken', deployer);

  const deployResult: DeployResult = await deployments.deploy('CpinConverter', {
    from: deployer,
    args: [
      cdata.address, //IERC20 _CDATAToken,
      cwatt.address, //IERC20 _CWATTToken,
    ],
    log: true,
    autoMine: true,
  });

  if (deployResult.newlyDeployed) {
    const converter: CpinConverter = await ethers.getContract('CpinConverter', deployer);
    const cpin: ERC20 = await ethers.getContract('CPINToken', deployer);
    const peaq: ERC20 = await ethers.getContractAt(
      'ERC20',
      '0x0000000000000000000000000000000000000809',
      deployer
    );

    await exec('setCdataExchangeRate cpin', converter.setCdataExchangeRate(cpin.address, 1_000));
    await exec('setCwattExchangeRate cpin', converter.setCdataExchangeRate(cpin.address, 1_000));

    await exec('setCdataExchangeRate peaq', converter.setCdataExchangeRate(peaq.address, 10_000));
    await exec('setCwattExchangeRate peaq', converter.setCdataExchangeRate(peaq.address, 10_000));
  }
};

export default func;

func.id = 'deploy_cpin_converter'; // id required to prevent reexecution
func.tags = ['CpinConverter'];
