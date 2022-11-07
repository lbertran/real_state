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
    const borrowThreshold = 10000000;
    const interestRate = 10;

    const transfer_to_otheraccount = 10000;
    

    async function deployContract() {
        const DivisibleAsset = await ethers.getContractFactory("DivisibleAsset");
        const divisibleAsset = await DivisibleAsset.deploy(ERC20_INITIALSUPLY, 'Asset1', 'A1');

        const LendingBorrowing = await ethers.getContractFactory("LendingBorrowing");
        const lendingBorrowing = await LendingBorrowing.deploy(
            divisibleAsset.address,
            maxLTV,
            liqThreshold,
            liqFeeProtocol,
            liqFeeSender,
            borrowThreshold,
            interestRate
        );
        
        const [owner, otherAccount, secondAccount] = await ethers.getSigners();

        await divisibleAsset.transfer(otherAccount.address, transfer_to_otheraccount);    
        
        return { lendingBorrowing, owner, otherAccount, secondAccount, divisibleAsset };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {lendingBorrowing, divisibleAsset} = await loadFixture(deployContract);

          expect(await lendingBorrowing.token()).to.equal(divisibleAsset.address);
          expect(await lendingBorrowing.interestRate()).to.equal(interestRate);
          expect(lendingBorrowing).to.not.empty;
      });
      
    });
    describe("Deposit", function () {
        it("Should revert with Amount must be > 0", async function () {
            const {lendingBorrowing, divisibleAsset, otherAccount} = await loadFixture(deployContract);

            await expect(lendingBorrowing.deposit(0)).to.be.revertedWith('Amount must be > 0');
        });

        it("Should revert with ERC20: insufficient allowance", async function () {
            const {lendingBorrowing} = await loadFixture(deployContract);

            await expect(lendingBorrowing.deposit(10)).to.be.revertedWith('ERC20: insufficient allowance');
        });

        it("Should revert with ERC20: transfer amount exceeds balance", async function () {
            const {lendingBorrowing, divisibleAsset, secondAccount} = await loadFixture(deployContract);

            await divisibleAsset.connect(secondAccount).approve(lendingBorrowing.address, transfer_to_otheraccount);
            
            await expect(lendingBorrowing.connect(secondAccount).deposit(10)).to.be.revertedWith('ERC20: transfer amount exceeds balance');
        });

        it("Should deposit tokens into contract", async function () {
            const {lendingBorrowing, divisibleAsset, otherAccount} = await loadFixture(deployContract);

            await divisibleAsset.connect(otherAccount).approve(lendingBorrowing.address, transfer_to_otheraccount);
            
            await lendingBorrowing.connect(otherAccount).deposit(transfer_to_otheraccount);
			
            expect(await divisibleAsset.balanceOf(otherAccount.address)).to.equal(0);

            expect(await divisibleAsset.balanceOf(lendingBorrowing.address)).to.equal(transfer_to_otheraccount);

            expect((await lendingBorrowing.positions(otherAccount.address)).collateral).to.equal(transfer_to_otheraccount);
        });
        
    });
});