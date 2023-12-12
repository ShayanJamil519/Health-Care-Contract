const hre = require("hardhat");
const { contractABI, contractAddress } = require("../constants");

async function interactWithContract() {
  // Connect to Ganache
  const ganacheProvider = new hre.ethers.JsonRpcProvider(
    "http://localhost:7545"
  );

  // Replace with your private key
  const privateKey =
    "0xdd388ef52890344bd50d0c08550b53386187686afb73b5f6b5335c1b71ac6380";
  const wallet = new ethers.Wallet(privateKey, ganacheProvider);

  // Create a contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  // Replace with your contract function parameters
  const dataHash = "0x7777";
  const name = "mydata";
  const price = ethers.parseEther("1");
  const isForSale = true;
  const expiration = Math.floor(Date.now() / 1000) + 3600;

  // Call your contract function
  const transaction = await contract.addHealthData(
    name,
    dataHash,
    price,
    expiration
  );

  console.log("Transaction hash:", transaction.hash);
  console.log("Waiting for the transaction to be mined...");

  // Wait for the transaction to be mined
  const receipt = await ganacheProvider.waitForTransaction(transaction.hash);

  console.log("Transaction mined in block:", receipt.blockNumber);
}

// Run the interaction script
// interactWithContract();
async function getWithContract() {
  // Connect to Ganache
  const ganacheProvider = new hre.ethers.JsonRpcProvider(
    "http://localhost:7545"
  );

  // Replace with your private key
  const privateKey =
    "0xdd388ef52890344bd50d0c08550b53386187686afb73b5f6b5335c1b71ac6380";
  const wallet = new ethers.Wallet(privateKey, ganacheProvider);

  // Create a contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  const transaction = await contract.getAllMyMarketRecords();
  console.log("Transaction details:", transaction);
}

// Run the interaction script
getWithContract();
