extends Node
## Progreso del jugador entre partidas (autoload): monedas, mejoras compradas y su guardado.
##
## Es un autoload (accesible por su nombre `PlayerProgress` y no se destruye al recargar el nivel).
## Lleva las monedas guardadas, las que se juntan en la partida en curso (se suman a las guardadas
## cuando la partida termina o se reinicia) y qué nodos del árbol de talentos están comprados. Todo se guarda en
## `user://progress.cfg`. Aplica las mejoras al jugador por encima de `player_config.tres`, sin
## modificarlo (ver [method apply_to_player_config]). Ver `docs/mecanicas/progreso-mercado.md`.

## Cambió la cantidad de monedas guardadas.
signal coins_changed(total: int)
## Cambió la cantidad de monedas juntadas en la partida en curso.
signal run_coins_changed(run_total: int)
## Se borraron todas las compras y las monedas (Reset all del mercado).
signal progress_reset
## Se compró un nodo del árbol.
signal upgrade_purchased(id: StringName)

## Razones por las que una mejora no se puede comprar (ver [method get_block_reason]). Estructural.
const BLOCK_NONE: StringName = &""
const BLOCK_OWNED: StringName = &"owned"
const BLOCK_LOCKED: StringName = &"locked"
const BLOCK_COINS: StringName = &"coins"
const BLOCK_REQUIRES: StringName = &"requires"
## Archivo donde se guarda el progreso. Estructural.
const SAVE_PATH: String = "user://progress.cfg"
## Config del progreso. Estructural: es el único `.tres` de este sistema.
const CONFIG_PATH: String = "res://resources/configs/progress_config.tres"
const SECTION_WALLET: String = "wallet"
const KEY_COINS: String = "coins"
const SECTION_UPGRADES: String = "upgrades"
const SECTION_META: String = "meta"
const KEY_TREE_VERSION: String = "tree_version"
## Versión del árbol de talentos. Si el archivo de guardado es de otra versión (o no tiene), se
## empieza de cero una sola vez: monedas y compras en 0. Estructural.
const TREE_VERSION: int = 1

## Parámetros del progreso (se carga de [constant CONFIG_PATH]).
var config: ProgressConfig

var _coins: int = 0
var _run_coins: int = 0
var _run_banked: bool = true
# id del nodo -> true si está comprado (los que vienen de regalo no se guardan).
var _owned: Dictionary = {}


func _ready() -> void:
	config = load(CONFIG_PATH) as ProgressConfig
	if config == null:
		push_warning("PlayerProgress: no se pudo cargar '%s': se usan los valores por defecto." % CONFIG_PATH)
		config = ProgressConfig.new()
	_load()
	if config.enabled and config.debug_set_coins >= 0:
		_coins = config.debug_set_coins
		_save()
	elif config.enabled and config.debug_min_coins > _coins:
		_coins = config.debug_min_coins
		_save()
	GameManager.run_started.connect(_on_run_started)
	GameManager.run_won.connect(bank_run)
	GameManager.run_lost.connect(_on_run_lost)
	GameManager.restart_requested.connect(bank_run)


func _notification(what: int) -> void:
	# Al cerrar el juego en medio de una partida, las monedas juntadas no se pierden.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		bank_run()


## Devuelve true si el progreso está activo (`ProgressConfig.enabled`).
func is_enabled() -> bool:
	return config.enabled


## Devuelve las monedas guardadas (sin contar las de la partida en curso).
func get_coins() -> int:
	return _coins


## Devuelve las monedas juntadas en la partida en curso.
func get_run_coins() -> int:
	return _run_coins


## Suma [param amount] monedas a la partida en curso. Las usa [Coin] al recogerse. Se ignora si el
## progreso está apagado.
func add_run_coins(amount: int) -> void:
	if not config.enabled or amount <= 0:
		return
	if _run_banked:
		# Una moneda llegó fuera de una partida registrada (por ejemplo, F6 sobre un segmento).
		_run_banked = false
	_run_coins += amount
	run_coins_changed.emit(_run_coins)


## Pasa las monedas de la partida a las guardadas. Se llama sola al ganar, perder o reiniciar; no
## suma dos veces la misma partida.
func bank_run() -> void:
	if _run_banked:
		return
	_run_banked = true
	if _run_coins <= 0:
		return
	_coins += _run_coins
	_save()
	coins_changed.emit(_coins)


## Devuelve true si el nodo [param id] está comprado (o viene de regalo).
func is_owned(id: StringName) -> bool:
	if _owned.has(id):
		return true
	var upgrade: UpgradeData = get_upgrade(id)
	return upgrade != null and upgrade.owned_by_default


## Devuelve el nodo con ese [param id] (null si no existe).
func get_upgrade(id: StringName) -> UpgradeData:
	for upgrade: UpgradeData in config.upgrades:
		if upgrade != null and upgrade.id == id:
			return upgrade
	return null


## Devuelve por qué no se puede comprar el nodo [param id]: [constant BLOCK_OWNED] (ya lo tenés o no
## existe), [constant BLOCK_LOCKED] (todavía no está implementado), [constant BLOCK_REQUIRES] (falta
## el nodo anterior), [constant BLOCK_COINS] (faltan monedas) o [constant BLOCK_NONE] (se puede
## comprar).
func get_block_reason(id: StringName) -> StringName:
	var upgrade: UpgradeData = get_upgrade(id)
	if upgrade == null or is_owned(id):
		return BLOCK_OWNED
	if upgrade.locked:
		return BLOCK_LOCKED
	if upgrade.requires_id != &"" and not is_owned(upgrade.requires_id):
		return BLOCK_REQUIRES
	if _coins < upgrade.price:
		return BLOCK_COINS
	return BLOCK_NONE


## Devuelve true si se puede comprar el nodo [param id] ahora mismo.
func can_buy(id: StringName) -> bool:
	return config.enabled and get_block_reason(id) == BLOCK_NONE


## Compra el nodo [param id]: descuenta las monedas y guarda. Devuelve true si se compró.
func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	var upgrade: UpgradeData = get_upgrade(id)
	_coins -= upgrade.price
	_owned[id] = true
	_save()
	coins_changed.emit(_coins)
	upgrade_purchased.emit(id)
	return true


## Borra monedas y compras, y guarda el archivo vacío (para pruebas).
func reset_all() -> void:
	_coins = 0
	_run_coins = 0
	_run_banked = true
	_owned.clear()
	_save()
	coins_changed.emit(_coins)
	run_coins_changed.emit(_run_coins)
	progress_reset.emit()


## Devuelve el valor más alto de los nodos comprados con ese [param effect] (ver
## [code]UpgradeData.EFFECT_*[/code]). Devuelve [param fallback] si no hay ninguno. Se ignoran los
## nodos con candado y, con el progreso apagado, todos.
func get_effect_value(effect: StringName, fallback: float) -> float:
	var node: UpgradeData = _best_node(effect)
	return fallback if node == null else node.value


## Devuelve true si hay algún nodo comprado con ese [param effect].
func has_effect(effect: StringName) -> bool:
	return _best_node(effect) != null


## Devuelve una COPIA de [param base] con el progreso aplicado: combustible máximo e inicial,
## distancia del dash (recta y diagonal), costo del dash y velocidad/aceleración de la propulsión.
## Sin compras: `base_max_fuel` y `base_dash_distance`, y el resto igual que [param base]. Con el
## progreso apagado devuelve [param base] sin copiar ni cambiar. Nunca modifica [param base] (es un
## recurso compartido).
func apply_to_player_config(base: PlayerConfig) -> PlayerConfig:
	if not config.enabled:
		return base
	var result: PlayerConfig = base.duplicate() as PlayerConfig
	var fuel: float = get_effect_value(UpgradeData.EFFECT_MAX_FUEL, config.base_max_fuel)
	result.max_fuel = fuel
	result.starting_fuel = fuel
	var dash: float = get_effect_value(UpgradeData.EFFECT_DASH_DISTANCE, config.base_dash_distance)
	result.dash_distance = dash
	result.dash_diagonal_distance = dash
	if has_effect(UpgradeData.EFFECT_DASH_FREE):
		result.dash_fuel_cost = 0.0
	var speed_node: UpgradeData = _best_node(UpgradeData.EFFECT_SPEED)
	if speed_node != null:
		result.max_speed = maxf(base.max_speed, speed_node.value)
		result.thrust_acceleration = maxf(base.thrust_acceleration, speed_node.extra_value)
	return result


## Devuelve cuánto combustible da un tanque: [param base_amount] (el de su config) o, si se compró
## una carga mayor en el árbol, esa. Sin progreso, [param base_amount].
func get_tank_amount(base_amount: float) -> float:
	if not config.enabled:
		return base_amount
	return maxf(base_amount, get_effect_value(UpgradeData.EFFECT_TANK_AMOUNT, base_amount))


## Devuelve cuánto vale una moneda: [param base_value] (el de su config) o, si se compró una mejora
## de monedas, ese valor. Sin progreso, [param base_value].
func get_coin_value(base_value: int) -> int:
	if not config.enabled:
		return base_value
	return maxi(base_value, int(get_effect_value(UpgradeData.EFFECT_COIN_VALUE, float(base_value))))


## Devuelve la invulnerabilidad del dash como {start, percent, unblockable} o un diccionario vacío
## si no se compró (o el progreso está apagado). `start` en s, `percent` es el porcentaje del dash
## que dura; `unblockable` es la lista de causas de muerte que no frena.
func get_dash_invulnerability() -> Dictionary:
	if not has_effect(UpgradeData.EFFECT_DASH_INVULN):
		return {}
	return {
		"start": config.dash_invulnerable_start,
		"percent": config.dash_invulnerable_percent,
		"unblockable": config.dash_unblockable_causes,
	}


## Devuelve cómo resiste golpes el jugador como {max_hp, hit_invulnerable_time, instakill_causes,
## respawn, respawn_height, respawn_hp}. Sin compras (o con el progreso apagado): 1 punto, sin
## reaparecer, o sea que el primer golpe letal mata como siempre.
func get_survival() -> Dictionary:
	var max_hp: int = 1
	var respawn: bool = false
	if config.enabled:
		max_hp = maxi(int(get_effect_value(UpgradeData.EFFECT_HIT_POINTS, 1.0)), 1)
		respawn = has_effect(UpgradeData.EFFECT_RESPAWN)
	return {
		"max_hp": max_hp,
		"hit_invulnerable_time": config.hit_invulnerable_time,
		"instakill_causes": config.instakill_causes,
		"respawn": respawn,
		"respawn_height": config.respawn_height,
		"respawn_hp": clampi(config.respawn_hit_points, 1, max_hp),
	}


# Nodo comprado con ese efecto y el mayor `value` (null si no hay). Ignora los nodos con candado.
func _best_node(effect: StringName) -> UpgradeData:
	if not config.enabled:
		return null
	var best: UpgradeData = null
	for upgrade: UpgradeData in config.upgrades:
		if upgrade == null or upgrade.locked or upgrade.effect != effect or not is_owned(upgrade.id):
			continue
		if best == null or upgrade.value > best.value:
			best = upgrade
	return best


func _on_run_started(_run_seed: int) -> void:
	# Por si la partida anterior no llegó a registrarse.
	bank_run()
	_run_banked = false
	_run_coins = 0
	run_coins_changed.emit(_run_coins)


func _on_run_lost(_cause: StringName) -> void:
	bank_run()


func _load() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	if int(file.get_value(SECTION_META, KEY_TREE_VERSION, 0)) != TREE_VERSION:
		# Guardado de otra versión del mercado: se empieza de cero una sola vez.
		_save()
		return
	_coins = maxi(int(file.get_value(SECTION_WALLET, KEY_COINS, 0)), 0)
	if file.has_section(SECTION_UPGRADES):
		for key: String in file.get_section_keys(SECTION_UPGRADES):
			if int(file.get_value(SECTION_UPGRADES, key, 0)) > 0:
				_owned[StringName(key)] = true


func _save() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION_META, KEY_TREE_VERSION, TREE_VERSION)
	file.set_value(SECTION_WALLET, KEY_COINS, _coins)
	for id: StringName in _owned:
		file.set_value(SECTION_UPGRADES, String(id), 1)
	file.save(SAVE_PATH)
