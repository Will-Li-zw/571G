# Pyramid Project

Step1.1 Deploy your own contract on Sepolia
Remember to add .env file at the root directory
```shell
# ETHERSCAN_API_KEY=<ETHERSCAN_API_KEY>
SEPOLIA_API_URL = "https://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH"
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
Copy paste the generated block chain adress to contractAddress in interact.tsx

Step1.2 Use existed contract
```shell
nvm use 18
yarn
yarn hardhat compile
```

Step2
Then enter frontend and run web app

```shell
cd frontend
nvm use 18
yarn
yarn start
```
