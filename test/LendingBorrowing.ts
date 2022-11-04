import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("DivisibleAsset", function () {
    const ERC20_INITIALSUPLY = 100e10;
    const LPTOKEN_OTHERACCOUNT = 50e10;
    const STAKING_OTHERACCOUNT = 30e10;
    const ONE_WEEK_IN_SECS = 7 * 24 * 60 * 60;
    

    async function deployContract() {
        const DivisibleAsset = await ethers.getContractFactory("DivisibleAsset");
        const divisibleAsset = await DivisibleAsset.deploy(ERC20_INITIALSUPLY, 'Asset1', 'A1');
        
        /* const LPToken = await ethers.getContractFactory("LPToken");
        const lPToken = await LPToken.deploy(ERC20_INITIALSUPLY);

        const TokenFarm = await ethers.getContractFactory("TokenFarmBonus");
        const tokenFarm = await TokenFarm.deploy(dappToken.address, lPToken.address); */
        
        const [owner, otherAccount, secondAccount] = await ethers.getSigners();
        
        return { divisibleAsset, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {divisibleAsset} = await loadFixture(deployContract);

          expect(await divisibleAsset.name()).to.equal('Asset1');
          expect(await divisibleAsset.symbol()).to.equal('A1');
          expect(divisibleAsset).to.not.empty;
          
      });
  });
});