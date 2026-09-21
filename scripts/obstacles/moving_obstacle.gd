@tool
class_name MovingObstacle
extends Obstacle
## Obstáculo móvil: un bloque letal que va y viene entre su posición inicial y
## `inicial + travel`.
##
## Ciclo: espera `start_delay`, va al extremo final, pausa, vuelve, pausa, y repite. La
## posición se calcula a partir del tiempo transcurrido, sin acumular error.
## En el editor (`@tool`) dibuja la trayectoria y el bloque en su posición final.

## Color de la ayuda de trayectoria en el editor. Solo visual (no se dibuja al jugar).
const PATH_COLOR: Color = Color(0.8471, 0.1961, 0.1961, 0.6)
## Grosor de la ayuda de trayectoria en el editor. Solo visual.
const PATH_WIDTH: float = 2.0

@export_group("Recorrido")
## Desplazamiento del extremo final respecto de la posición inicial. Es diseño de nivel.
## Unidad: px.
@export var travel: Vector2 = Vector2(120.0, 0.0):
	set(value):
		travel = value
		queue_redraw()

@export_group("Configuración")
## Parámetros de movimiento (ver [MovingObstacleConfig]).
@export var config: MovingObstacleConfig

var _origin: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0


func _ready() -> void:
	# GDScript no llama solo al _ready de la clase base: arma la forma y conecta las señales.
	super()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	_origin = position
	if config == null:
		push_warning("MovingObstacle '%s' sin config: se usan los valores por defecto." % name)
		config = MovingObstacleConfig.new()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position = _origin + travel * _get_progress()


## Vuelve a la posición inicial y reinicia el ciclo (incluida la espera `start_delay`).
func reset() -> void:
	_elapsed = 0.0
	position = _origin


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_line(Vector2.ZERO, travel, PATH_COLOR, PATH_WIDTH)
	draw_rect(Rect2(travel - size * 0.5, size), PATH_COLOR, false, PATH_WIDTH)


# Progreso del recorrido, de 0 (inicio) a 1 (extremo final), según el tiempo transcurrido.
func _get_progress() -> float:
	var length: float = travel.length()
	var t: float = _elapsed - config.start_delay
	if length < 0.01 or config.speed <= 0.0 or t <= 0.0:
		return 0.0
	var move_time: float = length / config.speed
	var pause: float = maxf(config.pause_at_ends, 0.0)
	var c: float = fmod(t, 2.0 * (move_time + pause))
	var progress: float = 0.0
	if c < move_time:
		progress = c / move_time
	elif c < move_time + pause:
		progress = 1.0
	elif c < 2.0 * move_time + pause:
		progress = 1.0 - (c - move_time - pause) / move_time
	if config.ease_at_ends:
		progress = smoothstep(0.0, 1.0, progress)
	return progress
