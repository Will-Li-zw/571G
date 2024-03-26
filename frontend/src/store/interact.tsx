// Import Web3 and any necessary types
import Web3, { Numbers } from "web3";
// import { AbiItem } from "web3-utils";
import { Card, CardImageMap, PoolProbMap, RewardMap } from "../types"; // Adjust the import path as necessary
// import "bn.js"
import { BigNumber } from "ethers";

// Setup your Web3 instance and contract
const web3 = new Web3("https://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH");
const contractABI = require('../artifacts/contracts/PyramidCards.sol/PyramidCards.json');
const contractAddress = "0x93156C2F37cD6d1a9D390257697CCe48228d3814";
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
        const timeout = 60000; // Set timeout (60 seconds in this example)
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

// export const adminCreate = async (collectionName:string, awardName: string,  probs: number[], urls:string[]): Promise<number[]> => {
//     try {
//         console.log(collectionName,awardName,probs,urls)

//         const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
//         const account = accounts[0];
//         const ids:any = await contract.methods.createCollections(collectionName, awardName, probs, urls).call({ from: account });
//         const result = ids.map((id:any)=> parseInt(id) )
//         console.log(result,"ADmin create IDS")
//         console.log('Award set successfully');
//         return result
//     } catch (error) {
//         console.error('Failed to set award:', error);
//         throw new Error('Failed to set award');
//     }
// };
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
        const idArray = respond[1];
        const probArray = respond[2];
        const lensArray = respond[3];
        console.log(poolNameArray)
        let result: { [key: string]: PoolData[] } = {}; // This object will store the final structure
        let currentIndex = 0; // This will keep track of our current position in the idArray and probArray

        // Iterating through each pool name
        for (let i = 0; i < poolNameArray.length; i++) {
            const poolName = poolNameArray[i];
            console.log(poolName)
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
        console.log("GETTTTTTTT",result)
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
        console.log("getAllCollections")
        // Requesting the user's Ethereum account
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        
        // Destructuring the result into respective arrays
        // const respond:any= await contract.methods.getAllCollections(account).call();
        const respond = {0:['Reward1', 'Reward2', 'Reward3'],1:[1, 2, 3, 3, 1, 2],2:[1, 1, 1, 10, 10, 10],3:[2, 1, 3]}
        // const {poolNameArray, idArray, probArray, lensArray }  = respond
        const rewardNameArray = respond[0];
        const idArray = respond[1];
        const quantityArray = respond[2];
        const lensArray = respond[3];
        console.log(rewardNameArray)
        let result: { [key: string]: PoolData[] } = {}; // This object will store the final structure
        let currentIndex = 0; // This will keep track of our current position in the idArray and probArray

        // Iterating through each pool name
        for (let i = 0; i < rewardNameArray.length; i++) {
            const rewardName = rewardNameArray[i];
            console.log(rewardName)
            const poolSize = lensArray[i]; // The number of records in the current pool
            const poolData = []; // This array will store the id and prob for the current pool

            // Iterating through the number of items in the current pool
            for (let j = 0; j < poolSize; j++) {
                poolData.push({
                    id: idArray[currentIndex + j],
                    quantity: quantityArray[currentIndex + j],
                });
            }

            // Adding the current pool's data to the result object
            result[rewardName] = poolData;

            // Updating currentIndex to move to the next set of ids and probs for the next pool
            currentIndex += poolSize;
        }
        console.log("GETTTTTTTT",result)
        return result;
    } catch (error) {
        console.log(error);
        throw error;
    }
};

// export const getAllRewards = async (): Promise<any> => {
//     try {
//     const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
//     const account = accounts[0];
//     // const rewards:any = await contract.methods.getAllRewards(account).call();
//     return {
//         'Reward1': [
//           { id: 1, quantity: 1 },
//           { id: 2, quantity: 1 },
//         ],
//         'Reward2': [
//           { id: 3, quantity: 1 },
//         ],
//         'Reward3': [
//           { id: 3, quantity: 10 },
//           { id: 1, quantity: 10 },
//           { id: 2, quantity: 10 },
  
//         ],
//         // ... other reward data
//       };
//     } catch (error) {
//         console.log(error)
//         throw error;
//     }
//     return 0;
// };

export const getURLMap= async (): Promise<any> => {
    try {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    const account = accounts[0];
    // const rewards:any = await contract.methods.getAllURLs().call({from:account});
    // const userData:any = await contract.methods.getAllURLs().call();
    // const ids = userData[0];
    // const urls = userData[1];
    // console.log("ids",ids)
    // console.log("urls",urls)
    // // Transform the arrays into the desired format
    // let result = {}
    // ids.map((id: number, index: string | number) => ({
    //     result[id] = 
    // }));
    // Assuming ids and urls are already defined as shown in your snippet:
    const userData = {0:[1,2,3],1:["https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg","a.jpg","a.jpg" ]}
    const ids = userData[0];
    const urls = userData[1];

    // Initialize an empty object to store the mapping
    let result: { [key: string]: string } = {};

    // Loop through the ids array and build the map
    ids.forEach((id, index) => {
    // Use the current id as the key and the corresponding url as the value
    result[id] = urls[index];
    });

    console.log(result);

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
        // console.log("WHY??????")
        
        console.log(error)
        throw error;
    }
    return 0;
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
    return 0;
};

