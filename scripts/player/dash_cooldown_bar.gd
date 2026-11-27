class_name DashCooldownBar
extends Node2D
## Barrita horizontal que sigue al jugador y muestra cuánto falta para poder volver a hacer dash.
##
## Es hija de [Player] y la controla él (llamadas hacia abajo): fija el avance con
## [method set_ratio] y la muestra u oculta con `visible`. Dibuja `hud_dash_under` y, encima,
## `hud_dash_progress` recortada de izquierda a derecha, centradas en su propia posición; el jugador
## la ubica sobre su cabeza desde `Player.tscn`. No tiene lógica de juego.
## Ver `docs/mecanicas/jugador.md` y `docs/arte/hud.md`.

## Fondo y relleno de la barra (18×5). Estructural.
const UNDER_TEXTURE: Texture2D = preload("res://assets/sprites/ui/hud/hud_dash_under.png")
const PROGRESS_TEXTURE: Texture2D = preload("res://assets/sprites/ui/hud/hud_dash_progress.png")
## Columnas del relleno dentro de la textura: primera columna y ancho (px). Solo visual; coincide
## con `hud_dash_progress.png` (relleno en x 2–15).
const FILL_START_X: float = 2.0
const FILL_WIDTH: float = 14.0
## Opacidad de la barra (igual que el HUD). Solo visual.
const BAR_ALPHA: float = 0.7

## Avance actual de 0 (recién usado) a 1 (listo para usar de nuevo).
var _ratio: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	modulate.a = BAR_ALPHA


func _draw() -> void:
	var size: Vector2 = UNDER_TEXTURE.get_size()
	var origin: Vector2 = (-size * 0.5).floor()
	draw_texture(UNDER_TEXTURE, origin)
	var width: float = FILL_START_X + roundf(FILL_WIDTH * _ratio)
	if _ratio > 0.0:
		var region: Rect2 = Rect2(0.0, 0.0, width, size.y)
		draw_texture_rect_region(PROGRESS_TEXTURE, Rect2(origin, region.size), region)


## Fija el avance de la barra. [param ratio] va de 0 (recién usado, barra vacía) a 1 (listo,
## barra llena); se acota a ese rango.
func set_ratio(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _ratio):
		return
	_ratio = clamped
	queue_redraw()

