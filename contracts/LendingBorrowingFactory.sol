/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./LendingBorrowing.sol";

contract LendingBorrowingFactory {
    
    mapping(address => address) public _lendingBorrowingContractsForTokens;

     address[] public _lendingBorrowingContracts;

    function createLendingBorrowing(
        address _token,
        address _assetFactory,
        address _priceConsumer,
        uint256 _maxLTV,
        uint256 _liqThreshold,
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _borrowThreshold,
        uint256 _interestRate
    ) public {
        LendingBorrowing lendingBorrowing = new LendingBorrowing(
             _token,
            _assetFactory,
            _priceConsumer,
            _maxLTV,
            _liqThreshold,
            _liqFeeProtocol,
            _liqFeeSender,
            _borrowThreshold,
            _interestRate
        );
        _lendingBorrowingContracts.push(address(lendingBorrowing));
        _lendingBorrowingContractsForTokens[_token] = address(lendingBorrowing);
    }

    function allProtocols()
        public
        view
        returns (address[] memory coll)
    {
        return _lendingBorrowingContracts;
    }
}