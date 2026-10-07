class_name ScrollConfig
extends Resource
## Parámetros del seguimiento / scroll vertical de la cámara y de los límites invisibles de pantalla.
##
## Se editan desde el inspector sobre `resources/configs/scroll_config.tres`.
## Ver `docs/mecanicas/scroll-camara.md`.

@export_group("Seguimiento")
## Si es true, la cámara sigue al jugador (sube y baja con él) en vez de subir sola. Con false
## vuelve al modo anterior: sube a `scroll_speed` y el tentáculo va anclado a su borde inferior.
@export var follow_player: bool = true
## En qué parte de la pantalla se ve al jugador, medida desde el borde superior (0 = arriba,
## 0.5 = centro, 1 = abajo). Solo con `follow_player`. Unidad: fracción de la altura (0 a 1).
@export_range(0.0, 1.0, 0.01) var follow_screen_ratio: float = 0.6
## Qué tan rápido alcanza la cámara al jugador: mayor = más pegada, 0 = sin retraso (pegada).
## Solo con `follow_player`. Unidad: 1/s.
@export var follow_smoothing: float = 6.0
## Si es true, la cámara nunca baja más allá de donde arrancó: evita ver el vacío de abajo al
## empezar, cuando el jugador aparece más abajo que `follow_screen_ratio`. Solo con
## `follow_player`. Con false la cámara también baja por debajo de su posición inicial.
@export var follow_stay_above_start: bool = true

@export_group("Scroll")
## Velocidad de ascenso de la cámara. Solo con `follow_player` apagado. Unidad: px/s.
@export var scroll_speed: float = 40.0
## Aumento progresivo de la velocidad (0 = velocidad constante). Solo con `follow_player` apagado.
## Unidad: px/s².
@export var scroll_acceleration: float = 0.0
## Tope de velocidad cuando hay aceleración. Solo con `follow_player` apagado. Unidad: px/s.
@export var max_scroll_speed: float = 120.0
## Espera antes de empezar a subir, contada desde el inicio o el reinicio. Con `follow_player` la
## cámara no la espera (sigue al jugador en cuanto llega a la altura deseada), pero el tentáculo sí:
## empieza a subir cuando termina. Unidad: s.
@export var start_delay: float = 2.0

@export_group("Fin")
## Si es true, la cámara no sube más allá de `stop_at_y`.
@export var stop_at_enabled: bool = false
## Coordenada Y (mundo) del centro de la cámara donde se detiene. Unidad: px.
@export var stop_at_y: float = -2400.0

@export_group("Límites")
## Activa las paredes invisibles laterales.
@export var side_walls_enabled: bool = true
## Activa la pared invisible superior.
@export var top_wall_enabled: bool = true
## Separación de la pared superior respecto del borde superior de la pantalla (positivo =
## la pared queda más adentro). Unidad: px.
@export var top_wall_margin: float = 0.0
