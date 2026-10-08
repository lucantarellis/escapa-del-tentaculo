@tool
class_name Asteroid
extends TileMapLayer
## Asteroide del espacio: paredes pintadas con tiles (como `Walls`) en su propio nodo, que flota
## yendo y viniendo (`drift`) y gira sobre sí mismo (`spin_speed`). El origen del nodo es el eje
## de giro: las celdas se pintan alrededor de (0, 0). Usa `use_kinematic_bodies` para que el
## jugador parado encima se mueva con él. En el editor se ve quieto.
## Ver `docs/mecanicas/tier-espacio.md`.

@export_group("Movimiento")
## Desplazamiento máximo del vaivén respecto de su posición (ida y vuelta). Unidad: px.
@export var drift: Vector2 = Vector2(0.0, 10.0)
## Duración de un vaivén completo. Unidad: s.
@export var drift_period: float = 4.0
## Desfase del vaivén (para que no se muevan todos juntos). Unidad: s.
@export var drift_offset: float = 0.0
## Velocidad de giro (positivo = horario, 0 = sin giro). Unidad: °/s.
@export var spin_speed: float = 0.0

var _origin: Vector2 = Vector2.ZERO
var _time: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	use_kinematic_bodies = true
	_origin = position
	_time = drift_offset


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if drift_period > 0.0:
		position = _origin + drift * sin(_time * TAU / drift_period)
	rotation += deg_to_rad(spin_speed) * delta
