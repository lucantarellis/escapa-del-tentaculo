class_name IntroDirector
extends Node
## Director de la intro: orquesta la secuencia de golpes, ruptura y lanzamiento llamando hacia abajo a [Hatch],
## [ScrollCamera], [Player] y [Tentacle], y avisa hacia arriba con señales.
##
## Lo crea [LevelController] en [method LevelController.play_intro]. Como el nivel está en pausa
## mientras dura la intro, el director corre siempre (`PROCESS_MODE_ALWAYS`) y espera con
## `SceneTree.create_timer`, que no depende de la pausa del nivel. Tras cada espera comprueba
## `is_inside_tree()`: el nivel puede liberarse en el medio. Ver `docs/mecanicas/intro-escotilla.md`.

## Se emite en cada golpe. [param index] cuenta desde 0.
signal hit(index: int)
## Se emite en el instante de la ruptura, con el jugador ya lanzado. [LevelController] responde
## empezando la partida (`GameManager.start_run`, HUD, scroll).
signal broken
## Se emite al terminar la secuencia (cuando el tentáculo empieza a entrar, o al saltearse esa
## entrada porque la partida ya terminó).
signal finished

## Parámetros de la secuencia. Lo asigna [LevelController].
var config: IntroConfig

var _hatch: Hatch
var _camera: ScrollCamera
var _player: Player
var _tentacle: Tentacle
var _playing: bool = false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Reproduce la secuencia. Devuelve enseguida (la secuencia corre con `await`). Ignorado si ya
## está reproduciéndose.
func play(hatch: Hatch, camera: ScrollCamera, player: Player, tentacle: Tentacle) -> void:
	if _playing:
		return
	_playing = true
	_hatch = hatch
	_camera = camera
	_player = player
	_tentacle = tentacle
	if config == null:
		config = IntroConfig.new()
	_run()


## Devuelve true mientras la secuencia está en curso.
func is_playing() -> bool:
	return _playing


func _run() -> void:
	if not await _wait(config.first_hit_delay):
		return
	for i: int in config.hit_count:
		var strength: float = pow(config.hit_escalation, i)
		_camera.shake(config.shake_amplitude * strength, config.shake_duration)
		_hatch.hit(strength)
		hit.emit(i)
		# Entre golpes espera `hit_interval`; tras el último, `pre_break_pause`.
		var pause: float = config.hit_interval if i < config.hit_count - 1 else config.pre_break_pause
		if not await _wait(pause):
			return
	_break_and_launch()
	# El tentáculo tarda en aparecer. Si la partida terminó antes (ganó o perdió), no entra.
	if not await _wait(config.tentacle_entry_delay):
		return
	if GameManager.get_state() == GameManager.State.PLAYING:
		_tentacle.enter(config.tentacle_entry_duration)
	_playing = false
	finished.emit()


# Ruptura: la escotilla se rompe, la cámara vibra más fuerte y el jugador sale disparado hacia
# arriba desde la escotilla. Desde este momento la partida está en curso (señal [signal broken]).
func _break_and_launch() -> void:
	_hatch.break_open()
	_camera.shake(config.break_shake_amplitude, config.break_shake_duration)
	# Desde ya vigila la caída: no hace falta que el tentáculo haya entrado para que caer bajo la
	# pantalla mate.
	_tentacle.set_fall_watch(true)
	_player.global_position = _hatch.get_launch_position()
	_player.launch(Vector2(0.0, -config.launch_speed), config.control_lock_time)
	broken.emit()


# Espera [param seconds]. Devuelve false si el director salió del árbol mientras tanto.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(maxf(seconds, 0.0)).timeout
	return is_inside_tree()
