class_name Main
extends Node
## Escena principal del juego: pantalla de título sobre el nivel ya cargado.
##
## Al abrir instancia el nivel (con [member LevelController.autostart] en `false`, o sea armado
## pero quieto) y encima el [TitleMenu]. Cuando el menú termina de disolverse, lo elimina y
## llama a [method LevelController.begin]. Con R ([signal GameManager.restart_requested])
## reconstruye solo el nivel, sin volver al título. Ver `docs/mecanicas/pantalla-titulo.md`.

## Escena del nivel jugable. Estructural.
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/Level.tscn")

@onready var _level_holder: Node = $LevelHolder
@onready var _title_layer: CanvasLayer = $TitleLayer
@onready var _title_menu: TitleMenu = $TitleLayer/TitleMenu

var _level: LevelController


func _ready() -> void:
	_level = _spawn_level(false)
	_title_menu.faded_out.connect(_on_title_faded_out)
	GameManager.restart_requested.connect(_on_restart_requested)


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.restart_requested.is_connected(_on_restart_requested):
		GameManager.restart_requested.disconnect(_on_restart_requested)


## Instancia el nivel en [code]LevelHolder[/code]. [param autostart] indica si la partida
## empieza sola. Se asigna antes de [method Node.add_child], porque el nivel lo lee en `_ready`.
func _spawn_level(autostart: bool) -> LevelController:
	var level: LevelController = LEVEL_SCENE.instantiate() as LevelController
	level.autostart = autostart
	_level_holder.add_child(level)
	return level


func _on_title_faded_out() -> void:
	_title_menu.queue_free()
	_level.begin()


func _on_restart_requested() -> void:
	# Se saca del árbol antes de liberarlo, para que su `_exit_tree` corra ya y no quede
	# escuchando al manager junto al nivel nuevo.
	_level_holder.remove_child(_level)
	_level.queue_free()
	_level = _spawn_level(true)
