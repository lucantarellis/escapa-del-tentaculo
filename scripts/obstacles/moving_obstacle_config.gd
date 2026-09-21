class_name MovingObstacleConfig
extends Resource
## Parámetros de un [MovingObstacle]: velocidad, pausas y suavizado del movimiento.
##
## Valores por defecto en `resources/configs/moving_obstacle_config.tres`. Para dar a una
## instancia valores propios (por ejemplo otro `start_delay`), hacer el recurso único en el
## inspector ("Make Unique") o duplicar el `.tres`. Ver `docs/mecanicas/obstaculos.md`.

@export_group("Movimiento")
## Velocidad media de desplazamiento. Con `ease_at_ends` el pico es 1,5 veces esta velocidad.
## Unidad: px/s.
@export var speed: float = 60.0
## Pausa en cada extremo del recorrido. Unidad: s.
@export var pause_at_ends: float = 0.5
## Si es true, acelera y frena suave cerca de los extremos.
@export var ease_at_ends: bool = true
## Espera antes de empezar a moverse; sirve para desfasar varias instancias. Unidad: s.
@export var start_delay: float = 0.0
