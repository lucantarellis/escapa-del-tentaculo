@tool
class_name TierEvent
extends Node2D
## Momento de historia al entrar a un tier. Cuando el jugador cruza (subiendo) la Y de este nodo:
## cámara lenta un instante, destello, explosión (anillo y fuego) desde abajo, eyección del
## jugador hacia arriba, restos letales del casco en direcciones al azar ([HullDebris]), sacudida
## y la silueta del alien huyendo por el fondo. Cada parte se activa y ajusta con `@export`.
## Se pone en los segmentos de entrada de un tier (`SegmentTier.entry_segments`). Ocurre una
## sola vez por partida (el nivel se rearma con R).
##
## Visuales placeholder (polígonos, partículas sin textura). El cambio de perseguidor, física y
## fondo lo hace [LevelController] al cruzar el borde del tier. Ver `docs/mecanicas/tier-espacio.md`.

## Se emite cuando el evento se dispara.
signal triggered

## Color de la silueta del alien (violeta oscuro de la paleta del tentáculo). Solo visual.
const SILHOUETTE_COLOR: Color = Color("3A1B5E")
## Color de la línea de ayuda en el editor. Solo visual.
const EDITOR_LINE_COLOR: Color = Color(1.0, 0.42, 0.2, 0.8)

@export_group("Cámara")
## Fuerza de la sacudida. Unidad: px.
@export var shake_amplitude: float = 28.0
## Duración de la sacudida. Unidad: s.
@export var shake_duration: float = 1.2
## Escala de tiempo durante la cámara lenta (1 = sin cámara lenta).
@export_range(0.05, 1.0, 0.05) var slow_motion_scale: float = 0.25
## Duración de la cámara lenta, en tiempo real. Unidad: s.
@export var slow_motion_duration: float = 0.35

@export_group("Explosión")
## Si es true, un anillo de fuego se expande desde abajo (desde el centro de `explosion_offset`).
@export var explosion_enabled: bool = true
## Espera desde que el jugador cruza este nodo hasta la explosión (y todo lo que la acompaña:
## cámara lenta, destello, empuje, restos). Unidad: s.
@export var explosion_delay: float = 0.0
## Origen de la explosión respecto de este nodo (por defecto, el centro del casco). Unidad: px.
@export var explosion_offset: Vector2 = Vector2(180.0, 40.0)
## Color del anillo y del fuego.
@export var explosion_color: Color = Color("FF6B32")
## Radio final del anillo. Unidad: px.
@export var explosion_radius: float = 560.0
## Duración de la expansión del anillo. Unidad: s.
@export var explosion_duration: float = 0.8
## Cantidad de partículas de fuego.
@export var fire_particles: int = 70

@export_group("Eyección")
## Velocidad hacia arriba que recibe el jugador (0 = sin eyección). Unidad: px/s.
@export var eject_speed: float = 450.0
## Tiempo sin control tras la eyección. Unidad: s.
@export var eject_control_lock: float = 0.3

@export_group("Restos del casco")
## Fragmentos letales por oleada (0 = sin restos).
@export var debris_count: int = 7
## Cantidad de oleadas y tiempo entre una y otra. Unidad: s.
@export var debris_waves: int = 3
@export var debris_wave_interval: float = 0.7
## Velocidad mínima y máxima de los fragmentos. Unidad: px/s.
@export var debris_speed_min: float = 220.0
@export var debris_speed_max: float = 380.0
## Tamaño de los fragmentos. Unidad: px.
@export var debris_size: float = 18.0
## Si es true, los fragmentos apuntan hacia el jugador (con `debris_aim_spread` de desvío al
## azar); si no, salen hacia arriba en direcciones al azar. Unidad del desvío: grados.
@export var debris_aim_at_player: bool = true
@export var debris_aim_spread: float = 35.0
## Distancia horizontal mínima al jugador donde puede aparecer un fragmento. Unidad: px.
@export var debris_min_player_distance: float = 60.0
## Tiempo inicial en que un fragmento todavía no mata. Unidad: s.
@export var debris_grace_time: float = 0.25

@export_group("Destello")
## Color del destello que cubre la pantalla.
@export var flash_color: Color = Color(1.0, 0.85, 0.6, 1.0)
## Opacidad máxima del destello (0..1).
@export_range(0.0, 1.0, 0.05) var flash_alpha: float = 0.8
## Duración del destello (sube de golpe y se desvanece). Unidad: s.
@export var flash_duration: float = 0.5

@export_group("Silueta")
## Si es true, la silueta del alien cruza la pantalla hacia arriba por el fondo.
@export var show_silhouette: bool = true
## Tiempo que tarda la silueta en cruzar la pantalla. Unidad: s.
@export var silhouette_duration: float = 0.8
## Espera desde el destello hasta que aparece la silueta. Unidad: s.
@export var silhouette_delay: float = 0.25
## Escala de la silueta (1 = unos 120 px de alto).
@export var silhouette_scale: float = 2.0

var _fired: bool = false


func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(0.0, 0.0), Vector2(360.0, 0.0), EDITOR_LINE_COLOR, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(4.0, -4.0), "TierEvent", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EDITOR_LINE_COLOR)


func _physics_process(_delta: float) -> void:
	if _fired:
		return
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Player = node as Player
		if player != null and player.is_alive() and player.global_position.y <= global_position.y:
			fire(player)
			return


## Dispara el evento (si no se disparó antes). [param player] es el jugador que lo cruzó
## (para la eyección y para no hacer aparecer restos encima de él).
func fire(player: Player = null) -> void:
	if _fired:
		return
	_fired = true
	set_physics_process(false)
	if explosion_delay > 0.0:
		await get_tree().create_timer(explosion_delay).timeout
		if not is_inside_tree():
			return
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null:
		camera.shake(shake_amplitude, shake_duration)
	_play_slow_motion()
	_play_flash()
	if explosion_enabled:
		_play_explosion()
	if player != null and eject_speed > 0.0:
		player.launch(Vector2(player.velocity.x * 0.5, -eject_speed), eject_control_lock)
	_spawn_debris(player)
	if show_silhouette:
		_play_silhouette()
	triggered.emit()


# Cámara lenta medida en tiempo real (el temporizador ignora la escala de tiempo).
func _play_slow_motion() -> void:
	if slow_motion_scale >= 1.0 or slow_motion_duration <= 0.0:
		return
	Engine.time_scale = slow_motion_scale
	await get_tree().create_timer(slow_motion_duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	# Si el nivel se descarga en plena cámara lenta (R), no dejar el juego lento.
	if _fired:
		Engine.time_scale = 1.0


# Anillo que se expande desde el casco y partículas de fuego.
func _play_explosion() -> void:
	var origin: Vector2 = global_position + explosion_offset
	var ring: Node2D = Node2D.new()
	ring.global_position = origin
	ring.z_index = 5
	get_parent().add_child(ring)
	ring.global_position = origin
	var state: Dictionary = {"r": 0.0, "a": 1.0}
	ring.draw.connect(func() -> void:
		ring.draw_circle(Vector2.ZERO, state["r"], Color(explosion_color, 0.25 * state["a"]))
		ring.draw_arc(Vector2.ZERO, state["r"], 0.0, TAU, 64, Color(explosion_color, state["a"]), 10.0))
	var tween: Tween = ring.create_tween().set_parallel(true)
	tween.tween_method(func(v: float) -> void:
		state["r"] = v * explosion_radius
		state["a"] = 1.0 - v
		ring.queue_redraw(), 0.0, 1.0, explosion_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(ring.queue_free)
	if fire_particles > 0:
		var fire: CPUParticles2D = CPUParticles2D.new()
		fire.global_position = origin
		fire.z_index = 4
		fire.emitting = false
		fire.one_shot = true
		fire.explosiveness = 0.9
		fire.amount = fire_particles
		fire.lifetime = 1.2
		fire.direction = Vector2.UP
		fire.spread = 80.0
		fire.initial_velocity_min = 120.0
		fire.initial_velocity_max = 380.0
		fire.gravity = Vector2.ZERO
		fire.scale_amount_min = 4.0
		fire.scale_amount_max = 9.0
		fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fire.emission_rect_extents = Vector2(170.0, 8.0)
		var ramp: Gradient = Gradient.new()
		ramp.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
		ramp.set_color(1, Color(explosion_color, 0.0))
		fire.color_ramp = ramp
		get_parent().add_child(fire)
		fire.global_position = origin
		fire.emitting = true
		get_tree().create_timer(2.0).timeout.connect(fire.queue_free)


# Restos letales de la nave: entran por el borde inferior de la pantalla (vienen de la
# explosión, abajo) en `debris_waves` oleadas, apuntando al jugador con algo de desvío.
func _spawn_debris(player: Player) -> void:
	if debris_count <= 0:
		return
	for wave: int in maxi(debris_waves, 1):
		if wave > 0:
			await get_tree().create_timer(debris_wave_interval).timeout
			if not is_inside_tree():
				return
		_spawn_debris_wave(player)


func _spawn_debris_wave(player: Player) -> void:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	var view: Rect2 = camera.get_visible_rect() if camera != null else Rect2(global_position + Vector2(0.0, -640.0), Vector2(360.0, 640.0))
	var spawn_y: float = view.end.y + 16.0
	var spawned: int = 0
	var tries: int = 0
	while spawned < debris_count and tries < debris_count * 10:
		tries += 1
		var x: float = randf_range(view.position.x + 10.0, view.end.x - 10.0)
		if player != null and absf(x - player.global_position.x) < debris_min_player_distance:
			continue
		var from: Vector2 = Vector2(x, spawn_y + randf_range(0.0, 30.0))
		var direction: Vector2 = Vector2.UP.rotated(deg_to_rad(randf_range(-50.0, 50.0)))
		if debris_aim_at_player and player != null and player.is_alive():
			direction = (player.global_position - from).normalized().rotated(deg_to_rad(randf_range(-debris_aim_spread, debris_aim_spread)))
		var debris: HullDebris = HullDebris.new()
		debris.velocity = direction * randf_range(debris_speed_min, debris_speed_max)
		debris.spin = randf_range(-6.0, 6.0)
		debris.size = debris_size
		debris.grace_time = debris_grace_time
		get_parent().add_child(debris)
		debris.global_position = from
		spawned += 1


func _play_flash() -> void:
	if flash_alpha <= 0.0 or flash_duration <= 0.0:
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
	tween.tween_property(rect, "color:a", 0.0, flash_duration)
	tween.tween_callback(layer.queue_free)


# Silueta en una capa de fondo (detrás del nivel), en coordenadas de pantalla.
func _play_silhouette() -> void:
	var view: Vector2 = get_viewport_rect().size
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var body: Polygon2D = Polygon2D.new()
	body.color = SILHOUETTE_COLOR
	body.polygon = _silhouette_points()
	body.scale = Vector2.ONE * silhouette_scale
	body.position = Vector2(view.x * 0.62, view.y + 140.0 * silhouette_scale)
	layer.add_child(body)
	var tween: Tween = create_tween()
	tween.tween_interval(silhouette_delay)
	tween.tween_property(body, "position:y", -160.0 * silhouette_scale, silhouette_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)


# Cabeza ovalada con tentáculos colgando, centrada en el origen (placeholder).
func _silhouette_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var a: float = PI + PI * float(i) / 12.0
		points.append(Vector2(cos(a) * 40.0, sin(a) * 50.0 - 10.0))
	var tips: Array[float] = [36.0, 22.0, 8.0, -8.0, -22.0, -36.0]
	var lengths: Array[float] = [70.0, 95.0, 60.0, 90.0, 75.0, 65.0]
	for i: int in tips.size():
		var x: float = tips[i]
		points.append(Vector2(x + 4.0, -10.0))
		points.append(Vector2(x + (6.0 if i % 2 == 0 else -6.0), -10.0 + lengths[i]))
		points.append(Vector2(x - 4.0, -10.0))
	return points
