class_name SpaceBackground
extends Node2D
## Fondo del espacio (tier 2): el mismo cielo de los ventanales del hub, en capas con paralaje y
## profundidad de campo. De atrás hacia adelante: nebulosa lejana (desenfocada), estrellas lejanas
## y sol, planeta del anillo (gira), estrellas cercanas (titilan) y la estrella fugaz por código.
## Delante del jugador, en una capa propia, van las rocas del frente muy desenfocadas, repartidas
## en los costados. Ver `docs/arte/fondo-espacio.md`.
##
## Vive dentro de [LevelBackground] (capa de pantalla −10, fuera del alcance del `CanvasModulate`
## del mundo), así que el desplazamiento se calcula a mano desde la Y de la cámara, igual que
## [ShipBackground]. Nada gira: las animaciones son cuadros pre-renderizados.

## Carpeta del arte (PNG y JSON de Aseprite). Estructural.
const DIR: String = "res://assets/sprites/environment/background_space/"
## Shader de desenfoque gaussiano (el mismo de las capas de la nave). Estructural.
const LAYER_SHADER: String = "res://shaders/background_layer.gdshader"
## Pantalla lógica. Estructural. Unidad: px.
const VIEW_SIZE: Vector2 = Vector2(360.0, 640.0)
## Alto de la nebulosa y de las estrellas lejanas, que se repiten en vertical. Estructural. Unidad: px.
const FAR_HEIGHT: float = 1200.0
## Lado de un cuadro del planeta. Estructural. Unidad: px.
const PLANET_SIZE: float = 168.0
## Capa de pantalla de las rocas del frente: entre el mundo y el HUD (80). Estructural.
const FRONT_LAYER: int = 5
## Borde transparente que se agrega alrededor de cada roca para que el desenfoque no se corte ni
## tome píxeles de las rocas vecinas del atlas. Estructural. Unidad: px.
const ROCK_PADDING: int = 8
## Lo más que una roca (con el borde) sobresale de su centro hacia arriba o abajo. Estructural. Unidad: px.
const ROCK_MARGIN: float = 160.0
## Ancho a partir del cual el frente se apaga hacia el centro. Estructural. Unidad: px.
const CLEAR_FADE_WIDTH: float = 70.0
## Duración de la estrella fugaz. Solo visual. Unidad: s.
const SHOOT_TIME: float = 0.7
## Recorrido de la estrella fugaz. Solo visual. Unidad: px.
const SHOOT_DISTANCE: float = 160.0
## Largo de la estela de la estrella fugaz. Solo visual. Unidad: px.
const SHOOT_TRAIL: float = 28.0
## Celeste de las estrellas (de la paleta). Solo visual.
const SHOOT_COLOR: Color = Color(0.7843, 0.9059, 0.9176)

## Ajustes (paralaje, desenfoque, planeta, frente). Vacío = valores por defecto.
@export var config: SpaceDecorConfig

## Rocas del frente ya recortadas del atlas (compartidas entre instancias).
static var _rock_textures: Array[Texture2D] = []

var _nebula: Array[Sprite2D] = []
var _far_stars: Array[Sprite2D] = []
var _near_stars: Array[Sprite2D] = []
var _planet: Sprite2D
var _shoot_node: Node2D
var _front_layer: CanvasLayer
var _front_root: Node2D
var _front_items: Array[Dictionary] = []
var _front_loop: float = 0.0
var _planet_frames: int = 1
var _planet_time: float = 0.15
var _near_frames: int = 1
var _near_time: float = 0.15
var _time: float = 0.0
var _shoot_wait: float = 4.0
var _shoot_t: float = -1.0
var _shoot_from: Vector2 = Vector2.ZERO
var _shoot_dir: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tween: Tween


func _ready() -> void:
	if config == null:
		config = SpaceDecorConfig.new()
	_rng.seed = config.foreground_seed
	var shader: Shader = load(LAYER_SHADER)
	_nebula = _make_tiles("space_far_nebula", 2, _make_blur_material(shader, config.nebula_blur), config.nebula_blur > 0.0, true)
	_far_stars = _make_tiles("space_far_stars", 2, null, false, true)
	_planet = Sprite2D.new()
	_planet.name = "Planet"
	_planet.centered = false
	_planet.region_enabled = true
	_planet.texture = load(DIR + "space_planet_ringed.png")
	_planet.material = _make_blur_material(shader, config.planet_blur)
	_planet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if config.planet_blur > 0.0 else CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_planet)
	var planet_info: Dictionary = _read_frames("space_planet_ringed")
	_planet_frames = planet_info.count
	_planet_time = planet_info.time
	_near_stars = _make_tiles("space_stars_near", 2, null, false, false)
	var near_info: Dictionary = _read_frames("space_stars_near")
	_near_frames = near_info.count
	_near_time = near_info.time
	for sprite: Sprite2D in _near_stars:
		sprite.region_enabled = true
	_shoot_node = Node2D.new()
	_shoot_node.name = "ShootingStar"
	_shoot_node.draw.connect(_draw_shooting)
	add_child(_shoot_node)
	_build_front(shader)
	_update_layers()


func _process(delta: float) -> void:
	_time += delta
	_update_shooting(delta)
	_update_layers()


## Muestra u oculta el fondo con un fundido de [param fade] s (0 = ya). Aplica el fundido también
## a las rocas del frente, que viven en otra capa de pantalla.
func set_shown(shown: bool, fade: float) -> void:
	if _tween != null:
		_tween.kill()
	var target: float = 1.0 if shown else 0.0
	if shown:
		_set_active(true)
	if fade <= 0.0:
		modulate.a = target
		_front_root.modulate.a = target
		_set_active(shown)
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", target, fade)
	_tween.tween_property(_front_root, "modulate:a", target, fade)
	_tween.chain().tween_callback(_set_active.bind(shown))


func _set_active(active: bool) -> void:
	visible = active
	_front_layer.visible = active
	set_process(active)


# Sprites apilados en vertical (los que hagan falta para cubrir la pantalla) con la misma textura.
func _make_tiles(file: String, count: int, tile_material: ShaderMaterial, smooth: bool, repeat: bool) -> Array[Sprite2D]:
	var texture: Texture2D = load(DIR + file + ".png")
	var tiles: Array[Sprite2D] = []
	for i: int in count:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = file.to_pascal_case() + str(i)
		sprite.centered = false
		sprite.texture = texture
		sprite.material = tile_material
		# Con desenfoque se filtra lineal (el desenfoque toma medios píxeles); si no, nearest.
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
		# Repetir la textura hace que el desenfoque de un borde tome el borde opuesto: sin costura.
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if repeat else CanvasItem.TEXTURE_REPEAT_DISABLED
		add_child(sprite)
		tiles.append(sprite)
	return tiles


func _make_blur_material(shader: Shader, blur: float) -> ShaderMaterial:
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("blur_radius", blur)
	shader_material.set_shader_parameter("fog_amount", 0.0)
	return shader_material


# Cantidad de cuadros y duración de uno (s) según el JSON de Aseprite de la hoja.
func _read_frames(file: String) -> Dictionary:
	var data: Dictionary = (load(DIR + file + ".json") as JSON).data
	var frames: Array = data.frames if data.frames is Array else (data.frames as Dictionary).values()
	return {"count": frames.size(), "time": maxf(float(frames[0].duration) / 1000.0, 0.01)}


func _camera_y() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	return camera.global_position.y if camera != null else 0.0


func _update_layers() -> void:
	var cam_y: float = _camera_y()
	# Al subir la cámara (Y menor) las capas bajan en pantalla; redondeado, sin medio píxel el
	# pixel art no tiembla.
	var far_y: float = fposmod(roundf(-cam_y * config.far_parallax), FAR_HEIGHT)
	for i: int in 2:
		var top: float = far_y - FAR_HEIGHT + FAR_HEIGHT * float(i)
		_nebula[i].position = Vector2(0.0, top)
		_far_stars[i].position = Vector2(0.0, top)
	# Planeta: una vez por tramo de `planet_loop`; fuera de la pantalla no se dibuja.
	var planet_y: float = fposmod(config.planet_origin.y + roundf(-cam_y * config.planet_parallax) + PLANET_SIZE, maxf(config.planet_loop, 1.0)) - PLANET_SIZE
	_planet.visible = planet_y < VIEW_SIZE.y and planet_y > -PLANET_SIZE
	_planet.position = Vector2(config.planet_origin.x, planet_y)
	var planet_frame: int = int(_time / _planet_time) % _planet_frames
	_planet.region_rect = Rect2(float(planet_frame) * PLANET_SIZE, 0.0, PLANET_SIZE, PLANET_SIZE)
	var near_y: float = fposmod(roundf(-cam_y * config.near_parallax), VIEW_SIZE.y)
	var near_frame: int = int(_time / _near_time) % _near_frames
	for i: int in 2:
		_near_stars[i].position = Vector2(0.0, near_y - VIEW_SIZE.y + VIEW_SIZE.y * float(i))
		_near_stars[i].region_rect = Rect2(float(near_frame) * VIEW_SIZE.x, 0.0, VIEW_SIZE.x, VIEW_SIZE.y)
	_update_front(cam_y)


# ---------------------------------------------------------------------------------------------
# Rocas del frente
# ---------------------------------------------------------------------------------------------

# Arma el reparto de las rocas: una cada `foreground_gap_min`–`max` px, alternando izquierda y
# derecha, sin repetir la pieza de la anterior (ni la del ciclo siguiente). Se repite cada
# `foreground_loop` px.
func _build_front(shader: Shader) -> void:
	_front_layer = CanvasLayer.new()
	_front_layer.name = "Front"
	_front_layer.layer = FRONT_LAYER
	add_child(_front_layer)
	_front_root = Node2D.new()
	_front_layer.add_child(_front_root)
	if config.foreground_loop <= 0.0:
		return
	var textures: Array[Texture2D] = _get_rock_textures()
	if textures.size() < 2:
		return
	var rock_material: ShaderMaterial = _make_blur_material(shader, config.foreground_blur)
	var y: float = 0.0
	var index: int = 0
	var last_piece: int = -1
	while true:
		var piece: int = _rng.randi() % textures.size()
		while piece == last_piece:
			piece = _rng.randi() % textures.size()
		last_piece = piece
		var from_left: bool = index % 2 == 0
		var inset: float = _rng.randf_range(config.foreground_edge_min, config.foreground_edge_max)
		var x: float = inset if from_left else VIEW_SIZE.x - inset
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Rock%d" % index
		sprite.texture = textures[piece]
		sprite.flip_h = _rng.randf() < 0.5
		sprite.material = rock_material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if config.foreground_blur > 0.0 else CanvasItem.TEXTURE_FILTER_NEAREST
		# Se apagan hacia el centro de la pantalla para no tapar el juego.
		var clear: float = smoothstep(config.foreground_clear_radius, config.foreground_clear_radius + CLEAR_FADE_WIDTH, absf(x - VIEW_SIZE.x * 0.5))
		sprite.modulate.a = config.foreground_alpha * clear
		_front_root.add_child(sprite)
		_front_items.append({"sprite": sprite, "x": x, "y": y, "piece": piece})
		y += _rng.randf_range(config.foreground_gap_min, maxf(config.foreground_gap_max, config.foreground_gap_min))
		index += 1
		if y >= config.foreground_loop:
			break
	_front_loop = y
	# La última pieza no puede ser igual a la primera (el ciclo se repite).
	if _front_items.size() > 2 and _front_items[-1].piece == _front_items[0].piece:
		var fix: int = (int(_front_items[-1].piece) + 1) % textures.size()
		_front_items[-1].piece = fix
		(_front_items[-1].sprite as Sprite2D).texture = textures[fix]


func _update_front(cam_y: float) -> void:
	if _front_items.is_empty():
		return
	var offset: float = cam_y * config.foreground_parallax
	for item: Dictionary in _front_items:
		var y: float = fposmod(float(item.y) - offset + ROCK_MARGIN, _front_loop) - ROCK_MARGIN
		var sprite: Sprite2D = item.sprite
		sprite.visible = y > -ROCK_MARGIN * 0.5 and y < VIEW_SIZE.y + ROCK_MARGIN * 0.5
		sprite.position = Vector2(float(item.x), roundf(y))


# Recorta cada pieza del atlas `space_front_rocks` en su propia textura con borde transparente.
static func _get_rock_textures() -> Array[Texture2D]:
	if not _rock_textures.is_empty():
		return _rock_textures
	var atlas_path: String = DIR + "space_front_rocks.png"
	var atlas: Texture2D = load(atlas_path)
	var image: Image = atlas.get_image() if atlas != null else null
	if image == null and FileAccess.file_exists(atlas_path):
		# Sin GPU (pruebas headless) la textura importada no tiene imagen: se lee el PNG.
		image = Image.load_from_file(ProjectSettings.globalize_path(atlas_path))
	if image == null:
		return _rock_textures
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var data: Dictionary = (load(DIR + "space_front_rocks.json") as JSON).data
	var slices: Array = data.meta.slices
	var names: Array[String] = []
	var bounds: Dictionary = {}
	for slice: Dictionary in slices:
		names.append(str(slice.name))
		bounds[str(slice.name)] = slice.keys[0].bounds
	names.sort()
	for slice_name: String in names:
		var b: Dictionary = bounds[slice_name]
		var piece: Image = Image.create(int(b.w) + ROCK_PADDING * 2, int(b.h) + ROCK_PADDING * 2, false, Image.FORMAT_RGBA8)
		piece.blit_rect(image, Rect2i(int(b.x), int(b.y), int(b.w), int(b.h)), Vector2i(ROCK_PADDING, ROCK_PADDING))
		_rock_textures.append(ImageTexture.create_from_image(piece))
	return _rock_textures


# ---------------------------------------------------------------------------------------------
# Estrella fugaz (por código)
# ---------------------------------------------------------------------------------------------

func _update_shooting(delta: float) -> void:
	if config.shooting_max_interval <= 0.0:
		return
	if _shoot_t >= 0.0:
		_shoot_t += delta
		_shoot_node.queue_redraw()
		if _shoot_t > SHOOT_TIME:
			_shoot_t = -1.0
			_shoot_wait = _rng.randf_range(config.shooting_min_interval, config.shooting_max_interval)
		return
	_shoot_wait -= delta
	if _shoot_wait <= 0.0:
		_shoot_t = 0.0
		# En los costados, lejos del centro, para no confundirse con un aviso de meteoro.
		_shoot_from = Vector2(_rng.randf_range(20.0, 110.0) if _rng.randf() < 0.5 else _rng.randf_range(250.0, 340.0), _rng.randf_range(40.0, 300.0))
		_shoot_dir = Vector2(_rng.randf_range(-0.5, 0.5), 1.0).normalized()


func _draw_shooting() -> void:
	if _shoot_t < 0.0:
		return
	var k: float = _shoot_t / SHOOT_TIME
	var head: Vector2 = _shoot_from + _shoot_dir * (k * SHOOT_DISTANCE)
	var tail: Vector2 = head - _shoot_dir * SHOOT_TRAIL
	_shoot_node.draw_line(tail, head, Color(SHOOT_COLOR, 0.35 * (1.0 - k)), 1.0)
