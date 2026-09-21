# Mecánica: game manager y ciclo de partida

**Archivos:** `scripts/managers/game_manager.gd` (autoload `GameManager`), `scripts/levels/level_controller.gd` (`LevelController`, script raíz de los niveles).
**Depende de:** `Player.died`, `Door.player_reached`, `Player.win()`, `ScrollCamera.set_scrolling()`.

## Propósito

Un solo lugar que sabe en qué estado está la partida (jugando, ganó, perdió), para que el nivel, la UI y, más adelante, el puntaje no tengan que preguntárselo a nodos sueltos.

## Qué es un autoload y por qué se eligió

Un **autoload** es un script que Godot carga una vez al iniciar el juego, queda accesible por su nombre desde cualquier script (`GameManager.get_state()`) y **no se destruye** cuando se recarga la escena. Se eligió porque el reinicio (R) recarga la escena entera: un nodo dentro de ella perdería su estado. Se registra en `project.godot`, sección `[autoload]` (`GameManager="*res://scripts/managers/game_manager.gd"`; el `*` significa que se instancia como nodo). El script vive en `scripts/managers/` junto a los demás scripts; la carpeta raíz `autoload/` queda reservada para escenas autoload si alguna vez hacen falta.

El manager **no conoce nodos de la escena** (no hace `get_node` a nada): solo guarda estado y emite señales. El nivel le avisa lo que pasa y reacciona a sus señales.

## Máquina de estados

Estados: `READY`, `PLAYING`, `WON`, `LOST`.

| Desde | Evento | Hacia | Señales |
|---|---|---|---|
| cualquiera | `start_run(seed)` | `PLAYING` | `state_changed`, `run_started(seed)` |
| `PLAYING` | `notify_player_died(cause)` | `LOST` | `state_changed`, `run_lost(cause)` |
| `PLAYING` | `notify_goal_reached()` | `WON` | `state_changed`, `run_won()` |
| cualquiera | `restart()` | `READY` (recarga la escena solo si nadie escucha `restart_requested`) | `state_changed`, `restart_requested` |
| `READY` | tecla R (`_unhandled_input`) | _(se ignora: en el título no hay nada que reiniciar)_ | — |
| `READY`, `WON`, `LOST` | `notify_player_died` / `notify_goal_reached` | _(se ignora)_ | — |

Consecuencia: morir después de ganar (o ganar después de morir) no cambia el resultado. `state_changed` no se emite si el estado no cambia.

## Señales

| Señal | Cuándo se emite |
|---|---|
| `run_started(run_seed: int)` | Empezó la partida |
| `run_won()` | El jugador ganó |
| `run_lost(cause: StringName)` | El jugador perdió, con la causa (`&"tentacle"`, `&"fell"`, `&"obstacle"`, `&"trap"`) |
| `state_changed(new_state, old_state)` | Cambió el estado |
| `restart_requested()` | Se pidió reiniciar. Si hay conexiones (por ejemplo `Main`), ellas reconstruyen el nivel y el manager **no** recarga la escena |

## API pública

| Función | Descripción |
|---|---|
| `start_run(run_seed: int = 0) -> void` | Pasa a `PLAYING` y guarda la seed. Lo llama el nivel al iniciar |
| `notify_player_died(cause: StringName) -> void` | Solo vale en `PLAYING` |
| `notify_goal_reached() -> void` | Solo vale en `PLAYING` |
| `restart() -> void` | Pasa a `READY` y emite `restart_requested`; solo si no hay ninguna conexión a esa señal recarga la escena actual. Se dispara con la acción `restart` (R) desde `_unhandled_input`, salvo en `READY` |
| `get_state() -> State` | Estado actual |
| `get_current_seed() -> int` | Seed de la partida actual (0 si el nivel no usa) |
| `get_last_death_cause() -> StringName` | Causa de la última derrota (`&""` si no hubo) |

## Cómo lo usa el nivel (`LevelController`)

Al iniciar (`_ready`):
1. Conecta `Player.died` → `GameManager.notify_player_died` y `Door.player_reached` → `GameManager.notify_goal_reached`.
2. Escucha `GameManager.state_changed`.
3. Llama `begin()`, que llama a `GameManager.start_run()`. Si `autostart` es `false` (lo usa `Main` para el título), el nivel queda en pausa y `begin()` se llama después. Ver `docs/mecanicas/pantalla-titulo.md`.

Al cambiar el estado:
- `WON`: `Player.win()`, detiene el scroll y muestra "ESCAPASTE — pulsá R para reiniciar".
- `LOST`: detiene el scroll y muestra el texto según la causa (constante `DEATH_TEXTS`: tentáculo/caída → "CAPTURADO", obstáculo/trampa → "GOLPEADO", otra → "PERDISTE"; todos terminan en "— pulsá R para reiniciar").

Como el manager sobrevive a la escena, el controlador suelta su conexión a `state_changed` en `_exit_tree` para no dejar conexiones a nodos ya liberados.

## Cómo reaccionar a un estado desde otra escena

Cualquier nodo (una UI, un sonido) puede hacer, en su `_ready`:

```gdscript
GameManager.run_won.connect(_on_run_won)
GameManager.run_lost.connect(_on_run_lost)
```

y desconectarse en `_exit_tree` si vive menos que el juego. Para consultar el estado sin esperar señales: `GameManager.get_state() == GameManager.State.PLAYING`.

## Cómo agregar puntaje más adelante

El puntaje se suma **en el manager, sin tocar el nivel**: agregar una variable `_score` y una función pública (por ejemplo `add_score(amount)`), reiniciarla en `start_run()`, emitir una señal `score_changed(score)` y, para fuentes de puntos nuevas (recoger un tanque, tiempo), conectarlas a `GameManager` desde el nivel o desde una escena de UI escuchando las señales que ya existen (`FuelTank.collected`, `run_won`). Al ser un autoload, el puntaje sobrevive al reinicio si se decide acumularlo entre partidas.

## Cómo probarlo

1. Ejecutar `scenes/levels/sandbox.tscn` (F6).
2. Perder por cada causa (tentáculo, caída, obstáculo, trampa) y comprobar el texto.
3. Ganar en la puerta y dejar que el tentáculo alcance al jugador: sigue "ESCAPASTE".
4. R reinicia en cualquier momento.
