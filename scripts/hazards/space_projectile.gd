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
## vector hasta el final del recorrido. La cabeza es un sprite (`meteor_head` con 16 direcciones,
## `comet_head` con `twinkle`) y la estela son partículas pixeladas en espacio global. Ver
## `docs/arte/peligros-espacio.md` y `docs/mecanicas/obstaculos-espacio.md`.

## Color de los pedazos cuando el meteoro se rompe contra algo. Solo visual.
const HEAD_COLOR: Color = Color("D83232")
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
## Direcciones que dibuja la cabeza del meteoro (cuadro k = k × 360 / 16 grados, 0 = derecha, sentido
## horario en pantalla). Estructural.
const HEAD_DIRECTIONS: int = 16
## Partículas de estela por segundo de vida de la estela. Solo visual.
const TRAIL_DENSITY: float = 90.0
## Apertura de la estela. Solo visual. Unidad: °.
const TRAIL_SPREAD: float = 12.0
## Velocidad con que se separan las partículas de la estela, respecto del mundo. Solo visual.
## Unidad: px/s.
const TRAIL_DRIFT_MIN: float = 3.0
const TRAIL_DRIFT_MAX: float = 20.0
## Cuadros que dibuja una partícula a lo largo de su vida (amarillo → naranja → rojo → oscuro o
## blanco → cian → azul). Estructural.
const PARTICLE_FRAMES: int = 4
## Tamaño del resplandor aditivo de la cabeza, en múltiplos de `size`. Solo visual.
const GLOW_SCALE: float = 3.0

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

@export_group("Arte")
## Hoja de la cabeza (`assets/sprites/hazards/<nombre>.png`): `meteor_head` o `comet_head`.
@export var head_sheet: String = "meteor_head"
## Si es true, el cuadro de la cabeza sale de la dirección del vuelo (16 direcciones: el meteoro);
## si no, la cabeza anima el tag `twinkle` (el cometa).
@export var directional_head: bool = true
## Hoja de las partículas de la estela: `particle_ember` (meteoro) o `particle_ice` (cometa).
@export var particle_sheet: String = "particle_ember"
## Color del resplandor aditivo de la cabeza. Solo visual.
@export var glow_color: Color = Color(1.0, 0.42, 0.2, 0.55)

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

static var _glow_cache: GradientTexture2D = null

var _state: State = State.WAITING
var _home_local: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _delay_left: float = 0.0
var _dist: float = 0.0
var _head: Node2D
var _head_sheet: HazardSheet
var _head_sprite: Sprite2D
var _head_emissive: Sprite2D
var _head_time: float = 0.0
var _trail: CPUParticles2D
var _telegraph: Node2D


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
		_head.rotation = -rotation
		_head_time = 0.0
		_update_head_frame()
		_set_flying(true)
		_telegraph.queue_redraw()


# Vuelo en línea recta. Mata al jugador; el meteoro se rompe contra lo sólido.
func _tick_flying(delta: float) -> void:
	var step: float = speed * delta
	global_position += travel.normalized() * step
	_dist += step
	_head_time += delta
	_update_head_frame()
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
		# Las partículas que ya salieron terminan su vida aunque el proyectil se apague.
		_trail.emitting = flying
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


# Muestra el cuadro de la cabeza: según la dirección del vuelo (meteoro) o el `twinkle` (cometa).
func _update_head_frame() -> void:
	if _head_sprite == null:
		return
	var frame: int
	if directional_head:
		var step: float = TAU / float(HEAD_DIRECTIONS)
		frame = posmod(roundi(travel.angle() / step), HEAD_DIRECTIONS)
	else:
		var tag: StringName = &"twinkle"
		var first: int = _head_sheet.tag_first(tag)
		var count: int = _head_sheet.tag_length(tag)
		frame = first + int(_head_time / _head_sheet.durations[first]) % count
	var rect: Rect2 = _head_sheet.region(frame)
	_head_sprite.region_rect = rect
	if _head_emissive != null:
		_head_emissive.region_rect = rect


# Cabeza con sprite (color + emisivo sin sombrear) y resplandor aditivo, estela de partículas y
# forma de colisión. La cabeza no gira con el nodo: el sprite ya trae la dirección.
func _build_visuals() -> void:
	_head_sheet = HazardSheet.get_sheet(head_sheet)
	_trail = _make_trail()
	add_child(_trail)
	_head = Node2D.new()
	_head.name = "Head"
	_head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_head)
	var glow: Sprite2D = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = _glow_texture()
	glow.scale = Vector2.ONE * (size * GLOW_SCALE / 64.0)
	glow.modulate = glow_color
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = additive
	_head.add_child(glow)
	_head_sprite = Sprite2D.new()
	_head_sprite.name = "Sprite"
	_head_sprite.texture = _head_sheet.texture
	_head_sprite.region_enabled = true
	_head.add_child(_head_sprite)
	if _head_sheet.emissive != null:
		_head_emissive = Sprite2D.new()
		_head_emissive.name = "Emissive"
		_head_emissive.texture = _head_sheet.emissive
		_head_emissive.region_enabled = true
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_head_emissive.material = unshaded
		_head.add_child(_head_emissive)
	_update_head_frame()
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


# Estela: partículas en espacio global soltadas detrás de la cabeza. Cada una recorre los 4 cuadros
# de la hoja a lo largo de su vida; el largo de la estela es la velocidad por la vida.
func _make_trail() -> CPUParticles2D:
	var sheet: HazardSheet = HazardSheet.get_sheet(particle_sheet)
	var life: float = maxf(trail_length / maxf(speed, 1.0), 0.05)
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Trail"
	particles.texture = sheet.texture
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.local_coords = false
	particles.emitting = false
	particles.lifetime = life
	particles.amount = maxi(8, roundi(TRAIL_DENSITY * life))
	particles.direction = Vector2(-1.0, 0.0)
	particles.spread = TRAIL_SPREAD
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = TRAIL_DRIFT_MIN
	particles.initial_velocity_max = TRAIL_DRIFT_MAX
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = size * 0.25
	particles.anim_speed_min = 1.0
	particles.anim_speed_max = 1.0
	var material_anim: CanvasItemMaterial = CanvasItemMaterial.new()
	material_anim.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material_anim.particles_animation = true
	material_anim.particles_anim_h_frames = PARTICLE_FRAMES
	material_anim.particles_anim_v_frames = 1
	material_anim.particles_anim_loop = false
	particles.material = material_anim
	return particles


# Textura del resplandor: círculo que se desvanece hacia el borde (compartida).
static func _glow_texture() -> GradientTexture2D:
	if _glow_cache == null:
		var gradient: Gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
		_glow_cache = GradientTexture2D.new()
		_glow_cache.gradient = gradient
		_glow_cache.fill = GradientTexture2D.FILL_RADIAL
		_glow_cache.fill_from = Vector2(0.5, 0.5)
		_glow_cache.fill_to = Vector2(1.0, 0.5)
		_glow_cache.width = 64
		_glow_cache.height = 64
	return _glow_cache
