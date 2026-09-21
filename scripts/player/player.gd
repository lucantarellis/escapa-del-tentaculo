class_name Player
extends CharacterBody2D
## Astronauta con jetpack controlado por el jugador.
##
## Propulsa en 4 direcciones (combinables) con inercia, gasta combustible al propulsar y
## tiene gravedad casi nula mientras queda combustible. Sin combustible la gravedad sube y
## puede saltar desde una superficie. Todos los valores salen de [PlayerConfig].
## Ver `docs/mecanicas/jugador.md`.

## Se emite cada vez que cambia el combustible.
signal fuel_changed(current: float, maximum: float)
## Se emite al quedarse sin combustible.
signal fuel_depleted
## Se emite al recuperar combustible después de haber estado vacío.
signal fuel_refilled
## Se emite cuando empieza a propulsar.
signal thrust_started
## Se emite cuando deja de propulsar.
signal thrust_stopped
## Se emite al saltar.
signal jumped
## Se emite al morir. [param cause] identifica el motivo (por ejemplo `&"tentacle"`).
signal died(cause: StringName)
## Se emite al ganar (ver [method win]).
signal won

## Color del cuerpo con combustible (naranja de la paleta). Solo visual.
const COLOR_BODY_NORMAL: Color = Color("#FF6B32")
## Color del cuerpo sin combustible (rojo de la paleta). Solo visual.
const COLOR_BODY_EMPTY: Color = Color("#D83232")
## Distancia del indicador de propulsión al centro del cuerpo. Unidad: px. Solo visual.
const THRUST_INDICATOR_DISTANCE: float = 16.0

## Parámetros de gameplay. Si queda vacío se usan los valores por defecto de [PlayerConfig].
@export var config: PlayerConfig

@onready var _body: Polygon2D = $Body
@onready var _thrust_indicator: Polygon2D = $ThrustIndicator

var _fuel: float = 0.0
## 0 = gravedad con combustible, 1 = gravedad sin combustible.
var _gravity_blend: float = 0.0
var _current_gravity: float = 0.0
var _is_thrusting: bool = false
## true mientras la partida sigue en curso para el jugador (ni murió ni ganó).
var _is_alive: bool = true
var _has_won: bool = false
var _was_empty: bool = false


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_current_gravity = config.gravity_with_fuel
	_was_empty = is_fuel_empty()
	_update_visuals(Vector2.ZERO)
	fuel_changed.emit(_fuel, config.max_fuel)


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var on_floor: bool = is_on_floor()
	# Sobre una superficie el eje horizontal se camina (sin combustible); el jetpack solo
	# se usa solo para subir.
	var walking: bool = on_floor and input.x != 0.0
	var thrust_input: Vector2 = Vector2(0.0, minf(input.y, 0.0)) if on_floor else input
	var thrusting: bool = thrust_input != Vector2.ZERO and _fuel > config.min_fuel_to_thrust
	if walking:
		_apply_walk(input.x, delta)
	if thrusting:
		_apply_thrust(thrust_input, delta)
	elif not walking:
		velocity = velocity.move_toward(Vector2.ZERO, config.coasting_drag * delta)
	_apply_gravity(delta)
	_try_jump()
	_move_with_bounce()
	_update_fuel(thrusting, delta)
	_set_thrusting(thrusting)
	_update_visuals(thrust_input if thrusting else Vector2.ZERO)


## Suma [param amount] de combustible (sin superar `max_fuel`). Lo usan los tanques.
func add_fuel(amount: float) -> void:
	_set_fuel(_fuel + amount)


## Devuelve el combustible como proporción de 0.0 a 1.0.
func get_fuel_ratio() -> float:
	if config.max_fuel <= 0.0:
		return 0.0
	return _fuel / config.max_fuel


## Devuelve el combustible actual. Unidad: u.
func get_fuel() -> float:
	return _fuel


## Devuelve true si el combustible está vacío (<= `jump_empty_threshold`).
func is_fuel_empty() -> bool:
	return _fuel <= config.jump_empty_threshold


## Devuelve true mientras el jetpack está propulsando.
func is_thrusting() -> bool:
	return _is_thrusting


## Devuelve true si en este momento cumple las condiciones para saltar.
func can_jump() -> bool:
	if not _is_alive:
		return false
	if config.jump_requires_empty_fuel and not is_fuel_empty():
		return false
	if config.jump_requires_floor and not is_on_floor():
		return false
	return true


## Devuelve la gravedad que se está aplicando ahora. Unidad: px/s².
func get_current_gravity() -> float:
	return _current_gravity


## Devuelve true mientras la partida sigue en curso para el jugador: está vivo, controlable
## y todavía no ganó. Tras [method die] o [method win] devuelve false; por eso los peligros
## y los tanques, que ignoran a un jugador no vivo, no afectan a quien ya ganó.
func is_alive() -> bool:
	return _is_alive


## Mata al jugador: desactiva el control y emite [signal died] con [param cause].
func die(cause: StringName) -> void:
	if not _is_alive:
		return
	_is_alive = false
	velocity = Vector2.ZERO
	_set_thrusting(false)
	_thrust_indicator.visible = false
	died.emit(cause)


## Devuelve true si el jugador ganó (llamó a [method win]).
func has_won() -> bool:
	return _has_won


## Marca la victoria: desactiva el control, deja al jugador quieto y emite [signal won].
## Desde ese momento [method is_alive] devuelve false, así que nada puede matarlo ni gasta
## combustible. Se ignora si ya murió o ya ganó. La llama el nivel o el game manager.
func win() -> void:
	if not _is_alive:
		return
	_is_alive = false
	_has_won = true
	velocity = Vector2.ZERO
	_set_thrusting(false)
	_thrust_indicator.visible = false
	won.emit()


## Deja al jugador vivo en [param spawn_position] (coordenadas globales), quieto y con
## el combustible inicial.
func reset(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_is_alive = true
	_has_won = false
	_gravity_blend = 0.0
	_current_gravity = config.gravity_with_fuel
	_set_thrusting(false)
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_was_empty = is_fuel_empty()
	fuel_changed.emit(_fuel, config.max_fuel)
	_update_visuals(Vector2.ZERO)


func _apply_thrust(input: Vector2, delta: float) -> void:
	var speed_before: float = velocity.length()
	var accel: Vector2 = input * config.thrust_acceleration
	# El multiplicador se aplica por eje: solo donde la entrada se opone a la velocidad.
	if input.x * velocity.x < 0.0:
		accel.x *= config.counter_thrust_multiplier
	if input.y * velocity.y < 0.0:
		accel.y *= config.counter_thrust_multiplier
	velocity += accel * delta
	# Si ya iba más rápido que max_speed (caída, rebote) no se corta de golpe: decae con drag.
	var speed_cap: float = maxf(config.max_speed, speed_before - config.coasting_drag * delta)
	velocity = velocity.limit_length(speed_cap)


func _apply_walk(direction: float, delta: float) -> void:
	var accel: float = config.walk_acceleration
	if direction * velocity.x < 0.0:
		accel *= config.counter_thrust_multiplier
	# Si ya iba más rápido que walk_max_speed (aterrizó con impulso) decae con drag.
	var speed_cap: float = maxf(config.walk_max_speed, absf(velocity.x) - config.coasting_drag * delta)
	velocity.x = clampf(velocity.x + direction * accel * delta, -speed_cap, speed_cap)


func _apply_gravity(delta: float) -> void:
	var target: float = 1.0 if is_fuel_empty() else 0.0
	if config.gravity_transition_time <= 0.0:
		_gravity_blend = target
	else:
		_gravity_blend = move_toward(_gravity_blend, target, delta / config.gravity_transition_time)
	_current_gravity = lerpf(config.gravity_with_fuel, config.gravity_without_fuel, _gravity_blend)
	# No frena una caída que ya supera el máximo: solo evita acelerar más.
	if velocity.y < config.max_fall_speed:
		velocity.y = minf(velocity.y + _current_gravity * delta, config.max_fall_speed)


func _try_jump() -> void:
	if Input.is_action_just_pressed("jump") and can_jump():
		velocity.y = -config.jump_velocity
		jumped.emit()


func _move_with_bounce() -> void:
	var pre_velocity: Vector2 = velocity
	move_and_slide()
	if config.wall_bounce <= 0.0:
		return
	for i: int in get_slide_collision_count():
		var normal: Vector2 = get_slide_collision(i).get_normal()
		# Componente de la velocidad previa que iba contra la superficie.
		var impact: float = -pre_velocity.dot(normal)
		if impact > config.bounce_min_speed:
			velocity += normal * impact * config.wall_bounce


func _update_fuel(thrusting: bool, delta: float) -> void:
	if thrusting:
		_set_fuel(_fuel - config.fuel_consumption_per_second * delta)
	elif config.fuel_regen_per_second > 0.0:
		_set_fuel(_fuel + config.fuel_regen_per_second * delta)


func _set_fuel(value: float) -> void:
	var new_fuel: float = clampf(value, 0.0, config.max_fuel)
	if is_equal_approx(new_fuel, _fuel):
		return
	_fuel = new_fuel
	fuel_changed.emit(_fuel, config.max_fuel)
	var empty: bool = is_fuel_empty()
	if empty and not _was_empty:
		fuel_depleted.emit()
	elif not empty and _was_empty:
		fuel_refilled.emit()
	_was_empty = empty


func _set_thrusting(value: bool) -> void:
	if value == _is_thrusting:
		return
	_is_thrusting = value
	if value:
		thrust_started.emit()
	else:
		thrust_stopped.emit()


func _update_visuals(thrust_direction: Vector2) -> void:
	_body.color = COLOR_BODY_EMPTY if is_fuel_empty() else COLOR_BODY_NORMAL
	_thrust_indicator.visible = _is_alive and thrust_direction != Vector2.ZERO
	if thrust_direction != Vector2.ZERO:
		_thrust_indicator.position = thrust_direction.normalized() * THRUST_INDICATOR_DISTANCE
