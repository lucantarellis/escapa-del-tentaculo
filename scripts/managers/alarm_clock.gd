extends Node
## Reloj de las alarmas de la nave (autoload `AlarmClock`). Las animaciones de tiles de Godot
## (modo `ANIMATION_MODE_DEFAULT`) se calculan con el tiempo del motor de render, que avanza con el
## mismo paso que el `delta` de `_process` (incluso con el árbol en pausa y con `Engine.time_scale`).
## Este nodo suma ese `delta` y publica el resultado en [member time], así las luces de las alarmas
## ([WallLights]) calculan su cuadro con el mismo reloj que el tile y parpadean juntas. Va primero
## en el orden de procesamiento (es autoload), así los demás nodos leen el tiempo de este mismo
## cuadro. Ver `docs/mecanicas/iluminacion.md`.

## Segundos desde que arrancó el bucle principal, en el reloj del tile.
var time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1000


func _process(delta: float) -> void:
	time += delta
