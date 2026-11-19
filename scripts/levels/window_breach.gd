@tool
class_name WindowBreach
extends Node2D
## Ventanal del techo de la nave que rompe el alien (salida del tier 1 al espacio). Mientras está
## sano es sólido (vidrio). Cuando el jugador se acerca desde abajo, un tentáculo baja desde afuera
## por el hueco del techo; cuando su punta toca el vidrio, el vidrio se raja y se rompe (sacudida y
## vidrios) y empieza la **descompresión**: el aire que se escapa arrastra al jugador hacia el
## hueco hasta sacarlo de la nave. El jugador conserva el control. El tentáculo intenta agarrarlo
## (sin colisión), se retira y se libera.
##
## Se pone en los segmentos de salida del tier 1 (`SegmentTier.exit_segments`), centrado en el hueco
## del techo. Arte: `docs/arte/ventanal.md`. Mecánica: `docs/mecanicas/tier-espacio.md`.

## Se emite cuando el tentáculo rompe el vidrio. [LevelController] lo usa para pasar el fondo al
## del tier siguiente (el espacio) en ese momento.
signal broken

## Hojas del ventanal y de la succión (96×112 por cuadro, mismo origen). Estructural.
const SHEET_DIR: String = "res://assets/sprites/environment/window/"
## El centro del vidrio (origen del nodo) está en (48, 34) del cuadro de 96×112. Estructural.
const SPRITE_OFFSET: Vector2 = Vector2(0.0, 22.0)
## Vidrios que salen volando: 6 cuadros de 6×6 en una columna. Estructural.
const SHARD_FRAMES: int = 6
## Tentáculo de la nave (variantes de `tentacle_front`). Se dibuja dado vuelta. Estructural.
const TENTACLE_FRAMES: Array[String] = [
	"res://assets/sprites/tentacle/ship/tentacle_front_01.res",
	"res://assets/sprites/tentacle/ship/tentacle_front_02.res",
	"res://assets/sprites/tentacle/ship/tentacle_front_03.res",
	"res://assets/sprites/tentacle/ship/tentacle_front_04.res",
]
## Animaciones del tentáculo que se usan una vez. Estructural.
const TENTACLE_ONE_SHOT: Array[StringName] = [&"reach", &"grab", &"retract"]
## z del tentáculo: detrás de las paredes (−1), así el techo lo recorta y se lo ve por el hueco.
## Estructural.
const TENTACLE_Z: int = -2
## Color del vidrio en el editor (cuando no hay sprite). Solo visual.
const GLASS_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.45)

@export_group("Ventanal")
## Tamaño del vidrio (ancho del hueco del techo × espesor). Unidad: px.
@export var glass_size: Vector2 = Vector2(72.0, 36.0):
	set(value):
		glass_size = value
		queue_redraw()
## Distancia vertical bajo el vidrio a la que el jugador dispara la llegada del tentáculo. Unidad: px.
@export var trigger_distance: float = 260.0

@export_group("Rotura")
## Fuerza y duración de la sacudida al romperse. Unidad: px y s.
@export var shake_amplitude: float = 14.0
@export var shake_duration: float = 0.6
## Cantidad de vidrios que salen volando (solo visual).
@export var shard_count: int = 30

@export_group("Tentáculo")
## Altura sobre el vidrio desde la que arranca la punta (fuera de cuadro, detrás del techo). Unidad: px.
@export var tentacle_start_height: float = 260.0
## Tiempo que tarda en bajar hasta el vidrio (mientras reproduce `reach`). Unidad: s.
@export var tentacle_descent_time: float = 0.6
## Cuánto entra en la nave, por debajo del vidrio, la parte más baja del tentáculo mientras intenta
## agarrar (`grab`). Unidad: px.
@export var tentacle_grab_depth: float = 50.0
## Cuánto se lo ve por encima del techo (afuera) antes de tocar el vidrio. Más arriba se recorta, así
## no se ve el corte de la base del sprite. Unidad: px.
@export var tentacle_visible_above: float = 80.0
## Tiempo que tarda en subir hasta salir (mientras reproduce `retract`). Unidad: s.
@export var tentacle_ascent_time: float = 0.7

@export_group("Descompresión")
## Aceleración con la que el aire arrastra al jugador hacia el hueco. Unidad: px/s².
@export var pull_acceleration: float = 1500.0
## Velocidad máxima que puede darle la descompresión. Unidad: px/s.
@export var pull_max_speed: float = 560.0
## Radio alrededor del hueco en el que se siente la succión. Unidad: px.
@export var pull_radius: float = 480.0
## Duración máxima de la succión (termina antes si el jugador ya salió). Unidad: s.
@export var pull_duration: float = 3.0
## Tiempo con que se desvanecen las líneas de aire al terminar la succión. Unidad: s.
@export var wind_fade_time: float = 0.5

## Punta del tentáculo por variante y cuadro (ver [method _measure_tips]).
static var _tips: Dictionary = {}

var _triggered: bool = false
var _broken: bool = false
var _pull_left: float = 0.0
var _wind_fading: bool = false
var _glass: StaticBody2D
var _glass_sprite: SheetSprite
var _wind: SheetSprite
var _tentacle: AnimatedSprite2D
var _tentacle_clip: Node2D
var _tentacle_path: String = ""
var _tentacle_tween: Tween


func _ready() -> void:
	_glass_sprite = _make_sheet_sprite("window_breach")
	_glass_sprite.play(&"intact", true, true)
	if Engine.is_editor_hint():
		return
	_glass = StaticBody2D.new()
	_glass.collision_layer = 1
	_glass.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = glass_size
	shape.shape = rect
	_glass.add_child(shape)
	add_child(_glass)
	_wind = _make_sheet_sprite("window_wind")
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_wind.material = unshaded
	_wind.visible = false
	_glass_sprite.finished.connect(_on_glass_finished)
	add_to_group(&"window_breach")
	# Diferido: el LevelBuilder termina de ubicar el segmento después de agregarlo.
	_set_camera_ceiling.call_deferred()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var h: Vector2 = glass_size * 0.5
	draw_rect(Rect2(-h, glass_size), GLASS_COLOR, false, 1.0)
	draw_line(Vector2(-h.x, h.y + trigger_distance), Vector2(h.x, h.y + trigger_distance), Color(0.72, 0.62, 0.95, 0.6), 1.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player: Player = _get_player()
	if player == null or not player.is_alive():
		return
	if not _triggered:
		var below: float = player.global_position.y - global_position.y
		if below > 0.0 and below <= trigger_distance:
			_start_tentacle()
		return
	if not _broken or _pull_left <= 0.0:
		return
	_pull_left -= delta
	var to_hole: Vector2 = global_position - player.global_position
	# Ya salió (está por encima del hueco): termina la succión.
	if to_hole.y > 0.0 or to_hole.length() > pull_radius:
		if to_hole.y > 0.0:
			_pull_left = 0.0
		if _pull_left <= 0.0:
			_fade_wind()
		return
	var pull: Vector2 = player.velocity + to_hole.normalized() * pull_acceleration * delta
	player.velocity = pull.limit_length(maxf(pull_max_speed, player.velocity.length()))
	if _pull_left <= 0.0:
		_fade_wind()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _broken or _tentacle == null:
		return
	# La punta dibujada tocó el vidrio: se rompe.
	if _tentacle_tip_y() >= -glass_size.y * 0.5:
		_break()


## Devuelve true si el vidrio ya se rompió.
func is_broken() -> bool:
	return _broken


# El jugador se acercó: el tentáculo baja por el hueco con `reach`. El vidrio se rompe cuando la
# punta lo toca (ver _process); si por algún motivo no llega a tocarlo, se rompe al terminar la
# bajada.
func _start_tentacle() -> void:
	_triggered = true
	_tentacle_path = TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]
	var frames: SpriteFrames = load(_tentacle_path)
	for anim: StringName in TENTACLE_ONE_SHOT:
		if frames.has_animation(anim):
			frames.set_animation_loop(anim, false)
	_measure_tips(_tentacle_path, frames)
	# Recorte: el tentáculo solo se ve desde `tentacle_visible_above` sobre el techo hacia abajo.
	_tentacle_clip = Node2D.new()
	_tentacle_clip.name = "TentacleClip"
	_tentacle_clip.z_index = TENTACLE_Z
	_tentacle_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_tentacle_clip.draw.connect(_draw_tentacle_clip)
	add_child(_tentacle_clip)
	_tentacle = AnimatedSprite2D.new()
	_tentacle.sprite_frames = frames
	_tentacle.flip_v = true
	_tentacle.flip_h = randf() < 0.5
	_tentacle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tentacle_clip.add_child(_tentacle)
	_tentacle.animation = &"reach"
	# Centrado en x del vidrio según dónde queda la punta al final de `reach` (el cuerpo se curva).
	var last_tip: Vector2 = _tip_local(&"reach", frames.get_frame_count(&"reach") - 1)
	_tentacle.position = Vector2(-last_tip.x, -glass_size.y * 0.5 - tentacle_start_height - _tip_local(&"reach", 0).y)
	var end_y: float = -glass_size.y * 0.5 - last_tip.y + 2.0
	_tentacle.play(&"reach")
	_tentacle.speed_scale = _anim_length(frames, &"reach") / maxf(tentacle_descent_time, 0.05)
	_tentacle_tween = create_tween()
	_tentacle_tween.tween_property(_tentacle, "position:y", end_y, tentacle_descent_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tentacle_tween.tween_callback(_on_descent_finished)


func _on_descent_finished() -> void:
	if not _broken:
		_break()
	# Ya adentro: intenta agarrar al jugador (no lo alcanza, no tiene colisión). Entra hasta que la
	# parte más baja de la pose de `grab` (que se curva hacia un costado) queda dentro de la nave.
	_tentacle.speed_scale = 1.0
	_tentacle.play(&"grab")
	var frames: SpriteFrames = _tentacle.sprite_frames
	var shallowest: float = INF
	for f: int in range(1, frames.get_frame_count(&"grab")):
		shallowest = minf(shallowest, _tip_local(&"grab", f).y)
	var grab_y: float = glass_size.y * 0.5 + tentacle_grab_depth - shallowest
	var grab_time: float = _anim_length(frames, &"grab")
	_tentacle_tween = create_tween()
	_tentacle_tween.tween_property(_tentacle, "position:y", grab_y, grab_time * 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tentacle_tween.tween_interval(grab_time * 0.65)
	_tentacle_tween.tween_callback(_retract)


func _retract() -> void:
	_tentacle.play(&"retract")
	_tentacle.speed_scale = _anim_length(_tentacle.sprite_frames, &"retract") / maxf(tentacle_ascent_time, 0.05)
	# Sube hasta que todo el tentáculo queda por encima del recorte.
	var deepest: float = -INF
	for f: int in _tentacle.sprite_frames.get_frame_count(&"retract"):
		deepest = maxf(deepest, _tip_local(&"retract", f).y)
	var top_y: float = _clip_top() - deepest - 10.0
	_tentacle_tween = create_tween()
	_tentacle_tween.tween_property(_tentacle, "position:y", top_y, tentacle_ascent_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tentacle_tween.tween_callback(_free_tentacle)


func _free_tentacle() -> void:
	_tentacle_clip.queue_free()
	_tentacle_clip = null
	_tentacle = null


# Y del borde de arriba del recorte del tentáculo.
func _clip_top() -> float:
	return -glass_size.y * 0.5 - tentacle_visible_above


# Zona donde se ve el tentáculo: desde el recorte hacia abajo, todo el ancho del segmento.
func _draw_tentacle_clip() -> void:
	var top: float = _clip_top()
	_tentacle_clip.draw_rect(Rect2(-400.0, top, 800.0, 1200.0), Color.WHITE)


# Rompe el ventanal: grietas y estallido del vidrio, sacudida, vidrios, succión y señal.
func _break() -> void:
	if _broken:
		return
	_broken = true
	_pull_left = pull_duration
	_glass.process_mode = Node.PROCESS_MODE_DISABLED
	(_glass.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	_glass_sprite.play(&"crack")
	var view_camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if view_camera != null:
		view_camera.clear_view_ceiling()
	_wind.visible = true
	_wind.modulate.a = 1.0
	_wind.play(&"loop", true)
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null:
		camera.shake(shake_amplitude, shake_duration)
	_play_shards()
	broken.emit()


func _on_glass_finished(tag: StringName) -> void:
	if tag == &"crack":
		_glass_sprite.play(&"shatter")
	elif tag == &"shatter":
		_glass_sprite.play(&"broken")


# Mientras el vidrio está sano, la pantalla no sube más allá del techo: el ventanal queda arriba
# del todo y no se ve lo que hay del otro lado hasta que se rompe.
func _set_camera_ceiling() -> void:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null and not _broken:
		camera.set_view_ceiling(global_position.y - glass_size.y * 0.5)


# Terminó la succión: las líneas de aire se desvanecen.
func _fade_wind() -> void:
	if _wind_fading or _wind == null or not _wind.visible:
		return
	_wind_fading = true
	var tween: Tween = create_tween()
	tween.tween_property(_wind, "modulate:a", 0.0, maxf(wind_fade_time, 0.01))
	tween.tween_callback(func() -> void: _wind.visible = false)


func _play_shards() -> void:
	if shard_count <= 0:
		return
	var shards: CPUParticles2D = CPUParticles2D.new()
	shards.one_shot = true
	shards.explosiveness = 1.0
	shards.amount = shard_count
	shards.lifetime = 1.0
	shards.direction = Vector2.DOWN
	shards.spread = 70.0
	shards.initial_velocity_min = 80.0
	shards.initial_velocity_max = 260.0
	shards.gravity = Vector2(0.0, 300.0)
	shards.angular_velocity_min = -360.0
	shards.angular_velocity_max = 360.0
	shards.scale_amount_min = 0.7
	shards.scale_amount_max = 1.2
	# Un cuadro al azar de `window_shards` por vidrio (sin animar).
	shards.texture = load(SHEET_DIR + "window_shards.png")
	var shard_material: CanvasItemMaterial = CanvasItemMaterial.new()
	shard_material.particles_animation = true
	shard_material.particles_anim_h_frames = 1
	shard_material.particles_anim_v_frames = SHARD_FRAMES
	shards.material = shard_material
	shards.anim_offset_min = 0.0
	shards.anim_offset_max = 1.0
	shards.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shards.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	shards.emission_rect_extents = glass_size * 0.5
	add_child(shards)
	shards.emitting = true
	get_tree().create_timer(1.5).timeout.connect(shards.queue_free)


func _make_sheet_sprite(sheet_name: String) -> SheetSprite:
	var sprite: SheetSprite = SheetSprite.new()
	sprite.name = sheet_name.to_pascal_case()
	sprite.centered = true
	sprite.offset = SPRITE_OFFSET
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_sheet_textures(SHEET_DIR + sheet_name + ".png", SHEET_DIR + sheet_name + "_normal.png")
	add_child(sprite)
	sprite.load_sheet(SHEET_DIR + sheet_name + ".json")
	return sprite


# Y local (respecto del centro del vidrio) de la punta dibujada del tentáculo en el cuadro actual.
func _tentacle_tip_y() -> float:
	return _tentacle.position.y + _tip_local(_tentacle.animation, _tentacle.frame).y


# Punta del tentáculo dado vuelta, relativa al centro del sprite, en un cuadro de un tag.
func _tip_local(anim: StringName, frame: int) -> Vector2:
	var key: String = "%s:%s:%d" % [_tentacle_path, anim, frame]
	var tip: Vector2 = _tips.get(key, Vector2(0.0, 150.0))
	if _tentacle != null and _tentacle.flip_h:
		tip.x = -tip.x
	return tip


static func _anim_length(frames: SpriteFrames, anim: StringName) -> float:
	var total: float = 0.0
	var speed: float = maxf(frames.get_animation_speed(anim), 0.01)
	for i: int in frames.get_frame_count(anim):
		total += frames.get_frame_duration(anim, i) / speed
	return total


# Mide, una vez por variante, dónde queda la punta en cada cuadro de `reach`, `grab` y `retract`: la
# fila opaca más alta del dibujo original (la punta) pasa a ser la más baja al darlo vuelta.
static func _measure_tips(path: String, frames: SpriteFrames) -> void:
	if _tips.has(path):
		return
	_tips[path] = true
	var images: Dictionary = {}
	for anim: StringName in TENTACLE_ONE_SHOT:
		if not frames.has_animation(anim):
			continue
		for f: int in frames.get_frame_count(anim):
			var texture: Texture2D = frames.get_frame_texture(anim, f)
			var image: Image = _frame_image(texture, images)
			if image == null:
				continue
			var size: Vector2i = image.get_size()
			var tip: Vector2 = Vector2(0.0, size.y * 0.5)
			for y: int in size.y:
				var sum_x: float = 0.0
				var count: int = 0
				for x: int in size.x:
					if image.get_pixel(x, y).a > 0.5:
						sum_x += x
						count += 1
				if count > 0:
					# Dado vuelta: la fila y del original queda en size.y − 1 − y.
					tip = Vector2(sum_x / count - size.x * 0.5, (size.y - 1 - y) - size.y * 0.5)
					break
			_tips["%s:%s:%d" % [path, anim, f]] = tip


# Imagen de un cuadro (región del atlas). Sin GPU (pruebas headless) lee el PNG.
static func _frame_image(texture: Texture2D, cache: Dictionary) -> Image:
	if not texture is AtlasTexture:
		return texture.get_image()
	var atlas_texture: AtlasTexture = texture as AtlasTexture
	var atlas_path: String = atlas_texture.atlas.resource_path
	if not cache.has(atlas_path):
		var image: Image = atlas_texture.atlas.get_image()
		if image == null and FileAccess.file_exists(atlas_path):
			image = Image.load_from_file(ProjectSettings.globalize_path(atlas_path))
		if image != null and image.is_compressed():
			image.decompress()
		cache[atlas_path] = image
	var atlas_image: Image = cache[atlas_path]
	if atlas_image == null:
		return null
	return atlas_image.get_region(Rect2i(atlas_texture.region))


func _get_player() -> Player:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if node is Player:
			return node as Player
	return null
