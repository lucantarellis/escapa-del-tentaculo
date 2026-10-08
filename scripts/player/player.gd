class_name Player
extends CharacterBody2D
## Astronauta con jetpack controlado por el jugador.
##
## Propulsa en 4 direcciones (combinables) con inercia, gasta combustible al propulsar y
## tiene gravedad casi nula mientras queda combustible. Sin combustible la gravedad sube y
## puede saltar desde una superficie. Con la acción `dash` se lanza hacia un costado (o en
## diagonal hacia arriba si se mantiene arriba) una distancia fija, a cambio de un poco de combustible y con un tiempo de espera (cooldown).
## Todos los valores salen de [PlayerConfig]. Ver `docs/mecanicas/jugador.md`.

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
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _cooldown_bar: DashCooldownBar = $DashCooldownBar

var _fuel: float = 0.0
## 0 = gravedad con combustible, 1 = gravedad sin combustible.
var _gravity_blend: float = 0.0
var _current_gravity: float = 0.0
var _is_thrusting: bool = false
## true mientras la partida sigue en curso para el jugador (ni murió ni ganó).
var _is_alive: bool = true
var _has_won: bool = false
var _was_empty: bool = false
## true mientras el jugador está congelado (ver [method set_frozen]).
var _frozen: bool = false
## Tiempo que le queda al bloqueo del Input tras un lanzamiento (ver [method launch]). Unidad: s.
var _control_lock_left: float = 0.0
## Dirección (vector unitario) del dash en curso: horizontal o diagonal hacia arriba. Solo vale mientras hay un dash.
var _dash_direction: Vector2 = Vector2.RIGHT
## Velocidad del dash en curso (distancia / duración). Solo vale mientras hay un dash. Unidad: px/s.
var _dash_speed: float = 0.0
## Distancia que le falta recorrer al dash en curso (0 = no hay dash). Unidad: px.
var _dash_distance_left: float = 0.0
## Tiempo que falta para poder hacer otro dash. Unidad: s.
var _dash_cooldown_left: float = 0.0
## Último lado al que se apretó moverse (-1 izquierda, 1 derecha): hacia dónde va el dash
## cuando no se aprieta ninguna dirección.
var _facing: float = 1.0


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_current_gravity = config.gravity_with_fuel
	_was_empty = is_fuel_empty()
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()
	fuel_changed.emit(_fuel, config.max_fuel)


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	# Con el control bloqueado (tras un lanzamiento) no se lee el Input: solo actúan la inercia y la gravedad.
	var locked: bool = _control_lock_left > 0.0
	_control_lock_left = maxf(_control_lock_left - delta, 0.0)
	var input: Vector2 = Vector2.ZERO if locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_tick_dash_cooldown(delta)
	if input.x != 0.0:
		_facing = signf(input.x)
	# Con "arriba" mantenido el dash sale en diagonal hacia arriba; si no, es lateral.
	var dash_up: bool = input.y < 0.0
	if _dash_distance_left <= 0.0 and Input.is_action_just_pressed("dash") and can_dash() and _get_dash_distance(dash_up) > 0.0:
		_start_dash(dash_up)
	# Un dash en curso (o uno que arranca ahora) reemplaza al movimiento normal: sin propulsión,
	# sin caminar, sin gravedad y sin salto hasta que termina.
	if _dash_distance_left > 0.0:
		_process_dash(delta)
		return
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
		# Apoyado y sin propulsar se frena con ground_friction (más fuerte que el aire),
		# para no deslizarse con los pies en el piso; en el aire se usa coasting_drag.
		var stop_drag: float = config.ground_friction if on_floor else config.coasting_drag
		velocity = velocity.move_toward(Vector2.ZERO, stop_drag * delta)
	_apply_gravity(delta)
	if not locked:
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


## Devuelve true si en este momento se puede hacer un dash: el jugador está vivo y con
## control, no hay otro dash en curso ni en cooldown, la distancia es mayor a 0 y alcanza el
## combustible (`dash_fuel_cost`).
func can_dash() -> bool:
	if not _is_alive or is_control_locked() or _dash_distance_left > 0.0:
		return false
	if _dash_cooldown_left > 0.0 or maxf(config.dash_distance, config.dash_diagonal_distance) <= 0.0:
		return false
	return _fuel >= config.dash_fuel_cost


## Devuelve true mientras hay un dash en curso.
func is_dashing() -> bool:
	return _dash_distance_left > 0.0


## Devuelve cuánto se recuperó el cooldown del dash, de 0.0 (recién usado) a 1.0 (listo).
func get_dash_cooldown_ratio() -> float:
	if config.dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cooldown_left / config.dash_cooldown, 0.0, 1.0)


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
	_dash_distance_left = 0.0
	_set_thrusting(false)
	_thrust_indicator.visible = false
	_update_cooldown_bar()
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
	_dash_distance_left = 0.0
	_set_thrusting(false)
	_thrust_indicator.visible = false
	_update_cooldown_bar()
	won.emit()


## Congela o descongela al jugador. Con [param frozen] `true` oculta el cuerpo y el indicador de
## propulsión, detiene su `_physics_process` y desactiva la colisión (no se ve, no se mueve ni
## choca con nada). Con `false` lo revierte. Lo usa la intro mientras el jugador está "detrás de
## la escotilla". [method reset] lo descongela.
func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	set_physics_process(not frozen)
	_body.visible = not frozen
	_collision.set_deferred("disabled", frozen)
	if frozen:
		_dash_distance_left = 0.0
		_thrust_indicator.visible = false
	else:
		_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()


## Lanza al jugador: lo descongela, le da [param launch_velocity] (px/s) y bloquea el Input
## durante [param control_lock] s (propulsión, caminata y salto). En ese tiempo la inercia
## (`coasting_drag`) y la gravedad actúan normalmente y las colisiones también. La cuenta se lleva
## en `_physics_process`. [method reset] la anula. La usa la intro al romperse la escotilla.
func launch(launch_velocity: Vector2, control_lock: float) -> void:
	set_frozen(false)
	velocity = launch_velocity
	_control_lock_left = maxf(control_lock, 0.0)


## Devuelve true mientras el Input está bloqueado por un lanzamiento (ver [method launch]).
func is_control_locked() -> bool:
	return _control_lock_left > 0.0


## Devuelve true si el jugador está congelado (ver [method set_frozen]).
func is_frozen() -> bool:
	return _frozen


## Cambia la config del jugador en plena partida (al entrar a un tier, ver [SegmentTier]). El
## combustible actual se conserva, recortado al máximo de la config nueva.
func apply_config(new_config: PlayerConfig) -> void:
	if new_config == null:
		return
	config = new_config
	_fuel = clampf(_fuel, 0.0, config.max_fuel)
	_was_empty = is_fuel_empty()
	fuel_changed.emit(_fuel, config.max_fuel)


## Deja al jugador vivo en [param spawn_position] (coordenadas globales), quieto y con
## el combustible inicial.
func reset(spawn_position: Vector2) -> void:
	set_frozen(false)
	_control_lock_left = 0.0
	global_position = spawn_position
	velocity = Vector2.ZERO
	_is_alive = true
	_has_won = false
	_gravity_blend = 0.0
	_current_gravity = config.gravity_with_fuel
	_dash_distance_left = 0.0
	_dash_cooldown_left = 0.0
	_facing = 1.0
	_set_thrusting(false)
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_was_empty = is_fuel_empty()
	fuel_changed.emit(_fuel, config.max_fuel)
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()


# Empieza un dash hacia `_facing` (en diagonal hacia arriba si `up`): gasta el combustible y
# arranca el cooldown. Hay que comprobar `can_dash()` antes.
func _start_dash(up: bool) -> void:
	_dash_direction = Vector2(_facing, -1.0).normalized() if up else Vector2(_facing, 0.0)
	_dash_distance_left = _get_dash_distance(up)
	_dash_speed = _dash_distance_left / maxf(config.dash_duration, 0.01)
	_dash_cooldown_left = maxf(config.dash_cooldown, 0.0)
	_set_fuel(_fuel - config.dash_fuel_cost)
	_set_thrusting(false)
	_update_cooldown_bar()


# Avanza el dash en curso un frame, en línea recta. No pasa por `_move_with_bounce`: contra una
# pared se detiene sin rebotar. El último paso se acorta para recorrer exactamente la
# distancia configurada.
func _process_dash(delta: float) -> void:
	var step: float = minf(_dash_speed * delta, _dash_distance_left)
	velocity = _dash_direction * (step / delta)
	move_and_slide()
	_dash_distance_left -= step
	# `is_zero_approx` evita un frame extra por la sobra mínima del redondeo de decimales.
	if _dash_distance_left <= 0.0 or is_zero_approx(_dash_distance_left) or is_on_wall() or is_on_ceiling():
		_end_dash()
	_update_fuel(false, delta)
	_set_thrusting(false)
	_update_visuals(Vector2.ZERO)


# Termina el dash y frena en seco: así el desplazamiento total es la distancia configurada,
# sin deriva extra por la inercia.
func _end_dash() -> void:
	_dash_distance_left = 0.0
	velocity = Vector2.ZERO


# Distancia del dash según el tipo: lateral o diagonal hacia arriba.
func _get_dash_distance(up: bool) -> float:
	return config.dash_diagonal_distance if up else config.dash_distance


func _tick_dash_cooldown(delta: float) -> void:
	if _dash_cooldown_left <= 0.0:
		return
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_update_cooldown_bar()


# La barra solo se ve mientras el dash está en cooldown, si la config lo permite y mientras el
# jugador está vivo y visible.
func _update_cooldown_bar() -> void:
	var should_show: bool = config.show_cooldown_bar and _is_alive and not _frozen \
			and _dash_cooldown_left > 0.0 and config.dash_cooldown > 0.0
	_cooldown_bar.visible = should_show
	if should_show:
		_cooldown_bar.set_ratio(1.0 - _dash_cooldown_left / config.dash_cooldown)


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
