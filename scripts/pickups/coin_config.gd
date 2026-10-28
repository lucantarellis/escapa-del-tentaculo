class_name CoinConfig
extends Resource
## Parámetros de una [Coin]: cuánto vale y su animación.
##
## Valores por defecto en `resources/configs/coin_config.tres`.
## Ver `docs/mecanicas/progreso-mercado.md`.

@export_group("Valor")
## Monedas que suma al recogerla. Unidad: monedas.
@export var value: int = 1

@export_group("Visual")
## Amplitud del vaivén vertical (0 = quieta). Solo visual. Unidad: px.
@export var bob_amplitude: float = 2.0
## Velocidad del vaivén. Solo visual. Unidad: Hz.
@export var bob_frequency: float = 1.2
