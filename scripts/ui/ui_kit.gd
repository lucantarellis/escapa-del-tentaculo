class_name UiKit
extends RefCounted
## Piezas de UI compartidas por las pantallas completas (Ajustes, Créditos): paleta, texto Tiny5
## 16 px con sombra, íconos, 9-slice y botones con `mk_focus`. Mismo criterio que [Market]
## (ver `docs/arte/mercado.md` y `docs/arte/ajustes.md`).

const MARKET_DIR: String = "res://assets/sprites/ui/market/"
const SETTINGS_DIR: String = "res://assets/sprites/ui/settings/"
const FONT_PATH: String = "res://assets/fonts/Tiny5-Regular.ttf"

## Colores (paleta). Solo visual.
const BG: Color = Color("0E1632")
const WHITE: Color = Color("E7EFF2")
const PALE: Color = Color("C8E7EA")
const CYAN: Color = Color("89D9EB")
const TEAL: Color = Color("63D6C5")
const BLUE: Color = Color("3A9BBF")
const GREY_BLUE: Color = Color("6689B7")
const AMBER: Color = Color("FCD51D")
const RED: Color = Color("F62A19")
const SHADOW: Color = Color("050609")

## Tamaño de fuente y alto de los dígitos a ese tamaño (para ubicar el borde superior). Solo visual.
const FONT_SIZE: int = 16
const GLYPH_HEIGHT: float = 10.0
## Márgenes 9-slice (izquierda, arriba, derecha, abajo). Solo visual.
const PANEL_MARGINS: Array[int] = [6, 6, 6, 6]
const PIECE_MARGINS: Array[int] = [3, 3, 3, 3]

static var _font: Font
static var _styles: Dictionary = {}


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font
	return _font


static func label(text: String, color: Color) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", FONT_SIZE)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", SHADOW)
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.add_theme_constant_override("shadow_outline_size", 0)
	return node


## Ubica [param node] con el borde superior de los dígitos en [param top].
static func place_text(node: Label, x: float, top: float) -> void:
	node.position = Vector2(roundf(x), roundf(top - (font().get_ascent(FONT_SIZE) - GLYPH_HEIGHT)))


## Centra [param node] (en los dos ejes) dentro de un área de [param area] que empieza en
## [param origin].
static func center_in(node: Label, area: Vector2, origin: Vector2 = Vector2.ZERO) -> void:
	place_text(node, origin.x + floorf((area.x - text_width(node.text)) * 0.5), origin.y + floorf((area.y - GLYPH_HEIGHT) * 0.5))


static func text_width(text: String) -> float:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


static func icon(path: String, at: Vector2) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.texture = load(path) as Texture2D
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = at
	node.size = node.texture.get_size()
	return node


static func style(path: String, margins: Array[int], expand: float = 0.0) -> StyleBoxTexture:
	var key: String = "%s:%s:%s" % [path, str(margins), expand]
	if _styles.has(key):
		return _styles[key]
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load(path)
	box.texture_margin_left = margins[0]
	box.texture_margin_top = margins[1]
	box.texture_margin_right = margins[2]
	box.texture_margin_bottom = margins[3]
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.set_expand_margin_all(expand)
	_styles[key] = box
	return box


static func nine_rect(path: String, margins: Array[int], rect: Rect2) -> NinePatchRect:
	var patch: NinePatchRect = NinePatchRect.new()
	patch.texture = load(path)
	patch.patch_margin_left = margins[0]
	patch.patch_margin_top = margins[1]
	patch.patch_margin_right = margins[2]
	patch.patch_margin_bottom = margins[3]
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.position = rect.position
	patch.size = rect.size
	return patch


## Botón con el mismo fondo en todos los estados y `mk_focus` 1 px por fuera.
static func button(rect: Rect2, path: String, margins: Array[int]) -> Button:
	var node: Button = Button.new()
	node.focus_mode = Control.FOCUS_ALL
	node.position = rect.position
	node.size = rect.size
	set_button_style(node, path, margins)
	return node


static func set_button_style(node: Button, path: String, margins: Array[int]) -> void:
	var box: StyleBoxTexture = style(path, margins)
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		node.add_theme_stylebox_override(state, box)
	node.add_theme_stylebox_override("focus", style(MARKET_DIR + "mk_focus.png", PIECE_MARGINS, 1.0))


## Subencabezado de sección: ícono en x 1, título en x 22 y una línea hasta [param line_end_x].
static func header(icon_path: String, title: String, at: Vector2, line_end_x: float) -> Control:
	var node: Control = Control.new()
	node.position = at
	node.size = Vector2(line_end_x, 20.0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image: TextureRect = icon(icon_path, Vector2(1.0, 2.0))
	node.add_child(image)
	var text: Label = label(title, TEAL)
	place_text(text, 22.0, 5.0)
	node.add_child(text)
	var line_x: float = 22.0 + text_width(title) + 4.0
	var line: ColorRect = ColorRect.new()
	line.color = BLUE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.position = Vector2(line_x, 10.0)
	line.size = Vector2(maxf(line_end_x - line_x, 0.0), 1.0)
	node.add_child(line)
	return node
