class_name Main
extends Node
## Escena principal del juego: el hub (la nave intacta como menú) y, al subir el ascensor, la
## partida.
##
## Al abrir muestra el [Hub] con la pantalla de inicio ([StartScreen]) encima. Cuando el ascensor termina de subir (pantalla en negro), libera el
## hub, instancia el nivel con [member LevelController.autostart] en `false`, llama a
## [method LevelController.play_intro] (intro de la escotilla: al romperse, el nivel empieza solo) y
## aclara la pantalla. Con R ([signal GameManager.restart_requested]) reconstruye solo el nivel y
## repite la intro. Con Escape (`ui_cancel`), solo después de ganar o perder, vuelve al hub.
## Durante la partida Escape no hace nada: no hay pausa. Ver `docs/mecanicas/hub.md`.

## Escena del nivel jugable. Estructural.
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/Level.tscn")
## Escena del hub. Estructural.
const HUB_SCENE: PackedScene = preload("res://scenes/hub/Hub.tscn")
## Fundido desde negro al arrancar la partida. Solo visual. Unidad: s.
const LEVEL_FADE_IN: float = 0.3

@onready var _level_holder: Node = $LevelHolder
@onready var _hub_holder: Node = $HubHolder
@onready var _fade: ColorRect = $FadeLayer/Fade

var _level: LevelController
var _hub: Hub
## true entre pedir volver al hub (Escape) y que se reconstruya el nivel: ese reinicio muestra
## el hub en vez de repetir la intro.
var _going_to_hub: bool = false


func _ready() -> void:
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_show_hub(true)
	GameManager.restart_requested.connect(_on_restart_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or _level == null:
		return
	# Solo al terminar la partida (ganar o perder): durante la partida no hay pausa ni salida.
	var state: GameManager.State = GameManager.get_state()
	if state != GameManager.State.WON and state != GameManager.State.LOST:
		return
	get_viewport().set_input_as_handled()
	_going_to_hub = true
	GameManager.restart()


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.restart_requested.is_connected(_on_restart_requested):
		GameManager.restart_requested.disconnect(_on_restart_requested)


## Devuelve el hub si se está mostrando (null durante la partida). Sirve para pruebas.
func get_hub() -> Hub:
	return _hub


## Devuelve el nivel en curso (null en el hub). Sirve para pruebas.
func get_level() -> LevelController:
	return _level


## Instancia el nivel en [code]LevelHolder[/code]. [param autostart] indica si la partida
## empieza sola. Se asigna antes de [method Node.add_child], porque el nivel lo lee en `_ready`.
func _spawn_level(autostart: bool) -> LevelController:
	var level: LevelController = LEVEL_SCENE.instantiate() as LevelController
	level.autostart = autostart
	level.show_menu_hint = true
	_level_holder.add_child(level)
	return level


# [param with_start] muestra la pantalla de inicio encima (solo al abrir el juego).
func _show_hub(with_start: bool = false) -> void:
	_hub = HUB_SCENE.instantiate() as Hub
	_hub.show_start_screen = with_start
	_hub_holder.add_child(_hub)
	_hub.launch_finished.connect(_on_hub_launch_finished)


# El hub dejó la pantalla en negro: se cambia por el nivel y arranca la intro de la escotilla.
func _on_hub_launch_finished() -> void:
	_fade.color.a = 1.0
	_hub_holder.remove_child(_hub)
	_hub.queue_free()
	_hub = null
	_level = _spawn_level(false)
	_level.play_intro()
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, LEVEL_FADE_IN)


func _on_restart_requested() -> void:
	if _level == null:
		return
	# Se saca del árbol antes de liberarlo, para que su `_exit_tree` corra ya y no quede
	# escuchando al manager junto al nivel nuevo.
	_level_holder.remove_child(_level)
	_level.queue_free()
	_level = null
	if _going_to_hub:
		# Escape tras ganar o perder: de vuelta al hub, con el mercado.
		_going_to_hub = false
		_show_hub()
		return
	# R repite la intro de la escotilla: el nivel nuevo arranca en pausa y se reproduce.
	_level = _spawn_level(false)
	_level.play_intro()
