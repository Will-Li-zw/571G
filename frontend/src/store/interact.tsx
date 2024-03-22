// Import Web3 and any necessary types
import Web3, { Numbers } from "web3";
// import { AbiItem } from "web3-utils";
import { Card, CardImageMap, PoolProbMap, RewardMap } from "../types"; // Adjust the import path as necessary
// import "bn.js"
import { BigNumber } from "ethers";

// Setup your Web3 instance and contract
const web3 = new Web3("wss://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH");
const contractABI = require('../artifacts/contracts/PyramidCards.sol/PyramidCards.json');
const contractAddress = "0xf40d8321601154fF589e174a98Eaf598b675BD0a";
const contract = new web3.eth.Contract(contractABI.abi, contractAddress);
declare let ethereum: any;
export async function addBalanceToContract(account: any, valueInEther: string, gasPrice = 'fast') {
    const valueInWei = web3.utils.toWei(valueInEther, 'ether');
    const gasLimitEstimate = await contract.methods.addBalance().estimateGas({
        from: account,
        value: valueInWei,
    });
    // Adjust gas price based on current network conditions and desired transaction speed
    const currentGasPrices = await ethereum.request({
        method: 'eth_gasPrice',
    });
    let gasPriceAdjusted;
    switch (gasPrice) {
        case 'slow':
            gasPriceAdjusted = (parseInt(currentGasPrices, 10) * 0.75).toString();
            break;
        case 'average':
            gasPriceAdjusted = currentGasPrices;
            break;
        case 'fast':
            gasPriceAdjusted = (parseInt(currentGasPrices, 10) * 1.25).toString();
            break;
        default:
            gasPriceAdjusted = currentGasPrices;
            break;
    }

    const transactionParameters = {
        to: contract.options.address, // Ensure you're using the correct contract address accessor based on your web3 version
        from: account,
        value: parseInt(valueInWei).toString(16),
        gas: web3.utils.toHex(gasLimitEstimate), // Using the estimated gas limit
        gasPrice: web3.utils.toHex(gasPriceAdjusted), // Adjusted gas price
        data: contract.methods.addBalance().encodeABI(),
    };

    try {
        const txHash = await ethereum.request({
            method: 'eth_sendTransaction',
            params: [transactionParameters],
        });

        console.log("Transaction Hash:", txHash);
        return txHash;
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

export const getBalance = async (account:string): Promise<number> => {
    try {
    const myBalance:any = await contract.methods.getUserBalances(account).call();
    // console.log(parseInt(myBalance),"Inside Balance")
    return parseInt(myBalance);
    } catch (error) {
        console.log(error)
    }
    return 0;
};

export const getUserCollection = async (account: string): Promise<{ id: number, quantity: number }[]> => {
    try {
        const userData:any = await contract.methods.getUserCollection(account).call();

        // Assuming userData is like: [[1, 2, 3], [30, 22, 11]]
        const ids = userData[0];
        const quantities = userData[1];
        console.log("ids",ids)
        console.log("quantities",quantities)
        // Transform the arrays into the desired format
        const transformedData = ids.map((id: any, index: string | number) => ({
            id: parseInt(id),
            quantity: parseInt(quantities[index]),
        }));

        return transformedData;

    } catch (error) {
        console.log(error)
        return []; // Return an empty array in case of error
    }
};


// export const fetchUserData = async (userAddress: string): Promise<{ remainingDraws: number; collection: Card[] }> => {
//   const data = await contract.methods.getUserData(userAddress).call();
//   return {
//     remainingDraws: data.remainingDraws,
//     collection: data.collection.map((item: any) => ({ id: item.id, quantity: item.quantity })),
//   };
// };

// export const fetchCardImageMap = async (): Promise<CardImageMap> => {
//   const data = await contract.methods.getCardImageMap().call();
//   let result: CardImageMap = {};
//   for (const [id, url] of Object.entries(data)) {
//     result[id] = url;
//   }
//   return result;
// };

// export const fetchPoolData = async (): Promise<PoolProbMap> => {
//   const data = await contract.methods.getPoolData().call();
//   let result: PoolProbMap = {};
//   for (const [poolName, poolData] of Object.entries(data)) {
//     result[poolName] = poolData.map((item: any) => ({ id: item.id, prob: item.prob }));
//   }
//   return result;
// };

// export const fetchRewardData = async (): Promise<RewardMap> => {
//   const data = await contract.methods.getRewardData().call();
//   let result: RewardMap = {};
//   for (const [rewardName, rewardData] of Object.entries(data)) {
//     result[rewardName] = rewardData.map((item: any) => ({ id: item.id, quantity: item.quantity }));
//   }
//   return result;
// };
