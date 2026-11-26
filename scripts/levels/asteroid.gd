@tool
class_name Asteroid
extends AnimatableBody2D
## Asteroide del espacio: roca de cuatro tamaños (chico, mediano, grande, gigante) con 10 variantes
## cada uno, que flota yendo y viniendo (`drift`) y, si es chico o mediano, gira (`spin_speed`).
## Es un cuerpo cinemático: el jugador parado encima se mueve con él. El origen del nodo es el
## centro del asteroide y el eje de giro. Ver `docs/mecanicas/tier-espacio.md` y
## `docs/arte/asteroides.md`.
##
## **El sprite no se rota**: el código lleva el ángulo acumulado y muestra el cuadro pre-renderizado
## más cercano (uno cada 5°, con el normal map ya girado, así la luz no gira con la roca). Solo la
## colisión rota, con el ángulo redondeado a 5° para que coincida con el dibujo. En el editor se ve
## quieto, en el cuadro 0.

## Tamaño del asteroide (forma base: chico 48×48, mediano 96×48, grande 120×72, gigante 144×96).
enum Size { SMALL, MEDIUM, LARGE, GIANT }

## Carpeta del arte: `asteroid_<tamaño>_<NN>.png`, `_normal.png`, `.json` y `asteroid_shapes.json`.
## Estructural.
const DIR: String = "res://assets/sprites/environment/asteroids/"
## Polígonos de colisión de cada asteroide (sin girar, origen en el centro). Estructural.
const SHAPES_FILE: String = DIR + "asteroid_shapes.json"
## Nombre de cada tamaño en los archivos, en el orden de [enum Size]. Estructural.
const SIZE_NAMES: Array[String] = ["small", "medium", "large", "giant"]
## Variantes por tamaño. Estructural.
const VARIANT_COUNT: int = 10
## Grados entre un cuadro del giro y el siguiente. Estructural. Unidad: °.
const SPIN_STEP: float = 5.0
## Orden de dibujo: detrás del jugador, como las paredes. Solo visual.
const DRAW_Z_INDEX: int = -1

@export_group("Forma")
## Tamaño. Los grandes y gigantes no giran (tienen un solo cuadro): con ellos `spin_speed` no se usa.
@export var size: Size = Size.SMALL:
	set(value):
		size = value
		_rebuild()
## Variante del tamaño (1–10). 0 = una al azar, estable para el mismo nombre y posición.
@export_range(0, 10, 1) var variant: int = 0:
	set(value):
		variant = value
		_rebuild()

@export_group("Movimiento")
## Desplazamiento máximo del vaivén respecto de su posición (ida y vuelta). Unidad: px.
@export var drift: Vector2 = Vector2(0.0, 10.0)
## Duración de un vaivén completo. Unidad: s.
@export var drift_period: float = 4.0
## Desfase del vaivén (para que no se muevan todos juntos). Unidad: s.
@export var drift_offset: float = 0.0
## Velocidad de giro (positivo = horario, 0 = sin giro). Solo chicos y medianos. Unidad: °/s.
@export var spin_speed: float = 0.0

## Polígonos por nombre de asteroide (de `asteroid_shapes.json`).
static var _shapes: Dictionary = {}
## Hojas ya cargadas por nombre: textura (color + normal), cantidad y tamaño de los cuadros.
static var _sheets: Dictionary = {}

var _sprite: Sprite2D
var _collision: CollisionPolygon2D
var _sheet: Dictionary = {}
var _origin: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _angle: float = 0.0
var _step: int = 0


func _ready() -> void:
	z_index = DRAW_Z_INDEX
	# Capa 1 `world`: sólido como las paredes (el jugador se para encima, el meteoro se rompe).
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	_rebuild()
	if Engine.is_editor_hint():
		return
	_origin = position
	_time = drift_offset


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if drift_period > 0.0:
		position = _origin + drift * sin(_time * TAU / drift_period)
	if not spins():
		return
	_angle += spin_speed * delta
	var step: int = roundi(_angle / SPIN_STEP)
	if step != _step:
		_step = step
		# Solo la colisión (el cuerpo) rota, en pasos de 5°.
		rotation = deg_to_rad(float(_step) * SPIN_STEP)


# El cuadro se elige con la rotación que tiene el cuerpo al dibujar (con `sync_to_physics` el
# cuerpo aplica la rotación nueva recién en el paso de física siguiente): así el dibujo coincide
# siempre con la colisión.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not spins():
		return
	_show_frame(roundi(rad_to_deg(global_rotation) / SPIN_STEP))


## true si este asteroide gira (es chico o mediano y tiene `spin_speed`).
func spins() -> bool:
	return not is_zero_approx(spin_speed) and int(_sheet.get("frames", 1)) > 1


## Nombre del arte que usa (por ejemplo `asteroid_small_03`), con la variante ya resuelta.
func get_art_name() -> String:
	return "asteroid_%s_%02d" % [SIZE_NAMES[size], _resolved_variant()]


## Rectángulo (coordenadas del padre) que el asteroide puede llegar a ocupar con el giro y el vaivén.
## Lo usa [CoinSpawner] para no poner monedas encima.
func get_reserved_rect() -> Rect2:
	var points: PackedVector2Array = _get_polygon()
	if points.is_empty():
		return Rect2(position - Vector2.ONE * 24.0, Vector2.ONE * 48.0)
	var rect: Rect2
	if spins():
		var radius: float = 0.0
		for point: Vector2 in points:
			radius = maxf(radius, point.length())
		rect = Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	else:
		rect = Rect2(points[0], Vector2.ZERO)
		for point: Vector2 in points:
			rect = rect.expand(point)
	var center: Vector2 = _origin if is_node_ready() and not Engine.is_editor_hint() else position
	rect.position += center
	return rect.grow_individual(absf(drift.x), absf(drift.y), absf(drift.x), absf(drift.y))


func _resolved_variant() -> int:
	if variant >= 1:
		return mini(variant, VARIANT_COUNT)
	return posmod(hash([String(name), position.round()]), VARIANT_COUNT) + 1


# Arma (o rearma) el sprite y la colisión según el tamaño y la variante.
func _rebuild() -> void:
	if not is_node_ready():
		return
	var art: String = get_art_name()
	_sheet = _get_sheet(art)
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite"
		_sprite.region_enabled = true
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_sprite)
	if _collision == null:
		_collision = CollisionPolygon2D.new()
		_collision.name = "Collision"
		add_child(_collision)
	_sprite.texture = _sheet.get("texture")
	_collision.polygon = _get_polygon()
	rotation = 0.0
	_show_frame(0)


# Muestra el cuadro del paso [param step] de giro (paso × 5°, positivo = horario) y contrarrota el
# sprite para que el dibujo no rote con el cuerpo. Los cuadros están girados en sentido antihorario
# (cuadro N = N × 5°): por eso se recorren al revés.
func _show_frame(step: int) -> void:
	if _sprite == null:
		return
	var frames: int = int(_sheet.get("frames", 1))
	var frame: int = posmod(-step, frames) if frames > 1 else 0
	_sprite.global_rotation = 0.0
	var frame_size: Vector2 = _sheet.get("frame_size", Vector2.ZERO)
	_sprite.region_rect = Rect2(Vector2(float(frame) * frame_size.x, 0.0), frame_size)


func _get_polygon() -> PackedVector2Array:
	if _shapes.is_empty():
		var data: Variant = (load(SHAPES_FILE) as JSON).data
		if data is Dictionary:
			_shapes = data
	var entry: Dictionary = _shapes.get(get_art_name(), {})
	var points: PackedVector2Array = PackedVector2Array()
	for p: Array in entry.get("polygon", []):
		points.append(Vector2(float(p[0]), float(p[1])))
	return points


# Carga (una vez) la hoja de un asteroide: color con relieve (normal map), cantidad de cuadros
# (de su JSON de Aseprite; sin JSON, un solo cuadro) y tamaño de cada uno.
static func _get_sheet(art: String) -> Dictionary:
	if _sheets.has(art):
		return _sheets[art]
	var base: String = DIR + art
	var diffuse: Texture2D = load(base + ".png")
	var texture: CanvasTexture = CanvasTexture.new()
	texture.diffuse_texture = diffuse
	if ResourceLoader.exists(base + "_normal.png"):
		texture.normal_texture = load(base + "_normal.png")
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames: int = 1
	var frame_size: Vector2 = diffuse.get_size()
	if ResourceLoader.exists(base + ".json"):
		var data: Dictionary = (load(base + ".json") as JSON).data
		var list: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
		frames = list.size()
		frame_size = Vector2(float(list[0].frame.w), float(list[0].frame.h))
	var sheet: Dictionary = {"texture": texture, "frames": frames, "frame_size": frame_size}
	_sheets[art] = sheet
	return sheet
