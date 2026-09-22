@tool
class_name Platform
extends StaticBody2D
## Plataforma modular: bloque sólido reutilizable con varias tipologías de comportamiento.
##
## Es un [StaticBody2D] (capa 1 `world`, máscara 0): el jugador colisiona físicamente con
## ella, igual que las plataformas armadas a mano hasta ahora. `size` regenera el polígono
## visual y la forma de colisión (origen = CENTRO del bloque, igual que [Obstacle] y [Door]).
## `platform_type` cambia el comportamiento en juego; los tiempos de cada tipo viven en
## `config` (ver [PlatformConfig]), no acá, siguiendo el mismo patrón que `obstacles/`.
## `@tool`: tamaño y tipo se ven en el editor, con el nombre del tipo dibujado arriba.
## Ver `docs/mecanicas/plataformas.md`.

## Una [BREAKABLE] empezó a romperse (el jugador se paró encima).
signal breaking_started
## Una [BREAKABLE] se rompió (dejó de ser sólida).
signal broke
## Una plataforma (BREAKABLE o TIMED) volvió a estar sólida.
signal restored

## Tipologías disponibles. Ver cada grupo de [PlatformConfig] para sus tiempos.
enum PlatformType {
	STATIC,    ## Sólida siempre, colisiona desde cualquier lado. Es lo que había hasta ahora.
	ONE_WAY,   ## Sólida solo desde arriba: se puede saltar a través desde abajo o los costados.
	BREAKABLE, ## Se rompe tras pisarla un rato y reaparece después. Ver `break_delay`/`respawn_time`.
	TIMED,     ## Alterna sólida/ausente en un ciclo fijo. Ver `timed_on_duration`/`timed_off_duration`.
}

## Color placeholder por tipo, para distinguirlos de un vistazo en el editor y en juego.
const COLOR_BY_TYPE: Dictionary = {
	PlatformType.STATIC: Color(0.2275, 0.6078, 0.749, 1.0),
	PlatformType.ONE_WAY: Color(0.549, 0.788, 0.298, 1.0),
	PlatformType.BREAKABLE: Color(0.898, 0.6, 0.298, 1.0),
	PlatformType.TIMED: Color(0.702, 0.396, 0.788, 1.0),
}
## Alto de la zona sensora que detecta "pisado" en BREAKABLE, pegada al borde superior.
## Estructural. Unidad: px.
const STEP_SENSOR_HEIGHT: float = 6.0

@export_group("Forma")
## Tamaño del bloque (ancho, alto). Es diseño de nivel, no tuning. Unidad: px.
@export var size: Vector2 = Vector2(80.0, 12.0):
	set(value):
		size = value.max(Vector2(4.0, 4.0))
		_update_shape()
		queue_redraw()

@export_group("Tipo")
## Tipología de la plataforma. Es diseño de nivel: decide qué armar en cada punto del segmento.
@export var platform_type: PlatformType = PlatformType.STATIC:
	set(value):
		platform_type = value
		_apply_type()
		queue_redraw()

@export_group("Configuración")
## Tiempos de rotura, reaparición y ciclo temporizado (ver [PlatformConfig]).
@export var config: PlatformConfig

@onready var _body: Polygon2D = $Body
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _step_sensor: Area2D = $StepSensor
@onready var _step_shape: CollisionShape2D = $StepSensor/CollisionShape2D
@onready var _footprint_sensor: Area2D = $FootprintSensor
@onready var _footprint_shape: CollisionShape2D = $FootprintSensor/CollisionShape2D

var _breaking: bool = false
var _broken: bool = false
var _break_timer: float = 0.0
var _respawn_left: float = 0.0
var _timed_elapsed: float = 0.0
var _timed_on: bool = true


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		_apply_type()
		return
	if config == null:
		push_warning("Platform '%s' sin config: se usan los valores por defecto." % name)
		config = PlatformConfig.new()
	_step_sensor.body_entered.connect(_on_step_entered)
	_step_sensor.body_exited.connect(_on_step_exited)
	_timed_on = config.timed_start_on
	_apply_type()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match platform_type:
		PlatformType.BREAKABLE:
			_process_breakable(delta)
		PlatformType.TIMED:
			_process_timed(delta)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half: Vector2 = size * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -half.y - 4.0), PlatformType.keys()[platform_type], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)


## Vuelve al estado inicial (sólida, sin romper, fase temporizada de arranque).
func reset() -> void:
	_breaking = false
	_broken = false
	_break_timer = 0.0
	_respawn_left = 0.0
	_timed_elapsed = 0.0
	_timed_on = config.timed_start_on if config != null else true
	if platform_type == PlatformType.TIMED:
		_apply_solid(_timed_on)
	else:
		_apply_solid(true)


# Regenera polígono visual, forma de colisión y sensor de "pisado" a partir de `size`. Antes
# de _ready los nodos hijos todavía no existen (los setters exportados corren al cargar la
# escena).
func _update_shape() -> void:
	if not is_node_ready():
		return
	var half: Vector2 = size * 0.5
	_body.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	if not _collision.shape is RectangleShape2D:
		_collision.shape = RectangleShape2D.new()
	(_collision.shape as RectangleShape2D).size = size
	if not _step_shape.shape is RectangleShape2D:
		_step_shape.shape = RectangleShape2D.new()
	(_step_shape.shape as RectangleShape2D).size = Vector2(size.x, STEP_SENSOR_HEIGHT)
	_step_sensor.position = Vector2(0.0, -half.y - STEP_SENSOR_HEIGHT * 0.5)
	if not _footprint_shape.shape is RectangleShape2D:
		_footprint_shape.shape = RectangleShape2D.new()
	(_footprint_shape.shape as RectangleShape2D).size = size


# Aplica lo que depende del tipo: color, colisión de un sentido, y estado sólido inicial.
func _apply_type() -> void:
	if not is_node_ready():
		return
	_body.color = COLOR_BY_TYPE.get(platform_type, COLOR_BY_TYPE[PlatformType.STATIC])
	var margin: float = config.one_way_margin if config != null else 5.0
	_collision.one_way_collision = platform_type == PlatformType.ONE_WAY
	_collision.one_way_collision_margin = margin
	if Engine.is_editor_hint():
		return
	_step_sensor.set_deferred("monitoring", platform_type == PlatformType.BREAKABLE)
	_footprint_sensor.set_deferred("monitoring", platform_type == PlatformType.TIMED)
	_breaking = false
	_break_timer = 0.0
	if platform_type == PlatformType.TIMED:
		_apply_solid(_timed_on)
	else:
		_apply_solid(true)


func _process_breakable(delta: float) -> void:
	if _broken:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_broken = false
			_apply_solid(true)
			restored.emit()
		return
	if _breaking:
		_break_timer += delta
		if _break_timer >= config.break_delay:
			_breaking = false
			_broken = true
			_break_timer = 0.0
			_respawn_left = config.respawn_time
			_apply_solid(false)
			broke.emit()


func _process_timed(delta: float) -> void:
	_timed_elapsed += delta
	var duration: float = config.timed_on_duration if _timed_on else config.timed_off_duration
	if duration <= 0.0:
		return
	if _timed_elapsed >= duration:
		# No volver a aparecer empujando al jugador: si está en medio, esperar a que se vaya
		# (no se pierde tiempo de más: se retoma apenas se libera).
		if not _timed_on and _is_footprint_occupied():
			_timed_elapsed = duration
			return
		_timed_elapsed -= duration
		_timed_on = not _timed_on
		_apply_solid(_timed_on)
		if _timed_on:
			restored.emit()


# true si hay un Player vivo dentro del rectángulo completo de la plataforma. Se usa antes
# de volverse sólida (TIMED) para no reaparecer empujando al jugador.
func _is_footprint_occupied() -> bool:
	for body: Node2D in _footprint_sensor.get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive():
			return true
	return false


# Activa o desactiva la colisión y la visual. Diferido: seguro dentro de callbacks de física.
func _apply_solid(solid: bool) -> void:
	_collision.set_deferred("disabled", not solid)
	_body.visible = solid


func _on_step_entered(body: Node2D) -> void:
	if platform_type != PlatformType.BREAKABLE or _broken or _breaking:
		return
	var player: Player = body as Player
	if player == null or not player.is_alive():
		return
	_breaking = true
	_break_timer = 0.0
	breaking_started.emit()


func _on_step_exited(body: Node2D) -> void:
	if platform_type != PlatformType.BREAKABLE or _broken or not _breaking:
		return
	if body is Player:
		_breaking = false
		_break_timer = 0.0
