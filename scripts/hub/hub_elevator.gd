class_name HubElevator
extends Node2D
## Ascensor del hub: plataforma a media pantalla con dos mordazas de muelle que lleva a la partida.
##
## Secuencia: con el jugador parado encima [member HubConfig.elevator_arm_time] s pasa a `arming`
## (si se baja antes, vuelve a `idle`); al completarse, `launched`, las mordazas pasan a `open` y se
## separan con un tween; recién entonces se prenden las 4 llamas, emite [signal launch_started] y
## la plataforma sube acelerando hasta [member HubConfig.elevator_max_speed]. Al recorrer
## [member HubConfig.elevator_ride_distance] emite [signal ride_finished] (el golpe del alien): el
## [Hub] la traba con [method stall] (baja un poco, las llamas fallan y las balizas titilan en rojo)
## y en el apagón la apaga con [method shut_down]. El jugador no se mueve solo durante la subida: el
## [Hub] lo lleva pegado a la plataforma. El origen del nodo es (0, 0)
## del hub; las posiciones son las de `docs/arte/hub.md`.

## Hojas del ascensor y de las llamas. Estructural.
const SHEET_DIR: String = "res://assets/sprites/environment/hub/"
const THRUSTER_DIR: String = "res://assets/sprites/environment/platforms/"
## Esquina superior izquierda de la plataforma en reposo, tamaño y alto de la tapa con colisión
## (px). Estructural.
const PLATFORM_POSITION: Vector2 = Vector2(140.0, 316.0)
const PLATFORM_SIZE: Vector2 = Vector2(80.0, 24.0)
const PLATFORM_CAP: float = 12.0
## Mordazas: esquina superior izquierda de la izquierda y de la derecha (espejada), y tamaño (px).
## Estructural.
const CLAMP_LEFT_POSITION: Vector2 = Vector2(122.0, 300.0)
const CLAMP_RIGHT_POSITION: Vector2 = Vector2(220.0, 300.0)
const CLAMP_SIZE: Vector2 = Vector2(18.0, 32.0)
## Luz de cada baliza: distancia al borde exterior de la mordaza y altura sobre la plataforma (px).
## Solo visual.
const BEACON_INSET: float = 7.0
const BEACON_HEIGHT: float = 10.0
## Colores de las balizas por estado. Solo visual.
const BEACON_RED: Color = Color("F62A19")
const BEACON_AMBER: Color = Color("F8B842")
const BEACON_GREEN: Color = Color("4BE07A")
## Ciclo de giro de la baliza roja (s) y parte del ciclo en que está fuerte (cuadros 1–5 de 8).
## Solo visual.
const BEACON_CYCLE: float = 0.8
const BEACON_STRONG_PART: float = 0.625
## Toberas (esquina superior izquierda de cada llama, locales a la plataforma). Solo visual.
const THRUSTER_XS: Array[float] = [12.0, 28.0, 46.0, 62.0]
const THRUSTER_Y: float = 17.0
## Margen para considerar que el jugador está parado encima (px). Estructural.
const STAND_TOLERANCE: float = 3.0
## Trabada: probabilidad por cuadro de que cada llama falle (se apague o vuelva) y período del
## titileo rojo de las balizas (s). Solo visual.
const SPUTTER_CHANCE: float = 0.18
const STALL_BEACON_PERIOD: float = 0.25

enum Phase { IDLE, ARMING, OPENING, RISING, DONE, STALLED, OFF }

## Se soltaron las mordazas y la plataforma empieza a subir.
signal launch_started
## La plataforma recorrió la distancia de la subida (momento del golpe del alien).
signal ride_finished

@export var config: HubConfig

var _player: Player
var _phase: Phase = Phase.IDLE
var _arm_left: float = 0.0
var _speed: float = 0.0
var _risen: float = 0.0
var _time: float = 0.0
var _car: AnimatableBody2D
var _platform: SheetSprite
var _thrusters: Array[SheetSprite] = []
var _clamps: Array[SheetSprite] = []
var _beacons: Array[PointLight2D] = []


func _ready() -> void:
	if config == null:
		config = HubConfig.new()
	_car = AnimatableBody2D.new()
	_car.name = "Car"
	_car.position = PLATFORM_POSITION
	_car.collision_layer = 1
	_car.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(PLATFORM_SIZE.x, PLATFORM_CAP)
	shape.shape = rect
	shape.position = Vector2(PLATFORM_SIZE.x * 0.5, PLATFORM_CAP * 0.5)
	_car.add_child(shape)
	add_child(_car)
	_platform = _make_sheet(SHEET_DIR, "elevator_platform", true)
	_car.add_child(_platform)
	_platform.play(&"idle", true)
	for x: float in THRUSTER_XS:
		var flame: SheetSprite = _make_sheet(THRUSTER_DIR, "platform_thruster", true)
		flame.position = Vector2(x, THRUSTER_Y)
		flame.visible = false
		_car.add_child(flame)
		_thrusters.append(flame)
	for index: int in 2:
		var clamp_sprite: SheetSprite = _make_sheet(SHEET_DIR, "elevator_clamp", true)
		clamp_sprite.name = "ClampLeft" if index == 0 else "ClampRight"
		clamp_sprite.position = CLAMP_LEFT_POSITION if index == 0 else CLAMP_RIGHT_POSITION
		clamp_sprite.flip_h = index == 1
		for follower: Sprite2D in clamp_sprite.followers:
			follower.flip_h = clamp_sprite.flip_h
		add_child(clamp_sprite)
		clamp_sprite.play(&"idle", true)
		_clamps.append(clamp_sprite)
		var beacon_x: float = clamp_sprite.position.x + (BEACON_INSET if index == 0 else CLAMP_SIZE.x - BEACON_INSET)
		var beacon: PointLight2D = LevelLighting.make_light(BEACON_RED, config.beacon_energy, config.beacon_radius)
		beacon.name = "Beacon%d" % index
		beacon.position = Vector2(beacon_x, PLATFORM_POSITION.y - BEACON_HEIGHT)
		add_child(beacon)
		_beacons.append(beacon)


## Jugador que puede subirse. Lo asigna el [Hub].
func set_player(player: Player) -> void:
	_player = player


## Fase actual (IDLE, ARMING, OPENING, RISING, DONE).
func get_phase() -> Phase:
	return _phase


## Cuánto subió la plataforma desde el reposo (px).
func get_risen() -> float:
	return _risen


## Proporción de la subida recorrida (0..1).
func get_ride_ratio() -> float:
	return clampf(_risen / maxf(config.elevator_ride_distance, 1.0), 0.0, 1.0)


## Posición global de la esquina superior izquierda de la plataforma.
func get_car_position() -> Vector2:
	return _car.global_position


## Devuelve true si el jugador está parado sobre la plataforma.
func is_player_on() -> bool:
	if _player == null or not _player.is_on_floor():
		return false
	var top: float = _car.global_position.y
	var feet: float = _player.global_position.y + 12.0
	var x: float = _player.global_position.x
	return absf(feet - top) <= STAND_TOLERANCE and x >= _car.global_position.x and x <= _car.global_position.x + PLATFORM_SIZE.x


func _physics_process(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.IDLE:
			if is_player_on():
				_start_arming()
		Phase.ARMING:
			if not is_player_on():
				_cancel_arming()
			else:
				_arm_left -= delta
				if _arm_left <= 0.0:
					_release()
		Phase.RISING:
			var accel: float = config.elevator_max_speed / maxf(config.elevator_accel_time, 0.01)
			_speed = minf(_speed + accel * delta, config.elevator_max_speed)
			var step: float = _speed * delta
			_risen += step
			_car.position.y -= step
			if _risen >= config.elevator_ride_distance:
				_phase = Phase.DONE
				ride_finished.emit()
		Phase.STALLED:
			for flame: SheetSprite in _thrusters:
				if randf() < SPUTTER_CHANCE:
					flame.visible = not flame.visible
	_update_beacons()


## Golpe del alien: la plataforma se frena de golpe, baja [member HubConfig.alien_stall_sag] px y
## vuelve a la mitad; las llamas fallan y las balizas titilan en rojo.
func stall() -> void:
	_phase = Phase.STALLED
	_speed = 0.0
	var y: float = _car.position.y
	var tween: Tween = create_tween()
	tween.tween_property(_car, "position:y", y + config.alien_stall_sag, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(_car, "position:y", y + config.alien_stall_sag * 0.5, 0.35).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Apagón: llamas y balizas apagadas.
func shut_down() -> void:
	_phase = Phase.OFF
	for flame: SheetSprite in _thrusters:
		flame.visible = false


func _start_arming() -> void:
	_phase = Phase.ARMING
	_arm_left = config.elevator_arm_time
	_platform.play(&"arming")
	for clamp_sprite: SheetSprite in _clamps:
		clamp_sprite.play(&"arming", true)


func _cancel_arming() -> void:
	_phase = Phase.IDLE
	_platform.play(&"idle", true)
	for clamp_sprite: SheetSprite in _clamps:
		clamp_sprite.play(&"idle", true)


# Mordazas sueltas: se separan con transición y recién al terminar arranca la subida.
func _release() -> void:
	_phase = Phase.OPENING
	_platform.play(&"launched", true)
	var tween: Tween = create_tween().set_parallel(true)
	for index: int in _clamps.size():
		var clamp_sprite: SheetSprite = _clamps[index]
		clamp_sprite.play(&"open", true)
		var outward: float = -1.0 if index == 0 else 1.0
		tween.tween_property(clamp_sprite, "position:x", clamp_sprite.position.x + outward * config.clamp_open_offset, config.clamp_open_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(_start_rising)


func _start_rising() -> void:
	for flame: SheetSprite in _thrusters:
		flame.visible = true
		flame.play(&"idle", true)
	_phase = Phase.RISING
	_speed = 0.0
	launch_started.emit()


func _update_beacons() -> void:
	var color: Color = BEACON_RED
	var energy: float = config.beacon_energy
	match _phase:
		Phase.IDLE:
			# La roja late con el giro: fuerte en la primera parte del ciclo, baja en el resto.
			var strong: bool = fposmod(_time, BEACON_CYCLE) < BEACON_CYCLE * BEACON_STRONG_PART
			energy = config.beacon_energy if strong else config.beacon_low_energy
		Phase.ARMING:
			color = BEACON_AMBER
		Phase.STALLED:
			var on: bool = fposmod(_time, STALL_BEACON_PERIOD) < STALL_BEACON_PERIOD * 0.5
			energy = config.beacon_energy if on else 0.0
		Phase.OFF:
			energy = 0.0
		_:
			color = BEACON_GREEN
	for beacon: PointLight2D in _beacons:
		beacon.color = color
		beacon.energy = energy


# Hoja con relieve (si hay `_normal`) y capa emisiva sin sombreado, esquina superior izquierda en el
# origen.
static func _make_sheet(dir: String, sheet: String, with_emissive: bool) -> SheetSprite:
	var sprite: SheetSprite = SheetSprite.new()
	sprite.name = sheet
	sprite.centered = false
	sprite.set_sheet_textures(dir + sheet + ".png", dir + sheet + "_normal.png")
	if with_emissive and ResourceLoader.exists(dir + sheet + "_emissive.png"):
		var emissive: Sprite2D = Sprite2D.new()
		emissive.name = "Emissive"
		emissive.centered = false
		emissive.texture = load(dir + sheet + "_emissive.png")
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		emissive.material = unshaded
		sprite.add_child(emissive)
		sprite.followers = [emissive]
	sprite.load_sheet(dir + sheet + ".json")
	return sprite
