const hre = require("hardhat");

async function main() {
  const lockedAmount = hre.ethers.parseEther("0.001");

  const lock = await hre.ethers.deployContract()

  await lock.waitForDeployment();

  console.log("Lock deployed to:", lock.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
