@tool
class_name WindowBreach
extends Node2D
## Ventanal del techo de la nave que rompe el alien (salida del tier 1 al espacio). Mientras está
## sano es sólido (vidrio). Cuando el jugador se acerca desde abajo, un tentáculo lo rompe desde
## afuera (sacudida y vidrios) y empieza la **descompresión**: el aire que se escapa arrastra al
## jugador hacia el hueco hasta sacarlo de la nave. El jugador conserva el control.
##
## Se pone en los segmentos de salida del tier 1 (`SegmentTier.exit_segments`), centrado en el hueco
## del techo. Visuales placeholder. Ver `docs/mecanicas/tier-espacio.md`.

## Se emite cuando el tentáculo rompe el vidrio.
signal broken

## Color del vidrio (blanco azulado translúcido). Solo visual.
const GLASS_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.45)
## Color del tentáculo que rompe el vidrio (violeta claro de la paleta del alien). Solo visual.
const TENTACLE_COLOR: Color = Color("B79FF1")

@export_group("Ventanal")
## Tamaño del vidrio (ancho del hueco del techo × espesor). Unidad: px.
@export var glass_size: Vector2 = Vector2(72.0, 36.0):
	set(value):
		glass_size = value
		queue_redraw()
## Distancia vertical bajo el vidrio a la que el jugador dispara la rotura. Unidad: px.
@export var trigger_distance: float = 260.0

@export_group("Rotura")
## Fuerza y duración de la sacudida al romperse. Unidad: px y s.
@export var shake_amplitude: float = 14.0
@export var shake_duration: float = 0.6
## Tiempo que tarda el tentáculo en entrar y salir. Unidad: s.
@export var smash_duration: float = 0.45
## Cantidad de vidrios que salen volando (solo visual).
@export var shard_count: int = 30

@export_group("Descompresión")
## Aceleración con la que el aire arrastra al jugador hacia el hueco. Unidad: px/s².
@export var pull_acceleration: float = 1500.0
## Velocidad máxima que puede darle la descompresión. Unidad: px/s.
@export var pull_max_speed: float = 560.0
## Radio alrededor del hueco en el que se siente la succión. Unidad: px.
@export var pull_radius: float = 480.0
## Duración máxima de la succión (termina antes si el jugador ya salió). Unidad: s.
@export var pull_duration: float = 3.0

var _broken: bool = false
var _pull_left: float = 0.0
var _glass: StaticBody2D
var _glass_body: Polygon2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_glass = StaticBody2D.new()
	_glass.collision_layer = 1
	_glass.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = glass_size
	shape.shape = rect
	_glass.add_child(shape)
	add_child(_glass)
	_glass_body = Polygon2D.new()
	_glass_body.color = GLASS_COLOR
	var h: Vector2 = glass_size * 0.5
	_glass_body.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	add_child(_glass_body)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var h: Vector2 = glass_size * 0.5
	draw_rect(Rect2(-h, glass_size), GLASS_COLOR, true)
	draw_line(Vector2(-h.x, h.y + trigger_distance), Vector2(h.x, h.y + trigger_distance), Color(0.72, 0.62, 0.95, 0.6), 1.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player: Player = _get_player()
	if player == null or not player.is_alive():
		return
	if not _broken:
		var below: float = player.global_position.y - global_position.y
		if below > 0.0 and below <= trigger_distance:
			_break()
		return
	if _pull_left <= 0.0:
		return
	_pull_left -= delta
	var to_hole: Vector2 = global_position - player.global_position
	# Ya salió (está por encima del hueco): termina la succión.
	if to_hole.y > 0.0 or to_hole.length() > pull_radius:
		if to_hole.y > 0.0:
			_pull_left = 0.0
		return
	var pull: Vector2 = player.velocity + to_hole.normalized() * pull_acceleration * delta
	player.velocity = pull.limit_length(maxf(pull_max_speed, player.velocity.length()))


## Rompe el ventanal (si no estaba roto): tentáculo, vidrios, sacudida y descompresión.
func _break() -> void:
	_broken = true
	_pull_left = pull_duration
	_glass.process_mode = Node.PROCESS_MODE_DISABLED
	(_glass.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	_glass_body.visible = false
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null:
		camera.shake(shake_amplitude, shake_duration)
	_play_tentacle()
	_play_shards()
	broken.emit()


# Punta de tentáculo que entra desde arriba por el hueco y se retira.
func _play_tentacle() -> void:
	var tip: Polygon2D = Polygon2D.new()
	tip.color = TENTACLE_COLOR
	tip.polygon = PackedVector2Array([Vector2(-18, -160), Vector2(18, -160), Vector2(10, -20), Vector2(0, 0), Vector2(-10, -20)])
	tip.position = Vector2(0.0, -glass_size.y)
	tip.z_index = 3
	add_child(tip)
	var tween: Tween = create_tween()
	tween.tween_property(tip, "position:y", glass_size.y + 30.0, smash_duration * 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(tip, "position:y", -200.0, smash_duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_callback(tip.queue_free)


func _play_shards() -> void:
	if shard_count <= 0:
		return
	var shards: CPUParticles2D = CPUParticles2D.new()
	shards.one_shot = true
	shards.explosiveness = 1.0
	shards.amount = shard_count
	shards.lifetime = 1.0
	shards.direction = Vector2.DOWN
	shards.spread = 70.0
	shards.initial_velocity_min = 80.0
	shards.initial_velocity_max = 260.0
	shards.gravity = Vector2(0.0, 300.0)
	shards.scale_amount_min = 2.0
	shards.scale_amount_max = 4.0
	shards.color = Color(GLASS_COLOR, 0.9)
	shards.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	shards.emission_rect_extents = glass_size * 0.5
	add_child(shards)
	shards.emitting = true
	get_tree().create_timer(1.5).timeout.connect(shards.queue_free)


func _get_player() -> Player:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if node is Player:
			return node as Player
	return null
