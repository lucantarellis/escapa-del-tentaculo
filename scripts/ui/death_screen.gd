class_name DeathScreen
extends Control
## Pantalla de derrota (pantalla completa de UI). La abre [LevelController] al perder, si la causa
## tiene una entrada en [member config]; las demás causas siguen con el texto de siempre.
##
## Arriba el título (CAPTURADO, ELECTROCUTADO…), la viñeta animada a 2× en un marco `mk_panel_list`
## con el rótulo "● REPETICIÓN", la línea de humor y el panel de datos (`mk_panel_detail`: progreso
## con barra, récord y monedas ganadas), y los botones REINTENTAR (foco por defecto, = R) y VOLVER
## AL HUB (= Escape). La viñeta reproduce `play` una vez y después `end` en bucle; tocarla durante
## `play` la salta a `end`. La línea y el panel aparecen con un fundido al terminar `play`. Los
## botones andan desde el primer cuadro. Navegable con teclado/joystick y táctil.
## Ver `docs/mecanicas/pantalla-derrota.md` y `docs/arte/derrota.md`.

const K = preload("res://scripts/ui/ui_kit.gd")

## Se pidió volver al hub (botón VOLVER AL HUB). Lo reenvía [LevelController] a [Main].
signal hub_requested

## Carpeta de las viñetas (`<nombre>.png` + `.json`). Estructural.
const VIGNETTE_DIR: String = "res://assets/sprites/ui/death/"
const COIN_ICON_PATH: String = "res://assets/sprites/ui/hud/hud_icon_coin.png"

## Layout (px, en pantalla). Solo visual; ver `docs/arte/derrota.md`.
const TITLE_CENTER: Vector2 = Vector2(180.0, 90.0)
const TITLE_FONT_SIZE: int = 32
const TITLE_GLYPH_HEIGHT: float = 20.0
const FRAME_RECT: Rect2 = Rect2(4.0, 116.0, 352.0, 204.0)
const VIGNETTE_POS: Vector2 = Vector2(8.0, 120.0)
const VIGNETTE_SCALE: float = 2.0
const VIGNETTE_SIZE: Vector2 = Vector2(172.0, 98.0)
const REPLAY_DOT_RECT: Rect2 = Rect2(14.0, 126.0, 6.0, 6.0)
const REPLAY_TEXT_X: float = 24.0
const REPLAY_TEXT_CENTER_Y: float = 129.0
const LINE_CENTER: Vector2 = Vector2(180.0, 340.0)
const DATA_PANEL_RECT: Rect2 = Rect2(8.0, 360.0, 344.0, 104.0)
const LABEL_X: float = 24.0
const VALUE_RIGHT: float = 336.0
const PROGRESS_TOP: float = 382.0
const BAR_RECT: Rect2 = Rect2(24.0, 394.0, 312.0, 7.0)
const RECORD_TOP: float = 418.0
const NEW_RECORD_CENTER_X: float = 180.0
const COINS_TOP: float = 446.0
const COIN_GAP: float = 2.0
const RETRY_RECT: Rect2 = Rect2(8.0, 484.0, 344.0, 38.0)
const HUB_RECT: Rect2 = Rect2(8.0, 530.0, 344.0, 38.0)
const VERSION_RIGHT: float = 348.0
const VERSION_CENTER_Y: float = 628.0

## Colores (paleta). Solo visual.
const BAR_BG: Color = Color("101134")
const BAR_BORDER: Color = Color("324370")
const BAR_FILL: Color = Color("3A9BBF")
const COINS_COLOR: Color = Color("F8B842")

## Textos. Solo visual.
const REPLAY_TEXT: String = "REPETICIÓN"
const PROGRESS_TEXT: String = "Progreso"
const RECORD_TEXT: String = "Récord"
const NEW_RECORD_TEXT: String = "NUEVO RÉCORD"
const COINS_TEXT: String = "Monedas"
const RETRY_TEXT: String = "REINTENTAR"
const HUB_TEXT: String = "VOLVER AL HUB"
const PERCENT_TEXT: String = "%d%%"

## Muertes, viñetas, líneas y tiempos (ver [DeathScreenConfig]).
@export var config: DeathScreenConfig

var _vignette: SheetSprite
var _line: Label
var _data: Control
var _retry_button: Button
var _hub_button: Button
var _revealed: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Devuelve true si [param cause] tiene pantalla de derrota en [param cfg].
static func has_screen(cfg: DeathScreenConfig, cause: StringName) -> bool:
	return cfg != null and cfg.get_entry(cause) != null


## Arma y muestra la pantalla para [param cause] con los datos de la partida: progreso (0..1),
## mejor progreso, si es récord nuevo y monedas ganadas. Llamarlo ya en el árbol.
func open(cause: StringName, progress: float, best: float, new_record: bool, coins: int) -> void:
	var entry: DeathScreenEntry = config.get_entry(cause) if config != null else null
	if entry == null:
		push_warning("DeathScreen: la causa '%s' no tiene pantalla." % cause)
		return
	_rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(360.0, 640.0)
	var bg: ColorRect = ColorRect.new()
	bg.color = K.BG
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_title(entry.title)
	_build_vignette(_pick(entry.vignettes))
	_build_line(_pick(entry.lines))
	_build_data(progress, best, new_record, coins)
	_build_buttons()
	_build_version()
	_retry_button.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, config.fade_in_time)


# Elemento al azar de una lista ("" si está vacía).
func _pick(list: Array[String]) -> String:
	return "" if list.is_empty() else list[_rng.randi() % list.size()]


func _build_title(text: String) -> void:
	var title: Label = K.label(text, K.RED)
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	var font: Font = K.font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE).x
	var top: float = TITLE_CENTER.y - floorf(TITLE_GLYPH_HEIGHT * 0.5)
	title.position = Vector2(roundf(TITLE_CENTER.x - floorf(width * 0.5)), roundf(top - (font.get_ascent(TITLE_FONT_SIZE) - TITLE_GLYPH_HEIGHT)))
	add_child(title)


func _build_vignette(vignette_name: String) -> void:
	add_child(K.nine_rect(K.MARKET_DIR + "mk_panel_list.png", K.PANEL_MARGINS, FRAME_RECT))
	if vignette_name != "":
		_vignette = SheetSprite.new()
		_vignette.centered = false
		_vignette.texture = load(VIGNETTE_DIR + vignette_name + ".png") as Texture2D
		_vignette.position = VIGNETTE_POS
		_vignette.scale = Vector2.ONE * VIGNETTE_SCALE
		add_child(_vignette)
		_vignette.load_sheet(VIGNETTE_DIR + vignette_name + ".json")
		_vignette.finished.connect(_on_vignette_finished)
		_vignette.play(&"play")
	# Rótulo "● REPETICIÓN" encima de la viñeta.
	add_child(_make_dot(REPLAY_DOT_RECT, K.RED))
	var replay: Label = K.label(REPLAY_TEXT, K.RED)
	K.place_text(replay, REPLAY_TEXT_X, REPLAY_TEXT_CENTER_Y - floorf(K.GLYPH_HEIGHT * 0.5))
	add_child(replay)
	# Zona táctil de la viñeta: tocarla salta a `end`.
	var touch: Control = Control.new()
	touch.position = VIGNETTE_POS
	touch.size = VIGNETTE_SIZE * VIGNETTE_SCALE
	touch.mouse_filter = Control.MOUSE_FILTER_STOP
	touch.gui_input.connect(_on_vignette_input)
	add_child(touch)
	if _vignette == null:
		_reveal()


# Punto redondo de 6×6 (sin las esquinas).
func _make_dot(rect: Rect2, color: Color) -> Control:
	var dot: Control = Control.new()
	dot.position = rect.position
	dot.size = rect.size
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for r: Rect2 in [Rect2(1.0, 0.0, rect.size.x - 2.0, rect.size.y), Rect2(0.0, 1.0, rect.size.x, rect.size.y - 2.0)]:
		var part: ColorRect = ColorRect.new()
		part.color = color
		part.position = r.position
		part.size = r.size
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(part)
	return dot


func _build_line(text: String) -> void:
	_line = K.label(text, K.PALE)
	K.place_text(_line, LINE_CENTER.x - floorf(K.text_width(text) * 0.5), LINE_CENTER.y - floorf(K.GLYPH_HEIGHT * 0.5))
	_line.modulate.a = 0.0
	add_child(_line)


func _build_data(progress: float, best: float, new_record: bool, coins: int) -> void:
	_data = Control.new()
	_data.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_data.modulate.a = 0.0
	add_child(_data)
	_data.add_child(K.nine_rect(K.MARKET_DIR + "mk_panel_detail.png", K.PANEL_MARGINS, DATA_PANEL_RECT))
	_add_row(PROGRESS_TEXT, PERCENT_TEXT % roundi(progress * 100.0), PROGRESS_TOP, K.WHITE)
	_build_bar(progress)
	_add_row(RECORD_TEXT, PERCENT_TEXT % roundi(best * 100.0), RECORD_TOP, K.WHITE)
	if new_record:
		var record: Label = K.label(NEW_RECORD_TEXT, K.AMBER)
		K.place_text(record, NEW_RECORD_CENTER_X - floorf(K.text_width(NEW_RECORD_TEXT) * 0.5), RECORD_TOP)
		_data.add_child(record)
	var coins_value: Label = _add_row(COINS_TEXT, "+%d" % coins, COINS_TOP, COINS_COLOR)
	var coin: TextureRect = K.icon(COIN_ICON_PATH, Vector2.ZERO)
	coin.position = Vector2(coins_value.position.x - COIN_GAP - coin.size.x, roundf(COINS_TOP + K.GLYPH_HEIGHT * 0.5 - coin.size.y * 0.5))
	_data.add_child(coin)


# Fila del panel: etiqueta a la izquierda y valor alineado a la derecha. Devuelve el valor.
func _add_row(label_text: String, value_text: String, top: float, value_color: Color) -> Label:
	var label: Label = K.label(label_text, K.TEAL)
	K.place_text(label, LABEL_X, top)
	_data.add_child(label)
	var value: Label = K.label(value_text, value_color)
	K.place_text(value, VALUE_RIGHT - K.text_width(value_text), top)
	_data.add_child(value)
	return value


func _build_bar(progress: float) -> void:
	var border: ColorRect = ColorRect.new()
	border.color = BAR_BORDER
	border.position = BAR_RECT.position
	border.size = BAR_RECT.size
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_data.add_child(border)
	var inner: Rect2 = BAR_RECT.grow(-1.0)
	var bg: ColorRect = ColorRect.new()
	bg.color = BAR_BG
	bg.position = inner.position
	bg.size = inner.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_data.add_child(bg)
	var fill_width: float = roundf(inner.size.x * clampf(progress, 0.0, 1.0))
	if fill_width > 0.0:
		var fill: ColorRect = ColorRect.new()
		fill.color = BAR_FILL
		fill.position = inner.position
		fill.size = Vector2(fill_width, inner.size.y)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_data.add_child(fill)


func _build_buttons() -> void:
	_retry_button = _make_button(RETRY_RECT, "mk_btn_primary", RETRY_TEXT, K.AMBER)
	_retry_button.pressed.connect(_on_retry_pressed)
	_hub_button = _make_button(HUB_RECT, "mk_btn_secondary", HUB_TEXT, K.BLUE)
	_hub_button.pressed.connect(_on_hub_pressed)
	_retry_button.focus_neighbor_bottom = _retry_button.get_path_to(_hub_button)
	_retry_button.focus_neighbor_top = _retry_button.get_path_to(_hub_button)
	_hub_button.focus_neighbor_top = _hub_button.get_path_to(_retry_button)
	_hub_button.focus_neighbor_bottom = _hub_button.get_path_to(_retry_button)


func _make_button(rect: Rect2, piece: String, text: String, color: Color) -> Button:
	var button: Button = K.button(rect, K.MARKET_DIR + piece + ".png", K.PIECE_MARGINS)
	add_child(button)
	var label: Label = K.label(text, color)
	K.center_in(label, rect.size)
	button.add_child(label)
	return button


func _build_version() -> void:
	var text: String = "v" + String(ProjectSettings.get_setting("application/config/version", ""))
	var version: Label = K.label(text, K.GREY_BLUE)
	K.place_text(version, VERSION_RIGHT - K.text_width(text), VERSION_CENTER_Y - floorf(K.GLYPH_HEIGHT * 0.5))
	add_child(version)


func _on_vignette_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not tapped:
		return
	accept_event()
	skip_to_end()


## Salta la viñeta a `end` (si todavía está en `play`) y muestra la línea y el panel.
func skip_to_end() -> void:
	if _vignette != null and _vignette.get_tag() == &"play":
		_vignette.play(&"end", true)
	_reveal()


func _on_vignette_finished(tag: StringName) -> void:
	if tag != &"play":
		return
	_vignette.play(&"end", true)
	_reveal()


# Fundido de la línea de humor y del panel de datos (una sola vez).
func _reveal() -> void:
	if _revealed:
		return
	_revealed = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_line, "modulate:a", 1.0, config.reveal_time)
	tween.tween_property(_data, "modulate:a", 1.0, config.reveal_time)


func _on_retry_pressed() -> void:
	GameManager.restart()


func _on_hub_pressed() -> void:
	hub_requested.emit()
