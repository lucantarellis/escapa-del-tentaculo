class_name RunRecords
extends RefCounted
## Récords del jugador guardados en el dispositivo (`user://records.cfg`).
##
## Por ahora solo el mejor progreso alcanzado (0..1 de la línea de progreso del HUD: 1 = llegó a
## la puerta). Como todos los segmentos miden lo mismo, el progreso de partidas distintas es
## comparable. Funciones estáticas: no hace falta instanciarlo. Ver `docs/mecanicas/hud.md`.

## Archivo donde se guardan los récords. Estructural.
const PATH: String = "user://records.cfg"
const SECTION: String = "records"
const KEY_BEST_PROGRESS: String = "best_progress"


## Devuelve el mejor progreso guardado (0..1). 0 si no hay récord.
static func get_best_progress() -> float:
	var file: ConfigFile = ConfigFile.new()
	if file.load(PATH) != OK:
		return 0.0
	return clampf(float(file.get_value(SECTION, KEY_BEST_PROGRESS, 0.0)), 0.0, 1.0)


## Registra el progreso de una partida terminada. Devuelve true si es un récord nuevo (y lo
## guarda).
static func submit_progress(progress: float) -> bool:
	progress = clampf(progress, 0.0, 1.0)
	if progress <= get_best_progress():
		return false
	var file: ConfigFile = ConfigFile.new()
	file.load(PATH)
	file.set_value(SECTION, KEY_BEST_PROGRESS, progress)
	file.save(PATH)
	return true


## Borra los récords (para pruebas).
static func clear() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.save(PATH)
