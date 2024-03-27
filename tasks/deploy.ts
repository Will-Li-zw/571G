import '@nomiclabs/hardhat-waffle';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import * as dotenv from 'dotenv';


dotenv.config();
const vrfCoordinatorV2 = process.env.COR_ADDRESS || '';
const subscriptionId = process.env.SUB_ID || '';
const callBackGasLimit = "1000000" || '';
const gasLane = process.env.GAS_LANE || '';

task('deploy', 'Deploy Greeter contract').setAction(
  async (_, hre: HardhatRuntimeEnvironment): Promise<void> => {
    
    const Pyramid = await hre.ethers.getContractFactory('PyramidCards');
    const pyramid = await Pyramid.deploy(vrfCoordinatorV2, gasLane, subscriptionId, callBackGasLimit);
    
    await pyramid.deployed();

    console.log('Pyramid deployed to:', pyramid.address);
  }
);
