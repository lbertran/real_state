/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Asset.sol";

contract AssetFactory {
    Asset[] private _assets;

    function createAsset(
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_
    ) public {
        Asset asset = new Asset(
            _initialSupply,
            name_,
            symbol_
        );
        _assets.push(asset);
    }

    function allAssets(uint256 limit, uint256 offset)
        public
        pure
        returns (Asset[] memory coll)
    {
        return coll;
    }
}