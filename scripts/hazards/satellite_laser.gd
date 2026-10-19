@tool
class_name SatelliteLaser
extends Node2D
## Láser de satélite del espacio: un satélite (pegado a un borde de la pantalla) que **apunta**
## con una línea fina barriendo de `angle_from` a `angle_to`, **fija** el blanco (la línea se
## detiene y parpadea rápido) y **dispara** un haz grueso letal `fire_time` s. Después descansa
## `cooldown_time` s y repite (con `ping_pong`, barriendo en sentido contrario cada vez).
## Solo avanza mientras el satélite está a la vista. El haz atraviesa todo. Mata al jugador que lo
## toque durante el disparo (nunca durante el aviso). Placeholders con polígonos. Ver
## `docs/mecanicas/obstaculos-espacio.md`.

## Rojo del haz y del aviso (más claro que el de lo letal, para verse sobre el fondo oscuro).
const BEAM_COLOR: Color = Color("FF5040")
## Núcleo caliente del haz. Solo visual.
const CORE_COLOR: Color = Color("FFE0D6")
## Gris metálico del satélite. Solo visual.
const BODY_COLOR: Color = Color("8A96A8")
## Azul frío de los paneles solares (plataformas, en la paleta). Solo visual.
const PANEL_COLOR: Color = Color("3A9BBF")
## Radio aproximado del cuerpo del jugador para el contacto con el haz. Unidad: px.
const PLAYER_RADIUS: float = 9.0
## Parpadeos por segundo de la fijación del blanco. Solo visual.
const LOCK_BLINK_RATE: float = 8.0
## Parpadeos por segundo de la línea de apuntado. Solo visual.
const AIM_BLINK_RATE: float = 2.5

enum State { IDLE, AIM, LOCK, FIRE, COOLDOWN }

@export_group("Haz")
## Ángulo donde empieza el apuntado (0 = a la derecha, 90 = abajo, 180 = a la izquierda).
## Unidad: °.
@export var angle_from: float = 160.0:
	set(value):
		angle_from = value
		queue_redraw()
## Ángulo donde se fija el blanco y se dispara. Unidad: °.
@export var angle_to: float = 210.0:
	set(value):
		angle_to = value
		queue_redraw()
## Largo del haz. Unidad: px.
@export var beam_length: float = 700.0
## Grosor del haz letal. Unidad: px.
@export var beam_width: float = 14.0
## Si es true, cada ciclo barre en sentido contrario (de `angle_to` a `angle_from`).
@export var ping_pong: bool = true

@export_group("Tiempos")
## Duración del apuntado (la línea fina barre). Unidad: s.
@export var aim_time: float = 1.4
## Duración de la fijación del blanco (la línea parpadea rápido y quieta). Unidad: s.
@export var lock_time: float = 0.4
## Duración del disparo letal. Unidad: s.
@export var fire_time: float = 0.5
## Descanso entre un disparo y el siguiente apuntado. Unidad: s.
@export var cooldown_time: float = 2.0
## Espera inicial, desde que el satélite entra en la vista, antes del primer apuntado (para
## desfasar varios láseres). Unidad: s.
@export var initial_delay: float = 0.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"laser"

var _state: State = State.IDLE
var _t: float = 0.0
var _delay_left: float = 0.0
var _reverse: bool = false
var _angle: float = 0.0


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	reset()


## Vuelve a esperar, con el haz apagado.
func reset() -> void:
	_state = State.IDLE
	_t = 0.0
	_delay_left = initial_delay
	_reverse = false
	_angle = angle_from
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _in_view():
		if _state != State.IDLE or _delay_left != initial_delay:
			reset()
		return
	_t += delta
	match _state:
		State.IDLE:
			_delay_left -= delta
			if _delay_left <= 0.0:
				_enter(State.AIM)
		State.AIM:
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
				_enter(State.COOLDOWN)
		State.COOLDOWN:
			if _t >= cooldown_time:
				if ping_pong:
					_reverse = not _reverse
				_angle = _from()
				_enter(State.AIM)
	queue_redraw()


func _enter(next: State) -> void:
	_state = next
	_t = 0.0


func _from() -> float:
	return angle_to if _reverse else angle_from


func _to() -> float:
	return angle_from if _reverse else angle_to


# El satélite está dentro de la vista de la cámara (con un pequeño margen).
func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(20.0).has_point(global_position)


# Mata al jugador si su cuerpo toca el haz (distancia al segmento del haz).
func _check_player() -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(_angle))
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Player = node as Player
		if player == null or not player.is_alive():
			continue
		var from: Vector2 = global_position
		var to: Vector2 = from + dir * beam_length
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if closest.distance_to(player.global_position) <= beam_width * 0.5 + PLAYER_RADIUS:
			player.die(cause)


func _draw() -> void:
	# Cuerpo del satélite con dos paneles solares y el cañón apuntando al haz.
	draw_rect(Rect2(-8.0, -10.0, 16.0, 20.0), BODY_COLOR)
	draw_rect(Rect2(-8.0 - 22.0, -4.0, 20.0, 8.0), PANEL_COLOR)
	draw_rect(Rect2(8.0 + 2.0, -4.0, 20.0, 8.0), PANEL_COLOR)
	if Engine.is_editor_hint():
		var mid: Color = Color(1.0, 0.42, 0.2, 0.8)
		for deg: float in [angle_from, angle_to]:
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(deg_to_rad(deg)) * 120.0, mid, 1.5)
		draw_arc(Vector2.ZERO, 60.0, deg_to_rad(minf(angle_from, angle_to)), deg_to_rad(maxf(angle_from, angle_to)), 24, mid, 2.0)
		return
	var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(_angle))
	draw_line(Vector2.ZERO, dir * 14.0, BODY_COLOR.lightened(0.25), 5.0)
	var end: Vector2 = dir * beam_length
	match _state:
		State.AIM:
			var blink: float = 0.55 + 0.45 * sin(_t * TAU * AIM_BLINK_RATE)
			draw_line(dir * 14.0, end, Color(BEAM_COLOR, 0.25 + 0.25 * blink), 1.5)
		State.LOCK:
			var blink: float = 0.5 + 0.5 * sin(_t * TAU * LOCK_BLINK_RATE)
			draw_line(dir * 14.0, end, Color(BEAM_COLOR, 0.35 + 0.65 * blink), 3.0)
		State.FIRE:
			draw_line(dir * 14.0, end, Color(BEAM_COLOR, 0.35), beam_width * 1.9)
			draw_line(dir * 14.0, end, BEAM_COLOR, beam_width)
			draw_line(dir * 14.0, end, CORE_COLOR, beam_width * 0.4)
		_:
			pass
