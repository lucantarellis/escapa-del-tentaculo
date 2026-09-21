class_name DebugOverlay
extends CanvasLayer
## Overlay de depuración que muestra el estado del [Player]. Se alterna con `debug_toggle` (F3).

## Jugador a observar. Se asigna desde el inspector o desde la escena que lo instancia.
@export var player: Player

@onready var _label: Label = $Label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	if player == null:
		_label.text = "DebugOverlay: falta asignar 'player'"
		return
	var v: Vector2 = player.velocity
	var lines: PackedStringArray = [
		"vel: (%.0f, %.0f)  |v| %.0f px/s" % [v.x, v.y, v.length()],
		"combustible: %.1f / %.1f" % [player.get_fuel(), player.config.max_fuel],
		"gravedad: %.0f px/s²" % player.get_current_gravity(),
		"on_floor: %s" % player.is_on_floor(),
		"propulsando: %s" % player.is_thrusting(),
		"puede saltar: %s" % player.can_jump(),
		"seed: %d" % GameManager.get_current_seed(),
		"FPS: %d" % Engine.get_frames_per_second(),
	]
	_label.text = "\n".join(lines)
