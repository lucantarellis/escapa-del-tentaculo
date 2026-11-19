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

static var _light_textures: Dictionary = {}

var _tween: Tween


func _ready() -> void:
	color = Color.WHITE


## Oscurece ([param dark] `true`) o aclara el mundo en [param fade] s (0 = ya).
func set_dark(dark: bool, fade: float) -> void:
	if _tween != null:
		_tween.kill()
	var target: Color = get_config().ambient_color if dark else Color.WHITE
	if fade <= 0.0:
		color = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "color", target, fade)


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
