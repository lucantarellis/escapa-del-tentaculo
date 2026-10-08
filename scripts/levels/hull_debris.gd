class_name HullDebris
extends Area2D
## Fragmento letal del casco despedido por una explosión ([TierEvent]): vuela en línea recta
## girando y mata al jugador al tocarlo (`Player.die(&"debris")`). Tras `grace_time` s recién
## es letal, para no matar en el mismo instante en que aparece. Se borra al salir de la vista
## (o tras `lifetime` s). Si choca contra algo sólido del mundo (asteroides, paredes, restos
## metálicos) se rompe en pedazos. Lo crea [TierEvent]; no se instancia a mano.

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
	# 2 = jugador (mata), 1 = mundo (se rompe).
	collision_mask = 2 | 1
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
	for body: Node2D in get_overlapping_bodies():
		_on_body_entered(body)
	# Pueden nacer fuera de la vista (bajo la pantalla): se borran recién tras 1,5 s afuera.
	if _age > lifetime or (_age > 1.5 and _is_far_off_screen()):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null:
		# Algo sólido del mundo: se rompe (también durante la gracia).
		_shatter()
		return
	if _age < grace_time:
		return
	if player.is_alive():
		player.die(&"debris")


# Se rompe en pedazos (solo visual) y desaparece.
func _shatter() -> void:
	if is_queued_for_deletion():
		return
	var bits: CPUParticles2D = CPUParticles2D.new()
	bits.one_shot = true
	bits.explosiveness = 1.0
	bits.amount = 10
	bits.lifetime = 0.5
	bits.spread = 180.0
	bits.initial_velocity_min = 60.0
	bits.initial_velocity_max = 160.0
	bits.gravity = Vector2.ZERO
	bits.scale_amount_min = 2.0
	bits.scale_amount_max = 4.0
	bits.color = COLOR
	get_parent().add_child(bits)
	bits.global_position = global_position
	bits.emitting = true
	get_tree().create_timer(0.8).timeout.connect(bits.queue_free)
	queue_free()


func _is_far_off_screen() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return false
	var view: Rect2 = Rect2(camera.global_position - get_viewport_rect().size * 0.5, get_viewport_rect().size).grow(120.0)
	return not view.has_point(global_position)
