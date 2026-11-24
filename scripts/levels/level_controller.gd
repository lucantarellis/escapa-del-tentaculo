class_name LevelController
extends Node2D
## Script raíz del nivel jugable (`Level.tscn`, armado por segmentos).
##
## Usa su hijo [LevelBuilder] para armar el nivel, ubicar al jugador, fijar el tope de la cámara
## y encontrar la puerta.
## Conecta lo que pasa en el nivel con el [code]GameManager[/code] (autoload) y reacciona a
## su estado: en victoria llama a [method Player.win], detiene el scroll y muestra el mensaje;
## en derrota detiene el scroll y muestra el mensaje según la causa. El reinicio (R) lo
## maneja el propio game manager. Ver `docs/mecanicas/game-manager.md`.
##
## Con [member autostart] en `false` el nivel espera a [method play_intro] (intro de la escotilla: golpes
## de cámara con gas antes de empezar) o a [method begin] (empezar directo). Ver
## `docs/mecanicas/intro-escotilla.md`.

## Se emite cuando el jugador cruza el borde inferior de un tier (ver [SegmentTier]).
## [param tier_index] es el índice en `LevelConfig.tiers`.
signal tier_entered(tier_index: int)

## Texto que se agrega al mensaje de fin cuando la partida supera el récord. Solo visual.
const NEW_RECORD_TEXT: String = "NUEVO RÉCORD"

## Texto de derrota por causa de muerte. Solo visual. Las causas no listadas usan
## [constant DEFAULT_DEATH_TEXT].
const DEATH_TEXTS: Dictionary = {
	&"tentacle": "CAPTURADO — pulsá R para reiniciar",
	&"fell": "CAPTURADO — pulsá R para reiniciar",
	&"obstacle": "GOLPEADO — pulsá R para reiniciar",
	&"pulse": "GOLPEADO — pulsá R para reiniciar",
	&"lethal": "GOLPEADO — pulsá R para reiniciar",
	&"trap": "GOLPEADO — pulsá R para reiniciar",
	&"debris": "GOLPEADO — pulsá R para reiniciar",
	&"meteor": "GOLPEADO — pulsá R para reiniciar",
	&"comet": "GOLPEADO — pulsá R para reiniciar",
	&"debris_field": "GOLPEADO — pulsá R para reiniciar",
	&"laser": "GOLPEADO — pulsá R para reiniciar",
	&"bile": "GOLPEADO — pulsá R para reiniciar",
	&"antibody": "GOLPEADO — pulsá R para reiniciar",
	&"minor_tentacle": "CAPTURADO — pulsá R para reiniciar",
}
## Texto para una causa de muerte desconocida. Solo visual.
const DEFAULT_DEATH_TEXT: String = "PERDISTE — pulsá R para reiniciar"
## Línea que se agrega al mensaje de fin cuando el nivel lo instancia [Main] (ver
## [member show_menu_hint]). Solo visual.
const MENU_HINT_TEXT: String = "\nEscape: volver al menú"
## Texto de victoria. Solo visual.
const WIN_TEXT: String = "ESCAPASTE — pulsá R para reiniciar"
## Aviso al completar una fase por primera vez (se ve unos segundos y se apaga). Solo visual.
const PHASE_NOTICE_TEXT: String = "¡FASE %d COMPLETADA!\nGanaste una compra gratis"
## Segundos que se ve el aviso de fase completada. Unidad: s. Solo visual.
const NOTICE_TIME: float = 3.0
## Duración del fundido del aviso. Unidad: s. Solo visual.
const NOTICE_FADE: float = 0.6
## Distancia del aviso al borde superior de la pantalla. Unidad: px. Solo visual.
const NOTICE_TOP: float = 70.0
## Tamaño de fuente del aviso. Unidad: px. Solo visual.
const NOTICE_FONT_SIZE: int = 16
## Color del aviso (celeste de los detalles de la paleta). Solo visual.
const NOTICE_COLOR: Color = Color("C8E7EA")
## Color del contorno del aviso. Solo visual.
const NOTICE_OUTLINE_COLOR: Color = Color(0.0196, 0.0235, 0.0353, 1.0)

## Si es `true` (por defecto) la partida empieza sola al armarse el nivel. Si es `false` el nivel se
## arma pero queda en pausa hasta que alguien llame a [method begin] (lo usa [Main] para mostrar
## el título con el nivel de fondo). Debe asignarse antes de agregar el nodo al árbol.
@export var autostart: bool = true
## Si es `true`, el mensaje de fin avisa que con Escape se vuelve al menú. Lo activa [Main] (el único
## que maneja esa tecla); con `Level.tscn` solo (F6) queda en `false`. Debe asignarse antes de
## agregar el nodo al árbol.
@export var show_menu_hint: bool = false
## Parámetros de la intro de la escotilla (ver [method play_intro]). Se comparte con el [Hatch].
@export var intro_config: IntroConfig

@onready var _camera: ScrollCamera = $ScrollCamera
@onready var _player: Player = $Player
@onready var _tentacle: Tentacle = $Tentacle
@onready var _builder: LevelBuilder = $LevelBuilder
@onready var _message_label: Label = $CaughtLayer/CaughtLabel
@onready var _debug_overlay: Node = get_node_or_null("DebugOverlay")
@onready var _hud: Hud = get_node_or_null("Hud") as Hud
@onready var _hatch: Hatch = get_node_or_null("Hatch") as Hatch
@onready var _lighting: LevelLighting = get_node_or_null("Lighting") as LevelLighting
@onready var _background: LevelBackground = get_node_or_null("Background") as LevelBackground

var _run_seed: int = 0
var _started: bool = false
var _intro_started: bool = false
var _intro_director: IntroDirector
## Inicio de cada tier (de [method LevelBuilder.get_tier_starts]) y el próximo a cruzar.
var _tier_starts: Array[Dictionary] = []
var _next_tier: int = 0
var _current_tier: int = -1
## Tiers cuyo fondo ya se aplicó antes de entrar (ver [method _on_window_broken]).
var _background_preapplied: Dictionary = {}
# Aviso de fase completada (se arma por código en la capa de mensajes).
var _notice_label: Label
var _notice_tween: Tween


func _ready() -> void:
	_message_label.visible = false
	_make_notice_label()
	PlayerProgress.phase_completed.connect(_on_phase_completed)
	var run_seed: int = 0
	run_seed = _builder.build()
	_player.reset(_builder.get_player_spawn())
	_camera.set_stop_y(_builder.get_camera_stop_y())
	# Un final con abertura en el techo deja salir al jugador por arriba de la pantalla.
	var end_segment: LevelSegment = _builder.get_end_segment()
	_camera.set_top_wall_enabled(end_segment == null or not end_segment.opens_top)
	if _hatch != null:
		_hatch.global_position = _builder.get_hatch_position()
	var door: Door = _builder.get_goal_door()
	if door == null:
		push_error("LevelController: el nivel no tiene puerta de meta.")
	else:
		door.player_reached.connect(GameManager.notify_goal_reached)
	_player.died.connect(GameManager.notify_player_died)
	if _hud != null and door != null:
		# El progreso va de la Y del jugador en el spawn a la Y de la puerta.
		_hud.set_progress_range(_player.global_position.y, door.global_position.y)
	_tier_starts = _builder.get_tier_starts()
	if _hud != null:
		# Sin marca para el primer tier: el inicio ya es parte de él.
		var ys: PackedFloat32Array = PackedFloat32Array()
		for i: int in range(1, _tier_starts.size()):
			ys.append(_tier_starts[i]["y"])
		_hud.set_tier_marks(ys)
		_hud.set_record(RunRecords.get_best_progress())
	for window: Node in get_tree().get_nodes_in_group(&"window_breach"):
		(window as WindowBreach).broken.connect(_on_window_broken)
	GameManager.state_changed.connect(_on_state_changed)
	_run_seed = run_seed
	# El segmento de inicio es parte del primer tier: su escenario rige desde el arranque.
	if not _tier_starts.is_empty():
		_enter_tier(int(_tier_starts[0]["tier"]))
		_next_tier = 1
	if _hatch != null:
		_hatch.config = intro_config
	if autostart:
		# Sin intro: la escotilla ya está rota y todo activo desde el primer frame.
		if _hatch != null:
			_hatch.set_broken(true)
		begin()
	else:
		# Antes de la intro: escotilla cerrada, sin tentáculo y con el jugador "detrás" de ella.
		_tentacle.set_active(false)
		_player.set_frozen(true)
		if _hatch != null:
			_hatch.set_broken(false)
			# Con intro la nave arranca con la luz encendida: los golpes la desestabilizan y la
			# ruptura la apaga.
			if _lighting != null and intro_config != null:
				_lighting.set_lit(intro_config.intro_ambient_color)
		# Nivel quieto: sin `_process`, física, timers ni tweens. El overlay F3 sigue activo.
		process_mode = Node.PROCESS_MODE_DISABLED
		if _debug_overlay != null:
			_debug_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		# El HUD no se muestra en el título: aparece en `begin()`.
		if _hud != null:
			_hud.visible = false


## Empieza la partida ya, sin intro: reanuda el nivel si estaba en pausa (ver [member autostart]),
## deja al tentáculo activo y al jugador libre, y avisa al game manager. Llamarlo más de una vez no
## hace nada.
func begin() -> void:
	_begin(true)


# Empieza la partida. [param activate_tentacle] `false` deja al tentáculo inactivo: lo usa la intro,
# donde el director lo hace entrar más tarde.
func _begin(activate_tentacle: bool) -> void:
	if _started:
		return
	_started = true
	if activate_tentacle:
		_tentacle.set_active(true)
	_player.set_frozen(false)
	process_mode = Node.PROCESS_MODE_INHERIT
	if _debug_overlay != null:
		_debug_overlay.process_mode = Node.PROCESS_MODE_INHERIT
	if _hud != null:
		_hud.visible = true
	GameManager.start_run(_run_seed)


## Reproduce la intro de la escotilla: el nivel sigue en pausa y solo se mueven la escotilla, el gas
## y la vibración de cámara. Tras los golpes la escotilla se rompe, el jugador sale disparado y en
## ese instante empieza la partida; el tentáculo entra un rato después. Sin escotilla o sin
## [member intro_config] empieza directo. Ignorado si la partida o la intro ya empezaron. El
## `GameManager` sigue en `READY` hasta [method begin], así que R no hace nada mientras dura.
func play_intro() -> void:
	if _started or _intro_started:
		return
	if _hatch == null or intro_config == null:
		begin()
		return
	_intro_started = true
	_intro_director = IntroDirector.new()
	_intro_director.config = intro_config
	add_child(_intro_director)
	_intro_director.hit.connect(_on_intro_hit)
	_intro_director.broken.connect(_on_intro_broken)
	_intro_director.play(_hatch, _camera, _player, _tentacle)


# Cada golpe baja un poco la luz de base y la hace titilar (más fuerte cuanto más golpes) hasta el
# golpe siguiente o, en el último, hasta la ruptura.
func _on_intro_hit(index: int) -> void:
	if _lighting == null:
		return
	var cfg: IntroConfig = intro_config
	var dark: Color = LevelLighting.get_config().ambient_color
	var drop: float = minf(cfg.light_drop_per_hit * float(index + 1), 1.0)
	_lighting.fade_base(cfg.intro_ambient_color.lerp(dark, drop), cfg.light_drop_time)
	var depth: float = minf(cfg.flicker_depth * pow(cfg.hit_escalation, float(index)), 1.0)
	var last: bool = index >= cfg.hit_count - 1
	var duration: float = cfg.pre_break_pause if last else cfg.hit_interval
	_lighting.flicker(depth, duration, cfg.flicker_step_min, cfg.flicker_step_max)


# La ruptura apaga la luz de golpe y empieza la partida. El tentáculo sigue inactivo: lo hace entrar
# el director.
func _on_intro_broken() -> void:
	if _lighting != null:
		_lighting.power_off(intro_config.power_off_time)
	_begin(false)


func _physics_process(_delta: float) -> void:
	if not _started or GameManager.get_state() != GameManager.State.PLAYING:
		return
	# El jugador entra a un tier al cruzar (subiendo) el borde inferior de su primer segmento.
	while _next_tier < _tier_starts.size() and _player.global_position.y <= float(_tier_starts[_next_tier]["y"]):
		_enter_tier(int(_tier_starts[_next_tier]["tier"]))
		# Cruzar al tier siguiente completa la fase anterior (la 1ª es la nave, la 2ª el espacio).
		PlayerProgress.complete_phase(_next_tier)
		_next_tier += 1


## Devuelve el índice (en `LevelConfig.tiers`) del tier en el que está el jugador; -1 si todavía
## no entró a ninguno (segmento de inicio) o no hay tiers.
func get_current_tier() -> int:
	return _current_tier


func _apply_tier_background(tier: SegmentTier, fade: float) -> void:
	if _background != null and tier.background_color.a > 0.0:
		_background.apply_style(tier.background_color, tier.background_stars, fade, tier.background_vignette, tier.background_ship)
	if _lighting != null:
		_lighting.set_dark(tier.dark_ambient, fade)


# El ventanal de la salida de la nave se rompió: del otro lado ya es el tier siguiente (el espacio),
# así que su fondo entra ahora, sin esperar a que el jugador cruce el borde del tier.
func _on_window_broken() -> void:
	if _next_tier >= _tier_starts.size():
		return
	var tier_index: int = int(_tier_starts[_next_tier]["tier"])
	var tier: SegmentTier = _builder.config.tiers[tier_index]
	if tier == null:
		return
	_apply_tier_background(tier, tier.background_fade)
	_background_preapplied[tier_index] = true


# Aplica el escenario del tier: perseguidor y física del jugador. El tileset de paredes ya lo
# puso el LevelBuilder al armar.
func _enter_tier(tier_index: int) -> void:
	var first: bool = _current_tier < 0
	_current_tier = tier_index
	var tier: SegmentTier = _builder.config.tiers[tier_index]
	if tier != null and not _background_preapplied.has(tier_index):
		_apply_tier_background(tier, 0.0 if first else tier.background_fade)
	if tier != null:
		_tentacle.apply_pursuer(tier.pursuer_config, tier.pursuer_color, tier.pursuer_reset_position)
		if tier.pursuer_delay > 0.0 and not first:
			_delay_pursuer(tier.pursuer_delay)
		_player.set_physics_scales(tier.gravity_scale, tier.air_drag_scale, tier.counter_thrust_scale)
	tier_entered.emit(tier_index)



func _exit_tree() -> void:
	# El autoload sobrevive a la escena: hay que soltar la conexión al descargarla.
	if GameManager.state_changed.is_connected(_on_state_changed):
		GameManager.state_changed.disconnect(_on_state_changed)
	if PlayerProgress.phase_completed.is_connected(_on_phase_completed):
		PlayerProgress.phase_completed.disconnect(_on_phase_completed)


func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.WON:
			_player.win()
			_camera.set_scrolling(false)
			_tentacle.set_rising(false)
			# Llegar a la puerta completa la última fase.
			PlayerProgress.complete_phase(maxi(_tier_starts.size(), 1))
			_show_message(WIN_TEXT + _record_suffix(1.0) + _menu_hint())
		GameManager.State.LOST:
			_camera.set_scrolling(false)
			_tentacle.set_rising(false)
			var progress: float = _hud.get_progress() if _hud != null else 0.0
			_show_message(DEATH_TEXTS.get(GameManager.get_last_death_cause(), DEFAULT_DEATH_TEXT) + _record_suffix(progress) + _menu_hint())


# Arma el aviso de fase completada: un Label centrado arriba, escondido hasta que haga falta.
func _make_notice_label() -> void:
	_notice_label = Label.new()
	_notice_label.visible = false
	_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_notice_label.offset_top = NOTICE_TOP
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.add_theme_font_size_override("font_size", NOTICE_FONT_SIZE)
	_notice_label.add_theme_color_override("font_color", NOTICE_COLOR)
	_notice_label.add_theme_color_override("font_outline_color", NOTICE_OUTLINE_COLOR)
	_notice_label.add_theme_constant_override("outline_size", 6)
	_message_label.get_parent().add_child(_notice_label)


# Se completó una fase por primera vez: muestra el aviso unos segundos y lo disuelve.
func _on_phase_completed(phase: int) -> void:
	_notice_label.text = PHASE_NOTICE_TEXT % phase
	_notice_label.modulate.a = 1.0
	_notice_label.visible = true
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_TIME)
	_notice_tween.tween_property(_notice_label, "modulate:a", 0.0, NOTICE_FADE)
	_notice_tween.tween_callback(_notice_label.hide)


func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = true


# Línea extra del mensaje de fin ("" si el nivel no la muestra).
func _menu_hint() -> String:
	return MENU_HINT_TEXT if show_menu_hint else ""


# Registra el progreso de la partida en los récords y devuelve el texto a agregar al mensaje de fin
# ("" si no es récord).
func _record_suffix(progress: float) -> String:
	if RunRecords.submit_progress(progress):
		if _hud != null:
			_hud.set_record(progress)
		return "\n" + NEW_RECORD_TEXT
	return ""


# Saca de escena al perseguidor [param delay] s (vigilando la caída) y lo vuelve a activar desde
# su distancia inicial bajo la pantalla.
func _delay_pursuer(delay: float) -> void:
	_tentacle.set_active(false)
	_tentacle.set_fall_watch(true)
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or GameManager.get_state() != GameManager.State.PLAYING:
		return
	_tentacle.set_fall_watch(false)
	_tentacle.set_active(true)
