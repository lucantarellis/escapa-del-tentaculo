class_name TentacleConfig
extends Resource
## Parámetros del tentáculo: posición, letalidad y animación.
##
## Se editan desde el inspector sobre `resources/configs/tentacle_config.tres`.
## Ver `docs/mecanicas/tentaculo.md`.

@export_group("Posición")
## Cuánto del tentáculo se ve sobre el borde inferior de la pantalla. Unidad: px.
@export var visible_height: float = 70.0
## Velocidad adicional de ascenso respecto de la cámara (0 = pegado al borde). Unidad: px/s.
@export var extra_rise_speed: float = 0.0

@export_group("Letalidad")
## Margen de gracia: la zona letal empieza este valor por debajo del borde superior del
## polígono visible. Unidad: px.
@export var kill_zone_inset: float = 10.0
## Si es true, caer por debajo del borde inferior de la pantalla también mata.
@export var kill_on_leaving_screen_bottom: bool = true
## Cuánto por debajo del borde inferior (medido desde el centro del jugador) cuenta como
## caída. Unidad: px.
@export var screen_bottom_margin: float = 24.0

@export_group("Animación")
## Amplitud de la ondulación del borde superior (0 = sin ondulación). Unidad: px.
@export var wobble_amplitude: float = 6.0
## Velocidad de la ondulación. Unidad: Hz.
@export var wobble_frequency: float = 2.0
## Cantidad de segmentos del borde superior (más segmentos = borde más suave).
@export var wobble_segments: int = 12
