/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DivisibleAsset.sol";

contract AssetFactory {

    struct Asset {
        uint256 price;
        uint256 lastUpdate;
    }

    mapping(address => Asset) public _divisibleAssets;

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
        Asset memory asset_ = Asset( _price, block.timestamp);
        
        _divisibleAssets[address(divisibleAsset)] = asset_;
    }

    function allAssets()
        public
        view
        returns (mapping)
    {
        return _divisibleAssets;
    }

    //TO-DO: actualizar precio del asset
}