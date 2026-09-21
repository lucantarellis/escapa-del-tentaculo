# Mecánica: obstáculos

**Archivos:** `scripts/obstacles/obstacle.gd`, `moving_obstacle.gd`, `moving_obstacle_config.gd`, `pulse_trap.gd`, `pulse_trap_config.gd`; escenas `scenes/obstacles/Obstacle.tscn`, `MovingObstacle.tscn`, `PulseTrap.tscn`; configs `resources/configs/moving_obstacle_config.tres` y `pulse_trap_config.tres`.
**Temporal:** `scripts/levels/sandbox_controller.gd` muestra el mensaje de derrota (lo reemplaza el game manager, paso 6).

## Propósito

Peligros que llenan el recorrido entre el jugador y la puerta. Hay tres, todos letales al contacto:

- **`Obstacle`**: bloque estático. Estrecha pasillos o bloquea zonas.
- **`MovingObstacle`**: bloque que va y viene entre dos puntos. Obliga a cronometrar el paso.
- **`PulseTrap`**: bloque que alterna entre seguro y letal, con un aviso antes de activarse. Obliga a esperar o a cruzar en la ventana segura.

## Modelo en palabras simples

- **Son `Area2D`, no cuerpos físicos.** Detectan al jugador (capa 3 `obstacles`, máscara 2 `player`) pero no lo empujan ni lo frenan: rozar un obstáculo no es rebotar, es morir. Por eso no hace falta ninguna lógica de choque en el jugador.
- **Qué mata.** Cuando un `Player` vivo entra en el área, el obstáculo emite `player_hit(cause)` y llama a `Player.die(cause)`, que emite `Player.died(cause)`. Un jugador ya muerto se ignora (no se emite dos veces).
- **La causa** (`cause`) es un `StringName` configurable por instancia. Por defecto `&"obstacle"` (estático y móvil) y `&"trap"` (trampa). El controlador de partida la usa para elegir el mensaje.
- **Herencia.** `MovingObstacle` y `PulseTrap` extienden `Obstacle`: comparten forma, colisión y detección. Sus escenas son escenas heredadas de `Obstacle.tscn`.
- **Reutilizables y configurables por instancia.** Lo que es *diseño de nivel* (tamaño, recorrido) se edita en la instancia; lo que es *tuning* (velocidad, tiempos) vive en un `Resource`. Para que dos instancias tengan tuning distinto (por ejemplo otro `start_delay`), hacer el recurso único (Make Unique en el inspector) o duplicar el `.tres`.
- **`@tool`.** Los tres scripts corren en el editor: al cambiar `size` se ve el cambio de forma y de área letal sin ejecutar el juego, y `MovingObstacle` dibuja su trayectoria. Convenciones en `CONVENCIONES.md` (sección 3c).
- **Origen = centro del bloque.** `position` es el centro, no la esquina.
- **Tiempo desde la física.** `MovingObstacle` y `PulseTrap` acumulan el tiempo en `_physics_process` y calculan posición o fase a partir de él (sin `Tween` ni `Timer`), así el comportamiento es reproducible y `reset()` es trivial.

## Colores (placeholder)

| Estado | Color |
|---|---|
| Letal (estático, móvil, trampa activa) | Rojo `#D83232` |
| Trampa inactiva | Azul frío `#3A9BBF` con alfa 0,35 |
| Trampa en aviso | Parpadeo entre azul inactivo y blanco azulado `#C8E7EA` |

## Parámetros

### Por instancia (diseño de nivel)

| Nodo | Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|---|
| `Obstacle` (y derivados) | `size` | Vector2 | (48, 48) | px | Tamaño del bloque: cambia el polígono y el área letal |
| `Obstacle` (y derivados) | `cause` | StringName | `&"obstacle"` (`&"trap"` en la trampa) | — | Causa que recibe `Player.die` |
| `MovingObstacle` | `travel` | Vector2 | (120, 0) | px | Desplazamiento del extremo final respecto de la posición inicial |
| `MovingObstacle` | `config` | MovingObstacleConfig | `moving_obstacle_config.tres` | — | Parámetros de movimiento |
| `PulseTrap` | `config` | PulseTrapConfig | `pulse_trap_config.tres` | — | Parámetros del ciclo |

### `MovingObstacleConfig`

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Movimiento | `speed` | float | 60 | px/s | Velocidad *media* de desplazamiento | Con `ease_at_ends` el pico es 1,5 veces este valor. |
| Movimiento | `pause_at_ends` | float | 0,5 | s | Pausa en cada extremo | Es la ventana para cruzar: más pausa = más fácil |
| Movimiento | `ease_at_ends` | bool | true | — | Acelera y frena suave cerca de los extremos | `false` da un movimiento lineal, más legible pero más mecánico |
| Movimiento | `start_delay` | float | 0,0 | s | Espera antes de empezar | Usarlo para desfasar varias instancias; cada instancia necesita su propia config |

Duración del ciclo completo: `2 × (|travel| / speed + pause_at_ends)`.

### `PulseTrapConfig`

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Ciclo | `on_time` | float | 1,5 | s | Tiempo activa (letal) | Cuanto más largo, más hay que esperar; un `on_time` de 0 la deja siempre segura |
| Ciclo | `off_time` | float | 1,5 | s | Tiempo inactiva (segura), incluido el aviso | Debe dar tiempo de cruzar: considerar el ancho de la trampa y la velocidad del jugador |
| Ciclo | `warning_time` | float | 0,5 | s | Últimos segundos del `off_time` en que parpadea | Se recorta a `off_time`; 0 = sin aviso (más injusto) |
| Ciclo | `initial_offset` | float | 0,0 | s | Desfase del ciclo al empezar | Con 0 arranca inactiva. Con `off_time` arranca activa. Sirve para desincronizar varias trampas |

Orden del ciclo (duración `off_time + on_time`): inactiva → aviso (últimos `warning_time` de la fase segura) → activa → vuelve a empezar. Si `off_time` es 0 la trampa queda siempre activa.

## Señales

| Nodo | Señal | Cuándo se emite |
|---|---|---|
| `Obstacle` (y derivados) | `player_hit(cause: StringName)` | Un `Player` vivo tocó el obstáculo; justo antes de `Player.die(cause)` |
| `PulseTrap` | `activated()` | La trampa pasó a activa (letal) |
| `PulseTrap` | `deactivated()` | La trampa dejó de estar activa |

## API pública

| Función | Nodo | Descripción |
|---|---|---|
| `set_active(active: bool) -> void` | `Obstacle` | Activa o desactiva la detección (`monitoring`, diferido). Un obstáculo desactivado no mata. La trampa la usa internamente para cada fase |
| `reset() -> void` | `MovingObstacle` | Vuelve a la posición inicial y reinicia el ciclo (incluido `start_delay`) |
| `reset() -> void` | `PulseTrap` | Reinicia el ciclo desde el tiempo cero |

## Estructura de nodos

```
Obstacle (Area2D, capa 4, máscara 2)      script: obstacle.gd (@tool)
├── Body (Polygon2D, rojo)                se regenera al cambiar size
└── CollisionShape2D (RectangleShape2D)   una forma propia por instancia (local_to_scene)

MovingObstacle: escena heredada de Obstacle + moving_obstacle.gd + config
PulseTrap:      escena heredada de Obstacle + pulse_trap.gd + config, cause = &"trap", cuerpo azul translúcido
```

## Cómo colocarlos en un nivel

1. Arrastrar `Obstacle.tscn`, `MovingObstacle.tscn` o `PulseTrap.tscn` al nivel. La posición es el **centro** del bloque.
2. Ajustar `size` en el inspector: el polígono y el área letal cambian en el editor.
3. `MovingObstacle`: ajustar `travel`. En el editor se dibuja la trayectoria y el contorno del bloque en su posición final; la posición del nodo es el extremo inicial. Un recorrido de (0, -90) sube 90 px.
4. Para que dos instancias no vayan sincronizadas, darles configs distintas (Make Unique) y cambiar `start_delay` (móvil) o `initial_offset` (trampa). En `sandbox.tscn`, `MovingObstacle2` y `PulseTrap2` lo hacen con recursos propios.
5. Tener en cuenta el tamaño del jugador (16×24 px) al dimensionar pasillos; el margen correcto se descubre jugando.

## Cómo probarlos

1. Abrir `scenes/levels/sandbox.tscn` (F6). Los obstáculos están en el primer tramo (Y entre 480 y -320).
2. Tocar un obstáculo: aparece "GOLPEADO — pulsá R para reiniciar". R reinicia.
3. Editar `moving_obstacle_config.tres` o `pulse_trap_config.tres` con el juego cerrado y repetir. Anotar los cambios relevantes en `docs/TUNING_LOG.md`.
4. Cambiar `size` de una instancia en el editor y comprobar que el área letal coincide con el dibujo.

## Notas técnicas

- **Las subclases llaman a `super()` en `_ready`.** GDScript no ejecuta solo el `_ready` de la clase base; sin `super()` la subclase no conectaría `body_entered` ni armaría la forma.
- **La causa de la trampa** se fija en `PulseTrap.tscn` (`cause = &"trap"`): al instanciar una escena heredada Godot vuelve a aplicar el valor de la clase base, así que el `_init` del script solo cubre `PulseTrap.new()`.
- **Jugador dentro al activarse.** En pruebas headless, reactivar `monitoring` con un cuerpo ya superpuesto emite `body_entered` en el frame siguiente. Aun así, mientras está activa la trampa revisa `get_overlapping_bodies()` cada tick como red de seguridad; es idempotente.
- **Movimiento calculado desde el tiempo, no integrado:** Un cambio de `speed` o `travel` en ejecución "salta" la posición; cambiar valores con el juego cerrado.
