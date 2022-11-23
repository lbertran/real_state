/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AssetFactory.sol";
import "./LendingBorrowingFactory.sol";
import "./PriceConsumer.sol";

contract Controller {

    AssetFactory public assetFactory;
    LendingBorrowingFactory public lendingBorrowingFactory;
    PriceConsumer public priceConsumer;
    
    uint256 public constant ETH_FACTOR = 10;

    event createAssetAndProtocolEvent(
        address indexed token,
        address indexed protocol,
        uint256 ethSupply
    );

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
        
    ) public payable {

        require(msg.value>=_price * _initialSupply / ETH_FACTOR , 'Not enough Ether');

        address _token = assetFactory.createDivisibleAsset(_initialSupply, name_, symbol_, _price);

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

        emit createAssetAndProtocolEvent(_token, _protocol, msg.value);

    }


    function setAssetFactory(address _assetFactory)
        public
    {
        assetFactory = AssetFactory(_assetFactory);
    }

    function setLendingBorrowingFactory(address _lendingBorrowingFactory)
        public
    {
        lendingBorrowingFactory = LendingBorrowingFactory(_lendingBorrowingFactory);
    }

    function setPriceConsumer(address _priceConsumer)
        public
    {
        priceConsumer = PriceConsumer(_priceConsumer);
    }
}