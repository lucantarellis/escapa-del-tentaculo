@tool
class_name BileWall
extends Node2D
## Pared que escupe bilis (tier 3): un orificio en la pared del túnel. Cada `interval` s se
## **hincha** `warning_time` s (aviso: bulto que crece y parpadea, más una línea tenue hacia donde
## va a escupir) y lanza un proyectil de bilis lento y en línea recta. El proyectil mata al
## jugador que toque y se disuelve al chocar con una pared (o al pasar `max_range`). Solo actúa
## con el orificio dentro de la vista. Colocarlo en la cara de la pared, mirando hacia el túnel.
## Placeholders con polígonos. Ver `docs/mecanicas/amenazas-alien.md`.

## Verde de la bilis (distinto del amarillo del ácido perseguidor). Solo visual.
const BILE_COLOR: Color = Color("5FCB3C")
## Núcleo claro del proyectil y del aviso. Solo visual.
const CORE_COLOR: Color = Color("D8FF9E")
## Borde rojo oscuro del proyectil (sigue leyéndose como peligro). Solo visual.
const OUTLINE_COLOR: Color = Color("B02828")
## Color de la carne del orificio. Solo visual.
const FLESH_COLOR: Color = Color("3A1220")
## Radio aproximado del cuerpo del jugador. Unidad: px.
const PLAYER_RADIUS: float = 9.0

@export_group("Disparo")
## Dirección del escupitajo (0 = derecha, 90 = abajo, 180 = izquierda). Unidad: °.
@export var angle: float = 0.0:
	set(value):
		angle = value
		queue_redraw()
## Velocidad del proyectil. Unidad: px/s.
@export var projectile_speed: float = 150.0
## Diámetro del proyectil. Unidad: px.
@export var bile_size: float = 14.0
## Distancia máxima que recorre el proyectil. Unidad: px.
@export var max_range: float = 420.0

@export_group("Tiempos")
## Tiempo entre escupitajos (desde el final del anterior aviso). Unidad: s.
@export var interval: float = 3.0
## Duración del aviso previo (el orificio se hincha). Unidad: s.
@export var warning_time: float = 0.7
## Espera antes del primer escupitajo, para desfasar varios. Unidad: s.
@export var initial_delay: float = 1.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"bile"

var _wait: float = 0.0
var _warn: float = -1.0
var _recoil: float = 0.0
# Cada proyectil: {"pos": Vector2 global, "dir": Vector2, "dist": float}
var _shots: Array[Dictionary] = []


func _ready() -> void:
	_wait = initial_delay
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_move_shots(delta)
	if not _in_view():
		_warn = -1.0
		_wait = initial_delay
		queue_redraw()
		return
	if _recoil > 0.0:
		_recoil = maxf(_recoil - delta, 0.0)
	if _warn >= 0.0:
		_warn += delta
		if _warn >= warning_time:
			_spit()
			_warn = -1.0
			_wait = interval
	else:
		_wait -= delta
		if _wait <= 0.0:
			_warn = 0.0
	queue_redraw()


## Borra los proyectiles y vuelve a esperar (al reiniciar la partida).
func reset() -> void:
	_shots.clear()
	_warn = -1.0
	_wait = initial_delay
	queue_redraw()


func _dir() -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(angle))


func _spit() -> void:
	_recoil = 0.25
	_shots.append({"pos": global_position + _dir() * 8.0, "dir": _dir(), "dist": 0.0})


func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(40.0).has_point(global_position)


func _move_shots(delta: float) -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var player: Player = null
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		player = node as Player
	var i: int = _shots.size() - 1
	while i >= 0:
		var shot: Dictionary = _shots[i]
		var from: Vector2 = shot["pos"]
		var step: float = projectile_speed * delta
		var to: Vector2 = from + (shot["dir"] as Vector2) * step
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 1)
		var hit: Dictionary = space.intersect_ray(query)
		shot["dist"] = float(shot["dist"]) + step
		shot["pos"] = to
		var dead: bool = not hit.is_empty() or float(shot["dist"]) >= max_range
		if player != null and player.is_alive():
			if to.distance_to(player.global_position) <= bile_size * 0.5 + PLAYER_RADIUS:
				player.die(cause)
				dead = true
		if dead:
			_shots.remove_at(i)
		i -= 1


func _draw() -> void:
	var dir: Vector2 = _dir()
	# Orificio: carne oscura con el borde rojo apagado.
	draw_circle(Vector2.ZERO, 7.0, FLESH_COLOR)
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, Color(BILE_COLOR, 0.55), 2.0)
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, dir * 60.0, Color(1, 1, 1, 0.4), 1.0)
		return
	if _warn >= 0.0:
		var k: float = _warn / maxf(warning_time, 0.001)
		var blink: float = 0.55 + 0.45 * sin(_warn * 30.0)
		var r: float = lerpf(7.0, 15.0, k)
		draw_circle(dir * 3.0, r, Color(BILE_COLOR, 0.45 + 0.4 * k))
		draw_circle(dir * 3.0, r * 0.5, Color(CORE_COLOR, blink * k))
		# Línea tenue con la dirección del escupitajo.
		draw_dashed_line(dir * 14.0, dir * 110.0, Color(BILE_COLOR, 0.35 * k), 2.0, 6.0)
	elif _recoil > 0.0:
		draw_circle(dir * 2.0, 6.0 + 6.0 * (_recoil / 0.25), Color(BILE_COLOR, 0.6))
	for shot: Dictionary in _shots:
		var at: Vector2 = to_local(shot["pos"])
		var back: Vector2 = -(shot["dir"] as Vector2)
		draw_line(at, at + back * 16.0, Color(BILE_COLOR, 0.5), bile_size * 0.6)
		draw_circle(at, bile_size * 0.5 + 1.5, OUTLINE_COLOR)
		draw_circle(at, bile_size * 0.5, BILE_COLOR)
		draw_circle(at, bile_size * 0.25, CORE_COLOR)
