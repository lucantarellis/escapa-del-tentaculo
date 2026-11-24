class_name SettingsScreen
extends Control
## Pantallas de Ajustes y Créditos (pantalla completa de UI, sin ilustración). Se entra por la
## puerta de Ajustes del hub ([Hub]); VOLVER o Escape cierran y emiten [signal closed].
##
## Ajustes: SONIDO (Música y Efectos, barras deslizantes), JUEGO (Vibración, Idioma), INFO
## (Créditos ›) y DATOS (Borrar progreso, con confirmación: Cancelar tiene el foco por defecto;
## Borrar reinicia monedas y mejoras con [method PlayerProgress.reset_all]). Los valores los guarda
## y aplica [code]GameSettings[/code]. Navegable con teclado/joystick (arriba/abajo recorre,
## izquierda/derecha ajusta) y táctil. Ver `docs/mecanicas/ajustes.md` y `docs/arte/ajustes.md`.

const K = preload("res://scripts/ui/ui_kit.gd")

## Layout (px, en pantalla). Solo visual; ver `docs/arte/ajustes.md`.
const TITLE_ICON_POS: Vector2 = Vector2(12.0, 12.0)
const TITLE_TEXT_X: float = 36.0
const TITLE_TEXT_TOP: float = 15.0
const PANEL_RECT: Rect2 = Rect2(8.0, 44.0, 344.0, 317.0)
const ROW_X: float = 14.0
const ROW_WIDTH: float = 331.0
const ROW_HEIGHT: float = 27.0
const ROW_STEP: float = 31.0
const HEADER_STEP: float = 24.0
const CONTENT_TOP: float = 52.0
const ROW_TEXT_X: float = 8.0
const SLIDER_X: float = 136.0
const SLIDER_WIDTH: float = 151.0
const SLIDER_Y: float = 10.0
const SLIDER_STEP: float = 0.1
const VALUE_RIGHT_X: float = 322.0
const TOGGLE_POS: Vector2 = Vector2(294.0, 7.0)
const ARROW_LEFT_X: float = 206.0
const ARROW_RIGHT_X: float = 302.0
const LANGUAGE_CENTER_X: float = 256.0
const LINK_ARROW_X: float = 318.0
const ARROW_Y: float = 10.0
const BACK_RECT: Rect2 = Rect2(8.0, 370.0, 120.0, 30.0)
const VERSION_RIGHT: float = 348.0
const VERSION_TOP: float = 623.0
const CONFIRM_DIM: Color = Color(0.0196, 0.0235, 0.0353, 0.7)
const CONFIRM_RECT: Rect2 = Rect2(24.0, 220.0, 312.0, 150.0)
const CONFIRM_CANCEL_RECT: Rect2 = Rect2(44.0, 329.0, 110.0, 25.0)
const CONFIRM_ERASE_RECT: Rect2 = Rect2(206.0, 329.0, 110.0, 25.0)
const CREDITS_LINE_HEIGHT: float = 18.0

## Textos. Solo visual.
const TITLE_SETTINGS: String = "AJUSTES"
const TITLE_CREDITS: String = "CRÉDITOS"
const BACK_TEXT: String = "Volver"
const VERSION_TEXT: String = "v%s"
const CONFIRM_TITLE: String = "¿Borrar progreso?"
const CONFIRM_LINES: Array[String] = ["Se pierden monedas", "y mejoras."]
const CANCEL_TEXT: String = "Cancelar"
const ERASE_TEXT: String = "Borrar"
## Créditos: [texto, rubro (true) o nombre (false)], con "" como renglón vacío. La licencia de
## Tiny5 (SIL OFL) pide que figure.
const CREDITS: Array = [
	["RISE OR DIE", "title"],
	["", ""],
	["HECHO POR", "role"],
	["Luca 'LT' Cantarelli", "name"],
	["Guido Robles", "name"],
	["", ""],
	["TIPOGRAFÍA", "role"],
	["Tiny5", "name"],
	["The Tiny5 Project Authors", "name"],
	["SIL Open Font License 1.1", "name"],
	["", ""],
	["MOTOR", "role"],
	["Hecho con Godot", "name"],
]

## Se cerró la pantalla (VOLVER o Escape desde Ajustes). No se oculta sola: la oculta quien la abrió
## ([Hub]), cuando la pantalla ya está en negro.
signal closed

var _closing: bool = false

var _settings_page: Control
var _credits_page: Control
var _confirm: Control
var _rows: Array[Button] = []
var _music_row: Button
var _sfx_row: Button
var _vibration_row: Button
var _language_row: Button
var _credits_row: Button
var _erase_row: Button
var _back_button: Button
var _credits_back: Button
var _cancel_button: Button
var _erase_button: Button
var _sliders: Dictionary = {}
var _toggle: TextureRect
var _language_label: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg: ColorRect = ColorRect.new()
	bg.color = K.BG
	bg.size = Vector2(360.0, 640.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_settings()
	_build_credits()
	_build_confirm()
	GameSettings.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if GameSettings.changed.is_connected(_refresh):
		GameSettings.changed.disconnect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _confirm.visible:
		_close_confirm()
	elif _credits_page.visible:
		_show_settings()
	else:
		close()


## Muestra Ajustes con el foco en la primera fila.
func open() -> void:
	_closing = false
	visible = true
	_show_settings()


## Emite [signal closed]. Una sola vez hasta el próximo [method open].
func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	closed.emit()


## Devuelve true si se ve la pantalla de créditos. Sirve para pruebas.
func is_showing_credits() -> bool:
	return visible and _credits_page.visible


## Devuelve true si se ve la confirmación de borrar progreso. Sirve para pruebas.
func is_confirming() -> bool:
	return visible and _confirm.visible


## Fila (botón) por nombre: `music`, `sfx`, `vibration`, `language`, `credits`, `erase`. Sirve
## para pruebas.
func get_row(row_name: StringName) -> Button:
	return {&"music": _music_row, &"sfx": _sfx_row, &"vibration": _vibration_row, &"language": _language_row, &"credits": _credits_row, &"erase": _erase_row}.get(row_name) as Button


# --- armado ---------------------------------------------------------------------------------

func _build_settings() -> void:
	_settings_page = _make_page(K.SETTINGS_DIR + "st_icon_gear.png", TITLE_SETTINGS)
	var y: float = CONTENT_TOP
	_settings_page.add_child(K.header(K.SETTINGS_DIR + "st_icon_sound.png", "SONIDO", Vector2(ROW_X, y), ROW_WIDTH - 2.0))
	y += HEADER_STEP
	_music_row = _make_slider_row("Música", y, &"music")
	y += ROW_STEP
	_sfx_row = _make_slider_row("Efectos", y, &"sfx")
	y += ROW_STEP
	_settings_page.add_child(K.header(K.SETTINGS_DIR + "st_icon_game.png", "JUEGO", Vector2(ROW_X, y), ROW_WIDTH - 2.0))
	y += HEADER_STEP
	_vibration_row = _make_row("Vibración", y)
	_toggle = K.icon(K.SETTINGS_DIR + "st_toggle_on.png", TOGGLE_POS)
	_vibration_row.add_child(_toggle)
	_vibration_row.pressed.connect(func() -> void: GameSettings.set_vibration_enabled(not GameSettings.is_vibration_enabled()))
	y += ROW_STEP
	_language_row = _make_row("Idioma", y)
	_language_row.add_child(K.icon(K.SETTINGS_DIR + "st_arrow_left.png", Vector2(ARROW_LEFT_X, ARROW_Y)))
	_language_row.add_child(K.icon(K.SETTINGS_DIR + "st_arrow_right.png", Vector2(ARROW_RIGHT_X, ARROW_Y)))
	_language_label = K.label("", K.WHITE)
	_language_row.add_child(_language_label)
	_language_row.gui_input.connect(_on_language_input)
	y += ROW_STEP
	_settings_page.add_child(K.header(K.SETTINGS_DIR + "st_icon_info.png", "INFO", Vector2(ROW_X, y), ROW_WIDTH - 2.0))
	y += HEADER_STEP
	_credits_row = _make_row("Créditos", y)
	_credits_row.add_child(K.icon(K.SETTINGS_DIR + "st_arrow_right.png", Vector2(LINK_ARROW_X, ARROW_Y)))
	_credits_row.pressed.connect(_show_credits)
	y += ROW_STEP
	_settings_page.add_child(K.header(K.SETTINGS_DIR + "st_icon_data.png", "DATOS", Vector2(ROW_X, y), ROW_WIDTH - 2.0))
	y += HEADER_STEP
	_erase_row = K.button(Rect2(ROW_X, y, ROW_WIDTH, ROW_HEIGHT), K.SETTINGS_DIR + "st_btn_danger.png", K.PIECE_MARGINS)
	_erase_row.name = "EraseRow"
	var erase_text: Label = K.label("Borrar progreso", K.RED)
	_erase_row.add_child(erase_text)
	K.center_in(erase_text, Vector2(ROW_WIDTH, ROW_HEIGHT))
	_erase_row.pressed.connect(_open_confirm)
	_settings_page.add_child(_erase_row)
	_rows.append(_erase_row)
	_back_button = _make_back(_settings_page)
	_back_button.pressed.connect(close)
	var version: Label = K.label(VERSION_TEXT % String(ProjectSettings.get_setting("application/config/version", "")), K.GREY_BLUE)
	K.place_text(version, VERSION_RIGHT - K.text_width(version.text), VERSION_TOP)
	_settings_page.add_child(version)
	_link_focus(_rows, _back_button)


func _make_page(icon_path: String, title: String) -> Control:
	var page: Control = Control.new()
	page.size = Vector2(360.0, 640.0)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	page.add_child(K.icon(icon_path, TITLE_ICON_POS))
	var text: Label = K.label(title, K.CYAN)
	K.place_text(text, TITLE_TEXT_X, TITLE_TEXT_TOP)
	page.add_child(text)
	page.add_child(K.nine_rect(K.MARKET_DIR + "mk_panel_list.png", K.PANEL_MARGINS, PANEL_RECT))
	return page


func _make_back(page: Control) -> Button:
	var back: Button = K.button(BACK_RECT, K.MARKET_DIR + "mk_btn_secondary.png", K.PIECE_MARGINS)
	back.name = "BackButton"
	var text: Label = K.label(BACK_TEXT, K.WHITE)
	back.add_child(text)
	K.center_in(text, BACK_RECT.size)
	page.add_child(back)
	return back


func _make_row(title: String, y: float) -> Button:
	var row: Button = K.button(Rect2(ROW_X, y, ROW_WIDTH, ROW_HEIGHT), K.MARKET_DIR + "mk_row_buy.png", K.PIECE_MARGINS)
	row.name = title
	var text: Label = K.label(title, K.WHITE)
	K.place_text(text, ROW_TEXT_X, floorf((ROW_HEIGHT - K.GLYPH_HEIGHT) * 0.5))
	row.add_child(text)
	row.focus_neighbor_left = NodePath(".")
	row.focus_neighbor_right = NodePath(".")
	_settings_page.add_child(row)
	_rows.append(row)
	return row


func _make_slider_row(title: String, y: float, key: StringName) -> Button:
	var row: Button = _make_row(title, y)
	var track: NinePatchRect = K.nine_rect(K.SETTINGS_DIR + "st_slider_track.png", K.PIECE_MARGINS, Rect2(SLIDER_X, SLIDER_Y, SLIDER_WIDTH, 7.0))
	row.add_child(track)
	var fill: NinePatchRect = K.nine_rect(K.SETTINGS_DIR + "st_slider_fill.png", K.PIECE_MARGINS, Rect2(SLIDER_X, SLIDER_Y, SLIDER_WIDTH, 7.0))
	row.add_child(fill)
	var knob: TextureRect = K.icon(K.SETTINGS_DIR + "st_slider_knob.png", Vector2(SLIDER_X, SLIDER_Y - 2.0))
	row.add_child(knob)
	var value: Label = K.label("", K.WHITE)
	row.add_child(value)
	_sliders[key] = {"fill": fill, "knob": knob, "value": value}
	row.gui_input.connect(_on_slider_input.bind(key, row))
	return row


func _build_credits() -> void:
	_credits_page = _make_page(K.SETTINGS_DIR + "st_icon_info.png", TITLE_CREDITS)
	_credits_page.visible = false
	var y: float = CONTENT_TOP + 14.0
	for entry: Array in CREDITS:
		var text: String = entry[0]
		if text != "":
			var color: Color = K.WHITE if entry[1] == "title" else (K.TEAL if entry[1] == "role" else K.PALE)
			var line: Label = K.label(text, color)
			K.place_text(line, floorf((360.0 - K.text_width(text)) * 0.5), y)
			_credits_page.add_child(line)
		y += CREDITS_LINE_HEIGHT
	_credits_back = _make_back(_credits_page)
	_credits_back.pressed.connect(_show_settings)


func _build_confirm() -> void:
	_confirm = Control.new()
	_confirm.name = "Confirm"
	_confirm.size = Vector2(360.0, 640.0)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.visible = false
	add_child(_confirm)
	var dim: ColorRect = ColorRect.new()
	dim.color = CONFIRM_DIM
	dim.size = Vector2(360.0, 640.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.add_child(dim)
	_confirm.add_child(K.nine_rect(K.MARKET_DIR + "mk_panel_detail.png", K.PANEL_MARGINS, CONFIRM_RECT))
	var title: Label = K.label(CONFIRM_TITLE, K.WHITE)
	K.place_text(title, CONFIRM_RECT.position.x + floorf((CONFIRM_RECT.size.x - K.text_width(CONFIRM_TITLE)) * 0.5), CONFIRM_RECT.position.y + 22.0)
	_confirm.add_child(title)
	for index: int in CONFIRM_LINES.size():
		var line: Label = K.label(CONFIRM_LINES[index], K.PALE)
		K.place_text(line, CONFIRM_RECT.position.x + floorf((CONFIRM_RECT.size.x - K.text_width(CONFIRM_LINES[index])) * 0.5), CONFIRM_RECT.position.y + 50.0 + 16.0 * index)
		_confirm.add_child(line)
	_cancel_button = K.button(CONFIRM_CANCEL_RECT, K.MARKET_DIR + "mk_btn_secondary.png", K.PIECE_MARGINS)
	var cancel_text: Label = K.label(CANCEL_TEXT, K.WHITE)
	_cancel_button.add_child(cancel_text)
	K.center_in(cancel_text, CONFIRM_CANCEL_RECT.size)
	_cancel_button.pressed.connect(_close_confirm)
	_confirm.add_child(_cancel_button)
	_erase_button = K.button(CONFIRM_ERASE_RECT, K.SETTINGS_DIR + "st_btn_danger.png", K.PIECE_MARGINS)
	var erase_text: Label = K.label(ERASE_TEXT, K.RED)
	_erase_button.add_child(erase_text)
	K.center_in(erase_text, CONFIRM_ERASE_RECT.size)
	_erase_button.pressed.connect(_on_erase_confirmed)
	_confirm.add_child(_erase_button)
	_cancel_button.focus_neighbor_right = _cancel_button.get_path_to(_erase_button)
	_erase_button.focus_neighbor_left = _erase_button.get_path_to(_cancel_button)
	for button: Button in [_cancel_button, _erase_button]:
		button.focus_neighbor_top = NodePath(".")
		button.focus_neighbor_bottom = NodePath(".")


# Arriba/abajo recorren las filas en orden; la última baja a VOLVER.
func _link_focus(rows: Array[Button], back: Button) -> void:
	for index: int in rows.size():
		var row: Button = rows[index]
		var up: Button = rows[index - 1] if index > 0 else back
		var down: Button = rows[index + 1] if index < rows.size() - 1 else back
		row.focus_neighbor_top = row.get_path_to(up)
		row.focus_neighbor_bottom = row.get_path_to(down)
	back.focus_neighbor_top = back.get_path_to(rows[rows.size() - 1])
	back.focus_neighbor_bottom = back.get_path_to(rows[0])
	back.focus_neighbor_left = NodePath(".")
	back.focus_neighbor_right = NodePath(".")


# --- estado ---------------------------------------------------------------------------------

func _refresh() -> void:
	_refresh_slider(&"music", GameSettings.get_music_volume())
	_refresh_slider(&"sfx", GameSettings.get_sfx_volume())
	var on: bool = GameSettings.is_vibration_enabled()
	_toggle.texture = load(K.SETTINGS_DIR + ("st_toggle_on.png" if on else "st_toggle_off.png"))
	_language_label.text = GameSettings.get_language_name()
	K.place_text(_language_label, LANGUAGE_CENTER_X - floorf(K.text_width(_language_label.text) * 0.5), floorf((ROW_HEIGHT - K.GLYPH_HEIGHT) * 0.5))


func _refresh_slider(key: StringName, ratio: float) -> void:
	var parts: Dictionary = _sliders[key]
	var width: float = roundf(SLIDER_WIDTH * clampf(ratio, 0.0, 1.0))
	var fill: NinePatchRect = parts.fill
	fill.visible = width >= 6.0
	fill.size = Vector2(maxf(width, 6.0), 7.0)
	var knob: TextureRect = parts.knob
	knob.position = Vector2(SLIDER_X + width - floorf(knob.size.x * 0.5), SLIDER_Y - 2.0)
	var value: Label = parts.value
	value.text = "%d%%" % roundi(ratio * 100.0)
	K.place_text(value, VALUE_RIGHT_X - K.text_width(value.text), floorf((ROW_HEIGHT - K.GLYPH_HEIGHT) * 0.5))


func _set_slider(key: StringName, ratio: float) -> void:
	var snapped: float = clampf(snappedf(ratio, 0.01), 0.0, 1.0)
	if key == &"music":
		GameSettings.set_music_volume(snapped)
	else:
		GameSettings.set_sfx_volume(snapped)


func _slider_value(key: StringName) -> float:
	return GameSettings.get_music_volume() if key == &"music" else GameSettings.get_sfx_volume()


# Izquierda/derecha mueven de a 10 %; tocar o arrastrar sobre la barra fija el valor.
func _on_slider_input(event: InputEvent, key: StringName, row: Button) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var step: float = SLIDER_STEP if event.is_action_pressed("ui_right") else -SLIDER_STEP
		_set_slider(key, _slider_value(key) + step)
		row.accept_event()
		return
	var pointer: Vector2 = Vector2(-1.0, -1.0)
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pointer = (event as InputEventMouseButton).position
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pointer = (event as InputEventMouseMotion).position
	if pointer.x >= SLIDER_X - 6.0 and pointer.x <= SLIDER_X + SLIDER_WIDTH + 6.0:
		_set_slider(key, (pointer.x - SLIDER_X) / SLIDER_WIDTH)


func _on_language_input(event: InputEvent) -> void:
	var step: int = 0
	if event.is_action_pressed("ui_left"):
		step = -1
	elif event.is_action_pressed("ui_right"):
		step = 1
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var x: float = (event as InputEventMouseButton).position.x
		if x >= ARROW_LEFT_X - 10.0:
			step = -1 if x < LANGUAGE_CENTER_X else 1
	if step != 0:
		GameSettings.cycle_language(step)
		_language_row.accept_event()


func _show_settings() -> void:
	var from_credits: bool = _credits_page.visible
	_credits_page.visible = false
	_confirm.visible = false
	_settings_page.visible = true
	if is_inside_tree() and visible:
		# Volviendo de Créditos, el foco queda en su fila.
		(_credits_row if from_credits else _music_row).grab_focus()


func _show_credits() -> void:
	_settings_page.visible = false
	_credits_page.visible = true
	_credits_back.grab_focus()


func _open_confirm() -> void:
	_confirm.visible = true
	_cancel_button.grab_focus()


func _close_confirm() -> void:
	_confirm.visible = false
	_erase_row.grab_focus()


func _on_erase_confirmed() -> void:
	PlayerProgress.reset_all()
	_close_confirm()
