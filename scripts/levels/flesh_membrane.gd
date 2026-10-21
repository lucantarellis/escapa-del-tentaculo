@tool
class_name FleshMembrane
extends Area2D
## Tentáculo del alien que cierra el paso al final del espacio (tier 2): hace de "ventanal" de esta
## transición. Un tentáculo de carne atraviesa la pantalla de lado a lado (su raíz sale de un
## costado sorteado por partida y la punta se clava en el otro). Crece desde su raíz mientras el
## jugador se acerca (`approach_distance`) y queda latiendo y ondulando. Al tocarlo el jugador se
## rompe en pedazos con un **estallido de sangre**: instante congelado, cámara lenta, sacudida,
## destello rojo, trozos del tentáculo y gotas de sangre. El jugador conserva su velocidad y sigue
## hacia el tier 3 (la rotura nunca lo frena). El origen del nodo es el centro del tentáculo.
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
## Largo del tentáculo (cubre el ancho de la pantalla). Unidad: px.
@export var length: float = 390.0:
	set(value):
		length = value
		queue_redraw()
## Ancho en la raíz y en la punta. Unidad: px.
@export var width_root: float = 84.0:
	set(value):
		width_root = value
		queue_redraw()
@export var width_tip: float = 48.0:
	set(value):
		width_tip = value
		queue_redraw()
## Inclinación del tentáculo (el signo se sortea con el costado). Unidad: °.
@export var tilt_degrees: float = 4.0
## Distancia vertical entre la cámara y el tentáculo a la que empieza a crecer desde su raíz (320 =
## justo al asomar por el borde superior de la pantalla). Unidad: px.
@export var approach_distance: float = 330.0
## Cuánto sube la cámara mientras el tentáculo termina de cruzar la pantalla. Unidad: px.
@export var grow_span: float = 160.0
## Si es true, el costado de la raíz se sortea por partida; si es false, siempre es `side`
## (−1 izquierda, 1 derecha).
@export var random_side: bool = true
@export_range(-1, 1, 2) var side: int = 1

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
var _side: int = 1
var _collision: CollisionPolygon2D


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_side = side
	if random_side:
		_side = 1 if randf() < 0.5 else -1
	rotation = deg_to_rad(tilt_degrees) * float(_side)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_collision = CollisionPolygon2D.new()
	_collision.polygon = _outline(1.0, 0.0, 1.0)
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


# x local del punto del tentáculo a la fracción [param u] (0 = raíz, 1 = punta).
func _x_at(u: float) -> float:
	return (-length * 0.5 + length * u) * float(-_side if _side != 0 else 1)


# Ancho del tentáculo a la fracción [param u] de su largo.
func _width_at(u: float) -> float:
	return lerpf(width_root, width_tip, u)


# Contorno cerrado del tentáculo desde la fracción [param u0] hasta [param u1] (para dibujar y
# para la colisión). [param wave] = amplitud de la ondulación (solo visual).
func _outline(u1: float, wave: float, scale_w: float, u0: float = 0.0) -> PackedVector2Array:
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	var steps: int = BODY_POINTS
	for i: int in steps + 1:
		var u: float = lerpf(u0, u1, float(i) / float(steps))
		var cy: float = sin(u * 7.0 + _clock * 2.0) * wave
		var h: float = _width_at(u) * 0.5 * scale_w
		top.append(Vector2(_x_at(u), cy - h))
		bottom.append(Vector2(_x_at(u), cy + h))
	bottom.reverse()
	top.append_array(bottom)
	return top


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


# El tentáculo se parte en trozos que salen despedidos lejos del punto del impacto.
func _spawn_pieces(impact: Vector2) -> void:
	for i: int in PIECES:
		var u0: float = float(i) / float(PIECES)
		var u1: float = float(i + 1) / float(PIECES)
		var piece: Polygon2D = Polygon2D.new()
		var pts: PackedVector2Array = _outline(u1, 0.0, 1.0, u0)
		var centre: Vector2 = Vector2((_x_at(u0) + _x_at(u1)) * 0.5, 0.0)
		for k: int in pts.size():
			pts[k] -= centre
		piece.polygon = pts
		piece.position = centre
		piece.color = FLESH_LIGHT if i % 2 == 0 else FLESH_COLOR
		piece.z_index = 6
		add_child(piece)
		var away: Vector2 = Vector2(signf(centre.x - impact.x) * randf_range(0.4, 1.0), randf_range(-1.0, 0.4)).normalized()
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(piece, "position", centre + away * randf_range(120.0, 260.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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


# Avance del anticipo (0–1): 0 = todavía no creció, 1 = ya cruza toda la pantalla.
func _grow() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return 1.0
	var dist: float = camera.global_position.y - global_position.y
	return smoothstep(0.0, 1.0, clampf((approach_distance - dist) / maxf(grow_span, 1.0), 0.0, 1.0))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_colored_polygon(_outline(1.0, 0.0, 1.0), Color(FLESH_COLOR, 0.8))
		return
	if _broken:
		return
	var e: float = _grow()
	if e <= 0.0:
		return
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BEAT_RATE)
	var wave: float = 6.0
	var body: PackedVector2Array = _outline(e, wave, 1.0 + 0.04 * beat)
	draw_colored_polygon(body, FLESH_COLOR)
	draw_polyline(body, FLESH_LIGHT, 3.0)
	# Anillos de carne y ventosas hacia el lado del jugador (abajo).
	for i: int in range(1, 12):
		var u: float = float(i) / 12.0
		if u > e:
			break
		var cy: float = sin(u * 7.0 + _clock * 2.0) * wave
		var h: float = _width_at(u) * 0.5
		draw_line(Vector2(_x_at(u), cy - h * 0.9), Vector2(_x_at(u), cy + h * 0.9), Color(FLESH_DARK, 0.45), 2.0)
		draw_circle(Vector2(_x_at(u), cy + h * 0.45), 4.0, FLESH_DARK)
		draw_circle(Vector2(_x_at(u), cy + h * 0.45), 2.0, FLESH_LIGHT)
