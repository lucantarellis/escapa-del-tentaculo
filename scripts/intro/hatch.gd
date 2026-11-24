class_name Hatch
extends Node2D
## Escotilla del piso del segmento de inicio: de ahí "sale" el jugador en la intro.
##
## Tiene tres estados visuales, dibujados con la hoja `hatch` (ver `docs/arte/piso-y-escotilla.md`):
## cerrada (`closed`, la rendija respira en rojo tenue), golpeada (cada [method hit] reproduce
## `hit_k` y queda en `idle_k`, más abombada y con más luz) y rota (`break` y después `broken`).
## Tres capas sincronizadas: color con relieve, emisivo y resplandor (aditivo), más una luz roja
## (`PointLight2D`) cuya energía sigue el estado (valores en [IntroConfig]). El origen del nodo es
## el centro del borde SUPERIOR del piso. Corre siempre (`PROCESS_MODE_ALWAYS`) porque el nivel
## está en pausa mientras dura la intro. Ver `docs/mecanicas/intro-escotilla.md`.

## Hojas de la escotilla (color + relieve, emisivo, resplandor) y su JSON de Aseprite. Estructural.
const SHEET_DIR: String = "res://assets/sprites/intro/"
const SHEET_JSON: String = SHEET_DIR + "hatch.json"
## Fragmentos: 6 cuadros de 12×12 en una columna. Estructural.
const DEBRIS_SHEET: String = SHEET_DIR + "hatch_debris.png"
const DEBRIS_SHEET_NORMAL: String = SHEET_DIR + "hatch_debris_normal.png"
const DEBRIS_FRAMES: int = 6
const DEBRIS_FRAME_SIZE: float = 12.0
## Desplazamiento del dibujo: el origen del nodo (centro del borde superior del piso) está en
## (72, 64) del cuadro de 144×96. Estructural. Unidad: px.
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -16.0)
## Golpes con animación propia (`hit_1..3`); los siguientes repiten el último. Estructural.
const MAX_HIT_ANIM: int = 3
## Semiancho del marco. Solo visual. Unidad: px.
const FRAME_HALF_WIDTH: float = 64.0
## Y de la cara superior del marco respecto del origen: de ahí sale el jugador. Solo visual.
## Unidad: px.
const FRAME_TOP: float = -15.0
## Grosor del marco alrededor de las hojas (zona de donde sale el gas). Solo visual. Unidad: px.
const FRAME_BORDER: float = 4.0
## Desplazamiento de la sacudida de la escotilla en un golpe normal. Solo visual. Unidad: px.
const HIT_SHAKE_PX: float = 3.0
## Salto hacia arriba de la escotilla en un golpe normal (el golpe viene de abajo): hace que se lea el
## impacto, porque el abombamiento del arte en los primeros golpes es sutil. Solo visual. Unidad: px.
const HIT_HOP_PX: float = 3.0
## Duración de la sacudida de la escotilla. Solo visual. Unidad: s.
const HIT_SHAKE_TIME: float = 0.3
## Gravedad de los fragmentos de la ruptura. Solo visual. Unidad: px/s².
const DEBRIS_GRAVITY: float = 900.0
## Rango de velocidad de los fragmentos al salir. Solo visual. Unidad: px/s.
const DEBRIS_SPEED_MIN: float = 120.0
const DEBRIS_SPEED_MAX: float = 300.0
## Vida de un fragmento (cae fuera de pantalla). Solo visual. Unidad: s.
const DEBRIS_LIFETIME: float = 1.4
## Giro máximo de un fragmento. Solo visual. Unidad: rad/s.
const DEBRIS_SPIN: float = 8.0
## Apertura del cono del gas. Solo visual. Unidad: grados.
const GAS_SPREAD_DEG: float = 35.0

## Vibración del celular en cada golpe y en la ruptura (si está activa en Ajustes). Unidad: ms.
## Solo visual.
const HIT_VIBRATION_MS: int = 80
const BREAK_VIBRATION_MS: int = 250

## Se emite cuando termina la animación de apertura de [method break_open].
signal break_finished

## Parámetros de la intro (gas). Lo asigna [LevelController]; si queda vacío se usan los valores
## por defecto de [IntroConfig].
@export var config: IntroConfig

@onready var _visual: Node2D = $Visual
@onready var _sprite: SheetSprite = $Visual/Sprite
@onready var _emissive: Sprite2D = $Visual/Emissive
@onready var _light: PointLight2D = $Light
## Tres emisores de gas, uno por forma de bocanada (`gas_puff_a/b/c`).
@onready var _gas_emitters: Array[CPUParticles2D] = [$GasPuffA, $GasPuffB, $GasPuffC]

var _hits: int = 0
var _broken: bool = false
var _shake_tween: Tween
var _light_tween: Tween
## Niveles actuales de las tres luces (entorno, halo y haz); _process los aplica con la respiración.
var _light_level: float = 0.0
var _halo_level: float = 0.0
var _beam_level: float = 0.0
var _time: float = 0.0
var _halo: Sprite2D
var _beam: Sprite2D
var _debris_texture: CanvasTexture


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_sprites()
	_setup_light()
	_setup_gas()
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	var cfg: IntroConfig = _get_config()
	var breath: float = 1.0
	if _broken:
		breath = 1.0 + cfg.hatch_breath_amount * sin(_time * TAU * cfg.hatch_breath_speed)
	_light.energy = _light_level * breath
	_halo.modulate.a = clampf(_halo_level * breath, 0.0, 1.0)
	_beam.modulate.a = clampf(_beam_level * breath, 0.0, 1.0)


## Golpe: sacude la escotilla, la abomba un poco más, intensifica el brillo y suelta una ráfaga
## de gas. [param strength] es el multiplicador de intensidad (1 = golpe base). Ignorado si la
## escotilla ya está rota.
func hit(strength: float) -> void:
	if _broken:
		return
	_hits += 1
	_sprite.play(StringName("hit_%d" % mini(_hits, MAX_HIT_ANIM)))
	# Destello del impacto y después queda en el nivel del golpe: más abollada, más luz se escapa.
	var level: Vector3 = _state_levels()
	_set_levels(level * (1.0 + _get_config().hatch_hit_flash), 0.04)
	_light_tween.tween_method(_apply_levels, level * (1.0 + _get_config().hatch_hit_flash), level, _get_config().hatch_light_fade)
	_shake_visual(strength)
	_burst_gas(roundi(_get_config().gas_amount * strength))
	GameSettings.vibrate(HIT_VIBRATION_MS)


## Rompe la escotilla con animación: ráfaga grande de gas (`break_gas_amount`), fragmentos que
## salen despedidos (`break_debris_count`), destello y las hojas que se abren con rebote (tag
## `break`, 0,41 s). Desde que se llama, [method is_broken] es `true`. Al terminar la apertura emite
## [signal break_finished] y queda en `broken`. Ignorado si ya está rota.
func break_open() -> void:
	if _broken:
		return
	var cfg: IntroConfig = _get_config()
	_broken = true
	GameSettings.vibrate(BREAK_VIBRATION_MS)
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2.ZERO
	_sprite.play(&"break")
	_burst_gas(cfg.break_gas_amount)
	_spawn_debris(cfg.break_debris_count)
	# Pico con la ruptura y después queda el halo rojo que respira, de donde sale el astronauta.
	var peak: Vector3 = Vector3(cfg.hatch_light_energy_break, cfg.hatch_halo_break, cfg.hatch_beam_break)
	_set_levels(peak, 0.04)
	_light_tween.tween_method(_apply_levels, peak, _state_levels(), _sprite.get_tag_duration(&"break") + 0.4)


## Fija el estado final sin animación: [param broken] `true` = rota (hueco rojo que respira),
## `false` = cerrada (y sin golpes acumulados). Lo usa el nivel cuando no hay intro.
func set_broken(broken: bool) -> void:
	_broken = broken
	_hits = 0
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2.ZERO
	_refresh()


## Devuelve true si la escotilla está rota.
func is_broken() -> bool:
	return _broken


## Devuelve la cantidad de golpes recibidos desde que se cerró.
func get_hit_count() -> int:
	return _hits


## Devuelve la posición global del centro superior de la escotilla: de ahí sale el jugador.
func get_launch_position() -> Vector2:
	return global_position + Vector2(0.0, FRAME_TOP)


func _get_config() -> IntroConfig:
	if config == null:
		config = IntroConfig.new()
	return config


func _leaf_half_width() -> float:
	return FRAME_HALF_WIDTH - FRAME_BORDER


# Dos sprites con el mismo cuadro: color con relieve y emisivo (sin sombreado). El de color maneja
# la animación y el emisivo lo sigue. La luz que se escapa es del haz y el halo de Godot.
func _setup_sprites() -> void:
	_sprite.set_sheet_textures(SHEET_DIR + "hatch.png", SHEET_DIR + "hatch_normal.png")
	_emissive.texture = load(SHEET_DIR + "hatch_emissive.png")
	for sprite: Sprite2D in [_sprite, _emissive]:
		sprite.centered = true
		sprite.offset = SPRITE_OFFSET
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.followers = [_emissive]
	_sprite.load_sheet(SHEET_JSON)
	_sprite.finished.connect(_on_sprite_finished)


# Tres luces: la que ilumina el entorno (PointLight2D), un halo rojo visible detrás de la escotilla
# y un haz que se escapa por la rendija hacia arriba (estos dos aditivos y sin sombreado, así la
# nave oscura no los apaga).
func _setup_light() -> void:
	var cfg: IntroConfig = _get_config()
	_light.texture = LevelLighting.get_light_texture(0.6)
	_light.texture_scale = cfg.hatch_light_radius * 2.0 / float(LevelLighting.LIGHT_TEXTURE_SIZE)
	_light.color = cfg.hatch_light_color
	_light.height = cfg.hatch_light_height
	var glow_material: CanvasItemMaterial = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# Halo: detrás de la escotilla (primer hijo dibujado), centrado en la rendija.
	_halo = Sprite2D.new()
	_halo.name = "Halo"
	_halo.texture = LevelLighting.get_light_texture(0.35)
	_halo.scale = cfg.hatch_halo_size / float(LevelLighting.LIGHT_TEXTURE_SIZE)
	_halo.position = Vector2(0.0, FRAME_TOP + 4.0)
	_halo.self_modulate = cfg.hatch_halo_color
	_halo.material = glow_material
	add_child(_halo)
	move_child(_halo, 0)
	# Haz: delante de la escotilla, con la base en la rendija y abriéndose hacia arriba.
	_beam = Sprite2D.new()
	_beam.name = "Beam"
	_beam.texture = _make_beam_texture()
	_beam.centered = false
	var beam_scale: Vector2 = cfg.hatch_beam_size / Vector2(_beam.texture.get_size())
	_beam.scale = beam_scale
	_beam.position = Vector2(-cfg.hatch_beam_size.x * 0.5, FRAME_TOP + 6.0 - cfg.hatch_beam_size.y)
	_beam.self_modulate = cfg.hatch_beam_color
	_beam.material = glow_material
	add_child(_beam)
	move_child(_beam, _visual.get_index() + 1)


# Cono que se abre hacia arriba: angosto y brillante en la base (la rendija), ancho y transparente
# arriba.
static func _make_beam_texture() -> Texture2D:
	var w: int = 64
	var h: int = 128
	var image: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		var t: float = float(y) / float(h - 1)  # 0 arriba, 1 en la base
		var half: float = lerpf(0.5, 0.12, t)
		var vertical: float = pow(t, 1.8)
		for x: int in w:
			var dx: float = absf((float(x) + 0.5) / float(w) - 0.5) / half
			var horizontal: float = clampf(1.0 - dx, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, vertical * horizontal * horizontal))
	return ImageTexture.create_from_image(image)


# Niveles (entorno, halo, haz) del estado actual, sin destellos.
func _state_levels() -> Vector3:
	var cfg: IntroConfig = _get_config()
	if _broken:
		return Vector3(cfg.hatch_light_energy_broken, cfg.hatch_halo_broken, cfg.hatch_beam_broken)
	return Vector3(
		cfg.hatch_light_energy_closed + cfg.hatch_light_energy_per_hit * _hits,
		minf(cfg.hatch_halo_closed + cfg.hatch_halo_per_hit * _hits, 1.0),
		minf(cfg.hatch_beam_per_hit * _hits, 1.0))


# Aplica el estado actual (cerrada / golpeada / rota) sin animación de transición.
func _refresh() -> void:
	var cfg: IntroConfig = _get_config()
	if _broken:
		_sprite.play(&"broken", true)
	elif _hits > 0:
		_sprite.play(StringName("idle_%d" % mini(_hits, MAX_HIT_ANIM)), true)
	else:
		_sprite.play(&"closed", true)
	_set_levels(_state_levels(), 0.0)


# Encadena: golpe → reposo del mismo golpe; ruptura → aviso y escotilla rota.
func _on_sprite_finished(tag: StringName) -> void:
	if String(tag).begins_with("hit_"):
		if not _broken:
			_sprite.play(StringName("idle_%d" % mini(_hits, MAX_HIT_ANIM)), true)
	elif tag == &"break":
		_sprite.play(&"broken", true)
		break_finished.emit()


# Lleva las tres luces a [param levels] (entorno, halo, haz) en [param fade] s (0 = ya). Deja el
# tween en `_light_tween` para encadenar el paso siguiente.
func _set_levels(levels: Vector3, fade: float) -> void:
	if _light_tween != null:
		_light_tween.kill()
	_light_tween = null
	if fade <= 0.0:
		_apply_levels(levels)
		return
	_light_tween = create_tween()
	_light_tween.tween_method(_apply_levels, Vector3(_light_level, _halo_level, _beam_level), levels, fade)


func _apply_levels(levels: Vector3) -> void:
	_light_level = levels.x
	_halo_level = levels.y
	_beam_level = levels.z


func _setup_gas() -> void:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	for gas: CPUParticles2D in _gas_emitters:
		gas.emitting = false
		gas.one_shot = true
		gas.explosiveness = 0.85
		gas.local_coords = false
		gas.position = Vector2(0.0, FRAME_TOP + FRAME_BORDER)
		gas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		gas.emission_rect_extents = Vector2(_leaf_half_width(), 1.0)
		gas.direction = Vector2.UP
		gas.spread = GAS_SPREAD_DEG
		gas.gravity = Vector2.ZERO
		gas.damping_min = 40.0
		gas.damping_max = 70.0
		# Sin escalar: deforma el pixel art. El color ya está en la textura.
		gas.scale_amount_min = 1.0
		gas.scale_amount_max = 1.0
		gas.color = Color.WHITE
		gas.color_ramp = ramp


# Suelta una ráfaga de [param amount] partículas, repartidas entre las tres formas.
func _burst_gas(amount: int) -> void:
	var cfg: IntroConfig = _get_config()
	var total: int = maxi(1, amount)
	var count: int = _gas_emitters.size()
	for index: int in count:
		var gas: CPUParticles2D = _gas_emitters[index]
		var share: int = total / count + (1 if index < total % count else 0)
		if share <= 0:
			continue
		gas.amount = share
		gas.lifetime = cfg.gas_lifetime
		gas.initial_velocity_min = cfg.gas_speed * 0.6
		gas.initial_velocity_max = cfg.gas_speed
		gas.restart()
		gas.emitting = true


func _shake_visual(strength: float) -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2(HIT_SHAKE_PX * strength, -HIT_HOP_PX * strength)
	_shake_tween = create_tween()
	_shake_tween.tween_property(_visual, "position", Vector2.ZERO, HIT_SHAKE_TIME) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Fragmentos de las hojas que salen despedidos hacia arriba y caen fuera de pantalla. Cada uno es
# un cuadro al azar de `hatch_debris`.
func _spawn_debris(count: int) -> void:
	if _debris_texture == null:
		_debris_texture = CanvasTexture.new()
		_debris_texture.diffuse_texture = load(DEBRIS_SHEET)
		if ResourceLoader.exists(DEBRIS_SHEET_NORMAL):
			_debris_texture.normal_texture = load(DEBRIS_SHEET_NORMAL)
		_debris_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i: int in maxi(count, 0):
		var piece := Sprite2D.new()
		piece.texture = _debris_texture
		piece.region_enabled = true
		piece.region_rect = Rect2(0.0, float(randi() % DEBRIS_FRAMES) * DEBRIS_FRAME_SIZE, DEBRIS_FRAME_SIZE, DEBRIS_FRAME_SIZE)
		piece.flip_h = randf() < 0.5
		var origin: Vector2 = Vector2(randf_range(-_leaf_half_width(), _leaf_half_width()), FRAME_TOP)
		piece.position = origin
		add_child(piece)
		var velocity: Vector2 = Vector2.from_angle(randf_range(-PI * 0.85, -PI * 0.15)) * randf_range(DEBRIS_SPEED_MIN, DEBRIS_SPEED_MAX)
		var spin: float = randf_range(-DEBRIS_SPIN, DEBRIS_SPIN)
		var tween: Tween = create_tween()
		tween.tween_method(_move_debris.bind(piece, origin, velocity, spin), 0.0, DEBRIS_LIFETIME, DEBRIS_LIFETIME)
		tween.tween_callback(piece.queue_free)


# Movimiento parabólico de un fragmento en el instante [param t] (s).
func _move_debris(t: float, piece: Node2D, origin: Vector2, velocity: Vector2, spin: float) -> void:
	piece.position = origin + velocity * t + Vector2(0.0, 0.5 * DEBRIS_GRAVITY * t * t)
	piece.rotation = spin * t
