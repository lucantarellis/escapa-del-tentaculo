class_name SegmentTier
extends Resource
## Un tier (un acto de la historia: la nave, el espacio, dentro del alien) con su lista de
## segmentos candidatos, cuántos se usan por partida y su escenario: segmento de entrada,
## perseguidor, física del jugador y tileset de las paredes.
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

@export_group("Escenario")
## Nombre del tier (para depurar y para la documentación). Ej.: "La nave".
@export var display_name: String = ""
## Segmentos de entrada (transición) del tier: se sortea uno por partida y va antes de los
## segmentos del tier (ej.: la nave explota, la extremidad del alien). Vacío = sin transición.
@export var entry_segments: Array[PackedScene] = []
## TileSet de las paredes de los segmentos de este tier (metal, chatarra, carne). Vacío = el de
## cada segmento. Debe respetar las coordenadas de atlas de `walls_tileset.tres` (tile sólido en
## (0, 0) y diagonal en (1, 0) con alternativas 0–3) para que lo pintado se vea igual.
@export var walls_tileset: TileSet

@export_group("Perseguidor")
## Config del perseguidor en este tier (el tentáculo, el fuego, el ácido). Vacío = sigue el de
## antes. Al cruzar el borde del tier, [LevelController] se la aplica al [Tentacle].
@export var pursuer_config: TentacleConfig
## Color placeholder del perseguidor en este tier. Se aplica siempre al entrar (rojo = tentáculo).
@export var pursuer_color: Color = Color("D83232")
## Si es true, al entrar al tier el perseguidor vuelve a su distancia inicial bajo la pantalla
## (otro perseguidor que recién aparece). Si es false, sigue desde donde estaba. Solo con
## `pursuer_config`.
@export var pursuer_reset_position: bool = true

@export_group("Jugador")
## Multiplica la gravedad del jugador en este tier (ej.: 0,16 en el espacio). 1 = la de
## `player_config.tres`. Se usa un multiplicador y no otra config para no duplicar valores.
@export_range(0.0, 4.0, 0.01) var gravity_scale: float = 1.0
## Multiplica el frenado en el aire (`coasting_drag`) en este tier: menos = más inercia.
## 1 = el de `player_config.tres`.
@export_range(0.0, 4.0, 0.01) var air_drag_scale: float = 1.0
