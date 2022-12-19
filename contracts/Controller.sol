/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AssetFactory.sol";
import "./LendingBorrowingFactory.sol";
import "./PriceConsumer.sol";
import "./DivisibleAsset.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";


contract Controller is AccessControl {

    using SafeERC20 for DivisibleAsset;

    AssetFactory public assetFactory;
    LendingBorrowingFactory public lendingBorrowingFactory;
    PriceConsumer public priceConsumer;
    
    uint256 public constant ETH_FACTOR = 10;

    event AssetAndProtocolCreated(
        address indexed token,
        address indexed protocol,
        uint256 ethSupply
    );

    event AssetFactorySeted(
        address indexed _assetFactory
    );

    event LendingBorrowingFactorySeted(
        address indexed _lendingBorrowingFactory
    );

    event PriceConsumerSeted (
        address indexed _priceConsumer
    );    

    // test vars
    uint256 public _var;

    constructor(address _assetFactory, address _lendingBorrowingFactory, address _priceConsumer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        assetFactory = AssetFactory(_assetFactory);
        lendingBorrowingFactory = LendingBorrowingFactory(_lendingBorrowingFactory);
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
        // initialSupply es la cantidad de tokens en que se fraccionará el activo

        // se trabajará con valores en USD y 2 decimales 

        // el valor de ETH en USD se obtiene con 8 decimales, los cuales se corrigen a 2
        //uint256 ethValueInUSD = uint256(priceConsumer.getLatestPrice() / 1e6); 

        // se corrije el msg.value y el _price a 2 decimales
        //uint256 msgValueInUSD = (msg.value / 1e16) * ethValueInUSD / 1e2;

         // en esta cuenta
        //  _price = precio de la propiedad en USD
        //  msgValueInUSD = msg.value en USD
        // ETH_FACTOR = cantidad de eth inicial que debe depositarse para tokenizar
        
        require( (msg.value / 1e16) * uint256(priceConsumer.getLatestPrice() / 1e6) / 1e2 >= ( _price * 1e2) / ETH_FACTOR , 'Not enough Ether');
        
        address _token = assetFactory.createDivisibleAsset(_initialSupply, name_, symbol_, msg.value, _price);

        
        address _protocol = lendingBorrowingFactory.createLendingBorrowing( 
            _token, 
            address(assetFactory), 
            address(priceConsumer),
            _maxLTV,
            _liqThreshold,
            _liqFeeProtocol,
            _liqFeeSender,
            _borrowThreshold,
            _interestRate
        );
        
        // enviar ETH al protocolo
        (bool sent, ) = _protocol.call{value: msg.value, gas: 20317}("");

        require(sent, "Failed to send Ether");
        
        emit AssetAndProtocolCreated(_token, _protocol, msg.value);

        return _protocol;
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
        
        DivisibleAsset(_token).safeTransfer(msg.sender, _quantity * 1e16);         

    }

    function claimInitialValue(address _token) external payable {

        uint256 _claimed = assetFactory.getClaimed(_token);
        require(_claimed == 0, 'Value alredy claimed');
        address _creator = assetFactory.getCreator(_token);
        require(msg.sender == _creator, 'Caller is not the token creator');

        DivisibleAsset _divisibleAsset = DivisibleAsset(_token);
        uint256 _contractBalance = _divisibleAsset.balanceOf(address(this));
        uint256 _totalSupply = _divisibleAsset.totalSupply();

        require(_contractBalance / _totalSupply * 10 >= 9, 'Value is not claimable' );

        (bool sent, ) = msg.sender.call{value: msg.value, gas: 20317}("");
        
        require(sent, "Failed to send Ether");
    }

    function setAssetFactory(address _assetFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        assetFactory = AssetFactory(_assetFactory);
        emit AssetFactorySeted(_assetFactory);
    }

    function setLendingBorrowingFactory(address _lendingBorrowingFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lendingBorrowingFactory = LendingBorrowingFactory(_lendingBorrowingFactory);
        emit LendingBorrowingFactorySeted(_lendingBorrowingFactory);
    }

    function setPriceConsumer(address _priceConsumer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceConsumer = PriceConsumer(_priceConsumer);
        emit PriceConsumerSeted(_priceConsumer);
    }
}