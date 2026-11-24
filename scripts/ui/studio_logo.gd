class_name StudioLogo
extends Control
## Logo del estudio, antes de la pantalla de inicio: fondo negro, la tele vieja en perspectiva
## (líneas blancas, a 2×), un reflejo que cruza el vidrio y, al terminar, el bebé aparece de golpe en
## la pantalla riéndose y saludando; a la vez aparecen el nombre del estudio y "ESTUDIO" debajo.
## Después funde a negro y emite [signal finished]. Cualquier tecla, botón o toque lo saltea.
##
## La tele es un [SheetSprite] con los tags `empty`, `reflect`, `pop` (una vez) y `wave` (bucle).
## Lo instancia [Main] al abrir el juego. Ver `docs/mecanicas/logo-estudio.md`.

const K = preload("res://scripts/ui/ui_kit.gd")

## Terminó (o se salteó) y la pantalla quedó en negro.
signal finished

## Hoja de la tele (PNG + JSON de Aseprite). Estructural.
const SHEET_PNG: String = "res://assets/sprites/ui/logo/studio_logo.png"
const SHEET_JSON: String = "res://assets/sprites/ui/logo/studio_logo.json"
## Layout (px, en pantalla). Solo visual.
const TV_SCALE: float = 2.0
const TV_TOP: float = 210.0
const TEXT_GAP: float = 16.0
const LINE_STEP: float = 18.0
const BG_COLOR: Color = Color("050609")

## Textos y tiempos (ver [StudioLogoConfig]).
@export var config: StudioLogoConfig

var _tv: SheetSprite
var _text: Control
var _done: bool = false
var _fade_tween: Tween


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(360.0, 640.0)
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_tv = SheetSprite.new()
	_tv.centered = false
	_tv.texture = load(SHEET_PNG) as Texture2D
	_tv.scale = Vector2.ONE * TV_SCALE
	add_child(_tv)
	_tv.load_sheet(SHEET_JSON)
	var tv_size: Vector2 = _tv.region_rect.size * TV_SCALE
	_tv.position = Vector2(floorf((size.x - tv_size.x) * 0.5), TV_TOP)
	_build_text(TV_TOP + tv_size.y + TEXT_GAP)
	_tv.modulate.a = 0.0
	_run()


func _build_text(top: float) -> void:
	_text = Control.new()
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.visible = false
	add_child(_text)
	var lines: Array = [[config.studio_name, K.WHITE], [config.studio_label, K.GREY_BLUE]]
	for i: int in lines.size():
		var label: Label = K.label(lines[i][0], lines[i][1])
		K.place_text(label, floorf((size.x - K.text_width(lines[i][0])) * 0.5), top + i * LINE_STEP)
		_text.add_child(label)


# Secuencia: entrada, reflejo, bebé con el texto, espera y fundido a negro.
func _run() -> void:
	_tv.play(&"empty")
	create_tween().tween_property(_tv, "modulate:a", 1.0, config.fade_in_time)
	if not await _wait(config.fade_in_time + config.empty_hold):
		return
	_tv.play(&"reflect")
	await _tv.finished
	if _done or not await _wait(config.pre_pop_pause):
		return
	_tv.play(&"pop")
	_text.visible = true
	await _tv.finished
	if _done:
		return
	_tv.play(&"wave", true)
	if not await _wait(config.hold_time):
		return
	_finish(config.fade_out_time)


# Espera [param seconds]; devuelve false si mientras tanto se salteó.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return not _done and is_inside_tree()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var pressed: bool = (event is InputEventKey and event.is_pressed() and not event.is_echo()) \
		or (event is InputEventJoypadButton and event.is_pressed()) \
		or (event is InputEventMouseButton and event.is_pressed()) \
		or (event is InputEventScreenTouch and event.is_pressed())
	if pressed:
		get_viewport().set_input_as_handled()
		_finish(config.skip_fade_time)


# Funde todo a negro y emite [signal finished].
func _finish(fade: float) -> void:
	if _done:
		return
	_done = true
	_fade_tween = create_tween().set_parallel()
	_fade_tween.tween_property(_tv, "modulate:a", 0.0, fade)
	_fade_tween.tween_property(_text, "modulate:a", 0.0, fade)
	_fade_tween.chain().tween_callback(finished.emit)
