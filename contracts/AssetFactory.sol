/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DivisibleAsset.sol";

contract AssetFactory {
    DivisibleAsset[] public _divisibleAssetAssets;

    function createDivisibleAsset(
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_
    ) public {
        DivisibleAsset divisibleAsset = new DivisibleAsset(
            _initialSupply,
            name_,
            symbol_
        );
        _divisibleAssetAssets.push(divisibleAsset);
    }

    function allAssets()
        public
        view
        returns (DivisibleAsset[] memory coll)
    {
        return _divisibleAssetAssets;
    }
}