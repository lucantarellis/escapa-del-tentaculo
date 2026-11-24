class_name HubConfig
extends Resource
## Parámetros del hub (la nave intacta que hace de menú): luz, puertas, ascensor y vista del
## espacio. Los usa [Hub]. Ver `docs/mecanicas/hub.md` y `docs/arte/hub.md`.

@export_group("Ambiente")
## Color por el que se multiplica el hub (mucho más claro que la partida, levemente frío).
@export var ambient_color: Color = Color(0.74, 0.77, 0.84)
## Luces de techo: color, energía y radio (px).
@export var ceiling_light_color: Color = Color("E7EFF2")
@export var ceiling_light_energy: float = 0.9
@export var ceiling_light_radius: float = 170.0
## Apliques de pared: color, energía y radio (px).
@export var wall_light_color: Color = Color("C8E7EA")
@export var wall_light_energy: float = 0.5
@export var wall_light_radius: float = 90.0
## Luz suave general desde abajo al centro: energía y radio (px).
@export var fill_light_energy: float = 0.35
@export var fill_light_radius: float = 260.0

@export_group("Puertas")
## Ancho del área delante de la puerta que la abre (px).
@export var door_trigger_width: float = 48.0
## Luz de cada puerta abierta: energía máxima, alcance (px) y titileo (fracción, ±).
@export var door_light_energy: float = 0.9
@export var door_light_range: float = 110.0
@export var door_light_flicker: float = 0.05
## Haz visible: alfa en la puerta, largo hacia la sala y alto en el hueco (px).
@export var door_beam_alpha: float = 0.35
@export var door_beam_length: float = 80.0
@export var door_beam_height: float = 67.0
## Fundido a negro al entrar o salir de Ajustes / Mercado. Unidad: s.
@export var door_fade_time: float = 0.25
## Cuánto camina el astronauta al salir de la puerta (del hueco al piso). Unidad: s.
@export var door_walk_time: float = 0.6

@export_group("Ascensor")
## Tiempo parado sobre la plataforma hasta que se arma (lo que dura `arming`). Unidad: s.
@export var elevator_arm_time: float = 1.0
## Cuánto se separa cada mordaza al soltarse (px) y en cuánto tiempo (s).
@export var clamp_open_offset: float = 6.0
@export var clamp_open_time: float = 0.24
## Velocidad máxima de la subida (px/s) y tiempo hasta alcanzarla (s).
@export var elevator_max_speed: float = 400.0
@export var elevator_accel_time: float = 1.2
## Distancia que sube antes del fundido a la partida (px).
@export var elevator_ride_distance: float = 560.0
## Fundido a negro al terminar la subida. Unidad: s.
@export var launch_fade_time: float = 0.3
## Luz de cada baliza de las mordazas: energía, radio (px) y energía baja del latido rojo.
@export var beacon_energy: float = 0.8
@export var beacon_radius: float = 60.0
@export var beacon_low_energy: float = 0.25

@export_group("Espacio")
## Velocidad de la deriva del espacio por los ventanales (px/s) y qué tan rápido cambia su
## dirección (rad/s).
@export var space_drift_speed: float = 3.0
@export var space_drift_turn: float = 0.05
## Rotación de la vista (grados por segundo) y cada cuánto puede cambiar de sentido (s, mín. y máx.).
@export var space_rotation_speed: float = 0.25
@export var space_rotation_flip_min: float = 20.0
@export var space_rotation_flip_max: float = 45.0
