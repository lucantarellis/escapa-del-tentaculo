class_name Repairer
extends Area2D
## Reparador: recogible que cura al jugador (mejora Reparador del mercado).
##
## Hay tres tipos: la llave inglesa cura 1 vida, la venda (cinta selladora) cura 2 y el botiquín (caja de
## herramientas) cura todas y da un escudo. Es un [Area2D] (capa 6 `pickups`, máscara 2 `player`): al tocarlo un jugador vivo lo cura
## y desaparece (un solo uso). La llave y la venda no se recogen con la vida llena: se quedan en su
## lugar. El botiquín se recoge siempre (por el escudo). Los valores salen de [ProgressConfig].
## Ver `docs/mecanicas/reparadores.md`.

## Tipos de reparador.
enum Kind {
	WRENCH,  ## Llave inglesa: cura 1 vida.
	BANDAGE, ## Venda: cura 2 vidas.
	MEDKIT,  ## Botiquín: cura todas las vidas y da un escudo.
}

## El jugador recogió el reparador. [param kind] es su tipo y [param healed] cuántas vidas curó.
signal collected(kind: Kind, healed: int)

## Hoja de sprites de cada tipo (la venda se dibuja como cinta selladora). Estructural.
const SHEET_BY_KIND: Dictionary = {
	Kind.WRENCH: "pickup_wrench",
	Kind.BANDAGE: "pickup_tape",
	Kind.MEDKIT: "pickup_toolbox",
}
## Amplitud (px) y velocidad (Hz) del vaivén. Solo visual.
const BOB_AMPLITUDE: float = 2.0
const BOB_FREQUENCY: float = 1.2

@export_group("Reparador")
## Qué tipo de reparador es. Lo fija quien lo crea ([RepairerSpawner]) antes de agregarlo.
@export var kind: Kind = Kind.WRENCH

var _available: bool = true
var _bob_time: float = 0.0
var _visual: PickupSkin


func _ready() -> void:
	_visual = PickupSkin.new()
	_visual.sheet = SHEET_BY_KIND[kind]
	add_child(_visual)
	_visual.collect_finished.connect(_on_collect_finished)
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	# Si el jugador está encima (por ejemplo, con la vida llena cuando llegó) y ahora puede
	# recogerlo, se reintenta: `body_entered` solo avisa al entrar.
	if not _available:
		return
	for body: Node2D in get_overlapping_bodies():
		_on_body_entered(body)


func _process(delta: float) -> void:
	if not _available:
		return
	_bob_time += delta
	_visual.position.y = sin(_bob_time * TAU * BOB_FREQUENCY) * BOB_AMPLITUDE


## Devuelve true si el reparador sigue sin recoger.
func is_available() -> bool:
	return _available


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive() or not _available:
		return
	var cfg: ProgressConfig = PlayerProgress.config
	var healed: int = 0
	match kind:
		Kind.WRENCH:
			if not player.needs_healing():
				return
			healed = player.heal(cfg.repairer_heal_wrench)
		Kind.BANDAGE:
			if not player.needs_healing():
				return
			healed = player.heal(cfg.repairer_heal_bandage)
		Kind.MEDKIT:
			healed = player.heal(-1)
			player.give_shield(PlayerProgress.get_shield_duration())
	_available = false
	set_deferred("monitoring", false)
	_visual.play_collect()
	collected.emit(kind, healed)


# Terminó el destello de recolección: se oculta.
func _on_collect_finished() -> void:
	visible = false
