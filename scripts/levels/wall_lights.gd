class_name WallLights
extends Node2D
## Luces de las paredes de la nave: una `PointLight2D` naranja por cada grieta incandescente (capa
## `Dano`, terreno `grieta`; una por grieta, no por celda) y una roja por cada alarma (tiles
## animados de la pared). Va como hija de la pared (`WallsShip.tscn`) y arma las luces al cargar,
## leyendo las celdas pintadas. Las que quedan lejos de la pantalla se apagan. Ver
## `docs/mecanicas/iluminacion.md`.

## Fuente de las grietas en `ship_walls_overlay.tres`. Estructural.
const CRACK_SOURCE: int = 1
## Fuente de los tiles animados en `walls_tileset_ship.tres` y celdas de las alarmas (sanas y rotas).
## Estructural.
const ANIM_SOURCE: int = 1
const ALARM_TILES: Array[Vector2i] = [Vector2i(0, 2), Vector2i(0, 4)]
const ALARM_BROKEN_TILES: Array[Vector2i] = [Vector2i(0, 3), Vector2i(0, 5)]

var _lights: Array[PointLight2D] = []
var _base_energy: PackedFloat32Array = PackedFloat32Array()
var _flicker: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var walls: TileMapLayer = get_parent() as TileMapLayer
	if walls == null:
		return
	var cfg: LightingConfig = LevelLighting.get_config()
	var tile: Vector2 = Vector2(walls.tile_set.tile_size)
	for cell: Vector2i in walls.get_used_cells_by_id(ANIM_SOURCE):
		var atlas: Vector2i = walls.get_cell_atlas_coords(cell)
		var energy: float = -1.0
		if atlas in ALARM_TILES:
			energy = cfg.alarm_energy
		elif atlas in ALARM_BROKEN_TILES:
			energy = cfg.alarm_broken_energy
		if energy > 0.0:
			_add(LevelLighting.make_light(cfg.alarm_color, energy, cfg.alarm_radius), (Vector2(cell) + Vector2(0.5, 0.5)) * tile, 0.0)
	var damage: TileMapLayer = walls.get_node_or_null("Dano") as TileMapLayer
	if damage != null:
		for group: Array[Vector2i] in _groups(damage.get_used_cells_by_id(CRACK_SOURCE)):
			var center: Vector2 = Vector2.ZERO
			for cell: Vector2i in group:
				center += (Vector2(cell) + Vector2(0.5, 0.5)) * tile
			center /= float(group.size())
			var radius: float = minf(cfg.crack_radius + cfg.crack_radius_per_cell * (group.size() - 1), cfg.crack_radius_max)
			_add(LevelLighting.make_light(cfg.crack_color, cfg.crack_energy, radius), center, cfg.crack_flicker)
	set_process(not _lights.is_empty())


func _process(delta: float) -> void:
	_time += delta
	var cfg: LightingConfig = LevelLighting.get_config()
	var screen: Rect2 = _screen_rect().grow(cfg.cull_margin)
	for i: int in _lights.size():
		var light: PointLight2D = _lights[i]
		var on: bool = screen == Rect2() or screen.has_point(light.global_position)
		light.enabled = on
		if on and _flicker[i] > 0.0:
			var seed_value: float = float(i) * 1.7
			var wave: float = 0.5 + 0.5 * sin(_time * 11.0 + seed_value) * sin(_time * 6.3 + seed_value * 2.0)
			light.energy = _base_energy[i] * (1.0 - _flicker[i] * wave)


func _add(light: PointLight2D, pos: Vector2, flicker: float) -> void:
	light.position = pos
	add_child(light)
	_lights.append(light)
	_base_energy.append(light.energy)
	_flicker.append(flicker)


# Agrupa celdas vecinas (por los lados) en grietas.
static func _groups(cells: Array[Vector2i]) -> Array:
	var left: Dictionary = {}
	for cell: Vector2i in cells:
		left[cell] = true
	var groups: Array = []
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var group: Array[Vector2i] = [start]
		var queue: Array[Vector2i] = [start]
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if left.has(next):
					left.erase(next)
					group.append(next)
					queue.append(next)
		groups.append(group)
	return groups


func _screen_rect() -> Rect2:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return Rect2()
	if camera is ScrollCamera:
		return (camera as ScrollCamera).get_visible_rect()
	var view: Vector2 = get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view * 0.5, view)
