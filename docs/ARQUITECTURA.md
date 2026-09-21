# Arquitectura — Escapa del Tentáculo

Documento vivo: se completa en cada paso del roadmap. Estado: **paso 8d completado** (intro de la escotilla: golpes y gas; falta la ruptura, paso 8e).

## Árbol de escenas

La escena principal es `scenes/main/Main.tscn` (título sobre el nivel):

```
Main (Node)                           script: scripts/main/main.gd
├── LevelHolder (Node)                aquí vive la instancia de Level.tscn (autostart = false hasta pulsar JUGAR)
└── TitleLayer (CanvasLayer, capa 95)
    └── TitleMenu (Control)           scenes/ui/TitleMenu.tscn; se elimina tras el fundido
```

Hay dos niveles jugables. `scenes/levels/Level.tscn` (nivel por segmentos, el principal):

```
Level (Node2D)                        script: level_controller.gd
├── LevelBuilder (Node2D)             script: level_builder.gd, config = level_config.tres
│   └── SegmentStart, Segment.., SegmentEnd (LevelSegment)   escenas de scenes/levels/segments/, agregadas al iniciar
├── ScrollCamera
├── Hatch (Node2D, ALWAYS)             scenes/intro/Hatch.tscn; escotilla de la intro, en el HatchAnchor del segmento de inicio
│   └── Visual (Frame, Hole, Glow, LeafLeft, LeafRight), GasParticles
├── Player, Tentacle, DebugOverlay (muestra la seed)
├── IntroDirector (Node, ALWAYS)       creado por LevelController en play_intro(); vive mientras dura la intro
├── Hud (CanvasLayer, capa 80)         scenes/ui/Hud.tscn; barra de combustible y progreso (export: player)
├── CaughtLayer (capa 90)
```

Y `sandbox.tscn` (columna fija de prueba):

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
├── Hud (CanvasLayer, capa 80)        scenes/ui/Hud.tscn (export: player)
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
| Player | `fuel_changed(current, maximum)` | `Hud` | Actualiza la barra de combustible |
| Player | `fuel_depleted()` / `fuel_refilled()` | `Hud` | La barra pasa a roja / vuelve a naranja |
| Player | `thrust_started()` / `thrust_stopped()` | _(nadie todavía)_ | Feedback de propulsión |
| Player | `jumped()` | _(nadie todavía)_ | Saltó |
| Player | `died(cause)` | `LevelController` | Llama a `GameManager.notify_player_died(cause)`. Causas: `&"tentacle"`, `&"fell"`, `&"obstacle"`, `&"trap"` |
| Player | `won()` | _(nadie todavía)_ | El jugador ganó (`Player.win()`); desde ahí `is_alive()` es `false` |
| Door | `player_reached()` | `LevelController` | Un jugador vivo llegó a la puerta. El controlador llama a `GameManager.notify_goal_reached()`. La puerta no llama a `Player` |
| GameManager | `state_changed(new, old)` | `LevelController` | En `WON`: `Player.win()`, detiene el scroll y muestra "ESCAPASTE". En `LOST`: detiene el scroll y muestra el mensaje según la causa |
| GameManager | `restart_requested()` | `Main` | Reconstruye el `Level` (sin título). Si nadie está conectado (`Level.tscn` o sandbox solos), el manager recarga la escena |
| TitleMenu | `play_pressed()` / `faded_out()` | `Main` | `faded_out`: elimina el menú y llama a `LevelController.play_intro()` |
| IntroDirector | `hit(index)` | _(nadie todavía; lo usará el audio)_ | Un golpe de la intro (`index` desde 0) |
| IntroDirector | `finished()` | `LevelController` | Termina la intro: llama a `begin()` |
| GameManager | `run_started(seed)` / `run_won()` / `run_lost(cause)` | _(nadie todavía; lo usarán UI y audio)_ | Hitos de la partida |
| ScrollCamera | `scroll_started()` | _(nadie todavía)_ | La cámara empezó a subir |
| ScrollCamera | `scroll_stopped()` | _(nadie todavía)_ | La cámara dejó de subir |
| Obstacle (y derivados) | `player_hit(cause)` | _(nadie todavía)_ | Un jugador vivo tocó el obstáculo. Además el obstáculo llama a `Player.die(cause)`, que emite `died` |
| FuelTank | `collected(amount)` | _(nadie todavía; lo usará la UI/feedback)_ | Un jugador recogió el tanque. Además el tanque llama a `Player.add_fuel(amount)` |
| PulseTrap | `activated()` / `deactivated()` | _(nadie todavía)_ | La trampa pasó a activa / dejó de estarlo |
| LevelBuilder | `level_built(level_seed)` | _(nadie todavía)_ | Se terminó de armar el nivel |
| Tentacle | `player_caught(cause)` | _(nadie todavía)_ | El tentáculo atrapó al jugador. Además llama a `Player.die(cause)`, que emite `died` |

## Autoloads

| Nombre | Script | Qué hace |
|---|---|---|
| `GameManager` | `scripts/managers/game_manager.gd` | Estado de la partida (`READY`, `PLAYING`, `WON`, `LOST`), seed y causa de derrota; señales de fin de partida; reinicio con R. No conoce nodos de la escena. Ver `docs/mecanicas/game-manager.md` |

## Flujo de una partida

0. **Título (solo con `Main`):** `Main` instancia `Level.tscn` con `autostart = false` (armado y en pausa, `GameManager` en `READY`; escotilla cerrada, tentáculo inactivo y jugador congelado) y encima el `TitleMenu`. Al pulsar JUGAR el menú se disuelve y `Main` llama a `LevelController.play_intro()`. Ver `docs/mecanicas/pantalla-titulo.md`.
0a. **Intro (solo con `Main`):** `LevelController.play_intro()` crea un `IntroDirector` que, con el nivel aún en pausa, llama tres veces a `ScrollCamera.shake()` y `Hatch.hit()` (vibración de cámara y gas). Al terminar emite `finished` y el nivel llama a `begin()`, que activa el tentáculo, descongela al jugador, reanuda el nivel y llama a `start_run()`. R no hace nada mientras dura (estado `READY`). Sin `Main` (F6, sandbox) o tras R no hay intro: `autostart = true`, escotilla ya rota. Ver `docs/mecanicas/intro-escotilla.md`.
0b. **HUD:** el `Hud` (capa 80) queda oculto mientras el nivel está en pausa y `begin()` lo muestra. `LevelController` le fija el rango de progreso (Y del spawn y de la puerta). Ver `docs/mecanicas/hud.md`.
1. Arranca el nivel (`Level.tscn`; con `autostart = true`, el valor por defecto, `begin()` se llama solo): `LevelController` arma el nivel con `LevelBuilder.build()` (segmentos por seed), ubica al jugador en el `PlayerSpawn`, fija el tope de la cámara con `ScrollCamera.set_stop_y()`, conecta `Player.died` y `Door.player_reached` (la del segmento final) con el `GameManager` y llama a `GameManager.start_run(seed)` (estado `PLAYING`). En `sandbox.tscn` no hay `LevelBuilder`: usa su nodo `GoalDoor` y seed 0. La cámara espera `start_delay` y empieza a subir; el tentáculo sube pegado al borde inferior.
2. El jugador propulsa, camina o salta para subir y esquivar.
3. **Derrota:** quien lo mata (tentáculo, caída, obstáculo, trampa) llama a `Player.die(cause)` → `died(cause)` → `GameManager.notify_player_died(cause)` → estado `LOST` → `LevelController` detiene el scroll y muestra el mensaje según la causa.
4. **Victoria:** `Door.player_reached` → `GameManager.notify_goal_reached()` → estado `WON` → `LevelController` llama a `Player.win()`, detiene el scroll y muestra "ESCAPASTE". Tras ganar, `is_alive()` es `false`, así que los peligros no lo afectan; además el manager ignora cualquier notificación fuera de `PLAYING`.
5. `restart` (R), escuchada por el `GameManager` (salvo en `READY`), pasa a `READY` y emite `restart_requested`. Con `Main`, este reconstruye solo el `Level` (sin volver al título). Sin `Main` (F6 sobre `Level.tscn` o sandbox) nadie escucha la señal y el manager recarga la escena. En ambos casos el nivel llama a `start_run()` y, con `seed` = 0, es un nivel nuevo.
