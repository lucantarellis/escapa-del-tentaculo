class_name TentacleFront
extends Node2D
## Frente de sprites del [Tentacle]: varias filas de tentáculos en profundidad que se doblan
## como si fueran flexibles y cada tanto cambian de sprite, para dar la sensación de una masa
## viva de miles de tentáculos.
##
## Es solo visual: no tiene colisión ni toca la zona letal. La fila 0 es la de adelante (grande y
## nítida, sus puntas asoman `tip_overhang` px sobre la zona letal); las de atrás son cada vez más
## chicas, oscuras y altas, y se mueven más lento. Cada tentáculo es un [Polygon2D] subdividido
## (el sprite con la punta arriba y el mismo en espejo debajo) que el shader
## `shaders/tentacle_bend.gdshader` dobla de costado. En las filas de atrás se meten, entre los
## tentáculos enteros, piezas chicas (puntas, variantes, enrollados, segmentos) para tapar huecos.
## Ver `docs/mecanicas/tentaculo.md`.

## Shader que dobla los tentáculos. Solo visual.
const BEND_SHADER: Shader = preload("res://shaders/tentacle_bend.gdshader")
## Cantidad de capas de tentáculos superpuestas hacia abajo en la fila de adelante. Estructural.
const FRONT_LAYERS: int = 3
## Ídem para las filas de atrás (se ven menos). Estructural.
const BACK_LAYERS: int = 2
## Dónde empieza cada capa respecto de la anterior, como fracción del alto del sprite. Estructural.
const LAYER_STEP: float = 1.55
## Cuánto se corre de costado la segunda capa para que las puntas no queden alineadas.
## Solo visual. Unidad: px.
const LAYER_SHIFT: float = 9.0
## Separación entre tentáculos de la fila de adelante. Solo visual. Unidad: px.
const FRONT_SPACING: float = 54.0
## Cuánto se achica cada fila de atrás (fracción del tamaño de la anterior). Solo visual.
const ROW_SHRINK: float = 0.15
## Cuánto más alta queda la punta de cada fila de atrás. Solo visual. Unidad: px.
const ROW_RISE: float = 6.0
## Cuánto más abajo puede quedar la punta de un tentáculo al azar (variación). Solo visual. Unidad: px.
const TIP_JITTER: float = 8.0
## Cuánto cambia la velocidad del doblez por cada fila hacia el fondo. Solo visual.
const ROW_SPEED_DROP: float = 0.18
## Subdivisiones de cada mitad de un tentáculo (más = el doblez es más curvo). Estructural.
const TALL_DIVISIONS: int = 8
## Subdivisiones de una pieza chica de relleno. Estructural.
const FILLER_DIVISIONS: int = 5
## Oscurecimiento extra de las piezas de relleno. Solo visual.
const FILLER_DARKEN: float = 0.85
## Cuánto sube y baja cada tentáculo al respirar. Solo visual. Unidad: px.
const BOB_AMPLITUDE: float = 2.5
## Velocidad de esa respiración. Solo visual. Unidad: Hz.
const BOB_FREQUENCY: float = 0.35

## Sprites de tentáculos enteros (vertical y completos): cada tentáculo sortea uno.
@export var textures: Array[Texture2D] = []
## Piezas chicas de relleno para las filas de atrás (puntas, variantes, enrollados, segmentos).
@export var filler_textures: Array[Texture2D] = []


## Un tentáculo (o una pieza de relleno): un Node2D con una o más capas de [Polygon2D].
class Unit:
	extends RefCounted
	var node: Node2D
	var polys: Array[Polygon2D] = []
	var tall: bool = true
	var texture_index: int = 0
	var base_x: float = 0.0
	## Y de la punta (arriba) respecto del origen del frente. Unidad: px.
	var tip_y: float = 0.0
	var scale: float = 1.0
	var phase: float = 0.0
	var flip: float = 1.0
	var swapped: bool = false
	## Pieza de relleno que se mueve junto con este tentáculo (puede ser null).
	var filler: Unit


## Una fila en profundidad.
class Row:
	extends RefCounted
	var node: Node2D
	var units: Array[Unit] = []
	var scale: float = 1.0
	var clock: float = 0.0
	var swap_time: float = 0.0
	var swapping: bool = false

var _config: TentacleConfig
var _rows: Array[Row] = []
var _mesh_cache: Dictionary = {}
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Arma las filas para una pantalla de [param width] px con los parámetros de [param config].
## Se puede llamar de nuevo (por ejemplo al cambiar de config) y reconstruye todo.
func setup(config: TentacleConfig, width: float) -> void:
	_config = config
	_clear()
	if textures.is_empty():
		push_warning("TentacleFront: no hay sprites asignados.")
		return
	_rng.randomize()
	position.y = -(config.tip_overhang - config.kill_zone_inset)
	var rows: int = clampi(config.row_count, 1, 6)
	# Se agregan de atrás hacia adelante: lo que se agrega después queda dibujado encima.
	for row_index: int in range(rows - 1, -1, -1):
		_rows.append(_build_row(row_index, rows, width))
	for row: Row in _rows:
		row.clock = _rng.randf() * config.swap_interval


## Vuelve al estado inicial de la animación (sin cambio en curso, relojes en cero).
func reset_animation() -> void:
	for row: Row in _rows:
		row.swapping = false
		row.clock = 0.0
		for unit: Unit in row.units:
			unit.node.position.y = 0.0


func _process(delta: float) -> void:
	if _config == null or _rows.is_empty():
		return
	_time += delta
	for row: Row in _rows:
		_update_row(row, delta)


func _update_row(row: Row, delta: float) -> void:
	if not row.swapping:
		row.clock += delta
		if row.clock >= _config.swap_interval:
			_start_row_swap(row)
	else:
		row.swap_time += delta
	var duration: float = maxf(_config.swap_duration, 0.01)
	for i: int in row.units.size():
		var unit: Unit = row.units[i]
		var dip: float = 0.0
		if row.swapping:
			var phase: float = clampf((row.swap_time - float(i) * _config.swap_stagger) / duration, 0.0, 1.0)
			dip = sin(phase * PI) * _config.swap_dip * row.scale
			if phase >= 0.5 and not unit.swapped:
				unit.swapped = true
				_change_unit(row, i)
		_place(unit, dip)
		if unit.filler != null:
			_place(unit.filler, dip)
	if row.swapping:
		var total: float = duration + float(row.units.size() - 1) * _config.swap_stagger
		if row.swap_time >= total:
			row.swapping = false
			row.clock = 0.0


# Coloca el nodo de [param unit]: balanceo de costado, respiración y la agachada del cambio.
func _place(unit: Unit, dip: float) -> void:
	var sway: float = sin(_time * TAU * _config.sway_frequency + unit.phase) * _config.sway_amplitude
	var bob: float = sin(_time * TAU * BOB_FREQUENCY + unit.phase * 1.3) * BOB_AMPLITUDE
	unit.node.position = Vector2(unit.base_x + sway, dip + bob)


func _start_row_swap(row: Row) -> void:
	for unit: Unit in row.units:
		unit.swapped = false
	row.swap_time = 0.0
	row.swapping = true


# Cambia el sprite del tentáculo [param index] de la fila (y de su pieza de relleno).
func _change_unit(row: Row, index: int) -> void:
	var unit: Unit = row.units[index]
	var left: int = row.units[index - 1].texture_index if index > 0 else -1
	unit.texture_index = _pick_index(textures.size(), unit.texture_index, left)
	_apply_unit(unit, textures)
	if unit.filler != null and not filler_textures.is_empty():
		unit.filler.texture_index = _pick_index(filler_textures.size(), unit.filler.texture_index, -1)
		_apply_unit(unit.filler, filler_textures)


# Sortea un índice distinto de [param avoid_a] y [param avoid_b] (si hay de dónde elegir).
func _pick_index(count: int, avoid_a: int, avoid_b: int) -> int:
	if count <= 1:
		return 0
	var index: int = _rng.randi_range(0, count - 1)
	var tries: int = 0
	while (index == avoid_a or index == avoid_b) and tries < 12:
		index = _rng.randi_range(0, count - 1)
		tries += 1
	return index


func _build_row(row_index: int, rows: int, width: float) -> Row:
	var row: Row = Row.new()
	row.node = Node2D.new()
	add_child(row.node)
	row.scale = maxf(1.0 - ROW_SHRINK * float(row_index), 0.3)
	var depth: float = float(row_index) / float(maxi(rows - 1, 1))
	var bright: float = 1.0 - _config.back_darken * depth
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BEND_SHADER
	material.set_shader_parameter(&"amplitude", _config.bend_amplitude * row.scale)
	material.set_shader_parameter(&"speed", maxf(_config.bend_speed * (1.0 - ROW_SPEED_DROP * float(row_index)), 0.05))
	var spacing: float = FRONT_SPACING * row.scale
	var count: int = ceili((width + spacing) / spacing) + 1
	var use_fillers: bool = row_index > 0 and not filler_textures.is_empty()
	var layers: int = FRONT_LAYERS if row_index == 0 else BACK_LAYERS
	var fillers: Array[Unit] = []
	var talls: Array[Unit] = []
	for i: int in count:
		var unit: Unit = Unit.new()
		unit.tall = true
		unit.scale = row.scale * _rng.randf_range(0.9, 1.1)
		unit.base_x = (float(i) - 0.5) * spacing + _rng.randf_range(-0.2, 0.2) * spacing
		unit.tip_y = -ROW_RISE * float(row_index) + _rng.randf_range(0.0, TIP_JITTER)
		unit.phase = _rng.randf() * TAU
		unit.flip = 1.0 if _rng.randf() < 0.5 else -1.0
		unit.node = Node2D.new()
		for layer: int in layers:
			var poly: Polygon2D = _make_polygon(material, Color(bright, bright, bright))
			unit.polys.append(poly)
			unit.node.add_child(poly)
		unit.texture_index = _pick_index(textures.size(), -1, talls[i - 1].texture_index if i > 0 else -1)
		talls.append(unit)
		if use_fillers:
			var filler: Unit = Unit.new()
			filler.tall = false
			filler.scale = row.scale * _rng.randf_range(0.8, 1.1)
			filler.base_x = unit.base_x + spacing * 0.5
			filler.tip_y = unit.tip_y + 14.0 + _rng.randf_range(0.0, 18.0)
			filler.phase = _rng.randf() * TAU
			filler.flip = 1.0 if _rng.randf() < 0.5 else -1.0
			filler.node = Node2D.new()
			var fpoly: Polygon2D = _make_polygon(material, Color(bright * FILLER_DARKEN, bright * FILLER_DARKEN, bright * FILLER_DARKEN))
			filler.polys.append(fpoly)
			filler.node.add_child(fpoly)
			filler.texture_index = _rng.randi_range(0, filler_textures.size() - 1)
			unit.filler = filler
			fillers.append(filler)
	# Primero las piezas de relleno (quedan detrás) y después los tentáculos enteros.
	for filler: Unit in fillers:
		row.node.add_child(filler.node)
		_apply_unit(filler, filler_textures)
	for unit: Unit in talls:
		row.node.add_child(unit.node)
		_apply_unit(unit, textures)
		row.units.append(unit)
	for unit: Unit in row.units:
		_place(unit, 0.0)
		if unit.filler != null:
			_place(unit.filler, 0.0)
	return row


func _make_polygon(material: ShaderMaterial, tint: Color) -> Polygon2D:
	var poly: Polygon2D = Polygon2D.new()
	poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	poly.material = material
	poly.modulate = tint
	return poly


# Le pone a las capas de [param unit] el sprite elegido (con su malla subdividida) y las posiciona.
func _apply_unit(unit: Unit, pool: Array[Texture2D]) -> void:
	var tex: Texture2D = pool[unit.texture_index]
	var mesh: Dictionary = _get_mesh(tex, unit.tall)
	var h: float = float(tex.get_height()) * unit.scale
	for layer: int in unit.polys.size():
		var poly: Polygon2D = unit.polys[layer]
		poly.texture = tex
		poly.polygon = mesh["polygon"]
		poly.uv = mesh["uv"]
		poly.vertex_colors = mesh["colors"]
		poly.polygons = mesh["triangles"]
		poly.scale = Vector2(unit.scale * unit.flip, unit.scale)
		var shift: float = LAYER_SHIFT * float(layer % 2) * unit.flip
		if unit.tall:
			# La base de la capa queda a un alto de sprite bajo su punta.
			poly.position = Vector2(shift, unit.tip_y + (float(layer) * LAYER_STEP + 1.0) * h)
		else:
			poly.position = Vector2(0.0, unit.tip_y)


# Malla de [param tex]: una grilla de 2 columnas. Un tentáculo entero es el sprite con la punta
# arriba y el mismo en espejo debajo (origen en la base); una pieza de relleno es el sprite
# solo (origen arriba). El canal rojo del color de cada vértice dice cuánto "punta" es.
func _get_mesh(tex: Texture2D, tall: bool) -> Dictionary:
	var key: int = tex.get_instance_id()
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var divisions: int = TALL_DIVISIONS * 2 if tall else FILLER_DIVISIONS
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var triangles: Array[PackedInt32Array] = []
	for i: int in divisions + 1:
		var t: float = float(i) / float(divisions)
		var y: float
		var v: float
		var tip: float
		if tall:
			y = -h + 2.0 * h * t
			v = h * (1.0 - absf(2.0 * t - 1.0))
			tip = absf(2.0 * t - 1.0)
		else:
			y = h * t
			v = h * t
			tip = 1.0 - t
		for x_index: int in 2:
			polygon.append(Vector2(-w * 0.5 + w * float(x_index), y))
			uv.append(Vector2(w * float(x_index), v))
			colors.append(Color(tip, 0.0, 0.0, 1.0))
	for i: int in divisions:
		var a: int = i * 2
		triangles.append(PackedInt32Array([a, a + 1, a + 2]))
		triangles.append(PackedInt32Array([a + 1, a + 3, a + 2]))
	var mesh: Dictionary = {"polygon": polygon, "uv": uv, "colors": colors, "triangles": triangles}
	_mesh_cache[key] = mesh
	return mesh


func _clear() -> void:
	for row: Row in _rows:
		row.node.queue_free()
	_rows.clear()
