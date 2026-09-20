class_name ScrollConfig
extends Resource
## Parámetros del scroll vertical de la cámara y de los límites invisibles de pantalla.
##
## Se editan desde el inspector sobre `resources/configs/scroll_config.tres`.
## Ver `docs/mecanicas/scroll-camara.md`.

@export_group("Scroll")
## Velocidad de ascenso de la cámara. Unidad: px/s.
@export var scroll_speed: float = 40.0
## Aumento progresivo de la velocidad (0 = velocidad constante). Unidad: px/s².
@export var scroll_acceleration: float = 0.0
## Tope de velocidad cuando hay aceleración. Unidad: px/s.
@export var max_scroll_speed: float = 120.0
## Espera antes de empezar a subir, contada desde el inicio o el reinicio. Unidad: s.
@export var start_delay: float = 2.0

@export_group("Fin")
## Si es true, la cámara se detiene al llegar a `stop_at_y`.
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
