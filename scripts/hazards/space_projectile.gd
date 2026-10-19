@tool
class_name SpaceProjectile
extends Area2D
## Proyectil letal del espacio: meteoro o cometa. Espera fuera de la pantalla; cuando su
## trayectoria entra en la vista **avisa** (una marca parpadeante en el borde por donde va a
## entrar y, en el cometa, la línea punteada de todo su recorrido), `warning_time` s después
## cruza en línea recta y mata al jugador que toque la cabeza (o la estela, si `trail_lethal`).
## Con `repeat_interval` > 0 vuelve a avisar y a cruzar mientras su trayectoria siga a la vista.
## El meteoro se rompe contra lo sólido (asteroides, paredes): sirve de escudo. El cometa
## atraviesa todo.
##
## El origen del nodo es el punto de partida (normalmente fuera de la pantalla); `travel` es el
## vector hasta el final del recorrido. Placeholders con polígonos. Ver
## `docs/mecanicas/obstaculos-espacio.md`.

## Rojo letal de la paleta (cabeza). Solo visual.
const HEAD_COLOR: Color = Color("D83232")
## Naranja de la estela. Solo visual.
const TRAIL_COLOR: Color = Color("FF6B32")
## Color del aviso (un rojo más claro que el de lo letal, para que se vea sobre el fondo oscuro). Solo visual.
const WARNING_COLOR: Color = Color("FF5040")
## Color del trazo de la trayectoria en el editor. Solo visual.
const EDITOR_COLOR: Color = Color(1.0, 0.42, 0.2, 0.8)
## Parpadeos por segundo del aviso. Solo visual.
const BLINK_RATE: float = 2.5
## Largo del trazo del aviso del meteoro. Solo visual. Unidad: px.
const ARROW_SHAFT: float = 70.0
## Largo de la punta de flecha del aviso. Solo visual. Unidad: px.
const ARROW_HEAD: float = 22.0
## Color del núcleo caliente de la cabeza. Solo visual.
const CORE_COLOR: Color = Color("FFB199")

enum State { WAITING, WARNING, FLYING, COOLDOWN, GONE }

@export_group("Trayectoria")
## Vector desde el punto de partida (la posición del nodo) hasta el final del recorrido.
## Unidad: px.
@export var travel: Vector2 = Vector2(420.0, 60.0):
	set(value):
		travel = value
		queue_redraw()
## Velocidad de vuelo. Unidad: px/s.
@export var speed: float = 180.0

@export_group("Forma")
## Tamaño de la cabeza. Unidad: px.
@export var size: float = 16.0
## Largo de la estela. Unidad: px.
@export var trail_length: float = 90.0
## Si es true, la estela también mata (el cometa); si no, es solo visual.
@export var trail_lethal: bool = false
## Si es true, se rompe al chocar contra algo sólido del mundo (el meteoro).
@export var breaks_on_solid: bool = true

@export_group("Aviso")
## Tiempo entre el aviso y el paso del proyectil. Unidad: s.
@export var warning_time: float = 1.0
## Si es true, el aviso dibuja la línea punteada de todo el recorrido visible (el cometa); si
## no, solo una marca en el borde y un trazo corto.
@export var show_path: bool = false

@export_group("Ciclo")
## Espera, desde que la trayectoria entra en la vista, antes de avisar la primera vez (para
## desfasar varios proyectiles de un mismo segmento). Unidad: s.
@export var initial_delay: float = 0.0
## Tiempo entre un paso y el aviso del siguiente (0 = pasa una sola vez). Unidad: s.
@export var repeat_interval: float = 0.0
## Causa que se pasa a [method Player.die].
@export var cause: StringName = &"meteor"

var _state: State = State.WAITING
var _home_local: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _delay_left: float = 0.0
var _dist: float = 0.0
var _head: Polygon2D
var _trail: Polygon2D
var _telegraph: Node2D
var _spin: float = 3.0


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_home_local = position
	collision_layer = 0
	# 2 = jugador (mata), 1 = mundo (rompe al meteoro).
	collision_mask = 2 | (1 if breaks_on_solid else 0)
	_build_visuals()
	_telegraph = Node2D.new()
	_telegraph.top_level = true
	_telegraph.z_index = 60
	add_child(_telegraph)
	_telegraph.draw.connect(_draw_telegraph)
	reset()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_line(Vector2.ZERO, travel, EDITOR_COLOR, 2.0)
	draw_circle(Vector2.ZERO, size * 0.5, EDITOR_COLOR)
	draw_circle(travel, 4.0, EDITOR_COLOR)


## Vuelve al estado inicial: quieto fuera de la pantalla, listo para avisar de nuevo.
func reset() -> void:
	if Engine.is_editor_hint():
		return
	_state = State.WAITING
	_delay_left = initial_delay
	_t = 0.0
	_dist = 0.0
	_set_flying(false)
	if get_parent() is Node2D:
		global_position = _start_global()
	_telegraph.queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		State.WAITING:
			_tick_waiting(delta)
		State.WARNING:
			_tick_warning(delta)
		State.FLYING:
			_tick_flying(delta)
		State.COOLDOWN:
			_tick_cooldown(delta)
		State.GONE:
			pass


# Espera a que el recorrido entre en la vista.
func _tick_waiting(delta: float) -> void:
	if _visible_clip().is_empty():
		return
	_delay_left -= delta
	if _delay_left <= 0.0:
		_state = State.WARNING
		_t = 0.0


# Aviso: marca parpadeante. Si el recorrido sale de la vista, se cancela.
func _tick_warning(delta: float) -> void:
	_t += delta
	if _visible_clip().is_empty():
		_state = State.WAITING
		_delay_left = 0.0
		_telegraph.queue_redraw()
		return
	_telegraph.queue_redraw()
	if _t >= warning_time:
		_state = State.FLYING
		_dist = 0.0
		global_position = _start_global()
		rotation = travel.angle()
		_set_flying(true)
		_telegraph.queue_redraw()


# Vuelo en línea recta. Mata al jugador; el meteoro se rompe contra lo sólido.
func _tick_flying(delta: float) -> void:
	var step: float = speed * delta
	global_position += travel.normalized() * step
	_dist += step
	if _head != null:
		_head.rotation += _spin * delta
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null:
			if player.is_alive():
				player.die(cause)
				_finish()
				return
		elif breaks_on_solid and not (body.get_parent() is Camera2D):
			_shatter()
			return
	if _dist >= travel.length():
		_finish()


func _tick_cooldown(delta: float) -> void:
	_t += delta
	if _t >= repeat_interval:
		_state = State.WAITING
		_delay_left = 0.0


# Termina un paso: vuelve a esperar (si repite) o se apaga.
func _finish() -> void:
	_set_flying(false)
	global_position = _start_global()
	if repeat_interval > 0.0:
		_state = State.COOLDOWN
		_t = 0.0
	else:
		_state = State.GONE


# Se rompe en pedazos (solo visual) y termina el paso.
func _shatter() -> void:
	var bits: CPUParticles2D = CPUParticles2D.new()
	bits.one_shot = true
	bits.explosiveness = 1.0
	bits.amount = 10
	bits.lifetime = 0.5
	bits.spread = 180.0
	bits.initial_velocity_min = 50.0
	bits.initial_velocity_max = 140.0
	bits.gravity = Vector2.ZERO
	bits.scale_amount_min = 2.0
	bits.scale_amount_max = 4.0
	bits.color = HEAD_COLOR
	get_parent().add_child(bits)
	bits.global_position = global_position
	bits.emitting = true
	get_tree().create_timer(0.8).timeout.connect(bits.queue_free)
	_finish()


# Muestra u oculta la cabeza y la estela, y enciende o apaga la detección.
func _set_flying(flying: bool) -> void:
	if _head != null:
		_head.visible = flying
	if _trail != null:
		_trail.visible = flying
	set_deferred("monitoring", flying)


func _start_global() -> Vector2:
	var parent: Node2D = get_parent() as Node2D
	return parent.to_global(_home_local) if parent != null else _home_local


# Parte del recorrido que está dentro de la vista: [entrada, salida] o vacío si no entra.
func _visible_clip() -> PackedVector2Array:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return PackedVector2Array()
	var start: Vector2 = _start_global()
	return _clip(start, start + travel, camera.get_visible_rect())


# Recorta el segmento a→b contra [param rect] (Liang–Barsky).
func _clip(a: Vector2, b: Vector2, rect: Rect2) -> PackedVector2Array:
	var t0: float = 0.0
	var t1: float = 1.0
	var d: Vector2 = b - a
	var p: Array[float] = [-d.x, d.x, -d.y, d.y]
	var q: Array[float] = [a.x - rect.position.x, rect.end.x - a.x, a.y - rect.position.y, rect.end.y - a.y]
	for i: int in 4:
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return PackedVector2Array()
		else:
			var r: float = q[i] / p[i]
			if p[i] < 0.0:
				if r > t1:
					return PackedVector2Array()
				t0 = maxf(t0, r)
			else:
				if r < t0:
					return PackedVector2Array()
				t1 = minf(t1, r)
	return PackedVector2Array([a + d * t0, a + d * t1])


# Aviso: trazo de la trayectoria con la punta de flecha ADELANTE (la punta marca hacia dónde
# va; si el trazo saliera de la punta se leería como una estela y la flecha parecería ir al
# revés). Meteoro: trazo corto desde el borde por donde entra. Cometa: trazo punteado de todo el
# recorrido visible, con un punto en el borde de entrada y la punta al final.
func _draw_telegraph() -> void:
	if _state != State.WARNING:
		return
	var clip: PackedVector2Array = _visible_clip()
	if clip.is_empty():
		return
	var entry: Vector2 = clip[0]
	var dir: Vector2 = travel.normalized()
	var side: Vector2 = dir.orthogonal()
	var blink: float = 0.55 + 0.45 * sin(_t * TAU * BLINK_RATE)
	var line_len: float = entry.distance_to(clip[1])
	var color: Color = Color(WARNING_COLOR, blink)
	var tip: Vector2
	if show_path:
		var pos: float = 0.0
		while pos < line_len:
			_telegraph.draw_line(entry + dir * pos, entry + dir * minf(pos + 10.0, line_len), Color(WARNING_COLOR, 0.3 + 0.3 * blink), 2.0)
			pos += 18.0
		_telegraph.draw_circle(entry + dir * 3.0, 4.0, color)
		tip = entry + dir * maxf(line_len - 3.0, 0.0)
	else:
		var shaft: float = minf(ARROW_SHAFT, maxf(line_len - ARROW_HEAD, 0.0))
		_telegraph.draw_line(entry, entry + dir * shaft, Color(WARNING_COLOR, 0.35 + 0.4 * blink), 3.0)
		tip = entry + dir * (shaft + ARROW_HEAD)
	var base: Vector2 = tip - dir * ARROW_HEAD
	_telegraph.draw_colored_polygon(PackedVector2Array([tip, base + side * 9.0, base - side * 9.0]), color)


# Copia de [param points] escalada respecto del origen.
func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * factor)
	return out


# Cabeza irregular (con halo y núcleo), estela con degradado y forma de colisión.
func _build_visuals() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0 + randf_range(-0.25, 0.25)
		points.append(Vector2(cos(a), sin(a)) * size * randf_range(0.42, 0.55))
	_trail = Polygon2D.new()
	_trail.polygon = PackedVector2Array([Vector2(0.0, -size * 0.45), Vector2(-trail_length, 0.0), Vector2(0.0, size * 0.45)])
	_trail.vertex_colors = PackedColorArray([Color(TRAIL_COLOR, 0.95), Color(TRAIL_COLOR, 0.0), Color(TRAIL_COLOR, 0.95)])
	add_child(_trail)
	_head = Polygon2D.new()
	_head.color = HEAD_COLOR
	_head.polygon = points
	add_child(_head)
	var halo: Polygon2D = Polygon2D.new()
	halo.color = Color(TRAIL_COLOR, 0.28)
	halo.polygon = _scaled(points, 1.7)
	_head.add_child(halo)
	halo.show_behind_parent = true
	var core: Polygon2D = Polygon2D.new()
	core.color = CORE_COLOR
	core.polygon = _scaled(points, 0.45)
	_head.add_child(core)
	_spin = randf_range(-5.0, 5.0)
	var shape: CollisionShape2D = CollisionShape2D.new()
	if trail_lethal:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(trail_length + size * 0.5, size * 0.8)
		shape.shape = rect
		shape.position = Vector2(-trail_length * 0.5 + size * 0.25, 0.0)
	else:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = size * 0.5
		shape.shape = circle
	add_child(shape)
