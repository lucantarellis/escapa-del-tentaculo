@tool
class_name DebrisField
extends Area2D
## Campo de escombros del espacio: fragmentos letales que giran en círculo alrededor del origen
## del nodo. Hay que cruzar el anillo en el hueco entre dos fragmentos, o rodearlo. Un anillo
## tenue marca la órbita, así el patrón es visible y predecible (no hay aviso: no hace falta).
## Los fragmentos atraviesan todo (asteroides incluidos). Colocarlo alrededor de un tanque lo
## convierte en un premio con riesgo. Placeholders con polígonos. Ver
## `docs/mecanicas/obstaculos-espacio.md`.

## Rojo letal de la paleta (fragmentos). Solo visual.
const CHUNK_COLOR: Color = Color("D83232")
## Color del anillo de la órbita. Solo visual.
const ORBIT_COLOR: Color = Color(1.0, 0.31, 0.25, 0.14)

@export_group("Órbita")
## Radio de la órbita. Unidad: px.
@export var orbit_radius: float = 70.0:
	set(value):
		orbit_radius = value
		queue_redraw()
## Cantidad de fragmentos, repartidos a la misma distancia entre sí.
@export_range(1, 12) var chunk_count: int = 5
## Velocidad de giro (positivo = horario, negativo = antihorario). Unidad: °/s.
@export var angular_speed: float = 55.0
## Ángulo inicial del primer fragmento (0 = a la derecha, 90 = abajo). Unidad: °.
@export var start_angle: float = 0.0

@export_group("Forma")
## Tamaño de cada fragmento. Unidad: px.
@export var chunk_size: float = 18.0
## Si es true, se dibuja el anillo tenue de la órbita.
@export var show_orbit: bool = true:
	set(value):
		show_orbit = value
		queue_redraw()

@export_group("Muerte")
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"debris_field"

var _angle: float = 0.0
var _chunks: Array[Polygon2D] = []
var _shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_angle = start_angle
	for i: int in chunk_count:
		var points: PackedVector2Array = PackedVector2Array()
		for k: int in 6:
			var a: float = TAU * float(k) / 6.0 + randf_range(-0.3, 0.3)
			points.append(Vector2(cos(a), sin(a)) * chunk_size * randf_range(0.38, 0.55))
		var chunk: Polygon2D = Polygon2D.new()
		chunk.color = CHUNK_COLOR
		chunk.polygon = points
		add_child(chunk)
		_chunks.append(chunk)
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = chunk_size * 0.45
		shape.shape = circle
		add_child(shape)
		_shapes.append(shape)
	_place_chunks()


func _draw() -> void:
	if show_orbit:
		draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 64, ORBIT_COLOR, 1.5)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_angle += angular_speed * delta
	_place_chunks()
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive():
			player.die(cause)
			return


# Coloca cada fragmento (y su forma de colisión) sobre la órbita.
func _place_chunks() -> void:
	for i: int in _chunks.size():
		var a: float = deg_to_rad(_angle + 360.0 * float(i) / float(_chunks.size()))
		var at: Vector2 = Vector2(cos(a), sin(a)) * orbit_radius
		_chunks[i].position = at
		_chunks[i].rotation = a * 2.0
		_shapes[i].position = at
