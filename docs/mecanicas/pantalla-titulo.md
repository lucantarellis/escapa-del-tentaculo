# Mecánica: pantalla de título y transición al juego

**Archivos:** `scenes/main/Main.tscn` + `scripts/main/main.gd` (`Main`), `scenes/ui/TitleMenu.tscn` + `scripts/ui/title_menu.gd` (`TitleMenu`), `scripts/ui/title_config.gd` (`TitleConfig`), `resources/configs/title_config.tres`.
**Depende de:** `LevelController.autostart` / `begin()`, `GameManager.restart_requested`.

## Propósito

Que al abrir el juego (F5) se vea el título con un botón grande de jugar **sobre el nivel ya armado y quieto**; al pulsarlo el menú se disuelve y la partida arranca. R reinicia directo al juego, sin volver al título.

## Flujo

1. **Abrir el juego.** `Main` (escena principal, `run/main_scene`) instancia `Level.tscn` con `autostart = false`: el nivel se arma (segmentos, jugador en el spawn, tope de cámara) pero queda **en pausa** (`process_mode = DISABLED` en su nodo raíz: no corren `_process`, física, timers ni tweens, así que no se mueven ni la cámara, ni el tentáculo, ni obstáculos y trampas). El `GameManager` sigue en `READY`. Encima se dibuja el `TitleMenu`. El overlay F3 sigue funcionando (se marca `PROCESS_MODE_ALWAYS` mientras el nivel está en pausa).
2. **Pulsar JUGAR** (clic, Enter o Espacio; el botón tiene el foco al abrir). El botón se deshabilita (no se puede pulsar dos veces), pasa `fade_delay`, y el menú baja su opacidad a 0 en `fade_duration`. Al terminar emite `faded_out`.
3. **Arranque.** `Main` elimina el menú y llama a `LevelController.play_intro()`: se reproduce la intro de la escotilla (tres golpes de cámara con gas; el nivel sigue en pausa y el `GameManager` en `READY`). En la ruptura de la escotilla el propio nivel empieza la partida (el equivalente a `LevelController.begin()`, sin activar todavía el tentáculo, que entra unos segundos después): se reanuda (`PROCESS_MODE_INHERIT`) y se llama a `GameManager.start_run(seed)` (`PLAYING`). La cuenta de `start_delay` de la cámara empieza recién ahí. Ver `docs/mecanicas/intro-escotilla.md`.
4. **Reinicio (R).** `GameManager.restart()` pasa a `READY` y emite `restart_requested`. `Main` está conectado: saca el nivel actual del árbol, lo libera e instancia uno nuevo con `autostart = true` (seed nueva si `level_config.seed` = 0). Sin menú ni fundido. R **no hace nada** mientras el estado es `READY` (título).
5. **Sin `Main`.** `Level.tscn` (F6) y `sandbox.tscn` no tienen a nadie conectado a `restart_requested`: `restart()` recarga la escena como antes y arrancan solos (`autostart = true` por defecto).

## Árbol de nodos de `Main`

```
Main (Node)                          scripts/main/main.gd
├── LevelHolder (Node)               aquí vive la instancia de Level.tscn
└── TitleLayer (CanvasLayer, capa 95)   encima del juego (HUD 80, mensaje de fin 90), debajo del overlay F3 (100)
    └── TitleMenu (Control)          scenes/ui/TitleMenu.tscn
        ├── Dim (ColorRect)          fondo oscuro semitransparente, para leer el título sin tapar el nivel
        └── Center → Box (VBox) → TitleLabel (Label) + PlayButton (Button)
```

## Configuración (`TitleConfig`, `resources/configs/title_config.tres`)

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Transición | `fade_duration` | 0.8 | s | Duración del fundido del menú a transparente |
| Transición | `fade_delay` | 0.0 | s | Espera entre pulsar el botón y empezar el fundido |
| Textos | `title_text` | "ESCAPA DEL TENTÁCULO" | — | Título del juego |
| Textos | `play_text` | "JUGAR" | — | Texto del botón |

Los textos no son gameplay; se dejan editables desde el inspector. Colores, tamaños de fuente y del botón son `const` visuales en `title_menu.gd`.

## Señales y API

| Elemento | Descripción |
|---|---|
| `TitleMenu.play_pressed` | Se pulsó el botón (una sola vez) |
| `TitleMenu.faded_out` | Terminó el fundido. El menú no se elimina solo: lo hace `Main` |
| `LevelController.autostart` (`@export`) | `false` = armar el nivel pero dejarlo en pausa. Asignar **antes** de `add_child` |
| `LevelController.play_intro()` | Reproduce la intro de la escotilla y al terminar llama a `begin()`. Lo usa `Main` tras el fundido |
| `LevelController.begin()` | Reanuda el nivel y llama a `GameManager.start_run()`. Idempotente. Deja el tentáculo activo y al jugador descongelado (empezar sin intro) |
| `GameManager.restart_requested` | Se pidió reiniciar; si hay alguien conectado, el manager no recarga la escena |

## Cómo probarlo

1. F5: se ve el título y el botón sobre el nivel; nada se mueve.
2. Clic (o Enter/Espacio) en JUGAR: el menú se disuelve, la escotilla golpea tres veces con gas y luego la partida arranca y la cámara empieza a subir. Pulsar varias veces rápido no rompe nada.
3. R durante la partida, tras ganar y tras perder: nivel nuevo, sin título. R en el título no hace nada.
4. `Level.tscn` y `sandbox.tscn` con F6: arrancan solos y R los recarga.
