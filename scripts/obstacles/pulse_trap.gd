@tool
class_name PulseTrap
extends Obstacle
## Trampa intermitente: un bloque que alterna entre inactivo (seguro), aviso (seguro,
## parpadea) y activo (letal).
##
## El ciclo dura `off_time + on_time` y empieza por la fase segura: con `initial_offset` = 0
## la trampa arranca inactiva. Las fases se calculan a partir del tiempo transcurrido.
## Si el jugador está dentro cuando se activa, muere.

## La trampa pasó a estado activo (letal).
signal activated()
## La trampa dejó de estar activa.
signal deactivated()

## Estados del ciclo.
enum State { OFF, WARNING, ON }

## Color inactiva: azul frío `#3A9BBF` con alfa 0,35. Solo visual.
const OFF_COLOR: Color = Color(0.2275, 0.6078, 0.749, 0.35)
## Color de aviso: blanco azulado `#C8E7EA`, alterna con [constant OFF_COLOR]. Solo visual.
const WARNING_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.9)
## Color activa: rojo letal `#D83232`. Solo visual.
const ON_COLOR: Color = Color(0.8471, 0.1961, 0.1961, 1.0)
## Parpadeos por segundo durante el aviso. Solo visual.
const WARNING_BLINK_HZ: float = 6.0

@export_group("Configuración")
## Parámetros del ciclo (ver [PulseTrapConfig]).
@export var config: PulseTrapConfig

var _state: State = State.OFF
var _elapsed: float = 0.0


# Causa por defecto al crear la trampa por código. Al instanciar la escena, el valor lo fija
# PulseTrap.tscn (Godot vuelve a aplicar el valor de la clase base al asignar el script).
func _init() -> void:
	cause = &"trap"


func _ready() -> void:
	# GDScript no llama solo al _ready de la clase base: arma la forma y conecta las señales.
	super()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	if config == null:
		push_warning("PulseTrap '%s' sin config: se usan los valores por defecto." % name)
		config = PulseTrapConfig.new()
	# Estado inicial sin diferir: todavía no hay física en curso.
	_state = _compute_state()
	monitoring = _state == State.ON
	_apply_visual()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var new_state: State = _compute_state()
	if new_state != _state:
		_change_state(new_state)
	if _state == State.WARNING:
		_apply_visual()
	elif _state == State.ON:
		_hit_overlapping_bodies()


## Reinicia el ciclo desde el tiempo cero (respetando `initial_offset`).
func reset() -> void:
	_elapsed = 0.0
	_change_state(_compute_state())


# Fase actual según el tiempo. Orden del ciclo: [0, off_time) segura (con el aviso al final),
# [off_time, off_time + on_time) activa.
func _compute_state() -> State:
	var on_time: float = maxf(config.on_time, 0.0)
	var off_time: float = maxf(config.off_time, 0.0)
	if on_time <= 0.0:
		return State.OFF
	if off_time <= 0.0:
		return State.ON
	var phase: float = fposmod(_elapsed + config.initial_offset, off_time + on_time)
	if phase >= off_time:
		return State.ON
	var warning: float = minf(maxf(config.warning_time, 0.0), off_time)
	if warning > 0.0 and phase >= off_time - warning:
		return State.WARNING
	return State.OFF


func _change_state(new_state: State) -> void:
	var was_on: bool = _state == State.ON
	_state = new_state
	set_active(new_state == State.ON)
	_apply_visual()
	if new_state == State.ON and not was_on:
		activated.emit()
	elif new_state != State.ON and was_on:
		deactivated.emit()


func _apply_visual() -> void:
	match _state:
		State.OFF:
			_body.color = OFF_COLOR
		State.WARNING:
			var blink_on: bool = int(_elapsed * WARNING_BLINK_HZ * 2.0) % 2 == 0
			_body.color = WARNING_COLOR if blink_on else OFF_COLOR
		State.ON:
			_body.color = ON_COLOR


# Red de seguridad para "el jugador ya estaba dentro cuando se activó": no depende de que
# Godot emita body_entered al reactivar el monitoreo con un cuerpo superpuesto.
func _hit_overlapping_bodies() -> void:
	if not monitoring:
		return
	for body: Node2D in get_overlapping_bodies():
		_try_hit(body)
