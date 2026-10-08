@tool
class_name BossBrain
extends Node2D
## Cerebro del alien (jefe final del tier 3). Tiene puntos débiles ([BrainNode], hijos de este
## nodo) que el jugador destruye embistiéndolos con el dash. Mientras quede alguno, el ojo (la
## [Door] del segmento, en `eye_path`) está cerrado; al destruir el último, el cerebro muere
## (sacudida, destello) y el ojo se abre: tocarlo gana la partida. Visual placeholder.
## Ver `docs/mecanicas/tier-alien.md`.

## Se emite cuando se destruye el último punto débil.
signal defeated

## Color del cerebro (rosado oscuro). Solo visual.
const BRAIN_COLOR: Color = Color(0.55, 0.22, 0.34, 1.0)
## Opacidad del ojo mientras está cerrado. Solo visual.
const CLOSED_ALPHA: float = 0.25

## Puerta que hace de ojo (salida). Cerrada hasta vencer al cerebro.
@export var eye_path: NodePath
## Tamaño del dibujo del cerebro. Unidad: px.
@export var brain_size: Vector2 = Vector2(220.0, 150.0):
	set(value):
		brain_size = value
		queue_redraw()
## Fuerza y duración de la sacudida al morir. Unidad: px y s.
@export var death_shake_amplitude: float = 20.0
@export var death_shake_duration: float = 1.0

var _eye: Door
var _left: int = 0


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_eye = get_node_or_null(eye_path) as Door
	for child: Node in get_children():
		if child is BrainNode:
			_left += 1
			(child as BrainNode).destroyed.connect(_on_node_destroyed)
	_set_eye_open(_left == 0)


func _draw() -> void:
	# Lóbulos: dos elipses y una franja central. Detrás de todo (z_index del nodo en la escena).
	var h: Vector2 = brain_size * 0.5
	for side: float in [-1.0, 1.0]:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 24:
			var a: float = TAU * i / 24.0
			points.append(Vector2(side * h.x * 0.48 + cos(a) * h.x * 0.52, sin(a) * h.y))
		draw_colored_polygon(points, BRAIN_COLOR)
	draw_line(Vector2(0.0, -h.y), Vector2(0.0, h.y), BRAIN_COLOR.darkened(0.4), 3.0)


## Devuelve cuántos puntos débiles quedan.
func get_nodes_left() -> int:
	return _left


func _on_node_destroyed() -> void:
	_left -= 1
	var camera: ScrollCamera = get_viewport().get_camera_2d() as ScrollCamera
	if _left > 0:
		if camera != null:
			camera.shake(8.0, 0.3)
		return
	if camera != null:
		camera.shake(death_shake_amplitude, death_shake_duration)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.3), 0.8)
	_set_eye_open(true)
	defeated.emit()


func _set_eye_open(open: bool) -> void:
	if _eye == null:
		return
	_eye.set_deferred("monitoring", open)
	_eye.modulate = Color(1.0, 1.0, 1.0, 1.0 if open else CLOSED_ALPHA)
