@tool
class_name SheetSprite
extends Sprite2D
## Sprite que reproduce los tags de una hoja exportada por Aseprite (PNG + JSON), respetando la
## duración de cada cuadro. Sirve para animaciones con tiempos distintos por cuadro (golpes y
## ruptura de la escotilla, rotura del ventanal) y para texturas con relieve (`CanvasTexture`), que
## un `AnimatedSprite2D` con `AtlasTexture` no garantiza.
##
## Uso: asignar la textura (o [method set_sheet_textures]) y [method load_sheet] con la ruta del
## JSON; después [method play]. Los `followers` (otros `Sprite2D` con hojas del mismo tamaño, por
## ejemplo la capa emisiva) copian el cuadro en cada cambio. En el editor no avanza.

## Un tag que no se repite terminó (queda mostrando su último cuadro).
signal finished(tag: StringName)

## Sprites que muestran siempre el mismo cuadro que este (capas emisivas, resplandor).
var followers: Array[Sprite2D] = []

## Hojas ya leídas, por ruta del JSON: rectángulos y duraciones de cada cuadro, y tags.
static var _sheets: Dictionary = {}

var _sheet: Dictionary = {}
var _tag: StringName = &""
var _from: int = 0
var _to: int = 0
var _loop: bool = false
var _done: bool = true
var _frame_index: int = 0
var _elapsed: float = 0.0


## Lee la hoja (cuadros, duraciones y tags) desde el JSON de Aseprite y activa la región.
func load_sheet(json_path: String) -> void:
	_sheet = get_sheet(json_path)
	region_enabled = true
	for follower: Sprite2D in followers:
		follower.region_enabled = true
	_show_frame(0)


## Arma la textura con relieve (difusa + normal opcional) y la asigna. Devuelve la textura.
func set_sheet_textures(diffuse_path: String, normal_path: String = "") -> Texture2D:
	var canvas: CanvasTexture = CanvasTexture.new()
	canvas.diffuse_texture = load(diffuse_path)
	if normal_path != "" and ResourceLoader.exists(normal_path):
		canvas.normal_texture = load(normal_path)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = canvas
	return canvas


## Reproduce un tag. `loop`: repetirlo; si no, al terminar emite [signal finished].
## `random_start`: arrancar en un cuadro al azar del tag.
func play(tag: StringName, loop: bool = false, random_start: bool = false) -> void:
	var tags: Dictionary = _sheet.get("tags", {})
	if not tags.has(tag):
		push_warning("SheetSprite '%s': la hoja no tiene el tag '%s'." % [name, tag])
		return
	var range_: Vector2i = tags[tag]
	_tag = tag
	_from = range_.x
	_to = range_.y
	_loop = loop
	_done = false
	_elapsed = 0.0
	_show_frame(_from + (randi() % (_to - _from + 1) if random_start else 0))
	set_process(not Engine.is_editor_hint() and (_to > _from or not _loop))


## Tag que se está mostrando.
func get_tag() -> StringName:
	return _tag


## Duración total de un tag (s). 0 si no existe.
func get_tag_duration(tag: StringName) -> float:
	var tags: Dictionary = _sheet.get("tags", {})
	if not tags.has(tag):
		return 0.0
	var range_: Vector2i = tags[tag]
	var total: float = 0.0
	var durations: PackedFloat32Array = _sheet.durations
	for i: int in range(range_.x, range_.y + 1):
		total += durations[i]
	return total


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _done or _sheet.is_empty():
		return
	var durations: PackedFloat32Array = _sheet.durations
	_elapsed += delta
	while _elapsed >= durations[_frame_index]:
		_elapsed -= durations[_frame_index]
		if _frame_index < _to:
			_show_frame(_frame_index + 1)
		elif _loop:
			_show_frame(_from)
		else:
			_done = true
			set_process(false)
			finished.emit(_tag)
			return


func _show_frame(index: int) -> void:
	_frame_index = index
	var rects: Array = _sheet.get("rects", [])
	if index < 0 or index >= rects.size():
		return
	region_rect = rects[index]
	for follower: Sprite2D in followers:
		follower.region_rect = region_rect


## Hoja leída del JSON de Aseprite: `rects` (Rect2 de cada cuadro), `durations` (s) y `tags`
## (StringName → Vector2i(desde, hasta)). Se lee una sola vez por ruta.
static func get_sheet(json_path: String) -> Dictionary:
	if _sheets.has(json_path):
		return _sheets[json_path]
	var data: Dictionary = (load(json_path) as JSON).data
	var frames: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
	var rects: Array[Rect2] = []
	var durations: PackedFloat32Array = PackedFloat32Array()
	for frame: Dictionary in frames:
		var r: Dictionary = frame.frame
		rects.append(Rect2(float(r.x), float(r.y), float(r.w), float(r.h)))
		durations.append(maxf(float(frame.duration) / 1000.0, 0.01))
	var tags: Dictionary = {}
	for tag: Dictionary in data.meta.frameTags:
		tags[StringName(tag.name)] = Vector2i(int(tag.from), int(tag.to))
	var sheet: Dictionary = {"rects": rects, "durations": durations, "tags": tags}
	_sheets[json_path] = sheet
	return sheet
