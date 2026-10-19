@tool
class_name MinorTentacle
extends Node2D
## Tentáculo menor del tier 3: un tentáculo que brota de la pared del túnel, **barre** un arco y se
## retrae. Ciclo: **escondido** → **aviso** (`warning_time`: asoma un poco, tiembla y se marca el
## sector que va a barrer con una cuña tenue) → **barrido** (`sweep_time`: gira de `angle_from` a
## `angle_to`, estirado, letal) → **retracción** → descanso (`cooldown_time`). Es un tentáculo
## pequeño, no el perseguidor. Solo actúa con el origen a la vista. Placeholders con polígonos.
## Ver `docs/mecanicas/amenazas-alien.md`.

## Rojo letal de la paleta. Solo visual.
const BODY_COLOR: Color = Color("D83232")
## Rojo oscuro de la base y de las ventosas. Solo visual.
const DARK_COLOR: Color = Color("8E1F2B")
## Color de la cuña de aviso. Solo visual.
const WARNING_COLOR: Color = Color(1.0, 0.31, 0.25, 0.18)
## Radio aproximado del cuerpo del jugador. Unidad: px.
const PLAYER_RADIUS: float = 9.0
## Tramos con los que se dibuja y colisiona el tentáculo. Solo visual y gameplay.
const SEGMENTS: int = 10

enum State { HIDDEN, WARN, SWEEP, RETRACT }

@export_group("Barrido")
## Ángulo inicial del barrido (0 = derecha, 90 = abajo, 180 = izquierda). Unidad: °.
@export var angle_from: float = 150.0:
	set(value):
		angle_from = value
		queue_redraw()
## Ángulo final del barrido. Unidad: °.
@export var angle_to: float = 210.0:
	set(value):
		angle_to = value
		queue_redraw()
## Largo del tentáculo estirado. Unidad: px.
@export var tentacle_length: float = 150.0:
	set(value):
		tentacle_length = value
		queue_redraw()
## Grosor en la base. Unidad: px.
@export var base_width: float = 14.0

@export_group("Tiempos")
## Aviso previo. Unidad: s.
@export var warning_time: float = 0.9
## Duración del barrido. Unidad: s.
@export var sweep_time: float = 0.9
## Duración de la retracción. Unidad: s.
@export var retract_time: float = 0.5
## Descanso entre ciclos. Unidad: s.
@export var cooldown_time: float = 1.8
## Espera inicial para desfasar varios. Unidad: s.
@export var initial_delay: float = 1.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"minor_tentacle"

var _state: State = State.HIDDEN
var _t: float = 0.0
var _wait: float = 0.0
var _reach: float = 0.0
var _angle: float = 0.0
var _clock: float = 0.0


func _ready() -> void:
	_wait = initial_delay
	_angle = angle_from
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _in_view():
		reset()
		return
	_clock += delta
	match _state:
		State.HIDDEN:
			_wait -= delta
			_reach = 0.0
			if _wait <= 0.0:
				_state = State.WARN
				_t = 0.0
				_angle = angle_from
		State.WARN:
			_t += delta
			_reach = 0.25 * smoothstep(0.0, 0.6, _t / maxf(warning_time, 0.001))
			if _t >= warning_time:
				_state = State.SWEEP
				_t = 0.0
		State.SWEEP:
			_t += delta
			var k: float = clampf(_t / maxf(sweep_time, 0.001), 0.0, 1.0)
			_angle = lerpf(angle_from, angle_to, smoothstep(0.0, 1.0, k))
			_reach = lerpf(0.25, 1.0, smoothstep(0.0, 0.25, k))
			_check_player()
			if _t >= sweep_time:
				_state = State.RETRACT
				_t = 0.0
		State.RETRACT:
			_t += delta
			_reach = lerpf(1.0, 0.0, clampf(_t / maxf(retract_time, 0.001), 0.0, 1.0))
			if _t >= retract_time:
				_state = State.HIDDEN
				_wait = cooldown_time
	queue_redraw()


## Se esconde y vuelve a esperar (al reiniciar la partida).
func reset() -> void:
	_state = State.HIDDEN
	_t = 0.0
	_wait = initial_delay
	_reach = 0.0
	_angle = angle_from
	queue_redraw()


func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(40.0).has_point(global_position)


# Puntos locales del tentáculo para el ángulo y alcance actuales (con una curvatura que ondula).
func _points() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var a: float = deg_to_rad(_angle)
	var length: float = tentacle_length * _reach
	var bend: float = sin(_clock * 3.0) * 0.35 + 0.35 * signf(angle_to - angle_from)
	var pos: Vector2 = Vector2.ZERO
	pts.append(pos)
	for i: int in SEGMENTS:
		var f: float = float(i + 1) / float(SEGMENTS)
		a += bend * 0.08 * f
		pos += Vector2.RIGHT.rotated(a) * (length / float(SEGMENTS))
		pts.append(pos)
	return pts


func _check_player() -> void:
	var pts: PackedVector2Array = _points()
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Player = node as Player
		if player == null or not player.is_alive():
			continue
		for i: int in pts.size() - 1:
			var width: float = lerpf(base_width, 4.0, float(i) / float(SEGMENTS))
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(to_local(player.global_position), pts[i], pts[i + 1])
			if closest.distance_to(to_local(player.global_position)) <= width * 0.5 + PLAYER_RADIUS:
				player.die(cause)
				return


func _draw() -> void:
	if Engine.is_editor_hint():
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for s: int in 13:
			wedge.append(Vector2.RIGHT.rotated(deg_to_rad(lerpf(angle_from, angle_to, float(s) / 12.0))) * tentacle_length)
		draw_colored_polygon(wedge, Color(1, 1, 1, 0.12))
		return
	# Base: bulto de carne en la pared.
	draw_circle(Vector2.ZERO, base_width * 0.6, DARK_COLOR)
	if _state == State.WARN:
		var k: float = _t / maxf(warning_time, 0.001)
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for s: int in 13:
			wedge.append(Vector2.RIGHT.rotated(deg_to_rad(lerpf(angle_from, angle_to, float(s) / 12.0))) * tentacle_length)
		draw_colored_polygon(wedge, Color(WARNING_COLOR, WARNING_COLOR.a * (0.4 + 0.6 * k)))
	if _reach <= 0.01:
		return
	var pts: PackedVector2Array = _points()
	var shake: Vector2 = Vector2(sin(_clock * 60.0), cos(_clock * 70.0)) * 1.5 if _state == State.WARN else Vector2.ZERO
	for i: int in pts.size() - 1:
		var width: float = lerpf(base_width, 4.0, float(i) / float(SEGMENTS))
		draw_line(pts[i] + shake, pts[i + 1] + shake, BODY_COLOR if i % 2 == 0 else Color(BODY_COLOR, 0.9), width)
		if i % 2 == 1:
			draw_circle(pts[i] + shake, width * 0.22, DARK_COLOR)
