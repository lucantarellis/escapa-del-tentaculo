class_name SpeedBoostConfig
extends Resource
## Parámetros de un [SpeedBoost]. Valores en `resources/configs/speed_boost_config.tres`.
## Ver `docs/mecanicas/tier-espacio.md`.

@export_group("Impulso")
## Duración del impulso. Unidad: s.
@export var duration: float = 1.0
## Multiplicador de la propulsión y de la velocidad máxima durante el impulso.
@export var multiplier: float = 1.8
## Combustible que además recarga al recogerlo (0 = nada). Unidad: u.
@export var fuel_amount: float = 0.0
