extends Node2D
## TEMPORAL: controlador mínimo de la escena de prueba `sandbox.tscn`.
##
## Muestra el mensaje de derrota, detiene el scroll y reinicia con `restart` recargando la
## escena. Lo reemplaza el game manager (paso 6 del roadmap): no agregarle lógica nueva.

@onready var _camera: ScrollCamera = $ScrollCamera
@onready var _tentacle: Tentacle = $Tentacle
@onready var _caught_label: Label = $CaughtLayer/CaughtLabel


func _ready() -> void:
	_caught_label.visible = false
	_tentacle.player_caught.connect(_on_player_caught)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_caught(_cause: StringName) -> void:
	_caught_label.visible = true
	_camera.set_scrolling(false)
