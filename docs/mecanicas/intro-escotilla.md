# Mecánica: intro de la escotilla

**Archivos:** `scenes/intro/Hatch.tscn` + `scripts/intro/hatch.gd` (`Hatch`), `scripts/intro/intro_director.gd` (`IntroDirector`), `scripts/intro/intro_config.gd` (`IntroConfig`), `resources/configs/intro_config.tres`. Toca además `ScrollCamera.shake`, `Player.set_frozen` / `Player.launch`, `Tentacle.set_active` / `set_fall_watch` / `enter`, `LevelController.play_intro` y `LevelBuilder.get_hatch_position`.
**Estado:** pasos 8d (escotilla, golpes y gas) y 8e (ruptura, lanzamiento del jugador y entrada del tentáculo).

## Propósito

Darle contexto al arranque: al pulsar JUGAR el astronauta todavía no está en escena. Se ve una escotilla en el piso y algo enorme golpea desde abajo tres veces, cada vez más fuerte, con gas que se escapa por las rendijas. Al tercero la escotilla se rompe, el jugador sale disparado hacia arriba (vuela por el impulso del golpe), empieza la partida y, un rato después, el tentáculo entra desde abajo.

## Línea de tiempo (valores de `IntroConfig` por defecto)

Tiempos medidos desde el fin del fundido del título (`TitleMenu.faded_out`), cuando `Main` llama a `LevelController.play_intro()`.

| t (s) | Qué pasa |
|---|---|
| 0.0 | Se ve el nivel quieto, la escotilla cerrada, **sin tentáculo ni jugador**. Estado `READY` |
| 0.6 | Golpe 1 (fuerza ×1): vibración de cámara de 8 px, escotilla sacudida y algo abombada, ráfaga de gas |
| 1.6 | Golpe 2 (fuerza ×1,3): 10,4 px |
| 2.6 | Golpe 3 (fuerza ×1,69): 13,5 px |
| 3.3 | **Ruptura** (`pre_break_pause` tras el último golpe): vibración fuerte de cámara (16 px, 0,6 s), ráfaga grande de gas (80 partículas), 6 fragmentos despedidos y las hojas se abren en 0,35 s. En ese mismo instante el jugador **aparece en el centro superior de la escotilla** con `velocity.y = −400` (`launch_speed`) y **sin control** durante 0,5 s (`control_lock_time`). Empieza la partida: `LevelController` reanuda el nivel, estado `PLAYING`, HUD visible. La cámara empieza a subir 2 s después (su `start_delay`, sin cambios) |
| 3.8 | Vuelve el control al jugador (ya subió ~174 px) |
| 4.8 | `tentacle_entry_delay` (1,5 s) tras la ruptura: el tentáculo empieza a entrar desde debajo de la pantalla y es letal donde esté su borde superior |
| 5.8 | `tentacle_entry_duration` (1 s): el tentáculo llegó a su posición normal y sigue como siempre |

Fórmulas: golpe *i* (desde 0) en `first_hit_delay + i × hit_interval`; fuerza `hit_escalation ^ i`; ruptura `pre_break_pause` s tras el último golpe; el tentáculo empieza a entrar `tentacle_entry_delay` s después de la ruptura y termina `tentacle_entry_duration` s más tarde.

### El vuelo del jugador

Con los valores de prueba actuales de `player_config.tres` (gravedad con combustible 150 px/s², `coasting_drag` 90 px/s²), medido por simulación: sin tocar nada el jugador sube ~174 px hasta recuperar el control (a 0,5 s, con `vy` ≈ −276 px/s) y su inercia lo lleva a un máximo de ~258 px sobre la escotilla; después cae. Ojo: la caída es hacia el tentáculo, así que el jugador tiene que propulsar. Al recuperar el control colisiona y se mueve como siempre. Si cambian la gravedad o el drag, cambian estas distancias: recalibrar `launch_speed` / `control_lock_time`.

**Por qué la escotilla no está en el centro:** en el segmento de inicio hay una plataforma (`StartPlatform`, x 100–260) a solo ~36 px sobre el piso, en el centro. Lanzar al jugador desde x = 180 lo haría chocar enseguida. La escotilla está en x = 290 (`HatchAnchor` de `SegmentStart.tscn`), libre de esa plataforma; la siguiente plataforma sobre ella (x 200–320) está a ~350 px de altura, justo por encima del máximo del vuelo sin propulsar.

### Red de seguridad de caída

Entre la ruptura y la entrada del tentáculo (o si este no llega a entrar) el jugador puede caer bajo la pantalla: el `Tentacle` inactivo sigue vigilando la caída (`Tentacle.set_fall_watch(true)`, que el director enciende en la ruptura) y, si el jugador queda por debajo del borde inferior de la cámara más `screen_bottom_margin`, muere con `&"fell"`, como siempre. Si el jugador gana o pierde **antes** de que el tentáculo entre, el director no lo hace entrar.

## Qué se mueve y qué no durante la intro

El nivel está en pausa (`process_mode = DISABLED` en la raíz, el mismo mecanismo del título). Solo se mueven:

- La **escotilla** y su gas: `Hatch` corre con `PROCESS_MODE_ALWAYS`.
- La **vibración de cámara**: un `Tween` creado desde el `SceneTree` (no depende de la pausa del nodo) que solo cambia `Camera2D.offset`. **No** toca `global_position`, así que no afecta al scroll, al tentáculo, a las paredes ni a `get_visible_rect()` / `get_bottom_y()`.
- El `IntroDirector`, también `ALWAYS`, que espera con `SceneTree.create_timer`.

Quedan quietos la cámara (posición), el tentáculo (además oculto e inofensivo), el jugador (congelado y oculto), los obstáculos móviles y las trampas. Esto vale hasta la ruptura: ahí el nivel se reanuda. El `GameManager` sigue en `READY` hasta la ruptura, por lo que **R no hace nada** (ya ignoraba R en ese estado; no se agregó código).

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
| Golpes | `pre_break_pause` | 0.7 | s | Pausa entre el último golpe y la ruptura |
| Vibración | `shake_amplitude` | 8.0 | px | Amplitud de la vibración del primer golpe |
| Vibración | `shake_duration` | 0.35 | s | Duración de cada vibración |
| Vibración | `hit_escalation` | 1.3 | × | Multiplicador de fuerza de cada golpe respecto del anterior |
| Gas | `gas_amount` | 24 | partículas | Partículas por ráfaga (golpe base; se multiplica por la fuerza del golpe) |
| Gas | `gas_lifetime` | 0.9 | s | Vida de cada partícula |
| Gas | `gas_speed` | 90.0 | px/s | Velocidad de salida del gas |
| Ruptura | `break_shake_amplitude` | 16.0 | px | Amplitud de la vibración de la ruptura |
| Ruptura | `break_shake_duration` | 0.6 | s | Duración de esa vibración |
| Ruptura | `break_gas_amount` | 80 | partículas | Partículas de la ráfaga grande |
| Ruptura | `break_duration` | 0.35 | s | Duración de la apertura de las hojas |
| Ruptura | `break_debris_count` | 6 | — | Fragmentos que salen despedidos |
| Lanzamiento | `launch_speed` | 400.0 | px/s | Velocidad vertical inicial (hacia arriba) |
| Lanzamiento | `control_lock_time` | 0.5 | s | Tiempo sin control tras el lanzamiento |
| Tentáculo | `tentacle_entry_delay` | 1.5 | s | Espera entre la ruptura y el inicio de la entrada |
| Tentáculo | `tentacle_entry_duration` | 1.0 | s | Duración de la subida del tentáculo hasta su posición |

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

Se ubica en el `HatchAnchor` (Marker2D) del segmento de inicio (`SegmentStart.tscn`, centro del borde superior del piso: (290, −20) local, o sea (290, 620) en el nivel) mediante `LevelBuilder.get_hatch_position()`. En `Level.tscn` está entre la cámara y el jugador: se dibuja sobre el piso y bajo el jugador. Todos los colores y medidas visuales son `const` en `hatch.gd`.

## API

| Elemento | Descripción |
|---|---|
| `Hatch.break_open()` | Ruptura con animación: gas grande, fragmentos y hojas que se abren. `is_broken()` pasa a `true` de inmediato; emite `break_finished` al terminar la apertura |
| `Hatch.hit(strength: float)` | Golpe: sacude, abomba un poco más, intensifica el brillo y suelta una ráfaga de `gas_amount × strength` partículas. Ignorado si está rota |
| `Hatch.set_broken(broken: bool)` | Estado final sin animación (`true` = rota; `false` = cerrada, sin golpes) |
| `Hatch.is_broken()`, `Hatch.get_hit_count()` | Consultas |
| `Hatch.get_launch_position() -> Vector2` | Centro superior de la escotilla (de ahí sale el jugador) |
| `IntroDirector.play(hatch, camera, player, tentacle)` | Reproduce la secuencia. Tras cada espera comprueba `is_inside_tree()` |
| `IntroDirector.hit(index)` | Señal, una por golpe (`index` desde 0) |
| `IntroDirector.broken` | Señal, en el instante de la ruptura (jugador ya lanzado). `LevelController` responde empezando la partida (sin activar el tentáculo) |
| `IntroDirector.finished` | Señal, cuando el tentáculo empieza a entrar (o se saltea porque la partida ya terminó) |
| `ScrollCamera.shake(amplitude, duration)` | Vibra `offset` con magnitud decreciente hasta dejarlo exactamente en `Vector2.ZERO`. Una llamada nueva pisa la anterior; `reset()` la cancela |
| `Player.launch(launch_velocity: Vector2, control_lock: float)` | Descongela, asigna la velocidad y bloquea el Input `control_lock` s (inercia, gravedad y colisiones siguen). La cuenta corre en `_physics_process`; `reset()` la anula |
| `Player.set_frozen(frozen: bool)` | `true`: oculta cuerpo e indicador, detiene su física y desactiva la colisión. `reset()` lo descongela |
| `Tentacle.set_active(active: bool)` | `false`: lo oculta, apaga `KillZone.monitoring`, el chequeo de caída y la animación. Estado inicial: activo |
| `Tentacle.set_fall_watch(watch: bool)` | Con el tentáculo inactivo, sigue vigilando la caída bajo la pantalla (`&"fell"`) |
| `Tentacle.enter(duration: float)` | Lo activa y lo hace subir desde debajo de la pantalla hasta su posición en `duration` s (con un desfase interno que decae a 0; sigue anclado a la cámara). `reset()` lo cancela |
| `LevelController.play_intro()` | Empieza la intro (con `autostart = false`). Sin escotilla o sin `intro_config` empieza directo. `begin()` (empezar sin intro) es idempotente y deja el tentáculo activo y al jugador descongelado; en la intro la partida empieza en la ruptura con el tentáculo aún inactivo |

Las señales del director suben hacia `LevelController`; el director llama hacia abajo a `Hatch`, `ScrollCamera`, `Player` y `Tentacle`.

## Cómo probarla

1. F5: se ve el nivel con una escotilla abajo, sin tentáculo ni jugador; nada se mueve.
2. JUGAR: tras el fundido, tres vibraciones de cámara, cada una con una ráfaga de gas y más fuerte que la anterior. Durante la intro R no hace nada.
3. Tercer golpe: la escotilla se rompe con vibración fuerte y una nube grande de gas; el jugador sale disparado hacia arriba, no responde ~0,5 s y después se puede controlar. Aparece el HUD y, ~1,5 s después, el tentáculo sube desde abajo.
4. Si no mueves al jugador, cae y muere (por el tentáculo, o por caída si aún no entró).
5. R en plena partida, `Level.tscn` y `sandbox.tscn` con F6: sin intro (escotilla ya rota, jugador en el spawn, tentáculo desde el primer frame).

## Cómo ajustar el "feel"

Todo se cambia en `resources/configs/intro_config.tres` desde el inspector: ritmo (`first_hit_delay`, `hit_interval`, `pre_break_pause`), fuerza (`shake_amplitude`, `hit_escalation`, `shake_duration`) y gas (`gas_amount`, `gas_lifetime`, `gas_speed`). Para más o menos altura de vuelo, `launch_speed` y `control_lock_time` (ver "El vuelo del jugador"); `tentacle_entry_delay` y `tentacle_entry_duration` regulan cuánto respiro tiene el jugador. Con `hit_escalation = 1` todos los golpes son iguales; con `hit_count` distinto de 3 cambia la cantidad de golpes.
