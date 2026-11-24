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
| 3.3 | **Ruptura** (`pre_break_pause` tras el último golpe): vibración fuerte de cámara (16 px, 0,6 s), ráfaga grande de gas (80 partículas), 6 fragmentos despedidos y las hojas se abren con rebote (tag `break`, 0,41 s; la luz roja hace un pico y queda media). En ese mismo instante el jugador **aparece en el centro superior de la escotilla** con `velocity.y = −560` (`launch_speed`) y **sin control** durante 0,5 s (`control_lock_time`). Empieza la partida: `LevelController` reanuda el nivel, estado `PLAYING`, HUD visible. La cámara empieza a subir 2 s después (su `start_delay`, sin cambios) |
| 3.8 | Vuelve el control al jugador (ya subió ~256 px) |
| 4.8 | `tentacle_entry_delay` (1,5 s) tras la ruptura: el tentáculo empieza a entrar desde debajo de la pantalla y es letal donde esté su borde superior |
| 5.8 | `tentacle_entry_duration` (1 s): el tentáculo llegó a su posición normal y sigue como siempre |

Fórmulas: golpe *i* (desde 0) en `first_hit_delay + i × hit_interval`; fuerza `hit_escalation ^ i`; ruptura `pre_break_pause` s tras el último golpe; el tentáculo empieza a entrar `tentacle_entry_delay` s después de la ruptura y termina `tentacle_entry_duration` s más tarde.

### El vuelo del jugador

Medido por simulación con los valores de prueba actuales de `player_config.tres` y `launch_speed` = 520 px/s: el jugador sube ~393 px sobre la escotilla antes de empezar a caer (con 560 subía ~456 px). Se bajó de 560 a 520 al pasar el inicio a 640 px de alto (fase 0), para que el vuelo termine dentro del segmento de inicio. La altura teórica es `launch_speed² / (2 × (drag + gravedad))`. Al recuperar el control colisiona y se mueve como siempre. Si cambian la gravedad o el drag, cambian estas distancias: recalibrar `launch_speed` / `control_lock_time`.

### El segmento de inicio (pasillo del vuelo)

La escotilla está **centrada** (x = 180). Para que el jugador pueda volar sin chocar, cada segmento de inicio (`SegmentStart01`–`SegmentStart10`, se sortea uno por partida) mide 640 px de alto, como todo segmento, y tiene un **pasillo central libre de x 132 a 228 de punta a punta**, sin plataformas ni paredes: las plataformas alternan a los costados y hay un tanque en tres de ellas. El `PlayerSpawn` (usado solo cuando no hay intro, por ejemplo `Level.tscn` con F6) está sobre la plataforma más baja. Si se crea o rediseña un inicio hay que mantener el pasillo libre por encima de la escotilla.

### La cámara sigue al jugador durante el vuelo

El vuelo pasa por encima de la pantalla inicial (~640 px de altura con los valores por defecto). Desde el lanzamiento el director llama a `ScrollCamera.follow_up(player, camera_follow_margin)`: la cámara sube lo necesario para que el jugador nunca quede a menos de `camera_follow_margin` px del borde superior (solo sube, respeta el tope del nivel y no cambia el scroll normal, que sigue en paralelo). La cámara lo suelta al llegar al punto más alto del vuelo (con el control ya recuperado), pasados `camera_follow_max_time` s, o si el jugador muere o gana. El tentáculo, anclado a la cámara, entra desde el borde inferior ya desplazado. Con esto el jugador **nunca sale de la vista** (verificado por simulación cuadro a cuadro).

### Red de seguridad de caída

Entre la ruptura y la entrada del tentáculo (o si este no llega a entrar) el jugador puede caer bajo la pantalla: el `Tentacle` inactivo sigue vigilando la caída (`Tentacle.set_fall_watch(true)`, que el director enciende en la ruptura) y, si el jugador queda por debajo del borde inferior de la cámara más `screen_bottom_margin`, muere con `&"fell"`, como siempre. Si el jugador gana o pierde **antes** de que el tentáculo entre, el director no lo hace entrar.

## Qué se mueve y qué no durante la intro

El nivel está en pausa (`process_mode = DISABLED` en la raíz, el mismo mecanismo del título). Solo se mueven:

- La **escotilla** y su gas: `Hatch` corre con `PROCESS_MODE_ALWAYS`.
- La **vibración de cámara**: un `Tween` creado desde el `SceneTree` (no depende de la pausa del nodo) que solo cambia `Camera2D.offset`. **No** toca `global_position`, así que no afecta al scroll, al tentáculo, a las paredes ni a `get_visible_rect()` / `get_bottom_y()`.
- El `IntroDirector`, también `ALWAYS`, que espera con `SceneTree.create_timer`.

Quedan quietos la cámara (posición), el tentáculo (además oculto e inofensivo), el jugador (congelado y oculto), los obstáculos móviles y las trampas. Esto vale hasta la ruptura: ahí el nivel se reanuda. El `GameManager` sigue en `READY` hasta la ruptura, por lo que **R no hace nada** (ya ignoraba R en ese estado; no se agregó código).

## Cuándo NO se reproduce

La intro corre cuando alguien llama a `LevelController.play_intro()`: `Main` al pulsar JUGAR y **también con cada R** (el nivel nuevo arranca en pausa y repite la intro, sin título). En `Level.tscn` solo (F6) no hay nadie que la llame: el nivel arranca con `autostart = true` y sin intro:

- **`Level.tscn` con F6** (R recarga la escena, igual que antes).
- La escotilla queda ya **rota** (`set_broken(true)`), el tentáculo activo desde el primer frame y el jugador aparece en el `PlayerSpawn` como antes (no se lo lanza). 

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
| Ruptura | `break_debris_count` | 6 | — | Fragmentos que salen despedidos |
| Lanzamiento | `launch_speed` | 520.0 | px/s | Velocidad vertical inicial (hacia arriba) |
| Lanzamiento | `control_lock_time` | 0.5 | s | Tiempo sin control tras el lanzamiento |
| Cámara | `camera_follow_margin` | 120.0 | px | Distancia mínima entre el jugador y el borde superior de la pantalla durante el vuelo |
| Cámara | `camera_follow_max_time` | 3.0 | s | Tiempo máximo de seguimiento tras el lanzamiento |
| Tentáculo | `tentacle_entry_delay` | 1.5 | s | Espera entre la ruptura y el inicio de la entrada |
| Tentáculo | `tentacle_entry_duration` | 1.0 | s | Duración de la subida del tentáculo hasta su posición |

Los valores son de prueba (no se anotan en `TUNING_LOG.md`). `Level.tscn` referencia el `.tres` en `LevelController.intro_config`; el nivel se lo pasa a la escotilla (`Hatch.config`) y al director.

## Nodos de `Hatch`

```
Hatch (Node2D, ALWAYS)           origen = centro del borde superior del piso
├── Halo (Sprite2D, en código)   resplandor rojo aditivo detrás de la escotilla
├── Light (PointLight2D)         luz roja #CD1417 que ilumina el entorno; energía según el estado
├── Visual (Node2D)              se sacude con cada golpe
│   ├── Sprite (SheetSprite)     hoja `hatch` con relieve; maneja la animación (tags del JSON de Aseprite)
│   └── Emissive (Sprite2D)      `hatch_emissive`, sin sombreado; sigue el cuadro de Sprite
├── Beam (Sprite2D, en código)   haz rojo aditivo que sale de la rendija hacia arriba
└── GasPuffA/B/C (CPUParticles2D)  tres emisores one_shot, uno por forma de bocanada (`gas_puff_a/b/c`, 4 cuadros animados en la vida de la partícula, sin escalar); `gas_amount` y `break_gas_amount` se reparten entre los tres
```

**Estados (arte: `docs/arte/piso-y-escotilla.md`):** cerrada `closed` (loop); golpe *k* → `hit_k` y después `idle_k` (loop; desde el 4.º golpe se repite `hit_3`); `break_open()` → `break`, `break_finished` al terminar y queda en `broken` (loop); `set_broken(true/false)` → `broken` o `closed` sin animación. Las hojas ya no se rotan por código; la sacudida (`Visual.position`), el gas y los fragmentos (un cuadro al azar de `hatch_debris` cada uno) siguen en código. El jugador sale desde `FRAME_TOP` = −15 (cara superior del marco).

**Luz:** tres capas que siguen el estado (cerrada → cada golpe → ruptura → rota), con valores en `IntroConfig`, grupo "Luz de la escotilla":
- **Luz del entorno** (`Light`, `PointLight2D`): ilumina piso, paredes y astronauta. Energía 0,15 cerrada, +0,35 por golpe, pico 2,5 en la ruptura y 1,0 rota; radio 170 px, altura 90 px.
- **Haz** (`Beam`, creado en código, aditivo y sin sombreado): cono rojo que se escapa por la rendija hacia arriba; no hay con la escotilla cerrada, suma 0,2 por golpe, pico en la ruptura y queda en 0,5.
- **Halo** (`Halo`, detrás de la escotilla, aditivo y sin sombreado): resplandor rojo de 240×130 px; casi nada cerrada (0,06), +0,12 por golpe, pico en la ruptura y queda en 0,6. De ahí sale el astronauta.
- Cada golpe hace un destello (`hatch_hit_flash`, +60 %) y vuelve a su nivel en `hatch_light_fade` (0,3 s). Rota, halo y haz respiran (`hatch_breath_amount`, `hatch_breath_speed`). Halo y haz no los oscurece la nave oscura.

**Piso:** el `Floor` de cada `SegmentStartNN` dibuja el piso en 3/4 con `ShipFloor` (`scripts/levels/ship_floor.gd`, módulos de `floor_ship`, `floor_seed` propio por segmento, franjas de peligro a los lados de `hatch_x`); la colisión (banda de 360×20) no cambió.

Se ubica en el `HatchAnchor` (Marker2D) del segmento de inicio (`SegmentStartNN.tscn`, centro del borde superior del piso: (180, −20) local, o sea (180, 620) en el nivel) mediante `LevelBuilder.get_hatch_position()`. En `Level.tscn` está entre la cámara y el jugador: se dibuja sobre el piso y bajo el jugador. Las medidas visuales son `const` en `hatch.gd`.

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
| `ScrollCamera.follow_up(target, top_margin)` / `stop_following()` | La cámara sube lo necesario para mantener a `target` a `top_margin` px del borde superior. El director la usa durante el vuelo |
| `LevelController.play_intro()` | Empieza la intro (con `autostart = false`). Sin escotilla o sin `intro_config` empieza directo. `begin()` (empezar sin intro) es idempotente y deja el tentáculo activo y al jugador descongelado; en la intro la partida empieza en la ruptura con el tentáculo aún inactivo |

Las señales del director suben hacia `LevelController`; el director llama hacia abajo a `Hatch`, `ScrollCamera`, `Player` y `Tentacle`.

## Cómo probarla

1. F5: se ve el nivel con una escotilla abajo, sin tentáculo ni jugador; nada se mueve.
2. JUGAR: tras el fundido, tres vibraciones de cámara, cada una con una ráfaga de gas y más fuerte que la anterior. Durante la intro R no hace nada.
3. Tercer golpe: la escotilla se rompe con vibración fuerte y una nube grande de gas; el jugador sale disparado hacia arriba, no responde ~0,5 s y después se puede controlar. Aparece el HUD y, ~1,5 s después, el tentáculo sube desde abajo.
4. Si no mueves al jugador, cae y muere (por el tentáculo, o por caída si aún no entró).
5. R en plena partida: repite la intro (escotilla cerrada, sin tentáculo ni jugador, tres golpes...). R durante la intro no hace nada. `Level.tscn` con F6: sin intro (escotilla ya rota, jugador en el spawn, tentáculo desde el primer frame).

## Cómo ajustar el "feel"

Todo se cambia en `resources/configs/intro_config.tres` desde el inspector: ritmo (`first_hit_delay`, `hit_interval`, `pre_break_pause`), fuerza (`shake_amplitude`, `hit_escalation`, `shake_duration`) y gas (`gas_amount`, `gas_lifetime`, `gas_speed`). Para más o menos altura de vuelo, `launch_speed` y `control_lock_time` (ver "El vuelo del jugador"); `tentacle_entry_delay` y `tentacle_entry_duration` regulan cuánto respiro tiene el jugador. Con `hit_escalation = 1` todos los golpes son iguales; con `hit_count` distinto de 3 cambia la cantidad de golpes.
