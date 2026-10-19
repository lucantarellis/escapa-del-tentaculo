@tool
class_name CiliaStrip
extends Node2D
## Hilera de cilios del tier 3: filamentos que crecen de la pared del túnel. Ciclo: **reposo**
## (pegados a la pared, rosados e inofensivos) → **aviso** (`warning_time`: tiemblan y se ponen
## rojizos) → **activos** (`active_time`: se estiran hacia el túnel, rojos y letales) → reposo. Cada
## filamento arranca con un retraso (`wave_delay`) respecto del anterior, así la ola recorre la hilera
## y se puede aprender el ritmo. Solo actúa con la hilera a la vista. Placeholders con polígonos.
## Ver `docs/mecanicas/amenazas-alien.md`.

## Rojo letal de la paleta (filamentos activos). Solo visual.
const ACTIVE_COLOR: Color = Color("D83232")
## Rosa carne del reposo. Solo visual.
const REST_COLOR: Color = Color("B46A7C")
## Radio aproximado del cuerpo del jugador. Unidad: px.
const PLAYER_RADIUS: float = 9.0
## Fracción de la extensión desde la que el filamento mata. Solo gameplay.
const LETHAL_EXTENSION: float = 0.55

@export_group("Hilera")
## Dirección hacia la que crecen (0 = derecha, 180 = izquierda: hacia adentro del túnel). Unidad: °.
@export var angle: float = 0.0:
	set(value):
		angle = value
		queue_redraw()
## Largo de la hilera a lo largo de la pared (siempre hacia abajo desde el origen). Unidad: px.
@export var strip_length: float = 90.0:
	set(value):
		strip_length = value
		queue_redraw()
## Cantidad de filamentos.
@export_range(2, 12) var count: int = 6:
	set(value):
		count = value
		queue_redraw()
## Largo de cada filamento extendido. Unidad: px.
@export var filament_length: float = 38.0

@export_group("Tiempos")
## Reposo entre ciclos. Unidad: s.
@export var rest_time: float = 1.6
## Aviso previo. Unidad: s.
@export var warning_time: float = 0.7
## Tiempo activo (letal). Unidad: s.
@export var active_time: float = 1.0
## Retraso entre un filamento y el siguiente (la ola). Unidad: s.
@export var wave_delay: float = 0.1
## Desfase inicial para no sincronizar varias hileras. Unidad: s.
@export var initial_delay: float = 0.0

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"cilia"

var _clock: float = 0.0


func _ready() -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _in_view():
		_clock = 0.0
		return
	_clock += delta
	queue_redraw()
	var player: Player = null
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		player = node as Player
	if player == null or not player.is_alive():
		return
	for i: int in count:
		if _extension(i) < LETHAL_EXTENSION:
			continue
		var base: Vector2 = global_position + _base(i)
		var tip: Vector2 = base + _dir() * filament_length * _extension(i)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, base, tip)
		if closest.distance_to(player.global_position) <= 3.0 + PLAYER_RADIUS:
			player.die(cause)
			return


## Vuelve al reposo (al reiniciar la partida).
func reset() -> void:
	_clock = 0.0
	queue_redraw()


func _dir() -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(angle))


# Posición local de la base del filamento [param i] (repartidos a lo largo de la pared).
func _base(i: int) -> Vector2:
	return Vector2.DOWN * strip_length * (float(i) / float(maxi(count - 1, 1)))


func _cycle() -> float:
	return rest_time + warning_time + active_time


# Fase del filamento [param i] en el ciclo (s desde el inicio del reposo).
func _phase(i: int) -> float:
	return fposmod(_clock - initial_delay - float(i) * wave_delay, _cycle())


# Extensión 0–1 del filamento [param i] (0 pegado a la pared, 1 estirado).
func _extension(i: int) -> float:
	var p: float = _phase(i)
	if p < rest_time:
		return 0.0
	if p < rest_time + warning_time:
		return 0.0
	var a: float = p - rest_time - warning_time
	return smoothstep(0.0, 0.18, a) * (1.0 - smoothstep(active_time - 0.2, active_time, a))


func _warning(i: int) -> float:
	var p: float = _phase(i)
	if p >= rest_time and p < rest_time + warning_time:
		return (p - rest_time) / maxf(warning_time, 0.001)
	return 0.0


func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	return camera.get_visible_rect().grow(40.0).has_point(global_position + _base(count / 2))


func _draw() -> void:
	var dir: Vector2 = _dir()
	var side: Vector2 = dir.orthogonal()
	for i: int in count:
		var base: Vector2 = _base(i)
		var ext: float = _extension(i) if not Engine.is_editor_hint() else 1.0
		var warn: float = _warning(i) if not Engine.is_editor_hint() else 0.0
		var rest_len: float = filament_length * 0.28
		var length: float = lerpf(rest_len, filament_length, ext)
		var col: Color = REST_COLOR.lerp(ACTIVE_COLOR, maxf(ext, warn * 0.8))
		var shiver: float = sin(_clock * 60.0 + float(i)) * 2.5 * warn
		var wob: float = sin(_clock * 4.0 + float(i) * 0.9) * 2.0
		# Filamento en tres tramos con un poco de ondulación; reposo = inclinado y corto.
		var lean: Vector2 = side * (6.0 if ext < 0.05 else 0.0)
		var p0: Vector2 = base
		var p1: Vector2 = base + dir * length * 0.4 + side * (wob + shiver) * 0.5 + lean * 0.5
		var p2: Vector2 = base + dir * length * 0.75 + side * (wob + shiver) + lean
		var p3: Vector2 = base + dir * length + side * (wob * 1.4 + shiver) + lean
		draw_polyline(PackedVector2Array([p0, p1, p2, p3]), col, 4.0 - 1.5 * float(ext < 0.05) , true)
		draw_circle(p3, 2.5 if ext > 0.05 else 2.0, col.lightened(0.25))
