class_name IntroConfig
extends Resource
## Parámetros de la intro de la escotilla: golpes, vibración de cámara y gas.
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
