class_name HullDebris
extends Area2D
## Fragmento letal del casco despedido por una explosión ([TierEvent]): vuela en línea recta
## girando y mata al jugador al tocarlo (`Player.die(&"debris")`). Tras `grace_time` s recién
## es letal, para no matar en el mismo instante en que aparece. Se borra al salir de la vista
## (o tras `lifetime` s). Lo crea [TierEvent]; no se instancia a mano.

## Rojo letal de la paleta. Solo visual.
const COLOR: Color = Color("D83232")

## Velocidad (px/s), dirección incluida.
var velocity: Vector2 = Vector2.ZERO
## Velocidad de giro. Unidad: rad/s.
var spin: float = 3.0
## Tiempo inicial sin ser letal. Unidad: s.
var grace_time: float = 0.25
## Vida máxima. Unidad: s.
var lifetime: float = 6.0
## Tamaño aproximado del fragmento. Unidad: px.
var size: float = 12.0

var _age: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var points: PackedVector2Array = PackedVector2Array()
	# Polígono irregular de 5 puntos.
	for i: int in 5:
		var a: float = TAU * float(i) / 5.0 + randf_range(-0.3, 0.3)
		points.append(Vector2(cos(a), sin(a)) * size * randf_range(0.5, 0.75))
	var body: Polygon2D = Polygon2D.new()
	body.color = COLOR
	body.polygon = points
	add_child(body)
	var shape: CollisionPolygon2D = CollisionPolygon2D.new()
	shape.polygon = points
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	position += velocity * delta
	rotation += spin * delta
	if _age >= grace_time:
		for body: Node2D in get_overlapping_bodies():
			_on_body_entered(body)
	if _age > lifetime or _is_far_off_screen():
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _age < grace_time:
		return
	var player: Player = body as Player
	if player != null and player.is_alive():
		player.die(&"debris")


func _is_far_off_screen() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return false
	var view: Rect2 = Rect2(camera.global_position - get_viewport_rect().size * 0.5, get_viewport_rect().size).grow(120.0)
	return not view.has_point(global_position)
