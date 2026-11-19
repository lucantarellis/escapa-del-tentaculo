class_name ShipBackground
extends Node2D
## Fondo de la nave: un pozo vertical en tres capas (lejana, media, cercana) que suben con la
## cámara a distinta velocidad. Ver `docs/arte/fondo-nave.md`.
##
## Vive dentro de [LevelBackground] (capa de pantalla −10, detrás del mundo, fuera del alcance del
## `CanvasModulate` del mundo), así que el desplazamiento se calcula a mano desde la Y de la
## cámara, igual que las estrellas. Cada capa tiene 3 tramos de 360×320 apilados; cuando uno sale
## por abajo, se reusa arriba con otro tramo al azar de la capa (sin repetir el de al lado), así el
## fondo no se corta con ningún largo de nivel. Encima de cada capa: su emisivo (sin niebla ni
## desenfoque) y los resplandores de `bg_ship_lights.json`, con la intensidad de cada cuadro
## tomada de los píxeles emisivos del arte (balizas que giran, fuegos, chispas).

## Carpeta de los tramos: `<tramo>.png`, `<tramo>_emissive.png`, `<tramo>.json`. Estructural.
const DIR: String = "res://assets/sprites/environment/background_ship/"
## Lista de tramos por capa y puntos de luz. Estructural.
const LIGHTS_FILE: String = DIR + "bg_ship_lights.json"
## Shader de desenfoque y niebla por capa. Estructural.
const LAYER_SHADER: String = "res://shaders/background_layer.gdshader"
## Tamaño de un tramo. Estructural. Unidad: px.
const TILE_SIZE: Vector2 = Vector2(360.0, 320.0)
## Alto de la pantalla lógica. Estructural. Unidad: px.
const VIEW_HEIGHT: float = 640.0
## Tramos visibles a la vez por capa (dos pantallas de 320 + uno que entra). Estructural.
const SLOTS: int = 3
## Capas, de atrás hacia adelante. Estructural.
const LAYER_NAMES: Array[String] = ["far", "mid", "near"]
## Radio alrededor de cada punto de luz donde se mide el brillo del emisivo. Estructural. Unidad: px.
const LIGHT_SAMPLE_RADIUS: int = 7

## Ajustes (velocidades, desenfoque, niebla, resplandores). Vacío = valores por defecto.
@export var config: ShipBackgroundConfig

## Tramos ya cargados, por nombre: texturas, cantidad y duración de cuadros, luces.
static var _tiles: Dictionary = {}

var _layers: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time: float = 0.0
var _glow_texture: Texture2D
var _tween: Tween


func _ready() -> void:
	if config == null:
		config = ShipBackgroundConfig.new()
	_rng.randomize()
	_glow_texture = _make_glow_texture()
	var lights_data: Dictionary = (load(LIGHTS_FILE) as JSON).data
	var shader: Shader = load(LAYER_SHADER)
	for layer_name: String in LAYER_NAMES:
		var tile_names: Array[String] = []
		for tile_name: String in lights_data:
			if str(lights_data[tile_name].layer) == layer_name:
				tile_names.append(tile_name)
		tile_names.sort()
		for tile_name: String in tile_names:
			_load_tile(tile_name, lights_data[tile_name].lights)
		_layers.append(_build_layer(layer_name, tile_names, shader))
	_update_layers()


func _process(delta: float) -> void:
	_time += delta
	_update_layers()


## Muestra u oculta el fondo con un fundido de [param fade] s (0 = ya).
func set_shown(shown: bool, fade: float) -> void:
	if _tween != null:
		_tween.kill()
	var target: float = 1.0 if shown else 0.0
	if shown:
		visible = true
		set_process(true)
	if fade <= 0.0:
		modulate.a = target
		_on_fade_done(shown)
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", target, fade)
	_tween.tween_callback(_on_fade_done.bind(shown))


func _on_fade_done(shown: bool) -> void:
	visible = shown
	set_process(shown)


func _build_layer(layer_name: String, tile_names: Array[String], shader: Shader) -> Dictionary:
	var scroll: float = config.get(layer_name + "_scroll")
	var blur: float = config.get(layer_name + "_blur")
	var fog: float = config.get(layer_name + "_fog")
	var root: Node2D = Node2D.new()
	root.name = layer_name.capitalize()
	add_child(root)
	var layer_material: ShaderMaterial = ShaderMaterial.new()
	layer_material.shader = shader
	layer_material.set_shader_parameter("blur_radius", blur)
	layer_material.set_shader_parameter("fog_color", config.fog_color)
	layer_material.set_shader_parameter("fog_amount", fog)
	var emissive_material: CanvasItemMaterial = CanvasItemMaterial.new()
	emissive_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if config.emissive_additive:
		emissive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var slots: Array[Dictionary] = []
	for i: int in SLOTS:
		var color_sprite: Sprite2D = Sprite2D.new()
		color_sprite.centered = false
		color_sprite.region_enabled = true
		color_sprite.material = layer_material
		# Las capas desenfocadas se filtran lineal (el desenfoque usa medios píxeles).
		color_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if blur > 0.0 else CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(color_sprite)
		slots.append({"color": color_sprite, "emissive": null, "n": -999999, "tile": "", "offset": 0, "frame": -1})
	# Emisivos encima de todos los tramos de la capa.
	for slot: Dictionary in slots:
		var emissive_sprite: Sprite2D = Sprite2D.new()
		emissive_sprite.centered = false
		emissive_sprite.region_enabled = true
		emissive_sprite.material = emissive_material
		emissive_sprite.modulate.a = config.emissive_strength
		emissive_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(emissive_sprite)
		slot.emissive = emissive_sprite
	var glow: Node2D = Node2D.new()
	glow.name = "Glow"
	var glow_material: CanvasItemMaterial = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = glow_material
	root.add_child(glow)
	var layer: Dictionary = {"name": layer_name, "tiles": tile_names, "scroll": scroll, "slots": slots, "glow": glow, "choices": {}}
	glow.draw.connect(_draw_glow.bind(layer))
	return layer


func _update_layers() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var cam_y: float = camera.global_position.y if camera != null else 0.0
	for layer: Dictionary in _layers:
		# Desplazamiento de la capa (sube la cámara → el fondo baja en pantalla). Redondeado: sin
		# medio píxel, el pixel art no tiembla.
		var v: float = roundf(-cam_y * float(layer.scroll))
		var first: int = floori(v / TILE_SIZE.y)
		for k: int in SLOTS:
			var n: int = first + k
			var slot: Dictionary = layer.slots[posmod(n, SLOTS)]
			if int(slot.n) != n:
				_assign(layer, slot, n)
			var top: float = TILE_SIZE.y - TILE_SIZE.y * n + v
			(slot.color as Sprite2D).position = Vector2(0.0, top)
			(slot.emissive as Sprite2D).position = Vector2(0.0, top)
			_set_slot_frame(slot)
		_prune_choices(layer, first)
		(layer.glow as Node2D).queue_redraw()


# Asigna al tramo número n (de abajo hacia arriba) un tramo de la capa al azar, distinto de los
# vecinos ya elegidos. La elección queda guardada: si la cámara baja, vuelve el mismo.
func _assign(layer: Dictionary, slot: Dictionary, n: int) -> void:
	var choices: Dictionary = layer.choices
	if not choices.has(n):
		var names: Array[String] = layer.tiles
		var options: Array[String] = []
		for tile_name: String in names:
			if tile_name != choices.get(n - 1, "") and tile_name != choices.get(n + 1, ""):
				options.append(tile_name)
		if options.is_empty():
			options = names
		choices[n] = options[_rng.randi() % options.size()]
	slot.n = n
	slot.tile = choices[n]
	var tile: Dictionary = _tiles[slot.tile]
	slot.offset = _rng.randi() % int(tile.frames)
	slot.frame = -1
	(slot.color as Sprite2D).texture = tile.color
	var emissive_sprite: Sprite2D = slot.emissive
	emissive_sprite.texture = tile.emissive
	emissive_sprite.visible = tile.emissive != null


func _set_slot_frame(slot: Dictionary) -> void:
	var frame: int = _slot_frame(slot)
	if frame == int(slot.frame):
		return
	slot.frame = frame
	var region: Rect2 = Rect2(0.0, frame * TILE_SIZE.y, TILE_SIZE.x, TILE_SIZE.y)
	(slot.color as Sprite2D).region_rect = region
	(slot.emissive as Sprite2D).region_rect = region


func _slot_frame(slot: Dictionary) -> int:
	var tile: Dictionary = _tiles[slot.tile]
	return (int(_time / float(tile.frame_time)) + int(slot.offset)) % int(tile.frames)


# Olvida las elecciones muy por debajo de la pantalla (el nivel no vuelve tan atrás).
func _prune_choices(layer: Dictionary, first: int) -> void:
	var choices: Dictionary = layer.choices
	if choices.size() < 32:
		return
	for n: int in choices.keys():
		if n < first - 8:
			choices.erase(n)


func _draw_glow(layer: Dictionary) -> void:
	var glow: Node2D = layer.glow
	for slot: Dictionary in layer.slots:
		if str(slot.tile) == "":
			continue
		var tile: Dictionary = _tiles[slot.tile]
		var origin: Vector2 = (slot.color as Sprite2D).position
		var frame: int = _slot_frame(slot)
		for light: Dictionary in tile.lights:
			var level: float = (light.levels as PackedFloat32Array)[frame]
			var color: Color
			var radius: float
			match str(light.type):
				"beacon":
					color = config.beacon_color
					radius = config.beacon_radius
					level *= config.beacon_intensity
				"fire":
					color = config.fire_color
					radius = config.fire_radius
					# Titileo propio de cada fuego, además del del arte.
					var seed_value: float = float(light.pos.x) * 0.37 + float(light.pos.y) * 0.11
					var flicker: float = 0.5 + 0.5 * sin(_time * 13.0 + seed_value) * sin(_time * 7.3 + seed_value * 2.0)
					level *= config.fire_intensity * (1.0 - config.fire_flicker * flicker)
				_:
					color = config.spark_color
					radius = config.spark_radius
					level *= config.spark_intensity
			if level <= 0.01:
				continue
			var center: Vector2 = origin + (light.pos as Vector2)
			glow.draw_texture_rect(_glow_texture, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(color, level))


# Carga un tramo una sola vez: texturas, cuadros (del JSON de Aseprite) y la intensidad de cada
# luz por cuadro (brillo del emisivo alrededor del punto, normalizado al cuadro más brillante).
static func _load_tile(tile_name: String, lights: Array) -> void:
	if _tiles.has(tile_name):
		return
	var data: Dictionary = (load(DIR + tile_name + ".json") as JSON).data
	var frames: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
	var emissive_path: String = DIR + tile_name + "_emissive.png"
	var emissive: Texture2D = load(emissive_path) if ResourceLoader.exists(emissive_path) else null
	var image: Image = _get_image(emissive, emissive_path)
	var light_list: Array[Dictionary] = []
	for light: Dictionary in lights:
		var pos: Vector2i = Vector2i(int(light.x), int(light.y))
		light_list.append({"type": str(light.type), "pos": Vector2(pos), "levels": _measure_light(image, pos, frames.size())})
	_tiles[tile_name] = {
		"color": load(DIR + tile_name + ".png"),
		"emissive": emissive,
		"frames": frames.size(),
		"frame_time": maxf(float(frames[0].duration) / 1000.0, 0.01),
		"lights": light_list,
	}


static func _get_image(texture: Texture2D, path: String) -> Image:
	var image: Image = texture.get_image() if texture != null else null
	if image == null and FileAccess.file_exists(path):
		# Sin GPU (pruebas headless) la textura importada no tiene imagen: se lee el PNG.
		image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image != null and image.is_compressed():
		image.decompress()
	return image


static func _measure_light(image: Image, pos: Vector2i, frame_count: int) -> PackedFloat32Array:
	var levels: PackedFloat32Array = PackedFloat32Array()
	levels.resize(frame_count)
	if image == null:
		levels.fill(1.0)
		return levels
	var peak: float = 0.0
	for f: int in frame_count:
		var total: float = 0.0
		for dx: int in range(-LIGHT_SAMPLE_RADIUS, LIGHT_SAMPLE_RADIUS + 1):
			for dy: int in range(-LIGHT_SAMPLE_RADIUS, LIGHT_SAMPLE_RADIUS + 1):
				var x: int = pos.x + dx
				var y: int = pos.y + dy
				if x < 0 or x >= int(TILE_SIZE.x) or y < 0 or y >= int(TILE_SIZE.y):
					continue
				var c: Color = image.get_pixel(x, y + f * int(TILE_SIZE.y))
				total += (c.r + c.g + c.b) / 3.0 * c.a
		levels[f] = total
		peak = maxf(peak, total)
	for f: int in frame_count:
		levels[f] = levels[f] / peak if peak > 0.0 else 1.0
	return levels


# Mancha radial suave para los resplandores (blanca; el color lo pone cada luz).
static func _make_glow_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.35, Color(1.0, 1.0, 1.0, 0.45))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture
