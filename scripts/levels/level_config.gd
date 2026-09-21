class_name LevelConfig
extends Resource
## Parámetros de la generación de niveles por segmentos.
##
## Se edita desde el inspector sobre `resources/configs/level_config.tres`. Los valores
## iniciales son de prueba. Ver `docs/mecanicas/niveles-por-segmentos.md`.

@export_group("Nivel")
## Cantidad de segmentos intermedios por partida (sin contar inicio y final).
@export var segment_count: int = 6
## Seed del nivel. 0 = aleatoria en cada partida; distinto de 0 = fija (reproduce siempre el
## mismo nivel).
@warning_ignore("shadowed_global_identifier")
@export var seed: int = 0
## Un segmento no se repite dentro de los últimos N elegidos. Con un pool chico se relaja
## solo cuando no hay opciones.
@export var avoid_repeat_window: int = 1

@export_group("Segmentos")
## Escena del segmento de inicio (debe tener un nodo `PlayerSpawn`).
@export var start_segment: PackedScene
## Escena del segmento final (debe contener una [Door]).
@export var end_segment: PackedScene
## Escenas candidatas para los segmentos intermedios.
@export var segment_pool: Array[PackedScene] = []
