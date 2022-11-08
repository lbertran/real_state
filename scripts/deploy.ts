import { ethers } from "hardhat";

async function main() {

  const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
  const priceConsumer = await PriceConsumer.deploy("0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e");

  await priceConsumer.deployed();

  console.log(await priceConsumer.getLatestPrice());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
