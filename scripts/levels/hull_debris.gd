class_name HullDebris
extends Area2D
## Fragmento letal del casco despedido por una explosión ([TierEvent]): vuela en línea recta
## girando y mata al jugador al tocarlo (`Player.die(&"debris")`). Tras `grace_time` s recién
## es letal, para no matar en el mismo instante en que aparece. Se borra al salir de la vista
## (o tras `lifetime` s). Si choca contra algo sólido del mundo (asteroides, paredes, restos
## metálicos) se rompe en pedazos. Lo crea [TierEvent]; no se instancia a mano.
## Cada fragmento es un sprite (`hull_debris`, 4 diseños de 36 cuadros: un giro completo cada 10°)
## que avanza de cuadro con su giro; el sprite no se rota. Solo gira la forma de colisión. Ver
## `docs/arte/peligros-espacio.md`.

## Hoja de los fragmentos (ver [HazardSheet]). Estructural.
const SHEET_NAME: String = "hull_debris"
## Diseños de fragmento de la hoja (tags `frag1` a `frag4`). Estructural.
const DESIGNS: int = 4
## Cuadros de un giro completo de un fragmento (un cuadro cada 10°, en sentido antihorario).
## Estructural.
const SPIN_FRAMES: int = 36
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
## Giro acumulado del fragmento (positivo = horario, como en Godot). Unidad: rad.
var _angle: float = 0.0
var _sheet: HazardSheet = null
## Primer cuadro del diseño elegido en la hoja.
var _first_frame: int = 0
var _sprite: Sprite2D
var _emissive: Sprite2D
var _shape: CollisionPolygon2D


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
	_shape = CollisionPolygon2D.new()
	_shape.polygon = points
	add_child(_shape)
	_sheet = HazardSheet.get_sheet(SHEET_NAME)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_first_frame = _sheet.tag_first(StringName("frag%d" % (1 + randi() % DESIGNS)))
	_angle = randf() * TAU
	_sprite = Sprite2D.new()
	_sprite.texture = _sheet.texture
	_sprite.region_enabled = true
	add_child(_sprite)
	if _sheet.emissive != null:
		# Lo incandescente va aparte y sin sombreado, con el mismo cuadro.
		_emissive = Sprite2D.new()
		_emissive.texture = _sheet.emissive
		_emissive.region_enabled = true
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_emissive.material = unshaded
		add_child(_emissive)
	_update_frame()
	_shape.rotation = _angle
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	position += velocity * delta
	_angle += spin * delta
	# Solo gira la colisión; el dibujo cambia de cuadro.
	_shape.rotation = _angle
	_update_frame()
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


# Muestra el cuadro (0 a 35) del giro acumulado. Los cuadros avanzan en sentido antihorario y el
# ángulo de Godot crece en sentido horario, por eso se invierte.
func _update_frame() -> void:
	var frame: int = posmod(-roundi(rad_to_deg(_angle) / (360.0 / float(SPIN_FRAMES))), SPIN_FRAMES)
	var region: Rect2 = _sheet.region(_first_frame + frame)
	_sprite.region_rect = region
	if _emissive != null:
		_emissive.region_rect = region


func _is_far_off_screen() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return false
	var view: Rect2 = Rect2(camera.global_position - get_viewport_rect().size * 0.5, get_viewport_rect().size).grow(120.0)
	return not view.has_point(global_position)
