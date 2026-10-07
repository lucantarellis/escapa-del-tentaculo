class_name TentacleConfig
extends Resource
## Parámetros del tentáculo: posición, letalidad y animación.
##
## Se editan desde el inspector sobre `resources/configs/tentacle_config.tres`.
## Ver `docs/mecanicas/tentaculo.md`.

@export_group("Posición")
## Cuánto del tentáculo se ve sobre el borde inferior de la pantalla. Unidad: px.
@export var visible_height: float = 70.0
## Velocidad adicional de ascenso respecto de la cámara (0 = pegado al borde). Solo con la
## cámara en modo anterior (`ScrollConfig.follow_player` apagado). Unidad: px/s.
@export var extra_rise_speed: float = 0.0

@export_group("Ascenso propio")
## Velocidad con la que el tentáculo sube por el nivel cuando la cámara sigue al jugador
## (`ScrollConfig.follow_player`). Sube aunque el jugador no se mueva y puede quedar fuera de
## la pantalla. Unidad: px/s.
@export var rise_speed: float = 40.0
## Si es true, la velocidad de ascenso aumenta con el tiempo (ver `rise_acceleration`). Si es
## false, el tentáculo sube siempre a `rise_speed`.
@export var rise_acceleration_enabled: bool = true
## Aumento de la velocidad de ascenso por segundo, desde `rise_speed` hasta `max_rise_speed`.
## Solo con `rise_acceleration_enabled`. Unidad: px/s².
@export var rise_acceleration: float = 1.0
## Tope de la velocidad de ascenso cuando hay aceleración. Unidad: px/s.
@export var max_rise_speed: float = 120.0

@export_group("Final del nivel")
## Si es true, cuando la cámara llega a su tope (final del nivel) el tentáculo sigue subiendo
## hasta cubrir toda la pantalla, así el jugador no queda a salvo esperando. Solo con la cámara
## en modo anterior: siguiendo al jugador el tentáculo siempre sube.
@export var rise_after_camera_stops: bool = true
## Velocidad de ascenso del tentáculo una vez detenida la cámara (se suma a `extra_rise_speed`).
## Unidad: px/s.
@export var end_rise_speed: float = 40.0

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
