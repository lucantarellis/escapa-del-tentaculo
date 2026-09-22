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
