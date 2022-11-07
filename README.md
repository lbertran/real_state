# SMART CONTRACTS

# DivisibleAsset

Es un contrato ERC20 que se utilizará en el caso en que un activo sea sometido a una tokenización fraccional.
Cada inmueble tokenizado por esta vía tendrá su propio contrato ERC20.

# AssetFactory

Es el contrato que genera un contrato ERC20 (DivisibleAsset) o ERC1155 por cada inmueble tokenizado.
Utiliza el Factory Pattern

# LendingBorrowing
Es un contrato que gestiona lending & borrowings de cada token ERC20 generado. Cada inmueble tokenizado con ERC20 tendrá su propio contrato LendingBorrowing.

VARIABLES
- token: dirección del contrato ERC20

- Position: estructura para la pocisión de cada address. Estan contenidas en el array "positions". Compuesta por: 
    - collateral: cantidad de colateral del token ERC20 stakeado.
    - debt: deuda de la pocisión
    - lastInterest: último interés

- procotolTotalCollateral y procotolTotalBorrowed: a fines informativos para visualizar en el frontend

- maxLTV: max ratio between collateral and loan when borrowing

- liqThreshold: Liquidation threshold. This is the threshold at which a borrow position will be considered undercollateralized and subject to liquidation.

- liqFeeProtocol y liqFeeSender: son los fees que se le asignaran al protocolo y al liquidador en el caso de una liquidación.

- protocolDebt: bad debt. when an account is not liquidated on time, the liquidated collateral might not be enough to cover the position’s debt, and it adds to the amount of bad debt within the protocol — which can pose a risk to users.

- borrowThreshold: is the total amount that individuals can borrow

- interestRate: tasa de interés.
