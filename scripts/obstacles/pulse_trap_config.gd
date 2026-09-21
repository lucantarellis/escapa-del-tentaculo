class_name PulseTrapConfig
extends Resource
## Parámetros de una [PulseTrap]: duración de cada fase del ciclo.
##
## El ciclo empieza siempre por la fase segura (inactiva) y sigue con la letal (activa).
## Valores por defecto en `resources/configs/pulse_trap_config.tres`. Para dar a una instancia
## valores propios (por ejemplo otro `initial_offset`), hacer el recurso único en el
## inspector o duplicar el `.tres`. Ver `docs/mecanicas/obstaculos.md`.

@export_group("Ciclo")
## Tiempo que la trampa está activa (letal). Unidad: s.
@export var on_time: float = 1.5
## Tiempo que la trampa está inactiva (segura), incluido el aviso. Unidad: s.
@export var off_time: float = 1.5
## Últimos segundos del `off_time` en que parpadea avisando. Se recorta a `off_time`.
## Unidad: s.
@export var warning_time: float = 0.5
## Desfase del ciclo al empezar (se suma al tiempo transcurrido). Unidad: s.
@export var initial_offset: float = 0.0
