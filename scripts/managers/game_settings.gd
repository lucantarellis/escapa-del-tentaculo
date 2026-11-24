extends Node
## Ajustes del jugador (autoload `GameSettings`): volumen de música y efectos, vibración e idioma.
##
## Se cargan al abrir el juego desde `user://settings.cfg`, se aplican al instante (buses de audio
## `Music` y `SFX` de `default_bus_layout.tres`, `TranslationServer`) y se guardan en cada cambio.
## [method vibrate] es el punto único para vibrar: no hace nada con la vibración apagada.
## Ver `docs/mecanicas/ajustes.md`.

## Archivo de guardado. Estructural.
const SAVE_PATH: String = "user://settings.cfg"
## Buses de audio. Estructural.
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
## Idiomas disponibles: código de `TranslationServer` y nombre que se ve. Hoy hay uno solo; para
## sumar otro, agregarlo acá y cargar su traducción en el proyecto.
const LANGUAGES: Array[Dictionary] = [{"code": "es", "name": "Español"}]

## Cambió algún ajuste.
signal changed

var _music: float = 0.8
var _sfx: float = 0.8
var _vibration: bool = true
var _language: String = "es"


func _ready() -> void:
	_load()
	_apply()


## Volumen de la música (0..1).
func get_music_volume() -> float:
	return _music


## Volumen de los efectos (0..1).
func get_sfx_volume() -> float:
	return _sfx


## Devuelve true si la vibración está activa.
func is_vibration_enabled() -> bool:
	return _vibration


## Código del idioma actual (por ejemplo `es`).
func get_language() -> String:
	return _language


## Nombre del idioma actual (por ejemplo "Español").
func get_language_name() -> String:
	return LANGUAGES[_language_index()]["name"]


## Fija el volumen de la música (0..1), lo aplica y lo guarda.
func set_music_volume(value: float) -> void:
	_music = clampf(value, 0.0, 1.0)
	_apply_and_save()


## Fija el volumen de los efectos (0..1), lo aplica y lo guarda.
func set_sfx_volume(value: float) -> void:
	_sfx = clampf(value, 0.0, 1.0)
	_apply_and_save()


## Activa o desactiva la vibración y lo guarda.
func set_vibration_enabled(enabled: bool) -> void:
	_vibration = enabled
	_apply_and_save()


## Pasa al idioma anterior ([param step] −1) o siguiente (+1) de [constant LANGUAGES].
func cycle_language(step: int) -> void:
	var index: int = wrapi(_language_index() + step, 0, LANGUAGES.size())
	_language = LANGUAGES[index]["code"]
	_apply_and_save()


## Vibra [param duration_ms] ms si la vibración está activa (solo en el celular).
func vibrate(duration_ms: int = 60) -> void:
	if _vibration:
		Input.vibrate_handheld(duration_ms)


func _language_index() -> int:
	for index: int in LANGUAGES.size():
		if LANGUAGES[index]["code"] == _language:
			return index
	return 0


func _apply_and_save() -> void:
	_apply()
	_save()
	changed.emit()


func _apply() -> void:
	_set_bus(MUSIC_BUS, _music)
	_set_bus(SFX_BUS, _sfx)
	TranslationServer.set_locale(_language)


static func _set_bus(bus_name: StringName, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


func _load() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	_music = clampf(float(file.get_value("audio", "music", _music)), 0.0, 1.0)
	_sfx = clampf(float(file.get_value("audio", "sfx", _sfx)), 0.0, 1.0)
	_vibration = bool(file.get_value("game", "vibration", _vibration))
	_language = String(file.get_value("game", "language", _language))
	_language = LANGUAGES[_language_index()]["code"]


func _save() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("audio", "music", _music)
	file.set_value("audio", "sfx", _sfx)
	file.set_value("game", "vibration", _vibration)
	file.set_value("game", "language", _language)
	file.save(SAVE_PATH)
