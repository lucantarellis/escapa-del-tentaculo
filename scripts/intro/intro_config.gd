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

@export_group("Luz del nivel")
## El nivel arranca con la luz de la nave encendida (como el hub), cada golpe de la escotilla la
## desestabiliza y la ruptura la apaga: queda la oscuridad de la nave (`LightingConfig.ambient_color`).
## Color por el que se multiplica el mundo al arrancar la intro (el del hub).
@export var intro_ambient_color: Color = Color(0.74, 0.77, 0.84)
## Cuánto se apaga de base la luz con cada golpe (0–1: 0 = nada, 1 = hasta la oscuridad de la nave)
## y en cuánto tarda. Unidad: s.
@export_range(0.0, 1.0, 0.01) var light_drop_per_hit: float = 0.12
@export var light_drop_time: float = 0.15
## Titileo de cada golpe: cuánto cae la luz (0–1) en el primer golpe, se multiplica por
## `hit_escalation` en cada golpe (tope 1), y tiempo entre cambios bruscos (mín. y máx.). Unidad: s.
## El del último golpe dura hasta la ruptura y los demás hasta el golpe siguiente.
@export_range(0.0, 1.0, 0.01) var flicker_depth: float = 0.35
@export var flicker_step_min: float = 0.03
@export var flicker_step_max: float = 0.12
## Corte de luz de la ruptura: en cuánto se va a la oscuridad de la nave. Unidad: s.
@export var power_off_time: float = 0.08

@export_group("Luz de la escotilla")
## La escotilla tiene tres luces que siguen el estado (cerrada → cada golpe → ruptura → rota):
## la luz que ilumina el entorno (piso, paredes, astronauta), un halo rojo visible alrededor y un
## haz que se escapa por la rendija hacia arriba. Halo y haz no los oscurece la nave oscura.

## Color de la luz que ilumina el entorno.
@export var hatch_light_color: Color = Color("CD1417")
## Radio de la luz del entorno. Unidad: px.
@export var hatch_light_radius: float = 170.0
## Altura de la luz del entorno sobre las paredes: más alta, llega más lejos (ver LightingConfig).
## Unidad: px.
@export var hatch_light_height: float = 90.0
## Energía de la luz del entorno: cerrada, lo que suma cada golpe, pico en la ruptura y rota.
@export var hatch_light_energy_closed: float = 0.15
@export var hatch_light_energy_per_hit: float = 0.35
@export var hatch_light_energy_break: float = 2.5
@export var hatch_light_energy_broken: float = 1.0

## Color y tamaño (ancho, alto) del halo rojo alrededor de la escotilla. Unidad: px.
@export var hatch_halo_color: Color = Color(1.0, 0.12, 0.1)
@export var hatch_halo_size: Vector2 = Vector2(240.0, 130.0)
## Intensidad del halo (0–1): cerrada, lo que suma cada golpe, pico en la ruptura y rota.
@export_range(0.0, 1.0, 0.01) var hatch_halo_closed: float = 0.06
@export_range(0.0, 1.0, 0.01) var hatch_halo_per_hit: float = 0.12
@export_range(0.0, 1.0, 0.01) var hatch_halo_break: float = 1.0
@export_range(0.0, 1.0, 0.01) var hatch_halo_broken: float = 0.6

## Color y tamaño (ancho arriba, alto) del haz que se escapa por la rendija. Unidad: px.
@export var hatch_beam_color: Color = Color(1.0, 0.15, 0.1)
@export var hatch_beam_size: Vector2 = Vector2(120.0, 200.0)
## Intensidad del haz (0–1): lo que suma cada golpe (cerrada no hay), pico en la ruptura y rota.
@export_range(0.0, 1.0, 0.01) var hatch_beam_per_hit: float = 0.2
@export_range(0.0, 1.0, 0.01) var hatch_beam_break: float = 1.0
@export_range(0.0, 1.0, 0.01) var hatch_beam_broken: float = 0.5

## Destello de cada golpe: cuánto más brillan las tres luces en el impacto (0,5 = 50 % más) antes
## de volver a su nivel.
@export var hatch_hit_flash: float = 0.6
## Tiempo con que las luces pasan de un nivel al otro. Unidad: s.
@export var hatch_light_fade: float = 0.3
## Respiración del halo y el haz con la escotilla rota: cuánto varían (0–1) y a qué velocidad (Hz).
@export_range(0.0, 1.0, 0.05) var hatch_breath_amount: float = 0.2
@export var hatch_breath_speed: float = 0.7
