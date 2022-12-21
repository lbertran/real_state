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

        const LendingBorrowing = await ethers.getContractFactory("LendingBorrowing");
        const lendingBorrowing = await LendingBorrowing.deploy(assetFactory.address, priceConsumer.address);

        const Controller = await ethers.getContractFactory("Controller");
        const controller = await Controller.deploy(assetFactory.address, lendingBorrowing.address, priceConsumer.address);

        const [owner, otherAccount, secondAccount] = await ethers.getSigners(); 

        return { priceConsumer, assetFactory, lendingBorrowing, controller, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {controller} = await loadFixture(deployContract);
          expect(controller).to.not.empty;
      });
    });

    describe("Settings", function () {
        it("Should set smarts contracts used by the contract", async function () {
            const {controller} = await loadFixture(deployContract);

            await controller.setPriceConsumer(fake_smart_contract);
            await controller.setAssetFactory(fake_smart_contract);
            await controller.setLendingBorrowing(fake_smart_contract);

            expect(await controller.assetFactory()).to.equal(fake_smart_contract);
            expect(await controller.lendingBorrowing()).to.equal(fake_smart_contract);
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
            const {controller, lendingBorrowing} = await loadFixture(deployContract);

            /* const balanceLB = await ethers.provider.getBalance(lendingBorrowing.address);
            console.log('balanceLB: ', balanceLB);*/
            
            const options = {value: ethers.utils.parseEther("10.0")};

            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});

            let token;
            let protocol;

            if(event && event[0].args){
                token = event[0].args['token'];
            } 

            const divisibleAsset = await ethers.getContractAt("DivisibleAsset", (await token));
            expect(await divisibleAsset.name()).to.equal('Propiedad 1');
            expect(await divisibleAsset.balanceOf(controller.address)).to.equal(BigNumber.from(initialSupply+"000000000000000000"));

            const balanceLBNew = await ethers.provider.getBalance(lendingBorrowing.address);
            expect(balanceLBNew).to.equal(ethers.utils.parseEther("10.0"));
            //console.log('balanceLBNew: ', balanceLBNew);
        });
    });

    describe("Buy tokens and claims", function () {
        it("Buy tokens should revert with Not enough Ether", async function () {
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
            
            await expect(controller.buyTokens(token, 1000000, options2)).to.be.revertedWith('Not enough Ether');
        });
        
        it("Should buy and get tokens", async function () {
            const {controller, assetFactory, otherAccount} = await loadFixture(deployContract);

            /* const balanceController = await ethers.provider.getBalance(controller.address);
            console.log('balanceController: ', balanceController); */

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }

            // otheraccount buy tokens
            const options2 = {value: ethers.utils.parseEther("1")};
            await controller.connect(otherAccount).buyTokens(token, 1000, options2);
            const divisibleAsset = await ethers.getContractAt("DivisibleAsset", (await token));

            // otheraccount token balance
            let balance = await divisibleAsset.balanceOf(otherAccount.address);
            expect(balance).to.equal(BigNumber.from(1000+"0000000000000000"));

            // controller eth balance
            const balanceControllerNew = await ethers.provider.getBalance(controller.address);
            expect(balanceControllerNew).to.equal(ethers.utils.parseEther("1"));

        });

        it("Claim tokens sales should revert with Caller is not the token creator", async function () {
            const {controller, owner, otherAccount} = await loadFixture(deployContract);

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }
            
            const balanceOwner = await ethers.provider.getBalance(owner.address);
            //console.log('balanceOwner: ', balanceOwner); 
            
            // otheraccount buy tokens
            const options2 = {value: ethers.utils.parseEther("1")};
            await controller.connect(otherAccount).buyTokens(token, 1000, options2);
            
            // claims token sales
            await expect(controller.connect(otherAccount).claimTokensSales(token)).to.be.revertedWith('Caller is not the token creator');

        });

        it("Should claim tokens sales", async function () {
            const {controller, owner, otherAccount} = await loadFixture(deployContract);

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }
            
            const balanceOwner = await ethers.provider.getBalance(owner.address);
            //console.log('balanceOwner: ', balanceOwner); 
            
            // otheraccount buy tokens
            const options2 = {value: ethers.utils.parseEther("1")};
            await controller.connect(otherAccount).buyTokens(token, 1000, options2);
            
            // claims token sales
            await controller.claimTokensSales(token); 
            
            // owner eth balance
            const balanceOwnerNew = await ethers.provider.getBalance(owner.address);
            //console.log('balanceOwnerNew: ', balanceOwnerNew); 
            expect(balanceOwnerNew).to.greaterThan(balanceOwner.add(ethers.utils.parseEther("0.9")));
        });

        it("Claim initial values should revert with Caller is not the token creator", async function () {
            const {controller, otherAccount} = await loadFixture(deployContract);

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }
            
            await expect(controller.connect(otherAccount).claimInitialValue(token)).to.be.revertedWith('Caller is not the token creator');
        });

        it("Claim initial values should revert with Value is not claimable", async function () {
            const {controller, otherAccount} = await loadFixture(deployContract);

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }
            
            await expect(controller.claimInitialValue(token)).to.be.revertedWith('Value is not claimable');
        });

        it("Claim initial values", async function () {
            const {controller, owner, otherAccount} = await loadFixture(deployContract);

            // asset and tokens are created
            const options = {value: ethers.utils.parseEther("10.0")};
            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);
            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});
            let token;
            if(event && event[0].args){
                token = event[0].args['token'];
            }
            
            // otheraccount buy 100% tokens
            const options2 = {value: ethers.utils.parseEther("100")};
            await controller.connect(otherAccount).buyTokens(token, 200000, options2);

            // claims initial values
            const balanceOwner = await ethers.provider.getBalance(owner.address);
            await controller.claimInitialValue(token);
            const balanceOwnerNew = await ethers.provider.getBalance(owner.address);
            console.log('balanceOwner',balanceOwner);
            console.log('balanceOwnerNew',balanceOwnerNew);
            
            // #TODO: enviar el ETH desde el protocolo de L&B
        });
    });

    
});