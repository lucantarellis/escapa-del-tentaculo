class_name LevelConfig
extends Resource
## Parámetros de la generación de niveles por segmentos.
##
## Se edita desde el inspector sobre `resources/configs/level_config.tres`. Los valores
## iniciales son de prueba. Ver `docs/mecanicas/niveles-por-segmentos.md`.

@export_group("Nivel")
## Seed del nivel. 0 = aleatoria en cada partida; distinto de 0 = fija (reproduce siempre el
## mismo nivel).
@warning_ignore("shadowed_global_identifier")
@export var seed: int = 0

@export_group("Segmentos")
## Candidatos para el segmento de inicio: se sortea uno por partida con la seed. Cada uno debe
## tener los Marker2D `PlayerSpawn` y `HatchAnchor`, y el pasillo central libre para el vuelo
## de la escotilla (ver `docs/mecanicas/niveles-por-segmentos.md`).
@export var start_segments: Array[PackedScene] = []
## Candidatos para el segmento final: se sortea uno por partida con la seed. Cada uno debe
## contener una [Door].
@export var end_segments: Array[PackedScene] = []
## Tiers de segmentos (los segmentos intermedios), en el orden en que se recorren de abajo
## hacia arriba. Cada partida usa `count_per_run` segmentos de cada tier.
@export var tiers: Array[SegmentTier] = []
