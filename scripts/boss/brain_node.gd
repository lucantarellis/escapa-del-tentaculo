class_name BrainNode
extends Area2D
## Punto débil del cerebro del alien ([BossBrain]): se destruye cuando el [Player] lo embiste con
## el dash. Tocarlo sin dash no hace nada. Late (escala) para llamar la atención.
## Ver `docs/mecanicas/tier-alien.md`.

## Se emite al destruirse.
signal destroyed

## Color del nodo (rosa intenso). Solo visual.
const COLOR: Color = Color("F06C9B")
## Radio del nodo. Unidad: px.
const RADIUS: float = 14.0

var _alive: bool = true
var _time: float = 0.0
var _body: Polygon2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	_body = Polygon2D.new()
	_body.color = COLOR
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		points.append(Vector2.RIGHT.rotated(TAU * i / 16.0) * RADIUS)
	_body.polygon = points
	add_child(_body)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_time += delta
	_body.scale = Vector2.ONE * (1.0 + 0.12 * sin(_time * TAU * 1.5))
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and player.is_alive() and player.is_dashing():
			_destroy()
			return


## Devuelve true mientras no fue destruido.
func is_alive() -> bool:
	return _alive


func _destroy() -> void:
	_alive = false
	set_deferred("monitoring", false)
	var tween: Tween = create_tween()
	tween.tween_property(_body, "scale", Vector2.ONE * 2.2, 0.15)
	tween.parallel().tween_property(_body, "modulate:a", 0.0, 0.25)
	tween.tween_callback(hide)
	destroyed.emit()
