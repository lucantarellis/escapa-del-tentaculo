class_name UpgradeData
extends Resource
## Un nodo del árbol de talentos del mercado: qué da, cuánto cuesta y qué hay que tener antes.
##
## Cada nodo es un `.tres` en `resources/configs/upgrades/` y se compra una sola vez. El `effect`
## decide qué hace (lo aplica [code]PlayerProgress[/code]); si dos nodos tienen el mismo efecto,
## manda el de mayor `value`. Los nodos con `locked` en true se ven en el árbol pero todavía no se
## pueden comprar ni tienen efecto (son lugares reservados para próximas iteraciones).
## Ver `docs/mecanicas/progreso-mercado.md`.

## Efectos que ya tienen implementación (ver `PlayerProgress`). Estructural.
const EFFECT_NONE: StringName = &"none"
const EFFECT_DASH_DISTANCE: StringName = &"dash_distance"
const EFFECT_DASH_INVULN: StringName = &"dash_invuln"
const EFFECT_DASH_INVULN_LONG: StringName = &"dash_invuln_long"
const EFFECT_DASH_BREAK: StringName = &"dash_break"
const EFFECT_DASH_FREE: StringName = &"dash_free"
const EFFECT_MAX_FUEL: StringName = &"max_fuel"
const EFFECT_TANK_AMOUNT: StringName = &"tank_amount"
const EFFECT_SPEED: StringName = &"speed"
const EFFECT_COIN_VALUE: StringName = &"coin_value"
const EFFECT_HIT_POINTS: StringName = &"hit_points"
const EFFECT_RESPAWN: StringName = &"respawn"
const EFFECT_REPAIR: StringName = &"repair"
const EFFECT_SHIELD: StringName = &"shield"

@export_group("Datos")
## Identificador único del nodo (también es la clave en el archivo de guardado).
@export var id: StringName = &""
## Nombre que se ve en el árbol.
@export var display_name: String = ""
## Texto corto que explica qué hace el nodo. Se ve en el detalle.
@export_multiline var description: String = ""

@export_group("Árbol")
## Rama a la que pertenece (por ejemplo `dash`). Los nodos de una misma rama se muestran juntos,
## en el orden en que están en `ProgressConfig.upgrades`.
@export var branch: StringName = &""
## Nombre corto de la rama, para su solapa en el mercado (ver [Market]).
@export var branch_label: String = ""
## `id` del nodo que hay que tener antes de poder comprar este. Vacío = sin requisito.
@export var requires_id: StringName = &""

@export_group("Compra")
## Precio. Unidad: monedas.
@export var price: int = 0
## Si es true, el nodo ya viene comprado desde el principio.
@export var owned_by_default: bool = false
## Si es true, el nodo todavía no está implementado: se ve con candado y no se puede comprar.
@export var locked: bool = false

@export_group("Efecto")
## Qué hace al comprarlo (uno de los `EFFECT_*`). `none` = nada (nodo reservado).
@export var effect: StringName = &"none"
## Valor principal del efecto. Su unidad depende del `effect`: distancia en px (`dash_distance`),
## porcentaje del dash (`dash_invuln` y `dash_invuln_long`; no se usa, los porcentajes están en
## `ProgressConfig`), `dash_break` no usa valor,
## combustible en u (`max_fuel`, `tank_amount`), velocidad máxima en px/s (`speed`) o monedas
## por moneda (`coin_value`), o puntos de golpe TOTALES que aguanta el jugador (`hit_points`: 2 =
## resiste un golpe letal, 3 = resiste dos). `respawn` no usa valor. `repair`: nivel de reparador (1 = llave inglesa, 2 = también venda, 3 =
## también botiquín). `shield`: nivel de escudo del botiquín (1 = dura 10 s, 2 = dura hasta que te
## pegan).
@export var value: float = 0.0
## Segundo valor del efecto. Con `speed` es la aceleración de la propulsión (px/s²).
@export var extra_value: float = 0.0
