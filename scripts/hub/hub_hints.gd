class_name HubHints
extends CanvasLayer
## Overlay de ayuda del hub para jugadores nuevos: oscurece el hub con un velo translúcido y muestra
## una pista por vez (caminar, volar, plataforma del ascensor). Va en una capa propia, encima del
## mundo del hub y debajo de su UI (pantalla de inicio, Ajustes, Mercado y fundido), y no bloquea el
## input: el jugador se mueve con total libertad mientras está visible.
##
## Cada pista son piezas de `assets/sprites/ui/hub_hints/` (teclas, flecha abajo, chevrones), textos
## Tiny5 con sombra y, en la plataforma, un recuadro punteado que avanza y un agujero en el velo.
## Textos, tiempos y posiciones salen de [HubHintsConfig]. Las teclas que se muestran salen de un
## único punto ([method _glyphs_for_input]) para poder sumar la versión táctil.
##
## Secuencia ([method play_sequence]): caminar → volar → plataforma. Cada pista se va cuando el
## jugador hace la acción (o al llegar a su tope de tiempo) y, tras `step_pause`, aparece la
## siguiente. Si el jugador se adelanta (vuela antes de caminar), las pistas anteriores se dan por
## cumplidas; si se sube a la plataforma, el overlay se cierra. No toca los flags: el [Hub] marca
## `hub_hints_seen` al lanzar la partida.
## Ver `docs/mecanicas/overlay-hub.md`.

## Capa del overlay: encima del mundo del hub (0) y debajo de su UI (`Ui`, 90). Estructural.
const LAYER: int = 80
## Recurso por defecto si [member config] queda vacío. Estructural.
const CONFIG_PATH: String = "res://resources/configs/hub_hints_config.tres"
## Carpeta del arte. Estructural.
const HINTS_DIR: String = "res://assets/sprites/ui/hub_hints/"
## Tamaño de la pantalla (px). Estructural.
const SCREEN_SIZE: Vector2 = Vector2(360.0, 640.0)
## Tamaño de letra de los textos (Tiny5). Solo visual.
const FONT_SIZE: int = 16
const K = preload("res://scripts/ui/ui_kit.gd")

## Pista en pantalla. `NONE`: ninguna (overlay oculto).
enum Step { NONE, WALK, FLY, PLATFORM }

## Textos, tiempos y posiciones. Si queda vacío se carga [constant CONFIG_PATH].
@export var config: HubHintsConfig

var _root: Control
var _veil: Control
var _groups: Dictionary = {}
var _frames: Dictionary = {}
var _frame_rects: Dictionary = {}
var _group_tweens: Dictionary = {}
var _veil_tween: Tween
var _keys: Dictionary = {}
var _step: Step = Step.NONE
var _transition: int = 0
var _veil_alpha: float = 0.0
var _holes: Array[Rect2] = []
var _hole_open: float = 0.0
var _key_time: float = 0.0
var _key_phase: int = 0
var _dash_time: float = 0.0
var _player: Player
var _elevator: HubElevator
## Secuencia en curso, pausada (hay una pantalla abierta), pistas ya cumplidas, propulsor
## acumulado (s), x del jugador al aparecer la pista de caminar y tiempo de la pista actual (s).
var _running: bool = false
var _suspended: bool = false
var _walk_done: bool = false
var _fly_done: bool = false
var _fly_accum: float = 0.0
var _walk_origin: float = 0.0
var _step_time: float = 0.0


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH) as HubHintsConfig
	if config == null:
		config = HubHintsConfig.new()
	layer = LAYER
	_root = Control.new()
	_root.name = "Root"
	_root.size = SCREEN_SIZE
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_root)
	_veil = _make_canvas("Veil")
	_veil.draw.connect(_draw_veil)
	_build_walk()
	_build_fly()
	_build_platform()
	_root.visible = false
	set_process(false)
	set_physics_process(false)


## Jugador y ascensor del hub, para detectar las acciones. Lo llama [Hub] al armarse.
func setup(player: Player, elevator: HubElevator) -> void:
	_player = player
	_elevator = elevator


## Devuelve la pista en pantalla (`NONE` si no hay ninguna).
func get_step() -> Step:
	return _step


## Muestra [param step] con un fundido de `veil_fade`. Si había otra pista, primero se va con su
## fundido y se espera `step_pause`. Con `NONE` se va todo (pista y velo).
func show_step(step: Step) -> void:
	if step == _step:
		return
	_transition += 1
	var id: int = _transition
	var previous: Step = _step
	_step = step
	if previous != Step.NONE:
		if not _holes.is_empty():
			_fade_veil(_veil_alpha, 0.0)
		_fade_group(previous, 0.0)
		await _wait(config.veil_fade)
		if id != _transition:
			return
		if step != Step.NONE:
			await _wait(config.step_pause)
			if id != _transition:
				return
	if step == Step.NONE:
		_fade_veil(0.0, 0.0)
		await _wait(config.veil_fade)
		if id == _transition:
			_root.visible = false
			set_process(false)
		return
	_root.visible = not _suspended
	set_process(true)
	_holes = _holes_for(step)
	_hole_open = 0.0
	_key_time = 0.0
	_key_phase = 0
	_update_keys()
	_fade_veil(config.veil_alpha, 1.0 if not _holes.is_empty() else 0.0)
	_fade_group(step, 1.0)
	await _wait(config.veil_fade)


## Lo llama [Hub] cuando el jugador toma el control (después del logo, la pantalla de inicio o la
## vuelta de una partida). Con `debug_preview_step` muestra esa pista fija; si el jugador todavía no
## lanzó ninguna partida ([method PlayerProgress.is_hub_hints_seen]), arranca por caminar.
func start() -> void:
	if config.debug_preview_step >= Step.WALK and config.debug_preview_step <= Step.PLATFORM:
		show_step(config.debug_preview_step as Step)
	elif not PlayerProgress.is_hub_hints_seen():
		play_sequence()


## Corre las pistas 1 a 3 desde el principio, sin mirar ni tocar los flags (también lo usa "Ver
## controles" de Ajustes).
func play_sequence() -> void:
	if _player == null or _elevator == null:
		push_warning("HubHints: falta setup(player, elevator).")
		return
	_running = true
	_walk_done = false
	_fly_done = false
	_fly_accum = 0.0
	set_physics_process(true)
	_advance()


## Corta la secuencia y saca el overlay con fundido (lo llama [Hub] al lanzarse el ascensor).
func stop() -> void:
	_running = false
	set_physics_process(false)
	show_step(Step.NONE)


## Devuelve true mientras corre la secuencia de pistas.
func is_running() -> bool:
	return _running


## Con [param suspended] `true` oculta el overlay y pausa la detección (hay una pantalla abierta:
## Ajustes o Mercado); con `false` lo vuelve a mostrar donde estaba.
func set_suspended(suspended: bool) -> void:
	_suspended = suspended
	_root.visible = not suspended and _step != Step.NONE


## Saca todo con fundido (atajo de `show_step(NONE)`).
func hide_all() -> void:
	await show_step(Step.NONE)


func _process(delta: float) -> void:
	_key_time += delta
	var toggle: float = maxf(config.key_toggle_time, 0.05)
	if _key_time >= toggle:
		_key_time = fmod(_key_time, toggle)
		_key_phase += 1
		_update_keys()
	_dash_time += delta
	for frame: Control in _frames.values():
		if frame.is_visible_in_tree():
			frame.queue_redraw()


# Detección de las acciones de la secuencia. Solo cuenta lo que hace el jugador con el control:
# mientras está congelado, guiado por una puerta o montado en el ascensor, la pista de caminar
# vuelve a medir desde donde quedó.
func _physics_process(delta: float) -> void:
	if not _running or _suspended:
		return
	if not _player.is_physics_processing() or _player.is_control_locked() or not _player.is_alive():
		_walk_origin = _player.global_position.x
		return
	# Subirse a la plataforma (o que el ascensor ya se esté armando) cierra el overlay.
	if _elevator.is_player_on() or _elevator.get_phase() != HubElevator.Phase.IDLE:
		_running = false
		set_physics_process(false)
		show_step(Step.NONE)
		return
	_step_time += delta
	if _player.is_thrusting():
		_fly_accum += delta
	# Volar cumple también caminar (se adelantó).
	if _fly_accum >= config.fly_time:
		_fly_done = true
		_walk_done = true
	match _step:
		Step.WALK:
			if absf(_player.global_position.x - _walk_origin) >= config.walk_distance or _timed_out(config.walk_max_time):
				_walk_done = true
		Step.FLY:
			if _timed_out(config.fly_max_time):
				_fly_done = true
		Step.PLATFORM:
			pass
	_advance()


# true si [param max_time] es mayor que 0 y la pista actual ya lleva ese tiempo.
func _timed_out(max_time: float) -> bool:
	return max_time > 0.0 and _step_time >= max_time


# Muestra la primera pista no cumplida (si no es la que ya está).
func _advance() -> void:
	var next: Step = Step.WALK
	if _walk_done:
		next = Step.FLY if not _fly_done else Step.PLATFORM
	if next == _step:
		return
	_step_time = 0.0
	if next == Step.WALK:
		_walk_origin = _player.global_position.x
	show_step(next)


# --- teclas ---------------------------------------------------------------------------------

## Teclas que se muestran en cada pista: hoja y JSON de las teclas y el tag de cada acción. Por ahora
## solo flechas de teclado; la versión táctil se suma acá cuando estén los controles de celular.
func _glyphs_for_input() -> Dictionary:
	return {
		"sheet": HINTS_DIR + "hub_hint_keys",
		&"left": &"left",
		&"right": &"right",
		&"up": &"up",
	}


# Primer cuadro de cada tag: reposo; segundo: pulsada. Las de caminar se alternan una por vez (o
# parpadean juntas, según `walk_keys_alternate`).
func _update_keys() -> void:
	var odd: bool = _key_phase % 2 == 1
	for action: StringName in _keys:
		var pressed: bool = odd
		if action == &"left" and config.walk_keys_alternate:
			pressed = not odd
		_set_key_frame(_keys[action] as Sprite2D, action, pressed)


func _set_key_frame(sprite: Sprite2D, action: StringName, pressed: bool) -> void:
	var glyphs: Dictionary = _glyphs_for_input()
	var sheet: Dictionary = SheetSprite.get_sheet(String(glyphs["sheet"]) + ".json")
	var tag: Vector2i = (sheet["tags"] as Dictionary)[glyphs[action]]
	sprite.region_rect = (sheet["rects"] as Array)[tag.y if pressed else tag.x]


# --- armado ---------------------------------------------------------------------------------

func _build_walk() -> void:
	var group: Control = _make_group(Step.WALK)
	_add_key(group, &"left", config.key_left_position)
	_add_key(group, &"right", config.key_right_position)
	_add_text(group, config.walk_label, config.walk_label_center, HORIZONTAL_ALIGNMENT_CENTER)


func _build_fly() -> void:
	var group: Control = _make_group(Step.FLY)
	_add_key(group, &"up", config.key_up_position)
	_add_sheet(group, "hub_hint_chevrons", &"flow", config.fly_chevrons_position)
	_add_text(group, config.fly_line_1, config.fly_line_1_center, HORIZONTAL_ALIGNMENT_CENTER)
	_add_text(group, config.fly_line_2, config.fly_line_2_center, HORIZONTAL_ALIGNMENT_CENTER)


func _build_platform() -> void:
	var group: Control = _make_group(Step.PLATFORM)
	_add_frames(group, Step.PLATFORM, [config.platform_frame])
	_add_text(group, config.platform_line_1, config.platform_line_1_center, HORIZONTAL_ALIGNMENT_CENTER)
	_add_text(group, config.platform_line_2, config.platform_line_2_center, HORIZONTAL_ALIGNMENT_CENTER)
	_add_sheet(group, "hub_hint_arrow_down", &"bob", config.platform_arrow_position)
	_add_sheet(group, "hub_hint_chevrons", &"flow", config.platform_chevrons_left_position)
	_add_sheet(group, "hub_hint_chevrons", &"flow", config.platform_chevrons_right_position)


func _holes_for(step: Step) -> Array[Rect2]:
	var holes: Array[Rect2] = []
	if step == Step.PLATFORM:
		holes.append(config.platform_hole)
	return holes


func _make_canvas(node_name: String) -> Control:
	var node: Control = Control.new()
	node.name = node_name
	node.size = SCREEN_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(node)
	return node


func _make_group(step: Step) -> Control:
	var group: Control = _make_canvas("Step" + String(Step.keys()[step]).capitalize())
	group.modulate.a = 0.0
	group.visible = false
	_groups[step] = group
	return group


func _add_key(group: Control, action: StringName, at: Vector2) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Key" + String(action).capitalize()
	sprite.texture = load(String(_glyphs_for_input()["sheet"]) + ".png") as Texture2D
	sprite.centered = false
	sprite.region_enabled = true
	sprite.position = at
	group.add_child(sprite)
	_keys[action] = sprite
	_set_key_frame(sprite, action, false)


func _add_sheet(group: Control, sheet: String, tag: StringName, at: Vector2) -> void:
	var sprite: SheetSprite = SheetSprite.new()
	sprite.name = sheet
	sprite.texture = load(HINTS_DIR + sheet + ".png") as Texture2D
	sprite.centered = false
	sprite.position = at
	group.add_child(sprite)
	sprite.load_sheet(HINTS_DIR + sheet + ".json")
	sprite.play(tag, true)


# Texto Tiny5 con sombra de 1 px. [param anchor]: punto de referencia en x (centro, borde izquierdo
# o derecho según [param align]) y borde superior de la caja de texto en y (como en la maqueta).
func _add_text(group: Control, text: String, anchor: Vector2, align: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", K.font())
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", config.text_color)
	label.add_theme_color_override("font_shadow_color", config.text_shadow)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("shadow_outline_size", 0)
	var width: float = K.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var x: float = anchor.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= width
	label.position = Vector2(roundf(x), roundf(anchor.y))
	group.add_child(label)
	return label


# Capa que dibuja los recuadros punteados de una pista.
func _add_frames(group: Control, step: Step, rects: Array[Rect2]) -> void:
	var canvas: Control = Control.new()
	canvas.name = "Frames"
	canvas.size = SCREEN_SIZE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_frames.bind(step))
	group.add_child(canvas)
	_frames[step] = canvas
	_frame_rects[step] = rects


# --- dibujo ---------------------------------------------------------------------------------

# Velo a pantalla completa con los agujeros de la pista: lo de afuera con el alfa del velo, y los
# agujeros con el alfa que les queda mientras se abren.
func _draw_veil() -> void:
	var color: Color = config.veil_color
	color.a = _veil_alpha
	for rect: Rect2 in subtract_rects(Rect2(Vector2.ZERO, SCREEN_SIZE), _holes):
		_veil.draw_rect(rect, color)
	var hole_color: Color = config.veil_color
	hole_color.a = _veil_alpha * (1.0 - _hole_open)
	if hole_color.a > 0.0:
		for hole: Rect2 in _holes:
			_veil.draw_rect(hole, hole_color)


# Recuadros punteados de 1 px: trazo `dash_on`, hueco `dash_off`, recorriendo el borde en sentido
# horario y avanzando `dash_speed` px/s.
func _draw_frames(step: Step) -> void:
	var canvas: Control = _frames[step]
	var period: int = maxi(config.dash_on + config.dash_off, 1)
	var phase: int = floori(_dash_time * config.dash_speed)
	for rect: Rect2 in _frame_rects[step]:
		var points: PackedVector2Array = perimeter(rect)
		for index: int in points.size():
			if posmod(index - phase, period) < config.dash_on:
				canvas.draw_rect(Rect2(points[index], Vector2.ONE), config.text_color)


## Puntos (px) del borde de [param rect] en sentido horario desde la esquina superior izquierda. El
## borde son las filas y columnas de adentro del rectángulo (x de `position.x` a `end.x - 1`).
static func perimeter(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var x0: int = int(rect.position.x)
	var y0: int = int(rect.position.y)
	var x1: int = int(rect.end.x) - 1
	var y1: int = int(rect.end.y) - 1
	for x: int in range(x0, x1 + 1):
		points.append(Vector2(x, y0))
	for y: int in range(y0 + 1, y1 + 1):
		points.append(Vector2(x1, y))
	for x: int in range(x1 - 1, x0 - 1, -1):
		points.append(Vector2(x, y1))
	for y: int in range(y1 - 1, y0, -1):
		points.append(Vector2(x0, y))
	return points


## Divide [param area] en rectángulos que la cubren sin pisarse, salvo [param holes] (que no se
## pisan entre sí). Sirve para dibujar el velo translúcido con agujeros sin superponer alfas.
static func subtract_rects(area: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var ys: Array[float] = [area.position.y, area.end.y]
	for hole: Rect2 in holes:
		for y: float in [hole.position.y, hole.end.y]:
			if y > area.position.y and y < area.end.y and not ys.has(y):
				ys.append(y)
	ys.sort()
	var result: Array[Rect2] = []
	for band: int in ys.size() - 1:
		var top: float = ys[band]
		var bottom: float = ys[band + 1]
		var spans: Array[Rect2] = []
		for hole: Rect2 in holes:
			if hole.position.y <= top and hole.end.y >= bottom:
				spans.append(hole)
		spans.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		var x: float = area.position.x
		for span: Rect2 in spans:
			if span.position.x > x:
				result.append(Rect2(x, top, span.position.x - x, bottom - top))
			x = maxf(x, span.end.x)
		if x < area.end.x:
			result.append(Rect2(x, top, area.end.x - x, bottom - top))
	return result


# --- fundidos -------------------------------------------------------------------------------

func _fade_group(step: Step, alpha: float) -> Tween:
	var group: Control = _groups[step]
	var previous: Tween = _group_tweens.get(step) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	if alpha > 0.0:
		group.visible = true
	var tween: Tween = create_tween()
	_group_tweens[step] = tween
	tween.tween_property(group, "modulate:a", alpha, maxf(config.veil_fade, 0.01))
	if alpha <= 0.0:
		tween.tween_callback(group.hide)
	return tween


func _fade_veil(alpha: float, hole_open: float) -> Tween:
	if _veil_tween != null and _veil_tween.is_valid():
		_veil_tween.kill()
	var tween: Tween = create_tween().set_parallel(true)
	_veil_tween = tween
	tween.tween_method(_set_veil_alpha, _veil_alpha, alpha, maxf(config.veil_fade, 0.01))
	tween.tween_method(_set_hole_open, _hole_open, hole_open, maxf(config.veil_fade, 0.01))
	return tween


# Espera con un timer (los tweens cancelados no avisan que terminaron).
func _wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds, 0.01)).timeout


func _set_veil_alpha(value: float) -> void:
	_veil_alpha = value
	_veil.queue_redraw()


func _set_hole_open(value: float) -> void:
	_hole_open = value
	_veil.queue_redraw()
