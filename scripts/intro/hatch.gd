class_name Hatch
extends Node2D
## Escotilla del piso del segmento de inicio: de ahí "sale" el jugador en la intro.
##
## Tiene tres estados visuales: cerrada, golpeada (cada [method hit] la abomba un poco más, la
## sacude, intensifica el brillo rojo de abajo y suelta una ráfaga de gas) y rota (hojas abiertas,
## marco visible y hueco oscuro; ver [method set_broken]). El origen del nodo es el centro del
## borde SUPERIOR del piso. Corre siempre (`PROCESS_MODE_ALWAYS`) porque el nivel está en
## pausa mientras dura la intro. Todo es placeholder. Ver `docs/mecanicas/intro-escotilla.md`.

## Azul frío de la paleta: hojas. Solo visual.
const COLOR_LEAF: Color = Color("#3A9BBF")
## Blanco azulado de la paleta: marco. Solo visual.
const COLOR_FRAME: Color = Color("#C8E7EA")
## Rojo de la paleta: brillo de abajo. Solo visual.
const COLOR_GLOW: Color = Color("#D83232")
## Negro de la paleta: hueco de la escotilla rota. Solo visual.
const COLOR_HOLE: Color = Color("#050609")
## Blanco azulado con alfa: gas. Solo visual.
const COLOR_GAS: Color = Color(0.784, 0.906, 0.918, 0.55)
## Semiancho del marco. Solo visual. Unidad: px.
const FRAME_HALF_WIDTH: float = 64.0
## Y del borde superior del marco respecto del origen (negativo = sobre el piso). Solo visual. Unidad: px.
const FRAME_TOP: float = -12.0
## Y del borde inferior del marco respecto del origen (cubre la banda del piso). Solo visual. Unidad: px.
const FRAME_BOTTOM: float = 20.0
## Grosor del marco visible alrededor de las hojas. Solo visual. Unidad: px.
const FRAME_BORDER: float = 4.0
## Cuánto se abomba el centro de las hojas con cada golpe. Solo visual. Unidad: px.
const BULGE_PER_HIT: float = 2.5
## Opacidad del brillo rojo con la escotilla cerrada. Solo visual.
const GLOW_ALPHA_BASE: float = 0.12
## Opacidad que suma el brillo con cada golpe. Solo visual.
const GLOW_ALPHA_PER_HIT: float = 0.18
## Ángulo de apertura de las hojas al romperse. Solo visual. Unidad: rad.
const BROKEN_LEAF_ANGLE: float = 1.3
## Desplazamiento de la sacudida de la escotilla en un golpe normal. Solo visual. Unidad: px.
const HIT_SHAKE_PX: float = 3.0
## Duración de la sacudida de la escotilla. Solo visual. Unidad: s.
const HIT_SHAKE_TIME: float = 0.3
## Gravedad de los fragmentos de la ruptura. Solo visual. Unidad: px/s².
const DEBRIS_GRAVITY: float = 900.0
## Rango de velocidad de los fragmentos al salir. Solo visual. Unidad: px/s.
const DEBRIS_SPEED_MIN: float = 120.0
const DEBRIS_SPEED_MAX: float = 300.0
## Vida de un fragmento (cae fuera de pantalla). Solo visual. Unidad: s.
const DEBRIS_LIFETIME: float = 1.4
## Tamaño de un fragmento. Solo visual. Unidad: px.
const DEBRIS_SIZE: float = 9.0
## Giro máximo de un fragmento. Solo visual. Unidad: rad/s.
const DEBRIS_SPIN: float = 8.0
## Apertura del cono del gas. Solo visual. Unidad: grados.
const GAS_SPREAD_DEG: float = 35.0
## Tamaño de las partículas de gas (sin textura). Solo visual. Unidad: px.
const GAS_PARTICLE_SIZE: float = 5.0

## Se emite cuando termina la animación de apertura de [method break_open].
signal break_finished

## Parámetros de la intro (gas). Lo asigna [LevelController]; si queda vacío se usan los valores
## por defecto de [IntroConfig].
@export var config: IntroConfig

@onready var _visual: Node2D = $Visual
@onready var _frame: Polygon2D = $Visual/Frame
@onready var _hole: Polygon2D = $Visual/Hole
@onready var _glow: Polygon2D = $Visual/Glow
@onready var _leaf_left: Polygon2D = $Visual/LeafLeft
@onready var _leaf_right: Polygon2D = $Visual/LeafRight
@onready var _gas: CPUParticles2D = $GasParticles

var _hits: int = 0
var _broken: bool = false
var _shake_tween: Tween
var _break_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_static_shapes()
	_setup_gas()
	_refresh()


## Golpe: sacude la escotilla, la abomba un poco más, intensifica el brillo y suelta una ráfaga
## de gas. [param strength] es el multiplicador de intensidad (1 = golpe base). Ignorado si la
## escotilla ya está rota.
func hit(strength: float) -> void:
	if _broken:
		return
	_hits += 1
	_refresh()
	_shake_visual(strength)
	_burst_gas(roundi(_get_config().gas_amount * strength))


## Rompe la escotilla con animación: ráfaga grande de gas (`break_gas_amount`), fragmentos que
## salen despedidos (`break_debris_count`) y las hojas que se abren en `break_duration` s hasta
## dejar el marco y el hueco oscuro. Desde que se llama, [method is_broken] es `true`. Al terminar
## la apertura emite [signal break_finished]. Ignorado si ya está rota.
func break_open() -> void:
	if _broken:
		return
	var cfg: IntroConfig = _get_config()
	_broken = true
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2.ZERO
	_hole.visible = true
	_glow.visible = false
	# Aplana el abombamiento de los golpes: las hojas se abren desde su posición cerrada.
	_leaf_left.polygon = _leaf_polygon(0.0, 1.0)
	_leaf_right.polygon = _leaf_polygon(0.0, -1.0)
	_burst_gas(cfg.break_gas_amount)
	_spawn_debris(cfg.break_debris_count)
	if _break_tween != null:
		_break_tween.kill()
	_break_tween = create_tween().set_parallel(true)
	var duration: float = maxf(cfg.break_duration, 0.01)
	_break_tween.tween_property(_leaf_left, "rotation", -BROKEN_LEAF_ANGLE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_break_tween.tween_property(_leaf_right, "rotation", BROKEN_LEAF_ANGLE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_break_tween.chain().tween_callback(break_finished.emit)


## Fija el estado final sin animación: [param broken] `true` = rota (hojas abiertas, hueco
## oscuro), `false` = cerrada (y sin golpes acumulados). Lo usa el nivel cuando no hay intro.
func set_broken(broken: bool) -> void:
	_broken = broken
	_hits = 0
	if _shake_tween != null:
		_shake_tween.kill()
	if _break_tween != null:
		_break_tween.kill()
	_visual.position = Vector2.ZERO
	_refresh()


## Devuelve true si la escotilla está rota.
func is_broken() -> bool:
	return _broken


## Devuelve la cantidad de golpes recibidos desde que se cerró.
func get_hit_count() -> int:
	return _hits


## Devuelve la posición global del centro superior de la escotilla: de ahí sale el jugador.
func get_launch_position() -> Vector2:
	return global_position + Vector2(0.0, FRAME_TOP)


func _get_config() -> IntroConfig:
	if config == null:
		config = IntroConfig.new()
	return config


# Formas que no cambian: marco, hueco y colores fijos. Las hojas y el brillo dependen del estado.
func _build_static_shapes() -> void:
	_frame.color = COLOR_FRAME
	_frame.polygon = _rect(-FRAME_HALF_WIDTH, FRAME_TOP, FRAME_HALF_WIDTH, FRAME_BOTTOM)
	_hole.color = COLOR_HOLE
	_hole.polygon = _rect(-_leaf_half_width(), FRAME_TOP + FRAME_BORDER, _leaf_half_width(), FRAME_BOTTOM - FRAME_BORDER)
	_leaf_left.color = COLOR_LEAF
	_leaf_right.color = COLOR_LEAF
	_leaf_left.position = Vector2(-_leaf_half_width(), 0.0)
	_leaf_right.position = Vector2(_leaf_half_width(), 0.0)
	_glow.polygon = _rect(-FRAME_HALF_WIDTH + 1.0, FRAME_TOP + 1.0, FRAME_HALF_WIDTH - 1.0, FRAME_BOTTOM - 1.0)


func _leaf_half_width() -> float:
	return FRAME_HALF_WIDTH - FRAME_BORDER


# Aplica el estado actual (cerrada / golpeada / rota) a las formas.
func _refresh() -> void:
	_hole.visible = _broken
	_glow.visible = not _broken
	var alpha: float = clampf(GLOW_ALPHA_BASE + GLOW_ALPHA_PER_HIT * _hits, 0.0, 1.0)
	_glow.color = Color(COLOR_GLOW, alpha)
	var bulge: float = 0.0 if _broken else BULGE_PER_HIT * _hits
	_leaf_left.polygon = _leaf_polygon(bulge, 1.0)
	_leaf_right.polygon = _leaf_polygon(bulge, -1.0)
	_leaf_left.rotation = -BROKEN_LEAF_ANGLE if _broken else 0.0
	_leaf_right.rotation = BROKEN_LEAF_ANGLE if _broken else 0.0


# Polígono de una hoja relativo a su bisagra (el borde exterior). [param side] = 1 para la
# izquierda (se extiende hacia +x) y -1 para la derecha (hacia -x). El borde superior se arquea
# hacia arriba [param bulge] px en el centro de la escotilla.
func _leaf_polygon(bulge: float, side: float) -> PackedVector2Array:
	var width: float = _leaf_half_width() - 0.5
	var top: float = FRAME_TOP + FRAME_BORDER
	var bottom: float = FRAME_BOTTOM - FRAME_BORDER
	return PackedVector2Array([
		Vector2(0.0, top),
		Vector2(side * width * 0.5, top - bulge * 0.6),
		Vector2(side * width, top - bulge),
		Vector2(side * width, bottom),
		Vector2(0.0, bottom),
	])


func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


func _setup_gas() -> void:
	_gas.emitting = false
	_gas.one_shot = true
	_gas.explosiveness = 0.85
	_gas.local_coords = false
	_gas.position = Vector2(0.0, FRAME_TOP + FRAME_BORDER)
	_gas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_gas.emission_rect_extents = Vector2(_leaf_half_width(), 1.0)
	_gas.direction = Vector2.UP
	_gas.spread = GAS_SPREAD_DEG
	_gas.gravity = Vector2.ZERO
	_gas.damping_min = 40.0
	_gas.damping_max = 70.0
	_gas.scale_amount_min = GAS_PARTICLE_SIZE * 0.6
	_gas.scale_amount_max = GAS_PARTICLE_SIZE
	_gas.color = COLOR_GAS
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	_gas.color_ramp = ramp


# Suelta una ráfaga de [param amount] partículas.
func _burst_gas(amount: int) -> void:
	var cfg: IntroConfig = _get_config()
	_gas.amount = maxi(1, amount)
	_gas.lifetime = cfg.gas_lifetime
	_gas.initial_velocity_min = cfg.gas_speed * 0.6
	_gas.initial_velocity_max = cfg.gas_speed
	_gas.restart()
	_gas.emitting = true


func _shake_visual(strength: float) -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	_visual.position = Vector2(HIT_SHAKE_PX * strength, 0.0)
	_shake_tween = create_tween()
	_shake_tween.tween_property(_visual, "position", Vector2.ZERO, HIT_SHAKE_TIME) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Fragmentos de las hojas que salen despedidos hacia arriba y caen fuera de pantalla.
func _spawn_debris(count: int) -> void:
	for i: int in maxi(count, 0):
		var piece := Polygon2D.new()
		piece.color = COLOR_LEAF
		piece.polygon = PackedVector2Array([
			Vector2(-DEBRIS_SIZE * 0.5, -DEBRIS_SIZE * 0.5),
			Vector2(DEBRIS_SIZE * randf_range(0.4, 0.9), -DEBRIS_SIZE * 0.2),
			Vector2(0.0, DEBRIS_SIZE * randf_range(0.4, 0.8)),
		])
		var origin: Vector2 = Vector2(randf_range(-_leaf_half_width(), _leaf_half_width()), FRAME_TOP)
		piece.position = origin
		add_child(piece)
		var velocity: Vector2 = Vector2.from_angle(randf_range(-PI * 0.85, -PI * 0.15)) * randf_range(DEBRIS_SPEED_MIN, DEBRIS_SPEED_MAX)
		var spin: float = randf_range(-DEBRIS_SPIN, DEBRIS_SPIN)
		var tween: Tween = create_tween()
		tween.tween_method(_move_debris.bind(piece, origin, velocity, spin), 0.0, DEBRIS_LIFETIME, DEBRIS_LIFETIME)
		tween.tween_callback(piece.queue_free)


# Movimiento parabólico de un fragmento en el instante [param t] (s).
func _move_debris(t: float, piece: Polygon2D, origin: Vector2, velocity: Vector2, spin: float) -> void:
	piece.position = origin + velocity * t + Vector2(0.0, 0.5 * DEBRIS_GRAVITY * t * t)
	piece.rotation = spin * t
