class_name Market
extends Control
## Mercado: árbol de talentos donde se gastan las monedas guardadas en mejoras permanentes.
##
## Vive dentro del [TitleMenu] y se abre con [method open]. Arriba hay una solapa por rama (Dash,
## Tanque, etc.); cada rama es una cadena de nodos conectados por líneas, de arriba hacia abajo.
## Tocar un nodo lo selecciona (el detalle de abajo cuenta qué hace, cuánto cuesta y qué falta) y,
## si se puede comprar, lo compra. Las compras las hace [PlayerProgress]; esta pantalla solo las
## pide y se actualiza. Con Escape (acción `ui_cancel`) o el botón VOLVER se cierra y emite
## [signal closed]. Ver `docs/mecanicas/progreso-mercado.md`.

## Color del texto. Solo visual.
const TEXT_COLOR: Color = Color("C8E7EA")
## Color de las monedas y de los nodos comprados (cian de los recogibles). Solo visual.
const COIN_COLOR: Color = Color("63D6C5")
## Color de los nodos que se pueden comprar (naranja de meta). Solo visual.
const BUY_COLOR: Color = Color("FF6B32")
## Color de los nodos que no se pueden comprar todavía. Solo visual.
const DISABLED_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.16)
## Color de los nodos con candado (próximamente). Solo visual.
const LOCKED_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.08)
## Color de las solapas. Solo visual.
const TAB_COLOR: Color = Color("3A9BBF")
## Color del fondo del detalle. Solo visual.
const DETAIL_COLOR: Color = Color(0.2275, 0.6078, 0.749, 0.18)
## Color del texto sobre fondos claros (comprables y comprados). Solo visual.
const BUTTON_TEXT_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 1.0)
## Color del texto de los nodos apagados. Solo visual.
const MUTED_COLOR: Color = Color(0.7843, 0.9059, 0.9176, 0.55)
## Radio de las esquinas (px). Solo visual.
const RADIUS: int = 8
## Tamaño de fuente del título (px). Solo visual.
const TITLE_FONT_SIZE: int = 24
## Tamaño de fuente de las monedas (px). Solo visual.
const COINS_FONT_SIZE: int = 18
## Tamaño de fuente de los nodos (px). Solo visual.
const NODE_FONT_SIZE: int = 15
## Tamaño de fuente de las solapas (px). Solo visual.
const TAB_FONT_SIZE: int = 12
## Alto mínimo de las solapas (px). Estructural.
const TAB_MIN_HEIGHT: float = 36.0
## Margen horizontal interno de las solapas (px). Solo visual.
const TAB_PADDING: float = 3.0
## Tamaño de fuente del detalle (px). Solo visual.
const DETAIL_FONT_SIZE: int = 13
## Alto mínimo de los nodos y botones, pensado para tocarlos con el dedo (px). Estructural.
const BUTTON_MIN_HEIGHT: float = 44.0
## Alto mínimo del detalle, para que el árbol no salte al cambiar de nodo (px). Estructural.
const DETAIL_MIN_HEIGHT: float = 86.0
## Medidas de la línea que une dos nodos (px). Estructural.
const LINK_WIDTH: float = 4.0
const LINK_HEIGHT: float = 14.0
## Separación interna del detalle (px). Solo visual.
const DETAIL_PADDING: int = 10

## Color del botón Reset all y de su confirmación. Solo visual.
const RESET_COLOR: Color = Color("3A9BBF")
const RESET_CONFIRM_COLOR: Color = Color("D83232")
## Ancho del botón Reset all, y del espaciador del otro lado para que las monedas queden
## centradas (px). Estructural.
const RESET_WIDTH: float = 84.0
## Alto del botón Reset all (px). Estructural.
const RESET_HEIGHT: float = 32.0
## Tamaño de fuente del botón Reset all (px). Solo visual.
const RESET_FONT_SIZE: int = 12
## Segundos que espera la confirmación de Reset all antes de cancelarse. Unidad: s.
const RESET_CONFIRM_TIME: float = 3.0

## Textos de la pantalla. Solo visual.
const RESET_TEXT: String = "Reset all"
const RESET_CONFIRM_TEXT: String = "¿Seguro?"
const COINS_TEXT: String = "Monedas: %d"
const NODE_PRICE_TEXT: String = "%s   ·   %d"
const OWNED_TEXT: String = "COMPRADO"
const LOCKED_TEXT: String = "PRÓXIMAMENTE"
const STATE_OWNED: String = "Ya lo tenés."
const STATE_LOCKED: String = "Próximamente: todavía no se puede comprar."
const STATE_REQUIRES: String = "Primero comprá: %s."
const STATE_COINS: String = "Cuesta %d monedas (te faltan %d)."
const STATE_BUY: String = "Cuesta %d monedas. ¡Tocalo para comprarlo!"

## Se cerró el mercado (botón VOLVER o Escape).
signal closed

@onready var _title_label: Label = $Margin/Box/TitleLabel
@onready var _coins_label: Label = $Margin/Box/CoinsRow/CoinsLabel
@onready var _left_spacer: Control = $Margin/Box/CoinsRow/LeftSpacer
@onready var _reset_button: Button = $Margin/Box/CoinsRow/ResetButton
@onready var _tabs_box: HFlowContainer = $Margin/Box/Tabs
@onready var _nodes_box: VBoxContainer = $Margin/Box/Scroll/Nodes
@onready var _detail_panel: PanelContainer = $Margin/Box/DetailPanel
@onready var _detail_label: Label = $Margin/Box/DetailPanel/DetailLabel
@onready var _back_button: Button = $Margin/Box/BackButton

# Ramas en orden de aparición: [{id, label, tab: Button, items: Array[Control]}].
var _branches: Array[Dictionary] = []
# id del nodo -> Button del nodo.
var _node_buttons: Dictionary = {}
# id del nodo -> ColorRect de la línea que lo une con el anterior (si tiene).
var _links: Dictionary = {}
var _current_branch: int = 0
var _selected_id: StringName = &""
# Cuenta de qué confirmación de Reset all sigue vigente (para ignorar temporizadores viejos).
var _reset_token: int = 0
var _reset_pending: bool = false


func _ready() -> void:
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	_coins_label.add_theme_font_size_override("font_size", COINS_FONT_SIZE)
	_coins_label.add_theme_color_override("font_color", COIN_COLOR)
	_detail_label.add_theme_font_size_override("font_size", DETAIL_FONT_SIZE)
	_detail_label.add_theme_color_override("font_color", TEXT_COLOR)
	var detail_style: StyleBoxFlat = StyleBoxFlat.new()
	detail_style.bg_color = DETAIL_COLOR
	detail_style.set_corner_radius_all(RADIUS)
	detail_style.set_content_margin_all(DETAIL_PADDING)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	_detail_panel.custom_minimum_size = Vector2(0.0, DETAIL_MIN_HEIGHT)
	_style_button(_back_button, TEXT_COLOR.darkened(0.55), TEXT_COLOR)
	_back_button.pressed.connect(close)
	_left_spacer.custom_minimum_size = Vector2(RESET_WIDTH, 0.0)
	_reset_button.custom_minimum_size = Vector2(RESET_WIDTH, RESET_HEIGHT)
	_reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_button.focus_exited.connect(_cancel_reset)
	_update_reset_button()
	_build_tree()
	PlayerProgress.coins_changed.connect(_on_coins_changed)
	_refresh()


func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargar el mercado.
	if PlayerProgress.coins_changed.is_connected(_on_coins_changed):
		PlayerProgress.coins_changed.disconnect(_on_coins_changed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Abre el mercado: lo muestra, lo actualiza y deja el foco en el primer nodo que se puede
## comprar de la rama actual (o en VOLVER).
func open() -> void:
	_refresh()
	visible = true
	_focus_first()


## Cierra el mercado y emite [signal closed].
func close() -> void:
	if not visible:
		return
	_cancel_reset()
	visible = false
	closed.emit()


## Muestra la rama [param branch_id] (por ejemplo `dash`). No hace nada si no existe.
func show_branch(branch_id: StringName) -> void:
	for index: int in _branches.size():
		if _branches[index]["id"] == branch_id:
			_current_branch = index
			_refresh()
			return


## Devuelve el botón del nodo [param id] (null si no existe). Sirve para pruebas.
func get_node_button(id: StringName) -> Button:
	return _node_buttons.get(id) as Button


## Devuelve el id de la rama que se está viendo.
func get_current_branch() -> StringName:
	if _branches.is_empty():
		return &""
	return _branches[_current_branch]["id"]


## Devuelve el id del nodo seleccionado (vacío si no hay).
func get_selected_id() -> StringName:
	return _selected_id


# Crea las solapas y los nodos de todas las ramas.
func _build_tree() -> void:
	var by_branch: Dictionary = {}
	for upgrade: UpgradeData in PlayerProgress.config.upgrades:
		if upgrade == null:
			continue
		if not by_branch.has(upgrade.branch):
			by_branch[upgrade.branch] = {
				"id": upgrade.branch,
				"label": upgrade.branch_label if upgrade.branch_label != "" else String(upgrade.branch),
				"upgrades": [],
			}
			_branches.append(by_branch[upgrade.branch])
		(by_branch[upgrade.branch]["upgrades"] as Array).append(upgrade)
	for index: int in _branches.size():
		var branch: Dictionary = _branches[index]
		var tab: Button = Button.new()
		tab.text = branch["label"]
		tab.toggle_mode = false
		_style_tab(tab, index == _current_branch)
		tab.pressed.connect(_on_tab_pressed.bind(index))
		_tabs_box.add_child(tab)
		branch["tab"] = tab
		var items: Array[Control] = []
		var first: bool = true
		for upgrade: UpgradeData in branch["upgrades"]:
			if not first:
				var link: ColorRect = ColorRect.new()
				link.custom_minimum_size = Vector2(LINK_WIDTH, LINK_HEIGHT)
				link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				_nodes_box.add_child(link)
				_links[upgrade.id] = link
				items.append(link)
			first = false
			var button: Button = Button.new()
			button.pressed.connect(_on_node_pressed.bind(upgrade.id))
			button.focus_entered.connect(_select.bind(upgrade.id))
			button.mouse_entered.connect(_select.bind(upgrade.id))
			_nodes_box.add_child(button)
			_node_buttons[upgrade.id] = button
			items.append(button)
		branch["items"] = items


# Actualiza monedas, solapas, nodos y detalle.
func _refresh() -> void:
	_coins_label.text = COINS_TEXT % PlayerProgress.get_coins()
	for index: int in _branches.size():
		var branch: Dictionary = _branches[index]
		var is_current: bool = index == _current_branch
		for item: Control in branch["items"]:
			item.visible = is_current
		_style_tab(branch["tab"] as Button, is_current)
		for upgrade: UpgradeData in branch["upgrades"]:
			_refresh_node(upgrade)
	if _selected_id == &"" or not _is_in_current_branch(_selected_id):
		_selected_id = _first_node_id()
	_update_detail()


func _refresh_node(upgrade: UpgradeData) -> void:
	var button: Button = _node_buttons[upgrade.id] as Button
	var reason: StringName = PlayerProgress.get_block_reason(upgrade.id)
	var fill: Color = DISABLED_COLOR
	var text_color: Color = MUTED_COLOR
	match reason:
		PlayerProgress.BLOCK_OWNED:
			button.text = "%s   ·   %s" % [upgrade.display_name, OWNED_TEXT]
			fill = COIN_COLOR
			text_color = BUTTON_TEXT_COLOR
		PlayerProgress.BLOCK_LOCKED:
			button.text = "%s   ·   %s" % [upgrade.display_name, LOCKED_TEXT]
			fill = LOCKED_COLOR
		PlayerProgress.BLOCK_NONE:
			button.text = NODE_PRICE_TEXT % [upgrade.display_name, upgrade.price]
			fill = BUY_COLOR
			text_color = BUTTON_TEXT_COLOR
		_:
			button.text = NODE_PRICE_TEXT % [upgrade.display_name, upgrade.price]
	_style_button(button, fill, text_color, NODE_FONT_SIZE)
	if _links.has(upgrade.id):
		var link: ColorRect = _links[upgrade.id] as ColorRect
		link.color = COIN_COLOR if PlayerProgress.is_owned(upgrade.requires_id) else DISABLED_COLOR


func _update_detail() -> void:
	var upgrade: UpgradeData = PlayerProgress.get_upgrade(_selected_id)
	if upgrade == null:
		_detail_label.text = ""
		return
	var state: String
	match PlayerProgress.get_block_reason(upgrade.id):
		PlayerProgress.BLOCK_OWNED:
			state = STATE_OWNED
		PlayerProgress.BLOCK_LOCKED:
			state = STATE_LOCKED
		PlayerProgress.BLOCK_REQUIRES:
			var required: UpgradeData = PlayerProgress.get_upgrade(upgrade.requires_id)
			state = STATE_REQUIRES % (required.display_name if required != null else String(upgrade.requires_id))
		PlayerProgress.BLOCK_COINS:
			state = STATE_COINS % [upgrade.price, upgrade.price - PlayerProgress.get_coins()]
		_:
			state = STATE_BUY % upgrade.price
	_detail_label.text = "%s\n%s\n%s" % [upgrade.display_name, upgrade.description, state]


func _select(id: StringName) -> void:
	_selected_id = id
	_update_detail()


func _focus_first() -> void:
	var branch: Dictionary = _branches[_current_branch] if not _branches.is_empty() else {}
	for upgrade: UpgradeData in branch.get("upgrades", []):
		if PlayerProgress.can_buy(upgrade.id):
			_node_buttons[upgrade.id].grab_focus()
			return
	if not _branches.is_empty():
		var items: Array = (_branches[_current_branch]["upgrades"] as Array)
		if not items.is_empty():
			_node_buttons[(items[0] as UpgradeData).id].grab_focus()
			return
	_back_button.grab_focus()


func _first_node_id() -> StringName:
	if _branches.is_empty():
		return &""
	var upgrades: Array = _branches[_current_branch]["upgrades"]
	return (upgrades[0] as UpgradeData).id if not upgrades.is_empty() else &""


func _is_in_current_branch(id: StringName) -> bool:
	if _branches.is_empty():
		return false
	for upgrade: UpgradeData in _branches[_current_branch]["upgrades"]:
		if upgrade.id == id:
			return true
	return false


func _on_tab_pressed(index: int) -> void:
	_cancel_reset()
	_current_branch = index
	_selected_id = &""
	_refresh()


func _on_node_pressed(id: StringName) -> void:
	_cancel_reset()
	_selected_id = id
	PlayerProgress.buy(id)
	_refresh()


# Primer toque: pide confirmación (se cancela solo a los segundos). Segundo toque: borra todo.
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
	_reset_button.text = RESET_CONFIRM_TEXT if _reset_pending else RESET_TEXT
	_style_button(_reset_button, RESET_CONFIRM_COLOR if _reset_pending else RESET_COLOR, BUTTON_TEXT_COLOR if not _reset_pending else TEXT_COLOR, RESET_FONT_SIZE)
	_reset_button.custom_minimum_size = Vector2(RESET_WIDTH, RESET_HEIGHT)


## Devuelve true si Reset all está esperando la confirmación. Sirve para pruebas.
func is_reset_pending() -> bool:
	return _reset_pending


## Devuelve el botón Reset all. Sirve para pruebas.
func get_reset_button() -> Button:
	return _reset_button


func _on_coins_changed(_total: int) -> void:
	_refresh()


# Solapa de una rama: la activa va clara y las demás oscuras.
func _style_tab(tab: Button, active: bool) -> void:
	_style_button(tab, TAB_COLOR if active else TAB_COLOR.darkened(0.55), BUTTON_TEXT_COLOR if active else TEXT_COLOR, TAB_FONT_SIZE)
	tab.custom_minimum_size = Vector2(0.0, TAB_MIN_HEIGHT)
	for style_name: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = tab.get_theme_stylebox(style_name) as StyleBoxFlat
		style.content_margin_left = TAB_PADDING
		style.content_margin_right = TAB_PADDING


func _style_button(button: Button, color: Color, text_color: Color, font_size: int = 14) -> void:
	button.custom_minimum_size = Vector2(0.0, BUTTON_MIN_HEIGHT)
	button.add_theme_font_size_override("font_size", font_size)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, text_color)
	for style_name: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(RADIUS)
		if style_name == "hover":
			style.bg_color = color.lightened(0.12)
		elif style_name == "pressed":
			style.bg_color = color.darkened(0.15)
		elif style_name == "focus":
			style.set_border_width_all(3)
			style.border_color = TEXT_COLOR
		button.add_theme_stylebox_override(style_name, style)
