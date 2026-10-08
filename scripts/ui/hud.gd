class_name Hud
extends CanvasLayer
## HUD mínimo de solo lectura: barra de combustible y progreso del nivel.
##
## - **Combustible:** barra vertical fina pegada al borde izquierdo. Sigue a
##   [signal Player.fuel_changed]; es naranja con combustible y roja cuando se vacía
##   ([signal Player.fuel_depleted] / [signal Player.fuel_refilled]), como el cuerpo del jugador.
## - **Progreso:** línea vertical fina pegada al borde derecho con un marcador que sube desde el
##   spawn (0 %) hasta la puerta (100 %, marca naranja arriba). Se calcula con la Y del jugador
##   entre [method set_progress_range]'s `start_y` y `end_y`, acotado a 0..1.
## - **Récord y tiers:** en la misma línea, una marca fina con el mejor progreso guardado
##   ([RunRecords]) y marcas cortas donde empieza cada tier.
## - **Tentáculo:** en la misma línea, un marcador rojo con la altura del borde superior del
##   tentáculo, con el mismo cálculo. Se oculta mientras el tentáculo está inactivo (intro).
##
## No modifica el juego. Sin números ni etiquetas. Todos los valores son visuales.
## Ver `docs/mecanicas/hud.md`.

## Color de la barra con combustible (naranja de meta/jugador). Solo visual.
const FUEL_COLOR: Color = Color("FF6B32")
## Color de la barra sin combustible (rojo letal, igual que el jugador vacío). Solo visual.
const EMPTY_COLOR: Color = Color("D83232")
## Color del marcador de progreso (blanco azulado de detalles). Solo visual.
const MARKER_COLOR: Color = Color("C8E7EA")
## Color del marcador del tentáculo (rojo letal). Solo visual.
const TENTACLE_COLOR: Color = Color("D83232")
## Color de la marca del récord (blanco azulado tenue). Solo visual.
const RECORD_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.55)
## Tamaño de la marca del récord: más ancha y fina que el marcador del jugador (px). Solo visual.
const RECORD_SIZE: Vector2 = Vector2(19.0, 2.0)
## Color de las marcas de inicio de tier. Solo visual.
const TIER_MARK_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.35)
## Tamaño de las marcas de inicio de tier (px). Solo visual.
const TIER_MARK_SIZE: Vector2 = Vector2(9.0, 1.0)
## Color de la marca de la puerta (naranja de meta). Solo visual.
const GOAL_COLOR: Color = Color("FF6B32")
## Color del fondo de las barras. Solo visual.
const TRACK_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 1.0)
## Opacidad general del HUD (0..1). Solo visual.
const HUD_ALPHA: float = 0.7
## Opacidad del fondo de las barras respecto de [constant HUD_ALPHA]. Solo visual.
const TRACK_ALPHA_FACTOR: float = 0.6
## Ancho de las barras (px). Solo visual.
const BAR_WIDTH: float = 5.0
## Alto de las barras (px). Solo visual.
const BAR_HEIGHT: float = 200.0
## Separación al borde de la pantalla (px). Solo visual.
const EDGE_MARGIN: float = 6.0
## Tamaño del marcador de progreso y de la marca de la puerta (px). Solo visual.
const MARKER_SIZE: Vector2 = Vector2(13.0, 4.0)
## Viewport lógico del juego (px). Estructural: coincide con `project.godot` (360×640).
const VIEWPORT_SIZE: Vector2 = Vector2(360.0, 640.0)

## Jugador a observar. Se asigna desde la escena que instancia el HUD.
@export var player: Player
## Tentáculo a observar para su marcador en la línea de progreso. Opcional: si queda vacío, el
## marcador no se muestra.
@export var tentacle: Tentacle

var _start_y: float = 0.0
var _end_y: float = 0.0
var _top: float = 0.0
var _fuel_ratio: float = 1.0

@onready var _fuel_track: ColorRect = $FuelTrack
@onready var _fuel_fill: ColorRect = $FuelFill
@onready var _progress_track: ColorRect = $ProgressTrack
@onready var _goal_mark: ColorRect = $GoalMark
@onready var _marker: ColorRect = $ProgressMarker
@onready var _tentacle_marker: ColorRect = $TentacleMarker
@onready var _record_marker: ColorRect = $RecordMarker
@onready var _tier_marks: Control = $TierMarks

var _record: float = 0.0
var _tier_ys: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_top = (VIEWPORT_SIZE.y - BAR_HEIGHT) * 0.5
	var track_color: Color = Color(TRACK_COLOR, HUD_ALPHA * TRACK_ALPHA_FACTOR)
	_fuel_track.color = track_color
	_fuel_track.position = Vector2(EDGE_MARGIN, _top)
	_fuel_track.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fuel_fill.position = _fuel_track.position
	_progress_track.color = track_color
	_progress_track.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_progress_track.position = Vector2(VIEWPORT_SIZE.x - EDGE_MARGIN - BAR_WIDTH, _top)
	var center_x: float = _progress_track.position.x + BAR_WIDTH * 0.5
	_goal_mark.color = Color(GOAL_COLOR, HUD_ALPHA)
	_goal_mark.size = MARKER_SIZE
	_goal_mark.position = Vector2(center_x - MARKER_SIZE.x * 0.5, _top - MARKER_SIZE.y)
	_marker.color = Color(MARKER_COLOR, HUD_ALPHA)
	_marker.size = MARKER_SIZE
	_tentacle_marker.color = Color(TENTACLE_COLOR, HUD_ALPHA)
	_tentacle_marker.size = MARKER_SIZE
	_tentacle_marker.visible = false
	_record_marker.color = RECORD_COLOR
	_record_marker.size = RECORD_SIZE
	if player == null:
		push_error("Hud: falta asignar 'player'.")
		return
	player.fuel_changed.connect(_on_fuel_changed)
	player.fuel_depleted.connect(_on_fuel_state_changed)
	player.fuel_refilled.connect(_on_fuel_state_changed)
	_fuel_ratio = player.get_fuel_ratio()
	_refresh_fuel()
	_refresh_progress()


func _process(_delta: float) -> void:
	_refresh_progress()


## Fija el rango del progreso: [param start_y] es la Y global del spawn (0 %) y [param end_y]
## la Y global de la puerta (100 %). La llama el nivel tras armarse.
func set_progress_range(start_y: float, end_y: float) -> void:
	_start_y = start_y
	_end_y = end_y
	_refresh_progress()
	_refresh_record()
	_refresh_tier_marks()


## Muestra la marca del récord en [param progress] (0..1). Con 0 (sin récord) no se muestra.
func set_record(progress: float) -> void:
	_record = clampf(progress, 0.0, 1.0)
	_refresh_record()


## Fija dónde empieza cada tier: [param ys] son Y globales (como las de
## [method LevelBuilder.get_tier_starts]). Se dibuja una marca corta por cada una.
func set_tier_marks(ys: PackedFloat32Array) -> void:
	_tier_ys = ys
	_refresh_tier_marks()


## Devuelve el progreso actual (0..1) según la Y del jugador. 0 si el rango no es válido.
func get_progress() -> float:
	if player == null:
		return 0.0
	return _ratio_for_y(player.global_position.y)


## Devuelve la altura del borde superior del tentáculo en la línea de progreso (0..1), con el
## mismo rango que [method get_progress]. 0 si no hay tentáculo o el rango no es válido.
func get_tentacle_progress() -> float:
	if tentacle == null:
		return 0.0
	return _ratio_for_y(tentacle.global_position.y)


## Devuelve la proporción de combustible mostrada (0..1).
func get_fuel_ratio() -> float:
	return _fuel_ratio


## Devuelve el color actual de la barra de combustible.
func get_fuel_color() -> Color:
	return _fuel_fill.color


func _on_fuel_changed(current: float, maximum: float) -> void:
	_fuel_ratio = current / maximum if maximum > 0.0 else 0.0
	_refresh_fuel()


func _on_fuel_state_changed() -> void:
	_refresh_fuel()


func _refresh_fuel() -> void:
	var empty: bool = player.is_fuel_empty()
	_fuel_fill.color = Color(EMPTY_COLOR if empty else FUEL_COLOR, HUD_ALPHA)
	var height: float = BAR_HEIGHT * clampf(_fuel_ratio, 0.0, 1.0)
	_fuel_fill.size = Vector2(BAR_WIDTH, height)
	# La barra crece hacia arriba desde la base.
	_fuel_fill.position = Vector2(EDGE_MARGIN, _top + BAR_HEIGHT - height)


func _refresh_progress() -> void:
	var y: float = _top + BAR_HEIGHT * (1.0 - get_progress()) - MARKER_SIZE.y * 0.5
	_marker.position = Vector2(_progress_track.position.x + BAR_WIDTH * 0.5 - MARKER_SIZE.x * 0.5, y)
	_refresh_tentacle_marker()


# Proporción 0..1 de una Y global dentro del rango spawn → puerta. 0 si el rango no es válido.
func _ratio_for_y(y: float) -> float:
	if _start_y - _end_y <= 0.0:
		return 0.0
	return clampf((_start_y - y) / (_start_y - _end_y), 0.0, 1.0)


# Ubica el marcador del tentáculo; lo oculta si no hay tentáculo o está inactivo (intro).
func _refresh_tentacle_marker() -> void:
	if tentacle == null or not tentacle.is_active():
		_tentacle_marker.visible = false
		return
	_tentacle_marker.visible = true
	var y: float = _top + BAR_HEIGHT * (1.0 - get_tentacle_progress()) - MARKER_SIZE.y * 0.5
	_tentacle_marker.position = Vector2(_progress_track.position.x + BAR_WIDTH * 0.5 - MARKER_SIZE.x * 0.5, y)


# Y (en pantalla) de la línea de progreso para un progreso 0..1.
func _line_y(progress: float) -> float:
	return _top + BAR_HEIGHT * (1.0 - progress)


func _refresh_record() -> void:
	if not is_node_ready():
		return
	_record_marker.visible = _record > 0.0
	var center_x: float = _progress_track.position.x + BAR_WIDTH * 0.5
	_record_marker.position = Vector2(center_x - RECORD_SIZE.x * 0.5, _line_y(_record) - RECORD_SIZE.y * 0.5)


func _refresh_tier_marks() -> void:
	if not is_node_ready():
		return
	for child: Node in _tier_marks.get_children():
		child.queue_free()
	var center_x: float = _progress_track.position.x + BAR_WIDTH * 0.5
	for y: float in _tier_ys:
		var mark: ColorRect = ColorRect.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.color = TIER_MARK_COLOR
		mark.size = TIER_MARK_SIZE
		mark.position = Vector2(center_x - TIER_MARK_SIZE.x * 0.5, _line_y(_ratio_for_y(y)) - TIER_MARK_SIZE.y * 0.5)
		_tier_marks.add_child(mark)
