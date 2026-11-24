class_name DeathScreenEntry
extends Resource
## Una muerte de la pantalla de derrota ([DeathScreen]): qué causas la disparan, el título, las
## viñetas posibles y las líneas de humor. En cada muerte se elige una viñeta y una línea al azar.
## Ver `docs/mecanicas/pantalla-derrota.md` y `docs/arte/derrota.md`.

## Causas de [method Player.die] que muestran esta muerte (por ejemplo `tentacle`, `fell`).
@export var causes: Array[StringName] = []
## Título grande arriba (Tiny5 32 px, rojo). Solo visual.
@export var title: String = ""
## Nombres de las viñetas (sin extensión), en `assets/sprites/ui/death/`: `<nombre>.png` + `.json`
## con los tags `play` (una vez) y `end` (bucle). Para sumar una variante, agregar el nombre.
@export var vignettes: Array[String] = []
## Líneas de humor (Tiny5 16 px, hasta ~38 caracteres para que entren en una línea). Se pueden
## sumar todas las que se quieran.
@export var lines: Array[String] = []
