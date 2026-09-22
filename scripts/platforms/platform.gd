@tool
class_name Platform
extends AnimatableBody2D
## Plataforma modular: bloque reutilizable con varias tipologías, sólido o letal, quieto o
## en movimiento — reemplaza tanto a las plataformas armadas a mano como a `Obstacle`,
## `MovingObstacle` y `PulseTrap` (ver `docs/mecanicas/plataformas.md`).
##
## Es un [AnimatableBody2D] (capa 1 `world`, máscara 0): un [StaticBody2D] que, al mover su
## `position` en código, sincroniza la velocidad con la física para que un jugador parado
## encima se mueva con ella (`sync_to_physics`). `size` regenera el polígono visual y la
## forma de colisión (origen = CENTRO del bloque, igual que el resto de `scripts/`).
## `platform_type` decide el comportamiento (tabla completa en la doc); `moves` es
## independiente del tipo — cualquier tipo puede moverse o quedarse quieto. Los tiempos de
## cada tipo viven en `config` (ver [PlatformConfig]), no acá.
## `@tool`: tamaño, tipo y trayectoria se ven en el editor.

## Una [BREAKABLE] empezó a romperse (el jugador se paró encima).
signal breaking_started
## Una [BREAKABLE] se rompió (dejó de ser sólida).
signal broke
## Una plataforma (BREAKABLE o TIMED) volvió a estar sólida.
signal restored
## Un [Player] vivo tocó la plataforma mientras era letal (LETHAL, o PULSE en fase ON).
signal player_hit(cause: StringName)

## Tipologías disponibles. Ver cada grupo de [PlatformConfig] para sus tiempos.
enum PlatformType {
	STATIC,    ## Sólida siempre, colisiona desde cualquier lado.
	ONE_WAY,   ## Sólida solo desde arriba: se puede saltar a través desde abajo o los costados.
	BREAKABLE, ## Se rompe tras pisarla un rato y reaparece después. Ver `break_delay`/`respawn_time`.
	TIMED,     ## Alterna sólida/ausente en un ciclo fijo. Ver `timed_on_duration`/`timed_off_duration`.
	LETHAL,    ## Nunca sólida, siempre letal. Reemplaza a `Obstacle`.
	PULSE,     ## Alterna segura y sólida / letal, con aviso. Reemplaza a `PulseTrap`.
}
## Estados internos de PULSE (además del tipo). Igual que el `PulseTrap` original.
enum PulseState { OFF, WARNING, ON }

## Color placeholder por tipo (o por fase, en PULSE), para distinguirlos de un vistazo.
const COLOR_BY_TYPE: Dictionary = {
	PlatformType.STATIC: Color(0.2275, 0.6078, 0.749, 1.0),
	PlatformType.ONE_WAY: Color(0.549, 0.788, 0.298, 1.0),
	PlatformType.BREAKABLE: Color(0.898, 0.6, 0.298, 1.0),
	PlatformType.TIMED: Color(0.702, 0.396, 0.788, 1.0),
	PlatformType.LETHAL: Color(0.8471, 0.1961, 0.1961, 1.0),
}
const PULSE_OFF_COLOR: Color = Color(0.2275, 0.6078, 0.749, 0.35)
const PULSE_WARNING_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.9)
const PULSE_ON_COLOR: Color = Color(0.8471, 0.1961, 0.1961, 1.0)
const PULSE_WARNING_BLINK_HZ: float = 6.0
## Alto de la zona sensora que detecta "pisado" en BREAKABLE, pegada al borde superior.
## Estructural. Unidad: px.
const STEP_SENSOR_HEIGHT: float = 6.0
## Color de la ayuda de trayectoria en el editor cuando `moves` es true. Solo visual.
const PATH_COLOR: Color = Color(0.8471, 0.1961, 0.1961, 0.6)

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
## Causa que se pasa a [method Player.die] cuando el tipo es letal (LETHAL, o PULSE en ON).
## Sin efecto en los demás tipos.
@export var cause: StringName = &"obstacle"

@export_group("Movimiento")
## Si es true, la plataforma va y viene entre su posición inicial y `inicial + travel`.
## Independiente de `platform_type`: cualquier tipo puede moverse (por ejemplo una TIMED que
## además se mueve, o el equivalente del viejo `MovingObstacle` con `platform_type = LETHAL`).
@export var moves: bool = false:
	set(value):
		moves = value
		queue_redraw()
## Desplazamiento del extremo final respecto de la posición inicial. Unidad: px.
@export var travel: Vector2 = Vector2(120.0, 0.0):
	set(value):
		travel = value
		queue_redraw()

@export_group("Configuración")
## Tiempos de cada tipo y del movimiento (ver [PlatformConfig]).
@export var config: PlatformConfig

@onready var _body: Polygon2D = $Body
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _step_sensor: Area2D = $StepSensor
@onready var _step_shape: CollisionShape2D = $StepSensor/CollisionShape2D
@onready var _footprint_sensor: Area2D = $FootprintSensor
@onready var _footprint_shape: CollisionShape2D = $FootprintSensor/CollisionShape2D
@onready var _lethal_area: Area2D = $LethalArea
@onready var _lethal_shape: CollisionShape2D = $LethalArea/CollisionShape2D

var _breaking: bool = false
var _broken: bool = false
var _break_timer: float = 0.0
var _respawn_left: float = 0.0
var _timed_elapsed: float = 0.0
var _timed_on: bool = true
var _pulse_state: PulseState = PulseState.OFF
var _pulse_elapsed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _move_elapsed: float = 0.0


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
	_lethal_area.body_entered.connect(_on_lethal_entered)
	_timed_on = config.timed_start_on
	_origin = position
	_pulse_state = _compute_pulse_state()
	_apply_type()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if moves:
		_move_elapsed += delta
		position = _origin + travel * _get_move_progress()
	match platform_type:
		PlatformType.BREAKABLE:
			_process_breakable(delta)
		PlatformType.TIMED:
			_process_timed(delta)
		PlatformType.PULSE:
			_process_pulse(delta)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half: Vector2 = size * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -half.y - 4.0), PlatformType.keys()[platform_type], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if moves:
		draw_line(Vector2.ZERO, travel, PATH_COLOR, 2.0)
		draw_rect(Rect2(travel - half, size), PATH_COLOR, false, 2.0)


## Vuelve al estado inicial: sólida (salvo LETHAL/PULSE en ON), sin romper, en el origen.
func reset() -> void:
	_breaking = false
	_broken = false
	_break_timer = 0.0
	_respawn_left = 0.0
	_timed_elapsed = 0.0
	_timed_on = config.timed_start_on if config != null else true
	_move_elapsed = 0.0
	position = _origin
	_pulse_state = _compute_pulse_state()
	_change_pulse_state(_pulse_state)
	if platform_type == PlatformType.TIMED:
		_apply_solid(_timed_on)
	elif platform_type != PlatformType.LETHAL and platform_type != PlatformType.PULSE:
		_apply_solid(true)


# Regenera polígono visual, forma de colisión y sensores a partir de `size`. Antes de _ready
# los nodos hijos todavía no existen (los setters exportados corren al cargar la escena).
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
	if not _lethal_shape.shape is RectangleShape2D:
		_lethal_shape.shape = RectangleShape2D.new()
	(_lethal_shape.shape as RectangleShape2D).size = size


# Aplica lo que depende del tipo: color, colisión de un sentido, sensores activos y estado
# sólido/letal inicial.
func _apply_type() -> void:
	if not is_node_ready():
		return
	var margin: float = config.one_way_margin if config != null else 5.0
	_collision.one_way_collision = platform_type == PlatformType.ONE_WAY
	_collision.one_way_collision_margin = margin
	if platform_type == PlatformType.PULSE:
		_apply_pulse_visual()
	else:
		_body.color = COLOR_BY_TYPE.get(platform_type, COLOR_BY_TYPE[PlatformType.STATIC])
	if Engine.is_editor_hint():
		return
	_step_sensor.set_deferred("monitoring", platform_type == PlatformType.BREAKABLE)
	_footprint_sensor.set_deferred("monitoring", platform_type == PlatformType.TIMED)
	_breaking = false
	_break_timer = 0.0
	match platform_type:
		PlatformType.TIMED:
			_apply_solid(_timed_on)
			_lethal_area.set_deferred("monitoring", false)
		PlatformType.LETHAL:
			_apply_solid(false)
			_lethal_area.set_deferred("monitoring", true)
		PlatformType.PULSE:
			_pulse_state = _compute_pulse_state()
			_change_pulse_state(_pulse_state)
		_:
			_apply_solid(true)
			_lethal_area.set_deferred("monitoring", false)


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


func _process_pulse(delta: float) -> void:
	_pulse_elapsed += delta
	var new_state: PulseState = _compute_pulse_state()
	if new_state != _pulse_state:
		_change_pulse_state(new_state)
	if _pulse_state == PulseState.WARNING:
		_apply_pulse_visual()
	elif _pulse_state == PulseState.ON:
		_hit_overlapping_lethal_bodies()


# Fase actual de PULSE según el tiempo, igual que el PulseTrap original: [0, off_time) segura
# (con aviso al final), [off_time, off_time + on_time) letal.
func _compute_pulse_state() -> PulseState:
	if config == null:
		return PulseState.OFF
	var on_time: float = maxf(config.pulse_on_time, 0.0)
	var off_time: float = maxf(config.pulse_off_time, 0.0)
	if on_time <= 0.0:
		return PulseState.OFF
	if off_time <= 0.0:
		return PulseState.ON
	var phase: float = fposmod(_pulse_elapsed + config.pulse_initial_offset, off_time + on_time)
	if phase >= off_time:
		return PulseState.ON
	var warning: float = minf(maxf(config.pulse_warning_time, 0.0), off_time)
	if warning > 0.0 and phase >= off_time - warning:
		return PulseState.WARNING
	return PulseState.OFF


func _change_pulse_state(new_state: PulseState) -> void:
	var was_on: bool = _pulse_state == PulseState.ON
	_pulse_state = new_state
	_lethal_area.set_deferred("monitoring", new_state == PulseState.ON)
	_collision.set_deferred("disabled", new_state == PulseState.ON)
	_body.visible = true
	_apply_pulse_visual()
	if new_state == PulseState.ON and not was_on:
		pass
	elif new_state != PulseState.ON and was_on:
		restored.emit()


func _apply_pulse_visual() -> void:
	match _pulse_state:
		PulseState.OFF:
			_body.color = PULSE_OFF_COLOR
		PulseState.WARNING:
			var blink_on: bool = int(_pulse_elapsed * PULSE_WARNING_BLINK_HZ * 2.0) % 2 == 0
			_body.color = PULSE_WARNING_COLOR if blink_on else PULSE_OFF_COLOR
		PulseState.ON:
			_body.color = PULSE_ON_COLOR


# Red de seguridad: si el jugador ya estaba dentro cuando se activó la fase letal, igual muere
# (reactivar `monitoring` con un cuerpo superpuesto no siempre emite `body_entered` a tiempo).
func _hit_overlapping_lethal_bodies() -> void:
	if not _lethal_area.monitoring:
		return
	for body: Node2D in _lethal_area.get_overlapping_bodies():
		_try_hit(body)


# Progreso del recorrido (`moves`), de 0 a 1, igual que el viejo MovingObstacle.
func _get_move_progress() -> float:
	if config == null:
		return 0.0
	var length: float = travel.length()
	var t: float = _move_elapsed - config.moving_start_delay
	if length < 0.01 or config.moving_speed <= 0.0 or t <= 0.0:
		return 0.0
	var move_time: float = length / config.moving_speed
	var pause: float = maxf(config.moving_pause_at_ends, 0.0)
	var c: float = fmod(t, 2.0 * (move_time + pause))
	var progress: float = 0.0
	if c < move_time:
		progress = c / move_time
	elif c < move_time + pause:
		progress = 1.0
	elif c < 2.0 * move_time + pause:
		progress = 1.0 - (c - move_time - pause) / move_time
	if config.moving_ease_at_ends:
		progress = smoothstep(0.0, 1.0, progress)
	return progress


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


func _on_lethal_entered(body: Node2D) -> void:
	_try_hit(body)


func _try_hit(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive():
		return
	# Diagnóstico temporal (brief 06, ronda 2): LT reportó muertes sin nada visible tocándolo.
	# Con esto, la consola de salida de Godot (al correr con F5/F6 desde el editor) dice
	# exactamente qué plataforma fue, su tipo y dónde, en vez de tener que adivinar mirando
	# la captura de pantalla. Sacar cuando se confirme que no hace falta más.
	print("[Platform] '%s' (%s) golpeó al jugador en %s (jugador en %s)" % [
		name, PlatformType.keys()[platform_type], str(global_position), str(player.global_position),
	])
	player_hit.emit(cause)
	player.die(cause)
