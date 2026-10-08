class_name SpeedBoost
extends Area2D
## Recogible de impulso: al tocarlo, el [Player] propulsa más fuerte y más rápido durante un
## instante ([method Player.apply_speed_boost]). Sirve para sacarle ventaja al fuego en el
## espacio. Un solo uso por partida. Capa 6 `pickups`, máscara 2 `player`, como [FuelTank].

## Un jugador recogió el impulso.
signal collected

@export var config: SpeedBoostConfig

var _bob_time: float = 0.0

@onready var _body: Polygon2D = $Body


func _ready() -> void:
	if config == null:
		config = SpeedBoostConfig.new()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_time += delta
	_body.position.y = sin(_bob_time * TAU * 1.2) * 3.0


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive() or not visible:
		return
	player.apply_speed_boost(config.duration, config.multiplier)
	if config.fuel_amount > 0.0:
		player.add_fuel(config.fuel_amount)
	visible = false
	set_deferred("monitoring", false)
	collected.emit()
