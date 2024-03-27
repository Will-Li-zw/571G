// Import Web3 and any necessary types
import Web3, { Numbers } from "web3";
// import { AbiItem } from "web3-utils";
import { Card, CardImageMap, PoolProbMap, RewardMap } from "../types"; // Adjust the import path as necessary
// import "bn.js"
import { BigNumber } from "ethers";

// Setup your Web3 instance and contract
const web3 = new Web3("https://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH");
const contractABI = require('../artifacts/contracts/PyramidCards.sol/PyramidCards.json');
const contractAddress = "0x030C467a80c1F237c0621DbE62fb772C4c26C809";
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
        const userData:any = await contract.methods.getUserCollection(account).call({from:account});
        console.log("getUserCollection", account)
        console.log("getUserCollection", userData)
        const ids = userData[0].map((x: any)=>parseInt(x));
        const quantities = userData[1].map((x: any)=>parseInt(x));
        console.log("ids",ids)
        console.log("quantities",quantities)
        // Transform the arrays into the desired format
        const transformedData = ids.map((id: any, index: string | number) => ({
            id: parseInt(id),
            quantity: parseInt(quantities[index]),
        }));

        return transformedData

    } catch (error) {
        console.log(error)
        throw error;
    }
};
export const adminCreate = async (collectionName: string, awardName: string, probs: number[], urls: string[]): Promise<number[]> => {
    try {
        console.log(collectionName, awardName, probs, urls);

        // Request accounts and use the first one
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];

        // Encode the function call
        const data = contract.methods.createCollections(collectionName, awardName, probs, urls).encodeABI();

        // Estimate gas for the transaction
        const gasEstimate = await contract.methods.createCollections(collectionName, awardName, probs, urls).estimateGas({
            from: account,
        });

        // Get current gas price from the network
        const currentGasPrices = await ethereum.request({ method: 'eth_gasPrice' });

        // Set up transaction parameters
        const transactionParameters = {
            to: contract.options.address, // Ensure you're using the correct contract address accessor based on your web3 version
            from: account,
            gas: web3.utils.toHex(gasEstimate), // Convert gas estimate to hex
            gasPrice: web3.utils.toHex(currentGasPrices), // Use current gas price
            data: data, // Encoded function call
        };

        // Send the transaction
        const txHash = await ethereum.request({
            method: 'eth_sendTransaction',
            params: [transactionParameters],
        });
        const pollForPoolCreatedEvent = async (startTime: number, timeout: number) => {
            return new Promise((resolve, reject) => {
                const interval = setInterval(async () => {
                    const currentTime = new Date().getTime();
                    if (currentTime - startTime > timeout) {
                        console.log("Timeout reached, stopping event polling.");
                        clearInterval(interval);
                        reject(new Error("Event polling timed out."));
                    }
        
                    // Adjust fromBlock and toBlock as needed, depending on your network and expected transaction confirmation time
                    const events = await contract.getPastEvents('PoolCreated', {
                        fromBlock: 'latest',
                        toBlock: 'latest'
                    });
        
                    if (events.length > 0) {
                        console.log("Event found:", events);
                        clearInterval(interval);
                        resolve(events[0]); // Assuming you're interested in the first event found
                    }
                }, 5000); // Check every 5 seconds
            });
        };
        
        console.log("Transaction Hash:", txHash);
        const startTime = new Date().getTime();
        const timeout = 600000; // Set timeout (60 seconds in this example)
        const event:any = await pollForPoolCreatedEvent(startTime, timeout);

        // Handle event
        console.log('Event Details:', event.returnValues.ids);
        // return event.returnValues;
        // Since we cannot directly get the function return value from a transaction, we would need to watch for the transaction to be mined
        // and then use an event emitted by the contract (if available) to get the resultant IDs.
        // For this example, we're assuming you need to adapt this part based on your contract's events and how you're handling them.
        console.log('Collection creation initiated. Transaction Hash:', txHash);
        
        return event.returnValues.ids.map((id:any)=>parseInt(id)); // Placeholder return, adjust based on how you retrieve the result post-transaction.
    } catch (error) {
        console.error('Failed to create collection:', error);
        throw new Error('Failed to create collection');
    }
};

export const getAllCollections = async (): Promise<any> => {
    interface PoolData {
        id: number;
        prob: number;
    }
    try {
        console.log("getAllCollections")
        // Requesting the user's Ethereum account
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        
        // Destructuring the result into respective arrays
        const respond:any= await contract.methods.getAllCollections().call({from:account});
        // const respond = {0:['pool1', 'pool2', 'pool3'],1:[1, 2, 3, 3, 1, 2],2:[0.5, 0.5, 1, 0.3, 0.2, 0.5],3:[2, 1, 3]}
        // const {poolNameArray, idArray, probArray, lensArray }  = respond
        console.log("ALLCOLLECTION", respond);
        const poolNameArray = respond[0];
        const idArray = respond[1].map((x: any)=>parseInt(x));
        const probArray = respond[2].map((x: any)=>parseInt(x));
        const lensArray = respond[3].map((x: any)=>parseInt(x));
        let result: { [key: string]: PoolData[] } = {}; // This object will store the final structure
        let currentIndex = 0; // This will keep track of our current position in the idArray and probArray

        // Iterating through each pool name
        for (let i = 0; i < poolNameArray.length; i++) {
            const poolName = poolNameArray[i];
            const poolSize = lensArray[i]; // The number of records in the current pool
            const poolData = []; // This array will store the id and prob for the current pool

            // Iterating through the number of items in the current pool
            for (let j = 0; j < poolSize; j++) {
                poolData.push({
                    id: idArray[currentIndex + j],
                    prob: probArray[currentIndex + j],
                });
            }

            // Adding the current pool's data to the result object
            result[poolName] = poolData;

            // Updating currentIndex to move to the next set of ids and probs for the next pool
            currentIndex += poolSize;
        }
        console.log("getAllCollections",result)
        return result;
    } catch (error) {
        console.log(error);
        throw error;
    }
};
export const getAllRewards = async (): Promise<any> => {
    interface PoolData {
        id: number;
        quantity: number;
    }
    try {
        console.log("getAllRewards")
        // Requesting the user's Ethereum account
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        
        // Destructuring the result into respective arrays
        const respond:any= await contract.methods.getAllRewards({from:account}).call();
        const rewardNameArray = respond[0];
        const idArray = respond[1].map((x: any)=>parseInt(x));
        const quantityArray = respond[2].map((x: any)=>parseInt(x));
        const lensArray = respond[3].map((x: any)=>parseInt(x));
        let result: { [key: string]: PoolData[] } = {}; // This object will store the final structure
        let currentIndex = 0; // This will keep track of our current position in the idArray and probArray

        // Iterating through each pool name
        for (let i = 0; i < rewardNameArray.length; i++) {
            const rewardName = rewardNameArray[i];
            const poolSize = lensArray[i]; // The number of records in the current pool
            const poolData = []; // This array will store the id and prob for the current pool

            // Iterating through the number of items in the current pool
            for (let j = 0; j < poolSize; j++) {
                poolData.push({
                    id: idArray[currentIndex + j],
                    quantity: quantityArray[currentIndex + j],
                });
            }

            result[rewardName] = poolData;
            currentIndex += poolSize;
        }
        console.log("getAllRewards",result)
        return result;
    } catch (error) {
        console.log(error);
        throw error;
    }
};

export const getURLMap= async (): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const userData:any = await contract.methods.getAllURLs().call({from:account});
    const ids = userData[0].map((x: any)=>parseInt(x));
    const urls = userData[1];

    // Initialize an empty object to store the mapping
    let result: { [key: string]: string } = {};

    // Loop through the ids array and build the map
    ids.forEach((id: number, index:number) => {
    // Use the current id as the key and the corresponding url as the value
    result[id] = urls[index];
    });
    console.log("userRaw", userData);
    console.log("getURLMap", result);

    return result
    } catch (error) {
        console.log(error)
        throw error;
    }
};

export const drawCard = async (collection:string): Promise<number> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const drawnCard:any = await contract.methods.drawRandomCard(collection).call({ from: account });

    // Encode the function call
    const data = contract.methods.drawRandomCard(collection).encodeABI();

    // Estimate gas for the transaction
    const gasEstimate = await contract.methods.drawRandomCard(collection).estimateGas({
        from: account,
    });

    // Get current gas price from the network
    const currentGasPrices = await ethereum.request({ method: 'eth_gasPrice' });

    // Set up transaction parameters
    const transactionParameters = {
        to: contract.options.address, // Ensure you're using the correct contract address accessor based on your web3 version
        from: account,
        gas: web3.utils.toHex(gasEstimate), // Convert gas estimate to hex
        gasPrice: web3.utils.toHex(currentGasPrices), // Use current gas price
        data: data, // Encoded function call
    };

    // Send the transaction
    const txHash = await ethereum.request({
        method: 'eth_sendTransaction',
        params: [transactionParameters],
    });
    const pollForCardDrawEvent = async (startTime: number, timeout: number) => {
        return new Promise((resolve, reject) => {
            const interval = setInterval(async () => {
                const currentTime = new Date().getTime();
                if (currentTime - startTime > timeout) {
                    console.log("Timeout reached, stopping event polling.");
                    clearInterval(interval);
                    reject(new Error("Event polling timed out."));
                }
    
                // Adjust fromBlock and toBlock as needed, depending on your network and expected transaction confirmation time
                const events = await contract.getPastEvents('CardDraw', {
                    fromBlock: 'latest',
                    toBlock: 'latest'
                });
    
                if (events.length > 0) {
                    console.log("Event found:", events);
                    clearInterval(interval);
                    resolve(events[2]); // Assuming you're interested in the first event found
                }
            }, 5000); // Check every 5 seconds
        });
    };
    
    console.log("Transaction Hash:", txHash);
    const startTime = new Date().getTime();
    const timeout = 600000; // Set timeout (60 seconds in this example)
    const event:any = await pollForCardDrawEvent(startTime, timeout);
    console.log("DRAWCARD RESULT", event.returnValues.cardId)
    return parseInt(event.returnValues.id) // Placeholder return, adjust based on how you retrieve the result post-transaction.
} catch (error) {
    console.error('Failed to create collection:', error);
    throw new Error('Failed to create collection');
}
};





export const checkAdmin = async (): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    const result = await contract.methods.accountIsAdmin().call({ from: account });
    console.log("checkAdmine", result);
    return result
    // return parseInt(drawnCard)
    } catch (error) {
        
        console.log("Check Admine", error)
        throw error;
    }
};

export const redeemAward = async ( awardName: string): Promise<any> => {
    try {
        console.log("Start Redeem Award", awardName)
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];

        // Encode the function call
        const data = contract.methods.redeemAward( awardName).encodeABI();

        // Estimate gas for the transaction
        const gasEstimate = await contract.methods.redeemAward(awardName).estimateGas({
            from: account,
        });

        // Get current gas price from the network
        const currentGasPrices = await ethereum.request({ method: 'eth_gasPrice' });

        // Set up transaction parameters
        const transactionParameters = {
            to: contract.options.address, // Ensure you're using the correct contract address accessor based on your web3 version
            from: account,
            gas: web3.utils.toHex(gasEstimate), // Convert gas estimate to hex
            gasPrice: web3.utils.toHex(currentGasPrices), // Use current gas price
            data: data, // Encoded function call
        };

        // Send the transaction
        const txHash = await ethereum.request({
            method: 'eth_sendTransaction',
            params: [transactionParameters],
        });
        
        // return event.returnValues;
        // Since we cannot directly get the function return value from a transaction, we would need to watch for the transaction to be mined
        // and then use an event emitted by the contract (if available) to get the resultant IDs.
        // For this example, we're assuming you need to adapt this part based on your contract's events and how you're handling them.
        console.log('Award redeem initiated. Transaction Hash:', txHash);
        
        return txHash; // Placeholder return, adjust based on how you retrieve the result post-transaction.
    } catch (error) {
        console.error('Failed to create collection:', error);
        throw new Error('Failed to create collection');
    }
};

export const redeemChance = async ( id: number): Promise<any> => {
    try {
        console.log("Start Redeem Card", id)
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];

        // Encode the function call
        const data = contract.methods.redeemChance( id).encodeABI();

        // Estimate gas for the transaction
        const gasEstimate = await contract.methods.redeemChance(id).estimateGas({
            from: account,
        });

        // Get current gas price from the network
        const currentGasPrices = await ethereum.request({ method: 'eth_gasPrice' });

        // Set up transaction parameters
        const transactionParameters = {
            to: contract.options.address, // Ensure you're using the correct contract address accessor based on your web3 version
            from: account,
            gas: web3.utils.toHex(gasEstimate), // Convert gas estimate to hex
            gasPrice: web3.utils.toHex(currentGasPrices), // Use current gas price
            data: data, // Encoded function call
        };

        // Send the transaction
        const txHash = await ethereum.request({
            method: 'eth_sendTransaction',
            params: [transactionParameters],
        });
        console.log('Award redeem initiated. Transaction Hash:', txHash);
        
        return txHash; // Placeholder return, adjust based on how you retrieve the result post-transaction.
    } catch (error) {
        console.error('Failed to create collection:', error);
        throw new Error('Failed to create collection');
    }
};