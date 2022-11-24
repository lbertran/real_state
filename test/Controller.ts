import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("LendingBorrowing", function () {
    const ERC20_INITIALSUPLY = 100e10;
    const maxLTV = 80;
    const liqThreshold = 75;
    const liqFeeProtocol = 5;
    const liqFeeSender = 10;
    const borrowThreshold = 10;
    const interestRate = 10;

    const initialSupply = 10;
    const name = 'Propiedad 1';
    const symbol = 'PROP1';
    const asset_price = 10000;
    const transfer_to_otheraccount = 10000;
    const withdraw_to_otheraccount = 7000;
    const borrow_otheraccount = 7000;

    const chainlink_eth = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
    const chainlink_goerli = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';
    

    async function deployContract() {
        const PriceConsumer = await ethers.getContractFactory("PriceConsumer");
        const priceConsumer = await PriceConsumer.deploy(chainlink_goerli);

        const AssetFactory = await ethers.getContractFactory("AssetFactory");
        const assetFactory = await AssetFactory.deploy();

        const LendingBorrowingFactory = await ethers.getContractFactory("LendingBorrowingFactory");
        const lendingBorrowingFactory = await LendingBorrowingFactory.deploy();

        const Controller = await ethers.getContractFactory("Controller");
        const controller = await Controller.deploy();

        await controller.setPriceConsumer(priceConsumer.address);
        await controller.setAssetFactory(assetFactory.address);
        await controller.setLendingBorrowingFactory(lendingBorrowingFactory.address);
        
        await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1',asset_price);

        const [owner, otherAccount, secondAccount] = await ethers.getSigners(); 

        return { priceConsumer, assetFactory, lendingBorrowingFactory, controller, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {controller} = await loadFixture(deployContract);

          expect(controller).to.not.empty;
      });
    });
    
    describe("Create Asset and Protocol", function () {
        it("Should revert with Not enough Ether", async function () {
            const {controller} = await loadFixture(deployContract);

            await expect(controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate)).to.be.revertedWith('Not enough Ether');
        });

        it("Should create asset and lending & borrowing protocol", async function () {
            const {controller, owner} = await loadFixture(deployContract);
			
            const options = {value: ethers.utils.parseEther("10.0")};

            await expect(controller.createAssetAndProtocol(initialSupply, name, symbol, asset_price, maxLTV, liqThreshold, liqFeeProtocol, liqFeeSender, borrowThreshold, interestRate, options)).to.emit(controller, "createAssetAndProtocolEvent");
        });
        
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