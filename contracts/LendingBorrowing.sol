// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/ABDKMath64x64.sol";

import "hardhat/console.sol";

import "./AssetFactory.sol";
import "./PriceConsumer.sol";

// habrá un contrato de lending por cada token
// - natspec comments for functions

contract LendingBorrowing is Ownable {
    
    // ---------------------------------------------------------------------
    // VARIABLES
    // ---------------------------------------------------------------------
   
    AssetFactory public assetFactory;
    PriceConsumer public priceConsumer;

    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 lastInterest;
    }

    struct Protocol {
        mapping(address => Position) positions;
        address token;
        uint256 procotolTotalCollateral;
        uint256 procotolTotalBorrowed; 
        uint256 maxLTV; 
        uint256 liqThreshold;
        uint256 liqFeeProtocol;
        uint256 liqFeeSender;
        uint256 protocolDebt;
        uint256 borrowThreshold;
        uint256 interestRate;
    }

    mapping(address => Protocol) protocols;

    uint256 public constant SCALING_FACTOR = 10000;
    int128 public SECONDS_IN_YEAR; // int128 for compound interest math    

    // ---------------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------------

    event ProtocolCreated(address indexed account, uint256 amount, address token);

    event Deposit(address indexed account, uint256 amount, address token);

    event Withdraw(address indexed account, uint256 amount, address token);
    
    event Borrow(
        address indexed account,
        uint256 amountBorrowed,
        uint256 totalDebt,
        uint256 collateralAmount,
        address token
    );

    event Repay(
        address indexed account,
        uint256 debtRepaid,
        uint256 debtRemaining,
        uint256 collateralAmount,
        address token
    );
    // if liquidating at < 100% col rat -> protocol takes on debt
    event Liquidation(
        address indexed account,
        address indexed liquidator,
        uint256 collateralLiquidated,
        uint256 lastCollateralRatio,
        uint256 lastDebtOutstanding,
        uint256 protocolDebtCreated,
        address token
    );

    // ---------------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------------
    constructor(
        address _assetFactory,
        address _priceConsumer
    ) payable {
        assetFactory = AssetFactory(_assetFactory);
        priceConsumer = PriceConsumer(_priceConsumer);
        // set SECONDS_IN_YEAR for interest calculations
        SECONDS_IN_YEAR = ABDKMath64x64.fromUInt(31556952);        
    }
    
    function createProtocol(
        address _token,
        uint256 _maxLTV,
        uint256 _liqThreshold,
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _borrowThreshold,
        uint256 _interestRate    
    ) external payable {
        /* Protocol memory protocol_ = Protocol({
            token: _token,
            maxLTV: _maxLTV,
            liqThreshold: _liqThreshold,
            liqFeeProtocol: _liqFeeProtocol,
            liqFeeSender: _liqFeeSender,
            borrowThreshold: _borrowThreshold,
            interestRate: _interestRate
        }); */
        Protocol storage protocol_ = protocols[_token];
        protocols[_token].token = _token;
        protocols[_token].maxLTV = _maxLTV;
        protocols[_token].liqThreshold = _liqThreshold;
        protocols[_token].liqFeeProtocol = _liqFeeProtocol;
        protocols[_token].liqFeeSender = _liqFeeSender;
        protocols[_token].borrowThreshold = _borrowThreshold;
        protocols[_token].interestRate = _interestRate;

        emit ProtocolCreated(msg.sender, msg.value, _token);

    }
    // ---------------------------------------------------------------------
    // PUBLIC STATE-MODIFYING FUNCTIONS
    // ---------------------------------------------------------------------

    // User deposits token as collateral
    function deposit(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be > 0");
        require(
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Token transfer failed"
        );
        protocols[_token].positions[msg.sender].collateral += _amount;
        emit Deposit(msg.sender, _amount, _token);
    }

    // User withdraws collateral if safety ratio stays > 200%
    function withdraw(uint256 _amount, address _token) public {
        Position storage pos = protocols[_token].positions[msg.sender];
        require(pos.collateral >= _amount, "Not enough collateral token in account");

        uint256 interest_ = calcInterest(msg.sender, _token);
        pos.debt += interest_;
        pos.lastInterest = block.timestamp;

        uint256 withdrawable_;

        if (pos.debt == 0) {
            withdrawable_ = pos.collateral;
        } else {
            uint256 colRatio = getCurrentCollateralRatio(msg.sender, _token);

            withdrawable_ =
                (pos.collateral / colRatio) *
                (colRatio - protocols[_token].borrowThreshold);
        }
        
        require(withdrawable_ >= _amount, "Not enough withdrawable amount in account");

        pos.collateral -= _amount;

        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "Withdraw transfer failed"
        );

        emit Withdraw(msg.sender, _amount, _token);
    }

    // User mints and borrows against collateral
    function borrow(uint256 _amount, address _token) public payable {
        require(_amount > 0, "Amount must be > 0");

        Position storage pos = protocols[_token].positions[msg.sender];

        uint256 interest_ = calcInterest(msg.sender, _token);

        // Check forward col. ratio >= safe col. ratio limit
        require(
            getForwardCollateralRatio(
                msg.sender,
                pos.debt + interest_ + _amount,
                _token
            ) >= protocols[_token].borrowThreshold,
            "Not enough collateral to borrow that much"
        );

        // add interest and new debt to position
        pos.debt += (_amount + interest_);
        pos.lastInterest = block.timestamp;

        // enviar ETH al msg.sender
        (bool sent, ) = msg.sender.call{value: _amount, gas: 20317}("");
        
        require(sent, "Failed to send Ether");

        emit Borrow(msg.sender, _amount, pos.debt, pos.collateral, _token);
    }

    // User repays any interest
    function repay(uint256 _amount, address _token) public payable{
        _amount = msg.value;

        require(_amount > 0, "Can't repay 0");

        Position storage pos = protocols[_token].positions[msg.sender];

        uint256 interestDue = calcInterest(msg.sender, _token);

        // account for protocol interest revenue
        if (_amount >= interestDue + pos.debt) {
            pos.debt = 0;
        } else if (_amount >= interestDue) {
            // repays all interest, starts repaying debt
            pos.debt -= (_amount - interestDue);
        } else {
            // repay partial interest, no debt repayment
            pos.debt += (interestDue - _amount);
        }

        // restart interest compounding from here
        pos.lastInterest = block.timestamp;

        emit Repay(msg.sender, _amount, pos.debt, pos.collateral, _token);
    }

    // Liquidates account if collateral ratio below safety threshold
    // Accounts for protocol shortfal as debt 
    // No protocol interest revenue taken on liquidations,
    // as a protocol liquidation fee is taken instead
    function liquidate(address _account, address _token) public {
        Position storage pos = protocols[_token].positions[_account];

        require(pos.collateral > 0, "Account has no collateral");
        
        uint256 interest_ = calcInterest(_account, _token);
        uint256 totalCollateral = pos.collateral; //needed for reporting in event
        uint256 collateralRatio = getForwardCollateralRatio(
            _account,
            pos.debt + interest_,
            _token
        );

        // Check debt + interest puts account below liquidation col ratio
        // acá chequea si la pocisión es liquidable
        require(
            collateralRatio < protocols[_token].liqThreshold,
            "Account not below liquidation threshold"
        );

        // calc fees to protocol and liquidator
        uint256 protocolShare = ((pos.collateral * protocols[_token].liqFeeProtocol) /
            SCALING_FACTOR);
        uint256 liquidatorShare = ((pos.collateral * protocols[_token].liqFeeSender) /
            SCALING_FACTOR);

        require(
            protocolShare + liquidatorShare <= pos.collateral,
            "Liquidation fees incorrectly set"
        );

        // taking protocol fees in token
        // el protocolo queda con sus tokens ya depositados. Solo se transfieren token al liquidador
        require(
            IERC20(_token).transferFrom(
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
            pos.debt + interest_,
            _token
        );
        uint256 protocolDebtCreated;
        if (colRatioAfterFees < SCALING_FACTOR) {
            // if liquidating at col ratio < 100% + fees
            protocolDebtCreated =
                (SCALING_FACTOR - colRatioAfterFees) *
                pos.collateral;
        }

        protocols[_token].protocolDebt += protocolDebtCreated;

        emit Liquidation(
            _account,
            msg.sender,
            totalCollateral,
            collateralRatio,
            pos.debt,
            protocolDebtCreated,
            _token
        );

        pos.collateral = 0;
        pos.debt = 0;
    }

    // Calculates interest on position of given address
    // WARNING: contains fancy math
    function calcInterest(address _account, address _token)
        public
        view
        returns (uint256 interest)
    {
        // si la pocision esta en 0 ó el ultimo interes calculado es del bloque actual
        // retorna CERO
        if (
            protocols[_token].positions[_account].debt == 0 ||
            protocols[_token].positions[_account].lastInterest == 0 ||
            protocols[_token].interestRate == 0 ||
            block.timestamp == protocols[_token].positions[_account].lastInterest
        ) {
            return 0;
        }
        // si el ultimo interes calculado no es del bloque actual
        uint256 secondsSinceLastInterest_ = block.timestamp -
            protocols[_token].positions[_account].lastInterest;
        int128 yearsBorrowed_ = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(secondsSinceLastInterest_),
            SECONDS_IN_YEAR
        );
        int128 interestRate_ = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(protocols[_token].interestRate),
            ABDKMath64x64.fromUInt(SCALING_FACTOR)
        );
        int128 debt_ = ABDKMath64x64.fromUInt(protocols[_token].positions[_account].debt);

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
        return uint256(interest_) - protocols[_token].positions[_account].debt;
    }

    // Calculates forward collateral ratio of an account, using custom debt amount
    function getForwardCollateralRatio(address _account, uint256 _totalDebt, address _token)
        public
        view
        returns (uint256)
    {
        return _getCollateralRatio(_account, _totalDebt, _token);
    }

    // Calculates current collateral ratio of an account.
    // NOTE: EXCLUDES INTEREST
    function getCurrentCollateralRatio(address _account, address _token)
        public
        view
        returns (uint256)
    {
        return _getCollateralRatio(_account, protocols[_token].positions[_account].debt, _token);
    }

    // Internal getColRatio logic
    function _getCollateralRatio(address _account, uint256 _totalDebt, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 collateral_ = protocols[_token].positions[_account].collateral;

        if (collateral_ == 0) {
            // if collateral is 0, col ratio is 0 and no borrowing possible
            return 0;
        } else if (_totalDebt == 0) {
            // if debt is 0, col ratio is infinite
            return type(uint256).max;
        }
        
        // valor del colateral en USD

        (,,,,,uint price,) = assetFactory.divisibleAssetsMap(_token);

        uint256 collateralValue_ = collateral_ * price;

        // valor de ETH en USD
        // TO-DO: ver como testear el oraaculo
        int256 ethValue = priceConsumer.getLatestPrice();
        // se hardcodea hasta ver como testear el oraculo
        //int256 ethValue = 119;

        // valor de la deuda en USD
        uint256 _debtValue = _totalDebt * uint256(ethValue) / SCALING_FACTOR;

        // E.g. 2:1 will return 20 000 (20 000/10 000=2) for 200%
        return (collateralValue_ * SCALING_FACTOR) / (_debtValue);
    }

    // ---------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    // ---------------------------------------------------------------------

    function setFeesAndRates(
        uint256 _liqFeeProtocol,
        uint256 _liqFeeSender,
        uint256 _interestRate,
        address _token
    ) external onlyOwner {
        // Liquidation fees
        require(
            _liqFeeProtocol + _liqFeeSender <= SCALING_FACTOR,
            "Liquidation fees out of range"
        );
        protocols[_token].liqFeeProtocol = _liqFeeProtocol;
        protocols[_token].liqFeeSender = _liqFeeSender;

        // Interest rates - capped at 100% APR
        require(_interestRate <= SCALING_FACTOR, "InterestRate out of range");
        protocols[_token].interestRate = _interestRate;
    }

    function setThresholds(uint256 _borrowThreshold, uint256 _liqThreshold, address _token)
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
        protocols[_token].borrowThreshold = _borrowThreshold;
        protocols[_token].liqThreshold = _liqThreshold;
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