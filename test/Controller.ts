import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("LendingBorrowing", function () {
    
    // create asset params
    const initialSupply = 10;
    const name = 'Propiedad 1';
    const symbol = 'PROP1';
    const asset_price = 10000;
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

            const options = {value: ethers.utils.parseEther("0.5")};

            await expect(controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options)).to.be.revertedWith('Not enough Ether');
        });

        it("Should create asset and lending & borrowing protocol", async function () {
            const {controller, owner} = await loadFixture(deployContract);
			
            console.log(await ethers.provider.getBalance(owner.address));

            const options = {value: ethers.utils.parseEther("10.0")};

            const tx = await controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options);

            const result = await tx.wait();
            const event = result.events?.filter((x) => {return x.event == "AssetAndProtocolCreated"});

            if(event && event[0].args){
                let protocol = event[0].args['protocol'];
                console.log(await ethers.provider.getBalance(protocol));
                expect((await ethers.provider.getBalance(protocol))).to.equal(ethers.utils.parseEther("10.0"));
            } 

            

            
            
        });
        // 134487
        // 1344870.00
        // msg.value: 10000000000000000000
        // (msg.value / 1e16): 1000
        // value in usd: 13145.30
        // price_ : 10000.00
        // price_ / ETH_FACTOR: 100000

        1314530
        1314530

        /* it("Should create asset and lending & borrowing protocol", async function () {
            const {controller, owner} = await loadFixture(deployContract);
			
            const options = {value: ethers.utils.parseEther("10.0")};

            await expect(controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options)).to.emit(controller, "createAssetAndProtocolEvent");
        }); */
        
    });

    /*describe("Withdraw", function () {
        it("Should revert with Not enough collateral token in account", async function () {
            const {lendingBorrowing, otherAccount} = await loadFixture(deployContract);
            await expect(lendingBorrowing.connect(otherAccount).withdraw(10)).to.be.revertedWith('Not enough collateral token in account');
        });
        it("Should withdraw tokens yo account", async function () {
            const {lendingBorrowing, divisibleAsset, otherAccount} = await loadFixture(deployContract);   

            await divisibleAsset.transfer(otherAccount.address, transfer_to_otheraccount); 
            await divisibleAsset.connect(otherAccount).approve(lendingBorrowing.address, transfer_to_otheraccount);            
            await lendingBorrowing.connect(otherAccount).deposit(transfer_to_otheraccount);  

            await lendingBorrowing.connect(otherAccount).withdraw(withdraw_to_otheraccount);

            expect(await divisibleAsset.balanceOf(otherAccount.address)).to.equal(withdraw_to_otheraccount);

            expect(await divisibleAsset.balanceOf(lendingBorrowing.address)).to.equal(transfer_to_otheraccount-withdraw_to_otheraccount);

            expect((await lendingBorrowing.positions(otherAccount.address)).collateral).to.equal(transfer_to_otheraccount-withdraw_to_otheraccount);

            expect((await lendingBorrowing.positions(otherAccount.address)).lastInterest).to.equal((await ethers.provider.getBlock("latest")).timestamp);
        });
        
        
    });

    describe("Borrow", function () {
        it("Should revert with Amount must be > 0", async function () {
            const {lendingBorrowing, otherAccount} = await loadFixture(deployContract);
            await expect(lendingBorrowing.connect(otherAccount).borrow(0)).to.be.revertedWith('Amount must be > 0');
        });
        it("Should revert with Not enough collateral to borrow that much", async function () {
            const {lendingBorrowing, otherAccount} = await loadFixture(deployContract);
            await expect(lendingBorrowing.connect(otherAccount).borrow(transfer_to_otheraccount)).to.be.revertedWith('Not enough collateral to borrow that much');
        });
    });

    describe("Repay", function () {
        it("Should revert with Can't repay 0", async function () {
            const {lendingBorrowing, otherAccount} = await loadFixture(deployContract);
            await expect(lendingBorrowing.connect(otherAccount).repay(0)).to.be.revertedWith("Can't repay 0");
        });
        
    }); */
});