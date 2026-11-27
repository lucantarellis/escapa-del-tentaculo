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
## Hoja de las brasas de la estela (ver [HazardSheet]). Estructural.
const EMBER_SHEET: String = "particle_ember"
## Cuadros de la hoja de brasas (una brasa recorre todos a lo largo de su vida). Estructural.
const EMBER_FRAMES: int = 4
## Hoja de las astillas de la rotura (ver [HazardSheet]). Estructural.
const CHIPS_SHEET: String = "hull_chips"
## Cuadros de la hoja de astillas (1 a 3 acero, 4 a 6 brasa). Estructural.
const CHIP_FRAMES: int = 6

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

@export_group("Arte")
## Brasas de la estela por segundo. Solo visual.
@export var trail_density: float = 40.0
## Vida de cada brasa de la estela (el largo de la estela es su velocidad por esta vida).
## Unidad: s. Solo visual.
@export var trail_life: float = 0.35
## Dispersión de la estela, a cada lado de la dirección opuesta al vuelo. Unidad: °. Solo visual.
@export var trail_spread: float = 25.0
## Velocidad con que se alejan las brasas del fragmento. Unidad: px/s. Solo visual.
@export var trail_drift_min: float = 3.0
## Ver `trail_drift_min`. Unidad: px/s. Solo visual.
@export var trail_drift_max: float = 20.0
## Color del resplandor aditivo del fragmento. Solo visual.
@export var glow_color: Color = Color(1.0, 0.42, 0.2, 0.35)
## Tamaño del resplandor, en múltiplos de `size`. Solo visual.
@export var glow_scale: float = 2.0

@export_group("Rotura")
## Cantidad de astillas al romperse.
@export var chip_amount: int = 10
## Vida de las astillas. Unidad: s.
@export var chip_life: float = 0.5
## Velocidad inicial mínima de las astillas. Unidad: px/s.
@export var chip_speed_min: float = 60.0
## Velocidad inicial máxima de las astillas. Unidad: px/s.
@export var chip_speed_max: float = 160.0

static var _glow_cache: GradientTexture2D = null

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
	add_child(_make_trail())
	add_child(_make_glow())
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


# Se rompe en astillas de acero y brasas (solo visual) y desaparece. Cada astilla muestra un
# cuadro al azar de `hull_chips` (los 3 primeros son acero y los 3 últimos brasas).
func _shatter() -> void:
	if is_queued_for_deletion():
		return
	var sheet: HazardSheet = HazardSheet.get_sheet(CHIPS_SHEET)
	var bits: CPUParticles2D = CPUParticles2D.new()
	bits.texture = sheet.texture
	bits.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bits.one_shot = true
	bits.explosiveness = 1.0
	bits.amount = chip_amount
	bits.lifetime = chip_life
	bits.spread = 180.0
	bits.initial_velocity_min = chip_speed_min
	bits.initial_velocity_max = chip_speed_max
	bits.gravity = Vector2.ZERO
	# Cuadro al azar: la animación no avanza y cada partícula arranca en un punto de la hoja.
	bits.anim_speed_min = 0.0
	bits.anim_speed_max = 0.0
	bits.anim_offset_min = 0.0
	bits.anim_offset_max = 1.0
	# Se desvanecen sobre el final de su vida.
	var fade: Gradient = Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	bits.color_ramp = fade
	bits.material = _anim_material(CHIP_FRAMES)
	get_parent().add_child(bits)
	bits.global_position = global_position
	bits.emitting = true
	get_tree().create_timer(chip_life + 0.3).timeout.connect(bits.queue_free)
	queue_free()


# Estela: brasas en espacio global soltadas detrás del fragmento (la dirección opuesta al vuelo).
# Cada una recorre los 4 cuadros de la hoja a lo largo de su vida.
func _make_trail() -> CPUParticles2D:
	var sheet: HazardSheet = HazardSheet.get_sheet(EMBER_SHEET)
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Trail"
	particles.texture = sheet.texture
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.local_coords = false
	particles.lifetime = trail_life
	particles.amount = maxi(4, roundi(trail_density * trail_life))
	particles.direction = -velocity.normalized() if velocity != Vector2.ZERO else Vector2.DOWN
	particles.spread = trail_spread
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = trail_drift_min
	particles.initial_velocity_max = trail_drift_max
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = size * 0.3
	particles.anim_speed_min = 1.0
	particles.anim_speed_max = 1.0
	particles.material = _anim_material(EMBER_FRAMES)
	return particles


# Resplandor aditivo naranja, chico y sin luz real (hay hasta 24 fragmentos vivos a la vez).
func _make_glow() -> Sprite2D:
	var glow: Sprite2D = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = _glow_texture()
	glow.scale = Vector2.ONE * (size * glow_scale / 64.0)
	glow.modulate = glow_color
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = additive
	return glow


# Material sin sombreado para partículas con hoja de `frames` cuadros en una fila.
func _anim_material(frames: int) -> CanvasItemMaterial:
	var material_anim: CanvasItemMaterial = CanvasItemMaterial.new()
	material_anim.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material_anim.particles_animation = true
	material_anim.particles_anim_h_frames = frames
	material_anim.particles_anim_v_frames = 1
	material_anim.particles_anim_loop = false
	return material_anim


# Textura del resplandor: círculo que se desvanece hacia el borde (compartida).
static func _glow_texture() -> GradientTexture2D:
	if _glow_cache == null:
		var gradient: Gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
		_glow_cache = GradientTexture2D.new()
		_glow_cache.gradient = gradient
		_glow_cache.fill = GradientTexture2D.FILL_RADIAL
		_glow_cache.fill_from = Vector2(0.5, 0.5)
		_glow_cache.fill_to = Vector2(1.0, 0.5)
		_glow_cache.width = 64
		_glow_cache.height = 64
	return _glow_cache


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
