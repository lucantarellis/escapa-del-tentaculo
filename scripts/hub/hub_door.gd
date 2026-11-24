class_name HubDoor
extends Node2D
## Puerta del hub (Ajustes o Mercado) metida en la pared lateral, en perspectiva 2,5D.
##
## Se abre sola cuando el jugador entra en el área de [member HubConfig.door_trigger_width] px
## delante de ella y se cierra al salir. Con la puerta abierta, si el jugador sigue caminando
## contra la pared [member HubConfig.door_enter_push_time] s, emite [signal entered]. Al abrirse
## ilumina la sala con su color: `PointLight2D` con un cono horizontal y un haz visible aditivo,
## con la intensidad atada a la animación (`closed` 0, `opening` sube, `open` titila, `closing`
## baja). El origen del nodo es la esquina superior izquierda del sprite (25×125).
## Ver `docs/mecanicas/hub.md` y `docs/arte/hub.md`.

## Hojas de las puertas. Estructural.
const SHEET_DIR: String = "res://assets/sprites/environment/hub_doors/"
## Ancho de la pared en la que va metida (px). Estructural.
const WALL_WIDTH: float = 24.0
## Fila del sprite que coincide con el borde de atrás del piso. Estructural.
const FLOOR_ROW: float = 110.0
## Tamaño del cuadro (px). Estructural.
const FRAME_SIZE: Vector2 = Vector2(25.0, 125.0)
## Lado de la textura del cono de luz (px). Estructural.
const CONE_TEXTURE_SIZE: int = 128
## Apertura del cono de luz (grados). Solo visual.
const CONE_ANGLE_DEG: float = 70.0
## Cuánto se corre la luz hacia la sala desde el centro del hueco (px). Solo visual.
const LIGHT_INSET: float = 10.0
## Altura del centro del hueco sobre el borde de atrás del piso (px). Solo visual.
const GAP_CENTER_HEIGHT: float = 36.0
## Velocidad del titileo de la luz abierta (rad/s). Solo visual.
const FLICKER_SPEED: float = 2.3

## Se pidió entrar (el jugador empujó contra la pared con la puerta abierta).
signal entered

## `settings` o `market`: elige el arte, el color de la luz y en qué pared va.
@export var kind: StringName = &"settings"
## Parámetros (luz, área, tiempo de empuje). Lo asigna el [Hub].
@export var config: HubConfig

var _sprite: SheetSprite
var _light: PointLight2D
var _beam: Sprite2D
var _area: Area2D
var _player: Player
var _player_inside: bool = false
var _push_time: float = 0.0
var _level: float = 0.0
var _level_tween: Tween
var _time: float = 0.0
var _enabled: bool = true
var _held: bool = false


func _ready() -> void:
	if config == null:
		config = HubConfig.new()
	var sheet: String = "door_" + String(kind)
	_sprite = SheetSprite.new()
	_sprite.name = "Sprite"
	_sprite.centered = false
	_sprite.set_sheet_textures(SHEET_DIR + sheet + ".png", SHEET_DIR + sheet + "_normal.png")
	var emissive: Sprite2D = Sprite2D.new()
	emissive.name = "Emissive"
	emissive.centered = false
	emissive.texture = load(SHEET_DIR + sheet + "_emissive.png")
	emissive.material = _unshaded()
	_sprite.add_child(emissive)
	_sprite.followers = [emissive]
	_sprite.load_sheet(SHEET_DIR + sheet + ".json")
	_sprite.finished.connect(_on_sprite_finished)
	add_child(_sprite)
	_sprite.play(&"closed", true)
	_setup_light()
	_setup_area()


## Jugador que abre la puerta y puede entrar. Lo asigna el [Hub].
func set_player(player: Player) -> void:
	_player = player


## Activa o desactiva la puerta (mientras está desactivada no se abre ni deja entrar).
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_push_time = 0.0
		_held = false
		_set_open(false)
	elif _player_inside:
		_set_open(true)


## Mantiene la puerta abierta aunque el jugador salga del área (mientras entra o sale caminando).
## Con `false` suelta: se cierra si el jugador no está en el área.
func set_held_open(held: bool) -> void:
	_held = held
	if held:
		_set_open(true)
	elif not _player_inside:
		_set_open(false)


## Hacia dónde camina el jugador para entrar: -1 izquierda, +1 derecha.
func get_enter_direction() -> float:
	return -_inward()


## Hacia dónde sale el jugador de la puerta: +1 derecha, -1 izquierda.
func get_exit_direction() -> float:
	return _inward()


## Punto del piso en el centro del hueco, adonde se pierde el jugador (global).
func get_gap_point() -> Vector2:
	return Vector2(_gap_x(), global_position.y + FLOOR_ROW)


## Devuelve true si la puerta está abierta del todo (`open`).
func is_open() -> bool:
	return _sprite.get_tag() == &"open"


## Devuelve el tag que se ve (`closed`, `opening`, `open`, `closing`).
func get_state() -> StringName:
	return _sprite.get_tag()


## Punto del piso delante de la puerta, para dejar al jugador al volver (global).
func get_return_point() -> Vector2:
	var inward: float = _inward()
	var x: float = _gap_x() + inward * (config.door_trigger_width * 0.5 + 8.0)
	return Vector2(x, global_position.y + FLOOR_ROW)


func _process(delta: float) -> void:
	_time += delta
	var flicker: float = 1.0
	if is_open():
		flicker = 1.0 + config.door_light_flicker * sin(_time * FLICKER_SPEED)
	_light.energy = config.door_light_energy * _level * flicker
	_light.visible = _level > 0.001
	_beam.modulate.a = config.door_beam_alpha * _level * flicker
	_beam.visible = _level > 0.001
	_update_push(delta)


# Entrar: con la puerta abierta, el jugador en el área, en el piso, contra la pared y empujando.
func _update_push(delta: float) -> void:
	if not _enabled or _player == null or not _player_inside or not is_open():
		_push_time = 0.0
		return
	var axis: float = Input.get_axis("move_left", "move_right")
	var toward_wall: bool = signf(axis) == -_inward() and absf(axis) > 0.2
	if toward_wall and _player.is_on_floor() and _player.is_on_wall():
		_push_time += delta
		if _push_time >= config.door_enter_push_time:
			_push_time = 0.0
			entered.emit()
	else:
		_push_time = 0.0


# +1 si la sala queda a la derecha de la puerta (Ajustes, pared izquierda); −1 al revés.
func _inward() -> float:
	return 1.0 if kind == &"settings" else -1.0


# X global del centro del hueco (dentro de la pared).
func _gap_x() -> float:
	if kind == &"settings":
		return global_position.x + FRAME_SIZE.x - 1.0 - WALL_WIDTH * 0.5
	return global_position.x + WALL_WIDTH * 0.5


func _setup_light() -> void:
	var color: Color = Color("89D9EB") if kind == &"settings" else Color("F8B842")
	var inward: float = _inward()
	var local_gap: Vector2 = Vector2(_gap_x() - global_position.x, FLOOR_ROW - GAP_CENTER_HEIGHT)
	_light = PointLight2D.new()
	_light.name = "Light"
	_light.texture = _make_cone_texture(inward)
	# El vértice del cono está en el centro de la textura: medio lado es el alcance.
	_light.texture_scale = config.door_light_range / (float(CONE_TEXTURE_SIZE) * 0.5)
	_light.position = local_gap + Vector2(inward * LIGHT_INSET, 0.0)
	_light.color = color
	_light.energy = 0.0
	_light.height = LevelLighting.get_config().light_height
	add_child(_light)
	_beam = Sprite2D.new()
	_beam.name = "Beam"
	_beam.texture = _make_beam_texture(inward)
	_beam.centered = false
	var beam_material: CanvasItemMaterial = CanvasItemMaterial.new()
	beam_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beam_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_beam.material = beam_material
	_beam.self_modulate = color
	_beam.modulate.a = 0.0
	var floor_y: float = FLOOR_ROW + 7.0
	var start_x: float = FRAME_SIZE.x if inward > 0.0 else 0.0
	var beam_x: float = start_x if inward > 0.0 else start_x - config.door_beam_length
	_beam.position = Vector2(beam_x, floor_y - config.door_beam_height)
	add_child(_beam)


func _setup_area() -> void:
	_area = Area2D.new()
	_area.name = "Trigger"
	_area.collision_layer = 0
	_area.collision_mask = 2
	_area.monitorable = false
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(config.door_trigger_width, FRAME_SIZE.y - 20.0)
	shape.shape = rect
	var inner_x: float = FRAME_SIZE.x if kind == &"settings" else 0.0
	shape.position = Vector2(inner_x + _inward() * config.door_trigger_width * 0.5, FLOOR_ROW - rect.size.y * 0.5 + 7.0)
	_area.add_child(shape)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	add_child(_area)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_inside = true
		if _enabled:
			_set_open(true)


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_inside = false
		if not _held:
			_set_open(false)


func _set_open(open: bool) -> void:
	var tag: StringName = _sprite.get_tag()
	if open and (tag == &"closed" or tag == &"closing"):
		_sprite.play(&"opening")
		_fade_level(1.0, _sprite.get_tag_duration(&"opening"))
	elif not open and (tag == &"open" or tag == &"opening"):
		_sprite.play(&"closing")
		_fade_level(0.0, _sprite.get_tag_duration(&"closing"))


func _fade_level(target: float, duration: float) -> void:
	if _level_tween != null and _level_tween.is_valid():
		_level_tween.kill()
	_level_tween = create_tween()
	_level_tween.tween_property(self, "_level", target, maxf(duration, 0.01))


func _on_sprite_finished(tag: StringName) -> void:
	if tag == &"opening":
		_sprite.play(&"open", true)
	elif tag == &"closing":
		_sprite.play(&"closed", true)
		# Si el jugador volvió a entrar mientras se cerraba, se abre de nuevo.
		if _player_inside and _enabled:
			_set_open(true)


static func _unshaded() -> CanvasItemMaterial:
	var material: CanvasItemMaterial = CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material


# Cono horizontal de CONE_ANGLE_DEG con el vértice en el centro, abierto hacia la derecha si
# [param inward] > 0: 1 en el vértice y 0 a medio lado, con los costados suavizados.
static func _make_cone_texture(inward: float) -> Texture2D:
	var size: int = CONE_TEXTURE_SIZE
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half_angle: float = deg_to_rad(CONE_ANGLE_DEG * 0.5)
	for y: int in size:
		for x: int in size:
			var local: Vector2 = Vector2((float(x) - size * 0.5) * inward, float(y) - size * 0.5)
			var r: float = local.length() / (float(size) * 0.5)
			var a: float = absf(atan2(local.y, local.x))
			var side: float = clampf((half_angle - a) / (half_angle * 0.35), 0.0, 1.0)
			var v: float = clampf(1.0 - r, 0.0, 1.0) * side
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, v * v))
	return ImageTexture.create_from_image(image)


# Haz visible: sale del hueco, se abre hacia la sala y cae al piso. Columna 0 en la puerta.
func _make_beam_texture(inward: float) -> Texture2D:
	var w: int = int(config.door_beam_length)
	var h: int = int(config.door_beam_height)
	var image: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x: int in w:
		var t: float = float(x) / float(maxi(w - 1, 1))
		# El borde de arriba baja hacia la sala; el de abajo queda en el piso.
		var top: float = lerpf(float(h) * 0.15, float(h) * 0.55, t)
		for y: int in h:
			var v: float = 0.0
			if float(y) >= top:
				var edge: float = clampf((float(y) - top) / 6.0, 0.0, 1.0)
				v = (1.0 - t) * edge
			var px: int = x if inward > 0.0 else w - 1 - x
			image.set_pixel(px, y, Color(1.0, 1.0, 1.0, v))
	return ImageTexture.create_from_image(image)
