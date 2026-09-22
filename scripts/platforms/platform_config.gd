class_name PlatformConfig
extends Resource
## Parámetros de tuning de una [Platform]: tiempos de rotura, reaparición y ciclo temporizado.
##
## Lo que es *diseño de nivel* (tamaño, tipo, posición) se edita en la instancia; esto es
## *tuning* y vive en un `Resource`, igual que [MovingObstacleConfig] y [PulseTrapConfig].
## Para que una instancia tenga tiempos propios, hacer el recurso único en el inspector
## ("Make Unique") o duplicar el `.tres`. Ver `docs/mecanicas/plataformas.md`.

@export_group("Rompible (BREAKABLE)")
## Segundos parado encima antes de que se rompa. Unidad: s.
@export var break_delay: float = 0.15
## Segundos hasta que reaparece tras romperse. Unidad: s.
@export var respawn_time: float = 2.0

@export_group("Temporizada (TIMED)")
## Segundos sólida por ciclo. Unidad: s.
@export var timed_on_duration: float = 2.0
## Segundos atravesable (invisible) por ciclo. Unidad: s.
@export var timed_off_duration: float = 1.0
## Si el ciclo empieza sólida (true) o atravesable (false).
@export var timed_start_on: bool = true

@export_group("One-way")
## Margen de detección de colisión de un solo sentido. Muy chico puede dejar atravesar al
## jugador en una caída rápida; ver nota en `docs/mecanicas/plataformas.md`. Unidad: px.
@export var one_way_margin: float = 5.0

@export_group("Letal (LETHAL / PULSE en ON)")
## Cuánto más chico es el área letal que el dibujo, por lado (se resta de cada borde). Da
## margen de gracia en las esquinas: sin esto, rozar apenas la esquina de un bloque angosto
## cuenta como golpe aunque no se sienta así. Unidad: px.
@export var lethal_margin: float = 2.0

@export_group("Movimiento (moves = true)")
## Velocidad media de desplazamiento. Con `moving_ease_at_ends` el pico es 1,5x. Unidad: px/s.
@export var moving_speed: float = 60.0
## Pausa en cada extremo del recorrido. Unidad: s.
@export var moving_pause_at_ends: float = 0.5
## Si es true, acelera y frena suave cerca de los extremos.
@export var moving_ease_at_ends: bool = true
## Espera antes de empezar a moverse; sirve para desfasar varias instancias. Unidad: s.
@export var moving_start_delay: float = 0.0

@export_group("Pulso (PULSE)")
## Tiempo letal (fase ON) del ciclo. Unidad: s.
@export var pulse_on_time: float = 1.5
## Tiempo segura (fase OFF, incluye el aviso) del ciclo. Unidad: s.
@export var pulse_off_time: float = 1.5
## Últimos segundos de la fase segura en que parpadea antes de activarse. Se recorta a
## `pulse_off_time`; 0 = sin aviso. Unidad: s.
@export var pulse_warning_time: float = 0.5
## Desfase del ciclo al empezar. Con 0 arranca segura; con `pulse_off_time` arranca letal.
## Sirve para desincronizar varias instancias. Unidad: s.
@export var pulse_initial_offset: float = 0.0
