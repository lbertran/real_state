import { artifacts, ethers, network } from "hardhat";
import path from "path";

async function main() { 

  const chainlink_eth = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
  const chainlink_goerli = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

  const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
  const priceConsumer = await PriceConsumer.deploy(chainlink_goerli);
  await priceConsumer.deployed();

  const AssetFactory = await ethers.getContractFactory("AssetFactory");
  const assetFactory = await AssetFactory.deploy();
  await assetFactory.deployed();

  const LendingBorrowingFactory = await ethers.getContractFactory("LendingBorrowingFactory");
  const lendingBorrowingFactory = await LendingBorrowingFactory.deploy();
  await lendingBorrowingFactory.deployed();

  const Controller = await ethers.getContractFactory("Controller");
  const controller = await Controller.deploy();
  await controller.deployed();

  saveFrontendFiles(priceConsumer, assetFactory, lendingBorrowingFactory, controller);

  console.log(await priceConsumer.getLatestPrice());
}

function saveFrontendFiles(priceConsumer: any, assetFactory: any, lendingBorrowingFactory: any, controller: any) {
  const fs = require("fs");
  const contractsDir = path.join(__dirname, "..", "frontend", "src", "contracts");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  // guarda las direcciones de los contratos

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify({ 
      PriceConsumer: priceConsumer.address,  
      AssetFactory: assetFactory.address,
      LendingBorrowingFactory: lendingBorrowingFactory.address,
      Controller: controller.address, 
    }, undefined, 2)
  );

  // guarda los artifacts y abis de los contratos
  
  const PriceConsumerArtifact = artifacts.readArtifactSync("PriceConsumer");

  fs.writeFileSync(
    path.join(contractsDir, "PriceConsumer.json"),
    JSON.stringify(PriceConsumerArtifact, null, 2)
  );

  const AssetFactoryArtifact = artifacts.readArtifactSync("AssetFactory");

  fs.writeFileSync(
    path.join(contractsDir, "AssetFactory.json"),
    JSON.stringify(AssetFactoryArtifact, null, 2)
  );

  const LendingBorrowingFactoryArtifact = artifacts.readArtifactSync("LendingBorrowingFactory");

  fs.writeFileSync(
    path.join(contractsDir, "LendingBorrowingFactory.json"),
    JSON.stringify(LendingBorrowingFactoryArtifact, null, 2)
  );

  const ControllerArtifact = artifacts.readArtifactSync("Controller");

  fs.writeFileSync(
    path.join(contractsDir, "Controller.json"),
    JSON.stringify(ControllerArtifact, null, 2)
  );

  const DivisibleAssetArtifact = artifacts.readArtifactSync("DivisibleAsset");

  fs.writeFileSync(
    path.join(contractsDir, "DivisibleAsset.json"),
    JSON.stringify(DivisibleAssetArtifact, null, 2)
  );

  const LendingBorrowingArtifact = artifacts.readArtifactSync("LendingBorrowing");

  fs.writeFileSync(
    path.join(contractsDir, "LendingBorrowing.json"),
    JSON.stringify(LendingBorrowingArtifact, null, 2)
  );

  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
