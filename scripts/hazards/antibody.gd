@tool
class_name Antibody
extends Node2D
## Anticuerpo del tier 3: una defensa del cuerpo que patrulla un tramo recto del túnel (del origen
## del nodo a origen + `travel`). Si el jugador pasa a menos de `detect_radius` px, **se lanza** a
## `chase_speed` hacia el punto de su tramo más cercano al jugador durante `chase_time` s (nunca sale
## del tramo, así no atraviesa paredes); después se agota y descansa `recover_time` s sin detectar.
## Tocarlo mata. Solo actúa con el nodo a la vista. Placeholders con polígonos. Ver
## `docs/mecanicas/amenazas-alien.md`.

## Rojo letal de la paleta. Solo visual.
const BODY_COLOR: Color = Color("D83232")
## Color del cuerpo al lanzarse. Solo visual.
const ALERT_COLOR: Color = Color("FF6B5A")
## Radio aproximado del cuerpo del jugador. Unidad: px.
const PLAYER_RADIUS: float = 9.0

enum State { PATROL, CHASE, RECOVER }

@export_group("Recorrido")
## Vector del recorrido de patrulla, desde la posición del nodo. Unidad: px.
@export var travel: Vector2 = Vector2(100.0, 0.0):
	set(value):
		travel = value
		queue_redraw()
## Velocidad de patrulla. Unidad: px/s.
@export var patrol_speed: float = 40.0
## Velocidad al lanzarse. Unidad: px/s.
@export var chase_speed: float = 120.0

@export_group("Detección")
## Distancia a la que detecta al jugador. Unidad: px.
@export var detect_radius: float = 140.0
## Duración de la embestida. Unidad: s.
@export var chase_time: float = 1.8
## Descanso tras la embestida, sin detectar. Unidad: s.
@export var recover_time: float = 1.5

@export_group("Forma")
## Radio del cuerpo. Unidad: px.
@export var body_radius: float = 11.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"antibody"

var _state: State = State.PATROL
var _t: float = 0.0
var _u: float = 0.0
var _dir_sign: float = 1.0
var _clock: float = 0.0


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
	match _state:
		State.PATROL:
			_u += _dir_sign * patrol_speed * delta / length
			if _u >= 1.0 or _u <= 0.0:
				_u = clampf(_u, 0.0, 1.0)
				_dir_sign = -_dir_sign
			if player != null and global_position.distance_to(player.global_position) <= detect_radius + length * 0.5 and _body_pos().distance_to(player.global_position) <= detect_radius:
				_state = State.CHASE
				_t = 0.0
		State.CHASE:
			_t += delta
			if player != null:
				var target: float = _project(player.global_position)
				_u = move_toward(_u, target, chase_speed * delta / length)
			if _t >= chase_time:
				_state = State.RECOVER
				_t = 0.0
		State.RECOVER:
			_t += delta
			_u += _dir_sign * patrol_speed * delta / length
			if _u >= 1.0 or _u <= 0.0:
				_u = clampf(_u, 0.0, 1.0)
				_dir_sign = -_dir_sign
			if _t >= recover_time:
				_state = State.PATROL
	if player != null and player.is_alive() and _body_pos().distance_to(player.global_position) <= body_radius + PLAYER_RADIUS:
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
	var alert: bool = _state == State.CHASE
	var tired: bool = _state == State.RECOVER
	var col: Color = ALERT_COLOR if alert else BODY_COLOR
	if tired:
		col = Color(BODY_COLOR, 0.7)
	var wob: float = sin(_clock * (14.0 if alert else 5.0))
	var r: float = body_radius * (1.0 + 0.08 * wob)
	# Brazos en Y.
	for a: float in [-2.4, -0.74, 1.57]:
		var d: Vector2 = Vector2.RIGHT.rotated(a + 0.15 * wob)
		draw_line(at + d * r * 0.6, at + d * r * 1.7, col, 3.0)
	draw_circle(at, r, col)
	draw_circle(at, r * 0.45, Color("FFB199") if alert else Color("7A1A1A"))
