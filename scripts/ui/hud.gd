class_name Hud
extends CanvasLayer
## HUD de solo lectura con estética de "pantalla del traje": combustible, progreso, monedas y vida.
##
## - **Combustible:** [TextureProgressBar] vertical pegada al borde izquierdo (`hud_fuel_*`). Sigue a
##   [signal Player.fuel_changed]; con el tanque vacío ([signal Player.fuel_depleted]) el relleno
##   pasa a la textura roja `hud_fuel_progress_empty`. Ícono `fuel` debajo.
## - **Progreso:** barra vertical pegada al borde derecho (`hud_progress_*`). Su relleno rojo
##   (`danger`) sube desde abajo hasta la altura del tentáculo ([method get_tentacle_progress]).
##   Ícono `goal` arriba (la puerta).
## - **Marcadores:** a la izquierda de la barra de progreso, cada uno con una línea de 1 px que la
##   cruza: jugador, calavera en el borde del rojo (tentáculo) y récord (línea punteada). Marcas de
##   tier en cada Y de [method set_tier_marks].
## - **Monedas:** ícono `coin` + número (Tiny5 16 px) arriba a la izquierda (ver [PlayerProgress]).
## - **Vida:** celdas de integridad del traje, una por punto de golpe máximo, solo si hay más de 1
##   ([signal Player.hit_points_changed]). Al perder una, parpadea antes de quedar vacía. El ícono
##   `shield` aparece al lado mientras el escudo está activo ([signal Player.shield_changed]).
##
## No modifica el juego. Todos los valores son visuales.
## Ver `docs/mecanicas/hud.md` y `docs/arte/hud.md`.

## Carpeta de las texturas del HUD. Estructural.
const SPRITE_DIR: String = "res://assets/sprites/ui/hud/"
## Fuente del número de monedas (Tiny5, SIL OFL). Estructural.
const FONT_PATH: String = "res://assets/fonts/Tiny5-Regular.ttf"
## Viewport lógico del juego (px). Estructural: coincide con `project.godot` (360×640).
const VIEWPORT_SIZE: Vector2 = Vector2(360.0, 640.0)

## Opacidad general del HUD (0..1). Solo visual.
const HUD_ALPHA: float = 0.7
## Opacidad de monedas, celdas y escudo (más legibles que las barras). Solo visual.
const STATUS_ALPHA: float = 0.9
## Ancho y alto del área útil de las barras (px). Solo visual.
const BAR_WIDTH: float = 5.0
const BAR_HEIGHT: float = 200.0
## Margen de la textura de la barra alrededor del área útil: izquierda/arriba y abajo (px). Solo
## visual; coincide con `hud_fuel_*` / `hud_progress_*` (11×206, área útil x 3–7, y 3–202).
const BAR_TEXTURE_MARGIN: Vector2 = Vector2(3.0, 3.0)
const BAR_TEXTURE_BOTTOM_MARGIN: float = 3.0
## Separación del área útil de las barras al borde de la pantalla (px). Solo visual.
const EDGE_MARGIN: float = 6.0
## Separación de los íconos `fuel` y `goal` respecto de la textura de su barra (px). Solo visual.
const BAR_ICON_GAP: float = 3.0
## Cuánto empieza la línea de un marcador a la izquierda de la barra (px). Solo visual.
const MARKER_LINE_LEAD: float = 3.0
## Separación entre el ícono de un marcador y el inicio de su línea (px). Solo visual.
const MARKER_ICON_GAP: float = 1.0
## Cuánto sobresalen las marcas de tier a la derecha de la barra (px). Solo visual.
const TIER_MARK_OVERHANG: float = 2.0
## Colores de las líneas de los marcadores. Solo visual.
const PLAYER_LINE_COLOR: Color = Color("E7EFF2")
const TENTACLE_LINE_COLOR: Color = Color("F62A19")
const RECORD_LINE_COLOR: Color = Color("63D6C5")
const TIER_LINE_COLOR: Color = Color("C8E7EA")
## Posición del ícono de la moneda (px). Solo visual.
const COIN_ICON_POSITION: Vector2 = Vector2(6.0, 6.0)
## Esquina superior de los dígitos de las monedas (px). Solo visual.
const COIN_TEXT_POSITION: Vector2 = Vector2(27.0, 12.0)
## Tamaño de fuente del número (mínimo de texto del juego, múltiplo de 8). Solo visual.
const COIN_FONT_SIZE: int = 16
## Alto de los dígitos de Tiny5 a [constant COIN_FONT_SIZE] (para ubicar su borde superior). Solo
## visual.
const COIN_GLYPH_HEIGHT: float = 10.0
## Colores del número y de su sombra de 1 px. Solo visual.
const COIN_COLOR: Color = Color("89D9EB")
const TEXT_SHADOW_COLOR: Color = Color("050609")
## Alerta de combustible crítico: color y borde superior de los dígitos. Solo visual.
const FUEL_ALERT_COLOR: Color = Color("F62A19")
const FUEL_ALERT_TOP: float = 84.0
const FUEL_ALERT_BOX_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 0.75)
## Margen del recuadro alrededor del texto (x, y). Solo visual. Unidad: px.
const FUEL_ALERT_PADDING: Vector2 = Vector2(6.0, 4.0)
## Posición de la primera celda de vida y paso entre celdas (px). Solo visual.
const CELL_POSITION: Vector2 = Vector2(6.0, 28.0)
const CELL_STEP: float = 13.0
## Separación entre la última celda y el ícono del escudo (px). Solo visual.
const SHIELD_GAP: float = 2.0
## Parpadeos de una celda al perderse y duración de cada medio parpadeo (s). Solo visual.
const CELL_BLINK_COUNT: int = 3
const CELL_BLINK_HALF: float = 0.08

## Jugador a observar. Se asigna desde la escena que instancia el HUD.
@export var player: Player
## Escala de la vida y las monedas, y alerta de combustible (ver [HudConfig]).
@export var config: HudConfig
## Tentáculo a observar para el relleno rojo y la calavera. Opcional: si queda vacío, no se
## muestran.
@export var tentacle: Tentacle

var _start_y: float = 0.0
var _end_y: float = 0.0
var _top: float = 0.0
var _fuel_ratio: float = 1.0
var _record: float = 0.0
var _tier_ys: PackedFloat32Array = PackedFloat32Array()
var _fuel_texture: Texture2D
var _fuel_empty_texture: Texture2D
var _cell_full: Texture2D
var _cell_empty: Texture2D
var _cells: Array[TextureRect] = []
var _shown_hp: int = 0
var _cell_tweens: Dictionary = {}
var _fuel_alert: Label
var _fuel_alert_box: Panel
var _fuel_alert_time: float = 0.0

@onready var _bars: Control = $Bars
@onready var _fuel_bar: TextureProgressBar = $Bars/FuelBar
@onready var _fuel_icon: TextureRect = $Bars/FuelIcon
@onready var _progress_bar: TextureProgressBar = $Bars/ProgressBar
@onready var _goal_icon: TextureRect = $Bars/GoalIcon
@onready var _lines: Control = $Bars/Lines
@onready var _record_icon: TextureRect = $Bars/RecordIcon
@onready var _skull_icon: TextureRect = $Bars/SkullIcon
@onready var _player_icon: TextureRect = $Bars/PlayerIcon
@onready var _status: Control = $Status
@onready var _coin_icon: TextureRect = $Status/CoinIcon
@onready var _coin_label: Label = $Status/CoinLabel
@onready var _cells_root: Control = $Status/Cells
@onready var _shield_icon: TextureRect = $Status/ShieldIcon


func _ready() -> void:
	_top = (VIEWPORT_SIZE.y - BAR_HEIGHT) * 0.5
	_bars.modulate.a = HUD_ALPHA
	_status.modulate.a = STATUS_ALPHA
	_apply_status_scale()
	_make_fuel_alert()
	_setup_bars()
	_setup_markers()
	_setup_coins()
	_cell_full = _tex("hud_icon_cell_full")
	_cell_empty = _tex("hud_icon_cell_empty")
	_shield_icon.texture = _tex("hud_icon_shield")
	_shield_icon.visible = false
	_lines.draw.connect(_draw_lines)
	if player == null:
		push_error("Hud: falta asignar 'player'.")
		return
	player.fuel_changed.connect(_on_fuel_changed)
	player.fuel_depleted.connect(_refresh_fuel)
	player.fuel_refilled.connect(_refresh_fuel)
	player.hit_points_changed.connect(_on_hit_points_changed)
	player.shield_changed.connect(_on_shield_changed)
	_fuel_ratio = player.get_fuel_ratio()
	_shown_hp = player.get_hit_points()
	_rebuild_cells(player.get_hit_points(), player.get_max_hit_points())
	_on_shield_changed(player.has_shield())
	_refresh_fuel()
	_refresh_progress()


func _process(delta: float) -> void:
	_update_fuel_alert(delta)
	_refresh_progress()


## Fija el rango del progreso: [param start_y] es la Y global del spawn (0 %) y [param end_y]
## la Y global de la puerta (100 %). La llama el nivel tras armarse.
func set_progress_range(start_y: float, end_y: float) -> void:
	_start_y = start_y
	_end_y = end_y
	_refresh_progress()


## Muestra el marcador del récord en [param progress] (0..1). Con 0 (sin récord) no se muestra.
func set_record(progress: float) -> void:
	_record = clampf(progress, 0.0, 1.0)
	if is_node_ready():
		_refresh_progress()


## Fija dónde empieza cada tier: [param ys] son Y globales (como las de
## [method LevelBuilder.get_tier_starts]). Se dibuja una marca por cada una.
func set_tier_marks(ys: PackedFloat32Array) -> void:
	_tier_ys = ys
	if is_node_ready():
		_lines.queue_redraw()


## Devuelve el progreso actual (0..1) según la Y del jugador. 0 si el rango no es válido.
func get_progress() -> float:
	if player == null:
		return 0.0
	return _ratio_for_y(player.global_position.y)


## Devuelve la altura del borde superior del tentáculo en la barra de progreso (0..1), con el
## mismo rango que [method get_progress]. 0 si no hay tentáculo o el rango no es válido.
func get_tentacle_progress() -> float:
	if tentacle == null:
		return 0.0
	return _ratio_for_y(tentacle.global_position.y)


## Devuelve la proporción de combustible mostrada (0..1).
func get_fuel_ratio() -> float:
	return _fuel_ratio


## Devuelve true si la barra de combustible muestra el relleno de tanque vacío.
func is_fuel_shown_empty() -> bool:
	return _fuel_bar.texture_progress == _fuel_empty_texture


static func _tex(file_name: String) -> Texture2D:
	return load(SPRITE_DIR + file_name + ".png") as Texture2D


func _setup_bars() -> void:
	_fuel_texture = _tex("hud_fuel_progress")
	_fuel_empty_texture = _tex("hud_fuel_progress_empty")
	_setup_bar(_fuel_bar, Vector2(EDGE_MARGIN, _top), _tex("hud_fuel_under"), _fuel_texture, _tex("hud_fuel_over"))
	var progress_x: float = VIEWPORT_SIZE.x - EDGE_MARGIN - BAR_WIDTH
	_setup_bar(_progress_bar, Vector2(progress_x, _top), _tex("hud_progress_under"), _tex("hud_progress_danger"), _tex("hud_progress_over"))
	_fuel_icon.texture = _tex("hud_icon_fuel")
	_fuel_icon.position = Vector2(
		roundf(_fuel_bar.position.x + (_fuel_bar.size.x - _fuel_icon.texture.get_width()) * 0.5),
		_fuel_bar.position.y + _fuel_bar.size.y + BAR_ICON_GAP)
	_goal_icon.texture = _tex("hud_icon_goal")
	_goal_icon.position = Vector2(
		roundf(_progress_bar.position.x + (_progress_bar.size.x - _goal_icon.texture.get_width()) * 0.5),
		_progress_bar.position.y - BAR_ICON_GAP - _goal_icon.texture.get_height())


# [param area_pos] es la esquina superior izquierda del área útil; la textura empieza
# [constant BAR_TEXTURE_MARGIN] antes. El valor va en filas de la textura (ver [method _bar_value]).
func _setup_bar(bar: TextureProgressBar, area_pos: Vector2, under: Texture2D, progress: Texture2D, over: Texture2D) -> void:
	bar.texture_under = under
	bar.texture_progress = progress
	bar.texture_over = over
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
	bar.min_value = 0.0
	bar.max_value = under.get_height()
	bar.step = 1.0
	bar.position = area_pos - BAR_TEXTURE_MARGIN
	bar.size = under.get_size()


# Filas de la textura a mostrar para que el área útil quede llena en [param ratio] (0..1).
static func _bar_value(ratio: float) -> float:
	return BAR_TEXTURE_BOTTOM_MARGIN + roundf(BAR_HEIGHT * clampf(ratio, 0.0, 1.0))


func _setup_markers() -> void:
	_player_icon.texture = _tex("hud_icon_player")
	_skull_icon.texture = _tex("hud_icon_skull")
	_record_icon.texture = _tex("hud_icon_record")


func _setup_coins() -> void:
	_coin_icon.texture = _tex("hud_icon_coin")
	_coin_icon.position = COIN_ICON_POSITION
	var font: Font = load(FONT_PATH) as Font
	_coin_label.add_theme_font_override("font", font)
	_coin_label.add_theme_font_size_override("font_size", COIN_FONT_SIZE)
	_coin_label.add_theme_color_override("font_color", COIN_COLOR)
	_coin_label.add_theme_color_override("font_shadow_color", TEXT_SHADOW_COLOR)
	_coin_label.add_theme_constant_override("shadow_offset_x", 1)
	_coin_label.add_theme_constant_override("shadow_offset_y", 1)
	_coin_label.add_theme_constant_override("shadow_outline_size", 0)
	# El Label dibuja la línea base a `ascent` de su borde: se corre para que el borde superior de
	# los dígitos quede en COIN_TEXT_POSITION.
	var ascent: float = font.get_ascent(COIN_FONT_SIZE)
	_coin_label.position = COIN_TEXT_POSITION - Vector2(0.0, roundf(ascent - COIN_GLYPH_HEIGHT))
	var shown: bool = PlayerProgress.is_enabled()
	_coin_icon.visible = shown
	_coin_label.visible = shown
	_on_run_coins_changed(PlayerProgress.get_run_coins())
	PlayerProgress.run_coins_changed.connect(_on_run_coins_changed)


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargar el HUD.
	if PlayerProgress.run_coins_changed.is_connected(_on_run_coins_changed):
		PlayerProgress.run_coins_changed.disconnect(_on_run_coins_changed)


func _on_run_coins_changed(run_total: int) -> void:
	_coin_label.text = str(run_total)


func _on_fuel_changed(current: float, maximum: float) -> void:
	_fuel_ratio = current / maximum if maximum > 0.0 else 0.0
	_refresh_fuel()


func _refresh_fuel() -> void:
	_fuel_bar.texture_progress = _fuel_empty_texture if player.is_fuel_empty() else _fuel_texture
	_fuel_bar.value = _bar_value(_fuel_ratio)


func _refresh_progress() -> void:
	var tentacle_shown: bool = tentacle != null and tentacle.is_active()
	_progress_bar.value = _bar_value(get_tentacle_progress()) if tentacle_shown else 0.0
	_place_marker(_player_icon, get_progress(), true)
	_place_marker(_skull_icon, get_tentacle_progress(), tentacle_shown)
	_place_marker(_record_icon, _record, _record > 0.0)
	_lines.queue_redraw()


# Ícono a la izquierda de la barra de progreso, centrado en la Y de [param progress].
func _place_marker(icon: TextureRect, progress: float, shown: bool) -> void:
	icon.visible = shown
	if not shown:
		return
	var size: Vector2 = icon.texture.get_size()
	var right: float = _progress_area_x() - MARKER_LINE_LEAD - MARKER_ICON_GAP
	icon.position = Vector2(right - size.x, _line_y(progress) - floorf(size.y * 0.5))


# Proporción 0..1 de una Y global dentro del rango spawn → puerta. 0 si el rango no es válido.
func _ratio_for_y(y: float) -> float:
	if _start_y - _end_y <= 0.0:
		return 0.0
	return clampf((_start_y - y) / (_start_y - _end_y), 0.0, 1.0)


func _progress_area_x() -> float:
	return VIEWPORT_SIZE.x - EDGE_MARGIN - BAR_WIDTH


# Fila (en pantalla, entera) del área útil para un progreso 0..1: la de arriba del relleno.
func _line_y(progress: float) -> float:
	return _top + BAR_HEIGHT - roundf(BAR_HEIGHT * clampf(progress, 0.0, 1.0))


# Líneas de 1 px que cruzan la barra de progreso, de abajo hacia arriba en importancia: tiers,
# récord, tentáculo y jugador (encima).
func _draw_lines() -> void:
	var bar_x: float = _progress_area_x()
	var start_x: float = bar_x - MARKER_LINE_LEAD
	var end_x: float = bar_x + BAR_WIDTH
	for y: float in _tier_ys:
		var tier_y: float = _line_y(_ratio_for_y(y))
		_lines.draw_rect(Rect2(bar_x, tier_y, BAR_WIDTH + TIER_MARK_OVERHANG, 1.0), TIER_LINE_COLOR)
	if _record_icon.visible:
		var record_y: float = _line_y(_record)
		var x: float = start_x
		while x < end_x:
			_lines.draw_rect(Rect2(x, record_y, 1.0, 1.0), RECORD_LINE_COLOR)
			x += 2.0
	if _skull_icon.visible:
		_lines.draw_rect(Rect2(start_x, _line_y(get_tentacle_progress()), end_x - start_x, 1.0), TENTACLE_LINE_COLOR)
	_lines.draw_rect(Rect2(start_x, _line_y(get_progress()), end_x - start_x, 1.0), PLAYER_LINE_COLOR)


func _on_hit_points_changed(current: int, maximum: int) -> void:
	if maximum != _cells.size():
		_rebuild_cells(current, maximum)
	else:
		for index: int in maximum:
			var full: bool = index < current
			if not full and index < _shown_hp:
				_blink_cell(index)
			elif full:
				_stop_blink(index)
				_cells[index].texture = _cell_full
	_shown_hp = current
	_place_shield()


func _rebuild_cells(current: int, maximum: int) -> void:
	for index: int in _cell_tweens.keys():
		_stop_blink(index)
	for cell: TextureRect in _cells:
		cell.queue_free()
	_cells.clear()
	for index: int in maximum:
		var cell: TextureRect = TextureRect.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.texture = _cell_full if index < current else _cell_empty
		cell.position = CELL_POSITION + Vector2(CELL_STEP * index, 0.0)
		_cells_root.add_child(cell)
		_cells.append(cell)
	# Regla de siempre: la vida se ve solo con más de 1 punto de golpe máximo.
	_cells_root.visible = maximum > 1
	_place_shield()


# Parpadea la celda perdida y la deja vacía.
func _blink_cell(index: int) -> void:
	_stop_blink(index)
	var cell: TextureRect = _cells[index]
	var tween: Tween = create_tween()
	for i: int in CELL_BLINK_COUNT:
		tween.tween_callback(func() -> void: cell.texture = _cell_empty)
		tween.tween_interval(CELL_BLINK_HALF)
		tween.tween_callback(func() -> void: cell.texture = _cell_full)
		tween.tween_interval(CELL_BLINK_HALF)
	tween.tween_callback(func() -> void: cell.texture = _cell_empty)
	_cell_tweens[index] = tween


func _stop_blink(index: int) -> void:
	var tween: Tween = _cell_tweens.get(index) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_cell_tweens.erase(index)


func _on_shield_changed(active: bool) -> void:
	_shield_icon.visible = active
	_place_shield()


# A continuación de las celdas visibles (o en su lugar si no se ven), centrado en su altura.
func _place_shield() -> void:
	var cell_count: int = _cells.size() if _cells_root.visible else 0
	var x: float = CELL_POSITION.x
	if cell_count > 0:
		x += CELL_STEP * (cell_count - 1) + float(_cell_full.get_width()) + SHIELD_GAP
	var cell_h: float = float(_cell_full.get_height())
	var y: float = CELL_POSITION.y + floorf((cell_h - float(_shield_icon.texture.get_height())) * 0.5)
	_shield_icon.position = Vector2(x, y)


# La esquina de estado (monedas, vida, escudo) se escala entera y se corre para que el ícono de la
# moneda siga a EDGE_MARGIN del borde.
func _apply_status_scale() -> void:
	var factor: float = float(config.status_scale) if config != null else 1.0
	_status.scale = Vector2.ONE * factor
	_status.position = Vector2.ONE * EDGE_MARGIN - COIN_ICON_POSITION * factor


# Alerta de combustible crítico: texto rojo que parpadea, centrado arriba, debajo de la vida.
func _make_fuel_alert() -> void:
	_fuel_alert = Label.new()
	_fuel_alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuel_alert.visible = false
	var font: Font = load(FONT_PATH) as Font
	_fuel_alert.add_theme_font_override("font", font)
	_fuel_alert.add_theme_font_size_override("font_size", COIN_FONT_SIZE)
	_fuel_alert.add_theme_color_override("font_color", FUEL_ALERT_COLOR)
	_fuel_alert.add_theme_color_override("font_shadow_color", TEXT_SHADOW_COLOR)
	_fuel_alert.add_theme_constant_override("shadow_offset_x", 1)
	_fuel_alert.add_theme_constant_override("shadow_offset_y", 1)
	_fuel_alert.add_theme_constant_override("shadow_outline_size", 0)
	_fuel_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fuel_alert.size = Vector2(VIEWPORT_SIZE.x, 20.0)
	_fuel_alert.position = Vector2(0.0, FUEL_ALERT_TOP - roundf(font.get_ascent(COIN_FONT_SIZE) - COIN_GLYPH_HEIGHT))
	# Recuadro oscuro con borde rojo detrás del texto (se ajusta al ancho del texto).
	_fuel_alert_box = Panel.new()
	_fuel_alert_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuel_alert_box.visible = false
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = FUEL_ALERT_BOX_COLOR
	box.border_color = FUEL_ALERT_COLOR
	box.set_border_width_all(1)
	box.anti_aliasing = false
	_fuel_alert_box.add_theme_stylebox_override("panel", box)
	add_child(_fuel_alert_box)
	add_child(_fuel_alert)


func _update_fuel_alert(delta: float) -> void:
	if _fuel_alert == null or player == null or config == null:
		return
	var empty: bool = player.is_fuel_empty()
	var low: bool = config.fuel_alert_threshold > 0.0 and _fuel_ratio < config.fuel_alert_threshold
	if not (low or empty) or not player.is_alive():
		_fuel_alert.visible = false
		_fuel_alert_box.visible = false
		_fuel_alert_time = 0.0
		return
	_fuel_alert.text = config.fuel_empty_text if empty else config.fuel_alert_text % ceili(_fuel_ratio * 100.0)
	var period: float = config.fuel_alert_on_time + config.fuel_alert_off_time
	_fuel_alert.visible = fmod(_fuel_alert_time, period) < config.fuel_alert_on_time
	# El recuadro queda fijo; solo parpadea el texto.
	var width: float = (_fuel_alert.get_theme_font("font") as Font).get_string_size(_fuel_alert.text, HORIZONTAL_ALIGNMENT_LEFT, -1, COIN_FONT_SIZE).x
	var box_w: float = roundf(width) + FUEL_ALERT_PADDING.x * 2.0
	_fuel_alert_box.position = Vector2(floorf((VIEWPORT_SIZE.x - box_w) * 0.5), FUEL_ALERT_TOP - FUEL_ALERT_PADDING.y)
	_fuel_alert_box.size = Vector2(box_w, COIN_GLYPH_HEIGHT + FUEL_ALERT_PADDING.y * 2.0 + 1.0)
	_fuel_alert_box.visible = true
	_fuel_alert_time += delta
