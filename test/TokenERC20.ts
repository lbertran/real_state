import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("TokenERC20ken", function () {
    const ERC20_INITIALSUPLY = 100e10;
    const LPTOKEN_OTHERACCOUNT = 50e10;
    const STAKING_OTHERACCOUNT = 30e10;
    const ONE_WEEK_IN_SECS = 7 * 24 * 60 * 60;
    

    async function deployContract() {
        const TokenERC20ken = await ethers.getContractFactory("TokenERC20ken");
        const tokenERC20ken = await TokenERC20ken.deploy(ERC20_INITIALSUPLY, 'TokenRS', 'TRS');
        
        /* const LPToken = await ethers.getContractFactory("LPToken");
        const lPToken = await LPToken.deploy(ERC20_INITIALSUPLY);

        const TokenFarm = await ethers.getContractFactory("TokenFarmBonus");
        const tokenFarm = await TokenFarm.deploy(dappToken.address, lPToken.address); */
        
        const [owner, otherAccount, secondAccount] = await ethers.getSigners();
        
        return { tokenERC20ken, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {tokenERC20ken} = await loadFixture(deployContract);

          expect(await tokenERC20ken.name()).to.equal('TokenRS');
          expect(await tokenERC20ken.symbol()).to.equal('TRS');
          expect(tokenERC20ken).to.not.empty;
          
      });
  });
});