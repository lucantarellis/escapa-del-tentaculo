class_name LevelBackground
extends CanvasLayer
## Fondo del nivel detrás de todo (capa −10): color liso y, opcionalmente, un campo de estrellas
## con parallax. Cada tier define el suyo (`SegmentTier`, grupo "Fondo") y [LevelController] lo
## cambia al entrar al tier con un fundido. Placeholder hasta el arte final.

## Cantidad de estrellas. Solo visual.
const STAR_COUNT: int = 90
## Factor de parallax de las estrellas (0 = fijas en pantalla, 1 = se mueven con el mundo).
const STAR_PARALLAX: float = 0.15
## Viewport lógico del juego (px). Estructural: coincide con `project.godot` (360×640).
const VIEWPORT_SIZE: Vector2 = Vector2(360.0, 640.0)

var _rect: ColorRect
var _stars: Node2D
var _star_points: PackedVector3Array = PackedVector3Array()
var _stars_alpha: float = 0.0
var _tween: Tween


func _ready() -> void:
	layer = -10
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.size = VIEWPORT_SIZE
	_rect.color = Color("10141F")
	add_child(_rect)
	_stars = Node2D.new()
	_stars.draw.connect(_draw_stars)
	add_child(_stars)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	for i: int in STAR_COUNT:
		# x, y en pantalla y brillo
		_star_points.append(Vector3(rng.randf() * VIEWPORT_SIZE.x, rng.randf() * VIEWPORT_SIZE.y, rng.randf_range(0.3, 1.0)))


func _process(_delta: float) -> void:
	if _stars_alpha > 0.0:
		_stars.queue_redraw()


## Cambia el fondo a [param color], con o sin estrellas, con un fundido de [param fade] s (0 = ya).
func apply_style(color: Color, stars: bool, fade: float) -> void:
	if _tween != null:
		_tween.kill()
	var target_alpha: float = 1.0 if stars else 0.0
	if fade <= 0.0:
		_rect.color = color
		_stars_alpha = target_alpha
		_stars.queue_redraw()
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_rect, "color", color, fade)
	_tween.tween_property(self, "_stars_alpha", target_alpha, fade)


func _draw_stars() -> void:
	if _stars_alpha <= 0.0:
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	var offset_y: float = camera.global_position.y * STAR_PARALLAX if camera != null else 0.0
	for star: Vector3 in _star_points:
		var y: float = fposmod(star.y - offset_y, VIEWPORT_SIZE.y)
		var size: float = 1.0 if star.z < 0.75 else 2.0
		_stars.draw_rect(Rect2(star.x, y, size, size), Color(0.7843, 0.9059, 0.9176, star.z * _stars_alpha))
