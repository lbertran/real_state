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

    mapping(address => Asset) public _divisibleAssetsMap;

    uint256 public constant ETH_FACTOR = 10;

    function createDivisibleAsset(
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_,
        uint256 _price
        
    ) public payable {
        DivisibleAsset divisibleAsset = new DivisibleAsset(
            _initialSupply,
            name_,
            symbol_
        );
        //require(msg.value>=_price * _initialSupply / ETH_FACTOR , 'Not enough Ether');

        require(DivisibleAsset(divisibleAsset).transfer(msg.sender, _initialSupply),'Transfer to creator failed');
        
        Asset memory asset_ = Asset(divisibleAsset, _price, block.timestamp);
        _divisibleAssets.push(asset_); 
        _divisibleAssetsMap[address(asset_.token)] = asset_;

        // create Lending & Borrowing Contract

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