# Arquitectura — Escapa del Tentáculo

Documento vivo: se completa en cada paso del roadmap. Estado: **pasos 8d y 8e completados** (intro de la escotilla: golpes, gas, ruptura, lanzamiento del jugador y entrada del tentáculo).

## Árbol de escenas

La escena principal es `scenes/main/Main.tscn` (hub y, al subir el ascensor, la partida):

```
Main (Node)                           script: scripts/main/main.gd
├── LevelHolder (Node)                acá se instancia Level.tscn al arrancar la partida
├── HubHolder (Node)                  acá se instancia scenes/hub/Hub.tscn (menú navegable)
└── FadeLayer (CanvasLayer, capa 95)
    └── Fade (ColorRect)              fundido desde negro al arrancar la partida
```

Hay dos niveles jugables. `scenes/levels/Level.tscn` (nivel por segmentos, el principal):

```
Level (Node2D)                        script: level_controller.gd
├── Lighting (CanvasModulate)         script: level_lighting.gd; oscuridad de los tiers con dark_ambient (la nave)
├── Background (CanvasLayer, capa −10) script: level_background.gd (fondo por tier)
│   └── ShipBackground (Node2D)       scenes/levels/ShipBackground.tscn; pozo de la nave en parallax (tier con background_ship)
├── LevelBuilder (Node2D)             script: level_builder.gd, config = level_config.tres
│   └── SegmentStartNN, Segment.., SegmentFinal01 (LevelSegment)   escenas de scenes/levels/segments/, agregadas al iniciar
│       └── Walls (TileMapLayer)       nave e inicio: scenes/levels/WallsShip.tscn (Emissive, Detalle, Dano, Lights); espacio, alien y final: scenes/levels/Walls.tscn (ver mecanicas/paredes.md)
├── ScrollCamera
├── Hatch (Node2D, ALWAYS)             scenes/intro/Hatch.tscn; escotilla de la intro, en el HatchAnchor del segmento de inicio
│   └── Light, Visual (Sprite, Emissive), GasPuffA/B/C
├── Player, Tentacle, DebugOverlay (muestra la seed)
├── IntroDirector (Node, ALWAYS)       creado por LevelController en play_intro(); vive mientras dura la intro
├── Hud (CanvasLayer, capa 80)         scenes/ui/Hud.tscn; barra de combustible y progreso (export: player)
├── CaughtLayer (capa 90)
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
| GameManager | `restart_requested()` | `Main` | Reconstruye el `Level` (sin título). Si nadie está conectado (`Level.tscn` solo, con F6), el manager recarga la escena |
| Hub | `launch_finished()` | `Main` | Terminó la subida del ascensor (pantalla en negro): libera el hub, instancia el `Level` y llama a `play_intro()` |
| HubDoor | `entered()` | `Hub` | El jugador entró por la puerta (fundido y se abre el mercado) |
| HubElevator | `launch_started()` / `ride_finished()` | `Hub` | Sube la plataforma con el jugador / terminó la subida |
| IntroDirector | `hit(index)` | _(nadie todavía; lo usará el audio)_ | Un golpe de la intro (`index` desde 0) |
| IntroDirector | `broken()` | `LevelController` | La escotilla se rompió y el jugador ya salió disparado: empieza la partida (`begin` sin activar el tentáculo) |
| IntroDirector | `finished()` | `LevelController` | Empezó a entrar el tentáculo (o se saltó): libera al director |
| GameManager | `run_started(seed)` / `run_won()` / `run_lost(cause)` | `PlayerProgress` | Hitos de la partida: al ganar o perder se guardan las monedas juntadas |
| Repairer | `collected(kind, healed)` | `RepairerSpawner` (lo crea el `LevelBuilder`) | Un jugador vivo recogió un reparador (llave, venda o botiquín) |
| Coin | `collected(value)` | `CoinSpawner` (la conecta a `PlayerProgress.add_run_coins`) | Un jugador vivo recogió la moneda |
| PlayerProgress | `run_coins_changed(total)` / `coins_changed(total)` | `Hud` / `Market` | Contador de la partida y monedas guardadas |
| Market | `closed()` | `Hub` | Se cerró el mercado (tras la animación `exit`): el jugador vuelve delante de la puerta |
| Player | `hit_points_changed(current, maximum)` / `hit_taken(cause)` / `respawned(at)` | `Hud` (corazones) | Puntos de golpe y reaparición (mejoras Vidas) |
| ScrollCamera | `scroll_started()` | _(nadie todavía)_ | La cámara empezó a subir |
| ScrollCamera | `scroll_stopped()` | _(nadie todavía)_ | La cámara dejó de subir |
| FuelTank | `collected(amount)` | _(nadie todavía; lo usará la UI/feedback)_ | Un jugador recogió el tanque. Además el tanque llama a `Player.add_fuel(amount)` |
| Platform (`PROJECTILE`) | `launched()` / `exploded()` / `vanished()` | _(nadie todavía)_ | El proyectil se disparó / explotó / desapareció. Ver `docs/mecanicas/plataforma-proyectil.md` |
| LevelBuilder | `level_built(level_seed)` | _(nadie todavía)_ | Se terminó de armar el nivel |
| Tentacle | `player_caught(cause)` | _(nadie todavía)_ | El tentáculo atrapó al jugador. Además llama a `Player.die(cause)`, que emite `died` |

## Autoloads

| Nombre | Script | Qué hace |
|---|---|---|
| `GameManager` | `scripts/managers/game_manager.gd` | Estado de la partida (`READY`, `PLAYING`, `WON`, `LOST`), seed y causa de derrota; señales de fin de partida; reinicio con R. No conoce nodos de la escena. Ver `docs/mecanicas/game-manager.md` |
| `PlayerProgress` | `scripts/progress/player_progress.gd` | Monedas, nodos del árbol de talentos comprados y su guardado en `user://progress.cfg`; aplica las mejoras al `Player` por encima de `player_config.tres`. Ver `docs/mecanicas/progreso-mercado.md` |
| `RunRecords` | `scripts/managers/run_records.gd` | Récords guardados en `user://records.cfg` (mejor progreso). Funciones estáticas. Ver `docs/mecanicas/hud.md` |
| `TierEvent` | `scripts/levels/tier_event.gd` | Momento de historia al entrar a un tier (sacudida, destello, silueta del alien), en los segmentos de entrada. Ver `docs/mecanicas/tier-espacio.md` |
| `WindowBreach` | `scripts/levels/window_breach.gd` | Ventanal que rompe el alien en la salida de la nave; descompresión que saca al jugador. Ver `docs/mecanicas/tier-espacio.md` |
| `Asteroid` | `scripts/levels/asteroid.gd` | Asteroide del espacio: capa de tiles propia que flota y gira (cuerpos cinemáticos) |
| `Repairer` | `scripts/pickups/repairer.gd`, `scenes/pickups/Repairer.tscn` (+ `scripts/levels/repairer_spawner.gd`) | Reparador: llave (cura 1), venda (cura 2) y botiquín (cura todo + escudo) |
| `SpeedBoost` | `scripts/pickups/speed_boost.gd` (+ `speed_boost_config.gd`) | Recogible de impulso de velocidad (tier 2) |
| `HullDebris` | `scripts/levels/hull_debris.gd` | Fragmento letal despedido por un `TierEvent` (causa `&"debris"`) |
| `SpaceProjectile` | `scripts/hazards/space_projectile.gd` | Meteoro o cometa del tier 2: avisa, cruza la pantalla y mata (causas `&"meteor"`, `&"comet"`). Ver `docs/mecanicas/obstaculos-espacio.md` |
| `LevelBackground` | `scripts/levels/level_background.gd` | Fondo del nivel (color, pozo de la nave y estrellas con parallax) por tier; nodo `Background` de `Level.tscn` |

### Arte de la nave (brief 07)

| Clase | Script | Qué hace |
|---|---|---|
| `TentacleSea` | `scripts/tentacle/tentacle_sea.gd` (+ `tentacle_sea_config.gd`) | Mar de tentáculos del perseguidor en la nave. Ver `docs/mecanicas/tentaculo.md` |
| `EmissiveMirror` | `scripts/levels/emissive_mirror.gd` | Capa emisiva de una capa de paredes: copia sus celdas con el tileset `*_emissive` sin sombreado |
| `WallLights` | `scripts/levels/wall_lights.gd` | Luces de grietas y alarmas de las paredes de la nave (las alarmas siguen el cuadro del tile con `AlarmClock`) |
| `AlarmClock` (autoload) | `scripts/managers/alarm_clock.gd` | Reloj compartido entre los tiles de alarma y sus luces |
| `PlatformSkin` | `scripts/platforms/platform_skin.gd` | Módulos de sprites de las plataformas de la nave, animación por estado y propulsores |
| `PickupSkin` | `scripts/pickups/pickup_skin.gd` | Aura, ítem y emisivo de los recogibles; `idle` y `collect` |
| `ShipBackground` | `scripts/levels/ship_background.gd` (+ `ship_background_config.gd`, `shaders/background_layer.gdshader`) | Fondo en parallax de la nave. Ver `docs/arte/fondo-nave.md` |
| `ShipFloor` | `scripts/levels/ship_floor.gd` | Piso 3/4 de los segmentos de inicio |
| `SheetSprite` | `scripts/visual/sheet_sprite.gd` | Sprite que reproduce tags de una hoja de Aseprite con duración por cuadro (escotilla, ventanal) |
| `LevelLighting` | `scripts/levels/level_lighting.gd` (+ `lighting_config.gd`) | Oscuridad por tier y fábrica de luces. Ver `docs/mecanicas/iluminacion.md` |

## Flujo de una partida

0. **Hub (solo con `Main`):** `Main` instancia el `Hub` (`GameManager` en `READY`). El jugador camina y vuela por la nave intacta; por la puerta derecha entra al mercado. Al quedarse ~1 s sobre el ascensor, este sube con él; al terminar la subida (pantalla en negro) `Main` libera el hub, instancia `Level.tscn` con `autostart = false` y llama a `LevelController.play_intro()`. Ver `docs/mecanicas/hub.md`.
0a. **Intro (solo con `Main`):** `LevelController.play_intro()` crea un `IntroDirector` que, con el nivel aún en pausa, llama tres veces a `ScrollCamera.shake()` y `Hatch.hit()` (vibración de cámara y gas). Tras el último golpe la escotilla se rompe (`Hatch.break_open`), la cámara vibra más fuerte, el jugador aparece en la escotilla y sale disparado (`Player.launch`, Input bloqueado 0,5 s; la cámara lo sigue con `ScrollCamera.follow_up` durante el vuelo) y el director emite `broken`: el nivel se reanuda y llama a `start_run()` (`PLAYING`, HUD, scroll). El tentáculo sigue inactivo, pero vigila la caída (`set_fall_watch`); tras `tentacle_entry_delay` s el director lo hace entrar (`Tentacle.enter`), salvo que la partida ya haya terminado. R no hace nada hasta la ruptura (estado `READY`); desde la ruptura reinicia como siempre. Con R, `Main` reconstruye el nivel (`autostart = false`) y llama a `play_intro()`: repite la intro. Sin `Main` (F6 sobre `Level.tscn`) no hay intro: `autostart = true`, escotilla ya rota. Ver `docs/mecanicas/intro-escotilla.md`.
0b. **HUD:** el `Hud` (capa 80) queda oculto mientras el nivel está en pausa y `begin()` lo muestra. `LevelController` le fija el rango de progreso (Y del spawn y de la puerta). Ver `docs/mecanicas/hud.md`.
1. Arranca el nivel (`Level.tscn`; con `autostart = true`, el valor por defecto, `begin()` se llama solo): `LevelController` arma el nivel con `LevelBuilder.build()` (segmentos por seed), ubica al jugador en el `PlayerSpawn`, fija el tope de la cámara con `ScrollCamera.set_stop_y()`, conecta `Player.died` y `Door.player_reached` (la del segmento final) con el `GameManager` y llama a `GameManager.start_run(seed)` (estado `PLAYING`). La cámara espera `start_delay` y empieza a seguir al jugador (sube y baja con él); el tentáculo sube por su cuenta y puede quedar fuera de pantalla.
2. El jugador propulsa, camina o salta para subir y esquivar.
3. **Derrota:** quien lo mata (tentáculo, caída, obstáculo, trampa) llama a `Player.die(cause)` → `died(cause)` → `GameManager.notify_player_died(cause)` → estado `LOST` → `LevelController` detiene el scroll y muestra el mensaje según la causa.
4. **Victoria:** `Door.player_reached` → `GameManager.notify_goal_reached()` → estado `WON` → `LevelController` llama a `Player.win()`, detiene el scroll y muestra "ESCAPASTE". Tras ganar, `is_alive()` es `false`, así que los peligros no lo afectan; además el manager ignora cualquier notificación fuera de `PLAYING`.
4b. **Monedas:** al terminar la partida (ganar, perder, R) `PlayerProgress` suma las monedas juntadas a las guardadas. Las mejoras se compran en el mercado del hub (`Hub` → `Ui/Market`) y se aplican al crear el `Player`.
4c. **Volver al hub:** con la partida terminada, Escape (`ui_cancel`) hace que `Main` pida `GameManager.restart()` marcándolo "al hub": libera el nivel y muestra un `Hub` nuevo. Durante la partida Escape no hace nada.
5. `restart` (R), escuchada por el `GameManager` (salvo en `READY`), pasa a `READY` y emite `restart_requested`. Con `Main`, este reconstruye solo el `Level` (sin volver al hub). Sin `Main` (F6 sobre `Level.tscn`) nadie escucha la señal y el manager recarga la escena. En ambos casos el nivel llama a `start_run()` y, con `seed` = 0, es un nivel nuevo.
