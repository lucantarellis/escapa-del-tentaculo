class_name Main
extends Node
## Escena principal del juego: pantalla de título sobre el nivel ya cargado.
##
## Al abrir instancia el nivel (con [member LevelController.autostart] en `false`, o sea armado
## pero quieto) y encima el [TitleMenu]. Cuando el menú termina de disolverse, lo elimina y
## llama a [method LevelController.play_intro] (intro de la escotilla: al romperse, el nivel empieza
## solo). Con R ([signal GameManager.restart_requested]) reconstruye solo el nivel, sin volver al
## título, y repite la intro. Con Escape (`ui_cancel`), solo después de ganar o perder, vuelve
## al título (con el mercado) sobre un nivel nuevo. Durante la partida Escape no hace nada: no hay
## pausa. Ver `docs/mecanicas/pantalla-titulo.md`.

## Escena del nivel jugable. Estructural.
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/Level.tscn")
## Escena del menú de título. Estructural.
const TITLE_SCENE: PackedScene = preload("res://scenes/ui/TitleMenu.tscn")

@onready var _level_holder: Node = $LevelHolder
@onready var _title_layer: CanvasLayer = $TitleLayer
@onready var _title_menu: TitleMenu = $TitleLayer/TitleMenu

var _level: LevelController
## true entre pedir volver al título (Escape) y que se reconstruya el nivel: ese reinicio muestra
## el título en vez de repetir la intro.
var _going_to_title: bool = false


func _ready() -> void:
	_level = _spawn_level(false)
	_title_menu.faded_out.connect(_on_title_faded_out)
	GameManager.restart_requested.connect(_on_restart_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Solo al terminar la partida (ganar o perder): durante la partida no hay pausa ni salida.
	var state: GameManager.State = GameManager.get_state()
	if state != GameManager.State.WON and state != GameManager.State.LOST:
		return
	get_viewport().set_input_as_handled()
	_going_to_title = true
	GameManager.restart()


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.restart_requested.is_connected(_on_restart_requested):
		GameManager.restart_requested.disconnect(_on_restart_requested)


## Instancia el nivel en [code]LevelHolder[/code]. [param autostart] indica si la partida
## empieza sola. Se asigna antes de [method Node.add_child], porque el nivel lo lee en `_ready`.
func _spawn_level(autostart: bool) -> LevelController:
	var level: LevelController = LEVEL_SCENE.instantiate() as LevelController
	level.autostart = autostart
	level.show_menu_hint = true
	_level_holder.add_child(level)
	return level


func _on_title_faded_out() -> void:
	_title_menu.queue_free()
	_level.play_intro()


func _on_restart_requested() -> void:
	# Se saca del árbol antes de liberarlo, para que su `_exit_tree` corra ya y no quede
	# escuchando al manager junto al nivel nuevo.
	_level_holder.remove_child(_level)
	_level.queue_free()
	_level = _spawn_level(false)
	if _going_to_title:
		# Escape tras ganar o perder: nivel nuevo quieto y el título encima, con el mercado.
		_going_to_title = false
		_show_title()
		return
	# R repite la intro de la escotilla (sin título): el nivel nuevo arranca en pausa y se reproduce.
	_level.play_intro()


# Instancia un título nuevo sobre el nivel (que ya está armado y quieto).
func _show_title() -> void:
	_title_menu = TITLE_SCENE.instantiate() as TitleMenu
	_title_layer.add_child(_title_menu)
	_title_menu.faded_out.connect(_on_title_faded_out)
