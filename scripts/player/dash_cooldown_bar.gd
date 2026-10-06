class_name DashCooldownBar
extends Node2D
## Barrita horizontal que sigue al jugador y muestra cuánto falta para poder volver a hacer dash.
##
## Es hija de [Player] y la controla él (llamadas hacia abajo): fija el avance con
## [method set_ratio] y la muestra u oculta con `visible`. Se dibuja centrada en su propia
## posición; el jugador la ubica sobre su cabeza desde `Player.tscn`. No tiene lógica de juego.
## Ver `docs/mecanicas/jugador.md`.

## Tamaño de la barra (ancho, alto). Solo visual. Unidad: px.
const BAR_SIZE: Vector2 = Vector2(16.0, 3.0)
## Color del relleno (blanco azulado de detalles de la paleta). Solo visual.
const FILL_COLOR: Color = Color("C8E7EA")
## Color del fondo de la barra (negro de la paleta, semitransparente). Solo visual.
const TRACK_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 0.6)

## Avance actual de 0 (recién usado) a 1 (listo para usar de nuevo).
var _ratio: float = 0.0


func _draw() -> void:
	var origin: Vector2 = -BAR_SIZE * 0.5
	draw_rect(Rect2(origin, BAR_SIZE), TRACK_COLOR)
	draw_rect(Rect2(origin, Vector2(BAR_SIZE.x * _ratio, BAR_SIZE.y)), FILL_COLOR)


## Fija el avance de la barra. [param ratio] va de 0 (recién usado, barra vacía) a 1 (listo,
## barra llena); se acota a ese rango.
func set_ratio(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _ratio):
		return
	_ratio = clamped
	queue_redraw()


## Devuelve el avance actual de la barra (0..1).
func get_ratio() -> float:
	return _ratio
