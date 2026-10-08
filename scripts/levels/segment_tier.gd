class_name SegmentTier
extends Resource
## Un tier (nivel de dificultad) de segmentos: su lista de segmentos candidatos y cuántos se usan
## en cada partida.
##
## Una partida recorre los tiers en orden: primero los segmentos del tier 1, después los del
## tier 2 y así hasta el último, y arriba el segmento final. Se edita desde el inspector dentro
## de `LevelConfig.tiers`. Ver `docs/mecanicas/niveles-por-segmentos.md`.

## Escenas candidatas de este tier (cada una con un [LevelSegment] en la raíz). Si queda vacía,
## el tier se saltea con un aviso en la consola.
@export var segments: Array[PackedScene] = []
## Cantidad de segmentos de este tier que se usan en cada partida. Se sortean sin repetir
## mientras alcance la lista; si hay menos candidatos que esta cantidad, se vuelve a mezclar y
## se repiten (nunca el mismo dos veces seguidas). Unidad: segmentos.
@export_range(0, 100, 1) var count_per_run: int = 10
