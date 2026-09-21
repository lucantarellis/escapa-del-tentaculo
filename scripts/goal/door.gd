@tool
class_name Door
extends Area2D
## Puerta de meta: al tocarla un jugador vivo, gana la partida.
##
## Es un [Area2D] (capa 5 `goal`, máscara 2 `player`): detecta al jugador sin colisionar
## físicamente con él. No llama a [Player]: solo emite [signal player_reached]; la reacción
## (ganar, mostrar el mensaje, detener el scroll) es del nivel o del game manager.
## `@tool`: el tamaño se ve y se ajusta en el editor. El origen del nodo es el CENTRO de la
## puerta. Ver `docs/mecanicas/puerta.md`.

## Un [Player] vivo llegó a la puerta. Se emite una sola vez hasta llamar a [method reset].
signal player_reached

## Ancho del picaporte decorativo. Unidad: px. Solo visual.
const HANDLE_WIDTH: float = 6.0
## Alto del picaporte decorativo. Unidad: px. Solo visual.
const HANDLE_HEIGHT: float = 10.0
## Distancia del picaporte al borde derecho de la puerta. Unidad: px. Solo visual.
const HANDLE_MARGIN: float = 8.0

@export_group("Forma")
## Tamaño de la puerta (ancho, alto). Es diseño de nivel, no tuning. Unidad: px.
@export var size: Vector2 = Vector2(48.0, 72.0):
	set(value):
		size = value.max(Vector2.ONE)
		_update_shape()

@onready var _body: Polygon2D = $Body
@onready var _handle: Polygon2D = $Body/Handle
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _reached: bool = false


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


## Vuelve a dejar la puerta lista para activarse (por ejemplo al reiniciar la partida).
## Si el jugador está encima en ese momento, se activa de nuevo al instante.
func reset() -> void:
	_reached = false
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	for body: Node2D in get_overlapping_bodies():
		_on_body_entered(body)


# Regenera polígono, picaporte y forma de colisión a partir de `size`. Antes de _ready los
# nodos hijos todavía no existen (los setters exportados corren al cargar la escena).
func _update_shape() -> void:
	if not is_node_ready():
		return
	var half: Vector2 = size * 0.5
	_body.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	var handle_right: float = half.x - HANDLE_MARGIN
	_handle.polygon = PackedVector2Array([
		Vector2(handle_right - HANDLE_WIDTH, -HANDLE_HEIGHT * 0.5),
		Vector2(handle_right, -HANDLE_HEIGHT * 0.5),
		Vector2(handle_right, HANDLE_HEIGHT * 0.5),
		Vector2(handle_right - HANDLE_WIDTH, HANDLE_HEIGHT * 0.5),
	])
	# Cada instancia tiene su propia forma (la escena la marca local_to_scene).
	if not _collision.shape is RectangleShape2D:
		_collision.shape = RectangleShape2D.new()
	(_collision.shape as RectangleShape2D).size = size


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if _reached or player == null or not player.is_alive():
		return
	_reached = true
	player_reached.emit()
