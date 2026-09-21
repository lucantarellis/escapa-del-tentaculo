class_name LevelBuilder
extends Node2D
## Arma un nivel apilando segmentos ([LevelSegment]) hacia arriba: inicio, N segmentos
## elegidos al azar del pool y final.
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
var _seed: int = 0
var _spawn_local: Vector2 = Vector2.ZERO
var _hatch_local: Vector2 = Vector2.ZERO
var _camera_stop_local_y: float = 0.0
var _door: Door


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

	var start: LevelSegment = _place(config.start_segment, bottom_y)
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

	if config.segment_pool.is_empty():
		push_error("LevelBuilder: `segment_pool` está vacío.")
	else:
		for i: int in config.segment_count:
			var index: int = _pick_index()
			_sequence.append(index)
			var segment: LevelSegment = _place(config.segment_pool[index], bottom_y)
			if segment != null:
				bottom_y -= segment.height

	var end: LevelSegment = _place(config.end_segment, bottom_y)
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


## Devuelve la seed del último nivel armado.
func get_seed() -> int:
	return _seed


## Devuelve los índices del `segment_pool` de los segmentos intermedios, en orden de abajo
## hacia arriba. Sirve para comparar niveles y reportar "este nivel estuvo raro".
func get_sequence() -> PackedInt32Array:
	return _sequence


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


# Elige un índice del pool evitando los últimos `avoid_repeat_window` elegidos. Si no queda
# ninguno, relaja la regla: primero solo evita el último, y si el pool tiene uno solo, lo repite.
func _pick_index() -> int:
	var pool_size: int = config.segment_pool.size()
	var window: int = maxi(config.avoid_repeat_window, 0)
	var candidates: Array[int] = []
	for i: int in pool_size:
		var recent_start: int = maxi(_sequence.size() - window, 0)
		var is_recent: bool = false
		for j: int in range(recent_start, _sequence.size()):
			if _sequence[j] == i:
				is_recent = true
				break
		if not is_recent:
			candidates.append(i)
	if candidates.is_empty():
		for i: int in pool_size:
			if _sequence.is_empty() or _sequence[_sequence.size() - 1] != i:
				candidates.append(i)
	if candidates.is_empty():
		candidates.append(0)
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


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
