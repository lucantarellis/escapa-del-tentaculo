class_name TentacleSea
extends Node2D
## Mar de tentáculos del perseguidor de la nave: una fila de relleno atrás, una fila de tentáculos
## de adelante que se curvan hacia lados alternados y la masa de carne que tapa las bases.
##
## Es solo visual: no tiene colisión ni toca la zona letal del [Tentacle]. El origen es el del
## [Tentacle] (borde superior, esquina izquierda de la pantalla). Las puntas de la fila de adelante
## asoman `TentacleSeaConfig.tip_overhang` px sobre el borde de la zona letal que se le pasa a
## [method setup]; la carne (`tentacle_flesh`) arranca más abajo
## y `tentacle_flesh_deep` se repite hacia abajo hasta cubrir la profundidad del cuerpo (ver
## [method set_depth]). Los tentáculos de adelante encadenan `idle_a`/`idle_b` al azar y cada tanto
## (o si el jugador se acerca) hacen `reach` → `grab` → `retract`. Parámetros en
## [TentacleSeaConfig]. Ver `docs/mecanicas/tentaculo.md`.

## SpriteFrames de los tentáculos de adelante (Aseprite Wizard). Solo visual.
const FRONT_FRAMES: Array[SpriteFrames] = [
	preload("res://assets/sprites/tentacle/ship/tentacle_front_01.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_front_02.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_front_03.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_front_04.res"),
]
## Hacia dónde se curva cada tentáculo de adelante en el dibujo (1 derecha, -1 izquierda). Solo visual.
const FRONT_FACING: Array[int] = [1, -1, 1, -1]
## SpriteFrames de los tentáculos de relleno. Solo visual.
const FILL_FRAMES: Array[SpriteFrames] = [
	preload("res://assets/sprites/tentacle/ship/tentacle_fill_01.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_fill_02.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_fill_03.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_fill_04.res"),
	preload("res://assets/sprites/tentacle/ship/tentacle_fill_05.res"),
]
## Masa de carne (respira) y su continuación hacia abajo (se repite). Solo visual.
const FLESH_FRAMES: SpriteFrames = preload("res://assets/sprites/tentacle/ship/tentacle_flesh.res")
const DEEP_FRAMES: SpriteFrames = preload("res://assets/sprites/tentacle/ship/tentacle_flesh_deep.res")
## Altura de la punta de un tentáculo de adelante (en su pose de reposo más alta) sobre el borde
## inferior del cuadro. Medida en el arte (cuadros de 300×384). Solo visual. Unidad: px.
const FRONT_TIP_HEIGHT: float = 324.0
## Animaciones de los tentáculos de adelante. Solo visual.
const ANIM_IDLE_A: StringName = &"idle_a"
const ANIM_IDLE_B: StringName = &"idle_b"
const ANIM_REACH: StringName = &"reach"
const ANIM_GRAB: StringName = &"grab"
const ANIM_RETRACT: StringName = &"retract"
## Cuánto más arriba que la línea de las puntas puede llegar un tentáculo de adelante: las poses de
## `reach` (~13 px) más la variación de la base. Solo visual. Unidad: px.
const TOP_MARGIN: float = 20.0
## Margen por debajo del borde de la zona letal en el que el jugador todavía cuenta como "cerca"
## para el agarre. Solo visual. Unidad: px.
const GRAB_BELOW_MARGIN: float = 16.0


## Un tentáculo de adelante y su estado de agarre.
class FrontUnit:
	extends RefCounted
	var sprite: AnimatedSprite2D
	## true = en cuanto termine un ciclo de `idle_a` hace `reach`.
	var wants_reach: bool = false
	## true mientras hace `reach`, `grab` o `retract`.
	var reaching: bool = false
	## Tiempo hasta que intente agarrar por su cuenta. Unidad: s.
	var reach_timer: float = 0.0


var _config: TentacleSeaConfig
var _width: float = 0.0
## Y del borde de la zona letal, de la línea de las puntas y del borde superior de la carne,
## respecto del origen. Unidad: px.
var _kill_y: float = 0.0
var _tip_y: float = 0.0
var _baseline: float = 0.0
var _fill_layer: Node2D
var _front_layer: Node2D
var _flesh: AnimatedSprite2D
var _deep_layer: Node2D
## Y (respecto del origen) hasta donde llega la carne ya armada. Unidad: px.
var _covered_to: float = 0.0
var _front: Array[FrontUnit] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _player: Node2D


## Arma el mar para una pantalla de [param width] px, con el borde de la zona letal en la Y
## [param kill_y] (respecto del origen). Si ya estaba armado con la misma config, ancho y borde, no
## hace nada.
func setup(config: TentacleSeaConfig, kill_y: float, width: float) -> void:
	if config == _config and is_equal_approx(width, _width) and is_equal_approx(kill_y, _kill_y) and not _front.is_empty():
		return
	_clear()
	_config = config
	_width = width
	_kill_y = kill_y
	_tip_y = kill_y - config.tip_overhang
	_rng.randomize()
	_set_front_one_shot()
	_baseline = _tip_y + FRONT_TIP_HEIGHT - _config.front_base_depth
	# Orden de dibujo (atrás → adelante): relleno, adelante, carne, carne profunda.
	_fill_layer = _add_layer(&"Fill")
	_front_layer = _add_layer(&"Front")
	_build_fill()
	_build_front()
	_build_flesh()
	_deep_layer = _add_layer(&"Deep")
	_covered_to = _baseline + _frame_size(FLESH_FRAMES, &"idle").y


## Agrega copias de `tentacle_flesh_deep` hacia abajo hasta cubrir [param depth] px desde el origen.
## La llama el [Tentacle] cada cuadro con la profundidad de su cuerpo.
func set_depth(depth: float) -> void:
	if _deep_layer == null:
		return
	var deep_tex: Texture2D = DEEP_FRAMES.get_frame_texture(&"default", 0)
	var step: float = float(deep_tex.get_height())
	while _covered_to < depth:
		var deep: Sprite2D = Sprite2D.new()
		deep.texture = deep_tex
		deep.centered = false
		deep.position = Vector2(_flesh_x(), _covered_to)
		_deep_layer.add_child(deep)
		_covered_to += step


## Cuánto sobresale el mar por encima del origen (lo más alto que puede llegar una punta). Unidad: px.
func get_top_overhang() -> float:
	return -_tip_y + TOP_MARGIN


## Vuelve los tentáculos de adelante a reposo (sin agarres en curso), con cuadros al azar.
func reset_animation() -> void:
	for unit: FrontUnit in _front:
		unit.reaching = false
		unit.wants_reach = false
		unit.reach_timer = _next_reach_time()
		_play_random_idle(unit.sprite, true)


func _process(delta: float) -> void:
	if _config == null or _front.is_empty():
		return
	for unit: FrontUnit in _front:
		if unit.reaching or unit.wants_reach:
			continue
		unit.reach_timer -= delta
		if unit.reach_timer <= 0.0:
			unit.wants_reach = true
	_check_player_near()


# Si el jugador está apenas por encima del borde letal (entre las puntas), el tentáculo de adelante
# que le queda debajo intenta agarrarlo en cuanto termine su ciclo de `idle_a`.
func _check_player_near() -> void:
	if _config.grab_distance <= 0.0:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		if _player == null:
			return
	var local: Vector2 = to_local(_player.global_position)
	var above: float = _kill_y - local.y
	if above < -GRAB_BELOW_MARGIN or above > _config.grab_distance:
		return
	var nearest: FrontUnit = null
	var best: float = INF
	for unit: FrontUnit in _front:
		var dist: float = absf(unit.sprite.position.x - local.x)
		if dist < best:
			best = dist
			nearest = unit
	if nearest != null and not nearest.reaching:
		nearest.wants_reach = true


# Encadena las animaciones de un tentáculo de adelante: reposo al azar, y `reach` → `grab` →
# `retract` → reposo cuando le toca agarrar. `reach` arranca de la pose con que empieza `idle_a`, así
# que solo se dispara al terminar un ciclo de `idle_a`.
func _on_front_finished(unit: FrontUnit) -> void:
	match unit.sprite.animation:
		ANIM_REACH:
			unit.sprite.play(ANIM_GRAB)
		ANIM_GRAB:
			unit.sprite.play(ANIM_RETRACT)
		ANIM_RETRACT:
			# `retract` termina en la pose del primer cuadro de `idle_a`.
			unit.reaching = false
			unit.reach_timer = _next_reach_time()
			unit.sprite.play(ANIM_IDLE_A)
		ANIM_IDLE_A:
			if unit.wants_reach and _count_reaching() < _config.max_reaching:
				unit.wants_reach = false
				unit.reaching = true
				unit.sprite.play(ANIM_REACH)
			else:
				_play_random_idle(unit.sprite, false)
		_:
			# Para agarrar hay que pasar primero por `idle_a`.
			if unit.wants_reach:
				unit.sprite.play(ANIM_IDLE_A)
			else:
				_play_random_idle(unit.sprite, false)


func _build_fill() -> void:
	var size: Vector2 = _frame_size(FILL_FRAMES[0], &"idle")
	var brightness: float = _config.fill_brightness
	var start: float = _row_start(_config.fill_count, _config.fill_spacing)
	var previous: int = -1
	for i: int in _config.fill_count:
		var variant: int = _pick_variant(FILL_FRAMES.size(), previous)
		previous = variant
		var sprite: AnimatedSprite2D = _make_sprite(FILL_FRAMES[variant], size)
		sprite.position = Vector2(start + float(i) * _config.fill_spacing, _baseline + _config.fill_base_depth + _jitter())
		sprite.flip_h = _rng.randf() < 0.5
		sprite.modulate = Color(brightness, brightness, brightness, 1.0)
		_fill_layer.add_child(sprite)
		sprite.play(&"idle")
		_randomize_frame(sprite)


func _build_front() -> void:
	var size: Vector2 = _frame_size(FRONT_FRAMES[0], ANIM_IDLE_A)
	var start: float = _row_start(_config.front_count, _config.front_spacing)
	# Se alternan las direcciones: uno curvado a la derecha, el siguiente a la izquierda.
	var direction: int = 1 if _rng.randf() < 0.5 else -1
	var previous: int = -1
	for i: int in _config.front_count:
		var variant: int = _pick_variant(FRONT_FRAMES.size(), previous)
		previous = variant
		var unit: FrontUnit = FrontUnit.new()
		unit.sprite = _make_sprite(FRONT_FRAMES[variant], size)
		unit.sprite.position = Vector2(start + float(i) * _config.front_spacing, _baseline + _config.front_base_depth + _jitter())
		unit.sprite.flip_h = FRONT_FACING[variant] != direction
		unit.reach_timer = _next_reach_time()
		_front_layer.add_child(unit.sprite)
		unit.sprite.animation_finished.connect(_on_front_finished.bind(unit))
		_play_random_idle(unit.sprite, true)
		_front.append(unit)
		direction = -direction


func _build_flesh() -> void:
	_flesh = AnimatedSprite2D.new()
	_flesh.name = &"Flesh"
	_flesh.sprite_frames = FLESH_FRAMES
	_flesh.centered = false
	_flesh.position = Vector2(_flesh_x(), _baseline)
	add_child(_flesh)
	_flesh.play(&"idle")
	_randomize_frame(_flesh)


# Un sprite con el origen en el centro del borde inferior del cuadro (la base del tentáculo) y una
# velocidad propia dentro del rango de la config.
func _make_sprite(frames: SpriteFrames, size: Vector2) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	sprite.speed_scale = _rng.randf_range(_config.speed_scale_min, _config.speed_scale_max)
	return sprite


func _play_random_idle(sprite: AnimatedSprite2D, random_frame: bool) -> void:
	sprite.play(ANIM_IDLE_A if _rng.randf() < 0.5 else ANIM_IDLE_B)
	if random_frame:
		_randomize_frame(sprite)


func _randomize_frame(sprite: AnimatedSprite2D) -> void:
	var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.set_frame_and_progress(_rng.randi_range(0, count - 1), _rng.randf())


# Los tentáculos de adelante encadenan animaciones al terminar cada una, así que ninguna puede
# repetirse sola. El Wizard las importa en loop: se corrige al armar (afecta al recurso compartido,
# que solo se usa así).
func _set_front_one_shot() -> void:
	for frames: SpriteFrames in FRONT_FRAMES:
		for anim: StringName in [ANIM_IDLE_A, ANIM_IDLE_B, ANIM_REACH, ANIM_GRAB, ANIM_RETRACT]:
			if frames.has_animation(anim):
				frames.set_animation_loop(anim, false)


func _count_reaching() -> int:
	var count: int = 0
	for unit: FrontUnit in _front:
		if unit.reaching:
			count += 1
	return count


func _next_reach_time() -> float:
	return _rng.randf_range(_config.reach_interval_min, maxf(_config.reach_interval_max, _config.reach_interval_min))


# Variante al azar distinta de la anterior, para que dos vecinos no se muevan igual.
func _pick_variant(count: int, previous: int) -> int:
	var variant: int = _rng.randi_range(0, count - 1)
	if count > 1 and variant == previous:
		variant = (variant + 1 + _rng.randi_range(0, count - 2)) % count
	return variant


func _jitter() -> float:
	return _rng.randf_range(-_config.base_jitter, _config.base_jitter)


# X del primero de una fila de [param count] elementos separados [param spacing], centrada en la pantalla.
func _row_start(count: int, spacing: float) -> float:
	return (_width - float(maxi(count - 1, 0)) * spacing) * 0.5


# X de la carne: centrada en la pantalla (el dibujo ya mide el ancho de la pantalla).
func _flesh_x() -> float:
	return (_width - _frame_size(FLESH_FRAMES, &"idle").x) * 0.5


func _frame_size(frames: SpriteFrames, anim: StringName) -> Vector2:
	return frames.get_frame_texture(anim, 0).get_size()


func _add_layer(layer_name: StringName) -> Node2D:
	var layer: Node2D = Node2D.new()
	layer.name = layer_name
	add_child(layer)
	return layer


func _clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_front.clear()
	_flesh = null
	_deep_layer = null
	_fill_layer = null
	_front_layer = null
