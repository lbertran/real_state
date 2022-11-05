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
- Position: estructura para la pocisión de cada address. Compuesta por: 
    - collateral: cantidad de colateral del token ERC20 stakeado.
    - debt: deuda de la pocisión
    - lastInterest: último interés



