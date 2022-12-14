/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AssetFactory.sol";
import "./LendingBorrowing.sol";
import "./PriceConsumer.sol";
import "./DivisibleAsset.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";


contract Controller is AccessControl {

    using SafeERC20 for DivisibleAsset;

    AssetFactory public assetFactory;
    LendingBorrowing public lendingBorrowing;
    PriceConsumer public priceConsumer;
    
    uint256 public constant ETH_FACTOR = 10;

    event AssetAndProtocolCreated(
        address indexed token,
        uint256 ethSupply
    );

    event AssetFactorySeted(
        address indexed _assetFactory
    );

    event LendingBorrowingSeted(
        address indexed _lendingBorrowing
    );

    event PriceConsumerSeted (
        address indexed _priceConsumer
    );    

    // test vars
    uint256 public _var;

    constructor(address _assetFactory, address payable _lendingBorrowing, address _priceConsumer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        assetFactory = AssetFactory(_assetFactory);
        lendingBorrowing = LendingBorrowing(_lendingBorrowing);
        priceConsumer = PriceConsumer(_priceConsumer);
    }
    
    function createAssetAndProtocol(
        uint256 _initialSupply,
        string memory name_,
        string memory symbol_,
        uint256 _price,
        uint256 _maxLTV,
        uint256 _liqThreshold,
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _borrowThreshold,
        uint256 _interestRate
        
    ) external payable returns( address ) {

        // el valor de ETH en USD se obtiene con 8 decimales, los cuales se corrigen a 2
        //uint256 ethValueInUSD = uint256(priceConsumer.getLatestPrice() / 1e6); 

        // se corrije el msg.value y el _price a 2 decimales
        //uint256 msgValueInUSD = (msg.value / 1e16) * ethValueInUSD / 1e2;

        // ETH_FACTOR = cantidad de eth inicial que debe depositarse para tokenizar
        
        require( (msg.value / 1e16) * uint256(priceConsumer.getLatestPrice() / 1e6) / 1e2 >= ( _price * 1e2) / ETH_FACTOR , 'Not enough Ether');
        
        address _token = assetFactory.createDivisibleAsset(_initialSupply, name_, symbol_, msg.value, _price);

        // enviar ETH al protocolo
        (bool sent, ) = address(lendingBorrowing).call{value: msg.value, gas: 20317}("");

        require(sent, "Failed to send Ether");
        
        lendingBorrowing.createProtocol( 
            _token, 
            _maxLTV,
            _liqThreshold,
            _liqFeeProtocol,
            _liqFeeSender, 
            _borrowThreshold,
            _interestRate,
            msg.value
        );

        emit AssetAndProtocolCreated(_token, msg.value);

        return _token;
    }

    // donde _quantity esta en numeros con 2 decimales 
    function buyTokens(address _token, uint256 _quantity) external payable {
        // el valor de ETH en USD se obtiene con 8 decimales, los cuales se corrigen a 2
        uint256 ethValueInUSD = uint256(priceConsumer.getLatestPrice() / 1e6); 
        // se corrije el msg.value y el _price a 2 decimales
        uint256 msgValueInUSD = (msg.value / 1e16) * ethValueInUSD / 1e2;

        // obtiene el precio del activo en USD
        uint256 _price = assetFactory.getPrice(_token);
        // obtiene el totalSupply del token
        DivisibleAsset _divisibleAsset = DivisibleAsset(_token);
        uint256 _totalSupply = _divisibleAsset.totalSupply() / 1e18;
        // calcula el monto unitario en USD por token  
        uint256 _amount = _price / _totalSupply;

        /* console.log('msg.value in USD: ', msgValueInUSD);
        console.log('_price: ', _price);
        console.log('_totalSupply', _totalSupply);
        console.log('_amount', _amount);
        console.log('_quantity', _quantity);
        console.log('monto a cubrir. (Cantidad x monto unitario)', _quantity * _amount); */

        require(msgValueInUSD >= (_quantity * _amount), 'Not enough Ether');
 
        assetFactory.addSale(_token, msg.value);
        
        DivisibleAsset(_token).safeTransfer(msg.sender, _quantity * 1e16);         

    }

    function claimInitialValue(address _token) external payable {

        
        address _creator = assetFactory.getCreator(_token);
        require(msg.sender == _creator, 'Caller is not the token creator');

        uint256 _claimed = assetFactory.getClaimed(_token);
        require(_claimed == 0, 'Value alredy claimed');

        DivisibleAsset _divisibleAsset = DivisibleAsset(_token);
        uint256 _contractBalance = _divisibleAsset.balanceOf(address(this));
        uint256 _totalSupply = _divisibleAsset.totalSupply();

        console.log('_contractBalance', _contractBalance);
        console.log('_totalSupply', _totalSupply);
        console.log('_contractBalance / _totalSupply', _contractBalance / _totalSupply);

        require(_contractBalance / _totalSupply * 10 <= 1, 'Value is not claimable' );

        // #TODO: enviar el ETH desde el protocolo de L&B
    }

    function claimTokensSales(address _token) external payable {

        address _creator = assetFactory.getCreator(_token);
        require(msg.sender == _creator, 'Caller is not the token creator');

        uint256 _salesTotal = assetFactory.getSalesTotal(_token);    

        assetFactory.emptySales(_token);

        (bool sent, ) = msg.sender.call{value: _salesTotal, gas: 20317}("");
        
        require(sent, "Failed to send Ether");
    }

    function setAssetFactory(address _assetFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        assetFactory = AssetFactory(_assetFactory);
        emit AssetFactorySeted(_assetFactory);
    }

    function setLendingBorrowing(address payable _lendingBorrowing)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lendingBorrowing = LendingBorrowing(_lendingBorrowing);
        emit LendingBorrowingSeted(_lendingBorrowing);
    }

    function setPriceConsumer(address _priceConsumer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceConsumer = PriceConsumer(_priceConsumer);
        emit PriceConsumerSeted(_priceConsumer);
    }
}