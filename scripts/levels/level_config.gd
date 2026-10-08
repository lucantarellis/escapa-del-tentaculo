class_name LevelConfig
extends Resource
## Parámetros de la generación de niveles por segmentos.
##
## Se edita desde el inspector sobre `resources/configs/level_config.tres`. Los valores
## iniciales son de prueba. Ver `docs/mecanicas/niveles-por-segmentos.md`.

@export_group("Nivel")
## Cantidad de segmentos intermedios por partida (sin contar inicio y final). Solo se usa si
## `tiers` está vacío (modo plano: un único `segment_pool`).
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
## Escenas candidatas para los segmentos intermedios. Solo se usa si `tiers` está vacío (modo
## plano, con `segment_count` segmentos).
@export var segment_pool: Array[PackedScene] = []
## Tiers de segmentos, en el orden en que se recorren de abajo hacia arriba. Cada partida usa
## `count_per_run` segmentos de cada tier. Si está vacío, se usan `segment_pool` y
## `segment_count`.
@export var tiers: Array[SegmentTier] = []
