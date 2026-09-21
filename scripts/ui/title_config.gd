class_name TitleConfig
extends Resource
## Configuración de la pantalla de título ([TitleMenu]).
##
## Los textos no son gameplay, pero se dejan editables desde el inspector.
## Ver `docs/mecanicas/pantalla-titulo.md`.

@export_group("Transición")
## Duración del fundido del menú hasta quedar transparente (s).
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_duration: float = 0.8
## Espera entre pulsar el botón y empezar el fundido (s).
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_delay: float = 0.0

@export_group("Textos")
## Título del juego.
@export var title_text: String = "ESCAPA DEL TENTÁCULO"
## Texto del botón de jugar.
@export var play_text: String = "JUGAR"
