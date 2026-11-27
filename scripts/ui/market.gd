class_name Market
extends Control
## Mercado: árbol de talentos donde se gastan las monedas guardadas en mejoras permanentes.
##
## Pantalla de 360×640: arriba el puesto con el vendedor (`market_booth`, ambiente en bucle) y su
## cara en la pantalla (`market_face`, reacciona a abrir, navegar, comprar, no alcanzar y salir);
## abajo la UI con piezas 9-slice (`mk_*`) y Tiny5 16 px: monedas, compras gratis y RESET arriba,
## tres solapas (Movimiento, Supervivencia, Economía), la lista de nodos con scroll agrupada por rama
## y el detalle del nodo elegido con VOLVER y COMPRAR. Las compras las hace [PlayerProgress]; esta
## pantalla solo las pide y se actualiza. Con Escape (`ui_cancel`) o VOLVER la cara se apaga
## (`exit`) y al terminar emite [signal closed] (quien lo abrió lo oculta).
## Ver `docs/mecanicas/progreso-mercado.md` y `docs/arte/mercado.md`.

## Carpetas del arte. Estructural.
const UI_DIR: String = "res://assets/sprites/ui/market/"
const COIN_ICON_PATH: String = "res://assets/sprites/ui/hud/hud_icon_coin.png"
const FONT_PATH: String = "res://assets/fonts/Tiny5-Regular.ttf"

## Solapas: texto, ancho (px) y ramas que agrupa, en orden. Una rama que no figure va a la última.
## Solo visual.
const TABS: Array[Dictionary] = [
	{"label": "Movimiento", "width": 104, "branches": [&"dash", &"speed"]},
	{"label": "Supervivencia", "width": 130, "branches": [&"lives", &"repair", &"tank"]},
	{"label": "Economía", "width": 96, "branches": [&"coins"]},
]
## Ícono (`mk_branch_<nombre>`) y título del subencabezado de cada rama. Solo visual.
const BRANCH_ICONS: Dictionary = {&"dash": "dash", &"speed": "speed", &"tank": "tank", &"lives": "life", &"repair": "repair", &"coins": "coins"}
const BRANCH_TITLES: Dictionary = {&"dash": "DASH", &"speed": "VELOCIDAD", &"tank": "TANQUE", &"lives": "VIDA", &"repair": "REPARACIÓN", &"coins": "MONEDAS"}

## Colores (paleta). Solo visual.
const UI_BG_COLOR: Color = Color("0E1632")
const WHITE: Color = Color("E7EFF2")
const PALE: Color = Color("C8E7EA")
const CYAN: Color = Color("89D9EB")
const TEAL: Color = Color("63D6C5")
const BLUE: Color = Color("3A9BBF")
const GREY_BLUE: Color = Color("6689B7")
const AMBER: Color = Color("FCD51D")
const RED: Color = Color("F62A19")
const SHADOW: Color = Color("050609")

## Tamaño de fuente (mínimo del juego, múltiplo de 8) y alto de los dígitos de Tiny5 a ese tamaño,
## para ubicar el borde superior del texto. Solo visual.
const FONT_SIZE: int = 16
const GLYPH_HEIGHT: float = 10.0

## Puesto y cara del vendedor: posición de la cara en el puesto (px), luz sobre la pantalla (centro,
## color normal y de `deny`, energía y radio). Solo visual.
const FACE_POSITION: Vector2 = Vector2(134.0, 59.0)
const SCREEN_LIGHT_POSITION: Vector2 = Vector2(180.0, 86.0)
const SCREEN_LIGHT_COLOR: Color = Color("89D9EB")
const SCREEN_LIGHT_DENY_COLOR: Color = Color("F62A19")
const SCREEN_LIGHT_ENERGY: float = 0.5
const SCREEN_LIGHT_RADIUS: float = 80.0
## Segundos sin moverse por la lista hasta que la cara vuelve de `browse` a `idle`. Solo visual.
const BROWSE_IDLE_TIME: float = 2.0

## Layout (px, en pantalla). Solo visual; ver `docs/arte/mercado.md`.
const UI_TOP: float = 208.0
const COIN_ICON_POS: Vector2 = Vector2(10.0, 214.0)
const COIN_TEXT_X: float = 34.0
const TOP_TEXT_TOP: float = 218.0
const FREE_TEXT_X: float = 80.0
const RESET_RECT: Rect2 = Rect2(276.0, 212.0, 75.0, 23.0)
const TABS_X: float = 8.0
const TAB_GAP: float = 2.0
const TAB_ACTIVE_TOP: float = 240.0
const TAB_ACTIVE_HEIGHT: float = 27.0
const TAB_INACTIVE_TOP: float = 244.0
const TAB_INACTIVE_HEIGHT: float = 22.0
const LIST_PANEL_RECT: Rect2 = Rect2(8.0, 266.0, 344.0, 265.0)
## Zona con scroll: 1 px más ancha que las filas de cada lado para que se vea el foco.
const LIST_RECT: Rect2 = Rect2(13.0, 271.0, 329.0, 255.0)
const ROW_WIDTH: float = 327.0
const ROW_HEIGHT: float = 27.0
const HEADER_HEIGHT: float = 20.0
const ROW_GAP: float = 3.0
const ROW_PADDING: float = 8.0
const HEADER_ICON_X: float = 1.0
const HEADER_TITLE_X: float = 22.0
const HEADER_LINE_END_X: float = 324.0
const SCROLL_TRACK_RECT: Rect2 = Rect2(345.0, 272.0, 3.0, 253.0)
const SCROLL_GRABBER_MIN: float = 8.0
const DETAIL_PANEL_RECT: Rect2 = Rect2(8.0, 538.0, 344.0, 97.0)
const DETAIL_TEXT_X: float = 16.0
const DETAIL_RIGHT_X: float = 343.0
const DETAIL_TITLE_TOP: float = 552.0
const DETAIL_DESC_TOP: float = 574.0
const BACK_RECT: Rect2 = Rect2(16.0, 596.0, 81.0, 25.0)
const BUY_RECT: Rect2 = Rect2(209.0, 596.0, 134.0, 25.0)
const ICON_GAP: float = 4.0

## Márgenes 9-slice (izquierda, arriba, derecha, abajo). Solo visual.
const PANEL_MARGINS: Array[int] = [6, 6, 6, 6]
const PIECE_MARGINS: Array[int] = [3, 3, 3, 3]
const ROW_OWN_MARGINS: Array[int] = [5, 3, 3, 3]
const SCROLL_TRACK_MARGINS: Array[int] = [0, 1, 0, 1]
const SCROLL_GRABBER_MARGINS: Array[int] = [0, 2, 0, 1]

## Textos de la pantalla. Solo visual.
const RESET_TEXT: String = "RESET"
const RESET_CONFIRM_TEXT: String = "¿SÍ?"
const FREE_ONE_TEXT: String = "+%d compra gratis"
const FREE_MANY_TEXT: String = "+%d compras gratis"
const FREE_PRICE_TEXT: String = "GRATIS"
const OWNED_TEXT: String = "Comprado"
const BACK_TEXT: String = "Volver"
const BUY_TEXT: String = "Comprar"
const REASON_LOCKED: String = "Próximamente"
const REASON_REQUIRES: String = "Requiere: %s"
const REASON_COINS: String = "Te faltan %d"
## Segundos que espera la confirmación de RESET antes de cancelarse. Unidad: s.
const RESET_CONFIRM_TIME: float = 3.0

## Se cerró el mercado (VOLVER o Escape), después de la animación `exit` de la cara.
signal closed

var _font: Font
var _coin_icon: Texture2D
var _booth: SheetSprite
var _face: SheetSprite
var _face_tag: StringName = &""
var _screen_light: PointLight2D
var _browse_left: float = 0.0
var _closing: bool = false

var _coins_label: Label
var _free_label: Label
var _reset_button: Button
var _reset_label: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _scroll_track: NinePatchRect
var _scroll_grabber: NinePatchRect
var _detail_title: Label
var _detail_reason: Label
var _detail_desc: Label
var _back_button: Button
var _buy_button: Button
var _buy_content: Control

# Solapas en orden: [{label, width, branches: Array[StringName], button: Button, label_node: Label}].
var _tabs: Array[Dictionary] = []
# Rama → nodos (UpgradeData) en el orden de la config.
var _upgrades_by_branch: Dictionary = {}
# id → Button de la fila (solo las de la solapa actual).
var _row_buttons: Dictionary = {}
var _row_order: Array[StringName] = []
var _current_tab: int = 0
var _selected_id: StringName = &""
var _reset_token: int = 0
var _reset_pending: bool = false
var _styles: Dictionary = {}


func _ready() -> void:
	_font = load(FONT_PATH) as Font
	_coin_icon = load(COIN_ICON_PATH) as Texture2D
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_group_upgrades()
	_build_booth()
	_build_top_bar()
	_build_tabs()
	_build_list()
	_build_detail()
	PlayerProgress.coins_changed.connect(_on_coins_changed)
	PlayerProgress.free_buys_changed.connect(_on_coins_changed)
	_rebuild_rows()
	_refresh()


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargar el mercado.
	if PlayerProgress.coins_changed.is_connected(_on_coins_changed):
		PlayerProgress.coins_changed.disconnect(_on_coins_changed)
	if PlayerProgress.free_buys_changed.is_connected(_on_coins_changed):
		PlayerProgress.free_buys_changed.disconnect(_on_coins_changed)


func _process(delta: float) -> void:
	if not visible:
		return
	if _face_tag == &"browse":
		_browse_left -= delta
		if _browse_left <= 0.0:
			_play_face(&"idle")
	_update_scrollbar()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Abre el mercado: lo muestra, la cara se prende (`enter`) y deja el foco en el primer nodo que se
## puede comprar de la solapa actual.
func open() -> void:
	_closing = false
	_cancel_reset()
	_rebuild_rows()
	_refresh()
	visible = true
	_play_face(&"enter")
	_focus_first()


## Cierra el mercado: la cara se apaga (`exit`) y al terminar emite [signal closed]. No se oculta
## solo: lo oculta quien lo abrió ([Hub]).
func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	_cancel_reset()
	_play_face(&"exit")


## Muestra la solapa que contiene la rama [param branch_id] (por ejemplo `dash`). No hace nada si
## no existe.
func show_branch(branch_id: StringName) -> void:
	for index: int in _tabs.size():
		if (_tabs[index]["branches"] as Array).has(branch_id):
			_set_tab(index)
			return


## Devuelve la fila del nodo [param id] (null si no está en la solapa actual). Sirve para pruebas.
func get_node_button(id: StringName) -> Button:
	return _row_buttons.get(id) as Button


# --- armado ---------------------------------------------------------------------------------

func _group_upgrades() -> void:
	for tab: Dictionary in TABS:
		_tabs.append({"label": tab.label, "width": float(tab.width), "branches": (tab.branches as Array).duplicate()})
	for upgrade: UpgradeData in PlayerProgress.config.upgrades:
		if upgrade == null:
			continue
		if not _upgrades_by_branch.has(upgrade.branch):
			_upgrades_by_branch[upgrade.branch] = []
			var known: bool = false
			for tab: Dictionary in _tabs:
				if (tab.branches as Array).has(upgrade.branch):
					known = true
			if not known:
				(_tabs[_tabs.size() - 1].branches as Array).append(upgrade.branch)
		(_upgrades_by_branch[upgrade.branch] as Array).append(upgrade)


func _build_booth() -> void:
	var stage: Node2D = Node2D.new()
	stage.name = "Booth"
	add_child(stage)
	_booth = _make_sheet("market_booth")
	stage.add_child(_booth)
	_booth.play(&"ambient", true)
	_face = _make_sheet("market_face")
	_face.position = FACE_POSITION
	_face.finished.connect(_on_face_finished)
	stage.add_child(_face)
	_screen_light = LevelLighting.make_light(SCREEN_LIGHT_COLOR, SCREEN_LIGHT_ENERGY, SCREEN_LIGHT_RADIUS)
	_screen_light.name = "ScreenLight"
	_screen_light.position = SCREEN_LIGHT_POSITION
	stage.add_child(_screen_light)
	_play_face(&"idle")
	var bg: ColorRect = ColorRect.new()
	bg.name = "UiBackground"
	bg.color = UI_BG_COLOR
	bg.position = Vector2(0.0, UI_TOP)
	bg.size = Vector2(360.0, 640.0 - UI_TOP)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)


# Hoja con su capa emisiva encima (sin sombreado), las dos con la esquina superior izquierda en el
# origen.
func _make_sheet(sheet: String) -> SheetSprite:
	var sprite: SheetSprite = SheetSprite.new()
	sprite.name = sheet
	sprite.centered = false
	sprite.texture = load(UI_DIR + sheet + ".png")
	var emissive: Sprite2D = Sprite2D.new()
	emissive.name = "Emissive"
	emissive.centered = false
	emissive.texture = load(UI_DIR + sheet + "_emissive.png")
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	emissive.material = unshaded
	sprite.add_child(emissive)
	sprite.followers = [emissive]
	sprite.load_sheet(UI_DIR + sheet + ".json")
	return sprite


func _build_top_bar() -> void:
	var icon: TextureRect = _icon(_coin_icon, COIN_ICON_POS)
	add_child(icon)
	_coins_label = _label("0", CYAN)
	_place_text(_coins_label, COIN_TEXT_X, TOP_TEXT_TOP)
	add_child(_coins_label)
	_free_label = _label("", AMBER)
	_place_text(_free_label, FREE_TEXT_X, TOP_TEXT_TOP)
	add_child(_free_label)
	_reset_button = _button(RESET_RECT, "mk_btn_reset", PANEL_MARGINS)
	_reset_button.name = "ResetButton"
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_button.focus_exited.connect(_cancel_reset)
	add_child(_reset_button)
	_reset_label = _label(RESET_TEXT, WHITE)
	_reset_button.add_child(_reset_label)
	_update_reset_button()


func _build_tabs() -> void:
	var panel: NinePatchRect = _nine_rect("mk_panel_list", PANEL_MARGINS, LIST_PANEL_RECT)
	panel.name = "ListPanel"
	add_child(panel)
	var x: float = TABS_X
	for index: int in _tabs.size():
		var tab: Dictionary = _tabs[index]
		var button: Button = Button.new()
		button.name = "Tab%d" % index
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_tab_pressed.bind(index))
		button.position = Vector2(x, TAB_INACTIVE_TOP)
		add_child(button)
		var text: Label = _label(tab.label, BLUE)
		button.add_child(text)
		tab["button"] = button
		tab["label_node"] = text
		tab["x"] = x
		x += float(tab.width) + TAB_GAP


func _build_list() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.position = LIST_RECT.position
	_scroll.size = LIST_RECT.size
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.follow_focus = true
	add_child(_scroll)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 1)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(margin)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.add_theme_constant_override("separation", int(ROW_GAP))
	margin.add_child(_list)
	_scroll_track = _nine_rect("mk_scroll_track", SCROLL_TRACK_MARGINS, SCROLL_TRACK_RECT)
	add_child(_scroll_track)
	_scroll_grabber = _nine_rect("mk_scroll_grabber", SCROLL_GRABBER_MARGINS, Rect2(SCROLL_TRACK_RECT.position, Vector2(SCROLL_TRACK_RECT.size.x, SCROLL_GRABBER_MIN)))
	add_child(_scroll_grabber)


func _build_detail() -> void:
	add_child(_nine_rect("mk_panel_detail", PANEL_MARGINS, DETAIL_PANEL_RECT))
	_detail_title = _label("", WHITE)
	_place_text(_detail_title, DETAIL_TEXT_X, DETAIL_TITLE_TOP)
	add_child(_detail_title)
	_detail_reason = _label("", GREY_BLUE)
	_place_text(_detail_reason, DETAIL_TEXT_X, DETAIL_TITLE_TOP)
	add_child(_detail_reason)
	_detail_desc = _label("", PALE)
	_place_text(_detail_desc, DETAIL_TEXT_X, DETAIL_DESC_TOP)
	_detail_desc.clip_text = true
	_detail_desc.size.x = DETAIL_RIGHT_X - DETAIL_TEXT_X
	add_child(_detail_desc)
	_back_button = _button(BACK_RECT, "mk_btn_secondary", PIECE_MARGINS)
	_back_button.name = "BackButton"
	_back_button.pressed.connect(close)
	add_child(_back_button)
	var back_text: Label = _label(BACK_TEXT, WHITE)
	_back_button.add_child(back_text)
	_center_in(back_text, BACK_RECT.size)
	_buy_button = _button(BUY_RECT, "mk_btn_primary", PIECE_MARGINS)
	_buy_button.name = "BuyButton"
	_buy_button.pressed.connect(_on_buy_pressed)
	add_child(_buy_button)
	_buy_content = Control.new()
	_buy_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buy_button.add_child(_buy_content)
	_back_button.focus_neighbor_right = _back_button.get_path_to(_buy_button)
	_buy_button.focus_neighbor_left = _buy_button.get_path_to(_back_button)


# --- filas ----------------------------------------------------------------------------------

# Arma la lista de la solapa actual: un subencabezado por rama y una fila por nodo.
func _rebuild_rows() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_row_buttons.clear()
	_row_order.clear()
	if _tabs.is_empty():
		return
	for branch: StringName in _tabs[_current_tab].branches:
		if not _upgrades_by_branch.has(branch):
			continue
		_list.add_child(_make_header(branch))
		for upgrade: UpgradeData in _upgrades_by_branch[branch]:
			var row: Button = _make_row(upgrade)
			_list.add_child(row)
			_row_buttons[upgrade.id] = row
			_row_order.append(upgrade.id)
	if _selected_id == &"" or not _row_buttons.has(_selected_id):
		_selected_id = _row_order[0] if not _row_order.is_empty() else &""
	_link_focus()
	_scroll.scroll_vertical = 0


func _make_header(branch: StringName) -> Control:
	var header: Control = Control.new()
	header.custom_minimum_size = Vector2(ROW_WIDTH, HEADER_HEIGHT)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_name: String = BRANCH_ICONS.get(branch, "coins")
	var icon: TextureRect = _icon(load(UI_DIR + "mk_branch_%s.png" % icon_name), Vector2(HEADER_ICON_X, 1.0))
	header.add_child(icon)
	var title: String = BRANCH_TITLES.get(branch, String(branch).to_upper())
	var text: Label = _label(title, TEAL)
	_place_text(text, HEADER_TITLE_X, floorf((HEADER_HEIGHT - GLYPH_HEIGHT) * 0.5))
	header.add_child(text)
	var line_x: float = HEADER_TITLE_X + _text_width(title) + ICON_GAP
	var line: ColorRect = ColorRect.new()
	line.color = BLUE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.position = Vector2(line_x, floorf(HEADER_HEIGHT * 0.5))
	line.size = Vector2(maxf(HEADER_LINE_END_X - line_x, 0.0), 1.0)
	header.add_child(line)
	return header


func _make_row(upgrade: UpgradeData) -> Button:
	var row: Button = Button.new()
	row.name = String(upgrade.id)
	row.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
	row.focus_mode = Control.FOCUS_ALL
	row.pressed.connect(_on_row_pressed.bind(upgrade.id))
	row.focus_entered.connect(_on_row_focused.bind(upgrade.id))
	row.gui_input.connect(_on_row_input)
	_fill_row(row, upgrade)
	return row


# Fondo, nombre y lado derecho de una fila según su estado (ver `docs/arte/mercado.md`).
func _fill_row(row: Button, upgrade: UpgradeData) -> void:
	for child: Node in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var reason: StringName = PlayerProgress.get_block_reason(upgrade.id)
	var piece: String = "mk_row_buy"
	var margins: Array[int] = PIECE_MARGINS
	var name_color: Color = WHITE
	var right: Array[Control] = []
	match reason:
		PlayerProgress.BLOCK_OWNED:
			piece = "mk_row_own"
			margins = ROW_OWN_MARGINS
			name_color = CYAN
			right = [_icon(load(UI_DIR + "mk_icon_check.png"), Vector2.ZERO), _label(OWNED_TEXT, TEAL)]
		PlayerProgress.BLOCK_LOCKED, PlayerProgress.BLOCK_REQUIRES:
			piece = "mk_row_lock"
			name_color = GREY_BLUE
			right = [_icon(load(UI_DIR + "mk_icon_lock.png"), Vector2.ZERO)]
		PlayerProgress.BLOCK_COINS:
			name_color = CYAN
			right = [_icon(_coin_icon, Vector2.ZERO), _label(str(upgrade.price), RED)]
		_:
			if PlayerProgress.is_free_buy(upgrade.id):
				right = [_label(FREE_PRICE_TEXT, AMBER)]
			else:
				right = [_icon(_coin_icon, Vector2.ZERO), _label(str(upgrade.price), AMBER)]
	_set_button_style(row, piece, margins)
	var title: Label = _label(upgrade.display_name, name_color)
	_place_text(title, ROW_PADDING, floorf((ROW_HEIGHT - GLYPH_HEIGHT) * 0.5))
	row.add_child(title)
	# El lado derecho se arma de derecha a izquierda, centrado en alto.
	var x: float = ROW_WIDTH - ROW_PADDING
	for index: int in range(right.size() - 1, -1, -1):
		var item: Control = right[index]
		row.add_child(item)
		if item is Label:
			x -= _text_width((item as Label).text)
			_place_text(item as Label, x, floorf((ROW_HEIGHT - GLYPH_HEIGHT) * 0.5))
		else:
			var size: Vector2 = (item as TextureRect).texture.get_size()
			x -= size.x
			item.position = Vector2(x, floorf((ROW_HEIGHT - size.y) * 0.5))
		x -= ICON_GAP


# Vecinos de foco: la primera fila sube a la solapa activa, la última baja a COMPRAR, y los botones
# del detalle suben a la fila elegida.
func _link_focus() -> void:
	var tab_button: Button = _tabs[_current_tab].button
	for tab: Dictionary in _tabs:
		var button: Button = tab.button
		button.focus_neighbor_top = button.get_path_to(_reset_button)
		if not _row_order.is_empty():
			button.focus_neighbor_bottom = button.get_path_to(_row_buttons[_row_order[0]])
	_reset_button.focus_neighbor_bottom = _reset_button.get_path_to(tab_button)
	for index: int in _row_order.size():
		var row: Button = _row_buttons[_row_order[index]]
		row.focus_neighbor_left = NodePath(".")
		row.focus_neighbor_right = NodePath(".")
		if index == 0:
			row.focus_neighbor_top = row.get_path_to(tab_button)
		if index == _row_order.size() - 1:
			row.focus_neighbor_bottom = row.get_path_to(_buy_button)
	_link_detail_focus()


func _link_detail_focus() -> void:
	var selected: Button = _row_buttons.get(_selected_id) as Button
	for button: Button in [_back_button, _buy_button]:
		button.focus_neighbor_top = button.get_path_to(selected) if selected != null else NodePath("")


# --- actualización --------------------------------------------------------------------------

func _refresh() -> void:
	_coins_label.text = str(PlayerProgress.get_coins())
	var free_buys: int = PlayerProgress.get_free_buys()
	_free_label.visible = free_buys > 0
	_free_label.text = (FREE_ONE_TEXT if free_buys == 1 else FREE_MANY_TEXT) % free_buys
	for index: int in _tabs.size():
		_style_tab(index)
	for id: StringName in _row_order:
		_fill_row(_row_buttons[id], PlayerProgress.get_upgrade(id))
	_update_detail()


func _style_tab(index: int) -> void:
	var tab: Dictionary = _tabs[index]
	var active: bool = index == _current_tab
	var button: Button = tab.button
	var top: float = TAB_ACTIVE_TOP if active else TAB_INACTIVE_TOP
	var height: float = TAB_ACTIVE_HEIGHT if active else TAB_INACTIVE_HEIGHT
	button.position = Vector2(tab.x, top)
	button.size = Vector2(tab.width, height)
	_set_button_style(button, "mk_tab_active" if active else "mk_tab_inactive", PIECE_MARGINS)
	var text: Label = tab.label_node
	text.add_theme_color_override("font_color", WHITE if active else BLUE)
	_center_in(text, Vector2(tab.width, height))
	# La activa queda encima del borde del panel (se funde con él).
	if active:
		move_child(button, -1)


func _update_detail() -> void:
	_link_detail_focus()
	for child: Node in _buy_content.get_children():
		_buy_content.remove_child(child)
		child.queue_free()
	var upgrade: UpgradeData = PlayerProgress.get_upgrade(_selected_id)
	if upgrade == null:
		_detail_title.text = ""
		_detail_reason.text = ""
		_detail_desc.text = ""
		_set_buy_enabled(false, false)
		return
	_detail_title.text = upgrade.display_name
	_detail_desc.text = upgrade.short_description if upgrade.short_description != "" else upgrade.description
	var reason: StringName = PlayerProgress.get_block_reason(upgrade.id)
	var reason_text: String = ""
	var reason_color: Color = GREY_BLUE
	match reason:
		PlayerProgress.BLOCK_OWNED:
			reason_text = OWNED_TEXT
			reason_color = TEAL
		PlayerProgress.BLOCK_LOCKED:
			reason_text = REASON_LOCKED
		PlayerProgress.BLOCK_REQUIRES:
			var required: UpgradeData = PlayerProgress.get_upgrade(upgrade.requires_id)
			reason_text = REASON_REQUIRES % (required.display_name if required != null else String(upgrade.requires_id))
		PlayerProgress.BLOCK_COINS:
			reason_text = REASON_COINS % (upgrade.price - PlayerProgress.get_coins())
			reason_color = RED
	_detail_reason.text = reason_text
	_detail_reason.add_theme_color_override("font_color", reason_color)
	_place_text(_detail_reason, DETAIL_RIGHT_X - _text_width(reason_text), DETAIL_TITLE_TOP)
	# COMPRAR: texto + moneda + precio (o GRATIS). Sin monedas se ve apagado pero se puede tocar
	# (la cara responde con `deny`); comprado o bloqueado no se puede tocar.
	var items: Array[Control] = [_label(BUY_TEXT, WHITE)]
	if reason != PlayerProgress.BLOCK_OWNED:
		if reason == PlayerProgress.BLOCK_NONE and PlayerProgress.is_free_buy(upgrade.id):
			items.append(_label(FREE_PRICE_TEXT, AMBER))
		else:
			items.append(_icon(_coin_icon, Vector2.ZERO))
			items.append(_label(str(upgrade.price), AMBER))
	_layout_inline(_buy_content, items, BUY_RECT.size)
	_set_buy_enabled(reason == PlayerProgress.BLOCK_NONE, reason == PlayerProgress.BLOCK_COINS)


# Pone textos e íconos en fila, centrados en [param area] y en píxeles enteros.
func _layout_inline(parent: Control, items: Array[Control], area: Vector2) -> void:
	var widths: Array[float] = []
	var total: float = 0.0
	for item: Control in items:
		var w: float = _text_width((item as Label).text) if item is Label else (item as TextureRect).texture.get_size().x
		widths.append(w)
		total += w
	total += ICON_GAP * float(items.size() - 1)
	var x: float = floorf((area.x - total) * 0.5)
	for index: int in items.size():
		var item: Control = items[index]
		parent.add_child(item)
		if item is Label:
			_place_text(item as Label, x, floorf((area.y - GLYPH_HEIGHT) * 0.5))
		else:
			item.position = Vector2(x, floorf((area.y - (item as TextureRect).texture.get_size().y) * 0.5))
		x += widths[index] + ICON_GAP


func _set_buy_enabled(can_buy: bool, pressable: bool) -> void:
	_buy_button.disabled = not (can_buy or pressable)
	_set_button_style(_buy_button, "mk_btn_primary" if can_buy else "mk_btn_primary_disabled", PIECE_MARGINS)


func _update_scrollbar() -> void:
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	var content: float = bar.max_value
	var page: float = bar.page
	var track: float = SCROLL_TRACK_RECT.size.y
	var shown: bool = content > page + 0.5
	_scroll_track.visible = shown
	_scroll_grabber.visible = shown
	if not shown:
		return
	var grab_h: float = roundf(maxf(track * page / content, SCROLL_GRABBER_MIN))
	var t: float = bar.value / maxf(content - page, 1.0)
	_scroll_grabber.size = Vector2(SCROLL_TRACK_RECT.size.x, grab_h)
	_scroll_grabber.position = Vector2(SCROLL_TRACK_RECT.position.x, SCROLL_TRACK_RECT.position.y + roundf((track - grab_h) * clampf(t, 0.0, 1.0)))


# --- cara del vendedor ----------------------------------------------------------------------

func _play_face(tag: StringName) -> void:
	_face_tag = tag
	_face.play(tag, tag == &"idle" or tag == &"browse")
	var deny: bool = tag == &"deny"
	_screen_light.color = SCREEN_LIGHT_DENY_COLOR if deny else SCREEN_LIGHT_COLOR
	_screen_light.enabled = tag != &"exit"


func _on_face_finished(tag: StringName) -> void:
	if tag != _face_tag:
		return
	match tag:
		&"exit":
			# Sigue visible (y `_closing`, hasta el próximo `open`): el [Hub] lo oculta cuando la
			# pantalla ya está en negro, así no se ve el hub entre dos fundidos.
			closed.emit()
		&"buy", &"deny", &"enter":
			_play_face(&"idle")


# Mientras se mueve el foco por la lista mira hacia abajo; sin respuesta especial en curso.
func _start_browse() -> void:
	if _face_tag != &"idle" and _face_tag != &"browse":
		return
	_browse_left = BROWSE_IDLE_TIME
	if _face_tag != &"browse":
		_play_face(&"browse")


# --- entrada --------------------------------------------------------------------------------

func _set_tab(index: int) -> void:
	_cancel_reset()
	if index == _current_tab:
		return
	_current_tab = index
	_selected_id = &""
	_rebuild_rows()
	_refresh()


func _on_tab_pressed(index: int) -> void:
	_set_tab(index)


func _on_row_focused(id: StringName) -> void:
	_selected_id = id
	_update_detail()
	_start_browse()


func _on_row_pressed(id: StringName) -> void:
	_cancel_reset()
	_selected_id = id
	_update_detail()
	if not _buy_button.disabled:
		_buy_button.grab_focus()


# Izquierda / derecha sobre la lista cambian de solapa.
func _on_row_input(event: InputEvent) -> void:
	var step: int = 0
	if event.is_action_pressed("ui_left"):
		step = -1
	elif event.is_action_pressed("ui_right"):
		step = 1
	if step == 0 or _tabs.is_empty():
		return
	get_viewport().set_input_as_handled()
	_set_tab(wrapi(_current_tab + step, 0, _tabs.size()))
	_focus_first()


func _on_buy_pressed() -> void:
	_cancel_reset()
	_try_buy()


func _try_buy() -> bool:
	if _selected_id == &"":
		return false
	var id: StringName = _selected_id
	var reason: StringName = PlayerProgress.get_block_reason(id)
	if PlayerProgress.buy(id):
		_play_face(&"buy")
		_refresh()
		var row: Button = _row_buttons.get(id) as Button
		if row != null and visible:
			row.grab_focus()
		return true
	if reason == PlayerProgress.BLOCK_COINS:
		_play_face(&"deny")
	return false


func _focus_first() -> void:
	if not is_inside_tree():
		return
	for id: StringName in _row_order:
		if PlayerProgress.can_buy(id):
			(_row_buttons[id] as Button).grab_focus()
			return
	if not _row_order.is_empty():
		(_row_buttons[_row_order[0]] as Button).grab_focus()
		return
	_back_button.grab_focus()


# Primer toque: pide confirmación (se cancela sola a los segundos). Segundo toque: borra todo.
func _on_reset_pressed() -> void:
	if not _reset_pending:
		_reset_pending = true
		_reset_token += 1
		_update_reset_button()
		_expire_reset(_reset_token)
		return
	_cancel_reset()
	PlayerProgress.reset_all()
	_selected_id = &""
	_rebuild_rows()
	_refresh()


func _expire_reset(token: int) -> void:
	await get_tree().create_timer(RESET_CONFIRM_TIME).timeout
	if token == _reset_token:
		_cancel_reset()


func _cancel_reset() -> void:
	if not _reset_pending:
		return
	_reset_pending = false
	_reset_token += 1
	_update_reset_button()


func _update_reset_button() -> void:
	_reset_label.text = RESET_CONFIRM_TEXT if _reset_pending else RESET_TEXT
	_reset_label.add_theme_color_override("font_color", RED if _reset_pending else WHITE)
	_center_in(_reset_label, RESET_RECT.size)


func _on_coins_changed(_total: int) -> void:
	_refresh()


# --- piezas ---------------------------------------------------------------------------------

func _label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("shadow_outline_size", 0)
	label.add_theme_constant_override("line_spacing", 0)
	return label


# Ubica un texto con el borde superior de los dígitos en [param top] (el Label deja el ascenso de la
# fuente arriba).
func _place_text(label: Label, x: float, top: float) -> void:
	label.position = Vector2(roundf(x), roundf(top - (_font.get_ascent(FONT_SIZE) - GLYPH_HEIGHT)))


func _center_in(label: Label, area: Vector2) -> void:
	var x: float = floorf((area.x - _text_width(label.text)) * 0.5)
	_place_text(label, x, floorf((area.y - GLYPH_HEIGHT) * 0.5))


func _text_width(text: String) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


func _icon(texture: Texture2D, at: Vector2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = texture
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = at
	icon.size = texture.get_size()
	return icon


func _style(piece: String, margins: Array[int], expand: float = 0.0) -> StyleBoxTexture:
	var key: String = "%s:%s:%s" % [piece, str(margins), expand]
	if _styles.has(key):
		return _styles[key]
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = load(UI_DIR + piece + ".png")
	style.texture_margin_left = margins[0]
	style.texture_margin_top = margins[1]
	style.texture_margin_right = margins[2]
	style.texture_margin_bottom = margins[3]
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.set_expand_margin_all(expand)
	_styles[key] = style
	return style


func _nine_rect(piece: String, margins: Array[int], rect: Rect2) -> NinePatchRect:
	var patch: NinePatchRect = NinePatchRect.new()
	patch.texture = load(UI_DIR + piece + ".png")
	patch.patch_margin_left = margins[0]
	patch.patch_margin_top = margins[1]
	patch.patch_margin_right = margins[2]
	patch.patch_margin_bottom = margins[3]
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.position = rect.position
	patch.size = rect.size
	return patch


func _button(rect: Rect2, piece: String, margins: Array[int]) -> Button:
	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.position = rect.position
	button.size = rect.size
	_set_button_style(button, piece, margins)
	return button


# El mismo fondo en todos los estados; el foco es `mk_focus`, 1 px por fuera.
func _set_button_style(button: Button, piece: String, margins: Array[int]) -> void:
	var style: StyleBoxTexture = _style(piece, margins)
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", _style("mk_focus", PIECE_MARGINS, 1.0))
