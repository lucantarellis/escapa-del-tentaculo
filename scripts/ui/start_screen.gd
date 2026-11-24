class_name StartScreen
extends Control
## Pantalla de inicio sobre el hub en vivo: logo "RISE OR DIE" con entrada animada, "TOCÁ PARA
## EMPEZAR" y la versión.
##
## Entrada: las letras (`title_letters`) bajan con un rebote leve; al llegar, los tentáculos de atrás
## y de adelante reproducen `emerge` (salen del humo) y pasan a `idle` en bucle; recién ahí aparece
## el texto, que parpadea. Cualquier tecla, botón o toque durante la entrada la saltea; después,
## empieza: el texto se oculta, todo se funde en 0,5 s y emite [signal started] (el [Hub] le da el
## control al jugador). El fondo es un shader que oscurece, desenfoca y viñetea el hub.
## Ver `docs/mecanicas/pantalla-titulo.md` y `docs/arte/titulo.md`.

const K = preload("res://scripts/ui/ui_kit.gd")
## Arte. Estructural.
const TITLE_DIR: String = "res://assets/sprites/ui/title/"
const BACKDROP_SHADER: Shader = preload("res://shaders/start_backdrop.gdshader")
## Esquina superior izquierda del logo (los tres sprites). Solo visual.
const LOGO_POSITION: Vector2 = Vector2(0.0, 110.0)
## Entrada de las letras: desde qué Y bajan, cuánto se pasan (rebote) y tiempos (s). Solo visual.
const LETTERS_START_Y: float = -220.0
const LETTERS_BOUNCE: float = 10.0
const LETTERS_DROP_TIME: float = 0.5
const LETTERS_SETTLE_TIME: float = 0.2
## "TOCÁ PARA EMPEZAR": centro, color y parpadeo (s visible / s oculto). Solo visual.
const PROMPT_TEXT: String = "TOCÁ PARA EMPEZAR"
const PROMPT_CENTER: Vector2 = Vector2(180.0, 520.0)
const PROMPT_BLINK: float = 0.6
## Versión: borde derecho y centro en alto. Solo visual.
const VERSION_RIGHT: float = 348.0
const VERSION_CENTER_Y: float = 628.0
## Fundido al empezar. Solo visual. Unidad: s.
const FADE_OUT_TIME: float = 0.5

## El jugador tocó para empezar y terminó el fundido.
signal started

var _letters: Sprite2D
var _back: SheetSprite
var _front: SheetSprite
var _prompt: Label
var _intro_tween: Tween
var _ready_to_start: bool = false
var _starting: bool = false
var _blink_time: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(360.0, 640.0)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.size = size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material_: ShaderMaterial = ShaderMaterial.new()
	material_.shader = BACKDROP_SHADER
	backdrop.material = material_
	add_child(backdrop)
	var logo: Node2D = Node2D.new()
	logo.name = "Logo"
	logo.position = LOGO_POSITION
	add_child(logo)
	_back = _make_tentacles("title_tentacles_back")
	logo.add_child(_back)
	_letters = Sprite2D.new()
	_letters.name = "Letters"
	_letters.centered = false
	_letters.texture = load(TITLE_DIR + "title_letters.png")
	_letters.position = Vector2(0.0, LETTERS_START_Y - LOGO_POSITION.y)
	logo.add_child(_letters)
	_front = _make_tentacles("title_tentacles_front")
	logo.add_child(_front)
	_front.finished.connect(_on_emerge_finished)
	_prompt = K.label(PROMPT_TEXT, K.WHITE)
	K.place_text(_prompt, PROMPT_CENTER.x - floorf(K.text_width(PROMPT_TEXT) * 0.5), PROMPT_CENTER.y - floorf(K.GLYPH_HEIGHT * 0.5))
	_prompt.visible = false
	add_child(_prompt)
	var version_text: String = "v" + String(ProjectSettings.get_setting("application/config/version", ""))
	var version: Label = K.label(version_text, K.GREY_BLUE)
	K.place_text(version, VERSION_RIGHT - K.text_width(version_text), VERSION_CENTER_Y - floorf(K.GLYPH_HEIGHT * 0.5))
	add_child(version)
	_play_intro()


func _process(delta: float) -> void:
	if not _ready_to_start or _starting:
		return
	_blink_time += delta
	_prompt.visible = fmod(_blink_time, PROMPT_BLINK * 2.0) < PROMPT_BLINK


func _gui_input(event: InputEvent) -> void:
	_handle_press(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_press(event)


## Devuelve true cuando terminó la entrada y espera el toque. Sirve para pruebas.
func is_waiting() -> bool:
	return _ready_to_start and not _starting


## Saltea la entrada (si sigue) o empieza (si ya terminó). Lo mismo que tocar.
func press() -> void:
	if _starting:
		return
	if not _ready_to_start:
		_skip_intro()
	else:
		_start()


func _handle_press(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventJoypadButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	press()


func _make_tentacles(sheet: String) -> SheetSprite:
	var sprite: SheetSprite = SheetSprite.new()
	sprite.name = sheet
	sprite.centered = false
	sprite.texture = load(TITLE_DIR + sheet + ".png")
	sprite.load_sheet(TITLE_DIR + sheet + ".json")
	sprite.visible = false
	return sprite


# Las letras bajan, se pasan un poco y vuelven; al llegar salen los tentáculos del humo.
func _play_intro() -> void:
	_intro_tween = create_tween()
	_intro_tween.tween_property(_letters, "position:y", LETTERS_BOUNCE, LETTERS_DROP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_intro_tween.tween_property(_letters, "position:y", 0.0, LETTERS_SETTLE_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_intro_tween.tween_callback(_emerge)


func _emerge() -> void:
	for sprite: SheetSprite in [_back, _front]:
		sprite.visible = true
		sprite.play(&"emerge")


func _on_emerge_finished(tag: StringName) -> void:
	if tag == &"emerge":
		_to_idle()


func _to_idle() -> void:
	for sprite: SheetSprite in [_back, _front]:
		sprite.visible = true
		sprite.play(&"idle", true)
	_ready_to_start = true
	_blink_time = 0.0
	_prompt.visible = true


func _skip_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_letters.position.y = 0.0
	_to_idle()


func _start() -> void:
	_starting = true
	_prompt.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME)
	tween.tween_callback(func() -> void: started.emit())
