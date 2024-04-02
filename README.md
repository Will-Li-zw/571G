# Pyramid Project
## Start From our existing contract
Step1. Use existed contract
```shell
nvm use 18
yarn
forge compile
yarn hardhat compile
```

Step2. Then enter frontend directory and run web app
```shell
cd frontend
nvm use 18
yarn
yarn start
```

## Start From Deploy Your Own Contract
Step1 Deploy your own contract on Sepolia
Remember to add .env file at the root directory
```shell
# ETHERSCAN_API_KEY=<ETHERSCAN_API_KEY>
SEPOLIA_API_URL = "Your SEPOLIA Provider API KEY"
SEPOLIA_PRIVATE_KEY = "Replace with your private key"
SUB_ID = "10299"
COR_ADDRESS = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625"
GAS_LANE = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c"
```

```shell
nvm use 18
yarn
yarn hardhat compile
yarn hardhat deploy --network sepolia
```
Copy&paste the logged on-chain address to the variable contractAddress in interact.tsx  
Add the logged address to your registered VRF account [VRFChainlink](https://vrf.chain.link/) to add it as a consumer to utilize the off-chain randomness function provided by Chainlink

Step2. Then enter frontend directory and run web app
```shell
cd frontend
nvm use 18
yarn
yarn start
```



