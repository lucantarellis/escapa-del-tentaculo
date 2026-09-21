class_name FuelTank
extends Area2D
## Tanque de combustible: recogible que recarga el combustible del [Player].
##
## Es un [Area2D] (capa 6 `pickups`, máscara 2 `player`): no colisiona físicamente. Al
## tocarlo un jugador vivo se le suma `fuel_amount` con [method Player.add_fuel]. Después se
## oculta y, si `respawn_time` > 0, reaparece. Ver `docs/mecanicas/tanques.md`.

## Un jugador recogió el tanque. [param amount] es la cantidad ofrecida (`fuel_amount`); el
## jugador recorta lo que exceda su `max_fuel`.
signal collected(amount: float)

## Tolerancia con la que el combustible del jugador cuenta como lleno. Estructural.
## Unidad: u.
const FULL_TOLERANCE: float = 0.001

@export_group("Configuración")
## Parámetros de recarga y animación (ver [FuelTankConfig]).
@export var config: FuelTankConfig

@onready var _body: Polygon2D = $Body

var _available: bool = true
var _respawn_left: float = 0.0
var _bob_time: float = 0.0


func _ready() -> void:
	if config == null:
		push_warning("FuelTank '%s' sin config: se usan los valores por defecto." % name)
		config = FuelTankConfig.new()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not _available:
		return
	# Vaivén solo visual: se mueve el dibujo, no el área de detección.
	_bob_time += delta
	_body.position.y = sin(_bob_time * TAU * config.bob_frequency) * config.bob_amplitude


func _physics_process(delta: float) -> void:
	if not _available:
		if _respawn_left > 0.0:
			_respawn_left -= delta
			if _respawn_left <= 0.0:
				_set_available(true)
		return
	# Con `only_if_not_full`, un jugador que estaba dentro con el tanque lleno no genera un
	# nuevo body_entered al gastar combustible: se revisa cada tick.
	if config.only_if_not_full and monitoring:
		for body: Node2D in get_overlapping_bodies():
			_try_collect(body)


## Devuelve true si el tanque está disponible (visible y recogible).
func is_available() -> bool:
	return _available


## Vuelve a dejar el tanque disponible y cancela cualquier reaparición pendiente.
func reset() -> void:
	_respawn_left = 0.0
	_bob_time = 0.0
	_set_available(true)


func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)


# Recarga al jugador si `body` es un Player vivo y se cumplen las condiciones de la config.
func _try_collect(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive() or not _available:
		return
	if config.only_if_not_full and player.get_fuel() >= player.config.max_fuel - FULL_TOLERANCE:
		return
	player.add_fuel(config.fuel_amount)
	collected.emit(config.fuel_amount)
	_respawn_left = maxf(config.respawn_time, 0.0)
	_set_available(false)


# Oculta o muestra el tanque y activa o desactiva su detección (diferido: seguro dentro de
# callbacks de física).
func _set_available(available: bool) -> void:
	_available = available
	visible = available
	set_deferred("monitoring", available)
