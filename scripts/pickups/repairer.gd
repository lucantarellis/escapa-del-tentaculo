class_name Repairer
extends Area2D
## Reparador: recogible que cura al jugador (mejora Reparador del mercado).
##
## Hay tres tipos: la llave inglesa cura 1 vida, la venda cura 2 y el botiquín cura todas y da un
## escudo. Es un [Area2D] (capa 6 `pickups`, máscara 2 `player`): al tocarlo un jugador vivo lo cura
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

## Colores placeholder: cian de recogible y blanco azulado de detalle. Solo visual.
const COLOR_MAIN: Color = Color("#63D6C5")
const COLOR_DETAIL: Color = Color("#C8E7EA")
## Amplitud (px) y velocidad (Hz) del vaivén. Solo visual.
const BOB_AMPLITUDE: float = 2.0
const BOB_FREQUENCY: float = 1.2

@export_group("Reparador")
## Qué tipo de reparador es. Lo fija quien lo crea ([RepairerSpawner]) antes de agregarlo.
@export var kind: Kind = Kind.WRENCH

var _available: bool = true
var _bob_time: float = 0.0
var _visual: Node2D


func _ready() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	_build_visual()
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


# Dibujo placeholder según el tipo, con polígonos simples (sin imágenes).
func _build_visual() -> void:
	match kind:
		Kind.WRENCH:
			# Mango inclinado y cabeza con boca.
			_add_poly(PackedVector2Array([Vector2(-7, 5), Vector2(-4, 8), Vector2(5, -1), Vector2(2, -4)]), COLOR_MAIN)
			_add_poly(PackedVector2Array([Vector2(1, -9), Vector2(8, -9), Vector2(9, -2), Vector2(5, -2), Vector2(5, -5), Vector2(3, -5), Vector2(3, -2), Vector2(-1, -2)]), COLOR_MAIN)
		Kind.BANDAGE:
			# Tira con una almohadilla al centro.
			_add_poly(PackedVector2Array([Vector2(-10, -4), Vector2(10, -4), Vector2(10, 4), Vector2(-10, 4)]), COLOR_MAIN)
			_add_poly(PackedVector2Array([Vector2(-3, -4), Vector2(3, -4), Vector2(3, 4), Vector2(-3, 4)]), COLOR_DETAIL)
		Kind.MEDKIT:
			# Caja blanca azulada con cruz cian.
			_add_poly(PackedVector2Array([Vector2(-9, -7), Vector2(9, -7), Vector2(9, 7), Vector2(-9, 7)]), COLOR_DETAIL)
			_add_poly(PackedVector2Array([Vector2(-2, -5), Vector2(2, -5), Vector2(2, 5), Vector2(-2, 5)]), COLOR_MAIN)
			_add_poly(PackedVector2Array([Vector2(-6, -2), Vector2(6, -2), Vector2(6, 2), Vector2(-6, 2)]), COLOR_MAIN)


func _add_poly(points: PackedVector2Array, color: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	_visual.add_child(poly)


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
			player.give_shield(cfg.repairer_shield_duration)
	_available = false
	visible = false
	set_deferred("monitoring", false)
	collected.emit(kind, healed)
