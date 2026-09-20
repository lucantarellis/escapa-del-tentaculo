# Arquitectura — Escapa del Tentáculo

Documento vivo: se completa en cada paso del roadmap. Estado: **paso 3 completado**.

## Árbol de escenas

```
Sandbox (Node2D)                      scenes/levels/sandbox.tscn (escena de prueba: columna alta)
│                                     script: sandbox_controller.gd (TEMPORAL, lo reemplaza el game manager)
├── ScrollCamera (Camera2D)           scenes/camera/ScrollCamera.tscn
│   └── ScreenBounds (StaticBody2D)   límites laterales y superior, se mueven con la cámara
│       └── LeftShape, RightShape, TopShape
├── Player (CharacterBody2D)          scenes/player/Player.tscn
│   └── Body, CollisionShape2D, ThrustIndicator
├── Tentacle (Node2D)                 scenes/tentacle/Tentacle.tscn (export: camera)
│   ├── BodyPolygon (Polygon2D)
│   └── KillZone (Area2D, capa 4, máscara 2) → CollisionShape2D
├── DebugOverlay (CanvasLayer)        scenes/ui/DebugOverlay.tscn
│   └── Label
├── CaughtLayer (CanvasLayer)         mensaje de derrota (temporal)
│   └── CaughtLabel (Label)
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
| Player | `died(cause)` | _(nadie todavía; lo usará el game manager)_ | Murió (causa `&"tentacle"` o `&"fell"`) |
| ScrollCamera | `scroll_started()` | _(nadie todavía)_ | La cámara empezó a subir |
| ScrollCamera | `scroll_stopped()` | _(nadie todavía)_ | La cámara dejó de subir |
| Tentacle | `player_caught(cause)` | `sandbox_controller.gd` (temporal) | Muestra "CAPTURADO" y detiene el scroll. Además el tentáculo llama a `Player.die(cause)` |

## Autoloads

Ninguno por ahora. El game manager (paso 6 del roadmap) será el primero.

## Flujo de una partida

_Se completa cuando exista el ciclo de partida. Hasta el paso 6, el ciclo es temporal y vive en `sandbox_controller.gd`:_

1. Arranca `sandbox.tscn`: la cámara espera `start_delay` y empieza a subir; el tentáculo sube pegado al borde inferior.
2. El jugador propulsa, camina o salta para subir y esquivar.
3. Si el tentáculo lo toca o cae bajo la pantalla: `Tentacle` emite `player_caught(cause)` y llama a `Player.die(cause)` (que emite `died`). El controlador muestra el mensaje y pausa el scroll.
4. `restart` (R) recarga la escena en cualquier momento.
