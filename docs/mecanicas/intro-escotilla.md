# Mecánica: intro de la escotilla

**Archivos:** `scenes/intro/Hatch.tscn` + `scripts/intro/hatch.gd` (`Hatch`), `scripts/intro/intro_director.gd` (`IntroDirector`), `scripts/intro/intro_config.gd` (`IntroConfig`), `resources/configs/intro_config.tres`. Toca además `ScrollCamera.shake`, `Player.set_frozen`, `Tentacle.set_active`, `LevelController.play_intro` y `LevelBuilder.get_hatch_position`.
**Estado:** paso 8d (escotilla, golpes y gas). La ruptura, el lanzamiento del jugador y la entrada del tentáculo son el paso 8e y todavía no existen: al terminar los golpes la partida arranca como siempre.

## Propósito

Darle contexto al arranque: al pulsar JUGAR el astronauta todavía no está en escena. Se ve una escotilla en el piso y algo enorme golpea desde abajo tres veces, cada vez más fuerte, con gas que se escapa por las rendijas. Después empieza la partida.

## Línea de tiempo (valores de `IntroConfig` por defecto)

| t (s) | Qué pasa |
|---|---|
| 0.0 | Termina el fundido del título (`TitleMenu.faded_out`) y `Main` llama a `LevelController.play_intro()`. Se ve el nivel quieto, la escotilla cerrada, **sin tentáculo ni jugador** |
| 0.6 | Golpe 1 (fuerza ×1): vibración de cámara de 8 px, escotilla sacudida y algo abombada, ráfaga de gas |
| 1.6 | Golpe 2 (fuerza ×1,3): 10,4 px |
| 2.6 | Golpe 3 (fuerza ×1,69): 13,5 px |
| 3.3 | Termina la pausa posterior (`pre_break_pause`) y se llama a `LevelController.begin()`: estado `PLAYING`, HUD visible, tentáculo activo, jugador visible en el spawn, la cámara empieza a contar `start_delay` |

Fórmulas: golpe *i* (desde 0) ocurre en `first_hit_delay + i × hit_interval`; su fuerza es `hit_escalation ^ i`; la secuencia termina `pre_break_pause` s después del último golpe.

## Qué se mueve y qué no durante la intro

El nivel está en pausa (`process_mode = DISABLED` en la raíz, el mismo mecanismo del título). Solo se mueven:

- La **escotilla** y su gas: `Hatch` corre con `PROCESS_MODE_ALWAYS`.
- La **vibración de cámara**: un `Tween` creado desde el `SceneTree` (no depende de la pausa del nodo) que solo cambia `Camera2D.offset`. **No** toca `global_position`, así que no afecta al scroll, al tentáculo, a las paredes ni a `get_visible_rect()` / `get_bottom_y()`.
- El `IntroDirector`, también `ALWAYS`, que espera con `SceneTree.create_timer`.

Quedan quietos la cámara (posición), el tentáculo (además oculto e inofensivo), el jugador (congelado y oculto), los obstáculos móviles y las trampas. El `GameManager` sigue en `READY` toda la intro, por lo que **R no hace nada** (ya ignoraba R en ese estado; no se agregó código).

## Cuándo NO se reproduce

La intro solo corre si alguien llama a `LevelController.play_intro()` (hoy, solo `Main` al pulsar JUGAR). En los demás casos el nivel arranca con `autostart = true` y sin intro:

- **R** (`Main` reconstruye el nivel), **`Level.tscn` con F6** y **`sandbox.tscn`**.
- La escotilla queda ya **rota** (`set_broken(true)`), el tentáculo activo desde el primer frame y el jugador aparece en el `PlayerSpawn` como antes (no se lo lanza). `sandbox.tscn` no tiene escotilla.

## Configuración (`IntroConfig`, `resources/configs/intro_config.tres`)

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Golpes | `hit_count` | 3 | — | Cantidad de golpes antes de la ruptura |
| Golpes | `first_hit_delay` | 0.6 | s | Espera entre el fin del fundido y el primer golpe |
| Golpes | `hit_interval` | 1.0 | s | Tiempo entre golpes consecutivos |
| Golpes | `pre_break_pause` | 0.7 | s | Pausa entre el último golpe y el paso siguiente (por ahora `begin()`) |
| Vibración | `shake_amplitude` | 8.0 | px | Amplitud de la vibración del primer golpe |
| Vibración | `shake_duration` | 0.35 | s | Duración de cada vibración |
| Vibración | `hit_escalation` | 1.3 | × | Multiplicador de fuerza de cada golpe respecto del anterior |
| Gas | `gas_amount` | 24 | partículas | Partículas por ráfaga (golpe base; se multiplica por la fuerza del golpe) |
| Gas | `gas_lifetime` | 0.9 | s | Vida de cada partícula |
| Gas | `gas_speed` | 90.0 | px/s | Velocidad de salida del gas |

Los valores son de prueba (no se anotan en `TUNING_LOG.md`). `Level.tscn` referencia el `.tres` en `LevelController.intro_config`; el nivel se lo pasa a la escotilla (`Hatch.config`) y al director.

## Nodos de `Hatch`

```
Hatch (Node2D, ALWAYS)           origen = centro del borde superior del piso
├── Visual (Node2D)              se sacude con cada golpe
│   ├── Frame (Polygon2D)        marco, blanco azulado #C8E7EA, 128×32 px
│   ├── Hole (Polygon2D)         hueco oscuro #050609; solo visible cuando está rota
│   ├── Glow (Polygon2D)         brillo rojo #D83232; su opacidad sube con cada golpe
│   ├── LeafLeft / LeafRight     hojas azul frío #3A9BBF; se arquean con cada golpe y se abren al romperse
└── GasParticles (CPUParticles2D)  una sola ráfaga (one_shot), sin textura, blanco azulado con alfa
```

Se ubica en el `HatchAnchor` (Marker2D) del segmento de inicio (`SegmentStart.tscn`, centro del borde superior del piso: (180, −20) local, o sea (180, 620) en el nivel) mediante `LevelBuilder.get_hatch_position()`. En `Level.tscn` está entre la cámara y el jugador: se dibuja sobre el piso y bajo el jugador. Todos los colores y medidas visuales son `const` en `hatch.gd`.

## API

| Elemento | Descripción |
|---|---|
| `Hatch.hit(strength: float)` | Golpe: sacude, abomba un poco más, intensifica el brillo y suelta una ráfaga de `gas_amount × strength` partículas. Ignorado si está rota |
| `Hatch.set_broken(broken: bool)` | Estado final sin animación (`true` = rota; `false` = cerrada, sin golpes) |
| `Hatch.is_broken()`, `Hatch.get_hit_count()` | Consultas |
| `Hatch.get_launch_position() -> Vector2` | Centro superior de la escotilla (de ahí saldrá el jugador en el paso 8e) |
| `IntroDirector.play(hatch, camera, player, tentacle)` | Reproduce la secuencia. Tras cada espera comprueba `is_inside_tree()` |
| `IntroDirector.hit(index)` | Señal, una por golpe (`index` desde 0) |
| `IntroDirector.finished` | Señal, al terminar la secuencia. `LevelController` responde con `begin()` |
| `ScrollCamera.shake(amplitude, duration)` | Vibra `offset` con magnitud decreciente hasta dejarlo exactamente en `Vector2.ZERO`. Una llamada nueva pisa la anterior; `reset()` la cancela |
| `Player.set_frozen(frozen: bool)` | `true`: oculta cuerpo e indicador, detiene su física y desactiva la colisión. `reset()` lo descongela |
| `Tentacle.set_active(active: bool)` | `false`: lo oculta, apaga `KillZone.monitoring`, el chequeo de caída y la animación. Estado inicial: activo |
| `LevelController.play_intro()` | Empieza la intro (con `autostart = false`). Sin escotilla o sin `intro_config` empieza directo. `begin()` sigue siendo idempotente y **siempre** deja el tentáculo activo y al jugador descongelado |

Las señales del director suben hacia `LevelController`; el director llama hacia abajo a `Hatch`, `ScrollCamera`, `Player` y `Tentacle`.

## Cómo probarla

1. F5: se ve el nivel con una escotilla abajo, sin tentáculo ni jugador; nada se mueve.
2. JUGAR: tras el fundido, tres vibraciones de cámara, cada una con una ráfaga de gas y más fuerte que la anterior. Durante la intro R no hace nada.
3. Al terminar, el juego arranca como siempre (jugador en el spawn, tentáculo abajo, HUD).
4. R en plena partida, `Level.tscn` y `sandbox.tscn` con F6: sin intro.

## Cómo ajustar el "feel"

Todo se cambia en `resources/configs/intro_config.tres` desde el inspector: ritmo (`first_hit_delay`, `hit_interval`, `pre_break_pause`), fuerza (`shake_amplitude`, `hit_escalation`, `shake_duration`) y gas (`gas_amount`, `gas_lifetime`, `gas_speed`). Con `hit_escalation = 1` todos los golpes son iguales; con `hit_count` distinto de 3 cambia la cantidad de golpes.
