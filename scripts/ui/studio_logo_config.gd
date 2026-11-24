class_name StudioLogoConfig
extends Resource
## Pantalla del logo del estudio ([StudioLogo]), antes de la pantalla de inicio: textos y tiempos.
## Los tiempos de cada cuadro de la tele salen del JSON de Aseprite. Ver
## `docs/mecanicas/logo-estudio.md` y `docs/arte/logo-estudio.md`.

## Si es false, el juego arranca directo en la pantalla de inicio (útil al probar).
@export var enabled: bool = true

@export_group("Textos")
## Nombre del estudio (línea de arriba, blanca). Por ahora guiones bajos. Solo visual.
@export var studio_name: String = "__________"
## Línea de abajo (gris). Solo visual.
@export var studio_label: String = "ESTUDIO"

@export_group("Tiempos")
## Fundido de entrada de la tele. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var fade_in_time: float = 0.3
## Pantalla vacía antes del reflejo. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var empty_hold: float = 0.3
## Pausa entre el reflejo y la aparición del bebé. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var pre_pop_pause: float = 0.2
## Cuánto queda el bebé saludando con el texto antes del fundido. Solo visual. Unidad: s.
@export_range(0.0, 5.0, 0.05) var hold_time: float = 1.8
## Fundido a negro al terminar. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var fade_out_time: float = 0.3
## Fundido a negro al saltearlo (cualquier tecla, botón o toque). Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var skip_fade_time: float = 0.15
