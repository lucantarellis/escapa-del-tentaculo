class_name Coin
extends Area2D
## Moneda: recogible que suma monedas a la partida en curso.
##
## Es un [Area2D] (capa 6 `pickups`, máscara 2 `player`): no colisiona físicamente. Al tocarla un
## jugador vivo emite [signal collected], reproduce el destello de recolección y se libera al
## terminarlo (un solo uso). Quien la crea (ver
## [CoinSpawner]) conecta la señal con [method PlayerProgress.add_run_coins]. Las monedas
## juntadas se guardan al terminar la partida. Ver `docs/mecanicas/progreso-mercado.md`.

## Un jugador recogió la moneda. [param value] es lo que vale (`CoinConfig.value`).
signal collected(value: int)

@export_group("Configuración")
## Valor y animación (ver [CoinConfig]).
@export var config: CoinConfig

@onready var _body: PickupSkin = $Skin

var _available: bool = true
var _bob_time: float = 0.0


func _ready() -> void:
	if config == null:
		config = CoinConfig.new()
	body_entered.connect(_on_body_entered)
	_body.collect_finished.connect(queue_free)


func _process(delta: float) -> void:
	if not _available:
		return
	# Vaivén solo visual: se mueve el dibujo, no el área de detección.
	_bob_time += delta
	_body.position.y = sin(_bob_time * TAU * config.bob_frequency) * config.bob_amplitude


## Devuelve true si la moneda sigue sin recoger.
func is_available() -> bool:
	return _available


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive() or not _available:
		return
	_available = false
	set_deferred("monitoring", false)
	# Destello de recolección; al terminar la moneda se libera (la suma ya se hizo).
	_body.play_collect()
	# Las mejoras de monedas del árbol suben lo que vale (ver [PlayerProgress]).
	collected.emit(PlayerProgress.get_coin_value(config.value))
