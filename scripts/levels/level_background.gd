class_name LevelBackground
extends CanvasLayer
## Fondo del nivel detrás de todo (capa −10): color liso y, opcionalmente, un campo de estrellas
## con parallax. Cada tier define el suyo (`SegmentTier`, grupo "Fondo") y [LevelController] lo
## cambia al entrar al tier con un fundido. Placeholder hasta el arte final.

## Decorado del espacio (capas, planeta, frente desenfocado). Vacío = valores por defecto de
## [SpaceDecorConfig]. Se muestra con las estrellas (tier del espacio).
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

var _rect: ColorRect
var _stars: Node2D
var _front_layer: CanvasLayer
var _front: Node2D
var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _vignette_strength: float = 0.0
var _far: PackedVector3Array = PackedVector3Array()
var _near: PackedVector3Array = PackedVector3Array()
var _nebulae: Array[Vector3] = []
var _front_objs: Array[Dictionary] = []
var _stars_alpha: float = 0.0
var _tween: Tween
var _time: float = 0.0
var _shoot_wait: float = 4.0
var _shoot_t: float = -1.0
var _shoot_from: Vector2 = Vector2.ZERO
var _shoot_dir: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	layer = -10
	if decor == null:
		decor = SpaceDecorConfig.new()
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.size = VIEWPORT_SIZE
	_rect.color = Color("10141F")
	add_child(_rect)
	_stars = Node2D.new()
	_stars.draw.connect(_draw_back)
	add_child(_stars)
	# Frente: capa propia entre el mundo y el HUD (80), así queda delante del jugador.
	_front_layer = CanvasLayer.new()
	_front_layer.layer = 5
	add_child(_front_layer)
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	_front_layer.add_child(_front)
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
	_rng.seed = 1234
	for i: int in decor.far_star_count:
		_far.append(Vector3(_rng.randf() * VIEWPORT_SIZE.x, _rng.randf() * VIEWPORT_SIZE.y, _rng.randf_range(0.25, 0.6)))
	for i: int in decor.near_star_count:
		_near.append(Vector3(_rng.randf() * VIEWPORT_SIZE.x, _rng.randf() * VIEWPORT_SIZE.y, _rng.randf_range(0.5, 1.0)))
	for i: int in decor.nebula_count:
		# x, y virtual, radio
		_nebulae.append(Vector3(_rng.randf_range(40.0, 320.0), _rng.randf_range(0.0, 900.0), _rng.randf_range(110.0, 190.0)))
	for i: int in decor.foreground_count:
		var left: bool = i % 2 == 0
		_front_objs.append({
			"x": _rng.randf_range(-10.0, 40.0) if left else _rng.randf_range(320.0, 370.0),
			"y": _rng.randf() * decor.foreground_loop,
			"size": _rng.randf_range(34.0, 70.0),
			"rot": _rng.randf() * TAU,
			"spin": _rng.randf_range(-0.25, 0.25),
			"scrap": i % 3 == 2,
		})


func _process(delta: float) -> void:
	if _vignette_strength > 0.0:
		_vignette_mat.set_shader_parameter("pulse_time", Time.get_ticks_msec() / 1000.0)
	if _stars_alpha <= 0.0:
		return
	_time += delta
	_update_shooting(delta)
	_stars.queue_redraw()
	_front.queue_redraw()


## Cambia el fondo a [param color], con o sin estrellas y con viñeta de intensidad [param vignette], con un fundido de [param fade] s (0 = ya).
func apply_style(color: Color, stars: bool, fade: float, vignette: float = 0.0) -> void:
	if _tween != null:
		_tween.kill()
	_vignette_rect.visible = true
	_vignette_strength = vignette
	var target_alpha: float = 1.0 if stars else 0.0
	if fade <= 0.0:
		_rect.color = color
		_stars_alpha = target_alpha
		_vignette_mat.set_shader_parameter("strength", vignette)
		_stars.queue_redraw()
		_front.queue_redraw()
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_rect, "color", color, fade)
	_tween.tween_property(self, "_stars_alpha", target_alpha, fade)
	_tween.tween_property(_vignette_mat, "shader_parameter/strength", vignette, fade)


func _camera_y() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	return camera.global_position.y if camera != null else 0.0


func _update_shooting(delta: float) -> void:
	if decor.shooting_max_interval <= 0.0:
		return
	if _shoot_t >= 0.0:
		_shoot_t += delta
		if _shoot_t > 0.7:
			_shoot_t = -1.0
			_shoot_wait = _rng.randf_range(decor.shooting_min_interval, decor.shooting_max_interval)
		return
	_shoot_wait -= delta
	if _shoot_wait <= 0.0:
		_shoot_t = 0.0
		# En los costados, lejos del centro, para no confundirse con un aviso de meteoro.
		_shoot_from = Vector2(_rng.randf_range(20.0, 110.0) if _rng.randf() < 0.5 else _rng.randf_range(250.0, 340.0), _rng.randf_range(40.0, 300.0))
		_shoot_dir = Vector2(_rng.randf_range(-0.5, 0.5), 1.0).normalized()


func _draw_back() -> void:
	if _stars_alpha <= 0.0:
		return
	var cam_y: float = _camera_y()
	_draw_nebulae(cam_y)
	_draw_planet(cam_y)
	_draw_star_plane(_far, cam_y * decor.far_parallax, false)
	_draw_star_plane(_near, cam_y * decor.near_parallax, true)
	if _shoot_t >= 0.0:
		var k: float = _shoot_t / 0.7
		var head: Vector2 = _shoot_from + _shoot_dir * (k * 160.0)
		var tail: Vector2 = head - _shoot_dir * 28.0
		_stars.draw_line(tail, head, Color(0.78, 0.91, 0.92, 0.35 * (1.0 - k) * _stars_alpha), 1.0)


func _draw_star_plane(points: PackedVector3Array, offset: float, twinkle: bool) -> void:
	for i: int in points.size():
		var star: Vector3 = points[i]
		var y: float = fposmod(star.y - offset, VIEWPORT_SIZE.y)
		var a: float = star.z
		if twinkle and i % 3 == 0:
			a *= 0.65 + 0.35 * sin(_time * decor.twinkle_speed + float(i))
		var size: float = 1.0 if (star.z < 0.75 or not twinkle) else 2.0
		_stars.draw_rect(Rect2(star.x, y, size, size), Color(0.7843, 0.9059, 0.9176, a * _stars_alpha))


func _draw_nebulae(cam_y: float) -> void:
	var off: float = cam_y * decor.nebula_parallax
	for i: int in _nebulae.size():
		var n: Vector3 = _nebulae[i]
		var y: float = fposmod(n.y - off + 200.0, 1100.0) - 230.0
		var col: Color = decor.nebula_colors[i % decor.nebula_colors.size()]
		# Manchas suaves: círculos concéntricos de poca opacidad.
		for step: int in 10:
			var r: float = n.z * (1.0 - float(step) * 0.09)
			_stars.draw_circle(Vector2(n.x, y), r, Color(col.r, col.g, col.b, decor.nebula_alpha * 0.3 * _stars_alpha))


func _draw_planet(cam_y: float) -> void:
	var r: float = decor.planet_radius
	var y: float = fposmod(-cam_y * decor.planet_parallax + 120.0, decor.planet_loop) - r * 2.5
	var c: Vector2 = Vector2(262.0, y)
	if y < -r * 2.5 or y > VIEWPORT_SIZE.y + r * 2.5:
		return
	var al: float = _stars_alpha
	var base: Color = decor.planet_color
	# Anillo, mitad de atrás.
	_stars.draw_set_transform(c, -0.35, Vector2(1.0, 0.28))
	_stars.draw_arc(Vector2.ZERO, r * 1.55, PI, TAU, 40, Color(decor.planet_ring_color, 0.55 * al), 5.0)
	_stars.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_stars.draw_circle(c, r, Color(base.r * 0.55, base.g * 0.55, base.b * 0.55, al))
	for step: int in 3:
		var k: float = float(step + 1)
		_stars.draw_circle(c + Vector2(-0.10, -0.10) * r * k * 0.5, r * (1.0 - 0.18 * k * 0.5 - 0.05 * k), Color(base.r * (0.7 + 0.1 * k), base.g * (0.7 + 0.1 * k), base.b * (0.7 + 0.1 * k), al * 0.55))
	# Anillo, mitad de adelante.
	_stars.draw_set_transform(c, -0.35, Vector2(1.0, 0.28))
	_stars.draw_arc(Vector2.ZERO, r * 1.55, 0.0, PI, 40, Color(decor.planet_ring_color, 0.7 * al), 5.0)
	_stars.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Objetos grandes y desenfocados (falso desenfoque: la misma silueta en varias pasadas ampliadas y
# muy transparentes). Solo se ven hacia los costados y se apagan cerca del centro, para no tapar el
# juego.
func _draw_front() -> void:
	if _stars_alpha <= 0.0:
		return
	var off: float = _camera_y() * decor.foreground_parallax
	for o: Dictionary in _front_objs:
		var y: float = fposmod(float(o["y"]) - off, decor.foreground_loop) - 200.0
		if y < -120.0 or y > VIEWPORT_SIZE.y + 120.0:
			continue
		var x: float = float(o["x"])
		var clear: float = smoothstep(decor.foreground_clear_radius, decor.foreground_clear_radius + 70.0, absf(x - 180.0))
		var rot: float = float(o["rot"]) + _time * float(o["spin"])
		var pts: PackedVector2Array = _shape(bool(o["scrap"]), float(o["size"]))
		var col: Color = decor.foreground_color
		for pass_i: int in 5:
			var grow: float = 1.0 + 0.16 * float(pass_i)
			_front.draw_set_transform(Vector2(x, y), rot, Vector2(grow, grow))
			_front.draw_colored_polygon(pts, Color(col.r, col.g, col.b, decor.foreground_alpha * 0.28 * clear * _stars_alpha))
	_front.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _shape(scrap: bool, size: float) -> PackedVector2Array:
	var h: float = size * 0.5
	if scrap:
		return PackedVector2Array([Vector2(-h, -h * 0.4), Vector2(-h * 0.2, -h * 0.5), Vector2(h, -h * 0.3), Vector2(h * 0.8, h * 0.5), Vector2(-h * 0.5, h * 0.4)])
	return PackedVector2Array([Vector2(-h, -h * 0.3), Vector2(-h * 0.4, -h), Vector2(h * 0.5, -h * 0.8), Vector2(h, 0.0), Vector2(h * 0.4, h * 0.9), Vector2(-h * 0.6, h * 0.7)])
