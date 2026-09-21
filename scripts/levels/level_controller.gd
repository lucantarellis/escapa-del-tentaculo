class_name LevelController
extends Node2D
## Script raíz de los niveles jugables (incluido `sandbox.tscn`).
##
## Conecta lo que pasa en el nivel con el [code]GameManager[/code] (autoload) y reacciona a
## su estado: en victoria llama a [method Player.win], detiene el scroll y muestra el mensaje;
## en derrota detiene el scroll y muestra el mensaje según la causa. El reinicio (R) lo
## maneja el propio game manager. Ver `docs/mecanicas/game-manager.md`.

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

@onready var _camera: ScrollCamera = $ScrollCamera
@onready var _player: Player = $Player
@onready var _door: Door = $GoalDoor
@onready var _message_label: Label = $CaughtLayer/CaughtLabel


func _ready() -> void:
	_message_label.visible = false
	_player.died.connect(GameManager.notify_player_died)
	_door.player_reached.connect(GameManager.notify_goal_reached)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.start_run()


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.state_changed.is_connected(_on_state_changed):
		GameManager.state_changed.disconnect(_on_state_changed)


func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.WON:
			_player.win()
			_camera.set_scrolling(false)
			_show_message(WIN_TEXT)
		GameManager.State.LOST:
			_camera.set_scrolling(false)
			_show_message(DEATH_TEXTS.get(GameManager.get_last_death_cause(), DEFAULT_DEATH_TEXT))


func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = true
