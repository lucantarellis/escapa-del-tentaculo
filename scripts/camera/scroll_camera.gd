class_name ScrollCamera
extends Camera2D
## Cámara que sube a velocidad configurable y mantiene al jugador dentro de la pantalla.
##
## Se mueve en `_physics_process` (con `process_callback` en física y sin suavizado) para
## quedar sincronizada con el jugador. Lleva un hijo `ScreenBounds` con paredes invisibles
## (laterales y superior) que se mueven con ella. Ver `docs/mecanicas/scroll-camara.md`.

## Se emite cuando la cámara empieza a subir (después de `start_delay` o al reanudar).
signal scroll_started
## Se emite cuando la cámara deja de subir (pausa, o llegó a `stop_at_y`).
signal scroll_stopped

## Grosor de las paredes invisibles. Es estructural (solo tiene que ser mayor que la
## velocidad máxima de un frame), no un valor de gameplay. Unidad: px.
const WALL_THICKNESS: float = 64.0

## Parámetros de scroll y límites. Si queda vacío se usan los valores por defecto de
## [ScrollConfig].
@export var config: ScrollConfig

@onready var _left_shape: CollisionShape2D = $ScreenBounds/LeftShape
@onready var _right_shape: CollisionShape2D = $ScreenBounds/RightShape
@onready var _top_shape: CollisionShape2D = $ScreenBounds/TopShape

var _start_position: Vector2 = Vector2.ZERO
var _enabled: bool = true
var _moving: bool = false
var _reached_end: bool = false
var _delay_left: float = 0.0
var _speed: float = 0.0
## Tope de scroll propio de esta instancia (lo fija [method set_stop_y]); pisa al de la config.
var _stop_override_enabled: bool = false
var _stop_override_y: float = 0.0


func _ready() -> void:
	if config == null:
		config = ScrollConfig.new()
	_start_position = global_position
	_delay_left = config.start_delay
	_speed = config.scroll_speed
	_build_bounds()


func _physics_process(delta: float) -> void:
	var should_move: bool = _enabled and not _reached_end
	if should_move and _delay_left > 0.0:
		_delay_left -= delta
		should_move = _delay_left <= 0.0
	_set_moving(should_move)
	if not should_move:
		return
	if config.scroll_acceleration > 0.0:
		var top_speed: float = maxf(config.max_scroll_speed, config.scroll_speed)
		_speed = minf(_speed + config.scroll_acceleration * delta, top_speed)
	global_position.y -= _speed * delta
	var stop_enabled: bool = _stop_override_enabled or config.stop_at_enabled
	var stop_y: float = _stop_override_y if _stop_override_enabled else config.stop_at_y
	if stop_enabled and global_position.y <= stop_y:
		global_position.y = stop_y
		_reached_end = true
		_set_moving(false)


## Pausa ([param enabled] = false) o reanuda el scroll. Al reanudar no se repite `start_delay`.
func set_scrolling(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_set_moving(false)


## Activa un tope de scroll en [param y] (Y mundo del CENTRO de la cámara) solo para esta
## instancia, sin modificar el `ScrollConfig` compartido. Lo usa [LevelBuilder] para que el
## segmento final quede completo a la vista. Pisa a `stop_at_enabled` / `stop_at_y`.
func set_stop_y(y: float) -> void:
	_stop_override_enabled = true
	_stop_override_y = y


## Devuelve la coordenada Y (mundo) del borde inferior de la pantalla. Unidad: px.
func get_bottom_y() -> float:
	return global_position.y + _get_visible_size().y * 0.5


## Devuelve el rectángulo del mundo que se ve ahora (coordenadas globales).
func get_visible_rect() -> Rect2:
	var size: Vector2 = _get_visible_size()
	return Rect2(global_position - size * 0.5, size)


## Vuelve a la posición inicial y reinicia velocidad, espera y estado de fin.
func reset() -> void:
	global_position = _start_position
	_enabled = true
	_reached_end = false
	_delay_left = config.start_delay
	_speed = config.scroll_speed
	_set_moving(false)


func _get_visible_size() -> Vector2:
	return get_viewport_rect().size / zoom


## Dimensiona las paredes invisibles a partir del tamaño visible. Posiciones relativas al
## centro de la cámara, por eso se mueven con ella.
func _build_bounds() -> void:
	var size: Vector2 = _get_visible_size()
	var half: Vector2 = size * 0.5
	var side_size: Vector2 = Vector2(WALL_THICKNESS, size.y + WALL_THICKNESS * 2.0)
	var top_size: Vector2 = Vector2(size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)

	var left := RectangleShape2D.new()
	left.size = side_size
	_left_shape.shape = left
	_left_shape.position = Vector2(-half.x - WALL_THICKNESS * 0.5, 0.0)
	_left_shape.disabled = not config.side_walls_enabled

	var right := RectangleShape2D.new()
	right.size = side_size
	_right_shape.shape = right
	_right_shape.position = Vector2(half.x + WALL_THICKNESS * 0.5, 0.0)
	_right_shape.disabled = not config.side_walls_enabled

	var top := RectangleShape2D.new()
	top.size = top_size
	_top_shape.shape = top
	_top_shape.position = Vector2(0.0, -half.y - WALL_THICKNESS * 0.5 + config.top_wall_margin)
	_top_shape.disabled = not config.top_wall_enabled


func _set_moving(value: bool) -> void:
	if value == _moving:
		return
	_moving = value
	if value:
		scroll_started.emit()
	else:
		scroll_stopped.emit()
