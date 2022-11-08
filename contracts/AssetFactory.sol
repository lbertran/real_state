/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DivisibleAsset.sol";

contract AssetFactory {
    Asset[] public _divisibleAssets;

    struct Asset {
        DivisibleAsset token;
        uint256 price;
        uint256 lastUpdate;
    }

    function createDivisibleAsset(
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_,
        uint256 _price
        
    ) public {
        DivisibleAsset divisibleAsset = new DivisibleAsset(
            _initialSupply,
            name_,
            symbol_
        );
        Asset memory asset_ = Asset(divisibleAsset, _price, block.timestamp);
        _divisibleAssets.push(asset_); 
    }

    function allAssets()
        public
        view
        returns (Asset[] memory coll)
    {
        return _divisibleAssets;
    }

    //TO-DO: actualizar precio del asset
}