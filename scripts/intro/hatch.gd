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

## Blanco azulado con alfa: gas. Solo visual.
const COLOR_GAS: Color = Color(0.784, 0.906, 0.918, 0.55)
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
## Tamaño de las partículas de gas (sin textura). Solo visual. Unidad: px.
const GAS_PARTICLE_SIZE: float = 5.0
## Lado de la textura radial de la luz roja. Estructural. Unidad: px.
const LIGHT_TEXTURE_SIZE: int = 128

## Se emite cuando termina la animación de apertura de [method break_open].
signal break_finished

## Parámetros de la intro (gas). Lo asigna [LevelController]; si queda vacío se usan los valores
## por defecto de [IntroConfig].
@export var config: IntroConfig

@onready var _visual: Node2D = $Visual
@onready var _sprite: SheetSprite = $Visual/Sprite
@onready var _emissive: Sprite2D = $Visual/Emissive
@onready var _glow: Sprite2D = $Visual/Glow
@onready var _light: PointLight2D = $Light
@onready var _gas: CPUParticles2D = $GasParticles

var _hits: int = 0
var _broken: bool = false
var _shake_tween: Tween
var _light_tween: Tween
var _debris_texture: CanvasTexture


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_sprites()
	_setup_light()
	_setup_gas()
	_refresh()


## Golpe: sacude la escotilla, la abomba un poco más, intensifica el brillo y suelta una ráfaga
## de gas. [param strength] es el multiplicador de intensidad (1 = golpe base). Ignorado si la
## escotilla ya está rota.
func hit(strength: float) -> void:
	if _broken:
		return
	_hits += 1
	_sprite.play(StringName("hit_%d" % mini(_hits, MAX_HIT_ANIM)))
	_set_light(_get_config().hatch_light_energy_closed + _get_config().hatch_light_energy_per_hit * _hits)
	_shake_visual(strength)
	_burst_gas(roundi(_get_config().gas_amount * strength))


## Rompe la escotilla con animación: ráfaga grande de gas (`break_gas_amount`), fragmentos que
## salen despedidos (`break_debris_count`), destello y las hojas que se abren con rebote (tag
## `break`, 0,41 s). Desde que se llama, [method is_broken] es `true`. Al terminar la apertura emite
## [signal break_finished] y queda en `broken`. Ignorado si ya está rota.
func break_open() -> void:
	if _broken:
		return
	var cfg: IntroConfig = _get_config()
	_broken = true
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2.ZERO
	_sprite.play(&"break")
	_burst_gas(cfg.break_gas_amount)
	_spawn_debris(cfg.break_debris_count)
	# Pico de luz con la ruptura y después baja a la luz media de la escotilla rota.
	_set_light(cfg.hatch_light_energy_break, 0.04)
	_light_tween.tween_property(_light, "energy", cfg.hatch_light_energy_broken, _sprite.get_tag_duration(&"break") + 0.2)


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


# Tres sprites con el mismo cuadro: color con relieve, emisivo (sin sombreado) y resplandor (sin
# sombreado, aditivo). El de color maneja la animación y los otros dos lo siguen.
func _setup_sprites() -> void:
	_sprite.set_sheet_textures(SHEET_DIR + "hatch.png", SHEET_DIR + "hatch_normal.png")
	_emissive.texture = load(SHEET_DIR + "hatch_emissive.png")
	_glow.texture = load(SHEET_DIR + "hatch_glow.png")
	for sprite: Sprite2D in [_sprite, _emissive, _glow]:
		sprite.centered = true
		sprite.offset = SPRITE_OFFSET
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.followers = [_emissive, _glow]
	_sprite.load_sheet(SHEET_JSON)
	_sprite.finished.connect(_on_sprite_finished)


# Luz roja que sale de la escotilla e ilumina al astronauta, el piso y las paredes.
func _setup_light() -> void:
	var cfg: IntroConfig = _get_config()
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	_light.texture = texture
	_light.texture_scale = cfg.hatch_light_radius * 2.0 / float(LIGHT_TEXTURE_SIZE)
	_light.color = cfg.hatch_light_color
	# Con relieve en las texturas, una luz sin altura casi no ilumina lo plano (ver LightingConfig).
	_light.height = LevelLighting.get_config().light_height


# Aplica el estado actual (cerrada / golpeada / rota) sin animación de transición.
func _refresh() -> void:
	var cfg: IntroConfig = _get_config()
	if _broken:
		_sprite.play(&"broken", true)
		_set_light(cfg.hatch_light_energy_broken, 0.0)
	elif _hits > 0:
		_sprite.play(StringName("idle_%d" % mini(_hits, MAX_HIT_ANIM)), true)
		_set_light(cfg.hatch_light_energy_closed + cfg.hatch_light_energy_per_hit * _hits, 0.0)
	else:
		_sprite.play(&"closed", true)
		_set_light(cfg.hatch_light_energy_closed, 0.0)


# Encadena: golpe → reposo del mismo golpe; ruptura → aviso y escotilla rota.
func _on_sprite_finished(tag: StringName) -> void:
	if String(tag).begins_with("hit_"):
		if not _broken:
			_sprite.play(StringName("idle_%d" % mini(_hits, MAX_HIT_ANIM)), true)
	elif tag == &"break":
		_sprite.play(&"broken", true)
		break_finished.emit()


# Lleva la energía de la luz a [param energy] en [param fade] s (por defecto, `hatch_light_fade`).
func _set_light(energy: float, fade: float = -1.0) -> void:
	if _light_tween != null:
		_light_tween.kill()
	var duration: float = _get_config().hatch_light_fade if fade < 0.0 else fade
	if duration <= 0.0:
		_light.energy = energy
		_light_tween = null
		return
	_light_tween = create_tween()
	_light_tween.tween_property(_light, "energy", energy, duration)


func _setup_gas() -> void:
	_gas.emitting = false
	_gas.one_shot = true
	_gas.explosiveness = 0.85
	_gas.local_coords = false
	_gas.position = Vector2(0.0, FRAME_TOP + FRAME_BORDER)
	_gas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_gas.emission_rect_extents = Vector2(_leaf_half_width(), 1.0)
	_gas.direction = Vector2.UP
	_gas.spread = GAS_SPREAD_DEG
	_gas.gravity = Vector2.ZERO
	_gas.damping_min = 40.0
	_gas.damping_max = 70.0
	_gas.scale_amount_min = GAS_PARTICLE_SIZE * 0.6
	_gas.scale_amount_max = GAS_PARTICLE_SIZE
	_gas.color = COLOR_GAS
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	_gas.color_ramp = ramp


# Suelta una ráfaga de [param amount] partículas.
func _burst_gas(amount: int) -> void:
	var cfg: IntroConfig = _get_config()
	_gas.amount = maxi(1, amount)
	_gas.lifetime = cfg.gas_lifetime
	_gas.initial_velocity_min = cfg.gas_speed * 0.6
	_gas.initial_velocity_max = cfg.gas_speed
	_gas.restart()
	_gas.emitting = true


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
