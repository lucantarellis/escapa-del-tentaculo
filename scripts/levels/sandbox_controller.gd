extends Node2D
## TEMPORAL: controlador mínimo de la escena de prueba `sandbox.tscn`.
##
## Escucha [signal Player.died] y [signal Door.player_reached]: muestra el mensaje de derrota
## (según la causa) o de victoria, detiene el scroll y reinicia con `restart` recargando la escena. Lo reemplaza el game manager
## (paso 6 del roadmap): no agregarle lógica nueva.

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
@onready var _caught_label: Label = $CaughtLayer/CaughtLabel


func _ready() -> void:
	_caught_label.visible = false
	_player.died.connect(_on_player_died)
	_door.player_reached.connect(_on_player_reached_goal)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_died(cause: StringName) -> void:
	_caught_label.text = DEATH_TEXTS.get(cause, DEFAULT_DEATH_TEXT)
	_caught_label.visible = true
	_camera.set_scrolling(false)


func _on_player_reached_goal() -> void:
	_player.win()
	_caught_label.text = WIN_TEXT
	_caught_label.visible = true
	_camera.set_scrolling(false)
