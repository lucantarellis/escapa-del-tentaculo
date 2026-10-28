class_name Player
extends CharacterBody2D
## Astronauta con jetpack controlado por el jugador.
##
## Propulsa en 4 direcciones (combinables) con inercia, gasta combustible al propulsar y
## tiene gravedad casi nula mientras queda combustible. Sin combustible la gravedad sube y
## puede saltar desde una superficie. Con la acción `dash` se lanza en la dirección que se mantiene
## (8 direcciones; sin dirección, hacia el último lado) una distancia fija, a cambio de un poco
## de combustible y con un tiempo de espera (cooldown).
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
## Se emite cuando cambian los puntos de golpe (al recibir un golpe, reaparecer o reiniciar).
signal hit_points_changed(current: int, maximum: int)
## Se emite al recibir un golpe que NO mata (había puntos de golpe de más). [param cause] es el motivo.
signal hit_taken(cause: StringName)
## Se emite al reaparecer con la mejora Reaparecer (en lugar de morir). [param at] es el lugar.
signal respawned(at: Vector2)

## Color del cuerpo con combustible (naranja de la paleta). Solo visual.
## Tinte del jugador mientras dura un impulso de velocidad. Solo visual.
const BOOST_MODULATE: Color = Color(0.7, 1.4, 1.35, 1.0)
const COLOR_BODY_NORMAL: Color = Color("#FF6B32")
## Color del cuerpo sin combustible (rojo de la paleta). Solo visual.
const COLOR_BODY_EMPTY: Color = Color("#D83232")
## Oscurecimiento del cuerpo placeholder por cada golpe recibido (0 a 1). Solo visual.
const HIT_DARKEN_STEP: float = 0.3
## Opacidad baja del parpadeo tras un golpe (0 a 1). Solo visual.
const BLINK_ALPHA: float = 0.3
## Velocidad del parpadeo tras un golpe. Unidad: cambios por segundo. Solo visual.
const BLINK_RATE: float = 12.0
## Múltiplos de `respawn_height` donde se busca un lugar libre al reaparecer. Estructural.
const RESPAWN_SEARCH_SCALES: Array[float] = [1.0, 0.75, 0.5, 1.25, 1.5, 0.25]
## Distancia del indicador de propulsión al centro del cuerpo. Unidad: px. Solo visual.
const THRUST_INDICATOR_DISTANCE: float = 16.0

## Parámetros de gameplay. Si queda vacío se usan los valores por defecto de [PlayerConfig].
@export var config: PlayerConfig

@export_group("Visual")
## Sprites del jugador según los golpes recibidos: el primero es sin golpes, el segundo con 1 golpe,
## el tercero con 2 golpes. Si hay menos que golpes, se repite el último. Con la lista vacía se
## usa el cuerpo placeholder, que se oscurece con cada golpe. El sprite se muestra en el nodo
## `Body/Sprite` (se puede escalar o mover desde ahí). Los dibujos miran a la derecha y se
## espejan si el último lado al que se apretó moverse fue la izquierda.
@export var hit_sprites: Array[Texture2D] = []

@onready var _body: Polygon2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _thrust_indicator: Polygon2D = $ThrustIndicator
@onready var _flame: Sprite2D = $Flame
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
## Multiplicadores de la física del aire del tier actual (ver [method set_physics_scales]).
var _gravity_scale: float = 1.0
var _air_drag_scale: float = 1.0
var _counter_thrust_scale: float = 1.0
## Impulso de velocidad activo (ver [method apply_speed_boost]).
var _boost_left: float = 0.0
var _boost_multiplier: float = 1.0
## true mientras el jugador está congelado (ver [method set_frozen]).
var _frozen: bool = false
## Tiempo que le queda al bloqueo del Input tras un lanzamiento (ver [method launch]). Unidad: s.
var _control_lock_left: float = 0.0
## Dirección (vector unitario, 8 direcciones) del dash en curso. Solo vale mientras hay un dash.
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
## true si el último lado al que se apretó moverse fue la izquierda (el sprite se espeja). Solo visual.
var _look_left: bool = false
## Tiempo que lleva el dash en curso. Solo vale mientras hay un dash. Unidad: s.
var _dash_time: float = 0.0
## Invulnerabilidad del dash (mejora del mercado, ver [PlayerProgress]): cuándo empieza (s desde
## que arranca el dash) y cuánto dura (s). Con `_invuln_time` en 0 no hay invulnerabilidad.
var _invuln_start: float = 0.0
var _invuln_time: float = 0.0
## Causas de muerte que la invulnerabilidad del dash no frena.
var _invuln_unblockable: Array[StringName] = []
## Puntos de golpe: máximo y actuales (1 sin compras: el primer golpe letal mata).
var _max_hp: int = 1
var _hp: int = 1
## Tiempo que falta para poder perder otro punto tras un golpe. Unidad: s.
var _hit_invuln_left: float = 0.0
var _hit_invuln_time: float = 0.0
## Causas de muerte que matan siempre, sin tocar los puntos de golpe.
var _instakill: Array[StringName] = []
## Mejora Reaparecer: si está comprada, si ya se usó en esta partida y cómo reaparece.
var _can_respawn: bool = false
var _respawn_used: bool = false
var _respawn_height: float = 0.0
var _respawn_hp: int = 1
## Config original (sin progreso), de donde se parte cada vez que se aplica el progreso.
var _base_config: PlayerConfig


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	# El progreso (compras del árbol de talentos) se aplica sobre una copia: `player_config.tres` no
	# se toca. Si se compra algo con el nivel ya armado (mercado del título), se reaplica.
	_base_config = config
	_apply_progress()
	PlayerProgress.upgrade_purchased.connect(_on_upgrade_purchased)
	PlayerProgress.progress_reset.connect(_on_progress_reset)
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_current_gravity = config.gravity_with_fuel
	_was_empty = is_fuel_empty()
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()
	fuel_changed.emit(_fuel, config.max_fuel)


func _physics_process(delta: float) -> void:
	if _boost_left > 0.0:
		_boost_left -= delta
		# Tinte mientras dura el impulso (placeholder).
		modulate = BOOST_MODULATE if _boost_left > 0.0 else Color.WHITE
	if _hit_invuln_left > 0.0:
		_hit_invuln_left = maxf(_hit_invuln_left - delta, 0.0)
		var low: bool = _hit_invuln_left > 0.0 and int(_hit_invuln_left * BLINK_RATE) % 2 == 0
		_body.modulate.a = BLINK_ALPHA if low else 1.0
	if not _is_alive:
		return
	# Con el control bloqueado (tras un lanzamiento) no se lee el Input: solo actúan la inercia y la gravedad.
	var locked: bool = _control_lock_left > 0.0
	_control_lock_left = maxf(_control_lock_left - delta, 0.0)
	var input: Vector2 = Vector2.ZERO if locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_tick_dash_cooldown(delta)
	if input.x != 0.0:
		_facing = signf(input.x)
		_look_left = input.x < 0.0
	# Con las dos teclas a la vez el eje se anula: el sprite mira hacia la que se apretó última.
	if not locked:
		if Input.is_action_just_pressed("move_left"):
			_look_left = true
		elif Input.is_action_just_pressed("move_right"):
			_look_left = false
	# El dash sale hacia la dirección que se mantiene (8 direcciones); sin dirección, hacia el
	# último lado al que se apretó.
	var dash_dir: Vector2 = _snap_dash_direction(input)
	if _dash_distance_left <= 0.0 and Input.is_action_just_pressed("dash") and can_dash() and _get_dash_distance(dash_dir) > 0.0:
		_start_dash(dash_dir)
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
		var stop_drag: float = config.ground_friction if on_floor else config.coasting_drag * _air_drag_scale
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


## Devuelve true mientras el dash en curso está en su ventana de invulnerabilidad (mejora del
## mercado): desde `start` hasta `start + time` segundos después de que arrancó el dash.
func is_dash_invulnerable() -> bool:
	if _invuln_time <= 0.0 or _dash_distance_left <= 0.0:
		return false
	return _dash_time >= _invuln_start and _dash_time < _invuln_start + _invuln_time


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
	# La invulnerabilidad del dash frena los golpes, pero no la caída ni el tentáculo.
	if is_dash_invulnerable() and not _invuln_unblockable.has(cause):
		return
	if not _instakill.has(cause):
		# Tras un golpe no se puede perder otro punto durante un rato.
		if _hit_invuln_left > 0.0:
			return
		# Con puntos de más, el golpe resta uno y no mata.
		if _hp > 1:
			_hp -= 1
			_hit_invuln_left = _hit_invuln_time
			_update_visuals(Vector2.ZERO)
			hit_points_changed.emit(_hp, _max_hp)
			hit_taken.emit(cause)
			return
	# Mejora Reaparecer: una vez por partida, en lugar de morir se vuelve más arriba.
	if _can_respawn and not _respawn_used:
		_respawn_used = true
		_respawn(cause)
		return
	_is_alive = false
	velocity = Vector2.ZERO
	_dash_distance_left = 0.0
	_set_thrusting(false)
	_show_thrust(false)
	_update_cooldown_bar()
	died.emit(cause)


## Devuelve los puntos de golpe actuales (1 = el próximo golpe letal mata).
func get_hit_points() -> int:
	return _hp


## Devuelve los puntos de golpe máximos (1 sin mejoras).
func get_max_hit_points() -> int:
	return _max_hp


## Devuelve true mientras el jugador no puede perder otro punto por un golpe reciente.
func is_hit_invulnerable() -> bool:
	return _hit_invuln_left > 0.0


## Devuelve true si todavía puede reaparecer en esta partida (mejora Reaparecer sin usar).
func can_respawn() -> bool:
	return _can_respawn and not _respawn_used


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
	_show_thrust(false)
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
		_show_thrust(false)
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


## Escala la física del aire para el tier actual (ver [SegmentTier]): [param gravity] multiplica la
## gravedad, [param air_drag] el frenado en el aire (`coasting_drag`) y [param counter_thrust] la
## fuerza de la propulsión en contra del movimiento (frenar). 1 = sin cambio. Así el tier no
## duplica la config: todo lo demás sigue saliendo de `config`.
func set_physics_scales(gravity: float, air_drag: float, counter_thrust: float = 1.0) -> void:
	_gravity_scale = maxf(gravity, 0.0)
	_air_drag_scale = maxf(air_drag, 0.0)
	_counter_thrust_scale = maxf(counter_thrust, 0.0)


## Impulso de velocidad (pickup [SpeedBoost]): durante [param duration] s la propulsión y la
## velocidad máxima se multiplican por [param multiplier]. Uno nuevo reinicia la duración.
func apply_speed_boost(duration: float, multiplier: float) -> void:
	_boost_left = maxf(duration, 0.0)
	_boost_multiplier = maxf(multiplier, 1.0)


## Devuelve true mientras dura un impulso de velocidad.
func is_boosted() -> bool:
	return _boost_left > 0.0


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
	_dash_time = 0.0
	_dash_cooldown_left = 0.0
	_boost_left = 0.0
	modulate = Color.WHITE
	_hp = _max_hp
	_hit_invuln_left = 0.0
	_respawn_used = false
	_body.modulate.a = 1.0
	_facing = 1.0
	_look_left = false
	_set_thrusting(false)
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	_was_empty = is_fuel_empty()
	fuel_changed.emit(_fuel, config.max_fuel)
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()
	hit_points_changed.emit(_hp, _max_hp)


# Guarda cómo resiste golpes el jugador (ver [method PlayerProgress.get_survival]) y lo deja con
# todos sus puntos y la reaparición disponible.
func _setup_survival(data: Dictionary) -> void:
	_max_hp = int(data["max_hp"])
	_hp = _max_hp
	_hit_invuln_left = 0.0
	_hit_invuln_time = maxf(float(data["hit_invulnerable_time"]), 0.0)
	_instakill.assign(data["instakill_causes"])
	_can_respawn = bool(data["respawn"])
	_respawn_used = false
	_respawn_height = maxf(float(data["respawn_height"]), 0.0)
	_respawn_hp = int(data["respawn_hp"])
	_body.modulate.a = 1.0
	hit_points_changed.emit(_hp, _max_hp)


# Arma `config` a partir de la config original más las compras del árbol de talentos.
func _apply_progress() -> void:
	config = PlayerProgress.apply_to_player_config(_base_config)
	_setup_dash_invulnerability(PlayerProgress.get_dash_invulnerability())
	_setup_survival(PlayerProgress.get_survival())


# Se compró un nodo del árbol: se reaplican los efectos y se actualiza el combustible inicial.
func _on_upgrade_purchased(_id: StringName) -> void:
	_apply_progress()
	_fuel = clampf(config.starting_fuel, 0.0, config.max_fuel)
	fuel_changed.emit(_fuel, config.max_fuel)
	_update_visuals(Vector2.ZERO)


# Se borró el progreso (Reset all): se vuelve a la config sin compras.
func _on_progress_reset() -> void:
	_on_upgrade_purchased(&"")


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar las conexiones al descargar al jugador.
	if PlayerProgress.upgrade_purchased.is_connected(_on_upgrade_purchased):
		PlayerProgress.upgrade_purchased.disconnect(_on_upgrade_purchased)
	if PlayerProgress.progress_reset.is_connected(_on_progress_reset):
		PlayerProgress.progress_reset.disconnect(_on_progress_reset)


# Reaparece más arriba en lugar de morir: busca un lugar libre desde `respawn_height` px por encima
# de donde murió, queda quieto con `respawn_hp` puntos y con la invulnerabilidad de un golpe.
func _respawn(_cause: StringName) -> void:
	var origin: Vector2 = global_position
	var target: Vector2 = origin + Vector2(0.0, -_respawn_height)
	for scale_factor: float in RESPAWN_SEARCH_SCALES:
		var candidate: Vector2 = origin + Vector2(0.0, -_respawn_height * scale_factor)
		if not test_move(Transform2D(0.0, candidate), Vector2.ZERO, null, 0.08, true):
			target = candidate
			break
	global_position = target
	velocity = Vector2.ZERO
	_dash_distance_left = 0.0
	_set_thrusting(false)
	_hp = _respawn_hp
	_hit_invuln_left = _hit_invuln_time
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()
	hit_points_changed.emit(_hp, _max_hp)
	respawned.emit(target)


# Guarda la invulnerabilidad del dash que da el progreso ({} = sin invulnerabilidad).
func _setup_dash_invulnerability(data: Dictionary) -> void:
	_invuln_start = 0.0
	_invuln_time = 0.0
	_invuln_unblockable.clear()
	if data.is_empty():
		return
	_invuln_start = maxf(float(data["start"]), 0.0)
	# El porcentaje es sobre la duración del dash, así sigue valiendo si esa duración cambia.
	_invuln_time = maxf(config.dash_duration, 0.0) * clampf(float(data["percent"]), 0.0, 100.0) / 100.0
	_invuln_unblockable.assign(data["unblockable"])


# Dirección del dash a partir de la entrada, redondeada a 8 direcciones (unitaria). Sin entrada,
# horizontal hacia `_facing`.
func _snap_dash_direction(input: Vector2) -> Vector2:
	if input.length() < 0.2:
		return Vector2(_facing, 0.0)
	var angle: float = snappedf(input.angle(), PI / 4.0)
	return Vector2.RIGHT.rotated(angle)


# Empieza un dash en `direction` (unitaria, 8 direcciones): gasta el combustible y arranca el
# cooldown. Hay que comprobar `can_dash()` antes.
func _start_dash(direction: Vector2) -> void:
	_dash_direction = direction
	_dash_distance_left = _get_dash_distance(direction)
	_dash_time = 0.0
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
	_dash_time += delta
	# `is_zero_approx` evita un frame extra por la sobra mínima del redondeo de decimales.
	if _dash_distance_left <= 0.0 or is_zero_approx(_dash_distance_left) or is_on_wall() or is_on_ceiling() or (_dash_direction.y > 0.0 and is_on_floor()):
		_end_dash()
	_update_fuel(false, delta)
	_set_thrusting(false)
	_update_visuals(Vector2.ZERO)


# Termina el dash y frena en seco: así el desplazamiento total es la distancia configurada,
# sin deriva extra por la inercia.
func _end_dash() -> void:
	_dash_distance_left = 0.0
	velocity = Vector2.ZERO


# Distancia del dash según la dirección: recta (horizontal o vertical) o diagonal.
func _get_dash_distance(direction: Vector2) -> float:
	var diagonal: bool = absf(direction.x) > 0.1 and absf(direction.y) > 0.1
	return config.dash_diagonal_distance if diagonal else config.dash_distance


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
	var boost: float = _boost_multiplier if _boost_left > 0.0 else 1.0
	var accel: Vector2 = input * config.thrust_acceleration * boost
	# El multiplicador se aplica por eje: solo donde la entrada se opone a la velocidad.
	var counter: float = config.counter_thrust_multiplier * _counter_thrust_scale
	if input.x * velocity.x < 0.0:
		accel.x *= counter
	if input.y * velocity.y < 0.0:
		accel.y *= counter
	velocity += accel * delta
	# Si ya iba más rápido que max_speed (caída, rebote, impulso) no se corta de golpe: decae con drag.
	var speed_cap: float = maxf(config.max_speed * boost, speed_before - config.coasting_drag * _air_drag_scale * delta)
	velocity = velocity.limit_length(speed_cap)


func _apply_walk(direction: float, delta: float) -> void:
	var accel: float = config.walk_acceleration
	if direction * velocity.x < 0.0:
		accel *= config.counter_thrust_multiplier
	# Si ya iba más rápido que walk_max_speed (aterrizó con impulso) decae con drag.
	var speed_cap: float = maxf(config.walk_max_speed, absf(velocity.x) - config.coasting_drag * _air_drag_scale * delta)
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
		velocity.y = minf(velocity.y + _current_gravity * _gravity_scale * delta, config.max_fall_speed)


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
	var base_color: Color = COLOR_BODY_EMPTY if is_fuel_empty() else COLOR_BODY_NORMAL
	var hits_taken: int = _max_hp - _hp
	if hit_sprites.is_empty():
		_sprite.visible = false
		_body.color = base_color.darkened(HIT_DARKEN_STEP * hits_taken)
	else:
		# Con sprites propios, el polígono queda transparente y se muestra el sprite del estado.
		_body.color = Color(base_color, 0.0)
		_sprite.texture = hit_sprites[mini(hits_taken, hit_sprites.size() - 1)]
		# Los dibujos miran a la derecha: se espejan si el último lado apretado fue la izquierda.
		_sprite.flip_h = _look_left
		_sprite.visible = true
		_sprite.modulate = Color(1.0, 0.6, 0.6) if is_fuel_empty() else Color.WHITE
	_show_thrust(_is_alive and thrust_direction != Vector2.ZERO, thrust_direction)


# Muestra u oculta lo que indica la propulsión. Con sprites propios es la llama, fija debajo del
# astronauta sin importar hacia dónde se propulse; sin sprites, el cuadradito que apunta hacia
# [param direction].
func _show_thrust(on: bool, direction: Vector2 = Vector2.ZERO) -> void:
	var use_flame: bool = not hit_sprites.is_empty() and _flame.texture != null
	_flame.visible = on and use_flame
	_thrust_indicator.visible = on and not use_flame
	if on and not use_flame and direction != Vector2.ZERO:
		_thrust_indicator.position = direction.normalized() * THRUST_INDICATOR_DISTANCE
