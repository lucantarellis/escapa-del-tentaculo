@tool
class_name DebrisField
extends Area2D
## Campo de escombros del espacio: fragmentos letales que giran en círculo alrededor del origen
## del nodo. Hay que cruzar el anillo en el hueco entre dos fragmentos, o rodearlo. Un anillo
## tenue marca la órbita, así el patrón es visible y predecible (no hay aviso: no hace falta).
## Los fragmentos atraviesan todo (asteroides incluidos). Colocarlo alrededor de un tanque lo
## convierte en un premio con riesgo. Cada fragmento es un sprite (`debris_fragment`, 6 diseños de
## 36 cuadros: un giro completo cada 10°) que avanza de cuadro con su giro; el sprite no se rota.
## Ver `docs/arte/peligros-espacio.md` y `docs/mecanicas/obstaculos-espacio.md`.

## Hoja de los fragmentos (ver [HazardSheet]). Estructural.
const SHEET_NAME: String = "debris_fragment"
## Diseños de fragmento de la hoja (tags `frag1` a `frag6`). Estructural.
const DESIGNS: int = 6
## Cuadros de un giro completo de un fragmento (un cuadro cada 10°, en sentido antihorario).
## Estructural.
const SPIN_FRAMES: int = 36
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
var _chunks: Array[Sprite2D] = []
## Primer cuadro del diseño de cada fragmento en la hoja.
var _first_frames: PackedInt32Array = PackedInt32Array()
var _sheet: HazardSheet = null
var _shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_angle = start_angle
	_sheet = HazardSheet.get_sheet(SHEET_NAME)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i: int in chunk_count:
		var chunk: Sprite2D = Sprite2D.new()
		chunk.texture = _sheet.texture
		chunk.region_enabled = true
		add_child(chunk)
		_first_frames.append(_sheet.tag_first(StringName("frag%d" % (1 + randi() % DESIGNS))))
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
		_chunks[i].region_rect = _sheet.region(_first_frames[i] + _spin_frame(a * 2.0))
		_shapes[i].position = at


# Cuadro (0 a 35) que muestra el giro `radians` del fragmento. Los cuadros avanzan en sentido
# antihorario y el ángulo de Godot crece en sentido horario, por eso se invierte.
func _spin_frame(radians: float) -> int:
	return posmod(-roundi(rad_to_deg(radians) / (360.0 / float(SPIN_FRAMES))), SPIN_FRAMES)
