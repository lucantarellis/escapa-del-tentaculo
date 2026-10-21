@tool
class_name ExitBeacon
extends Node2D
## Señal de la salida del tier 3, sin flechas ni texto: es lo único luminoso del tramo final. Dibuja
## (1) motas de luz que suben por el haz y se escapan por la abertura del techo y (2) venas finas
## sobre la pared, pegadas a los bordes del túnel y convergiendo hacia la abertura, por las que
## corre un pulso de luz hacia arriba. Todo late con la viñeta. Las venas se calculan al empezar a
## partir de las celdas de la capa de paredes hermana (`Walls`). Solo dibuja con el tramo a la vista.
## Placeholders con líneas y rectángulos. Ver `docs/mecanicas/tier-alien.md`.

## Alto de cada fila de tiles. Estructural. Unidad: px.
const TILE: float = 12.0
## Alto del segmento. Estructural. Unidad: px.
const SEGMENT_HEIGHT: float = 640.0
## Pulsos por segundo del latido (igual que la viñeta: 2,2 rad/s). Solo visual.
const BEAT_RATE: float = 2.2

## Color de la luz (blanco-celeste frío: no aparece en ningún otro lugar del tier). Solo visual.
@export var light_color: Color = Color("C8E7EA")
@export_group("Abertura")
## Borde izquierdo y derecho de la abertura del techo (x local). Unidad: px.
@export var opening_left: float = 144.0
@export var opening_right: float = 216.0
@export_group("Motas")
## Cantidad de motas de luz.
@export var particle_count: int = 26
## Altura (y local, negativa hacia arriba) desde la que nacen las motas. Unidad: px.
@export var particle_start_y: float = -300.0
## Velocidad de ascenso de las motas. Unidad: px/s.
@export var particle_speed: float = 38.0
@export_group("Venas")
## Altura (y local) desde la que se dibujan las venas hacia arriba. Unidad: px.
@export var vein_start_y: float = -260.0
## Velocidad del pulso que corre por las venas. Unidad: px/s.
@export var pulse_speed: float = 150.0
## Opacidad de las venas en reposo (muy tenue). Solo visual.
@export_range(0.0, 0.5, 0.01) var vein_alpha: float = 0.16

var _walls: TileMapLayer
var _veins: Array[PackedVector2Array] = []
# Cada mota: x relativo (−1..1 del ancho del haz), fase y, velocidad, tamaño.
var _motes: Array[Vector4] = []
var _clock: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	for i: int in particle_count:
		_motes.append(Vector4(rng.randf_range(-1.0, 1.0), rng.randf(), rng.randf_range(0.7, 1.3), rng.randf_range(1.0, 2.2)))
	_walls = get_node_or_null("../Walls") as TileMapLayer
	_build_veins()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _in_view():
		return
	_clock += delta
	var light: CanvasItem = get_node_or_null("../OpeningLight") as CanvasItem
	if light != null:
		light.modulate.a = 0.85 + 0.15 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BEAT_RATE))
	queue_redraw()


# Venas: por cada fila entre vein_start_y y el techo, el borde izquierdo y derecho del túnel en el
# centro de la pantalla; la vena corre unos px dentro de la pared (dos por lado, a distinta
# profundidad).
func _build_veins() -> void:
	if _walls == null:
		return
	var rows_from: int = int(floorf(vein_start_y / TILE))
	var rows_to: int = int(floorf(-SEGMENT_HEIGHT / TILE))
	var centre_col: int = int(floorf(180.0 / TILE))
	var left: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array()]
	var right: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array()]
	var row: int = rows_from
	while row >= rows_to:
		if _walls.get_cell_source_id(Vector2i(centre_col, row)) == -1:
			var c0: int = centre_col
			while c0 > 0 and _walls.get_cell_source_id(Vector2i(c0 - 1, row)) == -1:
				c0 -= 1
			var c1: int = centre_col
			while c1 < 29 and _walls.get_cell_source_id(Vector2i(c1 + 1, row)) == -1:
				c1 += 1
			var y: float = (float(row) + 0.5) * TILE
			var wob: float = sin(y * 0.045) * 3.0
			for k: int in 2:
				var depth: float = 9.0 + 17.0 * float(k) + wob
				left[k].append(Vector2(float(c0) * TILE - depth, y))
				right[k].append(Vector2(float(c1 + 1) * TILE + depth, y))
		row -= 1
	for k: int in 2:
		if left[k].size() > 1:
			_veins.append(left[k])
		if right[k].size() > 1:
			_veins.append(right[k])


func _in_view() -> bool:
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera == null:
		return false
	var rect: Rect2 = camera.get_visible_rect().grow(60.0)
	return rect.intersects(Rect2(global_position + Vector2(0.0, -SEGMENT_HEIGHT), Vector2(360.0, SEGMENT_HEIGHT)))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(opening_left, -SEGMENT_HEIGHT, opening_right - opening_left, 40.0), Color(light_color, 0.3))
		return
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BEAT_RATE)
	_draw_veins(beat)
	_draw_motes(beat)


func _draw_veins(beat: float) -> void:
	for vein: PackedVector2Array in _veins:
		var base: Color = Color(light_color, vein_alpha * (0.8 + 0.4 * beat))
		draw_polyline(vein, base, 1.5)
		# Pulso: un tramo brillante que sube por la vena (el primer punto es el más bajo).
		var length: float = 0.0
		var seg_len: PackedFloat32Array = PackedFloat32Array()
		for i: int in vein.size() - 1:
			var l: float = vein[i].distance_to(vein[i + 1])
			seg_len.append(l)
			length += l
		if length <= 1.0:
			continue
		var head: float = fposmod(_clock * pulse_speed + vein[0].x * 3.0, length + 60.0)
		for i: int in vein.size() - 1:
			var acc: float = 0.0
			for j: int in i:
				acc += seg_len[j]
			var mid: float = acc + seg_len[i] * 0.5
			var d: float = head - mid
			if d >= 0.0 and d < 60.0:
				var a: float = (1.0 - d / 60.0) * (0.35 + 0.35 * beat)
				draw_line(vein[i], vein[i + 1], Color(light_color, a), 2.0)


func _draw_motes(beat: float) -> void:
	var top: float = -SEGMENT_HEIGHT - 60.0
	var span: float = particle_start_y - top
	for m: Vector4 in _motes:
		var p: float = fposmod(m.y + _clock * particle_speed * m.z / span, 1.0)
		var y: float = particle_start_y - p * span
		# El haz se angosta hacia la abertura.
		var k: float = clampf((particle_start_y - y) / (particle_start_y + SEGMENT_HEIGHT), 0.0, 1.0)
		var half: float = lerpf(70.0, (opening_right - opening_left) * 0.5, k)
		var x: float = 180.0 + m.x * half + sin(_clock * 1.3 + m.y * 20.0) * 4.0
		var a: float = sin(p * PI) * (0.35 + 0.35 * beat)
		draw_rect(Rect2(x, y, m.w, m.w), Color(light_color, a))
