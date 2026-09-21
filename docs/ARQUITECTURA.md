# Arquitectura — Escapa del Tentáculo

Documento vivo: se completa en cada paso del roadmap. Estado: **paso 6 completado** (game manager y ciclo de partida).

## Árbol de escenas

```
Sandbox (Node2D)                      scenes/levels/sandbox.tscn (escena de prueba: columna alta)
│                                     script: level_controller.gd (LevelController; habla con el autoload GameManager)
├── ScrollCamera (Camera2D)           scenes/camera/ScrollCamera.tscn
│   └── ScreenBounds (StaticBody2D)   límites laterales y superior, se mueven con la cámara
│       └── LeftShape, RightShape, TopShape
├── GoalDoor (Area2D, capa 5, máscara 2)  scenes/goal/Door.tscn (puerta de meta, cerca de la cima)
│   └── Body (Polygon2D), Handle, CollisionShape2D
├── Player (CharacterBody2D)          scenes/player/Player.tscn
│   └── Body, CollisionShape2D, ThrustIndicator
├── Tentacle (Node2D)                 scenes/tentacle/Tentacle.tscn (export: camera)
│   ├── BodyPolygon (Polygon2D)
│   └── KillZone (Area2D, capa 4, máscara 2) → CollisionShape2D
├── DebugOverlay (CanvasLayer)        scenes/ui/DebugOverlay.tscn
│   └── Label
├── CaughtLayer (CanvasLayer)         mensaje de derrota (temporal)
│   └── CaughtLabel (Label)
├── Obstacle1, Obstacle2 (Area2D, capa 3, máscara 2)               scenes/obstacles/Obstacle.tscn
├── MovingObstacle1, MovingObstacle2 (Area2D, capa 3, máscara 2)   scenes/obstacles/MovingObstacle.tscn
├── PulseTrap1, PulseTrap2 (Area2D, capa 3, máscara 2)             scenes/obstacles/PulseTrap.tscn
│   └── Solid (StaticBody2D, capa 1)                               sólido mientras la trampa es segura
├── FuelTank1..4 (Area2D, capa 6, máscara 2)                       scenes/pickups/FuelTank.tscn
│   └── Body (Polygon2D), Detail, CollisionShape2D
├── FuelLedge (StaticBody2D, capa 1)                               plataforma del tanque alto
└── Floor / Ceiling / StartPlatform / Platform1..N (StaticBody2D, capa 1)
```

## Señales

Regla: señales hacia arriba, llamadas hacia abajo.

| Emisor | Señal | Receptor | Efecto |
|---|---|---|---|
| Player | `fuel_changed(current, maximum)` | _(nadie todavía; lo usará la UI)_ | Combustible cambió |
| Player | `fuel_depleted()` / `fuel_refilled()` | _(nadie todavía)_ | Combustible vacío / recuperado |
| Player | `thrust_started()` / `thrust_stopped()` | _(nadie todavía)_ | Feedback de propulsión |
| Player | `jumped()` | _(nadie todavía)_ | Saltó |
| Player | `died(cause)` | `LevelController` | Llama a `GameManager.notify_player_died(cause)`. Causas: `&"tentacle"`, `&"fell"`, `&"obstacle"`, `&"trap"` |
| Player | `won()` | _(nadie todavía)_ | El jugador ganó (`Player.win()`); desde ahí `is_alive()` es `false` |
| Door | `player_reached()` | `LevelController` | Un jugador vivo llegó a la puerta. El controlador llama a `GameManager.notify_goal_reached()`. La puerta no llama a `Player` |
| GameManager | `state_changed(new, old)` | `LevelController` | En `WON`: `Player.win()`, detiene el scroll y muestra "ESCAPASTE". En `LOST`: detiene el scroll y muestra el mensaje según la causa |
| GameManager | `run_started(seed)` / `run_won()` / `run_lost(cause)` | _(nadie todavía; lo usarán UI y audio)_ | Hitos de la partida |
| ScrollCamera | `scroll_started()` | _(nadie todavía)_ | La cámara empezó a subir |
| ScrollCamera | `scroll_stopped()` | _(nadie todavía)_ | La cámara dejó de subir |
| Obstacle (y derivados) | `player_hit(cause)` | _(nadie todavía)_ | Un jugador vivo tocó el obstáculo. Además el obstáculo llama a `Player.die(cause)`, que emite `died` |
| FuelTank | `collected(amount)` | _(nadie todavía; lo usará la UI/feedback)_ | Un jugador recogió el tanque. Además el tanque llama a `Player.add_fuel(amount)` |
| PulseTrap | `activated()` / `deactivated()` | _(nadie todavía)_ | La trampa pasó a activa / dejó de estarlo |
| Tentacle | `player_caught(cause)` | _(nadie todavía)_ | El tentáculo atrapó al jugador. Además llama a `Player.die(cause)`, que emite `died` |

## Autoloads

| Nombre | Script | Qué hace |
|---|---|---|
| `GameManager` | `scripts/managers/game_manager.gd` | Estado de la partida (`READY`, `PLAYING`, `WON`, `LOST`), seed y causa de derrota; señales de fin de partida; reinicio con R. No conoce nodos de la escena. Ver `docs/mecanicas/game-manager.md` |

## Flujo de una partida

1. Arranca el nivel (`sandbox.tscn`): `LevelController` conecta `Player.died` y `Door.player_reached` con el `GameManager` y llama a `GameManager.start_run()` (estado `PLAYING`). La cámara espera `start_delay` y empieza a subir; el tentáculo sube pegado al borde inferior.
2. El jugador propulsa, camina o salta para subir y esquivar.
3. **Derrota:** quien lo mata (tentáculo, caída, obstáculo, trampa) llama a `Player.die(cause)` → `died(cause)` → `GameManager.notify_player_died(cause)` → estado `LOST` → `LevelController` detiene el scroll y muestra el mensaje según la causa.
4. **Victoria:** `Door.player_reached` → `GameManager.notify_goal_reached()` → estado `WON` → `LevelController` llama a `Player.win()`, detiene el scroll y muestra "ESCAPASTE". Tras ganar, `is_alive()` es `false`, así que los peligros no lo afectan; además el manager ignora cualquier notificación fuera de `PLAYING`.
5. `restart` (R), escuchada por el `GameManager`, recarga la escena en cualquier momento (estado `READY`); el nivel vuelve a llamar a `start_run()`.
