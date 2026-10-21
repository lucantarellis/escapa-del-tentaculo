@tool
class_name FleshMembrane
extends Area2D
## Tentáculo del alien que cierra el paso al final del espacio (tier 2): hace de "ventanal" de esta
## transición. Un tentáculo de carne **vertical** baja desde arriba y queda latiendo y ondulando,
## con la **punta** hacia el jugador, tapando el único hueco de una masa de carne (capa `Limb` del
## segmento). El jugador entra **por la punta**: al tocarla, estalla con un **estallido de sangre**
## (instante congelado, cámara lenta, sacudida, destello rojo, trozos de la punta y gotas) y queda
## abierto el interior del tentáculo, por donde el jugador sigue hacia el tier 3 con su velocidad
## (la rotura nunca lo frena). El origen del nodo es el extremo de la punta; el cuerpo sube desde
## ahí (y negativa). Baja desde arriba mientras la cámara se acerca (`approach_distance`).
## Placeholders con polígonos. Ver `docs/mecanicas/tier-espacio.md`.

## Emitida al tocar el tentáculo, justo antes de romperse (gancho para el sonido del golpe).
signal membrane_hit
## Emitida cuando el tentáculo ya se rompió (gancho para el sonido del desgarro).
signal broken

## Carne del tentáculo (la del tier 3). Solo visual.
const FLESH_COLOR: Color = Color("6E2A3A")
## Carne clara del borde. Solo visual.
const FLESH_LIGHT: Color = Color("9A3F55")
## Carne oscura de las ventosas. Solo visual.
const FLESH_DARK: Color = Color("3A1220")
## Tonos de la sangre. Solo visual.
const BLOOD_COLORS: Array[Color] = [Color("A01020"), Color("D8182C"), Color("FF3048"), Color("6E0F1A")]
## Latidos por segundo (como la viñeta). Solo visual.
const BEAT_RATE: float = 2.2
## Puntos con los que se dibuja el cuerpo. Solo visual.
const BODY_POINTS: int = 20
## Piezas en las que se parte el tentáculo al romperse. Solo visual.
const PIECES: int = 6

@export_group("Tentáculo")
## Largo del cuerpo desde la punta hacia arriba. Unidad: px.
@export var length: float = 250.0:
	set(value):
		length = value
		queue_redraw()
## Semiancho del cuerpo cerca de la punta y arriba del todo (donde empalma con la abertura de la
## piel del tier 3). Unidad: px.
@export var half_width_tip: float = 55.0:
	set(value):
		half_width_tip = value
		queue_redraw()
@export var half_width_top: float = 36.0:
	set(value):
		half_width_top = value
		queue_redraw()
## Largo de la punta redondeada. Unidad: px.
@export var cap_length: float = 70.0
## Distancia vertical entre la cámara y la punta a la que empieza a bajar (320 = justo al asomar por
## el borde superior de la pantalla). Unidad: px.
@export var approach_distance: float = 330.0
## Cuánto sube la cámara mientras el tentáculo termina de bajar. Unidad: px.
@export var grow_span: float = 160.0
## Cuánto baja el tentáculo desde arriba hasta su posición final. Unidad: px.
@export var drop_distance: float = 300.0

@export_group("Rotura")
## Instante congelado al tocarlo, en tiempo real. Unidad: s.
@export var freeze_time: float = 0.06
## Escala de tiempo de la cámara lenta tras el golpe y su duración (en tiempo real).
@export_range(0.05, 1.0, 0.05) var slow_scale: float = 0.3
@export var slow_time: float = 0.3
## Sacudida de cámara: amplitud (px) y duración (s).
@export var shake_amplitude: float = 16.0
@export var shake_duration: float = 0.6
## Destello rojo: color y opacidad máxima.
@export var flash_color: Color = Color(0.8, 0.05, 0.12, 1.0)
@export_range(0.0, 1.0, 0.05) var flash_alpha: float = 0.55
## Gotas de sangre del estallido.
@export var blood_count: int = 70

var _broken: bool = false
var _clock: float = 0.0
var _collision: CollisionPolygon2D


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_collision = CollisionPolygon2D.new()
	_collision.polygon = _outline(-130.0, 0.0, 0.0)
	add_child(_collision)
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


# Semiancho del cuerpo a la altura local [param ly] (0 = punta, negativo = hacia arriba).
func _half_width(ly: float) -> float:
	if ly > -cap_length:
		# Punta redondeada.
		var k: float = clampf((ly + cap_length) / cap_length, 0.0, 1.0)
		return half_width_tip * sqrt(maxf(1.0 - k * k, 0.0))
	var t: float = smoothstep(cap_length, length, -ly)
	return lerpf(half_width_tip, half_width_top, t)


# Contorno cerrado del cuerpo entre las alturas locales [param ly_from] (abajo, más cerca de la
# punta) y [param ly_to] (arriba). [param wave] = amplitud de la ondulación lateral (solo visual).
func _outline(ly_to: float, wave: float, margin: float, ly_from: float = 0.0) -> PackedVector2Array:
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	var steps: int = BODY_POINTS
	for i: int in steps + 1:
		var ly: float = lerpf(ly_from, ly_to, float(i) / float(steps))
		var cx: float = sin(ly * 0.03 + _clock * 1.8) * wave * clampf(-ly / 80.0, 0.0, 1.0)
		var h: float = _half_width(ly) + margin
		left.append(Vector2(cx - h, ly))
		right.append(Vector2(cx + h, ly))
	right.reverse()
	left.append_array(right)
	return left


func _on_body_entered(body: Node2D) -> void:
	if _broken or not (body is Player):
		return
	var player: Player = body as Player
	if not player.is_alive():
		return
	_break(to_local(player.global_position))


func _break(impact: Vector2) -> void:
	_broken = true
	membrane_hit.emit()
	set_deferred("monitoring", false)
	_spawn_pieces(impact)
	_spawn_blood(impact)
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


# La punta se parte en trozos que salen despedidos lejos del punto del impacto.
func _spawn_pieces(impact: Vector2) -> void:
	for i: int in PIECES:
		var ang0: float = PI * float(i) / float(PIECES)
		var ang1: float = PI * float(i + 1) / float(PIECES)
		var piece: Polygon2D = Polygon2D.new()
		var r: float = half_width_tip + 6.0
		var pts: PackedVector2Array = PackedVector2Array([Vector2(0.0, -cap_length * 0.6)])
		for k: int in 5:
			var a: float = lerpf(ang0, ang1, float(k) / 4.0)
			pts.append(Vector2(-cos(a) * r, -cap_length + sin(a) * cap_length))
		piece.polygon = pts
		piece.color = FLESH_LIGHT if i % 2 == 0 else FLESH_COLOR
		piece.z_index = 6
		add_child(piece)
		var mid: float = (ang0 + ang1) * 0.5
		var away: Vector2 = Vector2(-cos(mid), 0.3 * sin(mid) + randf_range(0.2, 0.9)).normalized()
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(piece, "position", away * randf_range(110.0, 240.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", randf_range(-3.0, 3.0), 1.0)
		tween.tween_property(piece, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(piece.queue_free)


# Estallido de sangre: un anillo que se expande y gotas que salen en todas direcciones.
func _spawn_blood(impact: Vector2) -> void:
	var ring: Polygon2D = Polygon2D.new()
	var ring_pts: PackedVector2Array = PackedVector2Array()
	for k: int in 20:
		var a: float = TAU * float(k) / 20.0
		ring_pts.append(Vector2(cos(a), sin(a)) * 24.0)
	ring.polygon = ring_pts
	ring.color = Color("D8182C")
	ring.position = impact
	ring.z_index = 7
	add_child(ring)
	var ring_tween: Tween = create_tween().set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2(3.2, 3.2), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tween.chain().tween_callback(ring.queue_free)
	for i: int in blood_count:
		var drop: Polygon2D = Polygon2D.new()
		var r: float = randf_range(2.0, 7.0)
		var pts: PackedVector2Array = PackedVector2Array()
		for k: int in 6:
			var ang: float = TAU * float(k) / 6.0
			pts.append(Vector2(cos(ang), sin(ang)) * r)
		drop.polygon = pts
		drop.color = BLOOD_COLORS[randi() % BLOOD_COLORS.size()]
		drop.position = impact + Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 8.0))
		drop.z_index = 7
		add_child(drop)
		var dir: Vector2 = Vector2.UP.rotated(randf_range(-PI, PI))
		var dist: float = randf_range(80.0, 320.0)
		var t: float = randf_range(0.6, 1.2)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(drop, "position", drop.position + dir * dist + Vector2(0.0, dist * 0.35), t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "modulate:a", 0.0, t)
		tween.chain().tween_callback(drop.queue_free)


# Avance del descenso (0–1): 0 = todavía arriba, fuera de la pantalla; 1 = ya en su sitio.
func _grow() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return 1.0
	var dist: float = camera.global_position.y - global_position.y
	return smoothstep(0.0, 1.0, clampf((approach_distance - dist) / maxf(grow_span, 1.0), 0.0, 1.0))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_colored_polygon(_outline(-length, 0.0, 0.0), Color(FLESH_COLOR, 0.8))
		return
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BEAT_RATE)
	var e: float = _grow()
	if e <= 0.0:
		return
	var drop: float = (1.0 - e) * drop_distance
	draw_set_transform(Vector2(0.0, -drop), 0.0, Vector2.ONE)
	if _broken:
		# Interior abierto del tentáculo: sin punta, más oscuro, con el borde desgarrado.
		var inner: PackedVector2Array = _outline(-length, 4.0, 0.0, -cap_length)
		draw_colored_polygon(inner, Color(FLESH_DARK, 0.9))
		draw_polyline(inner, Color(FLESH_LIGHT, 0.8), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var body: PackedVector2Array = _outline(-length, 5.0, 2.0 * beat)
	draw_colored_polygon(body, FLESH_COLOR)
	draw_polyline(body, FLESH_LIGHT, 3.0)
	# Anillos de carne y ventosas.
	for i: int in range(1, 10):
		var ly: float = -float(i) * (length / 10.0)
		var h: float = _half_width(ly)
		var cx: float = sin(ly * 0.03 + _clock * 1.8) * 5.0 * clampf(-ly / 80.0, 0.0, 1.0)
		draw_line(Vector2(cx - h * 0.9, ly), Vector2(cx + h * 0.9, ly), Color(FLESH_DARK, 0.5), 2.0)
		draw_circle(Vector2(cx - h * 0.45, ly + 8.0), 4.0, FLESH_DARK)
		draw_circle(Vector2(cx - h * 0.45, ly + 8.0), 2.0, FLESH_LIGHT)
		draw_circle(Vector2(cx + h * 0.45, ly + 8.0), 4.0, FLESH_DARK)
		draw_circle(Vector2(cx + h * 0.45, ly + 8.0), 2.0, FLESH_LIGHT)
	# Punta: un brillo húmedo.
	draw_circle(Vector2(0.0, -cap_length * 0.35), 7.0, Color(FLESH_LIGHT, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
