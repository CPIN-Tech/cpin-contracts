import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction, DeployResult } from 'hardhat-deploy/types';
import { CpinVirtualPanel, CpinBuyPanel, ERC20 } from '../typechain';
import exec from '../utils/exec';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deployer } = await getNamedAccounts();

  const nft: CpinVirtualPanel = await ethers.getContract('CpinVirtualPanel', deployer);
  // const cpin = await ethers.getContract('CPINToken', deployer);
  const peaq: ERC20 = await ethers.getContractAt(
    'ERC20',
    '0x0000000000000000000000000000000000000809',
    deployer
  );
  const usdc: ERC20 = await ethers.getContractAt(
    'ERC20',
    '0xbbA60da06c2c5424f03f7434542280FCAd453d10',
    deployer
  );
  const usdt: ERC20 = await ethers.getContractAt(
    'ERC20',
    '0xd8cF92E9B6Fae6B32f795AcB11Edd50E8dD6Ff4d',
    deployer
  );

  const deployResult: DeployResult = await deployments.deploy('CpinBuyPanel', {
    contract: 'CpinBuyPanel',
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [deployer, nft.address],
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
    const buyPanel: CpinBuyPanel = await ethers.getContract('CpinBuyPanel', deployer);

    await exec(
      'set price as PEAQ',
      buyPanel.updatePrice(peaq.address, ethers.utils.parseUnits('50', await peaq.decimals()))
    );
    await exec(
      'set price as USDC',
      buyPanel.updatePrice(usdc.address, ethers.utils.parseUnits('5', await usdc.decimals()))
    );
    await exec(
      'set price as USDT',
      buyPanel.updatePrice(usdt.address, ethers.utils.parseUnits('5', await usdt.decimals()))
    );

    await exec('set buyPanel as minter', nft.grantRole(await nft.MINTER_ROLE(), buyPanel.address));
  }
};

export default func;

func.id = 'deploy_cpin_buy_panel'; // id required to prevent reexecution
func.tags = ['CpinBuyPanel'];
