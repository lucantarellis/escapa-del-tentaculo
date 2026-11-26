class_name FireChaser
extends Node2D
## Dibujo del perseguidor de fuego del espacio: un muro de explosiones siempre en erupción con una
## banda de humo violeta detrás y, debajo, un relleno de explosiones sobre rojo plano. Es hijo del
## [Tentacle] y **todo se mide desde su borde superior** (el origen del nodo; y positiva = hacia
## abajo), no desde la pantalla: funciona con el fuego lejos (borde debajo de la pantalla) y cuando
## alcanza al astronauta (el borde puede pasar el borde de arriba de la pantalla).
##
## Capas, de atrás hacia adelante: humo violeta (`fire_smoke`); en la capa del fuego, rojo plano,
## los cuadros de humo de las explosiones del frente, el relleno (`*_fill`, las nuevas detrás) y
## los cuadros calientes del frente (las nuevas encima). Todo se dibuja con `_draw` desde listas
## de bocanadas que se reciclan (pool); los sprites se espejan al azar y nunca se giran.
## Solo visual: la zona letal es la del [Tentacle]. Parámetros en [FireChaserConfig]. Ver
## `docs/arte/peligros-espacio.md`.

## Rojo plano del fuego. Solo visual.
const RED: Color = Color("CD1417")
## Hojas de las explosiones y del humo (ver [HazardSheet]). Estructural.
const EXPLOSION_SHEET: String = "fire_explosion"
const SMOKE_SHEET: String = "fire_smoke"
## Pivote de cada hoja dentro del cuadro (centro del estallido, base de la bocanada). Estructural.
## Unidad: px.
const EXPLOSION_PIVOT: Vector2 = Vector2(42.0, 40.0)
const SMOKE_PIVOT: Vector2 = Vector2(40.0, 36.0)
## Tags del frente y del relleno, en el orden de los pesos de [FireChaserConfig]. Estructural.
const FRONT_TAGS: Array[StringName] = [&"a", &"b", &"c", &"d"]
const FILL_TAGS: Array[StringName] = [&"a_fill", &"b_fill", &"c_fill"]
const SMOKE_TAGS: Array[StringName] = [&"a", &"b", &"c"]
## Cuadros calientes de cada variante del frente: desde ese cuadro (contando desde 0 dentro del
## tag) la explosión ya es humo y se dibuja detrás del relleno. Estructural.
const FRONT_HOT_FRAMES: Dictionary = {&"a": 6, &"b": 6, &"c": 5, &"d": 9}
## Un salto del borde mayor que esto en un cuadro es un reacomodo (cambio de tier, reinicio) y no
## hunde el relleno. Unidad: px.
const TELEPORT_DISTANCE: float = 160.0
## Lo que más sube el dibujo por encima del borde (explosiones altas y humo). Solo visual.
## Unidad: px.
const TOP_OVERHANG: float = 90.0


## Una explosión o un humo vivo. Se reciclan desde el pool.
class Puff:
	## Primer cuadro y largo del tag en la hoja.
	var first: int = 0
	var length: int = 1
	## Cuadro (dentro del tag) desde el que es humo (solo frente).
	var hot: int = 0
	## Posición del pivote respecto del borde. Unidad: px.
	var x: float = 0.0
	var y: float = 0.0
	## Velocidad vertical respecto del borde (frente: se hunde; humo: sube, negativa). Relleno:
	## factor de la velocidad del perseguidor. Unidad: px/s (o factor).
	var speed: float = 0.0
	var mirrored: bool = false
	## Tiempo de vida. Unidad: s.
	var age: float = 0.0
	## Cuadro actual (dentro del tag).
	var frame: int = 0


var _config: FireChaserConfig
var _width: float = 360.0
var _explosions: HazardSheet
var _smoke_sheet: HazardSheet
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _front: Array[Puff] = []
var _fill: Array[Puff] = []
var _smoke: Array[Puff] = []
var _pool: Array[Puff] = []
var _front_lanes: Array[int] = []
var _smoke_lanes: Array[int] = []
var _tick_left: float = 0.0
## Y (mundo) del borde en el cuadro anterior, velocidad medida del borde (px/s, positiva = sube)
## y distancia del borde al fondo de la pantalla (negativa = el borde está debajo).
var _last_edge_y: float = 0.0
var _has_last_edge: bool = false
var _edge_speed: float = 0.0
var _bottom_distance: float = 0.0
var _paused: bool = true
## Capas de dibujo (hijos): humo violeta detrás, fuego delante.
var _smoke_layer: Node2D
var _fire_layer: Node2D


func _ready() -> void:
	_rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_smoke_layer = Node2D.new()
	_smoke_layer.name = "Smoke"
	_smoke_layer.draw.connect(_draw_smoke)
	add_child(_smoke_layer)
	_fire_layer = Node2D.new()
	_fire_layer.name = "Fire"
	# El fuego da luz: no lo oscurece el ambiente ni lo aclaran las luces.
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_fire_layer.material = unshaded
	_fire_layer.draw.connect(_draw_fire)
	add_child(_fire_layer)


## Prepara el fuego con [param config] para una pantalla de [param width] px de ancho. Vacía lo
## que hubiera: el muro se vuelve a llenar al aparecer.
func setup(config: FireChaserConfig, width: float) -> void:
	_config = config
	_width = width
	_explosions = HazardSheet.get_sheet(EXPLOSION_SHEET)
	_smoke_sheet = HazardSheet.get_sheet(SMOKE_SHEET)
	reset_animation()


## Vacía todas las bocanadas y vuelve a llenar el muro la próxima vez que se vea (lo usa el
## [Tentacle] al reaparecer o reubicarse).
func reset_animation() -> void:
	for list: Array[Puff] in [_front, _fill, _smoke]:
		_pool.append_array(list)
		list.clear()
	_front_lanes.clear()
	_smoke_lanes.clear()
	_tick_left = 0.0
	_has_last_edge = false
	_paused = true
	_redraw()


## Cuánto sube el dibujo por encima del borde. Unidad: px.
func get_top_overhang() -> float:
	return TOP_OVERHANG


## Cantidad de explosiones (frente + relleno) y de humos vivos, para medir el rendimiento.
func get_live_counts() -> Vector2i:
	return Vector2i(_front.size() + _fill.size(), _smoke.size())


## Avanza la animación [param delta] s. [param bottom_distance]: distancia del borde al fondo de la
## pantalla (positiva = el borde está a la vista o por encima; negativa = debajo). La llama el
## [Tentacle] en cada cuadro.
func step(delta: float, bottom_distance: float) -> void:
	if _config == null:
		return
	_bottom_distance = bottom_distance
	var edge_y: float = global_position.y
	var rise: float = 0.0
	if _has_last_edge:
		rise = _last_edge_y - edge_y
		if absf(rise) > TELEPORT_DISTANCE:
			rise = 0.0
	_last_edge_y = edge_y
	_has_last_edge = true
	if delta > 0.0:
		_edge_speed = lerpf(_edge_speed, rise / delta, clampf(delta * 4.0, 0.0, 1.0))
	# Lejos debajo de la pantalla no se ve nada: se pausa y al volver se precarga.
	if bottom_distance < -_config.pause_margin:
		if not _paused:
			reset_animation()
		_paused = true
		return
	if _paused:
		_paused = false
		_prewarm()
	_advance(delta, rise)
	_redraw()


# Simula `prewarm_time` s a la velocidad actual del perseguidor, para que el muro aparezca lleno.
func _prewarm() -> void:
	var dt: float = maxf(_config.spawn_interval, 0.01)
	var steps: int = ceili(_config.prewarm_time / dt)
	var speed: float = maxf(_edge_speed, 0.0)
	for i: int in steps:
		_advance(dt, speed * dt)


# Mueve, envejece, libera y hace nacer bocanadas. [param rise]: cuánto subió el borde (px).
func _advance(delta: float, rise: float) -> void:
	var i: int = _front.size() - 1
	while i >= 0:
		var puff: Puff = _front[i]
		puff.age += delta
		puff.y += puff.speed * delta
		puff.frame = _frame_at(_explosions, puff)
		if puff.frame < 0:
			_release(_front, i)
		i -= 1
	i = _fill.size() - 1
	while i >= 0:
		var puff: Puff = _fill[i]
		puff.age += delta
		# Quedan fijas en el mundo: respecto del borde bajan lo que el borde sube.
		puff.y += rise * puff.speed
		puff.frame = _frame_at(_explosions, puff)
		if puff.frame < 0:
			puff.frame = puff.length - 1 # Se sostiene el último cuadro.
		if puff.y > _config.fill_release_depth:
			_release(_fill, i)
		i -= 1
	i = _smoke.size() - 1
	while i >= 0:
		var puff: Puff = _smoke[i]
		puff.age += delta
		puff.y += puff.speed * delta
		puff.frame = _frame_at(_smoke_sheet, puff)
		if puff.frame < 0:
			_release(_smoke, i)
		i -= 1
	_tick_left -= delta
	while _tick_left <= 0.0:
		_tick_left += maxf(_config.spawn_interval, 0.01)
		_spawn_tick()


func _spawn_tick() -> void:
	var count: int = _config.front_per_tick + (1 if _rng.randf() < _config.front_extra_chance else 0)
	for k: int in count:
		_spawn_front()
	for k: int in _config.fill_per_tick:
		_spawn_fill()
	if _rng.randf() < _config.smoke_chance:
		_spawn_smoke()


func _spawn_front() -> void:
	var tag: StringName = FRONT_TAGS[_pick_weighted(_config.front_weights)]
	var puff: Puff = _take(_front, _config.front_max)
	_init_puff(puff, _explosions, tag)
	puff.hot = FRONT_HOT_FRAMES.get(tag, puff.length)
	var lane_width: float = _width / float(_config.front_lanes)
	puff.x = float(_next_lane(_front_lanes, _config.front_lanes)) * lane_width + _rng.randf_range(-4.0, lane_width)
	if _rng.randf() < _config.front_high_chance:
		puff.y = -_rng.randf_range(_config.front_high_min, _config.front_high_max)
	else:
		puff.y = _rng.randf_range(_config.front_y_min, _config.front_y_max)
	puff.speed = _rng.randf_range(_config.front_sink_min, _config.front_sink_max)
	_front.append(puff)


func _spawn_fill() -> void:
	var tag: StringName = FILL_TAGS[_pick_weighted(_config.fill_weights)]
	var puff: Puff = _take(_fill, _config.fill_max)
	_init_puff(puff, _explosions, tag)
	puff.x = _rng.randf_range(-_config.fill_x_margin, _width + _config.fill_x_margin)
	puff.y = _rng.randf_range(_config.fill_y_min, _config.fill_y_max)
	puff.speed = _rng.randf_range(_config.fill_speed_factor_min, _config.fill_speed_factor_max)
	_fill.append(puff)


func _spawn_smoke() -> void:
	var tag: StringName = SMOKE_TAGS[_rng.randi() % SMOKE_TAGS.size()]
	var puff: Puff = _take(_smoke, _config.smoke_max)
	_init_puff(puff, _smoke_sheet, tag)
	var lane_width: float = _width / float(_config.smoke_lanes)
	puff.x = float(_next_lane(_smoke_lanes, _config.smoke_lanes)) * lane_width + _rng.randf_range(-lane_width * 0.25, lane_width * 0.75)
	puff.y = -_rng.randf_range(_config.smoke_y_min, _config.smoke_y_max)
	puff.speed = -_rng.randf_range(_config.smoke_rise_min, _config.smoke_rise_max)
	_smoke.append(puff)


func _init_puff(puff: Puff, sheet: HazardSheet, tag: StringName) -> void:
	puff.first = sheet.tag_first(tag)
	puff.length = sheet.tag_length(tag)
	puff.hot = puff.length
	puff.mirrored = _rng.randf() < 0.5
	puff.age = 0.0
	puff.frame = 0


# Saca una bocanada del pool (o recicla la más vieja de la lista si llegó al máximo).
func _take(list: Array[Puff], max_count: int) -> Puff:
	if list.size() >= max_count and not list.is_empty():
		var oldest: Puff = list[0]
		list.remove_at(0)
		return oldest
	if _pool.is_empty():
		return Puff.new()
	return _pool.pop_back()


func _release(list: Array[Puff], index: int) -> void:
	_pool.append(list[index])
	list.remove_at(index)


# Cuadro (dentro del tag) según la edad, o -1 si ya terminó.
func _frame_at(sheet: HazardSheet, puff: Puff) -> int:
	var elapsed: float = 0.0
	for k: int in puff.length:
		elapsed += sheet.durations[puff.first + k]
		if puff.age < elapsed:
			return k
	return -1


# Próxima franja de una lista barajada; al vaciarse, se vuelve a barajar.
func _next_lane(lanes: Array[int], count: int) -> int:
	if lanes.is_empty():
		for k: int in count:
			lanes.append(k)
		for k: int in range(count - 1, 0, -1):
			var j: int = _rng.randi() % (k + 1)
			var swap: int = lanes[k]
			lanes[k] = lanes[j]
			lanes[j] = swap
	return lanes.pop_back()


func _pick_weighted(weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += maxf(w, 0.0)
	var roll: float = _rng.randf() * total
	for k: int in weights.size():
		roll -= maxf(weights[k], 0.0)
		if roll < 0.0:
			return k
	return 0


func _redraw() -> void:
	if _smoke_layer != null:
		_smoke_layer.queue_redraw()
		_fire_layer.queue_redraw()


# ---------------------------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------------------------

func _draw_smoke() -> void:
	if _paused:
		return
	for puff: Puff in _smoke:
		_draw_puff(_smoke_layer, _smoke_sheet, puff, SMOKE_PIVOT)


func _draw_fire() -> void:
	if _paused or _config == null:
		return
	# Rojo plano: desde un poco debajo del borde hasta pasado el fondo de la pantalla.
	var red_height: float = maxf(_config.red_min_height, _bottom_distance + 200.0)
	_fire_layer.draw_rect(Rect2(-_config.fill_x_margin, _config.red_offset, _width + _config.fill_x_margin * 2.0, red_height), RED)
	# Humo marrón del frente (cuadros que ya no son calientes), detrás del relleno.
	for puff: Puff in _front:
		if puff.frame >= puff.hot:
			_draw_puff(_fire_layer, _explosions, puff, EXPLOSION_PIVOT)
	# Relleno: las nuevas detrás (se dibujan primero).
	for k: int in range(_fill.size() - 1, -1, -1):
		_draw_puff(_fire_layer, _explosions, _fill[k], EXPLOSION_PIVOT)
	# Frente caliente: las nuevas encima.
	for puff: Puff in _front:
		if puff.frame < puff.hot:
			_draw_puff(_fire_layer, _explosions, puff, EXPLOSION_PIVOT)


# Dibuja una bocanada con su pivote en (x, y), espejada si corresponde, en píxeles enteros.
func _draw_puff(layer: Node2D, sheet: HazardSheet, puff: Puff, pivot: Vector2) -> void:
	var size: Vector2 = sheet.frame_size
	var pivot_x: float = (size.x - 1.0 - pivot.x) if puff.mirrored else pivot.x
	var top_left: Vector2 = Vector2(roundf(puff.x - pivot_x), roundf(puff.y - pivot.y))
	var rect: Rect2 = Rect2(top_left, size)
	if puff.mirrored:
		rect = Rect2(top_left + Vector2(size.x, 0.0), Vector2(-size.x, size.y))
	layer.draw_texture_rect_region(sheet.texture, rect, sheet.region(puff.first + puff.frame))
