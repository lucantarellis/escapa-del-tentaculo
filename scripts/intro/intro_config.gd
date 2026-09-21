class_name IntroConfig
extends Resource
## Parámetros de la intro de la escotilla: golpes, vibración de cámara, gas, ruptura, lanzamiento
## del jugador y entrada del tentáculo.
##
## Se editan desde el inspector sobre `resources/configs/intro_config.tres`. Todos los tiempos y
## magnitudes de la secuencia viven acá; los scripts de la intro no llevan números propios de
## gameplay. Ver `docs/mecanicas/intro-escotilla.md`.

@export_group("Golpes")
## Cantidad de golpes antes de la ruptura.
@export var hit_count: int = 3
## Espera entre el fin del fundido del menú y el primer golpe. Unidad: s.
@export var first_hit_delay: float = 0.6
## Tiempo entre golpes consecutivos. Unidad: s.
@export var hit_interval: float = 1.0
## Pausa entre el último golpe y la ruptura. Unidad: s.
@export var pre_break_pause: float = 0.7

@export_group("Vibración")
## Amplitud de la vibración de cámara del primer golpe. Unidad: px.
@export var shake_amplitude: float = 8.0
## Duración de cada vibración de cámara. Unidad: s.
@export var shake_duration: float = 0.35
## Multiplicador de fuerza de cada golpe respecto del anterior (1 = todos iguales). Unidad: ×.
@export var hit_escalation: float = 1.3

@export_group("Gas")
## Partículas por ráfaga en un golpe normal (se escala con la fuerza del golpe).
@export var gas_amount: int = 24
## Vida de cada partícula de gas. Unidad: s.
@export var gas_lifetime: float = 0.9
## Velocidad de salida del gas. Unidad: px/s.
@export var gas_speed: float = 90.0

@export_group("Ruptura")
## Amplitud de la vibración de cámara de la ruptura. Unidad: px.
@export var break_shake_amplitude: float = 16.0
## Duración de esa vibración. Unidad: s.
@export var break_shake_duration: float = 0.6
## Partículas de la ráfaga grande de gas de la ruptura.
@export var break_gas_amount: int = 80
## Duración de la animación de apertura de las hojas. Unidad: s.
@export var break_duration: float = 0.35
## Fragmentos de polígono que salen despedidos al romperse.
@export var break_debris_count: int = 6

@export_group("Lanzamiento")
## Velocidad vertical inicial del jugador, hacia arriba. Unidad: px/s.
@export var launch_speed: float = 560.0
## Tiempo tras el lanzamiento en que el jugador no responde al Input (la inercia y la gravedad
## siguen actuando). Unidad: s.
@export var control_lock_time: float = 0.5

@export_group("Cámara")
## Distancia mínima entre el jugador y el borde superior de la pantalla mientras la cámara lo sigue
## durante el vuelo. Unidad: px.
@export var camera_follow_margin: float = 120.0
## Tiempo máximo que la cámara sigue al jugador tras el lanzamiento (termina antes si llega al punto
## más alto del vuelo). Unidad: s.
@export var camera_follow_max_time: float = 3.0

@export_group("Tentáculo")
## Espera entre la ruptura y el inicio de la entrada del tentáculo. Unidad: s.
@export var tentacle_entry_delay: float = 1.5
## Duración de la subida del tentáculo desde fuera de pantalla hasta su posición. Unidad: s.
@export var tentacle_entry_duration: float = 1.0
