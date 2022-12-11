# REAL STATE TOKENIZATION

## Introducción

El proyecto consiste en una plataforma mediante la cual se podrán tokenizar activos mediante un token ERC20.

Luego estos tokens podrán ser utilizados en un procolo de Lending & Borrowing.

## Tokenomics

### Tokenización

- Se crea un ERC20 que representa al activo. 

- Se debe especifica la cantidad a emitir y el precio de 1 token en el momento de la creación.

- El creador debe depositar el 10% del precio en ETH, que serán devueltos al venderse el 90% de la propiedad. Estos ETH formarán parte del vault del protocolo de lending & borrowing. El creador a su vez percibirá los intereses de hacer staking de esos ETH (en ETH).

- Los tokens creados serán transferidos al creador.

### Lending & Borrowing

- Existirá un SC de L&B por cada ERC20 creado en la tokenización.

- Lending: se depositarán ERC20.

- Borrowing: se prestarán ETH del protocolo.

# Ejecución

## Testing

- Testear en fork goerli: para esto se incluye en el archivo hardhat.config.ts la siguiente red

```
 networks: {
        hardhat: {
          forking: {
            // eslint-disable-next-line
            enabled: true,
            url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      }
```
Luego tan solo levantar el nodo con:

```
npx hardhat node
```

y correr los tests con 

```
npx hardhat test
```
## Deploy

npx hardhat run --network goerli scripts/deploy.ts

También se crearán los archivos necesarios para el funcionamiento de la DApp

verificar los contratos creados para poder usar etherscan (address del contrato y parametros iniciales - en wei )
npx hardhat verify --network goerli direccion-del-contrato

## Frontend

```
cd frontend
npm run start
```

# SMART CONTRACTS

## Controller
Controla toda la operación, envía peticiones a AssetFactory y LendingBorrowingFactory

## PriceConsumer
Es el contrato que obtiene el precio en USD de ETH a través de un oráculo de ChainLink

## DivisibleAsset

Es un contrato ERC20 que se utilizará en el caso en que un activo sea sometido a una tokenización fraccional.
Cada inmueble tokenizado por esta vía tendrá su propio contrato ERC20.

## AssetFactory

Es el contrato que genera un contrato ERC20 (DivisibleAsset) por cada activo tokenizado.
Utiliza el Factory Pattern

## LendingBorrowing
Es un contrato que gestiona lending & borrowings de cada token ERC20 generado. Cada inmueble tokenizado con ERC20 tendrá su propio contrato LendingBorrowing.

VARIABLES
- token: dirección del contrato ERC20

- Position: estructura para la pocisión de cada address. Estan contenidas en el array "positions". Compuesta por: 
    - collateral: cantidad de colateral del token ERC20 stakeado.
    - debt: deuda de la pocisión
    - lastInterest: última vez que se calculo el interés y se actualizó la deuda

- procotolTotalCollateral y procotolTotalBorrowed: a fines informativos para visualizar en el frontend

- maxLTV: max ratio between collateral and loan when borrowing

- liqThreshold: Liquidation threshold. This is the threshold at which a borrow position will be considered undercollateralized and subject to liquidation.

- liqFeeProtocol y liqFeeSender: son los fees que se le asignaran al protocolo y al liquidador en el caso de una liquidación.

- protocolDebt: bad debt. when an account is not liquidated on time, the liquidated collateral might not be enough to cover the position’s debt, and it adds to the amount of bad debt within the protocol — which can pose a risk to users.

- borrowThreshold: is the total amount that individuals can borrow

- interestRate: tasa de interés.

- scaling factor: El factor de escala es un multiplicador que afecta la tasa de interés de los préstamos

- SECONDS_IN_YEAR: for compound interest math

INTERÉS
Se utiliza interés compuesto continuo.

Formula: P*e^(i*t)

donde:
- P: deuda
- i: tasa de interes sobre el scalling factor
- t: tiempo en años

## LendingBorrowingFactory
Es el contrato que genera un contrato de Lendgin&Borrowing por cada activo tokenizado con un ERC20.


