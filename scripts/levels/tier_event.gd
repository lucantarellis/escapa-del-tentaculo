@tool
class_name TierEvent
extends Node2D
## Momento de historia al entrar a un tier, sin quitarle el control al jugador: cuando el jugador
## cruza (subiendo) la Y de este nodo, sacude la cámara, hace un destello y cruza una silueta del
## alien hacia arriba por el fondo. Se pone en los segmentos de entrada de un tier
## (`SegmentTier.entry_segments`). Ocurre una sola vez por partida (el nivel se rearma con R).
##
## Todo es visual y placeholder (polígonos); el cambio de perseguidor y de física lo hace
## [LevelController] al cruzar el borde del tier. Ver `docs/mecanicas/tier-espacio.md`.

## Se emite cuando el evento se dispara.
signal triggered

## Color de la silueta del alien (violeta oscuro de la paleta del tentáculo). Solo visual.
const SILHOUETTE_COLOR: Color = Color("3A1B5E")
## Color de la línea de ayuda en el editor. Solo visual.
const EDITOR_LINE_COLOR: Color = Color(1.0, 0.42, 0.2, 0.8)

@export_group("Cámara")
## Fuerza de la sacudida. Unidad: px.
@export var shake_amplitude: float = 18.0
## Duración de la sacudida. Unidad: s.
@export var shake_duration: float = 0.9

@export_group("Destello")
## Color del destello que cubre la pantalla.
@export var flash_color: Color = Color(1.0, 0.85, 0.6, 1.0)
## Opacidad máxima del destello (0..1).
@export_range(0.0, 1.0, 0.05) var flash_alpha: float = 0.8
## Duración del destello (sube de golpe y se desvanece). Unidad: s.
@export var flash_duration: float = 0.5

@export_group("Silueta")
## Si es true, la silueta del alien cruza la pantalla hacia arriba por el fondo.
@export var show_silhouette: bool = true
## Tiempo que tarda la silueta en cruzar la pantalla. Unidad: s.
@export var silhouette_duration: float = 1.1
## Espera desde el destello hasta que aparece la silueta. Unidad: s.
@export var silhouette_delay: float = 0.25
## Escala de la silueta (1 = unos 120 px de alto).
@export var silhouette_scale: float = 1.4

var _fired: bool = false


func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(0.0, 0.0), Vector2(360.0, 0.0), EDITOR_LINE_COLOR, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(4.0, -4.0), "TierEvent", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EDITOR_LINE_COLOR)


func _physics_process(_delta: float) -> void:
	if _fired:
		return
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Player = node as Player
		if player != null and player.is_alive() and player.global_position.y <= global_position.y:
			fire()
			return


## Dispara el evento (si no se disparó antes).
func fire() -> void:
	if _fired:
		return
	_fired = true
	set_physics_process(false)
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if camera != null:
		camera.shake(shake_amplitude, shake_duration)
	_play_flash()
	if show_silhouette:
		_play_silhouette()
	triggered.emit()


func _play_flash() -> void:
	if flash_alpha <= 0.0 or flash_duration <= 0.0:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 85
	add_child(layer)
	var rect: ColorRect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(flash_color, flash_alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	var tween: Tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, flash_duration)
	tween.tween_callback(layer.queue_free)


# Silueta en una capa de fondo (detrás del nivel), en coordenadas de pantalla.
func _play_silhouette() -> void:
	var view: Vector2 = get_viewport_rect().size
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var body: Polygon2D = Polygon2D.new()
	body.color = SILHOUETTE_COLOR
	body.polygon = _silhouette_points()
	body.scale = Vector2.ONE * silhouette_scale
	body.position = Vector2(view.x * 0.62, view.y + 140.0 * silhouette_scale)
	layer.add_child(body)
	var tween: Tween = create_tween()
	tween.tween_interval(silhouette_delay)
	tween.tween_property(body, "position:y", -160.0 * silhouette_scale, silhouette_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)


# Cabeza ovalada con tentáculos colgando, centrada en el origen (placeholder).
func _silhouette_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var a: float = PI + PI * float(i) / 12.0
		points.append(Vector2(cos(a) * 40.0, sin(a) * 50.0 - 10.0))
	var tips: Array[float] = [36.0, 22.0, 8.0, -8.0, -22.0, -36.0]
	var lengths: Array[float] = [70.0, 95.0, 60.0, 90.0, 75.0, 65.0]
	for i: int in tips.size():
		var x: float = tips[i]
		points.append(Vector2(x + 4.0, -10.0))
		points.append(Vector2(x + (6.0 if i % 2 == 0 else -6.0), -10.0 + lengths[i]))
		points.append(Vector2(x - 4.0, -10.0))
	return points
