const hre = require("hardhat");

async function main() {
  const lock = await hre.ethers.deployContract("HealthcareDataToken");

  await lock.waitForDeployment();

  console.log(`HealthcareDataToken  deployed to ${lock.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
