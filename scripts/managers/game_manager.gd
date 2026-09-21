extends Node
## Game manager (autoload): lleva el estado de la partida y avisa con señales.
##
## Es un autoload: Godot lo carga una vez al iniciar el juego, es accesible por su nombre
## (`GameManager`) desde cualquier script y NO se destruye al recargar la escena. Por eso
## puede llevar el estado y, más adelante, datos que sobrevivan al reinicio (por ejemplo un
## puntaje).
##
## No conoce nodos de la escena: no hace `get_node` a nada. El nivel (ver [LevelController])
## le notifica lo que pasa y reacciona a sus señales. Ver `docs/mecanicas/game-manager.md`.

## Estados de la partida.
enum State {
	## Todavía no empezó (por ejemplo, mientras se recarga la escena).
	READY,
	## Partida en curso.
	PLAYING,
	## El jugador llegó a la puerta.
	WON,
	## El jugador murió.
	LOST,
}

## La partida empezó. [param run_seed] es la seed del nivel (0 si el nivel no usa seed).
signal run_started(run_seed: int)
## El jugador ganó la partida.
signal run_won
## El jugador perdió. [param cause] es la causa de muerte (por ejemplo `&"tentacle"`).
signal run_lost(cause: StringName)
## El estado cambió de [param old_state] a [param new_state].
signal state_changed(new_state: State, old_state: State)

var _state: State = State.READY
var _current_seed: int = 0
var _last_death_cause: StringName = &""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()


## Empieza una partida (pasa a [constant State.PLAYING]). Vale desde cualquier estado: el
## nivel la llama al iniciar. [param run_seed] se guarda para consultarla y para reportar
## "este nivel estuvo raro".
func start_run(run_seed: int = 0) -> void:
	_current_seed = run_seed
	_last_death_cause = &""
	_set_state(State.PLAYING)
	run_started.emit(run_seed)


## El jugador murió. Solo vale durante [constant State.PLAYING]; si no, se ignora (por
## ejemplo, morir después de ganar).
func notify_player_died(cause: StringName) -> void:
	if _state != State.PLAYING:
		return
	_last_death_cause = cause
	_set_state(State.LOST)
	run_lost.emit(cause)


## El jugador llegó a la puerta. Solo vale durante [constant State.PLAYING]; si no, se
## ignora.
func notify_goal_reached() -> void:
	if _state != State.PLAYING:
		return
	_set_state(State.WON)
	run_won.emit()


## Recarga la escena actual (vuelve a [constant State.READY]). El nivel empieza otra
## partida al cargarse.
func restart() -> void:
	_set_state(State.READY)
	get_tree().reload_current_scene()


## Devuelve el estado actual de la partida.
func get_state() -> State:
	return _state


## Devuelve la seed de la partida actual (0 si el nivel no usa seed).
func get_current_seed() -> int:
	return _current_seed


## Devuelve la causa de la última muerte (`&""` si la partida en curso no terminó en derrota).
func get_last_death_cause() -> StringName:
	return _last_death_cause


func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	var old_state: State = _state
	_state = new_state
	state_changed.emit(new_state, old_state)
