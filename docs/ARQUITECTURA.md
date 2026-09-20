# Arquitectura — Escapa del Tentáculo

Documento vivo: se completa en cada paso del roadmap. Estado: **paso 2 completado**.

## Árbol de escenas

```
Sandbox (Node2D)                      scenes/levels/sandbox.tscn (escena de prueba: columna alta)
├── ScrollCamera (Camera2D)           scenes/camera/ScrollCamera.tscn
│   └── ScreenBounds (StaticBody2D)   límites laterales y superior, se mueven con la cámara
│       └── LeftShape, RightShape, TopShape
├── Player (CharacterBody2D)          scenes/player/Player.tscn
│   └── Body, CollisionShape2D, ThrustIndicator
├── DebugOverlay (CanvasLayer)        scenes/ui/DebugOverlay.tscn
│   └── Label
└── Floor / Ceiling / Platform1..N (StaticBody2D, capa 1)
```

## Señales

Regla: señales hacia arriba, llamadas hacia abajo.

| Emisor | Señal | Receptor | Efecto |
|---|---|---|---|
| Player | `fuel_changed(current, maximum)` | _(nadie todavía; lo usará la UI)_ | Combustible cambió |
| Player | `fuel_depleted()` / `fuel_refilled()` | _(nadie todavía)_ | Combustible vacío / recuperado |
| Player | `thrust_started()` / `thrust_stopped()` | _(nadie todavía)_ | Feedback de propulsión |
| Player | `jumped()` | _(nadie todavía)_ | Saltó |
| Player | `died(cause)` | _(nadie todavía)_ | Murió |
| ScrollCamera | `scroll_started()` | _(nadie todavía)_ | La cámara empezó a subir |
| ScrollCamera | `scroll_stopped()` | _(nadie todavía)_ | La cámara dejó de subir |

## Autoloads

Ninguno por ahora. El game manager (paso 6 del roadmap) será el primero.

## Flujo de una partida

_Se completa cuando exista el ciclo de partida. Hasta el paso 3, el reinicio es temporal: `sandbox_controller.gd` recarga la escena con la acción `restart`._
