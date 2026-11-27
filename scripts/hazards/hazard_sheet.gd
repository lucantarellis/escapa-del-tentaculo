class_name HazardSheet
extends RefCounted
## Hoja de cuadros de un peligro del espacio (`assets/sprites/hazards/<nombre>.png` + `.json` de
## Aseprite, y `<nombre>_emissive.png` si existe). Se carga una vez por nombre y se comparte entre
## las instancias. Los cuadros están en una grilla de izquierda a derecha y de arriba abajo. Ver
## `docs/arte/peligros-espacio.md`.

## Carpeta de las hojas. Estructural.
const SHEET_DIR: String = "res://assets/sprites/hazards/"

static var _cache: Dictionary = {}

## Textura de color (nearest).
var texture: Texture2D
## Textura emisiva (null si la hoja no tiene).
var emissive: Texture2D
## Tamaño de un cuadro. Unidad: px.
var frame_size: Vector2 = Vector2.ZERO
## Cuadros por fila de la hoja.
var columns: int = 1
## Cantidad de cuadros.
var frame_count: int = 0
## Duración de cada cuadro. Unidad: s.
var durations: PackedFloat32Array = PackedFloat32Array()
## Tags de la hoja: nombre (StringName) → Vector2i(primer cuadro, último cuadro).
var tags: Dictionary = {}


## Devuelve la hoja `sheet_name` (sin extensión), cargándola la primera vez.
static func get_sheet(sheet_name: String) -> HazardSheet:
	if _cache.has(sheet_name):
		return _cache[sheet_name]
	var base: String = SHEET_DIR + sheet_name
	var json: JSON = load(base + ".json") as JSON
	var data: Dictionary = json.data
	var frames: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
	var sheet: HazardSheet = HazardSheet.new()
	sheet.frame_size = Vector2(float(frames[0].frame.w), float(frames[0].frame.h))
	sheet.frame_count = frames.size()
	sheet.columns = maxi(1, roundi(float(data.meta.size.w) / sheet.frame_size.x))
	for frame: Dictionary in frames:
		sheet.durations.append(maxf(float(frame.duration) / 1000.0, 0.01))
	for tag: Dictionary in data.meta.frameTags:
		sheet.tags[StringName(tag.name)] = Vector2i(int(tag.from), int(tag.to))
	sheet.texture = load(base + ".png") as Texture2D
	if ResourceLoader.exists(base + "_emissive.png"):
		sheet.emissive = load(base + "_emissive.png") as Texture2D
	_cache[sheet_name] = sheet
	return sheet


## Rectángulo del cuadro `frame` dentro de la textura.
func region(frame: int) -> Rect2:
	var index: int = clampi(frame, 0, frame_count - 1)
	return Rect2(Vector2(float(index % columns), float(floori(float(index) / float(columns)))) * frame_size, frame_size)


## Primer cuadro del tag (global en la hoja).
func tag_first(tag: StringName) -> int:
	return (tags[tag] as Vector2i).x


## Cantidad de cuadros del tag.
func tag_length(tag: StringName) -> int:
	var range_: Vector2i = tags[tag]
	return range_.y - range_.x + 1


## Duración total del tag. Unidad: s.
func tag_duration(tag: StringName) -> float:
	var range_: Vector2i = tags[tag]
	var total: float = 0.0
	for i: int in range(range_.x, range_.y + 1):
		total += durations[i]
	return total
