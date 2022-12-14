# REAL STATE TOKENIZATION

## Introducción

El proyecto consiste en una plataforma en la que se podrán tokenizar activos mediante un token ERC20.

Luego estos tokens podrán ser utilizados en un procolo de Lending & Borrowing.

## Tokenomics

### Tokenización

- Se crea un ERC20 que representa al activo. Todo el supply es propiedad del protocol en el Smart Contract "Controller".

- Se debe especificar el precio total del activo y cuantos tokens se emitirán.

- El creador debe depositar el 10% del precio en ETH, que serán devueltos al venderse el 90% de la propiedad. Estos ETH formarán parte del vault del protocolo de lending & borrowing. El creador a su vez percibirá los intereses de hacer staking de esos ETH (en ETH).

- Los tokens creados serán transferidos al creador.

### Lending & Borrowing

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

### constructor
Se configuran los contratos necesarios para el funcionamiento de la plataforma:
- AssetFactory
- LendingBorrowing
- PriceConsumer

Además se setea al compilador del contrato como Admin.

### createAssetAndProtocol
Se lleva a cabo la tokenización. Recibe los siguientes parametros:
- _initialSupply:  del erc20. En números enteros. Luego se asignan 18 decimales. Por ejemplo si se desean 100 tokens iniciales, se debe pasar el número 100 y luego en el AssetFactory se agregan 18 decimales, quedando 100000000000000000000.
- name_: del erc20.
- symbol_: del erc20.
- _price: en USD, número entero. No se admiten decimales.
- otros parametros financieros. Se explican en dettalle en el contrato LendingBorrowing.

### buyTokens
Para que un usuario pueda comprar tokens pagando con ETH. Recibe los siguientes parámetros:
- _token: address del contrato erc20 que quiere comprar.
-  _qunantuty: en números con 2 decimales. Es la cantidada de tokens que desea adquirir.

### claimInitialValue
Es la función que deevuelve el staking de ETH inicial al usuario tokenizaador. Recibe como parámetro el address del erc20.

### claimTokensSales
Función que trasnfiere el monto de las ventas al tokenizador (dueño del activo real).

## PriceConsumer
Es el contrato que obtiene el precio en USD de ETH a través de un oráculo de ChainLink

## DivisibleAsset

Es un contrato ERC20 que se utilizará en el caso en que un activo sea sometido a una tokenización fraccional.
Cada inmueble tokenizado por esta vía tendrá su propio contrato ERC20.

## AssetFactory

Es el contrato que genera un contrato ERC20 (DivisibleAsset) por cada activo tokenizado.
Utiliza el Factory Pattern

## LendingBorrowing
Es un contrato que gestiona lending & borrowings de cada token ERC20 generado.

### Protocol
Es una estructura que se instanciará por cada token ERC20 creado. Se alojaran en el map "protocols".

Sus atributos son:

- Position: estructura para la pocisión de cada address. Estan contenidas en el array "positions". Compuesta por: 
    - collateral: cantidad de colateral del token ERC20 stakeado.
    - debt: deuda de la pocisión
    - lastInterest: última vez que se calculo el interés y se actualizó la deuda

- token: dirección del contrato ERC20

- procotolTotalCollateral y procotolTotalBorrowed: a fines informativos para visualizar en el frontend

- maxLTV: max ratio between collateral and loan when borrowing

- liqThreshold: Liquidation threshold. This is the threshold at which a borrow position will be considered undercollateralized and subject to liquidation.

- liqFeeProtocol y liqFeeSender: son los fees que se le asignaran al protocolo y al liquidador en el caso de una liquidación.

- protocolDebt: bad debt. when an account is not liquidated on time, the liquidated collateral might not be enough to cover the position’s debt, and it adds to the amount of bad debt within the protocol — which can pose a risk to users.

- borrowThreshold: is the total amount that individuals can borrow

- interestRate: tasa de interés.

- vault: cantidad de ETH en el protocolo, disponible para prestamos y retiros de creadores de tokens.

### Variables 

- SCALING_FACTOR: El factor de escala es un multiplicador que afecta la tasa de interés de los préstamos

- SECONDS_IN_YEAR: for compound interest math



### Métodos

#### constructor
Se configuran los contratos necesarios para el funcionamiento de la plataforma:
- AssetFactory
- PriceConsumer

Además se definen la cantidad de segundos en un año.

#### createProtocol
Se crea una instancia de la estrctura Protocol. Se reciben los parametros:
- _token,
- _maxLTV,
- _liqThreshold,
- _liqFeeProtocol,
- _liqFeeSender,
- _borrowThreshold,
- _interestRate,
- _vault

#### deposit
Se realiza un deposito de colateral en la pocisión del usuario en el protocolo. Se reciben los paramtros:
- _amount
- _token

#### withdraw
Se realiza un retiro de colateral de la pocisión del usuario en el protocolo. Se reciben los paramtros:
- _amount
- _token

El proceso consiste en:
- Calcular el monto "retirable".
- Actualizar la deuda (el interés) y registrar el bloque de esta actualizacion.
- Si la deuda es igual a cero, el retirable es igual al monto pasado por parámetro.
- Si la deuda es distinta a cero:
- - Se calcula el ColateralRatio actual
- - El retirable será: (colateral / ColateralRatio) * (ColateralRatio - borrowThreshold)
- Si el retirable es menor o igual al monto pasado por parámetro se hace el retiro por el importe de esté ultimo.
- Ese monto pasado por parámetro se descuenta del colateral.

#### borrow 
Se solicita un prestama de ETH al protocolo, considerando el colateral depositado previamente. Se reciben los parámetros:
- monto solicitado
- token del protocolo

El proceso consiste en:
- obtener interes de la pocisión
- getForwardCollateralRatio donde la deuda sera el interes calculado en el punto anterior + la deuda de la pocisión + el monto solicitado
- este ultimo debe ser mayor o igual al colateral
- se actualiza la deuda de la pocisión
- se transfiere el prestamo en ETH

#### repay
Pagos de prestamos al protocolo. Se reciben los parámetros:
- monto a pagar (por value de llamada a funcion payable)
- token del protocolo

El proceso consiste en:
- obtener interes de la pocisión
- si el monto a pagar es mayor o igual al interes + la deuda de la pocision, queda saldada la deuda
- sino, si el monto es, al menos, mayor o igual a solo el interes, se descuenta a la deuda total, el monto a pagar menos el interes
- sino, se suma a la deuda total, el interes menos el monto a pagar
- finalmente, se atualiza la deuda

#### liquidate
Se liquidación las pocisiones cuya colateral, ya no cubre el monto prestado en ETH. Se reciben los parámetros:
- Cuenta
- Token del protocolo

Proceso:
- Primero se chequea si la cuenta posee colateral
- Luego se calculan: el interes y el colateral ratio, donde la deuda es la deuda de la pocisión + el interés.
- Si el colateral ratio esta por debajo del _liqThreshold, no se puede liquidar
- Luego se calculan los fees para el protocolo y para el liquidador, en base al colateral de la pocisión a liquidar y el SCALING_FACTOR
- Se transfieren los fees al liquidador. El protocolo queda con los fees en su poder.
- Se recalcula el colateral de la posición, retandole la sumas de los fees anteriores.
- Se calcula la bad debt del protocolo en base al colateral ratio con el nuevo colateral, pasando como deuda la deuda de la pocisión + el interes
- Si el nuevo colateral ratio es menor al SCALING_FACTOR se ha creado bad debt, que es igual a multiplicar el nuevo colateral por la diferencia entre el SCALING_FACTOR y el nuevo colateral ratio. Se actualiza la bad debt del protocolo.
- Se actualizan el colateral y la deuda de la pocisión a 0.


### Métodos financieros

#### calcInterest
Calcula el interés actual de una pocisión. Se utiliza interés compuesto continuo. Reciben como parámetros:
- Cuenta
- Token del protocolo

- si la pocision esta en 0 ó el ultimo interes calculado es del bloque actual,el interes es 0.
- si el ultimo interes calculado no es del bloque actual:
- - calcula los segundos desde el ultimo calculo de interes
- - calcula los años que representan los segundos del punto anterior
- - Calcula la tasa de interes, tomando la tasa de interes del protocolo sobre el SCALING_FACTOR
- - Calcula el interes compuesto como resultado de: 

Formula: P*e^(i*t)

donde:
- P: deuda
- i: tasa de interes sobre el scalling factor
- t: tiempo en años

- - Retorno el interes calculado en el punto anterior menos la deuda

#### _getCollateralRatio
Calcula el ratio de colateral. Recibe como parámetros:
- una cuenta
- deuda
- token del protocolo

- Si el colateral es igual a cero, el ratio es 0.
- Sino, si la deuda es igual a cero, el ratio es infinito.
- Si ni el colateral, ni la deuda son cero:
- - Se obtiene el precio del token
- - El valor del colateral es la cantidad de colateral por precio.
- - Se obtiene el precio de ETH.
- - El valor de la deuda es la cantidad de deuda por el precio de ETH sobre el SCALING_FACTOR.
- - el ratio es igual al valor del colateral por el SCALING_FACTOR sobre el valor de la deuda.

#### getCurrentCollateralRatio
Obtiene el ratio de colateral actual. Recibe como parametros:
- Cuenta
- Token del protocolo

#### getForwardCollateralRatio
Obtiene el ratio de colateral con una deuda dada. Recibe como parametros:
- Cuenta
- Deuda
- Token del protocolo