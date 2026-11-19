@tool
class_name PlatformSkin
extends Node2D
## Dibuja una plataforma de la nave con módulos de sprites: tapa izquierda (`L`), centros al azar
## (`C0`, `C1`, …) y tapa derecha (`R`), de 10 px cada uno. Ver `docs/arte/plataformas-nave.md`.
##
## Lo crea y maneja [Platform]: elige la hoja según el tipo y pide qué tag mostrar en cada estado
## ([method play]). Todos los módulos muestran el mismo cuadro (el dibujo de cada módulo ya es
## distinto). Un solo nodo dibuja todo; el hijo `Emissive` dibuja los píxeles que emiten luz con
## material sin sombreado. Las texturas son `CanvasTexture` (color + relieve) y se comparten entre
## instancias. Los tiempos de cada cuadro salen del JSON de Aseprite de cada hoja.

## Un tag que no se repite llegó a su último cuadro (queda mostrándolo).
signal finished(tag: StringName)

## Carpeta de las hojas: `<hoja>.png`, `<hoja>_normal.png`, `<hoja>_emissive.png`, `<hoja>.json`.
## Estructural.
const SHEET_DIR: String = "res://assets/sprites/environment/platforms/"
## Ancho de un módulo de plataforma. Estructural. Unidad: px.
const MODULE_WIDTH: float = 10.0
## Mínimo de módulos: tapa izquierda + tapa derecha. Estructural.
const MIN_MODULES: int = 2
## Hoja de los propulsores de las plataformas móviles (6×9 px por cuadro). Estructural.
const THRUSTER_SHEET: String = "platform_thruster"
## Distancia del centro de cada propulsor a la punta de la plataforma. Solo visual. Unidad: px.
const THRUSTER_INSET: float = 10.0

## Hojas ya cargadas, por nombre (compartidas entre instancias).
static var _sheets: Dictionary = {}

var _sheet: Dictionary = {}
var _thruster: Dictionary = {}
var _columns: PackedInt32Array = PackedInt32Array()
var _width: float = 0.0
var _center_y: float = 0.0
var _body_bottom: float = 0.0
var _tag: StringName = &""
var _from: int = 0
var _to: int = 0
var _loop: bool = false
var _done: bool = false
var _frame: int = 0
var _elapsed: float = 0.0
var _thrusters: bool = false
var _thruster_frame: int = 0
var _thruster_elapsed: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _emissive: Node2D = null


## Arma la plataforma: hoja, ancho del bloque, alto de la colisión, desplazamiento vertical del
## dibujo (`beam_top`: filas transparentes arriba de la viga en la hoja), semilla (centros y cuadro
## inicial estables) y si lleva propulsores.
func setup(sheet_name: String, width: float, body_height: float, beam_top: float, seed_value: int, with_thrusters: bool) -> void:
	_sheet = _get_sheet(sheet_name)
	_rng.seed = seed_value
	var modules: int = maxi(MIN_MODULES, roundi(width / MODULE_WIDTH))
	_width = modules * MODULE_WIDTH
	var frame_h: float = _sheet.frame_h
	# El borde de arriba de la viga coincide con el de la colisión.
	_center_y = -body_height * 0.5 - beam_top + frame_h * 0.5
	_body_bottom = body_height * 0.5
	var centers: int = (_sheet.modules as int) - 2
	_columns.resize(modules)
	var last: int = -1
	for i: int in modules:
		if i == 0:
			_columns[i] = 0
		elif i == modules - 1:
			_columns[i] = centers + 1
		else:
			var column: int = 1 + _rng.randi() % centers
			if column == last and centers > 1:
				column = 1 + (column % centers)
			_columns[i] = column
			last = column
	_thrusters = with_thrusters
	if _thrusters:
		_thruster = _get_sheet(THRUSTER_SHEET)
		_thruster_frame = _rng.randi() % (_thruster.durations as PackedFloat32Array).size()
	_ensure_emissive()
	_update_processing()
	_redraw()


## Muestra un tag de la hoja. `loop`: repetirlo; si no, al final emite [signal finished] y queda
## en el último cuadro. `random_start`: arrancar en un cuadro al azar del tag (para que las
## plataformas iguales no se muevan al unísono).
func play(tag: StringName, loop: bool = false, random_start: bool = false) -> void:
	var tags: Dictionary = _sheet.get("tags", {})
	if not tags.has(tag):
		push_warning("PlatformSkin: la hoja no tiene el tag '%s'." % tag)
		return
	var range_: Vector2i = tags[tag]
	_tag = tag
	_from = range_.x
	_to = range_.y
	_loop = loop
	_done = false
	_elapsed = 0.0
	_frame = _from + (_rng.randi() % (_to - _from + 1) if random_start else 0)
	_update_processing()
	_redraw()


## Tag que se está mostrando.
func get_tag() -> StringName:
	return _tag


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var changed: bool = false
	var finished_tag: StringName = &""
	if _to > _from and not _done:
		var durations: PackedFloat32Array = _sheet.durations
		_elapsed += delta
		while _elapsed >= durations[_frame]:
			_elapsed -= durations[_frame]
			changed = true
			if _frame < _to:
				_frame += 1
			elif _loop:
				_frame = _from
			else:
				_done = true
				_elapsed = 0.0
				finished_tag = _tag
				break
	if _thrusters:
		var t_durations: PackedFloat32Array = _thruster.durations
		_thruster_elapsed += delta
		while _thruster_elapsed >= t_durations[_thruster_frame]:
			_thruster_elapsed -= t_durations[_thruster_frame]
			_thruster_frame = (_thruster_frame + 1) % t_durations.size()
			changed = true
	if changed:
		_redraw()
	if finished_tag != &"":
		_update_processing()
		finished.emit(finished_tag)


func _draw() -> void:
	if _sheet.is_empty():
		return
	_draw_modules(self, _sheet.color)
	if _thrusters:
		_draw_thrusters(self, _thruster.color)


func _draw_emissive() -> void:
	if _sheet.is_empty():
		return
	if _sheet.emissive != null:
		_draw_modules(_emissive, _sheet.emissive)
	if _thrusters and _thruster.emissive != null:
		_draw_thrusters(_emissive, _thruster.emissive)


func _draw_modules(canvas: CanvasItem, texture: Texture2D) -> void:
	var frame_h: float = _sheet.frame_h
	var top: float = _center_y - frame_h * 0.5
	for i: int in _columns.size():
		var region: Rect2 = Rect2(_columns[i] * MODULE_WIDTH, _frame * frame_h, MODULE_WIDTH, frame_h)
		var dest: Rect2 = Rect2(-_width * 0.5 + i * MODULE_WIDTH, top, MODULE_WIDTH, frame_h)
		canvas.draw_texture_rect_region(texture, dest, region)


# Dos propulsores pegados al borde de abajo, a THRUSTER_INSET de cada punta.
func _draw_thrusters(canvas: CanvasItem, texture: Texture2D) -> void:
	var w: float = _thruster.frame_w
	var h: float = _thruster.frame_h
	var region: Rect2 = Rect2(0.0, _thruster_frame * h, w, h)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (_width * 0.5 - THRUSTER_INSET) - w * 0.5
		canvas.draw_texture_rect_region(texture, Rect2(x, _body_bottom, w, h), region)


func _redraw() -> void:
	queue_redraw()
	if _emissive != null:
		_emissive.queue_redraw()


func _update_processing() -> void:
	set_process(not Engine.is_editor_hint() and (_thrusters or (_to > _from and not _done)))


# Capa de lo que emite luz: hija, dibujada encima, sin sombreado.
func _ensure_emissive() -> void:
	var needed: bool = _sheet.emissive != null or (_thrusters and _thruster.emissive != null)
	if not needed:
		if _emissive != null:
			_emissive.queue_free()
			_emissive = null
		return
	if _emissive != null:
		return
	_emissive = Node2D.new()
	_emissive.name = "Emissive"
	var material_unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	material_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_emissive.material = material_unshaded
	_emissive.draw.connect(_draw_emissive)
	add_child(_emissive)


# Carga (una vez) la hoja: textura de color con relieve, emisiva si existe, alto y ancho del
# cuadro, cantidad de módulos, duración de cada cuadro (s) y tags (desde el JSON de Aseprite).
static func _get_sheet(sheet_name: String) -> Dictionary:
	if _sheets.has(sheet_name):
		return _sheets[sheet_name]
	var base: String = SHEET_DIR + sheet_name
	var json: JSON = load(base + ".json") as JSON
	var data: Dictionary = json.data
	var frames: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
	var first: Dictionary = frames[0].frame
	var durations: PackedFloat32Array = PackedFloat32Array()
	for frame: Dictionary in frames:
		durations.append(maxf(float(frame.duration) / 1000.0, 0.01))
	var tags: Dictionary = {}
	for tag: Dictionary in data.meta.frameTags:
		tags[StringName(tag.name)] = Vector2i(int(tag.from), int(tag.to))
	var color: CanvasTexture = CanvasTexture.new()
	color.diffuse_texture = load(base + ".png")
	if ResourceLoader.exists(base + "_normal.png"):
		color.normal_texture = load(base + "_normal.png")
	color.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var emissive: Texture2D = load(base + "_emissive.png") if ResourceLoader.exists(base + "_emissive.png") else null
	var module_w: float = MODULE_WIDTH if sheet_name != THRUSTER_SHEET else float(first.w)
	var sheet: Dictionary = {
		"color": color,
		"emissive": emissive,
		"frame_w": float(first.w),
		"frame_h": float(first.h),
		"modules": roundi(float(first.w) / module_w),
		"durations": durations,
		"tags": tags,
	}
	_sheets[sheet_name] = sheet
	return sheet
