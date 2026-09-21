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
##
## No modifica el juego. Sin números ni etiquetas. Todos los valores son visuales.
## Ver `docs/mecanicas/hud.md`.

## Color de la barra con combustible (naranja de meta/jugador). Solo visual.
const FUEL_COLOR: Color = Color("FF6B32")
## Color de la barra sin combustible (rojo letal, igual que el jugador vacío). Solo visual.
const EMPTY_COLOR: Color = Color("D83232")
## Color del marcador de progreso (blanco azulado de detalles). Solo visual.
const MARKER_COLOR: Color = Color("C8E7EA")
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

var _start_y: float = 0.0
var _end_y: float = 0.0
var _top: float = 0.0
var _fuel_ratio: float = 1.0

@onready var _fuel_track: ColorRect = $FuelTrack
@onready var _fuel_fill: ColorRect = $FuelFill
@onready var _progress_track: ColorRect = $ProgressTrack
@onready var _goal_mark: ColorRect = $GoalMark
@onready var _marker: ColorRect = $ProgressMarker


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


## Devuelve el progreso actual (0..1) según la Y del jugador. 0 si el rango no es válido.
func get_progress() -> float:
	if player == null or _start_y - _end_y <= 0.0:
		return 0.0
	return clampf((_start_y - player.global_position.y) / (_start_y - _end_y), 0.0, 1.0)


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
