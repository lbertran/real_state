import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("LendingBorrowingFactory", function () {
    const ERC20_INITIALSUPLY = 100e10;
    const maxLTV = 80;
    const liqThreshold = 75;
    const liqFeeProtocol = 5;
    const liqFeeSender = 10;
    const borrowThreshold = 10;
    const interestRate = 10;

    const asset_price = 10000;
    const transfer_to_otheraccount = 10000;
    const withdraw_to_otheraccount = 7000;
    const borrow_otheraccount = 7000;
    
    const chainlink_eth = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
    const chainlink_goerli = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

    async function deployContract() {
        const LendingBorrowingFactory = await ethers.getContractFactory("LendingBorrowingFactory");
        const LendingBorrowing = await ethers.getContractFactory('LendingBorrowing');
        const lendingBorrowingFactory = await LendingBorrowingFactory.deploy();
        const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
        const priceConsumer = await PriceConsumer.deploy(chainlink_goerli);
        const AssetFactory = await ethers.getContractFactory("AssetFactory");
        const assetFactory = await AssetFactory.deploy();
        
        await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1',asset_price);
        const divisibleAsset = await ethers.getContractAt("DivisibleAsset", (await assetFactory._divisibleAssets(0)).token);

        const [owner, otherAccount, secondAccount] = await ethers.getSigners();
        
        return { lendingBorrowingFactory, priceConsumer, assetFactory, divisibleAsset, LendingBorrowing, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {lendingBorrowingFactory} = await loadFixture(deployContract);
          expect(lendingBorrowingFactory).to.not.empty;
          
      });
    });

    describe("Create LendingBorrowing instances", function () {
        it("Should create multiple LendingBorrowing and call its functions", async function () {
            const {lendingBorrowingFactory, priceConsumer, assetFactory, divisibleAsset} = await loadFixture(deployContract);

            const lendingBorrowing = await lendingBorrowingFactory.createLendingBorrowing(
                divisibleAsset.address,
                assetFactory.address,
                priceConsumer.address,
                maxLTV,
                liqThreshold,
                liqFeeProtocol,
                liqFeeSender,
                borrowThreshold,
                interestRate
            );

            expect(lendingBorrowing).to.not.empty;
        });

        it("Should create multiple LendingBorrowing and return collection", async function () {
            const {lendingBorrowingFactory, priceConsumer, assetFactory, divisibleAsset} = await loadFixture(deployContract);

            const lendingBorrowing = await lendingBorrowingFactory.createLendingBorrowing(
                divisibleAsset.address,
                assetFactory.address,
                priceConsumer.address,
                maxLTV,
                liqThreshold,
                liqFeeProtocol,
                liqFeeSender,
                borrowThreshold,
                interestRate
            );

            const lendingBorrowing1 = await lendingBorrowingFactory.createLendingBorrowing(
                divisibleAsset.address,
                assetFactory.address,
                priceConsumer.address,
                maxLTV,
                liqThreshold,
                liqFeeProtocol,
                liqFeeSender,
                borrowThreshold,
                interestRate
            );

            const protocolsArray = await lendingBorrowingFactory.allProtocols();
            expect(protocolsArray.length).to.equal(2);
        }); 
      });
});