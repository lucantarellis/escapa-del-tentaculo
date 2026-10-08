@tool
class_name Platform
extends AnimatableBody2D
## Plataforma modular: bloque reutilizable con varias tipologías, sólido o letal, quieto o
## en movimiento. Todo lo que se pisa, se esquiva o mata en un segmento es una `Platform`
## (ver `docs/mecanicas/plataformas.md`).
##
## Es un [AnimatableBody2D] (capa 1 `world`, máscara 0): un [StaticBody2D] que, al mover su
## `position` en código, sincroniza la velocidad con la física para que un jugador parado
## encima se mueva con ella (`sync_to_physics`). `size` regenera el polígono visual y la
## forma de colisión (origen = CENTRO del bloque, igual que el resto de `scripts/`).
## `platform_type` decide el comportamiento (tabla completa en la doc); `moves` es
## independiente del tipo — cualquier tipo puede moverse o quedarse quieto. Los tiempos de
## cada tipo viven en `config` (ver [PlatformConfig]), no acá.
## `PROJECTILE` es un caso aparte: letal desde el inicio, quieta hasta que se cumple su disparador
## (cámara o distancia), después vuela en línea recta y al final explota, desaparece o rebota
## (ver `docs/mecanicas/plataforma-proyectil.md`); no usa `moves`.
## `@tool`: tamaño, tipo y trayectoria se ven en el editor.

## Una [BREAKABLE] empezó a romperse (el jugador se paró encima).
signal breaking_started
## Una [BREAKABLE] se rompió (dejó de ser sólida).
signal broke
## Una plataforma (BREAKABLE o TIMED) volvió a estar sólida.
signal restored
## Un [Player] vivo tocó la plataforma mientras era letal (LETHAL, o PULSE en fase ON).
signal player_hit(cause: StringName)
## Un [PROJECTILE] se disparó y empezó a moverse.
signal launched
## Un [PROJECTILE] explotó (al final del recorrido o al golpear al jugador).
signal exploded
## Un [PROJECTILE] desapareció (ocultado y desactivado; [method reset] lo revive).
signal vanished

## Tipologías disponibles. Ver cada grupo de [PlatformConfig] para sus tiempos.
enum PlatformType {
	STATIC,    ## Sólida siempre, colisiona desde cualquier lado.
	ONE_WAY,   ## Sólida solo desde arriba: se puede saltar a través desde abajo o los costados.
	BREAKABLE, ## Se rompe tras pisarla un rato y reaparece después. Ver `break_delay`/`respawn_time`.
	TIMED,     ## Alterna sólida/ausente en un ciclo fijo. Ver `timed_on_duration`/`timed_off_duration`.
	LETHAL,    ## Nunca sólida, siempre letal.
	PULSE,     ## Alterna segura (atravesable) / letal, con aviso.
	PROJECTILE, ## Letal; quieta hasta su disparador, luego vuela en línea recta. Ver `projectile_*`.
}
## Qué dispara el movimiento de un [PROJECTILE]. Solo uno por plataforma.
enum ProjectileTrigger {
	CAMERA,   ## Arranca cuando la plataforma entra en el rectángulo visible de la cámara.
	DISTANCE, ## Arranca cuando el jugador entra en el radio `projectile_trigger_distance`.
}
## Qué hace un [PROJECTILE] al llegar al final de su recorrido.
enum ProjectileEnd {
	EXPLODE, ## Explota: zona letal de radio `explosion_radius` que dura `explosion_duration`.
	DESTROY, ## Desaparece (se oculta y desactiva; no se borra, así `reset()` la revive).
	BOUNCE,  ## Rebota contra las 4 paredes de la pantalla `projectile_bounce_count` veces.
}
## Estados internos de un [PROJECTILE].
enum ProjectileState { IDLE, WAITING, FLYING, EXPLODING, GONE }
## Estados internos de PULSE (además del tipo).
enum PulseState { OFF, WARNING, ON }

## Color placeholder por tipo (o por fase, en PULSE), para distinguirlos de un vistazo.
const COLOR_BY_TYPE: Dictionary = {
	PlatformType.STATIC: Color(0.2275, 0.6078, 0.749, 1.0),
	PlatformType.ONE_WAY: Color(0.549, 0.788, 0.298, 1.0),
	PlatformType.BREAKABLE: Color(0.898, 0.6, 0.298, 1.0),
	PlatformType.TIMED: Color(0.702, 0.396, 0.788, 1.0),
	PlatformType.LETHAL: Color(0.8471, 0.1961, 0.1961, 1.0),
	PlatformType.PROJECTILE: Color(0.8471, 0.1961, 0.1961, 1.0),
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
## Color de la zona letal de la explosión de un PROJECTILE. Solo visual.
const EXPLOSION_COLOR: Color = Color(0.8471, 0.1961, 0.1961, 0.55)
## Color del radio de disparo y del radio de explosión dibujados en el editor. Solo visual.
const PROJECTILE_HELPER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.45)
## Largo de la flecha de dirección en el editor para el final BOUNCE (el recorrido real lo
## decide el rebote contra la pantalla). Solo visual. Unidad: px.
const BOUNCE_PREVIEW_LENGTH: float = 80.0
## Radios usados si la plataforma no tiene `config` (valores por defecto de [PlatformConfig]).
## Estructural. Unidad: px.
const DEFAULT_TRIGGER_RADIUS: float = 160.0
const DEFAULT_EXPLOSION_RADIUS: float = 48.0

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
## Si es true, la plataforma va y viene entre su posición inicial y `inicial + travel`. Ignorado
## por PROJECTILE.
## Independiente de `platform_type`: cualquier tipo puede moverse (por ejemplo una TIMED que
## además se mueve).
@export var moves: bool = false:
	set(value):
		moves = value
		queue_redraw()
## Desplazamiento del extremo final respecto de la posición inicial. Con PROJECTILE es el recorrido
## en línea recta: su dirección es la dirección de vuelo y su largo es hasta dónde llega (con el
## final BOUNCE solo importa la dirección). Unidad: px.
@export var travel: Vector2 = Vector2(120.0, 0.0):
	set(value):
		travel = value
		queue_redraw()

@export_group("Proyectil")
## Qué dispara el movimiento (solo PROJECTILE): entrar en cámara o que el jugador se acerque.
@export var projectile_trigger: ProjectileTrigger = ProjectileTrigger.CAMERA:
	set(value):
		projectile_trigger = value
		queue_redraw()
## Qué hace al llegar al final del recorrido (solo PROJECTILE).
@export var projectile_end: ProjectileEnd = ProjectileEnd.EXPLODE:
	set(value):
		projectile_end = value
		queue_redraw()

@export_group("Configuración")
## Tiempos de cada tipo y del movimiento (ver [PlatformConfig]).
@export var config: PlatformConfig

@export_group("Editor")
## Muestra en el editor los círculos de detección del proyectil (`TriggerArea`, radio de
## disparo, y `ExplosionArea`, radio de explosión). Solo visual: no cambia la detección ni la
## explosión, y en el juego no tiene efecto. Apagado por defecto para no tapar el segmento.
@export var show_detection_areas: bool = false:
	set(value):
		show_detection_areas = value
		_apply_detection_areas_visibility()

@onready var _body: Polygon2D = $Body
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _step_sensor: Area2D = $StepSensor
@onready var _step_shape: CollisionShape2D = $StepSensor/CollisionShape2D
@onready var _footprint_sensor: Area2D = $FootprintSensor
@onready var _footprint_shape: CollisionShape2D = $FootprintSensor/CollisionShape2D
@onready var _lethal_area: Area2D = $LethalArea
@onready var _lethal_shape: CollisionShape2D = $LethalArea/CollisionShape2D
@onready var _trigger_area: Area2D = $TriggerArea
@onready var _trigger_shape: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var _explosion_area: Area2D = $ExplosionArea
@onready var _explosion_shape: CollisionShape2D = $ExplosionArea/CollisionShape2D

var _breaking: bool = false
var _broken: bool = false
var _break_timer: float = 0.0
var _respawn_left: float = 0.0
var _timed_elapsed: float = 0.0
var _timed_on: bool = true
## Color que reemplaza al del tipo (ver [method set_tint]). Alfa 0 = el color del tipo.
var _tint: Color = Color(0.0, 0.0, 0.0, 0.0)
var _pulse_state: PulseState = PulseState.OFF
var _pulse_elapsed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _move_elapsed: float = 0.0
var _proj_state: ProjectileState = ProjectileState.IDLE
var _proj_elapsed: float = 0.0
var _proj_travelled: float = 0.0
var _proj_bounces: int = 0
var _proj_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	_update_shape()
	_apply_detection_areas_visibility()
	if Engine.is_editor_hint():
		_apply_type()
		return
	if config == null:
		push_warning("Platform '%s' sin config: se usan los valores por defecto." % name)
		config = PlatformConfig.new()
	_step_sensor.body_entered.connect(_on_step_entered)
	_step_sensor.body_exited.connect(_on_step_exited)
	_lethal_area.body_entered.connect(_on_lethal_entered)
	_explosion_area.body_entered.connect(_on_explosion_entered)
	_timed_on = config.timed_start_on
	_origin = position
	_pulse_state = _compute_pulse_state()
	_apply_type()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if moves and platform_type != PlatformType.PROJECTILE:
		_move_elapsed += delta
		position = _origin + travel * _get_move_progress()
	match platform_type:
		PlatformType.BREAKABLE:
			_process_breakable(delta)
		PlatformType.TIMED:
			_process_timed(delta)
		PlatformType.PULSE:
			_process_pulse(delta)
		PlatformType.PROJECTILE:
			_process_projectile(delta)


func _draw() -> void:
	if not Engine.is_editor_hint():
		# En juego solo se dibuja la explosión de un PROJECTILE (el resto usa el Polygon2D).
		if platform_type == PlatformType.PROJECTILE and _proj_state == ProjectileState.EXPLODING:
			draw_circle(Vector2.ZERO, _get_explosion_radius(), EXPLOSION_COLOR)
		return
	var half: Vector2 = size * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -half.y - 4.0), PlatformType.keys()[platform_type], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if moves and platform_type != PlatformType.PROJECTILE:
		draw_line(Vector2.ZERO, travel, PATH_COLOR, 2.0)
		draw_rect(Rect2(travel - half, size), PATH_COLOR, false, 2.0)
	if platform_type == PlatformType.PROJECTILE:
		_draw_projectile_preview(half)


## Cambia el color placeholder de la plataforma (no el de PULSE, que comunica su fase). Lo usa
## [LevelBuilder] para que cada tier tenga su aspecto (ej.: restos metálicos en el espacio) sin
## duplicar escenas. Alfa 0 = vuelve al color del tipo.
func set_tint(color: Color) -> void:
	_tint = color
	if is_node_ready() and platform_type != PlatformType.PULSE:
		_body.color = _tint if _tint.a > 0.0 else COLOR_BY_TYPE.get(platform_type, COLOR_BY_TYPE[PlatformType.STATIC])


## Vuelve al estado inicial: sólida (salvo LETHAL/PULSE en ON), sin romper, en el origen. Un
## PROJECTILE vuelve quieto, visible y sin disparar (también si ya había desaparecido).
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
	elif platform_type == PlatformType.PROJECTILE:
		_setup_projectile()
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
	# Un poco más chico que el dibujo (lethal_margin por lado): sin esto, un roce apenas por
	# la esquina del jugador cuenta como golpe aunque no se vea así (confirmado con LT: el
	# rectángulo del jugador se solapaba unos px con la esquina de un LETHAL angosto).
	var lethal_margin: float = config.lethal_margin if config != null else 2.0
	var lethal_size: Vector2 = (size - Vector2(lethal_margin, lethal_margin) * 2.0).max(Vector2(2.0, 2.0))
	(_lethal_shape.shape as RectangleShape2D).size = lethal_size
	if not _trigger_shape.shape is CircleShape2D:
		_trigger_shape.shape = CircleShape2D.new()
	(_trigger_shape.shape as CircleShape2D).radius = _get_trigger_radius()
	if not _explosion_shape.shape is CircleShape2D:
		_explosion_shape.shape = CircleShape2D.new()
	(_explosion_shape.shape as CircleShape2D).radius = _get_explosion_radius()


# Muestra u oculta en el editor los círculos de detección del proyectil según
# `show_detection_areas`. En el juego quedan siempre visibles, así "Formas de colisión
# visibles" (menú Depurar) los sigue mostrando.
func _apply_detection_areas_visibility() -> void:
	if not is_node_ready():
		return
	var areas_visible: bool = show_detection_areas or not Engine.is_editor_hint()
	_trigger_shape.visible = areas_visible
	_explosion_shape.visible = areas_visible


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
		_body.color = _tint if _tint.a > 0.0 else COLOR_BY_TYPE.get(platform_type, COLOR_BY_TYPE[PlatformType.STATIC])
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
			_apply_solid(false, true)
			_lethal_area.set_deferred("monitoring", true)
		PlatformType.PROJECTILE:
			_setup_projectile()
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
	if _breaking and _is_step_occupied_and_landed():
		# Solo cuenta mientras el jugador está realmente parado encima (on_floor), no
		# mientras cae y apenas atraviesa la franja sensora de camino a aterrizar — LT
		# reportó que a veces se rompía antes de tocarla, y era justo esto: el sensor está
		# pegado arriba del borde y el jugador lo cruza un poco antes de aterrizar de verdad.
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


# Fase actual de PULSE según el tiempo: [0, off_time) segura
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
	# Mientras es segura se puede atravesar (decisión de LT); `pulse_solid_when_safe` vuelve al
	# comportamiento anterior (sólida mientras es segura).
	var solid_when_safe: bool = config.pulse_solid_when_safe if config != null else false
	_collision.set_deferred("disabled", new_state == PulseState.ON or not solid_when_safe)
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


# Progreso del recorrido (`moves`), de 0 a 1.
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


# true si hay un Player vivo apoyado (on_floor) dentro de la franja sensora de "pisado". Se
# usa para BREAKABLE: no alcanza con estar cruzando la franja, tiene que estar realmente
# parado encima.
func _is_step_occupied_and_landed() -> bool:
	for body: Node2D in _step_sensor.get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive() and player.is_on_floor():
			return true
	return false


# true si hay un Player vivo dentro del rectángulo completo de la plataforma. Se usa antes
# de volverse sólida (TIMED) para no reaparecer empujando al jugador.
func _is_footprint_occupied() -> bool:
	for body: Node2D in _footprint_sensor.get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive():
			return true
	return false


# Activa o desactiva la colisión física. Por defecto la visual acompaña a `solid` (plataformas
# normales/rompibles desaparecen al dejar de ser sólidas). Pasar `body_visible` aparte para los
# casos donde la plataforma sigue mostrándose aunque no sea sólida (p. ej. LETHAL, que nunca
# colisiona físicamente pero sí debe verse). Diferido: seguro dentro de callbacks de física.
func _apply_solid(solid: bool, body_visible: bool = solid) -> void:
	_collision.set_deferred("disabled", not solid)
	_body.visible = body_visible


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
	# Un PROJECTILE que ya explotó o desapareció no golpea por el cuerpo: lo hace la explosión.
	if platform_type == PlatformType.PROJECTILE and (_proj_state == ProjectileState.EXPLODING or _proj_state == ProjectileState.GONE):
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
	if platform_type == PlatformType.PROJECTILE:
		_start_explosion()


# --- PROJECTILE -------------------------------------------------------------------------------

# Deja al proyectil en su estado inicial: quieto en el origen, visible, letal, sin sólido y con
# el disparador armado. Lo usan _apply_type (al arrancar) y reset().
func _setup_projectile() -> void:
	_proj_state = ProjectileState.IDLE
	_proj_elapsed = 0.0
	_proj_travelled = 0.0
	_proj_bounces = 0
	_proj_velocity = Vector2.ZERO
	if config != null and travel.length() > 0.01:
		_proj_velocity = travel.normalized() * config.projectile_speed
	_apply_solid(false, true)
	_lethal_area.set_deferred("monitoring", true)
	_trigger_area.set_deferred("monitoring", projectile_trigger == ProjectileTrigger.DISTANCE)
	_explosion_area.set_deferred("monitoring", false)
	queue_redraw()


func _process_projectile(delta: float) -> void:
	match _proj_state:
		ProjectileState.IDLE:
			_hit_overlapping_lethal_bodies()
			if _is_projectile_trigger_met():
				_proj_elapsed = 0.0
				_proj_state = ProjectileState.WAITING
				_trigger_area.set_deferred("monitoring", false)
				if config.projectile_start_delay <= 0.0:
					_launch()
		ProjectileState.WAITING:
			_hit_overlapping_lethal_bodies()
			_proj_elapsed += delta
			if _proj_elapsed >= config.projectile_start_delay:
				_launch()
		ProjectileState.FLYING:
			_fly(delta)
			if _proj_state == ProjectileState.FLYING:
				_hit_overlapping_lethal_bodies()
		ProjectileState.EXPLODING:
			_proj_elapsed += delta
			_hit_overlapping_explosion_bodies()
			if _proj_elapsed >= config.explosion_duration:
				_vanish()


# true si se cumple el disparador elegido (solo uno a la vez).
func _is_projectile_trigger_met() -> bool:
	if projectile_trigger == ProjectileTrigger.CAMERA:
		var screen: Rect2 = _get_screen_rect()
		if screen.size == Vector2.ZERO:
			return false
		var own: Rect2 = Rect2(global_position - size * 0.5, size)
		return screen.grow(config.projectile_screen_margin).intersects(own)
	# `monitoring` se aplica diferido: en el primer frame puede estar todavía apagado.
	if not _trigger_area.monitoring:
		return false
	for body: Node2D in _trigger_area.get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive():
			return true
	return false


func _launch() -> void:
	_proj_state = ProjectileState.FLYING
	_proj_elapsed = 0.0
	launched.emit()


func _fly(delta: float) -> void:
	var length: float = travel.length()
	if length < 0.01 or config.projectile_speed <= 0.0:
		_finish_route()
		return
	if projectile_end == ProjectileEnd.BOUNCE:
		position += _proj_velocity * delta
		_bounce_against_screen()
		return
	var step: float = config.projectile_speed * delta
	var remaining: float = length - _proj_travelled
	if step >= remaining:
		position = _origin + travel
		_proj_travelled = length
		_finish_route()
	else:
		position += travel / length * step
		_proj_travelled += step


# Final del recorrido para EXPLODE y DESTROY (BOUNCE termina en _bounce_against_screen).
func _finish_route() -> void:
	if projectile_end == ProjectileEnd.EXPLODE:
		_start_explosion()
	else:
		_vanish()


# Rebote contra las 4 paredes de la pantalla (rectángulo visible de la cámara, que se mueve con
# ella). Solo cuenta si va hacia afuera de esa pared; una plataforma que arranca asomada y va
# hacia adentro no rebota. Un choque de esquina cuenta como dos rebotes (uno por eje). Con los
# rebotes agotados, el siguiente choque la hace desaparecer.
func _bounce_against_screen() -> void:
	var screen: Rect2 = _get_screen_rect()
	if screen.size == Vector2.ZERO:
		return
	var half: Vector2 = size * 0.5
	var center: Vector2 = global_position
	var hit_x: bool = (center.x - half.x < screen.position.x and _proj_velocity.x < 0.0) \
			or (center.x + half.x > screen.end.x and _proj_velocity.x > 0.0)
	var hit_y: bool = (center.y - half.y < screen.position.y and _proj_velocity.y < 0.0) \
			or (center.y + half.y > screen.end.y and _proj_velocity.y > 0.0)
	if hit_x:
		if _proj_bounces >= config.projectile_bounce_count:
			_vanish()
			return
		_proj_bounces += 1
		_proj_velocity.x = -_proj_velocity.x
	if hit_y:
		if _proj_bounces >= config.projectile_bounce_count:
			_vanish()
			return
		_proj_bounces += 1
		_proj_velocity.y = -_proj_velocity.y


# Explota en la posición actual: oculta el bloque, apaga la zona letal del cuerpo y enciende la
# zona de la explosión durante `explosion_duration`.
func _start_explosion() -> void:
	if _proj_state == ProjectileState.EXPLODING or _proj_state == ProjectileState.GONE:
		return
	_proj_state = ProjectileState.EXPLODING
	_proj_elapsed = 0.0
	_body.visible = false
	_lethal_area.set_deferred("monitoring", false)
	_trigger_area.set_deferred("monitoring", false)
	_explosion_area.set_deferred("monitoring", true)
	queue_redraw()
	exploded.emit()


# Desaparece: queda oculta y sin ninguna zona activa. No se borra (queue_free) para que
# reset() pueda revivirla.
func _vanish() -> void:
	if _proj_state == ProjectileState.GONE:
		return
	_proj_state = ProjectileState.GONE
	_body.visible = false
	_lethal_area.set_deferred("monitoring", false)
	_trigger_area.set_deferred("monitoring", false)
	_explosion_area.set_deferred("monitoring", false)
	queue_redraw()
	vanished.emit()


# Red de seguridad: si el jugador ya estaba dentro cuando se encendió la explosión, igual muere.
func _hit_overlapping_explosion_bodies() -> void:
	if not _explosion_area.monitoring:
		return
	for body: Node2D in _explosion_area.get_overlapping_bodies():
		_hit_by_explosion(body)


func _on_explosion_entered(body: Node2D) -> void:
	_hit_by_explosion(body)


func _hit_by_explosion(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive():
		return
	player_hit.emit(cause)
	player.die(cause)


# Rectángulo visible de la cámara activa en coordenadas globales. Rect2() vacío si no hay cámara.
func _get_screen_rect() -> Rect2:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return Rect2()
	if camera is ScrollCamera:
		return (camera as ScrollCamera).get_visible_rect()
	var view: Vector2 = get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view * 0.5, view)


func _get_trigger_radius() -> float:
	return config.projectile_trigger_distance if config != null else DEFAULT_TRIGGER_RADIUS


func _get_explosion_radius() -> float:
	return config.explosion_radius if config != null else DEFAULT_EXPLOSION_RADIUS


# Ayudas del editor para PROJECTILE: dirección y fin del recorrido, radio de disparo y radio de
# explosión en el punto donde explotaría.
func _draw_projectile_preview(half: Vector2) -> void:
	if projectile_end == ProjectileEnd.BOUNCE:
		var end_point: Vector2 = travel.normalized() * BOUNCE_PREVIEW_LENGTH if travel.length() > 0.01 else Vector2.ZERO
		draw_line(Vector2.ZERO, end_point, PATH_COLOR, 2.0)
		draw_circle(end_point, 4.0, PATH_COLOR)
	else:
		draw_line(Vector2.ZERO, travel, PATH_COLOR, 2.0)
		draw_rect(Rect2(travel - half, size), PATH_COLOR, false, 2.0)
		if projectile_end == ProjectileEnd.EXPLODE:
			draw_arc(travel, _get_explosion_radius(), 0.0, TAU, 48, PROJECTILE_HELPER_COLOR, 1.5)
	if projectile_trigger == ProjectileTrigger.DISTANCE:
		draw_arc(Vector2.ZERO, _get_trigger_radius(), 0.0, TAU, 64, PROJECTILE_HELPER_COLOR, 1.5)
