import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("PriceConsumer", function () {

    const chainlink_eth = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
    const chainlink_goerli = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';
    

    async function deployContract() {
        const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
        const priceConsumer = await PriceConsumer.deploy(chainlink_goerli);
        
        return { priceConsumer };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {priceConsumer} = await loadFixture(deployContract);

          expect(priceConsumer).to.not.empty;
          
      });
      it("Should return ETH price in USD", async function () {
        const {priceConsumer} = await loadFixture(deployContract);

        console.log(await priceConsumer.getLatestPrice());

        expect(priceConsumer).to.not.empty;
    });
  });
  
});