@tool
class_name FleshMembrane
extends Area2D
## Membrana de carne del tentáculo del alien, al final del espacio (tier 2). Es la punta del
## tentáculo, cerrando la boca del embudo de carne. Tiene dos partes:
## 1. **Anticipo**: el tentáculo (dibujado con polígonos, sin colisión ni daño) entra por un
##    costado (sorteado por partida) a `approach_distance` px antes de la membrana, sube más rápido
##    que la cámara, se adelanta al jugador y se posa sobre la membrana.
## 2. **Rotura**: al tocarla el jugador, la carne se rompe: instante congelado, cámara lenta,
##    sacudida, destello rojizo, colgajos que salen despedidos y salpicadura de trozos de carne.
##    El jugador conserva su velocidad y sigue hacia el tier 3 (la rotura nunca lo frena).
## El origen del nodo es el centro de la membrana (la punta del tentáculo). Placeholders con
## polígonos. Ver `docs/mecanicas/tier-espacio.md`.

## Emitida al tocar la membrana, justo antes de romperse (gancho para el sonido del golpe).
signal membrane_hit
## Emitida cuando la carne ya se desgarró (gancho para el sonido del desgarro).
signal broken

## Carne del tentáculo (la del tier 3). Solo visual.
const FLESH_COLOR: Color = Color("6E2A3A")
## Carne clara del borde y de la membrana. Solo visual.
const FLESH_LIGHT: Color = Color("9A3F55")
## Carne oscura de las ventosas y del interior. Solo visual.
const FLESH_DARK: Color = Color("3A1220")
## Latidos por segundo (como la viñeta). Solo visual.
const BEAT_RATE: float = 2.2
## Puntos con los que se dibuja el cuerpo del tentáculo. Solo visual.
const BODY_POINTS: int = 24

@export_group("Anticipo")
## Distancia antes de la membrana desde la que el tentáculo empieza a entrar. Unidad: px.
@export var approach_distance: float = 1100.0
## Ancho del tentáculo en la base y en la punta. Unidad: px.
@export var width_base: float = 120.0
@export var width_tip: float = 96.0
## Si es true, el costado por el que entra se sortea por partida; si es false, siempre entra por
## `side` (−1 izquierda, 1 derecha).
@export var random_side: bool = true
@export_range(-1, 1, 2) var side: int = 1

@export_group("Membrana")
## Ancho de la membrana (cubre la boca del embudo). Unidad: px.
@export var membrane_width: float = 132.0:
	set(value):
		membrane_width = value
		queue_redraw()
## Alto de la membrana (cuánto se hincha hacia el jugador). Unidad: px.
@export var membrane_bulge: float = 46.0

@export_group("Rotura")
## Instante congelado al tocarla, en tiempo real. Unidad: s.
@export var freeze_time: float = 0.06
## Escala de tiempo de la cámara lenta tras el golpe y su duración (en tiempo real).
@export_range(0.05, 1.0, 0.05) var slow_scale: float = 0.3
@export var slow_time: float = 0.3
## Sacudida de cámara: amplitud (px) y duración (s).
@export var shake_amplitude: float = 16.0
@export var shake_duration: float = 0.6
## Destello rojizo: color y opacidad máxima.
@export var flash_color: Color = Color(0.75, 0.1, 0.2, 1.0)
@export_range(0.0, 1.0, 0.05) var flash_alpha: float = 0.5
## Trozos de carne de la salpicadura.
@export var splatter_count: int = 28

var _broken: bool = false
var _clock: float = 0.0
var _side: int = 1


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_side = side
	if random_side:
		_side = 1 if randf() < 0.5 else -1
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(membrane_width, membrane_bulge * 0.6)
	shape.shape = rect
	shape.position = Vector2(0.0, membrane_bulge * 0.3)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _exit_tree() -> void:
	# Si el nivel se descarga en plena cámara lenta (R), no dejar el juego lento.
	if _broken:
		Engine.time_scale = 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _broken or not (body is Player):
		return
	var player: Player = body as Player
	if not player.is_alive():
		return
	_break()


func _break() -> void:
	_broken = true
	membrane_hit.emit()
	set_deferred("monitoring", false)
	_spawn_flaps()
	_spawn_splatter()
	_play_flash()
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null:
		camera.shake(shake_amplitude, shake_duration)
	broken.emit()
	_play_time_effect()


# Instante congelado y cámara lenta medidos en tiempo real (el temporizador ignora la escala).
func _play_time_effect() -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(freeze_time, true, false, true).timeout
	Engine.time_scale = slow_scale
	await get_tree().create_timer(slow_time, true, false, true).timeout
	Engine.time_scale = 1.0


func _play_flash() -> void:
	if flash_alpha <= 0.0:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 85
	add_child(layer)
	var rect: ColorRect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(flash_color, flash_alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


# Cuatro colgajos triangulares de la membrana que salen despedidos girando.
func _spawn_flaps() -> void:
	var hw: float = membrane_width * 0.5
	var corners: Array[Vector2] = [Vector2(-hw, 0.0), Vector2(0.0, -4.0), Vector2(hw, 0.0), Vector2(0.0, membrane_bulge)]
	for i: int in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var flap: Polygon2D = Polygon2D.new()
		flap.polygon = PackedVector2Array([Vector2(0.0, membrane_bulge * 0.35), a, b])
		flap.color = FLESH_LIGHT if i % 2 == 0 else FLESH_COLOR
		flap.z_index = 6
		add_child(flap)
		var out: Vector2 = ((a + b) * 0.5 - Vector2(0.0, membrane_bulge * 0.35)).normalized()
		if out == Vector2.ZERO:
			out = Vector2.UP
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(flap, "position", out * 150.0 + Vector2(0.0, -60.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(flap, "rotation", randf_range(-2.5, 2.5), 0.9)
		tween.tween_property(flap, "modulate:a", 0.0, 0.9)
		tween.chain().tween_callback(flap.queue_free)


# Salpicadura de trozos de carne hacia arriba y a los costados (en el sentido en que avanza el
# jugador), que se apagan en ~1 s.
func _spawn_splatter() -> void:
	for i: int in splatter_count:
		var chunk: Polygon2D = Polygon2D.new()
		var r: float = randf_range(3.0, 9.0)
		var pts: PackedVector2Array = PackedVector2Array()
		for k: int in 5:
			var ang: float = TAU * float(k) / 5.0 + randf_range(-0.3, 0.3)
			pts.append(Vector2(cos(ang), sin(ang)) * r * randf_range(0.6, 1.0))
		chunk.polygon = pts
		chunk.color = [FLESH_COLOR, FLESH_LIGHT, FLESH_DARK, Color("C04058")][randi() % 4]
		chunk.position = Vector2(randf_range(-membrane_width * 0.4, membrane_width * 0.4), randf_range(0.0, membrane_bulge))
		chunk.z_index = 6
		add_child(chunk)
		var dir: Vector2 = Vector2.UP.rotated(randf_range(-1.3, 1.3))
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(chunk, "position", chunk.position + dir * randf_range(90.0, 300.0), randf_range(0.7, 1.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chunk, "rotation", randf_range(-6.0, 6.0), 1.0)
		tween.tween_property(chunk, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(chunk.queue_free)


# Avance del anticipo (0–1): 0 = el tentáculo todavía no entró, 1 = posado sobre la membrana.
func _approach() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return 1.0
	var dist: float = camera.global_position.y - global_position.y
	return smoothstep(0.0, 1.0, clampf((approach_distance + 340.0 - dist) / approach_distance, 0.0, 1.0))


func _draw() -> void:
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BEAT_RATE)
	if Engine.is_editor_hint():
		_draw_membrane(0.0)
		return
	var e: float = _approach()
	if e <= 0.0:
		return
	_draw_body(e, beat)
	if not _broken:
		_draw_membrane(beat)


# Cuerpo del tentáculo: una curva desde la base (fuera de pantalla, al costado) hasta la punta.
func _draw_body(e: float, beat: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var cam_y: float = camera.global_position.y if camera != null else global_position.y + 320.0
	var tip_start: Vector2 = to_local(Vector2(180.0 + float(_side) * 215.0, cam_y + 160.0))
	var base_start: Vector2 = to_local(Vector2(180.0 + float(_side) * 360.0, cam_y + 760.0))
	var base_end: Vector2 = Vector2(float(_side) * 300.0, 620.0)
	var tip: Vector2 = tip_start.lerp(Vector2.ZERO, e * e)
	tip.y = lerpf(tip_start.y, 0.0, e)
	var base: Vector2 = base_start.lerp(base_end, e)
	var sway: float = sin(_clock * 1.6) * 24.0
	var ctrl: Vector2 = (tip + base) * 0.5 + Vector2(-float(_side) * 70.0 + sway, -60.0)
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	var centre: PackedVector2Array = PackedVector2Array()
	for i: int in BODY_POINTS:
		var u: float = float(i) / float(BODY_POINTS - 1)
		var p: Vector2 = tip * (1.0 - u) * (1.0 - u) + ctrl * 2.0 * (1.0 - u) * u + base * u * u
		var tangent: Vector2 = (ctrl - tip) * 2.0 * (1.0 - u) + (base - ctrl) * 2.0 * u
		var n: Vector2 = tangent.normalized().orthogonal()
		var w: float = lerpf(width_tip, width_base, u) * 0.5 * (1.0 + 0.04 * beat)
		left.append(p + n * w)
		right.append(p - n * w)
		centre.append(p)
	for i: int in BODY_POINTS - 1:
		var col: Color = FLESH_COLOR if i % 2 == 0 else FLESH_COLOR.lightened(0.06)
		draw_colored_polygon(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]), col)
	draw_polyline(left, FLESH_LIGHT, 3.0)
	draw_polyline(right, FLESH_LIGHT, 3.0)
	# Ventosas a lo largo del cuerpo.
	for i: int in range(2, BODY_POINTS - 1, 3):
		draw_circle(centre[i], 5.0, FLESH_DARK)
		draw_circle(centre[i], 2.5, FLESH_LIGHT)


# Membrana: domo de carne que se hincha hacia el jugador (hacia abajo), con venas y un latido.
func _draw_membrane(beat: float) -> void:
	var hw: float = membrane_width * 0.5
	var bulge: float = membrane_bulge * (1.0 + 0.05 * beat)
	var dome: PackedVector2Array = PackedVector2Array()
	for i: int in 17:
		var a: float = PI * float(i) / 16.0
		dome.append(Vector2(-cos(a) * hw, sin(a) * bulge))
	draw_colored_polygon(dome, FLESH_COLOR)
	var inner: PackedVector2Array = PackedVector2Array()
	for i: int in 17:
		var a: float = PI * float(i) / 16.0
		inner.append(Vector2(-cos(a) * hw * 0.72, sin(a) * bulge * 0.68))
	draw_colored_polygon(inner, FLESH_LIGHT.lerp(FLESH_COLOR, 0.35))
	draw_polyline(dome, FLESH_LIGHT, 3.0)
	# Venas: líneas que salen del centro.
	for k: int in 7:
		var a: float = PI * (float(k) + 0.5) / 7.0
		var end: Vector2 = Vector2(-cos(a) * hw * 0.85, sin(a) * bulge * 0.85)
		draw_line(Vector2(0.0, bulge * 0.3), end, Color(FLESH_DARK, 0.7), 2.0)
