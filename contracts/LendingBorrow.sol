// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/ABDKMath64x64.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUSDZ.sol";

import "hardhat/console.sol";

// TODO features
// - Admin functions for withdrawing protocol USDZ/xSUSHI

// TODO fixes
// - add nonReentrant
// - remove fees/rates in contructor - setter only for safety
// - check best practices for ABDKMath64x64
// - standardize revert msgs
// - use smaller uints for fees and rates
// - natspec comments for functions

contract Controller is Ownable {
    
    // ---------------------------------------------------------------------
    // VARIABLES
    // ---------------------------------------------------------------------

    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 lastInterest;
    }

    mapping(address => Position) private positions;
    
    uint256 public liqFeeProtocol;
    uint256 public liqFeeSender;

    uint256 public interestRate;

    uint256 public borrowThreshold;
    uint256 public liqThreshold;

    uint256 public constant SCALING_FACTOR = 10000;
    int128 public SECONDS_IN_YEAR; // int128 for compound interest math

    // ---------------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------------

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Borrow(
        address indexed account,
        uint256 amountBorrowed,
        uint256 totalDebt,
        uint256 collateralAmount
    );
    event Repay(
        address indexed account,
        uint256 debtRepaid,
        uint256 debtRemaining,
        uint256 collateralAmount
    );
    event Liquidation(
        address indexed account,
        address indexed liquidator,
        uint256 collateralLiquidated,
        uint256 lastCollateralRatio,
        uint256 lastDebtOutstanding,
        uint256 protocolDebtCreated // if liquidating at < 100% col rat -> protocol takes on debt
    );

    // ---------------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------------
    constructor(
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _interestRate,
        uint256 _borrowThreshold,
        uint256 _liqThreshold
    ) {

        // fees and rates use SCALING_FACTOR 
        liqFeeProtocol = _liqFeeProtocol;
        liqFeeSender = _liqFeeSender;
        interestRate = _interestRate;
        borrowThreshold = _borrowThreshold;
        liqThreshold = _liqThreshold;

        // set SECONDS_IN_YEAR for interest calculations
        SECONDS_IN_YEAR = ABDKMath64x64.fromUInt(31556952);

        
    }

    // ---------------------------------------------------------------------
    // PUBLIC STATE-MODIFYING FUNCTIONS
    // ---------------------------------------------------------------------

    // User deposits xSUSHI as collateral
    function deposit(uint256 _amount) public {
        

        emit Deposit(msg.sender, _amount);
    }

    // User withdraws xSUSHI collateral if safety ratio stays > 200%
    function withdraw(uint256 _amount) public {
        

        emit Withdraw(msg.sender, _amount);
    }

    // User mints and borrows USDZ against collateral
    function borrow(uint256 _amount) public {
        require(_amount > 0, "can't borrow 0");
        Position storage pos = positions[msg.sender];

        

        emit Borrow(msg.sender, _amount, pos.debt, pos.collateral);
    }

    // User repays any interest, then debt in USDZ
    // Interest revenue is acounted for in protocolIntRev
    function repay(uint256 _amount) public {
        require(_amount > 0, "can't repay 0");

        Position storage pos = positions[msg.sender];
        

        emit Repay(msg.sender, _amount, pos.debt, pos.collateral);
    }

    // Liquidates account if collateral ratio below safety threshold
    // Accounts for protocol shortfal as debt (in xSUSHI)
    // No protocol interest revenue taken on liquidations,
    // as a protocol liquidation fee is taken instead
    function liquidate(address _account) public {
        Position storage pos = positions[_account];

        

        pos.collateral = 0;
        pos.debt = 0;
    }



}