class_name RepairerSpawner
extends RefCounted
## Reparte reparadores ([Repairer]) en los segmentos del nivel, según el nivel de reparador
## comprado en el mercado.
##
## En cada segmento hay `repairer_chance_percent` % de chance de que aparezca uno, en un lugar
## libre (mismo criterio que las monedas, ver [CoinSpawner]). Cuál sale se sortea con los pesos de
## [ProgressConfig] entre los tipos habilitados: nivel 1 = llave; 2 = llave y venda; 3 = llave, venda
## y botiquín. El azar sale del [RandomNumberGenerator] que se le pasa, así la misma seed da los
## mismos reparadores. Ver `docs/mecanicas/reparadores.md`.

var _scene: PackedScene
var _finder: CoinSpawner


func _init(repairer_scene: PackedScene, finder: CoinSpawner) -> void:
	_scene = repairer_scene
	_finder = finder


## Sortea y coloca (si toca) un reparador en [param segment]. [param level] es el nivel de reparador
## (1 a 3). Devuelve true si puso uno.
func populate(segment: LevelSegment, rng: RandomNumberGenerator, cfg: ProgressConfig, level: int) -> bool:
	if level <= 0:
		return false
	# Se sortean siempre las mismas tiradas por segmento, así un lugar sin espacio no corre el azar.
	var roll: float = rng.randf() * 100.0
	var kind_roll: float = rng.randf()
	if roll >= cfg.repairer_chance_percent:
		return false
	var pos: Vector2 = _finder.find_free_position(segment, rng, cfg)
	if pos == Vector2.INF:
		return false
	var repairer: Repairer = _scene.instantiate() as Repairer
	repairer.kind = _pick_kind(cfg, level, kind_roll)
	repairer.position = pos
	segment.add_child(repairer)
	return true


# Elige el tipo con los pesos de la config entre los habilitados por [param level]. [param roll]
# va de 0 a 1.
func _pick_kind(cfg: ProgressConfig, level: int, roll: float) -> Repairer.Kind:
	var kinds: Array[Repairer.Kind] = [Repairer.Kind.WRENCH]
	var weights: Array[float] = [maxf(cfg.repairer_weight_wrench, 0.0)]
	if level >= 2:
		kinds.append(Repairer.Kind.BANDAGE)
		weights.append(maxf(cfg.repairer_weight_bandage, 0.0))
	if level >= 3:
		kinds.append(Repairer.Kind.MEDKIT)
		weights.append(maxf(cfg.repairer_weight_medkit, 0.0))
	var total: float = 0.0
	for weight: float in weights:
		total += weight
	if total <= 0.0:
		return kinds[0]
	var target: float = roll * total
	for i: int in kinds.size():
		target -= weights[i]
		if target < 0.0:
			return kinds[i]
	return kinds[kinds.size() - 1]
