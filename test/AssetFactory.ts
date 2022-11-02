import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

describe("AssetFactory", function () {
    const ERC20_INITIALSUPLY = 100e10;
    const LPTOKEN_OTHERACCOUNT = 50e10;
    const STAKING_OTHERACCOUNT = 30e10;
    const ONE_WEEK_IN_SECS = 7 * 24 * 60 * 60;
    

    async function deployContract() {
        const AssetFactory = await ethers.getContractFactory("AssetFactory");
        const DivisibleAsset = await ethers.getContractFactory('DivisibleAsset');

        const assetFactory = await AssetFactory.deploy();
        
        const [owner, otherAccount, secondAccount] = await ethers.getSigners();
        
        return { assetFactory, DivisibleAsset, owner, otherAccount, secondAccount };
    }

    describe("Deployment", function () {
      it("Should deploy the contract", async function () {
          const {assetFactory} = await loadFixture(deployContract);
          expect(assetFactory).to.not.empty;
          
      });
    });

    describe("Create DivisibleAsset instances", function () {
        it("Should create multiple DivisibleAsset and call its functions", async function () {
            const {assetFactory, DivisibleAsset} = await loadFixture(deployContract);

            const tx_asset1 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1');
            const tx_asset2 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset2', 'A2');
            const tx_asset3 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset3', 'A3');

            expect(tx_asset1).to.not.empty;
            expect(tx_asset2).to.not.empty;
            expect(tx_asset3).to.not.empty;

            const asset1_address = await assetFactory._divisibleAssetAssets(0);
            const asset2_address = await assetFactory._divisibleAssetAssets(1);
            const asset3_address = await assetFactory._divisibleAssetAssets(2);

            console.log("A1 address at: ", asset1_address);
            console.log("A2 address at: ", asset2_address);
            console.log("A3 address at: ", asset3_address);

            const asset1 = DivisibleAsset.attach(asset1_address);
            const asset2 = DivisibleAsset.attach(asset2_address);
            const asset3 = DivisibleAsset.attach(asset3_address);

            expect(await asset1.name()).to.equal('Asset1');
            expect(await asset1.symbol()).to.equal('A1');

            expect(await asset2.name()).to.equal('Asset2');
            expect(await asset2.symbol()).to.equal('A2');

            expect(await asset3.name()).to.equal('Asset3');
            expect(await asset3.symbol()).to.equal('A3');
        });

        it("Should create multiple DivisibleAsset and return collection", async function () {
            const {assetFactory, DivisibleAsset} = await loadFixture(deployContract);

            const tx_asset1 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1');
            const tx_asset2 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset2', 'A2');
            const tx_asset3 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset3', 'A3');

            console.log(await assetFactory.allAssets());
        });
      });
});