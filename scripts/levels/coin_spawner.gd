class_name CoinSpawner
extends RefCounted
## Reparte monedas ([Coin]) dentro de un segmento, en lugares libres.
##
## No toca los `.tscn` de los segmentos: mira lo que ya tiene el segmento (plataformas con su
## recorrido, puertas, tanques, paredes pintadas y cualquier otro nodo con posición) y busca
## puntos al azar que queden a `coin_obstacle_margin` de todo eso y de los bordes. El azar sale de
## un [RandomNumberGenerator] que se le pasa (el del nivel), así la misma seed da las mismas
## monedas. Ver `docs/mecanicas/progreso-mercado.md`.

## Mitad del lado de la caja que se reserva alrededor de un nodo del que solo se conoce la
## posición (tanques, peligros, etc.). Estructural. Unidad: px.
const UNKNOWN_BOX_HALF: float = 24.0
## Cantidad de puntos alrededor de una moneda candidata que se revisan contra las paredes.
## Estructural.
const WALL_SAMPLES: int = 8

var _coin_scene: PackedScene


func _init(coin_scene: PackedScene) -> void:
	_coin_scene = coin_scene


## Reparte monedas en [param segment] con el azar de [param rng] y los parámetros de
## [param cfg]. Devuelve cuántas puso (puede ser menos que las pedidas si no hay lugar libre).
func populate(segment: LevelSegment, rng: RandomNumberGenerator, cfg: ProgressConfig) -> int:
	var blocked: Array[Rect2] = _get_blocked_rects(segment)
	var layers: Array[TileMapLayer] = []
	for child: Node in segment.get_children():
		if child is TileMapLayer:
			layers.append(child as TileMapLayer)
	var wanted: int = rng.randi_range(cfg.coins_per_segment_min, maxi(cfg.coins_per_segment_min, cfg.coins_per_segment_max))
	var placed: Array[Vector2] = []
	for i: int in wanted:
		for attempt: int in cfg.coin_placement_tries:
			var pos: Vector2 = Vector2(
				rng.randf_range(cfg.coin_edge_margin, LevelSegment.WIDTH - cfg.coin_edge_margin),
				rng.randf_range(-LevelSegment.HEIGHT + cfg.coin_edge_margin, -cfg.coin_edge_margin))
			if is_free(pos, blocked, layers, placed, cfg):
				placed.append(pos)
				break
	for pos: Vector2 in placed:
		var coin: Coin = _coin_scene.instantiate() as Coin
		coin.position = pos
		coin.collected.connect(PlayerProgress.add_run_coins)
		segment.add_child(coin)
	return placed.size()


## Busca al azar un punto libre de [param segment] (coordenadas del segmento) con el mismo criterio
## que las monedas, lejos también de [param taken]. Devuelve [code]Vector2.INF[/code] si no
## encontró lugar tras `coin_placement_tries` intentos.
func find_free_position(segment: LevelSegment, rng: RandomNumberGenerator, cfg: ProgressConfig, taken: Array[Vector2] = []) -> Vector2:
	var blocked: Array[Rect2] = _get_blocked_rects(segment)
	var layers: Array[TileMapLayer] = []
	for child: Node in segment.get_children():
		if child is TileMapLayer:
			layers.append(child as TileMapLayer)
	for attempt: int in cfg.coin_placement_tries:
		var pos: Vector2 = Vector2(
			rng.randf_range(cfg.coin_edge_margin, LevelSegment.WIDTH - cfg.coin_edge_margin),
			rng.randf_range(-LevelSegment.HEIGHT + cfg.coin_edge_margin, -cfg.coin_edge_margin))
		if is_free(pos, blocked, layers, taken, cfg):
			return pos
	return Vector2.INF


## Devuelve true si [param pos] (coordenadas del segmento) está libre: lejos de los rectángulos
## de [param blocked], de las paredes de [param layers] y de las monedas ya puestas
## ([param placed]), según [param cfg].
func is_free(pos: Vector2, blocked: Array[Rect2], layers: Array[TileMapLayer], placed: Array[Vector2], cfg: ProgressConfig) -> bool:
	for rect: Rect2 in blocked:
		if rect.grow(cfg.coin_obstacle_margin).has_point(pos):
			return false
	for other: Vector2 in placed:
		if other.distance_to(pos) < cfg.coin_min_separation:
			return false
	for layer: TileMapLayer in layers:
		if _touches_wall(layer, pos, cfg.coin_obstacle_margin):
			return false
	return true


# true si el centro o algún punto del contorno (radio `margin`) cae en una celda pintada.
func _touches_wall(layer: TileMapLayer, pos: Vector2, margin: float) -> bool:
	if _has_cell(layer, pos):
		return true
	for i: int in WALL_SAMPLES:
		var point: Vector2 = pos + Vector2.from_angle(TAU * float(i) / float(WALL_SAMPLES)) * margin
		if _has_cell(layer, point):
			return true
	return false


func _has_cell(layer: TileMapLayer, segment_point: Vector2) -> bool:
	return layer.get_cell_source_id(layer.local_to_map(segment_point - layer.position)) != -1


## Devuelve los rectángulos (coordenadas del segmento) que ocupan los hijos directos del
## segmento, sin contar las paredes pintadas (esas se revisan por celda).
func _get_blocked_rects(segment: LevelSegment) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child: Node in segment.get_children():
		if child is Platform:
			var platform: Platform = child as Platform
			var rect: Rect2 = Rect2(platform.position - platform.size * 0.5, platform.size)
			# Las que se mueven y los proyectiles recorren `travel`: se reserva todo el recorrido.
			if platform.moves or platform.platform_type == Platform.PlatformType.PROJECTILE:
				rect = rect.merge(Rect2(rect.position + platform.travel, platform.size))
			result.append(rect)
		elif child is Door:
			var door: Door = child as Door
			result.append(Rect2(door.position - door.size * 0.5, door.size))
		elif child is StaticBody2D:
			var body_rect: Rect2 = _get_polygon_rect(child as StaticBody2D)
			if body_rect.size != Vector2.ZERO:
				result.append(body_rect)
			else:
				result.append(_box_around((child as Node2D).position))
		elif child is Node2D and not (child is TileMapLayer) and not (child is Marker2D):
			result.append(_box_around((child as Node2D).position))
	return result


func _box_around(point: Vector2) -> Rect2:
	return Rect2(point - Vector2.ONE * UNKNOWN_BOX_HALF, Vector2.ONE * UNKNOWN_BOX_HALF * 2.0)


# Rectángulo (en coordenadas del segmento) que cubren los polígonos de colisión de un cuerpo
# estático. Tamaño cero si no tiene ninguno.
func _get_polygon_rect(body: StaticBody2D) -> Rect2:
	var points: PackedVector2Array = PackedVector2Array()
	for shape: Node in body.get_children():
		if shape is CollisionPolygon2D:
			points.append_array((shape as CollisionPolygon2D).polygon)
	if points.is_empty():
		return Rect2()
	var rect: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		rect = rect.expand(point)
	return Rect2(rect.position + body.position, rect.size)
