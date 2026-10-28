class_name TitleMenu
extends Control
## Menú de título: nombre del juego, un botón grande de jugar y un botón para abrir el mercado.
##
## Se dibuja encima del nivel (que ya está armado y quieto). Al pulsar el botón se
## deshabilita, espera [member TitleConfig.fade_delay], se disuelve hasta quedar transparente
## en [member TitleConfig.fade_duration] y emite [signal faded_out]. El menú NO arranca la
## partida ni se elimina solo: eso lo hace quien lo instancia (ver [Main]).
## Ver `docs/mecanicas/pantalla-titulo.md`.

## Color del título. Solo visual.
const TITLE_COLOR: Color = Color("C8E7EA")
## Color del contorno del título. Solo visual.
const OUTLINE_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 1.0)
## Grosor del contorno del título (px). Solo visual.
const OUTLINE_SIZE: int = 8
## Tamaño de fuente del título (px). Solo visual.
const TITLE_FONT_SIZE: int = 30
## Tamaño de fuente del botón (px). Solo visual.
const BUTTON_FONT_SIZE: int = 24
## Tamaño mínimo del botón (px). Estructural: pensado para poder tocarlo con el dedo.
const BUTTON_MIN_SIZE: Vector2 = Vector2(220, 72)
## Color del botón (naranja de meta). Solo visual.
const BUTTON_COLOR: Color = Color("FF6B32")
## Color del texto del botón. Solo visual.
const BUTTON_TEXT_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 1.0)
## Radio de las esquinas del botón (px). Solo visual.
const BUTTON_RADIUS: int = 8
## Color del botón del mercado (azul frío de las plataformas). Solo visual.
const MARKET_BUTTON_COLOR: Color = Color("3A9BBF")
## Tamaño de fuente del botón del mercado (px). Solo visual.
const MARKET_FONT_SIZE: int = 18
## Tamaño mínimo del botón del mercado (px). Estructural: pensado para poder tocarlo con el dedo.
const MARKET_BUTTON_MIN_SIZE: Vector2 = Vector2(220, 52)

## El jugador pulsó el botón (una sola vez: el botón queda deshabilitado).
signal play_pressed
## Terminó el fundido: el menú es totalmente transparente y ya se puede eliminar.
signal faded_out

## Configuración de textos y tiempos.
@export var config: TitleConfig

@onready var _title_label: Label = $Center/Box/TitleLabel
@onready var _play_button: Button = $Center/Box/PlayButton
@onready var _market_button: Button = $Center/Box/MarketButton
@onready var _market: Market = $Market


func _ready() -> void:
	if config == null:
		config = TitleConfig.new()
	_title_label.text = config.title_text
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	_title_label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	_play_button.text = config.play_text
	_play_button.custom_minimum_size = BUTTON_MIN_SIZE
	_play_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_play_button.add_theme_color_override(color_name, BUTTON_TEXT_COLOR)
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		_play_button.add_theme_stylebox_override(style_name, _make_button_style(style_name))
	_play_button.pressed.connect(_on_play_button_pressed)
	_setup_market_button()
	# El foco permite activar el botón con Enter o Espacio (acción `ui_accept`).
	_play_button.grab_focus()


# Botón secundario que abre el mercado (ver [Market]). Se oculta con el progreso apagado.
func _setup_market_button() -> void:
	_market_button.visible = PlayerProgress.is_enabled()
	_market_button.custom_minimum_size = MARKET_BUTTON_MIN_SIZE
	_market_button.add_theme_font_size_override("font_size", MARKET_FONT_SIZE)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_market_button.add_theme_color_override(color_name, BUTTON_TEXT_COLOR)
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		_market_button.add_theme_stylebox_override(style_name, _make_button_style(style_name, MARKET_BUTTON_COLOR))
	_market_button.pressed.connect(_market.open)
	_market.closed.connect(_on_market_closed)


func _on_market_closed() -> void:
	_market_button.grab_focus()


func _make_button_style(style_name: String, color: Color = BUTTON_COLOR) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(BUTTON_RADIUS)
	if style_name == "hover":
		style.bg_color = color.lightened(0.15)
	elif style_name == "pressed":
		style.bg_color = color.darkened(0.15)
	elif style_name == "focus":
		style.set_border_width_all(3)
		style.border_color = TITLE_COLOR
	return style


func _on_play_button_pressed() -> void:
	_play_button.disabled = true
	_market_button.disabled = true
	play_pressed.emit()
	var tween: Tween = create_tween()
	tween.tween_interval(config.fade_delay)
	tween.tween_property(self, "modulate:a", 0.0, config.fade_duration)
	tween.finished.connect(func() -> void: faded_out.emit())
