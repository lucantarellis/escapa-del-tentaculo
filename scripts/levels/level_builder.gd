class_name LevelBuilder
extends Node2D
## Arma un nivel apilando segmentos ([LevelSegment]) hacia arriba: inicio (sorteado entre
## `LevelConfig.start_segments`), segmentos intermedios elegidos al azar y final (sorteado entre
## `LevelConfig.end_segments`). Recorre `LevelConfig.tiers` en orden (cada uno aporta
## su segmento de entrada, si tiene, y `count_per_run` segmentos).
##
## Usa un [RandomNumberGenerator] propio con la seed (nunca el azar global), así la misma seed
## da siempre el mismo nivel. Los segmentos se agregan como hijos de este nodo, que debe estar
## en el origen (0, 0) del nivel. Ver `docs/mecanicas/niveles-por-segmentos.md`.

## Se emite al terminar de armar el nivel. [param level_seed] es la seed usada.
signal level_built(level_seed: int)

## Y (local) del borde inferior del segmento de inicio: la cámara arranca mostrando 0..640.
## Estructural.
const START_BOTTOM_Y: float = 640.0
## Nombre del marcador de aparición del jugador dentro del segmento de inicio. Estructural.
const SPAWN_MARKER_NAME: String = "PlayerSpawn"
## Nombre del marcador de la escotilla dentro del segmento de inicio. Estructural.
const HATCH_MARKER_NAME: String = "HatchAnchor"
## Seed máxima al sortear una aleatoria. Estructural.
const MAX_RANDOM_SEED: int = 2147483647

## Parámetros de la generación. Si queda vacío se usan los valores por defecto de [LevelConfig]
## (sin escenas, así que no arma nada).
@export var config: LevelConfig

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _segments: Array[LevelSegment] = []
var _sequence: PackedInt32Array = PackedInt32Array()
## Tier (índice en `config.tiers`) de cada segmento intermedio.
var _tier_sequence: PackedInt32Array = PackedInt32Array()
var _seed: int = 0
var _spawn_local: Vector2 = Vector2.ZERO
var _hatch_local: Vector2 = Vector2.ZERO
var _camera_stop_local_y: float = 0.0
var _door: Door
## Índice del inicio y del final elegidos en `start_segments` / `end_segments` (-1 sin armar).
var _start_index: int = -1
## Inicio de cada tier armado: {tier = índice en `config.tiers`, y = Y local del borde inferior
## de su primer segmento (entrada incluida)}. En orden de abajo hacia arriba.
var _tier_starts: Array[Dictionary] = []
var _end_index: int = -1


## Arma el nivel y devuelve la seed usada. Limpia el anterior si lo hay. Con
## [param seed_override] distinto de 0 usa esa seed; si no, usa `config.seed`; si también es 0,
## sortea una nueva.
func build(seed_override: int = 0) -> int:
	clear()
	if config == null:
		config = LevelConfig.new()
	_seed = _resolve_seed(seed_override)
	_rng.seed = _seed
	var bottom_y: float = START_BOTTOM_Y

	_start_index = _pick_from(config.start_segments)
	var start: LevelSegment = null
	if _start_index < 0:
		push_error("LevelBuilder: `start_segments` está vacío.")
	else:
		start = _place(config.start_segments[_start_index], bottom_y)
	if start != null:
		var marker: Marker2D = start.get_node_or_null(SPAWN_MARKER_NAME) as Marker2D
		if marker != null:
			_spawn_local = start.position + marker.position
		else:
			push_error("LevelBuilder: el segmento de inicio no tiene un Marker2D '%s'." % SPAWN_MARKER_NAME)
		var hatch_marker: Marker2D = start.get_node_or_null(HATCH_MARKER_NAME) as Marker2D
		if hatch_marker != null:
			_hatch_local = start.position + hatch_marker.position
		else:
			push_error("LevelBuilder: el segmento de inicio no tiene un Marker2D '%s'." % HATCH_MARKER_NAME)
		bottom_y -= start.height

	if config.tiers.is_empty():
		push_error("LevelBuilder: `tiers` está vacío.")
	for tier_index: int in config.tiers.size():
		var tier: SegmentTier = config.tiers[tier_index]
		if tier == null or tier.segments.is_empty():
			push_warning("LevelBuilder: el tier %d no tiene segmentos: se saltea." % (tier_index + 1))
			continue
		_tier_starts.append({"tier": tier_index, "y": bottom_y})
		var entry_index: int = _pick_from(tier.entry_segments)
		if entry_index >= 0:
			var entry: LevelSegment = _place(tier.entry_segments[entry_index], bottom_y)
			if entry != null:
				# La entrada conserva sus paredes (ej.: el casco de la nave al salir al espacio).
				bottom_y -= entry.height
		for index: int in _draw_tier(tier):
			_sequence.append(index)
			_tier_sequence.append(tier_index)
			var tier_segment: LevelSegment = _place(tier.segments[index], bottom_y)
			if tier_segment != null:
				_apply_tier_tileset(tier_segment, tier)
				bottom_y -= tier_segment.height

	_end_index = _pick_from(config.end_segments)
	var end: LevelSegment = null
	if _end_index < 0:
		push_error("LevelBuilder: `end_segments` está vacío.")
	else:
		end = _place(config.end_segments[_end_index], bottom_y)
	if end != null:
		bottom_y -= end.height
		_door = _find_door(end)
	# La cámara se detiene cuando su borde superior alcanza el techo del segmento final.
	var view_height: float = float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	_camera_stop_local_y = bottom_y + view_height * 0.5
	level_built.emit(_seed)
	return _seed


## Elimina los segmentos del nivel actual.
func clear() -> void:
	for segment: LevelSegment in _segments:
		if is_instance_valid(segment):
			remove_child(segment)
			segment.queue_free()
	_segments.clear()
	_sequence.clear()
	_tier_sequence.clear()
	_start_index = -1
	_end_index = -1
	_tier_starts.clear()
	_door = null
	_spawn_local = Vector2.ZERO
	_hatch_local = Vector2.ZERO
	_camera_stop_local_y = 0.0


## Devuelve la posición global donde debe aparecer el jugador (marcador del segmento de
## inicio).
func get_player_spawn() -> Vector2:
	return to_global(_spawn_local)


## Devuelve la posición global donde va la escotilla (marcador `HatchAnchor` del segmento de
## inicio: centro del borde superior del piso).
func get_hatch_position() -> Vector2:
	return to_global(_hatch_local)


## Devuelve la Y global del centro de la cámara para que el segmento final quede completo a
## la vista. Se pasa a [method ScrollCamera.set_stop_y].
func get_camera_stop_y() -> float:
	return to_global(Vector2(0.0, _camera_stop_local_y)).y


## Devuelve la cantidad de segmentos intermedios armados (sin inicio ni final).
func get_segment_count() -> int:
	return _sequence.size()


## Devuelve dónde empieza cada tier armado, de abajo hacia arriba: una lista de
## {tier = índice en `LevelConfig.tiers`, y = Y global del borde inferior de su primer segmento}.
## Los tiers vacíos (salteados) no aparecen.
func get_tier_starts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _tier_starts:
		result.append({"tier": entry["tier"], "y": to_global(Vector2(0.0, entry["y"])).y})
	return result


## Devuelve el índice en `LevelConfig.start_segments` del inicio elegido (-1 si no hay nivel).
func get_start_index() -> int:
	return _start_index


## Devuelve el índice en `LevelConfig.end_segments` del final elegido (-1 si no hay nivel).
func get_end_index() -> int:
	return _end_index


## Devuelve la seed del último nivel armado.
func get_seed() -> int:
	return _seed


## Devuelve los índices de los segmentos intermedios (dentro de la lista de su tier, ver
## [method get_tier_sequence]), en orden de abajo hacia arriba. Sirve para comparar niveles y reportar
## "este nivel estuvo raro".
func get_sequence() -> PackedInt32Array:
	return _sequence


## Devuelve, para cada segmento intermedio (mismo orden que [method get_sequence]), el índice
## del tier del que salió (0 = tier 1).
func get_tier_sequence() -> PackedInt32Array:
	return _tier_sequence


## Devuelve todos los segmentos armados (inicio, intermedios, final) de abajo hacia arriba.
func get_segments() -> Array[LevelSegment]:
	return _segments


## Devuelve la puerta del segmento final (null si no hay).
func get_goal_door() -> Door:
	return _door


func _resolve_seed(seed_override: int) -> int:
	if seed_override != 0:
		return seed_override
	if config.seed != 0:
		return config.seed
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return random.randi_range(1, MAX_RANDOM_SEED)


# Sortea los índices de `tier.count_per_run` segmentos del tier, sin repetir mientras alcance la
# lista (baraja de Fisher-Yates con el RNG de la seed). Si hay menos candidatos que los pedidos,
# vuelve a barajar y repite, cuidando que el primero de la baraja nueva no sea el último usado.
func _draw_tier(tier: SegmentTier) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	var size: int = tier.segments.size()
	var deck: Array[int] = []
	while result.size() < tier.count_per_run:
		if deck.is_empty():
			for i: int in size:
				deck.append(i)
			for i: int in range(size - 1, 0, -1):
				var j: int = _rng.randi_range(0, i)
				var tmp: int = deck[i]
				deck[i] = deck[j]
				deck[j] = tmp
			if size > 1 and not result.is_empty() and deck[deck.size() - 1] == result[result.size() - 1]:
				var swap_with: int = _rng.randi_range(0, deck.size() - 2)
				var last: int = deck[deck.size() - 1]
				deck[deck.size() - 1] = deck[swap_with]
				deck[swap_with] = last
		result.append(deck.pop_back())
	return result


# Instancia un segmento con su borde inferior en `bottom_y` (local). Devuelve null si falla.
func _place(scene: PackedScene, bottom_y: float) -> LevelSegment:
	if scene == null:
		push_error("LevelBuilder: falta una escena de segmento en la config.")
		return null
	var segment: LevelSegment = scene.instantiate() as LevelSegment
	if segment == null:
		push_error("LevelBuilder: la raíz de '%s' no es un LevelSegment." % scene.resource_path)
		return null
	segment.position = Vector2(0.0, bottom_y)
	add_child(segment)
	_segments.append(segment)
	return segment


func _find_door(node: Node) -> Door:
	for child: Node in node.get_children():
		if child is Door:
			return child as Door
		var found: Door = _find_door(child)
		if found != null:
			return found
	return null


# Sortea un índice de [param scenes] con el RNG de la seed. -1 si la lista está vacía.
func _pick_from(scenes: Array[PackedScene]) -> int:
	if scenes.is_empty():
		return -1
	return _rng.randi_range(0, scenes.size() - 1)


# Si el tier define un tileset de paredes, se lo pone a las capas de paredes del segmento.
func _apply_tier_tileset(segment: LevelSegment, tier: SegmentTier) -> void:
	if tier.walls_tileset == null:
		return
	for child: Node in segment.get_children():
		if child is TileMapLayer:
			(child as TileMapLayer).tile_set = tier.walls_tileset
