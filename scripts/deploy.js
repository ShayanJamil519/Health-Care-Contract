const hre = require("hardhat");

async function main() {
  const lock = await hre.ethers.deployContract("HealthcareDataTokenM");

  await lock.waitForDeployment();

  console.log(`HealthcareDataToken with  deployed to ${lock.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
