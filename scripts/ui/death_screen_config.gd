class_name DeathScreenConfig
extends Resource
## Datos y tiempos de la pantalla de derrota ([DeathScreen]). Sumar una muerte, una viñeta o una
## línea de humor es solo editar este recurso (`resources/configs/death_screen_config.tres`).
## Ver `docs/mecanicas/pantalla-derrota.md`.

@export_group("Muertes")
## Una entrada por muerte. Las causas sin entrada siguen con el texto de [LevelController].
@export var entries: Array[DeathScreenEntry] = []

@export_group("Tiempos")
## Fundido de entrada de la pantalla al morir. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var fade_in_time: float = 0.3
## Fundido de la línea de humor y del panel de datos al terminar (o saltar) `play`. Solo visual.
## Unidad: s.
@export_range(0.0, 2.0, 0.05) var reveal_time: float = 0.2


## Devuelve la entrada que corresponde a [param cause], o null si ninguna la tiene.
func get_entry(cause: StringName) -> DeathScreenEntry:
	for entry: DeathScreenEntry in entries:
		if entry != null and entry.causes.has(cause):
			return entry
	return null
