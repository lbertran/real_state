// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/ABDKMath64x64.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "hardhat/console.sol";

import "./AssetFactory.sol";
import "./PriceConsumer.sol";

// habrá un contrato de lending por cada token
// - natspec comments for functions

contract LendingBorrowing is Ownable {
    
    // ---------------------------------------------------------------------
    // VARIABLES
    // ---------------------------------------------------------------------
    address public token;
    AssetFactory public assetFactory;
    PriceConsumer public priceConsumer;

    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 lastInterest;
    }

    mapping(address => Position) public positions;
    
    uint256 public procotolTotalCollateral;
    uint256 public procotolTotalBorrowed; 
    uint256 public maxLTV; 
    
    // umbral de liquidación, y fee para el protocolo y para el liquidador
    uint256 public liqThreshold;
    uint256 public liqFeeProtocol;
    uint256 public liqFeeSender;
    uint256 public protocolDebt;

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
        address _assetFactory,
        address _priceConsumer,
        uint256 _maxLTV,
        uint256 _liqThreshold,
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _borrowThreshold,
        uint256 _interestRate
    ) payable {
        token = _token;
        assetFactory = AssetFactory(_assetFactory);
        priceConsumer = PriceConsumer(_priceConsumer);
        // fees and rates use SCALING_FACTOR 
        maxLTV = _maxLTV;
        liqThreshold = _liqThreshold;
        liqFeeProtocol = _liqFeeProtocol;
        liqFeeSender = _liqFeeSender;
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

    // User withdraws collateral if safety ratio stays > 200%
    function withdraw(uint256 _amount) public {
        Position storage pos = positions[msg.sender];
        require(pos.collateral >= _amount, "Not enough collateral token in account");

        uint256 interest_ = calcInterest(msg.sender);
        pos.debt += interest_;
        pos.lastInterest = block.timestamp;

        uint256 withdrawable_;

        
        uint256 colRatio = getCurrentCollateralRatio(msg.sender);

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

    // User mints and borrows against collateral
    function borrow(uint256 _amount) public {
        require(_amount > 0, "Amount must be > 0");

        Position storage pos = positions[msg.sender];

        uint256 interest_ = calcInterest(msg.sender);

        // Check forward col. ratio >= safe col. ratio limit
        require(
            getForwardCollateralRatio(
                msg.sender,
                pos.debt + interest_ + _amount
            ) >= borrowThreshold,
            "Not enough collateral to borrow that much"
        );

        // add interest and new debt to position
        pos.debt += (_amount + interest_);
        pos.lastInterest = block.timestamp;

        // TO-DO enviar ETH al msg.sender
        emit Borrow(msg.sender, _amount, pos.debt, pos.collateral);
    }

    // User repays any interest
    function repay(uint256 _amount) public {
        require(_amount > 0, "Can't repay 0");

        Position storage pos = positions[msg.sender];
        uint256 interestDue = calcInterest(msg.sender);

        // account for protocol interest revenue
        if (_amount >= interestDue + pos.debt) {
            // repays all interest and debt
            // ver como pagar con ETH
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    pos.debt + interestDue
                ),
                "Repay transfer failed"
            );
            pos.debt = 0;
        } else if (_amount >= interestDue) {
            // repays all interest, starts repaying debt
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "Repay transfer failed"
            );
            pos.debt -= (_amount - interestDue);
        } else {
            // repay partial interest, no debt repayment
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "Repay transfer failed"
            );
            pos.debt += (interestDue - _amount);
        }

        // restart interest compounding from here
        pos.lastInterest = block.timestamp;

        emit Repay(msg.sender, _amount, pos.debt, pos.collateral);
    }

    // Liquidates account if collateral ratio below safety threshold
    // Accounts for protocol shortfal as debt (in xSUSHI)
    // No protocol interest revenue taken on liquidations,
    // as a protocol liquidation fee is taken instead
    function liquidate(address _account) public {
        Position storage pos = positions[_account];

        require(pos.collateral > 0, "Account has no collateral");
        
        uint256 interest_ = calcInterest(_account);
        uint256 totalCollateral = pos.collateral; //needed for reporting in event
        uint256 collateralRatio = getForwardCollateralRatio(
            _account,
            pos.debt + interest_
        );

        // Check debt + interest puts account below liquidation col ratio
        // acá chequea si la pocisión es liquidable
        require(
            collateralRatio < liqThreshold,
            "Account not below liquidation threshold"
        );

        // calc fees to protocol and liquidator
        uint256 protocolShare = ((pos.collateral * liqFeeProtocol) /
            SCALING_FACTOR);
        uint256 liquidatorShare = ((pos.collateral * liqFeeSender) /
            SCALING_FACTOR);

        require(
            protocolShare + liquidatorShare <= pos.collateral,
            "Liquidation fees incorrectly set"
        );

        // taking protocol fees in token
        // el protocolo queda con sus tokens ya depositados. Solo se transfieren token al liquidador
        require(
            IERC20(token).transferFrom(
                address(this),
                msg.sender,
                liquidatorShare
            ),
            "Token transfer to liquidator failed"
        );

        // Accounting for protocol shortfall by taking on debt
        pos.collateral = totalCollateral - (protocolShare + liquidatorShare);
        uint256 colRatioAfterFees = getForwardCollateralRatio(
            _account,
            pos.debt + interest_
        );
        uint256 protocolDebtCreated;
        if (colRatioAfterFees < SCALING_FACTOR) {
            // if liquidating at col ratio < 100% + fees
            protocolDebtCreated =
                (SCALING_FACTOR - colRatioAfterFees) *
                pos.collateral;
        }

        protocolDebt += protocolDebtCreated;

        emit Liquidation(
            _account,
            msg.sender,
            totalCollateral,
            collateralRatio,
            pos.debt,
            protocolDebtCreated
        );

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
        // si la pocision esta en 0 y el ultimo interes calculado es del bloque actual
        // retorna CERO
        if (
            positions[_account].debt == 0 ||
            positions[_account].lastInterest == 0 ||
            interestRate == 0 ||
            block.timestamp == positions[_account].lastInterest
        ) {
            return 0;
        }
        // si el ultimo interes calculado no es del bloque actual
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

    // Calculates forward collateral ratio of an account, using custom debt amount
    function getForwardCollateralRatio(address _account, uint256 _totalDebt)
        public
        view
        returns (uint256)
    {
        return _getCollateralRatio(_account, _totalDebt);
    }

    // Calculates current collateral ratio of an account.
    // NOTE: EXCLUDES INTEREST
    function getCurrentCollateralRatio(address _account)
        public
        view
        returns (uint256)
    {
        return _getCollateralRatio(_account, positions[_account].debt);
    }

    // Internal getColRatio logic
    function _getCollateralRatio(address _account, uint256 _totalDebt)
        internal
        view
        returns (uint256)
    {
        uint256 collateral_ = positions[_account].collateral;

        if (collateral_ == 0) {
            // if collateral is 0, col ratio is 0 and no borrowing possible
            return 0;
        } else if (_totalDebt == 0) {
            // if debt is 0, col ratio is infinite
            return type(uint256).max;
        }

        // TO-DO colRatio debe clacularse a partir del precio de ethereum vs del token colateral
        
        // valor del colateral en USD

        (,uint price,) = assetFactory._divisibleAssetsMap(token);

        uint256 collateralValue_ = collateral_ * price;

        // valor de ETH en USD

        int256 ethValue = priceConsumer.getLatestPrice();

        // E.g. 2:1 will return 20 000 (20 000/10 000=2) for 200%
        return (collateralValue_ * SCALING_FACTOR) / (_totalDebt);
    }

    // ---------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    // ---------------------------------------------------------------------

    function setFeesAndRates(
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _interestRate
    ) external onlyOwner {
        // Liquidation fees
        require(
            _liqFeeProtocol + _liqFeeSender <= SCALING_FACTOR,
            "Liquidation fees out of range"
        );
        liqFeeProtocol = _liqFeeProtocol;
        liqFeeSender = _liqFeeSender;

        // Interest rates - capped at 100% APR
        require(_interestRate <= SCALING_FACTOR, "InterestRate out of range");
        interestRate = _interestRate;
    }

    function setThresholds(uint256 _borrowThreshold, uint256 _liqThreshold)
        external
        onlyOwner
    {
        // both thresholds should be > scaling factor
        // e.g. 20 000 / 10 000 = 200%
        require(
            _borrowThreshold >= SCALING_FACTOR,
            "borrow threshold must be > scaling factor"
        );
        require(
            _liqThreshold >= SCALING_FACTOR,
            "liq threshold must be > scaling factor"
        );
        borrowThreshold = _borrowThreshold;
        liqThreshold = _liqThreshold;
    }

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        token = _token;
    }

    // ---------------------------------------------------------------------
    // ETHER FUNCTIONS
    // ---------------------------------------------------------------------
     // Función para recibir Ether. msg.data debe estar vacío
    receive() external payable {}

    // se llama a la función Fallback cuando msg.data no está vacío
    fallback() external payable {}

    // Función para transferir Ether desde el saldo del contrato 
    // a la dirección pasada por parámetro
    function transfer(address payable _to, uint _amount) external onlyOwner {
        // Note que "_to" es declarada como payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}