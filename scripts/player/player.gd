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
## Se emite cuando el escudo del botiquín aparece (`active` = true) o desaparece (false).
signal shield_changed(active: bool)

## Tinte del jugador mientras dura un impulso de velocidad. Solo visual.
const BOOST_MODULATE: Color = Color(0.7, 1.4, 1.35, 1.0)
## Tinte rojizo del sprite del astronauta sin combustible. Solo visual.
const EMPTY_FUEL_TINT: Color = Color(1.0, 0.6, 0.6)
## Opacidad baja del parpadeo tras un golpe (0 a 1). Solo visual.
const BLINK_ALPHA: float = 0.3
## Velocidad del parpadeo tras un golpe. Unidad: cambios por segundo. Solo visual.
const BLINK_RATE: float = 12.0
## Múltiplos de `respawn_height` donde se busca un lugar libre al reaparecer. Estructural.
const RESPAWN_SEARCH_SCALES: Array[float] = [1.0, 0.75, 0.5, 1.25, 1.5, 0.25]
## Máximo de plataformas rompibles que un mismo paso del dash puede romper en fila. Estructural.
## Vibración del celular al recibir un golpe y al morir (si está activa en Ajustes). Unidad: ms.
## Solo visual.
const HIT_VIBRATION_MS: int = 80
const DEATH_VIBRATION_MS: int = 200
## Carpeta de las hojas de efectos del jugador (PNG + JSON de Aseprite). Estructural.
const FX_DIR: String = "res://assets/sprites/fx/"
## Escudo del botiquín (`player_shield`, óvalo que cubre al astronauta entero más la llama): centro
## respecto del origen del jugador (px) y cuánto antes de terminar empieza a parpadear (s). Solo
## visual.
const SHIELD_CENTER: Vector2 = Vector2(0.0, 7.0)
const SHIELD_BLINK_TIME: float = 1.0
## Centro del cuerpo respecto del origen del jugador: ahí van la reparación (`player_repair`, misma
## celda que `Body/Sprite`) y el centro de la fuga del traje (px). Solo visual.
const BODY_CENTER: Vector2 = Vector2(0.0, -8.0)
## Destello de reparación sobre el cuerpo (`shaders/repair_flash.gdshader`): duración (s). Solo
## visual.
const REPAIR_FLASH_TIME: float = 0.6
## Reaparición (`player_respawn`): posición respecto del jugador (px; las 40 filas de abajo coinciden
## con la celda del astronauta) y desde qué cuadro de `respawn` (0 = primero) aparece el astronauta
## con fundido. Solo visual.
const RESPAWN_FX_OFFSET: Vector2 = Vector2(0.0, -16.0)
const RESPAWN_FADE_FROM_FRAME: int = 2
## Rastro del dash: cada cuánto se deja un "fantasma" (s), máximo por dash, tinte, alfa inicial y
## duración del desvanecimiento (s). Solo visual.
const DASH_GHOST_INTERVAL: float = 0.03
const DASH_GHOST_MAX: int = 4
const DASH_GHOST_COLOR: Color = Color("63D6C5")
const DASH_GHOST_ALPHA: float = 0.5
const DASH_GHOST_FADE: float = 0.2
## Fuga del traje con 1 punto de golpe: semiejes del borde del traje desde [constant BODY_CENTER]
## (px), separación mínima entre ráfagas seguidas (grados), apertura de cada ráfaga (grados),
## partículas por ráfaga, espera entre ráfagas (s), vida (s), velocidad (px/s) y freno. Solo visual.
const LEAK_RADIUS: Vector2 = Vector2(10.0, 13.0)
const LEAK_MIN_TURN_DEG: float = 60.0
const LEAK_SPREAD_DEG: float = 15.0
const LEAK_AMOUNT_MIN: int = 2
const LEAK_AMOUNT_MAX: int = 4
const LEAK_INTERVAL_MIN: float = 0.5
const LEAK_INTERVAL_MAX: float = 0.9
const LEAK_LIFETIME: float = 0.4
const LEAK_SPEED_MIN: float = 40.0
const LEAK_SPEED_MAX: float = 70.0
const LEAK_DAMPING: float = 140.0
const DASH_BREAK_MAX_CHAIN: int = 4
## Sufijo de la animación según los golpes recibidos: el índice es la cantidad de golpes y el último
## vale para 2 o más (`idle`, `idle_dano_1`, `idle_dano_2`). Solo visual.
const DAMAGE_SUFFIXES: Array[String] = ["", "_dano_1", "_dano_2"]
## Animaciones de una sola pasada (sin loop). El Wizard importa todo en loop y los tags no se pueden
## renombrar con el prefijo `_`, así que se corrige al cargar. Solo visual.
const ONE_SHOT_ANIMATIONS: Array[StringName] = [&"jump"]
## Velocidad horizontal mínima desde la que, en el suelo, se ve el trote en lugar de `idle`.
## Unidad: px/s. Solo visual.
const WALK_MIN_SPEED: float = 8.0
## Velocidad horizontal mínima desde la que, propulsando sin entrada lateral, se ve `thrust_side`.
## Unidad: px/s. Solo visual.
const SIDE_THRUST_MIN_SPEED: float = 30.0
## Centro de la llama del jetpack respecto del centro del sprite del astronauta. Con el sprite
## espejado, X cambia de signo. Unidad: px. Solo visual.
const FLAME_OFFSET: Vector2 = Vector2(-8.0, 20.0)
## Punto de fuga de gas (daño 2) respecto del centro del sprite, para partículas futuras. Con el
## sprite espejado, X cambia de signo. Unidad: px. Solo visual.
const GAS_VENT_OFFSET: Vector2 = Vector2(-2.0, 9.0)
## Tiempo con que se enciende la luz del astronauta al salir de la escotilla. Solo visual. Unidad: s.
const LIGHT_FADE_IN: float = 0.3

## Parámetros de gameplay. Si queda vacío se usan los valores por defecto de [PlayerConfig].
@export var config: PlayerConfig

# Visual: `Body/Sprite` (cuerpo) y `Body/Visor` (brillo del visor, encima) son AnimatedSprite2D con los
# SpriteFrames del Wizard; `Flame` (detrás) solo se ve al propulsar. Los dibujos miran a la derecha y
# se espejan si el último lado al que se apretó moverse fue la izquierda.
@onready var _body: Node2D = $Body
@onready var _sprite: AnimatedSprite2D = $Body/Sprite
@onready var _visor: AnimatedSprite2D = $Body/Visor
@onready var _flame: AnimatedSprite2D = $Flame
@onready var _gas_vent: Marker2D = $GasVent
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
## Luz principal de la nave oscura (ver [LevelLighting]) y su encendido.
var _light: PointLight2D
var _light_tween: Tween
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
## Animación base (sin sufijo de daño) y animación completa que se están mostrando. Solo visual.
var _anim_base: StringName = &""
var _anim_current: StringName = &""
## Última dirección de propulsión con que se actualizó el visual (para refrescar sin cortar la animación).
var _last_thrust_direction: Vector2 = Vector2.ZERO
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
## Tiempo que le queda al escudo del botiquín. Mientras es mayor que 0 absorbe un golpe común.
## Unidad: s.
var _shield_left: float = 0.0
## Efectos del jugador (hojas de `assets/sprites/fx/`), creados en `_setup_fx`.
var _shield_fx: SheetSprite
var _repair_fx: SheetSprite
var _respawn_fx: SheetSprite
var _repair_material: ShaderMaterial
var _repair_tween: Tween
## Material que tenía `Body/Sprite` antes del destello de reparación (se restaura al terminar).
var _sprite_material: Material
## Fundido del astronauta al reaparecer: mientras dura, el parpadeo de invulnerabilidad espera.
var _respawn_fade_tween: Tween
var _respawn_fading: bool = false
## Rastro del dash: tiempo hasta el próximo fantasma y cuántos dejó el dash en curso.
var _ghost_left: float = 0.0
var _ghost_count: int = 0
## Fuga del traje: un emisor por forma de bocanada, el temporizador de ráfagas y el último ángulo.
var _leak_emitters: Array[CPUParticles2D] = []
var _leak_timer: Timer
var _leak_angle: float = 0.0
## Causas de muerte de las que Reaparecer no salva (los perseguidores).
var _no_respawn: Array[StringName] = []
## Mejora Reaparecer: si está comprada, si ya se usó en esta partida y cómo reaparece.
var _can_respawn: bool = false
var _respawn_used: bool = false
var _respawn_height: float = 0.0
var _respawn_hp: int = 1
## Config original (sin progreso), de donde se parte cada vez que se aplica el progreso.
var _base_config: PlayerConfig
## Mejora "Rompe plataformas": el dash rompe las plataformas rompibles que toca.
var _dash_breaks: bool = false
## Plataformas rotas por el dash en curso: el jugador las atraviesa hasta que termina el dash.
var _dash_excepted: Array[Platform] = []


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
	_setup_sprites()
	_setup_light()
	_setup_fx()
	hit_points_changed.connect(_on_own_hit_points_changed)
	_update_visuals(Vector2.ZERO)
	_update_cooldown_bar()
	fuel_changed.emit(_fuel, config.max_fuel)


func _process(_delta: float) -> void:
	# El visor copia animación y cuadro del cuerpo (mismos tags y duraciones) para no desfasarse.
	_visor.animation = _sprite.animation
	_visor.frame = _sprite.frame


func _physics_process(delta: float) -> void:
	if _boost_left > 0.0:
		_boost_left -= delta
		# Tinte mientras dura el impulso (placeholder).
		modulate = BOOST_MODULATE if _boost_left > 0.0 else Color.WHITE
	if _shield_left > 0.0:
		_shield_left = maxf(_shield_left - delta, 0.0)
		_update_shield_visual()
		if _shield_left <= 0.0:
			_pop_shield()
			shield_changed.emit(false)
	if _hit_invuln_left > 0.0:
		_hit_invuln_left = maxf(_hit_invuln_left - delta, 0.0)
		# Mientras el astronauta aparece con fundido (Reaparecer), el parpadeo espera.
		if not _respawn_fading:
			var low: bool = _hit_invuln_left > 0.0 and int(_hit_invuln_left * BLINK_RATE) % 2 == 0
			_body.modulate.a = BLINK_ALPHA if low else 1.0
	# Terminado el dash, las plataformas que rompió vuelven a poder chocar con el jugador.
	if _dash_distance_left <= 0.0 and not _dash_excepted.is_empty():
		_clear_dash_exceptions()
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
		# El escudo del botiquín absorbe el golpe y se rompe (no frena a las `instakill_causes`). Sin
		# parpadeo ni invulnerabilidad: el golpe no cuenta como golpe recibido.
		if _shield_left > 0.0:
			_shield_left = 0.0
			_pop_shield()
			shield_changed.emit(false)
			return
		# Con puntos de más, el golpe resta uno y no mata.
		if _hp > 1:
			_hp -= 1
			_hit_invuln_left = _hit_invuln_time
			_update_visuals(_last_thrust_direction)
			hit_points_changed.emit(_hp, _max_hp)
			hit_taken.emit(cause)
			GameSettings.vibrate(HIT_VIBRATION_MS)
			return
	# Mejora Reaparecer: una vez por partida, en lugar de morir se vuelve más arriba.
	if _can_respawn and not _respawn_used and not _no_respawn.has(cause):
		_respawn_used = true
		_respawn(cause)
		return
	_is_alive = false
	velocity = Vector2.ZERO
	_dash_distance_left = 0.0
	_set_thrusting(false)
	_show_thrust(false)
	_update_cooldown_bar()
	_update_leak()
	GameSettings.vibrate(DEATH_VIBRATION_MS)
	died.emit(cause)


## Cura hasta [param amount] puntos de golpe (sin pasar del máximo). Devuelve cuántos curó de
## verdad. Un [param amount] menor que 0 cura todos. No hace nada si el jugador no está vivo.
func heal(amount: int) -> int:
	if not _is_alive:
		return 0
	var missing: int = _max_hp - _hp
	var healed: int = missing if amount < 0 else mini(amount, missing)
	if healed > 0:
		_hp += healed
		hit_points_changed.emit(_hp, _max_hp)
		_play_repair()
	return healed


## Devuelve true si al jugador le falta algún punto de golpe.
func needs_healing() -> bool:
	return _hp < _max_hp


## Da un escudo de [param duration] s que absorbe el próximo golpe común (no frena a los
## perseguidores ni a la caída). Con [param duration] negativo (-1) no tiene tiempo: dura hasta que
## absorbe un golpe. Si ya tenía, se renueva. Unidad: s.
func give_shield(duration: float) -> void:
	if not _is_alive or duration == 0.0:
		return
	var was_active: bool = _shield_left > 0.0
	_shield_left = INF if duration < 0.0 else duration
	_update_shield_visual()
	if not was_active:
		shield_changed.emit(true)


## Devuelve true mientras el escudo del botiquín está activo.
func has_shield() -> bool:
	return _shield_left > 0.0


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
	_set_light_on(not frozen)
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
	_shield_left = 0.0
	_update_shield_visual()
	_reset_fx()
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
	_no_respawn.assign(data.get("no_respawn_causes", []))
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
	_dash_breaks = PlayerProgress.has_dash_break()
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
	_spawn_vanish(origin)
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
	_play_respawn()
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
	_ghost_count = 0
	_ghost_left = 0.0


# Avanza el dash en curso un frame, en línea recta. No pasa por `_move_with_bounce`: contra una
# pared se detiene sin rebotar. El último paso se acorta para recorrer exactamente la
# distancia configurada.
func _process_dash(delta: float) -> void:
	var step: float = minf(_dash_speed * delta, _dash_distance_left)
	if _dash_breaks:
		_break_platforms_ahead(_dash_direction * step)
	velocity = _dash_direction * (step / delta)
	_tick_dash_ghosts(delta)
	move_and_slide()
	_dash_distance_left -= step
	_dash_time += delta
	# `is_zero_approx` evita un frame extra por la sobra mínima del redondeo de decimales.
	if _dash_distance_left <= 0.0 or is_zero_approx(_dash_distance_left) or is_on_wall() or is_on_ceiling() or (_dash_direction.y > 0.0 and is_on_floor()):
		_end_dash()
	_update_fuel(false, delta)
	_set_thrusting(false)
	_update_visuals(Vector2.ZERO)


# Con "Rompe plataformas": si el paso del dash choca con una plataforma rompible, la rompe y la
# deja atravesar (el choque se ignora hasta que termina el dash). Repite por si hay varias en fila.
func _break_platforms_ahead(motion: Vector2) -> void:
	var hit: KinematicCollision2D = KinematicCollision2D.new()
	for i: int in DASH_BREAK_MAX_CHAIN:
		if not test_move(global_transform, motion, hit):
			return
		var platform: Platform = hit.get_collider() as Platform
		if platform == null or not platform.break_now():
			return
		add_collision_exception_with(platform)
		_dash_excepted.append(platform)


func _clear_dash_exceptions() -> void:
	for platform: Platform in _dash_excepted:
		if is_instance_valid(platform):
			remove_collision_exception_with(platform)
	_dash_excepted.clear()


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
	_last_thrust_direction = thrust_direction
	var thrusting: bool = _is_alive and thrust_direction != Vector2.ZERO
	_set_body_animation(_pick_base_animation(thrusting, thrust_direction))
	# Los dibujos miran a la derecha: se espejan si el último lado apretado fue la izquierda.
	_sprite.flip_h = _look_left
	_visor.flip_h = _look_left
	_sprite.modulate = EMPTY_FUEL_TINT if is_fuel_empty() else Color.WHITE
	_place_attachments()
	_show_thrust(thrusting)


# Estado base según el movimiento: propulsando (`thrust_side` si hay entrada o velocidad lateral, si
# no `thrust`), en el suelo (`walk` o `idle`) o en el aire sin propulsar (`jump`).
func _pick_base_animation(thrusting: bool, thrust_direction: Vector2) -> StringName:
	if thrusting:
		var sideways: bool = thrust_direction.x != 0.0 or absf(velocity.x) > SIDE_THRUST_MIN_SPEED
		return &"thrust_side" if sideways else &"thrust"
	if is_on_floor():
		return &"walk" if absf(velocity.x) > WALK_MIN_SPEED else &"idle"
	return &"jump"


# Sufijo de daño según los golpes recibidos (0 = ninguno, 1 = `_dano_1`, 2 o más = `_dano_2`).
func _damage_suffix() -> String:
	return DAMAGE_SUFFIXES[clampi(_max_hp - _hp, 0, DAMAGE_SUFFIXES.size() - 1)]


# Cambia la animación del cuerpo. Si solo cambió el sufijo de daño, conserva el cuadro (y su avance)
# para que no salte; si cambió el estado base, arranca del primer cuadro.
func _set_body_animation(base: StringName) -> void:
	var anim: StringName = StringName(String(base) + _damage_suffix())
	if anim == _anim_current:
		return
	var keep_frame: bool = base == _anim_base and _sprite.sprite_frames.has_animation(anim)
	var frame: int = _sprite.frame
	var progress: float = _sprite.frame_progress
	_anim_base = base
	_anim_current = anim
	_sprite.play(anim)
	if keep_frame:
		_sprite.set_frame_and_progress(frame, progress)


# Pone la llama y el punto de fuga de gas respecto del centro del sprite, espejando X con él.
func _place_attachments() -> void:
	var side: float = -1.0 if _look_left else 1.0
	_flame.flip_h = _look_left
	_flame.position = _sprite.position + Vector2(FLAME_OFFSET.x * side, FLAME_OFFSET.y)
	_gas_vent.position = _sprite.position + Vector2(GAS_VENT_OFFSET.x * side, GAS_VENT_OFFSET.y)


# Todo el arte de una sola pasada (ver ONE_SHOT_ANIMATIONS) deja de repetirse en loop.
func _setup_sprites() -> void:
	for frames: SpriteFrames in [_sprite.sprite_frames, _visor.sprite_frames]:
		for suffix: String in DAMAGE_SUFFIXES:
			for base: StringName in ONE_SHOT_ANIMATIONS:
				var anim: StringName = StringName(String(base) + suffix)
				if frames.has_animation(anim):
					frames.set_animation_loop(anim, false)


# Luz principal de la nave oscura: el jugador descubre el entorno al subir (ver [LevelLighting]).
func _setup_light() -> void:
	var cfg: LightingConfig = LevelLighting.get_config()
	var light: PointLight2D = LevelLighting.make_light(cfg.player_color, cfg.player_energy, cfg.player_radius, cfg.player_height, cfg.player_core)
	add_child(light)
	_light = light
	_set_light_on(not _frozen)
	if not cfg.player_self_lit:
		# El astronauta se dibuja siempre con su color (sin oscuridad ni luces): su propia luz no lo
		# quema y se lee igual en cualquier lugar.
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		for sprite: CanvasItem in [_flame, _sprite, _visor]:
			if sprite.material == null:
				sprite.material = unshaded


# Prende o apaga la luz del astronauta. Congelado (antes de la intro) no se ve ni ilumina: sin esto
# su luz quedaba prendida en el punto de aparición, al costado de la escotilla. Al prenderse sube
# en `LIGHT_FADE_IN` s para no aparecer de golpe.
func _set_light_on(on: bool) -> void:
	if _light == null:
		return
	if _light_tween != null:
		_light_tween.kill()
	if not on:
		_light.enabled = false
		return
	var target: float = LevelLighting.get_config().player_energy
	_light.enabled = true
	_light.energy = 0.0
	_light_tween = create_tween()
	_light_tween.tween_property(_light, "energy", target, LIGHT_FADE_IN)


# Muestra u oculta la llama del jetpack (detrás del cuerpo, visible solo mientras se propulsa).
func _show_thrust(on: bool) -> void:
	_flame.visible = on


# Muestra u oculta el escudo (placeholder: óvalo cian con relleno translúcido). Parpadea el último segundo.
func _update_shield_visual() -> void:
	if _shield_fx == null:
		return
	if _shield_left > 0.0:
		if not _shield_fx.visible or _shield_fx.get_tag() != &"loop":
			_shield_fx.visible = true
			_shield_fx.play(&"loop", true)
		var blinking: bool = _shield_left < SHIELD_BLINK_TIME and int(_shield_left * BLINK_RATE) % 2 == 0
		_shield_fx.modulate.a = BLINK_ALPHA if blinking else 1.0
	elif _shield_fx.get_tag() != &"pop":
		_shield_fx.visible = false


# El escudo se rompe (absorbió un golpe o venció): `pop` una vez y se oculta al terminar.
func _pop_shield() -> void:
	if _shield_fx == null:
		return
	_shield_fx.modulate.a = 1.0
	_shield_fx.visible = true
	_shield_fx.play(&"pop")


# Hoja de efecto (PNG + JSON de Aseprite) sin sombreado: la capa emisiva de estos efectos es copia
# del color, así que todo el efecto brilla.
static func _make_fx(sheet: String) -> SheetSprite:
	var fx: SheetSprite = SheetSprite.new()
	fx.texture = load(FX_DIR + sheet + ".png")
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	fx.material = unshaded
	fx.load_sheet(FX_DIR + sheet + ".json")
	fx.visible = false
	return fx


func _setup_fx() -> void:
	_shield_fx = _make_fx("player_shield")
	_shield_fx.name = "ShieldFx"
	_shield_fx.position = SHIELD_CENTER
	_shield_fx.finished.connect(_on_shield_fx_finished)
	add_child(_shield_fx)
	_repair_fx = _make_fx("player_repair")
	_repair_fx.name = "RepairFx"
	_repair_fx.position = BODY_CENTER
	_repair_fx.finished.connect(func(_tag: StringName) -> void: _repair_fx.visible = false)
	add_child(_repair_fx)
	_respawn_fx = _make_fx("player_respawn")
	_respawn_fx.name = "RespawnFx"
	_respawn_fx.position = RESPAWN_FX_OFFSET
	_respawn_fx.finished.connect(func(_tag: StringName) -> void: _respawn_fx.visible = false)
	add_child(_respawn_fx)
	_repair_material = ShaderMaterial.new()
	_repair_material.shader = load("res://shaders/repair_flash.gdshader")
	_setup_leak()


func _on_shield_fx_finished(tag: StringName) -> void:
	if tag == &"pop" and _shield_left <= 0.0:
		_shield_fx.visible = false


# Deja los efectos como al empezar (reinicio): sin escudo, reparación, reaparición ni fuga.
func _reset_fx() -> void:
	if _shield_fx == null:
		return
	_shield_fx.visible = false
	_shield_fx.play(&"loop", true)
	_repair_fx.visible = false
	_respawn_fx.visible = false
	_stop_repair_flash()
	if _respawn_fade_tween != null and _respawn_fade_tween.is_valid():
		_respawn_fade_tween.kill()
	_respawn_fading = false
	_update_leak()


# Reparación: la cruz con chispas (`repair`) y el barrido cian sobre el cuerpo.
func _play_repair() -> void:
	if _repair_fx == null:
		return
	_repair_fx.visible = true
	_repair_fx.play(&"repair")
	_play_repair_flash()


# Pone el shader de destello en `Body/Sprite` y anima `progress` 0 → 1; al terminar devuelve el
# material de antes, así fuera del efecto no cambia nada.
func _play_repair_flash() -> void:
	_stop_repair_flash()
	_sprite_material = _sprite.material
	var frame: Texture2D = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	var half: float = float(frame.get_height()) * 0.5 if frame != null else 20.0
	_repair_material.set_shader_parameter("frame_top", _sprite.offset.y - half)
	_repair_material.set_shader_parameter("frame_bottom", _sprite.offset.y + half)
	_repair_material.set_shader_parameter("progress", 0.0)
	_sprite.material = _repair_material
	_repair_tween = create_tween()
	_repair_tween.tween_method(func(value: float) -> void: _repair_material.set_shader_parameter("progress", value), 0.0, 1.0, REPAIR_FLASH_TIME)
	_repair_tween.tween_callback(_stop_repair_flash)


func _stop_repair_flash() -> void:
	if _repair_tween != null and _repair_tween.is_valid():
		_repair_tween.kill()
	_repair_tween = null
	if _sprite.material == _repair_material:
		_sprite.material = _sprite_material


# Destello donde el jugador iba a morir: nodo suelto en el nivel que se libera al terminar.
func _spawn_vanish(at: Vector2) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var fx: SheetSprite = _make_fx("player_respawn")
	fx.name = "VanishFx"
	parent.add_child(fx)
	fx.global_position = at + RESPAWN_FX_OFFSET
	fx.visible = true
	fx.finished.connect(func(_tag: StringName) -> void: fx.queue_free())
	fx.play(&"vanish")


## Modo guionado: la física y el Input se apagan (la colisión sigue) y el astronauta camina en el
## lugar mirando hacia [param direction] (-1 izquierda, +1 derecha) mientras quien lo llama le cambia
## la posición. Con `false` vuelve al control normal. Lo usa el [Hub] para entrar y salir de las
## puertas.
func set_scripted(active: bool, direction: float = 0.0) -> void:
	set_physics_process(not active)
	if active:
		_facing = signf(direction) if direction != 0.0 else _facing
		_look_left = _facing < 0.0
		velocity = Vector2(_facing * WALK_MIN_SPEED * 4.0, 0.0)
	else:
		velocity = Vector2.ZERO
	_update_visuals(Vector2.ZERO)


## Opacidad del cuerpo (0–1). La usa el [Hub] para que el astronauta se pierda en el hueco de la
## puerta.
func set_body_alpha(alpha: float) -> void:
	_body.modulate.a = alpha


## Hace aparecer al jugador con la animación de reaparición (haz y fundido), sin tocar la vida ni la
## posición. Lo usa el [Hub] al empezar, después de [method set_frozen].
func play_appear() -> void:
	_play_respawn()


# Haz en la nueva posición y fundido del astronauta desde el cuadro RESPAWN_FADE_FROM_FRAME de
# `respawn`; después sigue el parpadeo de invulnerabilidad de siempre.
func _play_respawn() -> void:
	if _respawn_fx == null:
		return
	_respawn_fx.visible = true
	_respawn_fx.play(&"respawn")
	var sheet: Dictionary = SheetSprite.get_sheet(FX_DIR + "player_respawn.json")
	var range_: Vector2i = sheet.tags[&"respawn"]
	var durations: PackedFloat32Array = sheet.durations
	var wait: float = 0.0
	var fade: float = 0.0
	for index: int in range(range_.x, range_.y + 1):
		if index - range_.x < RESPAWN_FADE_FROM_FRAME:
			wait += durations[index]
		else:
			fade += durations[index]
	if _respawn_fade_tween != null and _respawn_fade_tween.is_valid():
		_respawn_fade_tween.kill()
	_respawn_fading = true
	_body.modulate.a = 0.0
	_respawn_fade_tween = create_tween()
	_respawn_fade_tween.tween_interval(wait)
	_respawn_fade_tween.tween_property(_body, "modulate:a", 1.0, maxf(fade, 0.01))
	_respawn_fade_tween.tween_callback(func() -> void: _respawn_fading = false)


# Rastro del dash: cada DASH_GHOST_INTERVAL deja una copia del cuadro actual del cuerpo, cian y
# semitransparente, que se desvanece sola.
func _tick_dash_ghosts(delta: float) -> void:
	_ghost_left -= delta
	if _ghost_left > 0.0 or _ghost_count >= DASH_GHOST_MAX:
		return
	_ghost_left = DASH_GHOST_INTERVAL
	_ghost_count += 1
	var parent: Node = get_parent()
	var frame: Texture2D = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if parent == null or frame == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = frame
	ghost.flip_h = _sprite.flip_h
	ghost.offset = _sprite.offset
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ghost.material = unshaded
	ghost.modulate = Color(DASH_GHOST_COLOR, DASH_GHOST_ALPHA)
	parent.add_child(ghost)
	# Detrás del jugador.
	parent.move_child(ghost, get_index())
	ghost.global_position = _sprite.global_position
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, DASH_GHOST_FADE)
	tween.tween_callback(ghost.queue_free)


# Fuga del traje: un emisor por forma de bocanada (`gas_puff_a/b/c`) con el shader de recolor, y un
# temporizador que dispara ráfagas cortas.
func _setup_leak() -> void:
	var leak_material: ShaderMaterial = ShaderMaterial.new()
	leak_material.shader = load("res://shaders/suit_leak.gdshader")
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	for shape: String in ["a", "b", "c"]:
		var leak: CPUParticles2D = CPUParticles2D.new()
		leak.name = "Leak" + shape.to_upper()
		leak.texture = load(FX_DIR + "gas_puff_%s.png" % shape)
		leak.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		leak.material = leak_material
		leak.emitting = false
		leak.one_shot = true
		leak.explosiveness = 0.6
		leak.local_coords = false
		leak.lifetime = LEAK_LIFETIME
		leak.spread = LEAK_SPREAD_DEG
		leak.gravity = Vector2.ZERO
		leak.initial_velocity_min = LEAK_SPEED_MIN
		leak.initial_velocity_max = LEAK_SPEED_MAX
		leak.damping_min = LEAK_DAMPING
		leak.damping_max = LEAK_DAMPING
		leak.anim_speed_min = 1.0
		leak.anim_speed_max = 1.0
		leak.color_ramp = ramp
		add_child(leak)
		_leak_emitters.append(leak)
	_leak_timer = Timer.new()
	_leak_timer.name = "LeakTimer"
	_leak_timer.one_shot = true
	_leak_timer.timeout.connect(_on_leak_timer)
	add_child(_leak_timer)
	_leak_angle = randf() * TAU


func _on_own_hit_points_changed(_current: int, _maximum: int) -> void:
	_update_leak()


# La fuga se ve mientras queda 1 punto de golpe de varios (con un solo punto máximo el traje está
# entero) y el jugador está vivo.
func _update_leak() -> void:
	if _leak_timer == null:
		return
	var leaking: bool = _is_alive and _hp == 1 and _max_hp > 1
	if leaking and _leak_timer.is_stopped():
		_leak_timer.start(randf_range(LEAK_INTERVAL_MIN, LEAK_INTERVAL_MAX))
	elif not leaking:
		_leak_timer.stop()


func _on_leak_timer() -> void:
	_burst_leak()
	_update_leak()


# Una ráfaga desde un punto nuevo del borde del traje, a más de LEAK_MIN_TURN_DEG de la anterior.
func _burst_leak() -> void:
	var angle: float = _leak_angle
	for attempt: int in 8:
		angle = randf() * TAU
		if absf(angle_difference(angle, _leak_angle)) > deg_to_rad(LEAK_MIN_TURN_DEG):
			break
	_leak_angle = angle
	var leak: CPUParticles2D = _leak_emitters[randi() % _leak_emitters.size()]
	leak.position = BODY_CENTER + Vector2(LEAK_RADIUS.x * cos(angle), LEAK_RADIUS.y * sin(angle))
	leak.direction = Vector2.from_angle(angle)
	leak.amount = randi_range(LEAK_AMOUNT_MIN, LEAK_AMOUNT_MAX)
	leak.restart()
	leak.emitting = true
