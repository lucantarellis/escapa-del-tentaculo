class_name TentacleSeaConfig
extends Resource
## Parámetros del mar de tentáculos de la nave ([TentacleSea]): densidad, ubicación, variedad y
## cuándo los tentáculos de adelante intentan agarrar.
##
## Es solo visual: la zona letal del [Tentacle] no cambia. Se asigna en `TentacleConfig.sea`; sin
## él, el tentáculo usa el frente anterior o el bloque de color. Ver `docs/mecanicas/tentaculo.md`.

@export_group("Densidad")
## Cantidad de tentáculos de adelante.
@export var front_count: int = 8
## Separación entre tentáculos de adelante. Unidad: px.
@export var front_spacing: float = 52.0
## Cantidad de tentáculos de relleno (fila de atrás).
@export var fill_count: int = 12
## Separación entre tentáculos de relleno. Unidad: px.
@export var fill_spacing: float = 34.0

@export_group("Ubicación")
## Cuánto asoman las puntas de los tentáculos de adelante por encima del borde de la zona letal.
## Esa franja se ve pero no mata: el borde letal queda donde el mar ya está cerrado (a ~140 px bajo
## las puntas los tentáculos cubren ~95 % del ancho; a 24 px, solo ~20 %). Unidad: px.
@export var tip_overhang: float = 140.0
## Cuánto quedan las bases de los tentáculos de adelante por debajo del borde superior de la
## carne (`tentacle_flesh`). Unidad: px.
@export var front_base_depth: float = 85.0
## Ídem para los tentáculos de relleno. Unidad: px.
@export var fill_base_depth: float = 60.0
## Variación al azar de la altura de cada base (más o menos). Unidad: px.
@export var base_jitter: float = 6.0

@export_group("Variedad")
## Rango de `speed_scale` de cada tentáculo (se sortea uno por tentáculo).
@export var speed_scale_min: float = 0.85
@export var speed_scale_max: float = 1.15
## Brillo de la fila de relleno (multiplica el color: 1 = igual, 0 = negro).
@export_range(0.0, 1.0) var fill_brightness: float = 0.6

@export_group("Agarre")
## Cada cuánto, como mínimo y como máximo, un tentáculo de adelante intenta agarrar por su cuenta
## (`reach` → `grab` → `retract`). Unidad: s.
@export var reach_interval_min: float = 4.0
@export var reach_interval_max: float = 9.0
## Si el jugador está a menos de esta distancia por encima del borde de la zona letal, el tentáculo
## de adelante que le queda debajo intenta agarrarlo en cuanto puede (sin esperar el intervalo).
## 0 = nunca. Unidad: px.
@export var grab_distance: float = 120.0
## Máximo de tentáculos de adelante agarrando a la vez.
@export var max_reaching: int = 2
