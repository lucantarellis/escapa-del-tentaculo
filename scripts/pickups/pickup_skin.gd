@tool
class_name PickupSkin
extends Node2D
## Dibujo de un recogible con sprites: aura cian detrás, el ítem y, encima, las partes que emiten luz.
## Ver `docs/arte/recogibles.md`.
##
## Cada hoja (`pickup_<n>.png`, `_aura.png`, `_emissive.png`) es una columna con un cuadro por fila;
## el JSON de Aseprite da los tags `idle` (en loop) y `collect` (una vez). El aura y el emisivo
## van sin sombreado y siguen siempre el cuadro del ítem. El ítem está centrado en el cuadro: el
## pivote coincide con el centro de la colisión del recogible, sin offset. El recogible que lo usa
## decide qué hacer al terminar `collect` (liberarse u ocultarse). En el editor muestra el primer
## cuadro, sin animar.

## Terminó la animación `collect` (el destello de recolección).
signal collect_finished

## Carpeta de las hojas y JSON. Estructural.
const DIR: String = "res://assets/sprites/pickups/"
## Nombres de los tags de la hoja. Estructural.
const TAG_IDLE: StringName = &"idle"
const TAG_COLLECT: StringName = &"collect"

## Hoja que se dibuja. Se elige por recogible (tanque, moneda, impulso, llave, cinta o caja).
@export_enum("pickup_tank", "pickup_coin", "pickup_boost", "pickup_wrench", "pickup_tape", "pickup_toolbox") var sheet: String = "pickup_tank":
	set(value):
		sheet = value
		if is_node_ready():
			_build()

## SpriteFrames y tags ya armados por hoja (compartidos entre instancias).
static var _cache: Dictionary = {}

var _color: AnimatedSprite2D
var _aura: AnimatedSprite2D
var _emissive: AnimatedSprite2D
var _light: PointLight2D
var _light_tween: Tween


func _ready() -> void:
	_build()


## Pone el ítem en reposo (`idle`, en loop), desde un cuadro al azar para que los recogibles
## iguales no se muevan al unísono.
func play_idle() -> void:
	if _color == null:
		return
	if _light != null:
		if _light_tween != null:
			_light_tween.kill()
		_light.energy = LevelLighting.get_config().pickup_energy
	_color.play(TAG_IDLE)
	var count: int = _color.sprite_frames.get_frame_count(TAG_IDLE)
	_color.set_frame_and_progress(randi() % count, 0.0)


## Reproduce el destello de recolección una vez; al terminar emite [signal collect_finished].
func play_collect() -> void:
	if _color != null:
		_color.play(TAG_COLLECT)
	if _light != null:
		# Destello de luz que acompaña al de la animación y se apaga.
		var cfg: LightingConfig = LevelLighting.get_config()
		if _light_tween != null:
			_light_tween.kill()
		_light.energy = cfg.pickup_collect_energy
		_light_tween = create_tween()
		_light_tween.tween_property(_light, "energy", 0.0, 0.4)


func _build() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var data: Dictionary = _get_data(sheet)
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# De atrás hacia adelante: aura, ítem, emisivo.
	_aura = _make_sprite(data.aura, unshaded)
	_color = _make_sprite(data.color, null)
	_emissive = _make_sprite(data.emissive, unshaded)
	_color.frame_changed.connect(_sync)
	_color.animation_changed.connect(_sync)
	_color.animation_finished.connect(_on_animation_finished)
	if Engine.is_editor_hint():
		_color.animation = TAG_IDLE
		_color.frame = 0
		_sync()
		return
	var cfg: LightingConfig = LevelLighting.get_config()
	if sheet != "pickup_coin" or cfg.pickup_light_on_coins:
		_light = LevelLighting.make_light(cfg.pickup_color, cfg.pickup_energy, cfg.pickup_radius)
		add_child(_light)
	play_idle()


func _make_sprite(frames: SpriteFrames, sprite_material: Material) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = sprite_material
	sprite.animation = TAG_IDLE
	add_child(sprite)
	return sprite


# El aura y el emisivo copian el cuadro del ítem (los tres tienen los mismos tiempos).
func _sync() -> void:
	for follower: AnimatedSprite2D in [_aura, _emissive]:
		if follower.animation != _color.animation:
			follower.animation = _color.animation
		follower.frame = _color.frame


func _on_animation_finished() -> void:
	if _color.animation == TAG_COLLECT:
		collect_finished.emit()


# SpriteFrames de color, aura y emisivo de una hoja, armados una sola vez desde el JSON.
static func _get_data(sheet_name: String) -> Dictionary:
	if _cache.has(sheet_name):
		return _cache[sheet_name]
	var json: Dictionary = (load(DIR + sheet_name + ".json") as JSON).data
	var frames: Array = json.frames if json.frames is Array else (json.frames as Dictionary).values()
	var size: Vector2i = Vector2i(int(frames[0].frame.w), int(frames[0].frame.h))
	var result: Dictionary = {}
	for layer: String in ["color", "aura", "emissive"]:
		var suffix: String = "" if layer == "color" else "_" + layer
		var texture: Texture2D = load("%s%s%s.png" % [DIR, sheet_name, suffix])
		var sprite_frames: SpriteFrames = SpriteFrames.new()
		sprite_frames.remove_animation(&"default")
		for tag: Dictionary in json.meta.frameTags:
			var tag_name: StringName = StringName(tag.name)
			sprite_frames.add_animation(tag_name)
			sprite_frames.set_animation_loop(tag_name, tag_name == TAG_IDLE)
			# Todos los cuadros de un tag duran lo mismo: la velocidad sale del primero.
			sprite_frames.set_animation_speed(tag_name, 1000.0 / float(frames[int(tag.from)].duration))
			for i: int in range(int(tag.from), int(tag.to) + 1):
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(0.0, i * size.y, size.x, size.y)
				sprite_frames.add_frame(tag_name, atlas)
		result[layer] = sprite_frames
	_cache[sheet_name] = result
	return result
