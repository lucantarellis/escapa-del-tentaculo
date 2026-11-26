@tool
class_name LaserTentacle
extends Node2D
## Tentáculo láser del espacio: la punta de un tentáculo del alien que asoma por un costado de la
## pantalla y termina en un ojo. **Apunta** con una línea punteada barriendo de `angle_from` a
## `angle_to`, **fija** el blanco (el ojo se achica y se carga) y **dispara** un haz grueso letal
## `fire_time` s desde el ojo. Después descansa `cooldown_time` s (el ojo se reabre) y repite (con
## `ping_pong`, barriendo en sentido contrario cada vez).
## Solo avanza mientras está a la vista. El haz atraviesa todo. Mata al jugador que lo toque
## durante el disparo (nunca durante el aviso).
## El nodo va en el borde de la pantalla (x = 0 o x = ancho): ahí está la base del tentáculo. El
## arte (`laser_tentacle`) está dibujado entrando desde la derecha; en el borde izquierdo se espeja
## y se usa el ángulo espejado (180° − ángulo). Los ángulos del barrido siguen la convención del
## código (0 = derecha, 90 = abajo) y el arte cubre de 150° a 210° (o su espejo) cada 5°. Ver
## `docs/arte/peligros-espacio.md` y `docs/mecanicas/obstaculos-espacio.md`.

## Rojo del haz y del aviso (más claro que el de lo letal, para verse sobre el fondo oscuro).
const BEAM_COLOR: Color = Color("FF5040")
## Núcleo caliente del haz. Solo visual.
const CORE_COLOR: Color = Color("FFE0D6")
## Color del brillo del ojo al empezar a cargar, a la mitad y al terminar (rojo → naranja →
## amarillo). Solo visual.
const CHARGE_COLORS: Array[Color] = [Color("FF3A30"), Color("FF8A30"), Color("FFE060")]
## Radio aproximado del cuerpo del jugador para el contacto con el haz. Unidad: px.
const PLAYER_RADIUS: float = 9.0
## Parpadeos por segundo de la fijación del blanco. Solo visual.
const LOCK_BLINK_RATE: float = 8.0
## Parpadeos por segundo de la línea de apuntado. Solo visual.
const AIM_BLINK_RATE: float = 2.5
## Largo del trazo y del hueco de la línea de apuntado. Solo visual. Unidad: px.
const AIM_DASH: float = 6.0

## Nombre de la hoja de cuadros del tentáculo (ver [HazardSheet]). Estructural.
const SHEET_NAME: String = "laser_tentacle"
## JSON con la posición del ojo en cada cuadro. Estructural.
const MUZZLE_PATH: String = "res://assets/sprites/hazards/laser_tentacle_muzzle.json"
## Píxel de la base del tentáculo en el cuadro (entra desde la derecha). Estructural. Unidad: px.
const BASE_PIXEL: Vector2 = Vector2(149.0, 85.0)
## Rango y paso de los ángulos dibujados (el arte trae un tag por cada uno). Estructural. Unidad: °.
const TAG_ANGLE_MIN: int = 150
const TAG_ANGLE_MAX: int = 210
const TAG_ANGLE_STEP: int = 5
## Cuadros por tag de apuntado, fijación y disparo. Estructural.
const AIM_FRAMES: int = 8
const LOCK_FRAMES: int = 6
const FIRE_FRAMES: int = 6
## Duración de un cuadro de apuntado (la onda que recorre el tallo). Solo visual. Unidad: s.
const AIM_FRAME_TIME: float = 0.1
## Duración de reabrir el ojo al empezar el descanso (`lock` al revés). Solo visual. Unidad: s.
const REOPEN_TIME: float = 0.42
## Velocidad con que el tentáculo gira hacia el ángulo al que apunta (no salta de un tag a otro).
## Solo visual. Unidad: °/s.
const POSE_SPEED: float = 90.0
## Margen alrededor de la vista con el que asoma el tentáculo (su dibujo mide 170 px de alto) y con
## el que empieza a actuar. Unidad: px.
const SHOW_MARGIN: float = 95.0
const ACTIVE_MARGIN: float = 20.0

enum State { IDLE, AIM, LOCK, FIRE, COOLDOWN }
## Fase del dibujo: oculto, asomando (`emerge`), listo (sigue a la máquina de estados) o
## retrocediendo (`emerge` al revés).
enum Phase { HIDDEN, EMERGING, READY, RETRACTING }

@export_group("Haz")
## Ángulo donde empieza el apuntado (0 = a la derecha, 90 = abajo, 180 = a la izquierda).
## Unidad: °.
@export var angle_from: float = 160.0:
	set(value):
		angle_from = value
		_refresh_editor()
## Ángulo donde se fija el blanco y se dispara. Unidad: °.
@export var angle_to: float = 210.0:
	set(value):
		angle_to = value
		_refresh_editor()
## Largo del haz. Unidad: px.
@export var beam_length: float = 700.0
## Grosor del haz letal. Unidad: px.
@export var beam_width: float = 14.0
## Si es true, cada ciclo barre en sentido contrario (de `angle_to` a `angle_from`).
@export var ping_pong: bool = true

@export_group("Tiempos")
## Duración del apuntado (la línea fina barre). Unidad: s.
@export var aim_time: float = 1.4
## Duración de la fijación del blanco (el ojo se achica y se carga). Unidad: s.
@export var lock_time: float = 0.4
## Duración del disparo letal. Unidad: s.
@export var fire_time: float = 0.5
## Descanso entre un disparo y el siguiente apuntado. Unidad: s.
@export var cooldown_time: float = 2.0
## Espera inicial, desde que el tentáculo terminó de asomar, antes del primer apuntado (para
## desfasar varios láseres). Unidad: s.
@export var initial_delay: float = 0.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"laser"

static var _muzzles: Array = []

var _state: State = State.IDLE
var _phase: Phase = Phase.HIDDEN
var _t: float = 0.0
var _delay_left: float = 0.0
var _reverse: bool = false
var _angle: float = 0.0
## Ángulo con el que se elige el tag del dibujo (sigue a `_angle` con velocidad limitada).
var _pose_angle: float = 180.0
var _cool_from: float = 0.0
var _emerge_t: float = 0.0
var _aim_phase: float = 0.0
var _was_active: bool = false
var _gone: bool = false
var _from_left: bool = false
var _sheet: HazardSheet = null
var _visual: Node2D = null
var _sprite: Sprite2D = null
var _emissive: Sprite2D = null
var _fx: Node2D = null
var _frame: int = 0


func _ready() -> void:
	_build_nodes()
	if Engine.is_editor_hint():
		_refresh_editor()
		return
	reset()


## Vuelve a esperar, con el haz apagado y el tentáculo escondido.
func reset() -> void:
	_state = State.IDLE
	_phase = Phase.HIDDEN
	_t = 0.0
	_delay_left = initial_delay
	_reverse = false
	_angle = angle_from
	_emerge_t = 0.0
	_aim_phase = 0.0
	_was_active = false
	_gone = false
	_from_left = _is_left_side()
	_pose_angle = 0.0 if _from_left else 180.0
	if _visual != null:
		_visual.visible = false
		_fx.queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var shown: bool = _in_view(SHOW_MARGIN)
	var active: bool = _in_view(ACTIVE_MARGIN)
	if not shown:
		if _phase != Phase.HIDDEN or _gone or _delay_left != initial_delay:
			reset()
		return
	match _phase:
		Phase.HIDDEN:
			if not _gone:
				_phase = Phase.EMERGING
				_emerge_t = 0.0
		Phase.EMERGING:
			_emerge_t += delta
			if _emerge_t >= _sheet.tag_duration(&"emerge"):
				_emerge_t = _sheet.tag_duration(&"emerge")
				_phase = Phase.READY
		Phase.READY:
			if active:
				_was_active = true
				_step_logic(delta)
			elif _was_active:
				_retract()
		Phase.RETRACTING:
			_emerge_t -= delta
			if _emerge_t <= 0.0:
				_emerge_t = 0.0
				_phase = Phase.HIDDEN
				_gone = true
	_update_visual(delta)


# Avanza la máquina de estados (solo con el tentáculo asomado y a la vista).
func _step_logic(delta: float) -> void:
	_t += delta
	match _state:
		State.IDLE:
			_aim_phase += delta
			_delay_left -= delta
			if _delay_left <= 0.0:
				_enter(State.AIM)
		State.AIM:
			_aim_phase += delta
			_angle = lerpf(_from(), _to(), smoothstep(0.0, 1.0, _t / maxf(aim_time, 0.001)))
			if _t >= aim_time:
				_angle = _to()
				_enter(State.LOCK)
		State.LOCK:
			if _t >= lock_time:
				_enter(State.FIRE)
		State.FIRE:
			_check_player()
			if _t >= fire_time:
				_cool_from = _angle
				_enter(State.COOLDOWN)
		State.COOLDOWN:
			_aim_phase += delta
			var reopen: float = minf(REOPEN_TIME, cooldown_time)
			var rest: float = maxf(cooldown_time - reopen, 0.001)
			# Punto donde empieza el próximo barrido (con `ping_pong`, donde terminó este).
			var next_from: float = _to() if ping_pong else angle_from
			_angle = lerpf(_cool_from, next_from, smoothstep(0.0, 1.0, clampf((_t - reopen) / rest, 0.0, 1.0)))
			if _t >= cooldown_time:
				if ping_pong:
					_reverse = not _reverse
				_angle = _from()
				_enter(State.AIM)


func _enter(next: State) -> void:
	_state = next
	_t = 0.0


# Retira el tentáculo (`emerge` al revés) y deja la máquina lista para el próximo asomo.
func _retract() -> void:
	_phase = Phase.RETRACTING
	_state = State.IDLE
	_t = 0.0
	_delay_left = initial_delay
	_was_active = false


func _from() -> float:
	return angle_to if _reverse else angle_from


func _to() -> float:
	return angle_from if _reverse else angle_to


# El tentáculo está dentro de la vista de la cámara con ese margen.
func _in_view(margin: float) -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(margin).has_point(global_position)


# true si el nodo está en el borde izquierdo de la pantalla (el arte se espeja).
func _is_left_side() -> bool:
	var width: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 360))
	return global_position.x < width * 0.5


# Posición del ojo (de donde sale el haz) en el espacio global, según el cuadro que se muestra.
func _muzzle_global() -> Vector2:
	return global_position + _muzzle_local()


func _muzzle_local() -> Vector2:
	var table: Array = _get_muzzles()
	if _frame < 0 or _frame >= table.size():
		return Vector2.ZERO
	var point: Array = table[_frame]
	return Vector2(float(point[0]) * (-1.0 if _from_left else 1.0), float(point[1]))


static func _get_muzzles() -> Array:
	if _muzzles.is_empty():
		var json: JSON = load(MUZZLE_PATH) as JSON
		_muzzles = json.data.muzzle_per_frame
	return _muzzles


# Mata al jugador si su cuerpo toca el haz (distancia al segmento del haz).
func _check_player() -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(_angle))
	var from: Vector2 = _muzzle_global()
	var to: Vector2 = from + dir * beam_length
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Player = node as Player
		if player == null or not player.is_alive():
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if closest.distance_to(player.global_position) <= beam_width * 0.5 + PLAYER_RADIUS:
			player.die(cause)


# ---------------------------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------------------------

func _build_nodes() -> void:
	_sheet = HazardSheet.get_sheet(SHEET_NAME)
	_visual = Node2D.new()
	_visual.name = "Visual"
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_visual)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = _sheet.texture
	_sprite.centered = false
	_sprite.offset = -BASE_PIXEL
	_sprite.region_enabled = true
	_visual.add_child(_sprite)
	if _sheet.emissive != null:
		_emissive = Sprite2D.new()
		_emissive.name = "Emissive"
		_emissive.texture = _sheet.emissive
		_emissive.centered = false
		_emissive.offset = -BASE_PIXEL
		_emissive.region_enabled = true
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_emissive.material = unshaded
		_visual.add_child(_emissive)
	# Línea de apuntado, brillo del ojo y haz: aditivos y sin sombrear, encima del tentáculo.
	_fx = Node2D.new()
	_fx.name = "Fx"
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_fx.material = additive
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_set_frame(&"emerge", 0)


# Muestra el cuadro `index` del tag.
func _set_frame(tag: StringName, index: int) -> void:
	var count: int = _sheet.tag_length(tag)
	_frame = _sheet.tag_first(tag) + clampi(index, 0, count - 1)
	var rect: Rect2 = _sheet.region(_frame)
	_sprite.region_rect = rect
	if _emissive != null:
		_emissive.region_rect = rect


# Tag de ángulo (150 a 210, de 5 en 5) más cercano al ángulo del juego, espejado en el borde
# izquierdo. Fuera del rango queda en el extremo.
func _tag_angle(game_angle: float) -> int:
	var drawn: float = 180.0 - game_angle if _from_left else game_angle
	drawn = fposmod(drawn, 360.0)
	var snapped_angle: int = roundi(drawn / float(TAG_ANGLE_STEP)) * TAG_ANGLE_STEP
	return clampi(snapped_angle, TAG_ANGLE_MIN, TAG_ANGLE_MAX)


func _update_visual(delta: float) -> void:
	_visual.visible = _phase != Phase.HIDDEN
	_visual.scale = Vector2(-1.0 if _from_left else 1.0, 1.0)
	if _phase == Phase.HIDDEN:
		_fx.queue_redraw()
		return
	if _phase == Phase.EMERGING or _phase == Phase.RETRACTING:
		_set_emerge_frame()
		_fx.queue_redraw()
		return
	# Con el tentáculo listo: sigue al ángulo del barrido con velocidad limitada.
	var target: float = _angle if _state != State.IDLE else _from()
	_pose_angle = move_toward(_pose_angle, target, POSE_SPEED * delta)
	var suffix: String = "_%d" % _tag_angle(_pose_angle)
	match _state:
		State.IDLE:
			_set_frame(StringName("aim" + suffix), int(_aim_phase / AIM_FRAME_TIME) % AIM_FRAMES)
		State.AIM:
			_set_frame(StringName("aim" + suffix), int(_aim_phase / AIM_FRAME_TIME) % AIM_FRAMES)
		State.LOCK:
			_set_frame(StringName("lock" + suffix), int(_t / maxf(lock_time, 0.001) * float(LOCK_FRAMES)))
		State.FIRE:
			_set_frame(StringName("fire" + suffix), int(_t / maxf(fire_time, 0.001) * float(FIRE_FRAMES)))
		State.COOLDOWN:
			var reopen: float = minf(REOPEN_TIME, cooldown_time)
			if _t < reopen:
				_set_frame(StringName("lock" + suffix), LOCK_FRAMES - 1 - int(_t / reopen * float(LOCK_FRAMES)))
			else:
				_set_frame(StringName("aim" + suffix), int(_aim_phase / AIM_FRAME_TIME) % AIM_FRAMES)
	_fx.queue_redraw()


# Cuadro del `emerge` según el tiempo transcurrido (`_emerge_t`; al retirarse baja hasta 0).
func _set_emerge_frame() -> void:
	var first: int = _sheet.tag_first(&"emerge")
	var count: int = _sheet.tag_length(&"emerge")
	var elapsed: float = 0.0
	var index: int = 0
	for i: int in count:
		elapsed += _sheet.durations[first + i]
		if _emerge_t < elapsed:
			index = i
			break
		index = i
	_set_frame(&"emerge", index)


func _draw_fx() -> void:
	if Engine.is_editor_hint() or _phase != Phase.READY:
		return
	var eye: Vector2 = _muzzle_local()
	var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(_angle))
	var end: Vector2 = eye + dir * beam_length
	match _state:
		State.AIM:
			var blink: float = 0.55 + 0.45 * sin(_t * TAU * AIM_BLINK_RATE)
			_fx.draw_dashed_line(eye, end, Color(BEAM_COLOR, 0.25 + 0.25 * blink), 1.5, AIM_DASH)
		State.LOCK:
			var progress: float = clampf(_t / maxf(lock_time, 0.001), 0.0, 1.0)
			var blink: float = 0.5 + 0.5 * sin(_t * TAU * LOCK_BLINK_RATE)
			_fx.draw_dashed_line(eye, end, Color(BEAM_COLOR, 0.35 + 0.65 * blink), 3.0, AIM_DASH)
			_fx.draw_circle(eye, 2.0 + 4.0 * progress, Color(_charge_color(progress), 0.5 + 0.5 * progress))
		State.FIRE:
			_fx.draw_line(eye, end, Color(BEAM_COLOR, 0.35), beam_width * 1.9)
			_fx.draw_line(eye, end, BEAM_COLOR, beam_width)
			_fx.draw_line(eye, end, CORE_COLOR, beam_width * 0.4)
			_fx.draw_circle(eye, beam_width * 0.7, Color(CORE_COLOR, 0.8))
		_:
			pass


# Rojo → naranja → amarillo según el progreso de la carga (0 a 1).
func _charge_color(progress: float) -> Color:
	if progress < 0.5:
		return CHARGE_COLORS[0].lerp(CHARGE_COLORS[1], progress * 2.0)
	return CHARGE_COLORS[1].lerp(CHARGE_COLORS[2], (progress - 0.5) * 2.0)


# En el editor: muestra el tentáculo apuntando entre los dos ángulos, con el rango dibujado.
func _refresh_editor() -> void:
	if not Engine.is_editor_hint() or not is_node_ready() or _sprite == null:
		return
	_from_left = _is_left_side()
	_visual.visible = true
	_visual.scale = Vector2(-1.0 if _from_left else 1.0, 1.0)
	var middle: float = (angle_from + angle_to) * 0.5
	_set_frame(StringName("aim_%d" % _tag_angle(middle)), 0)
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var eye: Vector2 = _muzzle_local()
	var mid: Color = Color(1.0, 0.42, 0.2, 0.8)
	for deg: float in [angle_from, angle_to]:
		draw_line(eye, eye + Vector2.RIGHT.rotated(deg_to_rad(deg)) * 120.0, mid, 1.5)
	draw_arc(eye, 60.0, deg_to_rad(minf(angle_from, angle_to)), deg_to_rad(maxf(angle_from, angle_to)), 24, mid, 2.0)
