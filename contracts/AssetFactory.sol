/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DivisibleAsset.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AssetFactory is AccessControl{

    //TO-DO: agregar eventos
    using SafeERC20 for DivisibleAsset;
    
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    EnumerableMap.UintToAddressMap private divisibleAssets;
    
    struct Asset {
        DivisibleAsset token;
        address creator;
        uint256 claimed;
        uint256 initialValue; // in ETH
        uint256 price;
        uint256 lastUpdate;
    }

    mapping(address => Asset) public divisibleAssetsMap;

    event DivisibleAssetCreated(
        DivisibleAsset divisibleAsset
    );

    event AssetPriceUpdated(
        address _address,
        uint _price
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);   
    }

    function createDivisibleAsset (
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_,
        uint256 _initialValue,
        uint256 _price
        
    ) 
        external
        //onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        DivisibleAsset divisibleAsset = new DivisibleAsset(
            _initialSupply * 1e18,
            name_,
            symbol_
        );
        
        DivisibleAsset(divisibleAsset).safeTransfer(msg.sender, _initialSupply * 1e18);

        Asset memory asset_ = Asset(divisibleAsset,  tx.origin , 0, _initialValue, _price, block.timestamp);
        
        divisibleAssetsMap[address(asset_.token)] = asset_;

        uint256 _key = divisibleAssets.length();

        divisibleAssets.set(_key, address(asset_.token));

        emit DivisibleAssetCreated(divisibleAsset);

        return address(asset_.token);

    }

    function divisibleAssetsLength()
        external
        view
        returns (uint256)
    {
        return divisibleAssets.length();
    }

    function divisibleAssetAddress(
        uint256 _key
    )
        external
        view
        returns (address)
    {
        return divisibleAssets.get(_key);
    }

    
    function updateAssetPrice(
        address _address,
        uint _price
    ) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price>0,'Price cannot be zero.');
        divisibleAssetsMap[_address].price = _price;
        divisibleAssetsMap[_address].lastUpdate = block.number;

        emit AssetPriceUpdated(_address, _price);
    }

    function getPrice(address _token) external view returns (uint256){
        return divisibleAssetsMap[_token].price;
    }  

    function getCreator(address _token) external view returns (address){
        return divisibleAssetsMap[_token].creator;
    } 

    function getClaimed(address _token) external view returns (uint256){
        return divisibleAssetsMap[_token].claimed;
    } 
}