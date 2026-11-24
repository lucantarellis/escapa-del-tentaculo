class_name Hub
extends Node2D
## Hub: la nave intacta e iluminada como menú navegable. El jugador camina y vuela con el jetpack
## (combustible infinito); Ajustes a la izquierda, Mercado a la derecha y el ascensor a media
## pantalla, que lleva a la partida.
##
## Pantalla fija de 360×640: fondo animado (`hub_bg`), espacio por los ventanales (shader que
## deriva y rota despacio), paredes de la nave sin daño pintadas por terreno, techo con el hueco del
## ascensor, piso `floor_ship`, lámparas con su luz, puertas ([HubDoor]) y ascensor
## ([HubElevator]). Al entrar por una puerta hay fundido a negro y se abre [SettingsScreen] o
## [Market]; al cerrarlo, el jugador vuelve delante de esa puerta. Al soltar el ascensor la cámara lo sigue por
## el hueco, el ambiente se oscurece hacia el de la partida y, al terminar la subida, fundido a negro
## y emite [signal launch_finished] (lo atiende [Main], que arranca la intro de la escotilla).
## Ver `docs/mecanicas/hub.md` y `docs/arte/hub.md`.

## Carpetas del arte. Estructural.
const HUB_DIR: String = "res://assets/sprites/environment/hub/"
const DOORS_DIR: String = "res://assets/sprites/environment/hub_doors/"
const WALLS_SCENE: PackedScene = preload("res://scenes/levels/WallsShip.tscn")
const SPACE_SHADER: Shader = preload("res://shaders/hub_space.gdshader")
const START_SCREEN_SCRIPT: Script = preload("res://scripts/ui/start_screen.gd")
## Tamaño de la pantalla (px). Estructural.
const SCREEN_SIZE: Vector2 = Vector2(360.0, 640.0)
## Paredes en celdas de 12 px: columnas de cada pared lateral, columnas del techo (a los lados del
## hueco del ascensor, x 132–227) y filas del techo (y 0–35). Estructural.
const TILE: float = 12.0
const WALL_COLUMNS: Array[int] = [0, 1, 28, 29]
const CEILING_COLUMNS: Array[Vector2i] = [Vector2i(2, 10), Vector2i(19, 27)]
const CEILING_ROWS: int = 3
## Última fila de pared (pasa por detrás del piso). Estructural.
const WALL_LAST_ROW: int = 52
## Piso: origen de `ShipFloor` (borde inferior; su fila 0 queda en y 596) y semilla. Estructural.
const FLOOR_ORIGIN_Y: float = 623.0
const FLOOR_SEED: int = 7
## Ventanales, reflejo del vidrio (esquina superior izquierda). Estructural.
const WINDOW_POSITIONS: Array[Vector2] = [Vector2(31.0, 46.0), Vector2(241.0, 46.0)]
const GLASS_POSITIONS: Array[Vector2] = [Vector2(36.0, 51.0), Vector2(246.0, 51.0)]
## Rieles del ascensor (x) y su base (esquina superior izquierda). Estructural.
const RAIL_XS: Array[float] = [126.0, 228.0]
const RAIL_BOTTOM: float = 598.0
const RAIL_BASES: Array[Vector2] = [Vector2(123.0, 598.0), Vector2(225.0, 598.0)]
## Lámparas: de techo (esquina superior izquierda) y de pared (y; x 24 a la izquierda y 331
## espejada a la derecha). Estructural.
const CEILING_LAMPS: Array[Vector2] = [Vector2(52.0, 36.0), Vector2(250.0, 36.0)]
const WALL_LAMP_YS: Array[float] = [150.0, 300.0, 450.0]
const WALL_LAMP_LEFT_X: float = 24.0
const WALL_LAMP_RIGHT_X: float = 331.0
## Puertas (esquina superior izquierda del sprite; la fila 110 cae en y 596). Estructural.
const SETTINGS_DOOR_POSITION: Vector2 = Vector2(0.0, 486.0)
const MARKET_DOOR_POSITION: Vector2 = Vector2(335.0, 486.0)
## Donde aparece el jugador al llegar al hub (global). Estructural.
const PLAYER_SPAWN: Vector2 = Vector2(180.0, 591.0)
## Mitad del alto del jugador: del origen a los pies (px). Estructural.
const PLAYER_HALF_HEIGHT: float = 12.0

## Terminó la subida del ascensor y la pantalla quedó en negro: ya se puede arrancar la partida.
signal launch_finished

@export var config: HubConfig
## Si es true, el hub arranca con la pantalla de inicio encima ([StartScreen]) y el jugador sin
## control hasta tocar. [Main] la pide solo al abrir el juego.
@export var show_start_screen: bool = false

var _ambient: CanvasModulate
var _space: ColorRect
var _space_material: ShaderMaterial
var _space_drift: Vector2 = Vector2.ZERO
var _space_drift_angle: float = 0.0
var _space_angle: float = 0.0
var _space_rot_dir: float = 1.0
var _space_flip_left: float = 30.0
var _lamp_lights: Array[PointLight2D] = []
var _lamp_energies: PackedFloat32Array = PackedFloat32Array()
var _doors: Dictionary = {}
var _elevator: HubElevator
var _riding: bool = false
var _ride_offset: Vector2 = Vector2.ZERO
var _busy: bool = false

@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Camera
@onready var _market: Market = $Ui/Market
@onready var _settings: SettingsScreen = $Ui/Settings
@onready var _fade: ColorRect = $Ui/Fade


func _ready() -> void:
	if config == null:
		config = HubConfig.new()
	_build_ambient()
	_build_space()
	_build_background()
	_build_windows()
	_build_walls()
	_build_rails()
	_build_lamps()
	_build_floor()
	_build_doors()
	_build_rail_bases()
	_build_elevator()
	# El jugador va encima de todo lo del hub.
	move_child(_player, -1)
	_player.global_position = PLAYER_SPAWN
	_camera.position = SCREEN_SIZE * 0.5
	_camera.make_current()
	_market.closed.connect(_on_room_closed.bind(&"market"))
	_settings.closed.connect(_on_room_closed.bind(&"settings"))
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_flip_rotation_timer()
	if show_start_screen:
		_show_start_screen()


# Pantalla de inicio encima del hub en vivo; el jugador no está en escena hasta tocar: entonces
# aparece con la animación de reaparición mientras se funde la pantalla.
func _show_start_screen() -> void:
	_busy = true
	_player.set_frozen(true)
	var start: StartScreen = START_SCREEN_SCRIPT.new() as StartScreen
	start.name = "StartScreen"
	$Ui.add_child(start)
	$Ui.move_child(start, _fade.get_index())
	start.starting.connect(_on_start_screen_starting)
	start.started.connect(_on_start_screen_started.bind(start))


func _on_start_screen_starting() -> void:
	_player.set_frozen(false)
	_player.velocity = Vector2.ZERO
	_player.play_appear()


func _on_start_screen_started(start: StartScreen) -> void:
	start.queue_free()
	_busy = false


func _physics_process(_delta: float) -> void:
	# En el hub el combustible no se gasta.
	if not _riding:
		_player.add_fuel(_player.config.max_fuel)


func _process(delta: float) -> void:
	_update_space(delta)
	if _riding:
		_player.global_position = _elevator.get_car_position() + _ride_offset
		_camera.position.y = SCREEN_SIZE.y * 0.5 + (_elevator.get_car_position().y - HubElevator.PLATFORM_POSITION.y)
		var t: float = _elevator.get_ride_ratio()
		_ambient.color = config.ambient_color.lerp(LevelLighting.get_config().ambient_color, t)
		for index: int in _lamp_lights.size():
			_lamp_lights[index].energy = _lamp_energies[index] * (1.0 - t)


## Devuelve el jugador del hub. Sirve para pruebas.
func get_player() -> Player:
	return _player


## Devuelve la puerta `settings` o `market`. Sirve para pruebas.
func get_door(kind: StringName) -> HubDoor:
	return _doors.get(kind) as HubDoor


## Devuelve la pantalla de inicio si se está mostrando (null si no). Sirve para pruebas.
func get_start_screen() -> StartScreen:
	return get_node_or_null("Ui/StartScreen") as StartScreen


## Devuelve el ascensor. Sirve para pruebas.
func get_elevator() -> HubElevator:
	return _elevator


# --- armado ---------------------------------------------------------------------------------

func _build_ambient() -> void:
	_ambient = CanvasModulate.new()
	_ambient.name = "Ambient"
	_ambient.color = config.ambient_color
	add_child(_ambient)


func _build_space() -> void:
	_space_material = ShaderMaterial.new()
	_space_material.shader = SPACE_SHADER
	var texture: Texture2D = load(HUB_DIR + "hub_space.png")
	_space_material.set_shader_parameter("space_texture", texture)
	_space_material.set_shader_parameter("texture_size", texture.get_size())
	_space_material.set_shader_parameter("rect_size", SCREEN_SIZE)
	_space = ColorRect.new()
	_space.name = "Space"
	_space.size = SCREEN_SIZE
	_space.material = _space_material
	_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_space.z_index = -10
	add_child(_space)
	_space_drift_angle = randf() * TAU
	_space_drift = Vector2(randf() * texture.get_width(), randf() * texture.get_height())


func _build_background() -> void:
	var bg: SheetSprite = SheetSprite.new()
	bg.name = "Background"
	bg.centered = false
	bg.texture = load(HUB_DIR + "hub_bg.png")
	bg.z_index = -9
	bg.add_child(_emissive(HUB_DIR + "hub_bg_emissive.png"))
	bg.followers = [bg.get_child(0) as Sprite2D]
	bg.load_sheet(HUB_DIR + "hub_bg.json")
	add_child(bg)
	bg.play(&"ambient", true)


func _build_windows() -> void:
	for at: Vector2 in WINDOW_POSITIONS:
		var window: Sprite2D = _sprite(_canvas_texture(HUB_DIR + "hub_window.png", HUB_DIR + "hub_window_normal.png"), at)
		window.name = "Window"
		window.z_index = -8
		add_child(window)
	var glass_material: CanvasItemMaterial = CanvasItemMaterial.new()
	glass_material.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	for at: Vector2 in GLASS_POSITIONS:
		var glass: Sprite2D = _sprite(load(HUB_DIR + "hub_window_glass.png"), at)
		glass.name = "Glass"
		glass.z_index = -8
		glass.material = glass_material
		add_child(glass)


# Paredes laterales, techo y el hueco que sigue hacia arriba, pintados por terreno (sin daño) antes
# de entrar al árbol, así las capas emisivas y las luces de pared los copian al arrancar.
func _build_walls() -> void:
	var walls: TileMapLayer = WALLS_SCENE.instantiate() as TileMapLayer
	walls.name = "Walls"
	var top_row: int = -int(ceilf((config.elevator_ride_distance + SCREEN_SIZE.y * 0.5) / TILE)) - 2
	var cells: Array[Vector2i] = []
	for row: int in range(top_row, WALL_LAST_ROW + 1):
		for column: int in WALL_COLUMNS:
			cells.append(Vector2i(column, row))
		if row < CEILING_ROWS:
			for span: Vector2i in CEILING_COLUMNS:
				for column: int in range(span.x, span.y + 1):
					cells.append(Vector2i(column, row))
	walls.set_cells_terrain_connect(cells, 0, 0)
	add_child(walls)


func _build_rails() -> void:
	var top: float = -(config.elevator_ride_distance + SCREEN_SIZE.y)
	var texture: CanvasTexture = _canvas_texture(HUB_DIR + "elevator_rail.png", HUB_DIR + "elevator_rail_normal.png")
	texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for x: float in RAIL_XS:
		var rail: Sprite2D = _sprite(texture, Vector2(x, top))
		rail.name = "Rail"
		rail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		rail.region_enabled = true
		rail.region_rect = Rect2(0.0, 0.0, 6.0, RAIL_BOTTOM - top)
		add_child(rail)


func _build_rail_bases() -> void:
	for at: Vector2 in RAIL_BASES:
		var base: Sprite2D = _sprite(load(HUB_DIR + "elevator_rail_base.png"), at)
		base.name = "RailBase"
		add_child(base)


func _build_lamps() -> void:
	for at: Vector2 in CEILING_LAMPS:
		_add_lamp("lamp_ceiling", at, false)
		_add_light(config.ceiling_light_color, config.ceiling_light_energy, config.ceiling_light_radius, at + Vector2(29.0, 5.0))
	for y: float in WALL_LAMP_YS:
		_add_lamp("lamp_wall", Vector2(WALL_LAMP_LEFT_X, y), false)
		_add_light(config.wall_light_color, config.wall_light_energy, config.wall_light_radius, Vector2(WALL_LAMP_LEFT_X + 7.0, y + 5.0))
		_add_lamp("lamp_wall", Vector2(WALL_LAMP_RIGHT_X, y), true)
		_add_light(config.wall_light_color, config.wall_light_energy, config.wall_light_radius, Vector2(WALL_LAMP_RIGHT_X - 2.0, y + 5.0))
	_add_light(config.wall_light_color, config.fill_light_energy, config.fill_light_radius, Vector2(SCREEN_SIZE.x * 0.5, 560.0))


func _add_lamp(sheet: String, at: Vector2, flip: bool) -> void:
	var lamp: Sprite2D = _sprite(load(HUB_DIR + sheet + ".png"), at)
	lamp.name = sheet
	lamp.flip_h = flip
	var emissive: Sprite2D = _emissive(HUB_DIR + sheet + "_emissive.png")
	emissive.flip_h = flip
	lamp.add_child(emissive)
	add_child(lamp)


func _add_light(color: Color, energy: float, radius: float, at: Vector2) -> void:
	var light: PointLight2D = LevelLighting.make_light(color, energy, radius)
	light.name = "LampLight"
	light.position = at
	add_child(light)
	_lamp_lights.append(light)
	_lamp_energies.append(energy)


func _build_floor() -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Floor"
	body.position = Vector2(0.0, FLOOR_ORIGIN_Y)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionPolygon2D = CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(0, -20), Vector2(SCREEN_SIZE.x, -20), Vector2(SCREEN_SIZE.x, 0), Vector2(0, 0)])
	body.add_child(shape)
	var floor_visual: ShipFloor = ShipFloor.new()
	floor_visual.name = "ShipFloor"
	floor_visual.hatch_x = -1.0
	floor_visual.width = SCREEN_SIZE.x
	floor_visual.floor_seed = FLOOR_SEED
	body.add_child(floor_visual)
	add_child(body)


func _build_doors() -> void:
	for kind: StringName in [&"settings", &"market"]:
		var door: HubDoor = HubDoor.new()
		door.name = "Door" + String(kind).capitalize()
		door.kind = kind
		door.config = config
		door.position = SETTINGS_DOOR_POSITION if kind == &"settings" else MARKET_DOOR_POSITION
		add_child(door)
		door.set_player(_player)
		door.entered.connect(_on_door_entered.bind(kind))
		_doors[kind] = door
	# Sin progreso no hay mercado.
	(_doors[&"market"] as HubDoor).set_enabled(PlayerProgress.is_enabled())


func _build_elevator() -> void:
	_elevator = HubElevator.new()
	_elevator.name = "Elevator"
	_elevator.config = config
	add_child(_elevator)
	_elevator.set_player(_player)
	_elevator.launch_started.connect(_on_launch_started)
	_elevator.ride_finished.connect(_on_ride_finished)


# --- puertas --------------------------------------------------------------------------------

# Fundido a negro, el jugador se congela y se abre Ajustes o el Mercado.
func _on_door_entered(kind: StringName) -> void:
	if _busy or _riding:
		return
	_busy = true
	_set_doors_enabled(false)
	await _fade_to(1.0, config.door_fade_time)
	_player.set_frozen(true)
	if kind == &"market":
		_market.open()
	else:
		_settings.open()
	await _fade_to(0.0, config.door_fade_time)


# Al cerrar la pantalla, fundido y el jugador vuelve delante de esa puerta.
func _on_room_closed(kind: StringName) -> void:
	await _fade_to(1.0, config.door_fade_time)
	var door: HubDoor = _doors[kind]
	_player.set_frozen(false)
	_player.velocity = Vector2.ZERO
	_player.global_position = door.get_return_point() - Vector2(0.0, PLAYER_HALF_HEIGHT)
	await _fade_to(0.0, config.door_fade_time)
	_set_doors_enabled(true)
	_busy = false


func _set_doors_enabled(enabled: bool) -> void:
	(_doors[&"settings"] as HubDoor).set_enabled(enabled)
	(_doors[&"market"] as HubDoor).set_enabled(enabled and PlayerProgress.is_enabled())


# --- ascensor -------------------------------------------------------------------------------

# El jugador queda pegado a la plataforma (sin física ni input) mientras sube.
func _on_launch_started() -> void:
	_riding = true
	_set_doors_enabled(false)
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)
	_ride_offset = _player.global_position - _elevator.get_car_position()


func _on_ride_finished() -> void:
	await _fade_to(1.0, config.launch_fade_time)
	launch_finished.emit()


func _fade_to(alpha: float, duration: float) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, maxf(duration, 0.01))
	await tween.finished


# --- espacio --------------------------------------------------------------------------------

# Deriva en una dirección que vaga despacio y rotación muy lenta que cambia de sentido cada tanto.
func _update_space(delta: float) -> void:
	_space_drift_angle += sin(Time.get_ticks_msec() * 0.00013) * config.space_drift_turn * delta
	_space_drift += Vector2.from_angle(_space_drift_angle) * config.space_drift_speed * delta
	_space_angle += deg_to_rad(config.space_rotation_speed) * _space_rot_dir * delta
	_space_flip_left -= delta
	if _space_flip_left <= 0.0:
		_space_rot_dir = -_space_rot_dir
		_flip_rotation_timer()
	_space_material.set_shader_parameter("drift", _space_drift)
	_space_material.set_shader_parameter("angle", _space_angle)


func _flip_rotation_timer() -> void:
	_space_flip_left = randf_range(config.space_rotation_flip_min, config.space_rotation_flip_max)


# --- piezas ---------------------------------------------------------------------------------

static func _canvas_texture(diffuse: String, normal: String) -> CanvasTexture:
	var texture: CanvasTexture = CanvasTexture.new()
	texture.diffuse_texture = load(diffuse)
	if ResourceLoader.exists(normal):
		texture.normal_texture = load(normal)
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return texture


static func _sprite(texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = at
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


static func _emissive(path: String) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Emissive"
	sprite.texture = load(path)
	sprite.centered = false
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = unshaded
	return sprite
