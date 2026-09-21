# Mecánica: obstáculos

**Archivos:** `scripts/obstacles/obstacle.gd`, `moving_obstacle.gd`, `moving_obstacle_config.gd`, `pulse_trap.gd`, `pulse_trap_config.gd`; escenas `scenes/obstacles/Obstacle.tscn`, `MovingObstacle.tscn`, `PulseTrap.tscn`; configs `resources/configs/moving_obstacle_config.tres` y `pulse_trap_config.tres`.
**Derrota:** `LevelController` muestra el mensaje según la causa (ver `game-manager.md`).

## Propósito

Peligros que llenan el recorrido entre el jugador y la puerta. Hay tres, todos letales al contacto:

- **`Obstacle`**: bloque estático. Estrecha pasillos o bloquea zonas.
- **`MovingObstacle`**: bloque que va y viene entre dos puntos. Obliga a cronometrar el paso.
- **`PulseTrap`**: bloque que alterna entre seguro y letal, con un aviso antes de activarse. Mientras es seguro es **sólido**: el jugador puede apoyarse encima como en una plataforma, pero tiene que bajarse antes de que se active.

## Modelo en palabras simples

- **Son `Area2D`, no cuerpos físicos** (salvo la parte sólida de la trampa, ver abajo). Detectan al jugador (capa 3 `obstacles`, máscara 2 `player`) pero no lo empujan ni lo frenan: rozar un obstáculo no es rebotar, es morir. Por eso no hace falta ninguna lógica de choque en el jugador.
- **Qué mata.** Cuando un `Player` vivo entra en el área, el obstáculo emite `player_hit(cause)` y llama a `Player.die(cause)`, que emite `Player.died(cause)`. Un jugador ya muerto se ignora (no se emite dos veces).
- **La trampa es sólida mientras es segura.** Además del `Area2D` letal, `PulseTrap` tiene un hijo `Solid` (`StaticBody2D`, capa 1 `world`) con la misma forma. Está activo cuando la trampa está inactiva o en aviso, y se desactiva al activarse. Así el jugador puede caminar o aterrizar encima, y si sigue ahí cuando se activa, muere (cae dentro del área letal unos frames después).
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
| Trampa inactiva (sólida) | Azul frío `#3A9BBF` con alfa 0,35 |
| Trampa en aviso (sólida) | Parpadeo entre azul inactivo y blanco azulado `#C8E7EA` |

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
└── Solid (StaticBody2D, capa 1, máscara 0)      sólido mientras la trampa es segura
    └── CollisionShape2D (RectangleShape2D)      una forma propia por instancia
```

## Cómo colocarlos en un nivel

1. Arrastrar `Obstacle.tscn`, `MovingObstacle.tscn` o `PulseTrap.tscn` al nivel. La posición es el **centro** del bloque.
2. Ajustar `size` en el inspector: el polígono y el área letal cambian en el editor.
3. `MovingObstacle`: ajustar `travel`. En el editor se dibuja la trayectoria y el contorno del bloque en su posición final; la posición del nodo es el extremo inicial. Un recorrido de (0, -90) sube 90 px.
4. Para que dos instancias no vayan sincronizadas, darles configs distintas: duplicar el `.tres` en `resources/configs/`, asignarlo en `Config` y cambiar `start_delay` (móvil) o `initial_offset` (trampa). En `sandbox.tscn`, `MovingObstacle2` y `PulseTrap2` lo hacen con `moving_obstacle_vertical_config.tres` y `pulse_trap_offset_config.tres`.
5. Tener en cuenta el tamaño del jugador (16×24 px) al dimensionar pasillos; el margen correcto se descubre jugando.

## Instancias del sandbox

Para ver la config de una instancia: abrir `sandbox.tscn`, elegirla en el árbol de escena y mirar el inspector (grupo **Configuración → Config**, y **Recorrido → Travel** en las móviles). Haciendo clic en el recurso se abre el `.tres` que se edita.

| Nodo | Posición (centro) | Tamaño | Config | Diferencia |
|---|---|---|---|---|
| `Obstacle1` | (130, 400) | 260×24 | — | Estrecha el pasillo: deja 100 px a la derecha |
| `Obstacle2` | (80, 250) | 100×80 | — | Bloque grande |
| `MovingObstacle1` | (60, 90) | 40×20 | `moving_obstacle_config.tres` | Horizontal, `travel` (240, 0), empieza de inmediato, 60 px/s |
| `MovingObstacle2` | (170, -40) | 24×60 | `moving_obstacle_vertical_config.tres` | Vertical, `travel` (0, -90), espera 1 s (`start_delay`), 45 px/s |
| `PulseTrap1` | (100, -235) | 200×20 | `pulse_trap_config.tres` | Ancha, `initial_offset` 0: arranca inactiva |
| `PulseTrap2` | (150, -300) | 24×60 | `pulse_trap_offset_config.tres` | Angosta, `initial_offset` 1,5: arranca activa |

`MovingObstacle1` está en Y = 90 (visible al arrancar la partida); `MovingObstacle2` en Y = -40 aparece más arriba, cuando la cámara sube.

## Cómo probarlos

1. Abrir `scenes/levels/sandbox.tscn` (F6). Los obstáculos están en el primer tramo (Y entre 480 y -320).
2. Tocar un obstáculo: aparece "GOLPEADO — pulsá R para reiniciar". R reinicia.
3. Editar `moving_obstacle_config.tres`, `pulse_trap_config.tres` o los de las instancias con el juego cerrado y repetir. Los valores que se ajustan mientras se prueba son de prueba, no de balance: no se anotan en `docs/TUNING_LOG.md`.
4. Cambiar `size` de una instancia en el editor y comprobar que el área letal coincide con el dibujo.
5. Aterrizar sobre una `PulseTrap` inactiva: se puede caminar encima. Quedarse hasta que se active: muere.

## Notas técnicas

- **Las subclases llaman a `super()` en `_ready`.** GDScript no ejecuta solo el `_ready` de la clase base; sin `super()` la subclase no conectaría `body_entered` ni armaría la forma.
- **La causa de la trampa** se fija en `PulseTrap.tscn` (`cause = &"trap"`): al instanciar una escena heredada Godot vuelve a aplicar el valor de la clase base, así que el `_init` del script solo cubre `PulseTrap.new()`.
- **Jugador dentro al activarse.** En pruebas headless, reactivar `monitoring` con un cuerpo ya superpuesto emite `body_entered` en el frame siguiente. Aun así, mientras está activa la trampa revisa `get_overlapping_bodies()` cada tick como red de seguridad; es idempotente.
- **Movimiento calculado desde el tiempo, no integrado:** Un cambio de `speed` o `travel` en ejecución "salta" la posición; cambiar valores con el juego cerrado.
