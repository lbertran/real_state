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

            const tx_asset1 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1', 1000);
            const tx_asset2 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset2', 'A2', 2000);
            const tx_asset3 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset3', 'A3', 3000);

            expect(tx_asset1).to.not.empty;
            expect(tx_asset2).to.not.empty;
            expect(tx_asset3).to.not.empty;

            const asset1_address = (await assetFactory.divisibleAssetAddress(0));
            const asset2_address = (await assetFactory.divisibleAssetAddress(1));
            const asset3_address = (await assetFactory.divisibleAssetAddress(2));

            const asset1 = await ethers.getContractAt("DivisibleAsset", (asset1_address));
            const asset2 = await ethers.getContractAt("DivisibleAsset", (asset2_address));
            const asset3 = await ethers.getContractAt("DivisibleAsset", (asset3_address));

            expect(await asset1.name()).to.equal('Asset1');
            expect(await asset1.symbol()).to.equal('A1');

            expect(await asset2.name()).to.equal('Asset2');
            expect(await asset2.symbol()).to.equal('A2');

            expect(await asset3.name()).to.equal('Asset3');
            expect(await asset3.symbol()).to.equal('A3');

            // compara el arreglo y el map
            const arrayLength = await assetFactory.divisibleAssetsLength();
            expect(arrayLength).to.equal(3);

            const map1 = await assetFactory.divisibleAssetsMap(asset1_address);
            const map2 = await assetFactory.divisibleAssetsMap(asset2_address);
            const map3 = await assetFactory.divisibleAssetsMap(asset3_address);
            
            expect(asset1_address).to.equal(map1.token);
            expect(asset2_address).to.equal(map2.token);
            expect(asset3_address).to.equal(map3.token);
        });

        it("Should create DivisibleAsset and update price", async function () {
            
            const {assetFactory, DivisibleAsset} = await loadFixture(deployContract);

            const tx_asset1 = await assetFactory.createDivisibleAsset(ERC20_INITIALSUPLY, 'Asset1', 'A1',1000);

            const asset1_address = (await assetFactory.divisibleAssetAddress(0));

            await assetFactory.updateAssetPrice(asset1_address, 2000);

            const price = (await assetFactory.divisibleAssetsMap(asset1_address)).price;

            const lastUpdate = (await assetFactory.divisibleAssetsMap(asset1_address)).lastUpdate;

            expect(price).to.equal(2000);

            expect(lastUpdate).to.equal(await ethers.provider.getBlockNumber());
            
        });
      });
});
