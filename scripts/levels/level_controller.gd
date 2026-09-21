class_name LevelController
extends Node2D
## Script raíz de los niveles jugables: `Level.tscn` (armado por segmentos) y `sandbox.tscn`.
##
## Si el nivel tiene un hijo [LevelBuilder], lo usa para armar el nivel, ubicar al jugador,
## fijar el tope de la cámara y encontrar la puerta; si no (sandbox), usa un nodo `GoalDoor`.
## Conecta lo que pasa en el nivel con el [code]GameManager[/code] (autoload) y reacciona a
## su estado: en victoria llama a [method Player.win], detiene el scroll y muestra el mensaje;
## en derrota detiene el scroll y muestra el mensaje según la causa. El reinicio (R) lo
## maneja el propio game manager. Ver `docs/mecanicas/game-manager.md`.
##
## Con [member autostart] en `false` el nivel espera a [method play_intro] (intro de la escotilla: golpes
## de cámara con gas antes de empezar) o a [method begin] (empezar directo). Ver
## `docs/mecanicas/intro-escotilla.md`.

## Texto de derrota por causa de muerte. Solo visual. Las causas no listadas usan
## [constant DEFAULT_DEATH_TEXT].
const DEATH_TEXTS: Dictionary = {
	&"tentacle": "CAPTURADO — pulsá R para reiniciar",
	&"fell": "CAPTURADO — pulsá R para reiniciar",
	&"obstacle": "GOLPEADO — pulsá R para reiniciar",
	&"trap": "GOLPEADO — pulsá R para reiniciar",
}
## Texto para una causa de muerte desconocida. Solo visual.
const DEFAULT_DEATH_TEXT: String = "PERDISTE — pulsá R para reiniciar"
## Texto de victoria. Solo visual.
const WIN_TEXT: String = "ESCAPASTE — pulsá R para reiniciar"

## Si es `true` (por defecto) la partida empieza sola al armarse el nivel. Si es `false` el nivel se
## arma pero queda en pausa hasta que alguien llame a [method begin] (lo usa [Main] para mostrar
## el título con el nivel de fondo). Debe asignarse antes de agregar el nodo al árbol.
@export var autostart: bool = true
## Parámetros de la intro de la escotilla (ver [method play_intro]). Se comparte con el [Hatch].
@export var intro_config: IntroConfig

@onready var _camera: ScrollCamera = $ScrollCamera
@onready var _player: Player = $Player
@onready var _tentacle: Tentacle = $Tentacle
@onready var _builder: LevelBuilder = get_node_or_null("LevelBuilder") as LevelBuilder
@onready var _message_label: Label = $CaughtLayer/CaughtLabel
@onready var _debug_overlay: Node = get_node_or_null("DebugOverlay")
@onready var _hud: Hud = get_node_or_null("Hud") as Hud
@onready var _hatch: Hatch = get_node_or_null("Hatch") as Hatch

var _run_seed: int = 0
var _started: bool = false
var _intro_started: bool = false
var _intro_director: IntroDirector


func _ready() -> void:
	_message_label.visible = false
	var run_seed: int = 0
	var door: Door = get_node_or_null("GoalDoor") as Door
	if _builder != null:
		run_seed = _builder.build()
		_player.reset(_builder.get_player_spawn())
		_camera.set_stop_y(_builder.get_camera_stop_y())
		if _hatch != null:
			_hatch.global_position = _builder.get_hatch_position()
		door = _builder.get_goal_door()
	if door == null:
		push_error("LevelController: el nivel no tiene puerta de meta.")
	else:
		door.player_reached.connect(GameManager.notify_goal_reached)
	_player.died.connect(GameManager.notify_player_died)
	if _hud != null and door != null:
		# El progreso va de la Y del jugador en el spawn a la Y de la puerta.
		_hud.set_progress_range(_player.global_position.y, door.global_position.y)
	GameManager.state_changed.connect(_on_state_changed)
	_run_seed = run_seed
	if _hatch != null:
		_hatch.config = intro_config
	if autostart:
		# Sin intro: la escotilla ya está rota y todo activo desde el primer frame.
		if _hatch != null:
			_hatch.set_broken(true)
		begin()
	else:
		# Antes de la intro: escotilla cerrada, sin tentáculo y con el jugador "detrás" de ella.
		_tentacle.set_active(false)
		_player.set_frozen(true)
		if _hatch != null:
			_hatch.set_broken(false)
		# Nivel quieto: sin `_process`, física, timers ni tweens. El overlay F3 sigue activo.
		process_mode = Node.PROCESS_MODE_DISABLED
		if _debug_overlay != null:
			_debug_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		# El HUD no se muestra en el título: aparece en `begin()`.
		if _hud != null:
			_hud.visible = false


## Empieza la partida ya, sin intro: reanuda el nivel si estaba en pausa (ver [member autostart]),
## deja al tentáculo activo y al jugador libre, y avisa al game manager. Llamarlo más de una vez no
## hace nada.
func begin() -> void:
	_begin(true)


# Empieza la partida. [param activate_tentacle] `false` deja al tentáculo inactivo: lo usa la intro,
# donde el director lo hace entrar más tarde.
func _begin(activate_tentacle: bool) -> void:
	if _started:
		return
	_started = true
	if activate_tentacle:
		_tentacle.set_active(true)
	_player.set_frozen(false)
	process_mode = Node.PROCESS_MODE_INHERIT
	if _debug_overlay != null:
		_debug_overlay.process_mode = Node.PROCESS_MODE_INHERIT
	if _hud != null:
		_hud.visible = true
	GameManager.start_run(_run_seed)


## Reproduce la intro de la escotilla: el nivel sigue en pausa y solo se mueven la escotilla, el gas
## y la vibración de cámara. Tras los golpes la escotilla se rompe, el jugador sale disparado y en
## ese instante empieza la partida; el tentáculo entra un rato después. Sin escotilla o sin
## [member intro_config] empieza directo. Ignorado si la partida o la intro ya empezaron. El
## `GameManager` sigue en `READY` hasta [method begin], así que R no hace nada mientras dura.
func play_intro() -> void:
	if _started or _intro_started:
		return
	if _hatch == null or intro_config == null:
		begin()
		return
	_intro_started = true
	_intro_director = IntroDirector.new()
	_intro_director.config = intro_config
	add_child(_intro_director)
	_intro_director.broken.connect(_on_intro_broken)
	_intro_director.play(_hatch, _camera, _player, _tentacle)


# La ruptura empieza la partida. El tentáculo sigue inactivo: lo hace entrar el director.
func _on_intro_broken() -> void:
	_begin(false)



func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.state_changed.is_connected(_on_state_changed):
		GameManager.state_changed.disconnect(_on_state_changed)


func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.WON:
			_player.win()
			_camera.set_scrolling(false)
			_tentacle.set_rising(false)
			_show_message(WIN_TEXT)
		GameManager.State.LOST:
			_camera.set_scrolling(false)
			_tentacle.set_rising(false)
			_show_message(DEATH_TEXTS.get(GameManager.get_last_death_cause(), DEFAULT_DEATH_TEXT))


func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = true
