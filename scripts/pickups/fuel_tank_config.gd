class_name FuelTankConfig
extends Resource
## Parámetros de un [FuelTank]: cuánto recarga, cuándo se puede recoger y su animación.
##
## Valores por defecto en `resources/configs/fuel_tank_config.tres`. Para que una instancia
## recargue otra cantidad, duplicar el `.tres` y asignarlo en su `Config`.
## Ver `docs/mecanicas/tanques.md`.

@export_group("Recarga")
## Combustible que suma al recogerlo (el jugador nunca supera su `max_fuel`). Unidad: u.
@export var fuel_amount: float = 40.0
## Si es true, no se recoge mientras el combustible del jugador esté lleno.
@export var only_if_not_full: bool = false
## Tiempo hasta reaparecer tras recogerlo (0 = un solo uso). Unidad: s.
@export var respawn_time: float = 0.0

@export_group("Visual")
## Amplitud del vaivén vertical (0 = quieto). Solo visual. Unidad: px.
@export var bob_amplitude: float = 3.0
## Velocidad del vaivén. Solo visual. Unidad: Hz.
@export var bob_frequency: float = 1.0
