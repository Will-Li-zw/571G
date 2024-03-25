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
export async function addBalanceToContract( valueInEther: string, gasPrice = 'fast') {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    console.log("new Account", account)
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
            gasPriceAdjusted = (parseInt(currentGasPrices, 10) * 2).toString();
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
        throw error;
    }
}

export const getBalance = async (): Promise<number> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const myBalance:any = await contract.methods.getUserBalances(account).call();
    // console.log(parseInt(myBalance),"Inside Balance")
    return parseInt(myBalance);
    } catch (error) {
        console.log(error)
        throw error;
    }
};

export const getUserCollection = async (): Promise<{ id: number, quantity: number }[]> => {
    try {
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        const userData:any = await contract.methods.getUserCollection(account).call();
        const ids = userData[0];
        const quantities = userData[1];
        console.log("ids",ids)
        console.log("quantities",quantities)
        // Transform the arrays into the desired format
        const transformedData = ids.map((id: any, index: string | number) => ({
            id: parseInt(id),
            quantity: parseInt(quantities[index]),
        }));

        return [
              { id: 1, quantity: 30 },
              { id: 2, quantity: 22 },
              { id: 3, quantity: 11 },
            ];

    } catch (error) {
        console.log(error)
        throw error;
        return []; // Return an empty array in case of error
    }
};
export const adminCreate = async (collectionName:string, awardName: string,  probs: number[], urls:string[]): Promise<void> => {
    try {
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        await contract.methods.NNNNNNNNN(collectionName, awardName, probs, urls).call({ from: account });
        console.log('Award set successfully');
    } catch (error) {
        console.error('Failed to set award:', error);
        throw new Error('Failed to set award');
    }
};

export const getAllCollections = async (): Promise<any> => {
    try {
    console.log("getAllCollections")
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    // const collections:any = await contract.methods.getAllCollections(account).call();
    // console.log(parseInt(myBalance),"Inside Balance")
    return {
        'Pool1': [
          { id: 1, prob: 0.5 },
          { id: 2, prob: 0.3 },
          { id: 3, prob: 0.2 },
        ],
        'Pool2': [
          { id: 1, prob: 0.5 },
          { id: 3, prob: 0.5 },
        ],
        // ... other pool data
      };
    } catch (error) {
        console.log(error)
        throw error;
    }
    return 0;
};

export const getAllRewards = async (): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    // const rewards:any = await contract.methods.getAllRewards(account).call();
    return {
        'Reward1': [
          { id: 1, quantity: 1 },
          { id: 2, quantity: 1 },
        ],
        'Reward2': [
          { id: 3, quantity: 1 },
        ],
        'Reward3': [
          { id: 3, quantity: 10 },
          { id: 1, quantity: 10 },
          { id: 2, quantity: 10 },
  
        ],
        // ... other reward data
      };
    } catch (error) {
        console.log(error)
        throw error;
    }
    return 0;
};

export const getURLMap= async (): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    // const rewards:any = await contract.methods.getAllRewards(account).call();
    return {
        1:'https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg',
        2:'https://i.postimg.cc/fR41mGPj/194048-1710070848523b.jpg',
        3:'https://i.postimg.cc/rFTPp1RQ/TEC3-L07-N0965-lead-720x1280.png',
    }
    } catch (error) {
        console.log(error)
        throw error;
    }
    return 0;
};

export const drawCard = async (collection:string): Promise<number> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const drawnCard:any = await contract.methods.drawRandomCard(collection).call({ from: account });
    return parseInt(drawnCard)
    } catch (error) {
        console.log(error)
        throw error;
    }
    return 0;
};


export const redeemCard = async (id:number): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const response = await contract.methods.redeemChance(id).call({ from: account });
    console.log(response)
    // return parseInt(drawnCard)
    } catch (error) {
        console.log("WHY??????")
        
        console.log(error)
        throw error;
    }
    return 0;
};
