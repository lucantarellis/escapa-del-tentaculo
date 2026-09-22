class_name PlayerConfig
extends Resource
## Parámetros de gameplay del jugador (jetpack, gravedad, combustible, salto, colisión).
##
## Todos los valores son un punto de partida para iterar jugando. Se editan desde el
## inspector sobre `resources/configs/player_config.tres`; ningún número de gameplay
## debe escribirse directamente en `player.gd`. Ver `docs/mecanicas/jugador.md`.

@export_group("Propulsión")
## Aceleración al mantener una dirección. Unidad: px/s².
@export var thrust_acceleration: float = 700.0
## Tope de velocidad al propulsar. Unidad: px/s.
@export var max_speed: float = 180.0
## Multiplica la aceleración en cada eje donde la entrada se opone a la velocidad actual
## (facilita frenar). Unidad: multiplicador (×).
@export var counter_thrust_multiplier: float = 1.5
## Frenado cuando no hay entrada o no se puede propulsar. Define la "deriva suave".
## Unidad: px/s².
@export var coasting_drag: float = 90.0

@export_group("Caminar")
## Aceleración horizontal al caminar sobre una superficie. No consume combustible.
## Unidad: px/s².
@export var walk_acceleration: float = 600.0
## Velocidad máxima al caminar. Unidad: px/s.
@export var walk_max_speed: float = 100.0
## Frenado horizontal al soltar la entrada estando apoyado y sin propulsar (brief 06,
## ronda 1: antes se usaba `coasting_drag`, pensado para el aire, y el jugador se
## deslizaba de más con los pies en el piso). Unidad: px/s².
@export var ground_friction: float = 400.0

@export_group("Gravedad")
## Gravedad mientras hay combustible (casi nula). Unidad: px/s².
@export var gravity_with_fuel: float = 30.0
## Gravedad cuando el combustible está vacío. Unidad: px/s².
@export var gravity_without_fuel: float = 500.0
## Tiempo que tarda la gravedad en pasar de un valor al otro. Unidad: s.
@export var gravity_transition_time: float = 0.5
## Velocidad máxima de caída. Unidad: px/s.
@export var max_fall_speed: float = 400.0

@export_group("Combustible")
## Capacidad del tanque. Unidad: u (unidades de combustible).
@export var max_fuel: float = 100.0
## Combustible al iniciar o reiniciar. Unidad: u.
@export var starting_fuel: float = 100.0
## Consumo mientras se propulsa. Unidad: u/s.
@export var fuel_consumption_per_second: float = 15.0
## Por debajo (o igual) de este valor no se puede propulsar. Unidad: u.
@export var min_fuel_to_thrust: float = 0.0
## Regeneración pasiva mientras no se propulsa (0 = solo tanques). Unidad: u/s.
@export var fuel_regen_per_second: float = 0.0

@export_group("Salto")
## Velocidad vertical hacia arriba que se aplica al saltar. Unidad: px/s.
@export var jump_velocity: float = 260.0
## Si es true, solo se puede saltar sin combustible.
@export var jump_requires_empty_fuel: bool = true
## Combustible menor o igual a este valor cuenta como "vacío" (salto, gravedad, color).
## Unidad: u.
@export var jump_empty_threshold: float = 0.0
## Si es true, solo se puede saltar apoyado en una superficie.
@export var jump_requires_floor: bool = true

@export_group("Colisión")
## Rebote al chocar: 0 = se detiene o desliza, 1 = rebote elástico. Rango: 0 a 1.
@export_range(0.0, 1.0) var wall_bounce: float = 0.25
## Velocidad de impacto mínima (componente hacia la superficie) para que haya rebote.
## Evita que el jugador "vibre" al apoyarse. Unidad: px/s.
@export var bounce_min_speed: float = 40.0
