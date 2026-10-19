@tool
class_name Antibody
extends Node2D
## Anticuerpo del tier 3: una defensa del cuerpo que patrulla un tramo recto del túnel (del origen
## del nodo a origen + `travel`), despacio. Ciclo de ataque, siempre legible:
## 1. **FIJA** (`lock_time`): si el jugador pasa a menos de `detect_radius`, se frena, tiembla, se
##    pone rojo claro, el ojo gira hacia el jugador y una línea punteada lo une a él. Al terminar,
##    **congela** el punto objetivo (el punto de su tramo más cercano al jugador en ese momento).
## 2. **EMBISTE**: se lanza en línea recta a `lunge_speed` hasta ese punto, sin seguir al jugador.
##    Se esquiva yéndose del punto (o dejándolo pasar).
## 3. **AGOTADO** (`tired_time`): gris, con los brazos caídos y quieto, y es **inofensivo**: es la
##    ventana para pasar. Después vuelve a patrullar.
## Nunca sale del tramo (no atraviesa paredes). Mata al tocarlo salvo agotado. Solo actúa con el nodo
## a la vista. Placeholders con polígonos. Ver `docs/mecanicas/amenazas-alien.md`.

## Rojo letal de la paleta. Solo visual.
const BODY_COLOR: Color = Color("D83232")
## Color del cuerpo al fijar y embestir. Solo visual.
const ALERT_COLOR: Color = Color("FF6B5A")
## Gris del anticuerpo agotado (inofensivo). Solo visual.
const TIRED_COLOR: Color = Color("7C828C")
## Radio aproximado del cuerpo del jugador. Unidad: px.
const PLAYER_RADIUS: float = 9.0

enum State { PATROL, LOCK, LUNGE, TIRED }

@export_group("Recorrido")
## Vector del recorrido de patrulla, desde la posición del nodo. Unidad: px.
@export var travel: Vector2 = Vector2(100.0, 0.0):
	set(value):
		travel = value
		queue_redraw()
## Velocidad de patrulla. Unidad: px/s.
@export var patrol_speed: float = 35.0
## Velocidad de la embestida. Unidad: px/s.
@export var lunge_speed: float = 150.0

@export_group("Ataque")
## Distancia a la que detecta al jugador. Unidad: px.
@export var detect_radius: float = 110.0
## Tiempo que fija al jugador antes de embestir (el aviso). Unidad: s.
@export var lock_time: float = 0.8
## Tiempo agotado e inofensivo tras la embestida. Unidad: s.
@export var tired_time: float = 2.2

@export_group("Forma")
## Radio del cuerpo. Unidad: px.
@export var body_radius: float = 11.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"antibody"

var _state: State = State.PATROL
var _t: float = 0.0
var _u: float = 0.0
var _u_target: float = 0.0
var _dir_sign: float = 1.0
var _clock: float = 0.0
var _look: Vector2 = Vector2.DOWN


func _ready() -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _in_view():
		reset()
		return
	_clock += delta
	var length: float = maxf(travel.length(), 1.0)
	var player: Player = _player()
	if player != null:
		_look = (player.global_position - _body_pos()).normalized()
	match _state:
		State.PATROL:
			_u += _dir_sign * patrol_speed * delta / length
			if _u >= 1.0 or _u <= 0.0:
				_u = clampf(_u, 0.0, 1.0)
				_dir_sign = -_dir_sign
			if player != null and player.is_alive() and _body_pos().distance_to(player.global_position) <= detect_radius:
				_state = State.LOCK
				_t = 0.0
		State.LOCK:
			_t += delta
			if player != null:
				_u_target = _project(player.global_position)
			if _t >= lock_time:
				_state = State.LUNGE
				_t = 0.0
		State.LUNGE:
			_u = move_toward(_u, _u_target, lunge_speed * delta / length)
			if is_equal_approx(_u, _u_target):
				_state = State.TIRED
				_t = 0.0
		State.TIRED:
			_t += delta
			if _t >= tired_time:
				_state = State.PATROL
	if _state != State.TIRED and player != null and player.is_alive() and _body_pos().distance_to(player.global_position) <= body_radius + PLAYER_RADIUS:
		player.die(cause)
	queue_redraw()


## Vuelve al inicio del tramo, en patrulla (al reiniciar la partida).
func reset() -> void:
	_state = State.PATROL
	_t = 0.0
	_u = 0.0
	_dir_sign = 1.0


func _body_pos() -> Vector2:
	return global_position + travel * _u


# Posición (0–1) del punto del tramo más cercano al punto global [param p].
func _project(p: Vector2) -> float:
	var len_sq: float = travel.length_squared()
	if len_sq <= 0.0:
		return 0.0
	return clampf((p - global_position).dot(travel) / len_sq, 0.0, 1.0)


func _player() -> Player:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		return node as Player
	return null


func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(40.0).has_point(global_position)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, travel, Color(1, 1, 1, 0.4), 1.0)
	var at: Vector2 = travel * _u
	var col: Color = BODY_COLOR
	var r: float = body_radius
	var arm_angles: Array[float] = [-2.4, -0.74, 1.57]
	var eye: Color = Color("7A1A1A")
	match _state:
		State.PATROL:
			r *= 1.0 + 0.06 * sin(_clock * 5.0)
		State.LOCK:
			var k: float = _t / maxf(lock_time, 0.001)
			# Tiembla cada vez más, parpadea y apunta con el ojo; línea punteada al jugador.
			at += Vector2(sin(_clock * 70.0), cos(_clock * 83.0)) * (0.8 + 2.2 * k)
			col = ALERT_COLOR if int(_clock * 14.0) % 2 == 0 else BODY_COLOR
			r *= 1.0 + 0.25 * k
			eye = Color("FFE0D6")
			draw_dashed_line(at, at + _look * minf(detect_radius, 90.0), Color(ALERT_COLOR, 0.35 + 0.4 * k), 2.0, 5.0)
			arm_angles = [-2.7, -0.44, 1.57]
		State.LUNGE:
			col = ALERT_COLOR
			eye = Color("FFE0D6")
			r *= 1.1
		State.TIRED:
			col = TIRED_COLOR
			r *= 0.9 + 0.04 * sin(_clock * 2.0)
			eye = Color("4A4F58")
			arm_angles = [2.3, 0.84, 1.57]
	for a: float in arm_angles:
		var d: Vector2 = Vector2.RIGHT.rotated(a)
		draw_line(at + d * r * 0.6, at + d * r * (1.7 if _state != State.TIRED else 1.35), col, 3.0)
	draw_circle(at, r, col)
	draw_circle(at, r * 0.5, Color(0.12, 0.12, 0.14) if _state == State.TIRED else Color("5A1010"))
	draw_circle(at + _look * r * 0.18, r * 0.28, eye)
