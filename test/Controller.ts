import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";

describe("Controller", function () {
    
    // create asset params
    const initialSupply = 2000; // en tokens enteros
    const name = 'Propiedad 1';
    const symbol = 'PROP1';
    const asset_price = 10000; // USD enteros
    const maxLTV = 80;
    const liqThreshold = 75;
    const liqFeeProtocol = 5;
    const liqFeeSender = 10;
    const borrowThreshold = 10;
    const interestRate = 10;

    const transfer_to_otheraccount = 10000;
    const withdraw_to_otheraccount = 7000;
    const borrow_otheraccount = 7000;

    const chainlink_eth = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
    const chainlink_goerli = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

    const fake_smart_contract = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';
    

    async function deployContract() {
        const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
        const priceConsumer = await PriceConsumer.deploy(chainlink_goerli);

        const AssetFactory = await ethers.getContractFactory("AssetFactory");
        const assetFactory = await AssetFactory.deploy();

        const LendingBorrowingFactory = await ethers.getContractFactory("LendingBorrowingFactory");
        const lendingBorrowingFactory = await LendingBorrowingFactory.deploy();

        const Controller = await ethers.getContractFactory("Controller");
        const controller = await Controller.deploy(assetFactory.address, lendingBorrowingFactory.address, priceConsumer.address);

        const [owner, otherAccount, secondAccount] = await ethers.getSigners(); 

        return { priceConsumer, assetFactory, lendingBorrowingFactory, controller, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {controller} = await loadFixture(deployContract);
          expect(controller).to.not.empty;
      });
    });

    describe("Setings", function () {
        it("Should set smarts contracts used by the contract", async function () {
            const {controller} = await loadFixture(deployContract);

            await controller.setPriceConsumer(fake_smart_contract);
            await controller.setAssetFactory(fake_smart_contract);
            await controller.setLendingBorrowingFactory(fake_smart_contract);

            expect(await controller.assetFactory()).to.equal(fake_smart_contract);
            expect(await controller.lendingBorrowingFactory()).to.equal(fake_smart_contract);
            expect(await controller.priceConsumer()).to.equal(fake_smart_contract);
            
        });
      });
    

    describe("Create Asset and Protocol", function () {
        it("Should revert with Not enough Ether", async function () {
            const {controller} = await loadFixture(deployContract);

            const options = {value: ethers.utils.parseEther("0.05")};

            await expect(controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options)).to.be.revertedWith('Not enough Ether');
        });

        it("Should create asset and lending & borrowing protocol", async function () {
            const {controller, owner} = await loadFixture(deployContract);

            const options = {value: ethers.utils.parseEther("10.0")};

            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});

            let token;
            let protocol;

            if(event && event[0].args){
                token = event[0].args['token'];
                protocol = event[0].args['protocol'];
            } 

            const divisibleAsset = await ethers.getContractAt("DivisibleAsset", (await token));
            expect(await divisibleAsset.name()).to.equal('Propiedad 1');
            expect(await divisibleAsset.balanceOf(controller.address)).to.equal(BigNumber.from(initialSupply+"000000000000000000"));

            expect((await ethers.provider.getBalance(protocol))).to.equal(ethers.utils.parseEther("10.0"));

            const lendingBorrowing = await ethers.getContractAt("LendingBorrowing", (await protocol));
            expect(await lendingBorrowing.maxLTV()).to.equal(80);
        });
    });

    describe("Create Asset and Protocol", function () {
        it("Should revert with Not enough Ether", async function () {
            const {controller} = await loadFixture(deployContract);

            const options = {value: ethers.utils.parseEther("10.0")};

            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});

            let token;

            if(event && event[0].args){
                token = event[0].args['token'];
            }

            const options2 = {value: ethers.utils.parseEther("1")};
            
            await expect(controller.sellTokens(token, 1000000, options2)).to.be.revertedWith('Not enough Ether');
        });

        it("Should buy and get tokens", async function () {
            const {controller, otherAccount} = await loadFixture(deployContract);

            const options = {value: ethers.utils.parseEther("10.0")};

            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});

            let token;

            if(event && event[0].args){
                token = event[0].args['token'];
            }

            const options2 = {value: ethers.utils.parseEther("1")};

            await controller.connect(otherAccount).sellTokens(token, 1000, options2);

            const divisibleAsset = await ethers.getContractAt("DivisibleAsset", (await token));

            let balance = await divisibleAsset.balanceOf(otherAccount.address);

            expect(balance).to.equal(BigNumber.from(1000+"0000000000000000"));

        });
    });

    
});