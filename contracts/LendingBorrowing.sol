// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/ABDKMath64x64.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUSDZ.sol";

import "hardhat/console.sol";

// habrá un contrato de lending por cada token
// - natspec comments for functions

contract LendingBorrowing is Ownable {
    
    // ---------------------------------------------------------------------
    // VARIABLES
    // ---------------------------------------------------------------------
    address public token;

    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 lastInterest;
    }

    mapping(address => Position) private positions;
    
    uint256 public totalCollateral;
    uint256 public totalBorrowed; 
    uint256 public maxLTV; 
    uint256 public liqThreshold;
    uint256 public borrowThreshold;
    uint256 public interestRate;
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
        address _token,
        uint256 _maxLTV,
        uint256 _liqThreshold,
        uint256 _borrowThreshold,
        uint256 _interestRate
    ) {
        token = _token;
        // fees and rates use SCALING_FACTOR 
        maxLTV = _maxLTV;
        liqThreshold = _liqThreshold;
        borrowThreshold = _borrowThreshold;
        interestRate = _interestRate;
        // set SECONDS_IN_YEAR for interest calculations
        SECONDS_IN_YEAR = ABDKMath64x64.fromUInt(31556952);

        
    }

    // ---------------------------------------------------------------------
    // PUBLIC STATE-MODIFYING FUNCTIONS
    // ---------------------------------------------------------------------

    // User deposits token as collateral
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Amount must be > 0");
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Token transfer failed"
        );
        positions[msg.sender].collateral += _amount;
        emit Deposit(msg.sender, _amount);
    }

    // User withdraws xSUSHI collateral if safety ratio stays > 200%
    function withdraw(uint256 _amount) public {
        Position storage pos = positions[msg.sender];
        require(pos.collateral >= _amount, "Not enough collateral token in account");

        uint256 interest_ = calcInterest(msg.sender);
        pos.debt += interest_;
        pos.lastInterest = block.timestamp;

        uint256 withdrawable_;

        // TO-DO colRatio debe clacularse a partir del precio de ethereum vs del token colateral
        // por ahora lo dejamos en 1
        uint256 colRatio = 1;
        if (pos.debt == 0) {
            withdrawable_ = pos.collateral;
        } else {
            withdrawable_ =
                (pos.collateral / colRatio) *
                (colRatio - borrowThreshold);
        }

        require(withdrawable_ >= _amount, "Not enough withdrawable amount in account");

        pos.collateral -= _amount;

        require(
            IERC20(token).transfer(msg.sender, _amount),
            "Withdraw transfer failed"
        );

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

    // Calculates interest on position of given address
    // WARNING: contains fancy math
    function calcInterest(address _account)
        public
        view
        returns (uint256 interest)
    {
        if (
            positions[_account].debt == 0 ||
            positions[_account].lastInterest == 0 ||
            interestRate == 0 ||
            block.timestamp == positions[_account].lastInterest
        ) {
            return 0;
        }

        uint256 secondsSinceLastInterest_ = block.timestamp -
            positions[_account].lastInterest;
        int128 yearsBorrowed_ = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(secondsSinceLastInterest_),
            SECONDS_IN_YEAR
        );
        int128 interestRate_ = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(interestRate),
            ABDKMath64x64.fromUInt(SCALING_FACTOR)
        );
        int128 debt_ = ABDKMath64x64.fromUInt(positions[_account].debt);

        // continous compound interest = P*e^(i*t)
        // this figure includes principal + interest
        uint64 interest_ = ABDKMath64x64.toUInt(
            ABDKMath64x64.mul(
                debt_,
                ABDKMath64x64.exp(
                    ABDKMath64x64.mul(interestRate_, yearsBorrowed_)
                )
            )
        );

        // returns only the interest, not the principal
        return uint256(interest_) - positions[_account].debt;
    }


}