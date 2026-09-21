@tool
class_name LevelSegment
extends Node2D
## Segmento de nivel: una pieza reutilizable escrita a mano que [LevelBuilder] apila para
## armar un nivel.
##
## Ocupa el rectángulo x ∈ [0, 360], y ∈ [−height, 0] en coordenadas locales: el ORIGEN es la
## esquina INFERIOR izquierda. El constructor coloca ese origen en la Y del borde inferior del
## segmento. `@tool`: en el editor dibuja el contorno y avisa si el segmento incumple el
## contrato. Ver `docs/mecanicas/niveles-por-segmentos.md`.

## Ancho de todo segmento (coincide con el ancho del viewport). Estructural. Unidad: px.
const WIDTH: float = 360.0
## Color del contorno que se dibuja solo en el editor. Solo visual.
const OUTLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)

@export_group("Forma")
## Alto del segmento. Es diseño de nivel, no tuning. Unidad: px.
@export var height: float = 640.0:
	set(value):
		height = maxf(value, 1.0)
		queue_redraw()
		update_configuration_warnings()

@export_group("Contrato")
## Si es true, el segmento debe contener al menos un [FuelTank] (los segmentos intermedios lo
## exigen; el de inicio y el final lo desactivan).
@export var requires_fuel_tank: bool = true:
	set(value):
		requires_fuel_tank = value
		update_configuration_warnings()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Ejecutado solo con F6 (el segmento es la escena actual): sin nada que lo encuadre, el
	# segmento queda fuera de pantalla (Y negativa). Se agrega una cámara para verlo aislado.
	if get_tree().current_scene == self:
		_add_preview_camera()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(0.0, -height, WIDTH, height), OUTLINE_COLOR, false, 2.0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if requires_fuel_tank and not has_fuel_tank():
		warnings.append("El segmento no contiene ningún FuelTank: los segmentos intermedios deben tener al menos uno.")
	for child: Node in get_out_of_bounds_children():
		warnings.append("'%s' queda fuera del rectángulo del segmento (x 0..%d, y −%d..0)." % [child.name, int(WIDTH), int(height)])
	return warnings


## Devuelve true si hay al menos un [FuelTank] entre los descendientes.
func has_fuel_tank() -> bool:
	return _contains_tank(self)


## Devuelve los hijos directos cuyo contenido sale del rectángulo del segmento. Para un
## obstáculo se cuenta su bloque completo y, si es móvil, todo su recorrido.
func get_out_of_bounds_children() -> Array[Node]:
	var result: Array[Node] = []
	var bounds: Rect2 = Rect2(0.0, -height, WIDTH, height).grow(0.5)
	for child: Node in get_children():
		var rect: Rect2 = _get_child_rect(child)
		if rect.size == Vector2.ZERO and not (child is Node2D):
			continue
		if not bounds.encloses(rect):
			result.append(child)
	return result


func _contains_tank(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is FuelTank or _contains_tank(child):
			return true
	return false


# Rectángulo (en coordenadas del segmento) que ocupa un hijo directo.
func _get_child_rect(child: Node) -> Rect2:
	if child is Obstacle:
		var obstacle: Obstacle = child as Obstacle
		var rect: Rect2 = Rect2(obstacle.position - obstacle.size * 0.5, obstacle.size)
		if child is MovingObstacle:
			rect = rect.merge(Rect2(rect.position + (child as MovingObstacle).travel, rect.size))
		return rect
	if child is Door:
		var door: Door = child as Door
		return Rect2(door.position - door.size * 0.5, door.size)
	if child is StaticBody2D:
		var body: StaticBody2D = child as StaticBody2D
		var points: PackedVector2Array = PackedVector2Array()
		for shape: Node in body.get_children():
			if shape is CollisionPolygon2D:
				points.append_array((shape as CollisionPolygon2D).polygon)
		if points.is_empty():
			return Rect2(body.position, Vector2.ZERO)
		var rect: Rect2 = Rect2(points[0], Vector2.ZERO)
		for point: Vector2 in points:
			rect = rect.expand(point)
		return Rect2(rect.position + body.position, rect.size)
	if child is Node2D:
		return Rect2((child as Node2D).position, Vector2.ZERO)
	return Rect2()


# Cámara de vista previa: centrada en el segmento y con zoom para que entre completo.
func _add_preview_camera() -> void:
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(WIDTH * 0.5, -height * 0.5)
	var view: Vector2 = get_viewport_rect().size
	var fit: float = minf(view.x / WIDTH, view.y / height)
	camera.zoom = Vector2(fit, fit)
	add_child(camera)
	camera.make_current()
