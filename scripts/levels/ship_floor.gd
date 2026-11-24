@tool
class_name ShipFloor
extends Node2D
## Piso de los segmentos de inicio en vista 3/4 (cara superior de chapa + frente de la viga), con
## los módulos de 20×27 px de `floor_ship`. Ver `docs/arte/piso-y-escotilla.md`.
##
## Es solo visual: la colisión sigue siendo la banda de 360×20 del `Floor` (StaticBody2D) del
## segmento. El origen de este nodo es el borde INFERIOR del piso; los módulos van en y = −27,
## así la cara superior empieza 7 px por encima de la línea de colisión (y = −20) y el astronauta
## pisa la mitad de la chapa. La elección de módulos usa `floor_seed`, así no cambia entre partidas.

## Hoja de módulos (color + relieve) y capa emisiva (rojo tenue de las rejillas). Estructural.
const SHEET: String = "res://assets/sprites/environment/floor_ship/floor_ship.png"
const SHEET_NORMAL: String = "res://assets/sprites/environment/floor_ship/floor_ship_normal.png"
const SHEET_EMISSIVE: String = "res://assets/sprites/environment/floor_ship/floor_ship_emissive.png"
## Tamaño de un módulo. Estructural. Unidad: px.
const MODULE_SIZE: Vector2 = Vector2(20.0, 27.0)
## Columna de cada módulo en la hoja (ver `floor_ship_layout.json`). Estructural.
const PLAIN_A: int = 0
const PLAIN_B: int = 1
const RIVET: int = 2
const JOINT: int = 3
const VENT: int = 4
const DENT: int = 5
const HAZARD: int = 6
const CABLE: int = 7
## Semiancho del marco de la escotilla: los módulos de peligro van justo a sus lados. Estructural.
## Unidad: px.
const HATCH_HALF_WIDTH: float = 64.0
## Fila de la hoja (0 = arriba) que se estira para alargar el frente del piso: es la franja oscura
## lisa, debajo de todos los detalles (juntas, caño). Estructural.
const STRETCH_ROW: int = 24

## Ancho del piso. Unidad: px.
@export var width: float = 360.0:
	set(value):
		width = value
		_rebuild()
## X del centro de la escotilla (franjas de peligro a sus lados). Negativo = sin escotilla.
## Unidad: px.
@export var hatch_x: float = 180.0:
	set(value):
		hatch_x = value
		_rebuild()
## Px extra de alto del frente del piso, hacia abajo (la cara superior no cambia). Sirve para que
## el piso llegue hasta el borde de la pantalla sin repetir módulos. Unidad: px.
@export_range(0.0, 200.0, 1.0) var extra_depth: float = 0.0:
	set(value):
		extra_depth = value
		_rebuild()
## Semilla de la elección de módulos: cambiarla re-sortea el piso de este segmento.
@export var floor_seed: int = 1:
	set(value):
		floor_seed = value
		_rebuild()

static var _texture: CanvasTexture
static var _emissive_texture: Texture2D

var _columns: PackedInt32Array = PackedInt32Array()
var _emissive: Node2D


func _ready() -> void:
	_emissive = Node2D.new()
	_emissive.name = "Emissive"
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_emissive.material = unshaded
	_emissive.draw.connect(_draw_emissive)
	add_child(_emissive)
	_rebuild()


## Columnas de la hoja elegidas para cada módulo, de izquierda a derecha.
func get_columns() -> PackedInt32Array:
	return _columns


func _rebuild() -> void:
	if not is_node_ready():
		return
	var count: int = maxi(1, roundi(width / MODULE_SIZE.x))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = floor_seed
	_columns.resize(count)
	_columns.fill(-1)
	# Franjas de peligro a los lados de la escotilla.
	if hatch_x >= 0.0:
		for x: float in [hatch_x - HATCH_HALF_WIDTH, hatch_x + HATCH_HALF_WIDTH]:
			var i: int = floori(x / MODULE_SIZE.x)
			if i >= 0 and i < count:
				_columns[i] = HAZARD
	# Un tramo de caño de 2 o 3 módulos, en un lugar libre.
	var run: int = rng.randi_range(2, 3)
	for attempt: int in 12:
		var start: int = rng.randi_range(0, count - run)
		var free: bool = true
		for k: int in run:
			if _columns[start + k] != -1:
				free = false
		if free:
			for k: int in run:
				_columns[start + k] = CABLE
			break
	# Juntas cada 3 a 5 módulos y relleno con algún detalle.
	var next_joint: int = rng.randi_range(2, 4)
	for i: int in count:
		if _columns[i] != -1:
			continue
		if i == next_joint:
			_columns[i] = JOINT
			next_joint = i + rng.randi_range(3, 5)
			continue
		if i > next_joint:
			next_joint = i + rng.randi_range(3, 5)
		var roll: float = rng.randf()
		if roll < 0.08:
			_columns[i] = RIVET
		elif roll < 0.14:
			_columns[i] = VENT
		elif roll < 0.19:
			_columns[i] = DENT
		else:
			_columns[i] = PLAIN_A if rng.randf() < 0.55 else PLAIN_B
	queue_redraw()
	if _emissive != null:
		_emissive.queue_redraw()


func _draw() -> void:
	_draw_modules(self, _get_texture())


func _draw_emissive() -> void:
	if _emissive_texture == null and ResourceLoader.exists(SHEET_EMISSIVE):
		_emissive_texture = load(SHEET_EMISSIVE)
	if _emissive_texture != null:
		_draw_modules(_emissive, _emissive_texture)


func _draw_modules(canvas: CanvasItem, texture: Texture2D) -> void:
	var top: float = -MODULE_SIZE.y - extra_depth
	var stretch_end: float = STRETCH_ROW + 1.0
	for i: int in _columns.size():
		var x: float = i * MODULE_SIZE.x
		var column_x: float = _columns[i] * MODULE_SIZE.x
		# Del borde superior hasta la fila de estiramiento (incluida).
		canvas.draw_texture_rect_region(texture, Rect2(x, top, MODULE_SIZE.x, stretch_end), Rect2(column_x, 0.0, MODULE_SIZE.x, stretch_end))
		# Franja estirada: la fila de estiramiento repetida `extra_depth` px.
		if extra_depth > 0.0:
			canvas.draw_texture_rect_region(texture, Rect2(x, top + stretch_end, MODULE_SIZE.x, extra_depth), Rect2(column_x, STRETCH_ROW, MODULE_SIZE.x, 1.0))
		# Resto del módulo (la última fila negra incluida).
		var rest: float = MODULE_SIZE.y - stretch_end
		canvas.draw_texture_rect_region(texture, Rect2(x, top + stretch_end + extra_depth, MODULE_SIZE.x, rest), Rect2(column_x, stretch_end, MODULE_SIZE.x, rest))


static func _get_texture() -> CanvasTexture:
	if _texture == null:
		_texture = CanvasTexture.new()
		_texture.diffuse_texture = load(SHEET)
		if ResourceLoader.exists(SHEET_NORMAL):
			_texture.normal_texture = load(SHEET_NORMAL)
		_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return _texture
