@tool
class_name Obstacle
extends Area2D
## Obstáculo estático: un bloque rectangular letal. Tocarlo mata al jugador.
##
## Es un [Area2D] (capa 3 `obstacles`, máscara 2 `player`): detecta al jugador sin colisionar
## físicamente con él. Base de [MovingObstacle] y [PulseTrap].
## `@tool`: el tamaño se ve y se ajusta en el editor. El origen del nodo es el CENTRO del
## bloque. Ver `docs/mecanicas/obstaculos.md`.

## Un [Player] vivo tocó el obstáculo. Se emite justo antes de llamar a [method Player.die].
signal player_hit(cause: StringName)

@export_group("Forma")
## Tamaño del bloque (ancho, alto). Es diseño de nivel, no tuning. Unidad: px.
@export var size: Vector2 = Vector2(48.0, 48.0):
	set(value):
		size = value.max(Vector2.ONE)
		_update_shape()
		queue_redraw()

@export_group("Letalidad")
## Causa que se pasa a [method Player.die] (la lee el controlador de partida).
@export var cause: StringName = &"obstacle"

@onready var _body: Polygon2D = $Body
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


## Activa o desactiva la detección del jugador. Se aplica de forma diferida (seguro dentro
## de callbacks de física). Un obstáculo desactivado no mata.
func set_active(active: bool) -> void:
	set_deferred("monitoring", active)


# Regenera polígono y forma de colisión a partir de `size`. Antes de _ready los nodos hijos
# todavía no existen (los setters de las propiedades exportadas corren al cargar la escena).
func _update_shape() -> void:
	if not is_node_ready():
		return
	var half: Vector2 = size * 0.5
	_body.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	# Cada instancia tiene su propia forma (la escena la marca local_to_scene); esta guarda
	# es por si alguien la reemplaza por otro tipo de forma.
	if not _collision.shape is RectangleShape2D:
		_collision.shape = RectangleShape2D.new()
	(_collision.shape as RectangleShape2D).size = size


func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)


# Mata al jugador si `body` es un Player vivo. Idempotente: ignora a un jugador ya muerto.
func _try_hit(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive():
		return
	player_hit.emit(cause)
	player.die(cause)
