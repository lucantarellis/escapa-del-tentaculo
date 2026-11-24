class_name LevelLighting
extends CanvasModulate
## Oscuridad del nivel: multiplica el mundo por `LightingConfig.ambient_color` en los tiers oscuros
## (`SegmentTier.dark_ambient`, hoy la nave) y vuelve a blanco en los demás, con fundido. El fondo,
## el HUD y los menús viven en otras capas y no se oscurecen; las capas emisivas (sin sombreado)
## tampoco. También arma las luces (`PointLight2D`) que usan el jugador, las paredes, las
## plataformas y los recogibles ([method make_light]). Ver `docs/mecanicas/iluminacion.md`.

## Config compartida por todas las luces. Estructural.
const CONFIG_PATH: String = "res://resources/configs/lighting_config.tres"
## Lado de la textura radial de las luces. Estructural. Unidad: px.
const LIGHT_TEXTURE_SIZE: int = 128

static var _config: LightingConfig
## Luz que queda a mitad del radio en las luces comunes. Estructural.
const DEFAULT_CORE: float = 0.45
## Grupo de todas las luces hechas con [method make_light]: el astronauta las recorre para teñirse.
const LIGHT_GROUP: StringName = &"env_lights"

static var _light_textures: Dictionary = {}

var _tween: Tween
## Color de base (sin titileo) y multiplicador de titileo (1 = sin efecto): el color final es la
## base por el multiplicador. Los usa la intro de la escotilla ([method set_lit], [method flicker]).
var _base: Color = Color.WHITE
var _flicker_level: float = 1.0
var _flicker_tween: Tween


func _ready() -> void:
	color = Color.WHITE


# Los tweens son del árbol (corren con el nivel en pausa): al salir se cancelan para que no llamen a
# un nodo liberado.
func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()
	if _flicker_tween != null:
		_flicker_tween.kill()


## Oscurece ([param dark] `true`) o aclara el mundo en [param fade] s (0 = ya).
func set_dark(dark: bool, fade: float) -> void:
	_fade_to(get_config().ambient_color if dark else Color.WHITE, fade)


## Pone el mundo con la luz de la nave encendida ([param lit_color], como el hub) de golpe. Es el
## arranque de la intro de la escotilla: después los golpes la desestabilizan ([method flicker]) y la
## ruptura la apaga ([method power_off]).
func set_lit(lit_color: Color) -> void:
	_stop_flicker()
	_fade_to(lit_color, 0.0)


## Lleva el color de base a [param target] en [param fade] s (0 = ya), sin tocar el titileo.
func fade_base(target: Color, fade: float) -> void:
	_fade_to(target, fade)


## Corte de luz: el mundo pasa a la oscuridad de la nave en [param fade] s y se cancela el titileo.
func power_off(fade: float) -> void:
	_stop_flicker()
	_fade_to(get_config().ambient_color, fade)


## Titileo de la luz durante [param duration] s: la luz cae a [param depth] (0–1, 1 = se apaga del
## todo) en cambios bruscos al azar, separados [param step_min]–[param step_max] s, y al final
## vuelve a la normal. Corre aunque el nivel esté en pausa (la intro).
func flicker(depth: float, duration: float, step_min: float, step_max: float) -> void:
	_stop_flicker()
	_flicker_tween = get_tree().create_tween()
	_flicker_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var elapsed: float = 0.0
	while elapsed < duration:
		var step: float = randf_range(step_min, step_max)
		var level: float = 1.0 - depth * (1.0 if randf() < 0.5 else randf_range(0.3, 0.8))
		_flicker_tween.tween_callback(_set_flicker.bind(level))
		_flicker_tween.tween_interval(step)
		elapsed += step
	_flicker_tween.tween_callback(_set_flicker.bind(1.0))


func _fade_to(target: Color, fade: float) -> void:
	if _tween != null:
		_tween.kill()
	if fade <= 0.0:
		_base = target
		_apply()
		return
	_tween = get_tree().create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_set_base, _base, target, fade)


func _set_base(value: Color) -> void:
	_base = value
	_apply()


func _set_flicker(level: float) -> void:
	_flicker_level = level
	_apply()


func _stop_flicker() -> void:
	if _flicker_tween != null:
		_flicker_tween.kill()
		_flicker_tween = null
	_flicker_level = 1.0
	_apply()


func _apply() -> void:
	color = Color(_base.r * _flicker_level, _base.g * _flicker_level, _base.b * _flicker_level, _base.a)


## Config de iluminación (se carga una vez).
static func get_config() -> LightingConfig:
	if _config == null:
		_config = load(CONFIG_PATH) as LightingConfig
		if _config == null:
			_config = LightingConfig.new()
	return _config


## Crea una luz puntual suave (sin sombras) de [param light_color], [param energy] y radio
## [param radius] px. [param height] < 0 usa `light_height` de la config; [param core] es cuánta luz
## queda a mitad del radio (0–1). Quien la crea la agrega como hija.
static func make_light(light_color: Color, energy: float, radius: float, height: float = -1.0, core: float = DEFAULT_CORE) -> PointLight2D:
	var light: PointLight2D = PointLight2D.new()
	light.name = "Light"
	light.texture = get_light_texture(core)
	light.texture_scale = radius * 2.0 / float(LIGHT_TEXTURE_SIZE)
	light.color = light_color
	light.energy = energy
	light.height = get_config().light_height if height < 0.0 else height
	light.add_to_group(LIGHT_GROUP)
	return light


## Textura radial de las luces: 1 en el centro, [param core] a mitad del radio y 0 en el borde. Se
## arma una vez por valor de [param core].
static func get_light_texture(core: float = DEFAULT_CORE) -> Texture2D:
	var key: int = roundi(core * 100.0)
	if _light_textures.has(key):
		return _light_textures[key]
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.5, Color(1.0, 1.0, 1.0, clampf(core, 0.0, 1.0)))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	_light_textures[key] = texture
	return texture
