class_name Tentacle
extends Node2D
## Amenaza anclada al borde inferior de la cámara: tocarla o caer bajo la pantalla mata.
##
## Sigue a la [ScrollCamera] en `_physics_process`. El origen del nodo es el borde superior
## (sin ondular) del tentáculo; el cuerpo se extiende hacia abajo hasta pasar el borde de
## la pantalla. Ver `docs/mecanicas/tentaculo.md`.

## Se emite cuando el tentáculo atrapa al jugador. [param cause] es `&"tentacle"` (contacto)
## o `&"fell"` (cayó bajo el borde inferior de la pantalla).
signal player_caught(cause: StringName)

## Rojo de la paleta. Solo visual.
const COLOR_BODY: Color = Color("#D83232")
## Desfase de la onda entre puntos contiguos del borde superior. Solo visual. Unidad: rad.
const WOBBLE_PHASE_PER_SEGMENT: float = 0.8
## Cuánto se extiende el cuerpo y la zona letal por debajo del borde inferior de la
## pantalla, para que nunca quede un hueco. Estructural. Unidad: px.
const BODY_PADDING: float = 96.0

## Parámetros de gameplay. Si queda vacío se usan los valores por defecto de
## [TentacleConfig].
@export var config: TentacleConfig
## Cámara a la que se ancla el tentáculo.
@export var camera: ScrollCamera

@onready var _body: Polygon2D = $BodyPolygon
@onready var _kill_zone: Area2D = $KillZone
@onready var _kill_shape: CollisionShape2D = $KillZone/CollisionShape2D

var _extra_rise: float = 0.0
## false congela el ascenso extra y el del final del nivel (ver [method set_rising]).
var _rising: bool = true
var _time: float = 0.0
var _player: Player
## false mientras el tentáculo está oculto e inofensivo (ver [method set_active]).
var _active: bool = true
## true = con el tentáculo inactivo, igual vigila que el jugador no caiga bajo la pantalla.
var _watch_fall: bool = false
## Desfase vertical de la entrada (ver [method enter]): positivo = más abajo. Unidad: px.
var _entry_offset: float = 0.0
var _entry_tween: Tween


func _ready() -> void:
	if config == null:
		config = TentacleConfig.new()
	if camera == null:
		push_error("Tentacle: falta asignar 'camera'.")
		set_physics_process(false)
		set_process(false)
		return
	_kill_shape.shape = RectangleShape2D.new()
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	_follow_camera()
	_update_kill_zone()
	_update_body_polygon()


func _physics_process(delta: float) -> void:
	if not _active:
		# Solo la red de seguridad de caída (ver [method set_fall_watch]).
		_check_fell()
		return
	if _rising:
		var speed: float = config.extra_rise_speed
		# Con la cámara detenida en el final del nivel, sigue subiendo hasta cubrir la pantalla.
		if config.rise_after_camera_stops and camera.has_reached_end():
			speed += config.end_rise_speed
		_extra_rise += speed * delta
	_follow_camera()
	_update_kill_zone()
	_check_fell()


func _process(delta: float) -> void:
	_time += delta
	_update_body_polygon()


## Activa o congela el ascenso (`extra_rise_speed` y `end_rise_speed`). El nivel lo congela al
## terminar la partida (victoria o derrota). El tentáculo sigue anclado a la cámara.
func set_rising(enabled: bool) -> void:
	_rising = enabled


## Activa o desactiva el tentáculo. Con [param active] `false` lo oculta, apaga la zona letal
## (`KillZone.monitoring`), el chequeo de caída y su animación, y deja de seguir a la cámara.
## Con `true` lo restaura y lo reubica. Estado inicial: activo. La intro lo usa para que no
## se vea antes de la ruptura.
func set_active(active: bool) -> void:
	if camera == null:
		return
	_active = active
	visible = active
	_kill_zone.set_deferred("monitoring", active)
	set_physics_process(active or _watch_fall)
	set_process(active)
	if active:
		_follow_camera()
		_update_kill_zone()
		_update_body_polygon()


## Con [param watch] `true`, un tentáculo inactivo sigue vigilando la caída: si el jugador cae bajo
## el borde inferior de la pantalla muere con `&"fell"`, sin que el tentáculo haga falta. La intro lo
## enciende en la ruptura (cuando empieza la partida) y el tentáculo entra recién después. Con el
## tentáculo activo no cambia nada (el chequeo ya corre).
func set_fall_watch(watch: bool) -> void:
	_watch_fall = watch
	if camera != null:
		set_physics_process(_active or _watch_fall)


## Activa el tentáculo y lo hace subir desde debajo de la pantalla hasta su posición normal en
## [param duration] s (siempre anclado a la cámara). Mientras sube ya es letal donde esté su borde
## superior. [method reset] cancela la entrada. La llama la intro tras `tentacle_entry_delay`.
func enter(duration: float) -> void:
	if camera == null:
		return
	if _entry_tween != null:
		_entry_tween.kill()
	# Arranca con el borde superior (más la onda) justo bajo el borde inferior de la pantalla.
	_entry_offset = config.visible_height + config.wobble_amplitude
	set_active(true)
	if duration <= 0.0:
		_entry_offset = 0.0
		_follow_camera()
		return
	_entry_tween = create_tween()
	_entry_tween.tween_property(self, "_entry_offset", 0.0, duration)


## Devuelve true si el tentáculo está activo (ver [method set_active]).
func is_active() -> bool:
	return _active


## Vuelve a la posición inicial (anulando el ascenso extra acumulado) y reanuda el ascenso.
func reset() -> void:
	if _entry_tween != null:
		_entry_tween.kill()
	_entry_offset = 0.0
	_extra_rise = 0.0
	_rising = true
	_follow_camera()


func _follow_camera() -> void:
	var rect: Rect2 = camera.get_visible_rect()
	global_position = Vector2(rect.position.x, camera.get_bottom_y() - config.visible_height - _extra_rise + _entry_offset)


## Profundidad del cuerpo: desde el borde superior hasta pasado el borde de la pantalla.
func _get_depth() -> float:
	return camera.get_bottom_y() - global_position.y + BODY_PADDING


func _update_kill_zone() -> void:
	var width: float = camera.get_visible_rect().size.x
	var top: float = config.kill_zone_inset
	var height: float = maxf(_get_depth() - top, 1.0)
	var shape: RectangleShape2D = _kill_shape.shape as RectangleShape2D
	shape.size = Vector2(width, height)
	_kill_shape.position = Vector2(width * 0.5, top + height * 0.5)


func _update_body_polygon() -> void:
	var width: float = camera.get_visible_rect().size.x
	var segments: int = maxi(config.wobble_segments, 1)
	var depth: float = _get_depth()
	var points := PackedVector2Array()
	for i: int in segments + 1:
		var wave: float = sin(_time * TAU * config.wobble_frequency + i * WOBBLE_PHASE_PER_SEGMENT)
		points.append(Vector2(width * i / segments, wave * config.wobble_amplitude))
	points.append(Vector2(width, depth))
	points.append(Vector2(0.0, depth))
	_body.polygon = points


func _check_fell() -> void:
	if not config.kill_on_leaving_screen_bottom:
		return
	var player: Player = _get_player()
	if player == null or not player.is_alive():
		return
	if player.global_position.y > camera.get_bottom_y() + config.screen_bottom_margin:
		_catch(player, &"fell")


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		_catch(body as Player, &"tentacle")


func _catch(player: Player, cause: StringName) -> void:
	if not player.is_alive():
		return
	player_caught.emit(cause)
	player.die(cause)


func _get_player() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player
