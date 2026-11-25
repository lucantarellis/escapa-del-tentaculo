class_name LevelBackground
extends CanvasLayer
## Fondo del nivel detrás de todo (capa −10): color liso y, según el tier, el pozo de la nave en
## parallax ([ShipBackground]) o el cielo del espacio en capas ([SpaceBackground]). Cada tier
## define el suyo (`SegmentTier`, grupo "Fondo") y [LevelController] lo cambia al entrar al tier
## con un fundido. También dibuja la viñeta de los bordes (capa 6).

## Decorado del espacio (paralaje, desenfoque, planeta, frente). Vacío = valores por defecto de
## [SpaceDecorConfig]. Se muestra con el fondo de estrellas (tier del espacio).
@export var decor: SpaceDecorConfig
## Shader de la viñeta: oscurece los bordes (rojo muy oscuro) y late despacio. `strength` 0–1.
const VIGNETTE_SHADER: String = "shader_type canvas_item;
uniform float strength = 0.0;
uniform float pulse_time = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5, 0.5)) * 1.6;
	float edge = smoothstep(0.55, 1.15, d);
	float beat = 0.5 + 0.5 * sin(pulse_time * 2.2);
	COLOR = vec4(0.09, 0.0, 0.03, edge * strength * (0.78 + 0.22 * beat));
}"
## Viewport lógico del juego (px). Estructural: coincide con `project.godot` (360×640).
const VIEWPORT_SIZE: Vector2 = Vector2(360.0, 640.0)
## Fondo de la nave en parallax (pozo con máquinas). Estructural.
const SHIP_BACKGROUND_SCENE: String = "res://scenes/levels/ShipBackground.tscn"
## Fondo del espacio en capas (nebulosa, planeta, estrellas, rocas del frente). Estructural.
const SPACE_BACKGROUND_SCENE: String = "res://scenes/levels/SpaceBackground.tscn"

var _rect: ColorRect
var _ship: ShipBackground
var _space: SpaceBackground
var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _vignette_strength: float = 0.0
var _tween: Tween


func _ready() -> void:
	layer = -10
	if decor == null:
		decor = SpaceDecorConfig.new()
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.size = VIEWPORT_SIZE
	_rect.color = Color("10141F")
	add_child(_rect)
	_ship = (load(SHIP_BACKGROUND_SCENE) as PackedScene).instantiate() as ShipBackground
	add_child(_ship)
	_ship.set_shown(false, 0.0)
	_space = (load(SPACE_BACKGROUND_SCENE) as PackedScene).instantiate() as SpaceBackground
	_space.config = decor
	add_child(_space)
	_space.set_shown(false, 0.0)
	# Viñeta: capa propia sobre el mundo y bajo el HUD.
	var vignette_layer: CanvasLayer = CanvasLayer.new()
	vignette_layer.layer = 6
	add_child(vignette_layer)
	var shader: Shader = Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = shader
	_vignette_rect = ColorRect.new()
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_rect.size = VIEWPORT_SIZE
	_vignette_rect.material = _vignette_mat
	_vignette_rect.visible = false
	vignette_layer.add_child(_vignette_rect)


func _process(_delta: float) -> void:
	if _vignette_strength > 0.0:
		_vignette_mat.set_shader_parameter("pulse_time", Time.get_ticks_msec() / 1000.0)


## Cambia el fondo a [param color], con o sin el cielo del espacio ([param stars]), con o sin el
## pozo de la nave ([param ship]) y con viñeta de intensidad [param vignette], con un fundido de
## [param fade] s (0 = ya).
func apply_style(color: Color, stars: bool, fade: float, vignette: float = 0.0, ship: bool = false) -> void:
	if _tween != null:
		_tween.kill()
	_ship.set_shown(ship, fade)
	_space.set_shown(stars, fade)
	_vignette_rect.visible = true
	_vignette_strength = vignette
	if fade <= 0.0:
		_rect.color = color
		_vignette_mat.set_shader_parameter("strength", vignette)
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_rect, "color", color, fade)
	_tween.tween_property(_vignette_mat, "shader_parameter/strength", vignette, fade)
