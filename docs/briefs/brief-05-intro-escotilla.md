# Brief 05 — Intro de la escotilla (pasos 0, 8d y 8e) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork). No hace falta adjuntar nada: todo el contexto está acá y en `docs/` del repo (que Claude puede leer en la carpeta conectada).

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior (y, al detenerse la cámara en el final del nivel, sigue subiendo hasta cubrir la pantalla) y el jugador usa un jetpack con combustible limitado para esquivar obstáculos, recoger tanques y llegar a una puerta antes de que lo atrapen.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D. Viewport vertical **360×640** (ventana de PC a 1,5×).
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). **Rama base:** `main`. Trabaja LT con un socio, que **no toca nada hasta que esté el MVP**: no hay que avisarle de nada.
- **Estado del repo:** `main` incluye los briefs 01 a 04 (PR #1 a #4): mecánicas base, obstáculos y tanques, puerta + game manager + niveles por segmentos, y pantalla de título + HUD mínimo. Leer **antes de escribir código**: `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md` y `docs/mecanicas/*.md` (en especial `pantalla-titulo.md`, `game-manager.md`, `niveles-por-segmentos.md`, `jugador.md`, `scroll-camara.md`, `tentaculo.md` y `hud.md`).
- **Alcance de este brief:** una intro al pulsar JUGAR (pasos **8d** y **8e** del roadmap): el nivel se ve con una **escotilla** en la parte inferior (en lugar del tentáculo); la cámara vibra **tres veces** como golpes de algo gigante, cada golpe con **gas** que se escapa de la escotilla; al tercero la escotilla **se rompe**, el jugador (que estaba detrás) **sale disparado hacia arriba**, empieza la partida y **al rato aparece el tentáculo** como hoy. **Fuera de alcance:** arte final, audio (los golpes y el gas quedan sin sonido; el paso 9 los agregará), controles táctiles, puntaje, balance del resto del juego, pausa, saltar la intro con una tecla. Todo lo visual es placeholder (`Polygon2D`, `CPUParticles2D` sin textura, `ColorRect`).

## Qué necesita aportar LT

1. Pegar este brief en la conversación nueva. Nada más.
2. Carpeta del repo conectada a la sesión. `git` y `gh` deben poder operar (ver "Notas técnicas": Godot y `gh` ya están instalados en `.tools/`; el login de `gh` y el permiso de borrado se piden en cada conversación).
3. Jugar cada paso y responder la checklist con el formato `1. OK / 2. KO (motivo)`. **El "se siente bien" de la intro (ritmo, fuerza de los golpes, cantidad de gas, impulso del lanzamiento) es de LT**: los valores iniciales son de prueba y se ajustan desde el inspector.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- **La intro solo se reproduce al pulsar JUGAR** en el título. **R la salta**: el nivel nuevo arranca ya con la escotilla rota y el tentáculo activo, sin animaciones (ver "Propuestas de Claude" para el detalle). `Level.tscn` solo (F6) y `sandbox.tscn` tampoco la reproducen. *(LT.)*
- **Antes de la ruptura no se ve el tentáculo**: en el inicio se ve la escotilla en la parte inferior del nivel. *(LT.)*
- **Tres golpes**, cada uno = vibración de cámara + gas que escapa de la escotilla, "como si hubiera demasiada presión debajo". Al terminar el tercero la escotilla se rompe. *(LT.)*
- **El jugador está detrás de la escotilla**: durante los golpes no se ve; se supone que viene peleando con el tentáculo desde la habitación anterior. Al romperse la escotilla **se presenta**: aparece y sale volando hacia arriba con un impulso vertical. **El control vuelve al terminar el impulso**, tras un tiempo corto configurable. *(LT.)*
- **El juego empieza en la ruptura**: el scroll de la cámara arranca y el estado pasa a `PLAYING` en ese momento. **El tentáculo entra desde abajo tras un retraso configurable** y desde ahí actúa como hoy (letal, sube con la cámara). *(LT.)*
- **Tema:** todo valor de gameplay o de tiempo es variable exportada en un `Resource` de configuración (`resources/configs/*.tres`); lo puramente visual va como `const` con comentario `## ... Solo visual.` / `Estructural.`.
- **Balance:** se deja para cuando el MVP esté listo. Los valores de las configs son de prueba. **No anotar nada en `docs/TUNING_LOG.md`** (solo se usa para pruebas reales de balance, a pedido de LT).
- **Documentación obligatoria**: cualquier persona debe entender el código leyendo `docs/` y los comentarios.
- **Input:** no tocar el Input Map ni los controles. Los controles táctiles (paso 8c) se hacen al final.
- **Colores de placeholder:** rojo `#D83232` = letal, cian `#63D6C5` = recogible, naranja `#FF6B32` = objetivo/meta, azul frío `#3A9BBF` = plataformas, blanco azulado `#C8E7EA` = detalles. Paleta completa en `assets/palette.md`.
- **Propuestas de Claude (LT las validará jugando; si hay un problema, avisar):**
  - **Escotilla = escena propia** `scenes/intro/Hatch.tscn` + `scripts/intro/hatch.gd` (`class_name Hatch extends Node2D`): dos hojas de polígonos (azul frío) con marco (blanco azulado) y un brillo rojo tenue debajo que se hace más intenso con cada golpe. Estados: cerrada, golpeada (deformada/abombada un poco más con cada golpe), rota (hojas desplazadas, marco visible, hueco oscuro). Se ubica en el centro del piso del segmento de inicio.
  - **`IntroConfig`** (`scripts/intro/intro_config.gd`, `resources/configs/intro_config.tres`) con todos los tiempos y magnitudes (ver tabla en el paso 8d y 8e).
  - **Director de la intro:** `scripts/intro/intro_director.gd` (`class_name IntroDirector extends Node`) orquesta la secuencia llamando hacia abajo a `Hatch`, `ScrollCamera`, `Player` y `Tentacle`, y emite señales hacia arriba (`hit(index)`, `broken`, `finished`). Lo crea/usa `LevelController`. Como la secuencia usa `await`, después de cada espera comprobar `is_inside_tree()`: el nivel puede liberarse en el medio.
  - **Nivel pausado durante la intro:** se usa el mecanismo del brief 04 (`autostart = false`, `process_mode = DISABLED` en la raíz del nivel). Lo único que se mueve mientras dura la intro es la escotilla, el gas y la vibración de cámara: `Hatch` (y sus partículas) con `PROCESS_MODE_ALWAYS`; la vibración de cámara se implementa con un `Tween` creado desde el `SceneTree` (no queda pausado con el nivel) sobre `Camera2D.offset`, **sin tocar `global_position`**, así que no afecta al scroll, al tentáculo, a las paredes ni a `get_visible_rect()` / `get_bottom_y()`. Comprobar por simulación que nada más se mueve.
  - **R durante la intro:** el `GameManager` está en `READY` y ya ignora R en ese estado; no se agrega nada. Documentarlo.
  - **Con la intro saltada** (R, F6) el jugador aparece en el `PlayerSpawn` como hoy (no se lanza), la escotilla queda ya rota y el tentáculo activo desde el primer frame. Es una propuesta: si se prefiere que R también lance al jugador desde la escotilla, se avisa.
  - **`start_delay` de la cámara:** no cambia. Sigue contando desde que empieza la partida (la ruptura), así que la cámara empieza a subir `start_delay` s después del lanzamiento, como hoy tras el título.
  - **HUD:** aparece en la ruptura (`begin()`), como hoy.

## Reglas de trabajo

1. **Gates:** al terminar cada paso, detenerse, entregar la checklist y esperar el "seguí" de LT. Cowork no puede jugar; el juicio de "se siente bien" es de LT.
2. **Git:** rama `feature/intro-escotilla` desde `main` actualizado. Un commit por paso (`pasoN: descripción`); los ajustes tras el QA de LT pueden ir en un commit `pasoN: ajustes tras QA`. **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y el resumen de cambios (ver Cierre).
3. **No modificar** `lvl1.tscn`, los sprite sheets ni el renderer (solo reportar cuál está en uso). No agregar assets (ni fuentes, ni imágenes, ni audio). **No cambiar** `run/main_scene`. `project.godot` solo se toca si el paso lo pide. Los `.tres` de `player_config`, `scroll_config`, `tentacle_config` y `level_config` son valores de prueba de LT: no tocarlos salvo que el paso lo pida.
4. **GDScript tipado** en todo (variables, parámetros, retornos), indentado con **tabulaciones**. Comentarios `##` en cada clase, variable exportada, señal y función pública. Comentarios en español, identificadores en inglés. Textos de UI en español rioplatense.
5. **Variables exportadas agrupadas** con `@export_group`, con unidad en el comentario (px, px/s, s, u).
6. **Sin valores hardcodeados**: lo que afecta gameplay o tiempos va en un `Resource`; lo puramente visual como `const` con `## ... Solo visual.` / `Estructural.`.
7. **Validación por CLI** tras cada paso: `.tools/godot --headless --path . --quit`, un script que cargue e instancie todas las escenas y scripts, y **simulación headless** de los comportamientos nuevos (ver "Notas técnicas"). Reportar errores. Guardar los scripts de prueba **fuera** del repo. Repetir las simulaciones de los briefs anteriores que puedan verse afectadas (título, R, `Level.tscn`/sandbox solos, HUD).
8. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.
9. **`TUNING_LOG.md`:** no se toca.
10. **Regresión:** `Level.tscn` (F6 directo, sin pasar por Main), `sandbox.tscn`, el título, el HUD y el reinicio con R deben seguir funcionando en todos los pasos.

## Estado actual del código (resumen para no tener que descubrirlo)

| Elemento | Detalle |
|---|---|
| `Main` (`scripts/main/main.gd`, escena principal) | Instancia `Level.tscn` con `autostart = false` en `LevelHolder` y el `TitleMenu` (capa 95). Tras `TitleMenu.faded_out` elimina el menú y llama a `level.begin()`. Con `GameManager.restart_requested` libera el `Level` y crea otro con `autostart = true` |
| `LevelController` (`scripts/levels/level_controller.gd`) | `@export var autostart: bool = true`. En `_ready` arma el nivel (`LevelBuilder.build()`), ubica al jugador, fija el tope de cámara, conecta la puerta, pasa el rango al HUD. Con `autostart` en `false` pone `process_mode = DISABLED` (el `DebugOverlay` queda `ALWAYS`) y oculta el HUD; `begin()` (idempotente) reanuda, muestra el HUD y llama a `GameManager.start_run(seed)` |
| `GameManager` (autoload) | Estados `READY`, `PLAYING`, `WON`, `LOST`; `restart()` emite `restart_requested` y solo recarga la escena si nadie escucha; ignora R en `READY` |
| `ScrollCamera` | `Camera2D` que sube a `scroll_speed` tras `start_delay` (2 s). API: `set_scrolling`, `set_stop_y`, `has_reached_end`, `get_bottom_y`, `get_visible_rect`, `reset`. Se mueve en `_physics_process`; `ScreenBounds` (paredes) cuelga de ella |
| `Tentacle` (`scripts/tentacle/tentacle.gd`) | Se ancla al borde inferior de la cámara (`visible_height` 70 px), `KillZone` (`Area2D`), chequeo de caída (`_check_fell`), onda con `_process`. API: `set_rising(bool)`, `reset()`. `TentacleConfig` en `resources/configs/tentacle_config.tres` |
| `Player` (`class_name Player`, grupo `player`) | `CharacterBody2D`; propulsa/camina/salta en `_physics_process` leyendo el Input Map; `is_alive()`, `die()`, `win()`, `reset(spawn)`, `add_fuel()`. Nodos: `Body`, `ThrustIndicator`, `CollisionShape2D` |
| `SegmentStart.tscn` | Segmento de 640 px: `Floor` (banda de 20 px de alto a todo el ancho, en el borde inferior), `StartPlatform`, tres plataformas, `PlayerSpawn` (Marker2D, en el nivel queda en (180, 548)) y un tanque |
| `LevelBuilder` | `build()`, `get_player_spawn()`, `get_camera_stop_y()`, `get_goal_door()`, `get_seed()`. Un nivel = inicio + 6 intermedios + final |
| Capas de UI | HUD 80, mensaje de fin 90, título 95, overlay F3 100 |

---

## PASO 0 — Preparación

**Objetivo:** rama, brief y documentación listos.

1. Si hay cambios sin commitear (valores de prueba de LT), apartarlos con `git stash push -m "valores de prueba LT"` y devolverlos al final; **no** subirlos. Luego `git checkout main`, `git pull`, `git checkout -b feature/intro-escotilla`. Confirmar árbol limpio (ignorar `.tools/`).
2. Copiar este brief a `docs/briefs/brief-05-intro-escotilla.md` (si LT ya lo dejó ahí sin trackear, solo commitearlo).
3. `docs/ROADMAP.md`: marcar 8d y 8e como "En brief / brief-05" (hoy figura un único 8d "Intro de la escotilla" como Pendiente: dividirlo en **8d** = escotilla, golpes con vibración y gas; **8e** = ruptura, lanzamiento del jugador y entrada del tentáculo); actualizar "Estado global" (brief 04 mergeado en PR #4, brief 05 en curso) y ampliar la sección 5 con los dos pasos. Agregar a la tabla de decisiones las propuestas de Claude que apliquen (director de la intro, R y F6 saltan la intro, `start_delay` sin cambios).
4. Verificar que `docs/.obsidian/` sigue en `.gitignore`.

**Criterios de aceptación:**
- [ ] `git status` limpio en la rama nueva y `docs/` actualizado como arriba.

**Commit:** `paso0: preparación del brief 05`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 8d — Escotilla, golpes y gas

**Objetivo:** al pulsar JUGAR se ve una escotilla en la parte inferior del nivel (sin tentáculo); la cámara vibra tres veces y en cada golpe sale gas de la escotilla. Al terminar el tercer golpe, **de momento** el juego arranca como hoy (`begin()`); la ruptura y el lanzamiento son el paso 8e.

### 8d.1 Comportamiento
1. **Título:** se ve el nivel quieto con la escotilla cerrada en la parte inferior (centrada, sobre el piso del segmento de inicio) y **sin tentáculo**. El jugador **no** se ve (está detrás de la escotilla; en este paso queda oculto y quieto hasta `begin()`).
2. **Al terminar el fundido del menú** (`TitleMenu.faded_out`): `Main` llama a `level.play_intro()` (en lugar de `begin()`). El estado del `GameManager` sigue en `READY`; R no hace nada.
3. **Cada golpe** (`hit_count` veces, separados por `hit_interval`; el primero tras `first_hit_delay`): la cámara vibra (`ScrollCamera.shake`), la escotilla se abomba/sacude un poco más y sale una ráfaga de gas por las rendijas. Cada golpe es un poco más fuerte que el anterior (`hit_escalation`).
4. **Después del último golpe** (`pre_break_pause` s), en este paso se llama a `begin()` (arranca la partida como hoy, con la escotilla golpeada y el jugador en el spawn y visible; el tentáculo vuelve a activarse). *El tramo definitivo (ruptura y lanzamiento) es el paso 8e.*
5. **Sin intro** (`Level.tscn` solo con F6, R con Main, `sandbox.tscn`): `autostart = true`, sin escotilla animada; funcionan exactamente como antes.

### 8d.2 Diseño propuesto (validar; si hay un problema, avisar)
- **`IntroConfig`** (`scripts/intro/intro_config.gd`, `class_name IntroConfig extends Resource`) + `resources/configs/intro_config.tres` (visible como `ExtResource` en la escena, no embebido):

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Golpes | `hit_count` | 3 | — | Cantidad de golpes antes de la ruptura |
| Golpes | `first_hit_delay` | 0.6 | s | Espera entre el fin del fundido y el primer golpe |
| Golpes | `hit_interval` | 1.0 | s | Tiempo entre golpes consecutivos |
| Golpes | `pre_break_pause` | 0.7 | s | Pausa entre el último golpe y la ruptura |
| Vibración | `shake_amplitude` | 8.0 | px | Amplitud de la vibración del primer golpe |
| Vibración | `shake_duration` | 0.35 | s | Duración de cada vibración |
| Vibración | `hit_escalation` | 1.3 | × | Multiplicador de amplitud de cada golpe respecto del anterior |
| Gas | `gas_amount` | 24 | partículas | Partículas por ráfaga (golpe normal) |
| Gas | `gas_lifetime` | 0.9 | s | Vida de cada partícula |
| Gas | `gas_speed` | 90.0 | px/s | Velocidad de salida del gas |

  (`ScrollCamera.shake` y las partículas leen estos valores; no hay números de intro en los scripts.)
- **`Hatch`** (`scenes/intro/Hatch.tscn` + `scripts/intro/hatch.gd`): API `hit(strength: float) -> void` (sacudida de la escotilla + ráfaga de gas; `strength` = multiplicador de intensidad), `set_broken(broken: bool) -> void` (estado final, sin animación; lo usa el nivel cuando no hay intro), `get_launch_position() -> Vector2` (centro superior de la escotilla, de donde sale el jugador en 8e). Gas con `CPUParticles2D` de una sola ráfaga (`one_shot`, sin textura, color blanco azulado con alfa). `process_mode = ALWAYS`.
- **`ScrollCamera.shake(amplitude: float, duration: float) -> void`:** sacude `Camera2D.offset` con decaimiento hasta 0 y lo deja exactamente en `Vector2.ZERO` al terminar; una llamada nueva pisa a la anterior. Vibración con `Tween` creado desde el `SceneTree`. `reset()` cancela la vibración. **No** modifica `global_position`.
- **`Player`:** `set_frozen(frozen: bool) -> void`: con `true` oculta el cuerpo y el indicador de propulsión, detiene `_physics_process` y desactiva la colisión; con `false` revierte. (La usa el director; en 8e se agrega `launch`.) `Player.reset()` deja `frozen = false`.
- **`Tentacle`:** `set_active(active: bool) -> void`: con `false` lo oculta, apaga `KillZone` (`monitoring`) y el chequeo de caída, y detiene su animación; con `true` lo restaura. Estado inicial: activo (no cambia el comportamiento de `sandbox.tscn`).
- **`LevelController`:** `@export var intro_config: IntroConfig` (`ExtResource` a `intro_config.tres` en `Level.tscn`) y función pública `play_intro() -> void`. Con `autostart = false`, en `_ready`: `Tentacle.set_active(false)`, `Player.set_frozen(true)`, `Hatch` cerrada. Con `autostart = true` (F6, R, sandbox): `Hatch.set_broken(true)` (si existe) y todo activo desde el primer frame. `begin()` sigue siendo idempotente y **siempre** deja `Tentacle.set_active(true)` y `Player.set_frozen(false)`.
- **`IntroDirector`** (`scripts/intro/intro_director.gd`): `play(hatch, camera, player, tentacle)`; emite `hit(index: int)` y `finished`. Por golpe llama a `camera.shake(...)` y `hatch.hit(...)`. Ver "Propuestas de Claude" (comprobar `is_inside_tree()` tras cada `await`).
- **`Level.tscn`:** agregar `Hatch` como hijo (`scenes/intro/Hatch.tscn`), ubicado por `LevelController` en el `HatchAnchor` del segmento de inicio (`Marker2D` nuevo en `SegmentStart.tscn`, centro del piso) usando un `LevelBuilder.get_hatch_position() -> Vector2` nuevo. Capa de dibujo: por encima del piso y por debajo del jugador.
- **`Main`:** `_on_title_faded_out` llama a `_level.play_intro()`.
- **Estilo placeholder:** escotilla de ~120×32 px centrada en x = 180, azul frío `#3A9BBF` con marco `#C8E7EA` y brillo rojo `#D83232` de baja opacidad debajo. Solo `const` visuales.

### 8d.3 Validación por simulación (script fuera del repo)
- Cargar `Main.tscn`: `Hatch` presente y cerrada, `Tentacle` inactivo (invisible, `KillZone.monitoring` = false), `Player` congelado/oculto; estado `READY`; tras 120 frames nada se movió.
- Tras `faded_out`: se emiten exactamente `hit_count` golpes con la separación de `IntroConfig`; durante cada golpe `Camera2D.offset` es ≠ 0 y al terminar vuelve a `Vector2.ZERO`; `camera.global_position` **no** cambia durante la intro; el tentáculo, las trampas y los obstáculos móviles siguen quietos; `GameManager.get_state()` sigue `READY` hasta el final.
- R durante la intro: no hace nada (mismo `Level`, estado `READY`).
- Al terminar: estado `PLAYING`, `Tentacle` activo, `Player` visible y en el spawn, HUD visible.
- Cada golpe es más fuerte que el anterior (amplitud medida).
- Regresión: `Level.tscn` solo y `sandbox.tscn` arrancan solos y sin intro; R con Main reinicia sin intro y con la escotilla rota; título, HUD y mensajes de fin sin cambios.

### 8d.4 Documentación
`docs/mecanicas/intro-escotilla.md` (propósito, línea de tiempo de la secuencia, nodos de `Hatch`, `IntroConfig` con tabla, API de `Hatch`/`IntroDirector`/`ScrollCamera.shake`/`Player.set_frozen`/`Tentacle.set_active`, cómo probarla, cómo ajustar el "feel"). Actualizar `pantalla-titulo.md` (el arranque pasa por `play_intro()`), `scroll-camara.md` (`shake`), `tentaculo.md` (`set_active`), `jugador.md` (`set_frozen`), `niveles-por-segmentos.md` (`HatchAnchor`, `get_hatch_position`), `ARQUITECTURA.md` (árbol de `Level`, señales y flujo con intro) y `README.md`.

**Criterios de aceptación (checklist para LT):**
- [ ] Con F5 y sin tocar nada se ve el nivel con una escotilla abajo y **sin** tentáculo ni jugador.
- [ ] Al pulsar JUGAR y disolverse el menú, la cámara vibra tres veces y en cada una sale gas de la escotilla; cada golpe se siente un poco más fuerte.
- [ ] Mientras dura la intro no se mueve nada más (ni cámara, ni obstáculos, ni trampas) y R no hace nada.
- [ ] Al terminar los golpes el juego arranca (por ahora sin ruptura) y funciona como antes.
- [ ] R en medio de la partida, `Level.tscn` y `sandbox.tscn` con F6 siguen como antes (sin intro).
- [ ] `docs/mecanicas/intro-escotilla.md` se entiende sin haber leído el código.

**Commit:** `paso8d: escotilla, golpes de cámara y gas`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 8e — Ruptura, lanzamiento del jugador y entrada del tentáculo

**Objetivo:** tras el tercer golpe la escotilla se rompe, el jugador sale disparado hacia arriba, empieza la partida y, un rato después, el tentáculo entra desde abajo.

### 8e.1 Comportamiento
1. **Ruptura** (`pre_break_pause` s después del último golpe): golpe final más fuerte (`break_shake_amplitude`, `break_shake_duration`), ráfaga grande de gas (`break_gas_amount`) y las hojas de la escotilla salen despedidas / se abren (animación corta, `break_duration`); queda el marco y el hueco oscuro. Pueden salir algunos fragmentos de polígono (`break_debris_count`) que caen fuera de pantalla.
2. **Lanzamiento:** en el instante de la ruptura el jugador **aparece** en `Hatch.get_launch_position()` y sale con velocidad `launch_speed` hacia arriba (`Player.launch`). Durante `control_lock_time` s el jugador **no** responde al Input (el jetpack y el movimiento quedan bloqueados; la inercia y la gravedad actúan normalmente); pasado ese tiempo recupera el control. Colisiona con las plataformas como siempre (si choca con algo, sigue la física normal).
3. **Empieza la partida:** en el mismo instante `LevelController.begin()` → `GameManager.start_run(seed)` (`PLAYING`), aparece el HUD, arranca el scroll (con su `start_delay` sin cambios) y se reanudan obstáculos y trampas.
4. **Tentáculo:** sigue **inactivo** durante `tentacle_entry_delay` s después de la ruptura; luego sube desde debajo de la pantalla hasta su posición normal en `tentacle_entry_duration` s (`Tentacle.enter(duration)`) y desde ese momento **mata** y se comporta como hoy. Mientras entra ya es letal donde esté su borde superior. Si el jugador cae bajo el borde inferior antes de que entre, **muere por caída** (`&"fell"`) como siempre: la red de seguridad de caída debe estar activa desde `begin()`; documentar y comprobar.
5. **Sin intro** (R con Main, F6, sandbox): no hay lanzamiento ni entrada; el tentáculo está activo desde el primer frame y el jugador aparece en el `PlayerSpawn` como hoy.

### 8e.2 Diseño propuesto (validar; si hay un problema, avisar)
- **`IntroConfig`** gana:

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Ruptura | `break_shake_amplitude` | 16.0 | px | Amplitud de la vibración de la ruptura |
| Ruptura | `break_shake_duration` | 0.6 | s | Duración de esa vibración |
| Ruptura | `break_gas_amount` | 80 | partículas | Partículas de la ráfaga grande |
| Ruptura | `break_duration` | 0.35 | s | Duración de la animación de apertura de las hojas |
| Ruptura | `break_debris_count` | 6 | — | Fragmentos que salen despedidos |
| Lanzamiento | `launch_speed` | 450.0 | px/s | Velocidad vertical inicial (hacia arriba) |
| Lanzamiento | `control_lock_time` | 0.5 | s | Tiempo sin control tras el lanzamiento |
| Tentáculo | `tentacle_entry_delay` | 1.5 | s | Espera entre la ruptura y el inicio de la entrada del tentáculo |
| Tentáculo | `tentacle_entry_duration` | 1.0 | s | Duración de la subida desde fuera de pantalla hasta su posición |

  Los valores son de prueba: calibrar `launch_speed` y `control_lock_time` para que el jugador suba una distancia razonable (del orden de 150–250 px) antes de recuperar el control y sin chocar contra el techo del primer segmento; reportar lo medido.
- **`Player.launch(launch_velocity: Vector2, control_lock: float) -> void`:** `set_frozen(false)`, asigna `velocity`, bloquea el Input `control_lock` s. La cuenta del bloqueo se lleva en `_physics_process` (variable interna, sin `Timer`); `reset()` la anula. Documentar la API.
- **`Hatch.break_open(config)`** o equivalente: animación de ruptura + `set_broken(true)` al final; emite `broken()` al terminar (o el director espera `break_duration`).
- **`Tentacle.enter(duration: float) -> void`:** hace `set_active(true)` y desplaza el tentáculo desde `camera.get_bottom_y()` hacia su posición normal con un `Tween` sobre un desfase interno (`_entry_offset`); sigue anclado a la cámara. `reset()` lo cancela.
- **`IntroDirector`** completa la secuencia: golpes → pausa → ruptura → (`launch`, `begin()`) → espera `tentacle_entry_delay` → `tentacle.enter(...)`. Señales: `hit(index)`, `broken`, `finished`. El `Player` no se libera del bloqueo antes de tiempo aunque el nivel termine (ganar/perder no debe dejar estado colgado).
- **`LevelController`:** `begin()` deja de activar el tentáculo por su cuenta cuando viene de la intro; el director lo hace. Sin intro (`autostart = true`) `begin()` deja todo activo (paso 8d).

### 8e.3 Validación por simulación (script fuera del repo)
- Secuencia completa desde `Main.tscn` con `faded_out`: `Tentacle` inactivo hasta `break + tentacle_entry_delay`, luego entra en `tentacle_entry_duration` (medir posición inicial y final) y queda igual que sin intro.
- Antes de la ruptura el `Player` está oculto y quieto; en la ruptura aparece en `get_launch_position()` con `velocity.y ≈ -launch_speed`; durante `control_lock_time` las acciones de propulsión simuladas (`Input.action_press`) **no** cambian su velocidad; después sí.
- `GameManager.get_state()` es `READY` hasta la ruptura y `PLAYING` justo después; el HUD se muestra en ese momento; `start_delay` de la cámara cuenta desde la ruptura.
- La cámara vibra en la ruptura con la amplitud de `break_shake_amplitude` y termina con `offset == Vector2.ZERO`.
- Sin control, el jugador que cae bajo el borde antes de que entre el tentáculo muere con `&"fell"`.
- Pulsar R después de la ruptura: reinicia sin intro y con la escotilla rota; R durante la intro no hace nada.
- Ganar y perder siguen funcionando (mensajes de fin), también si ocurre antes de que entre el tentáculo.
- Regresión de todo lo del brief 04 (título, HUD, R, `Level.tscn` y sandbox solos).

### 8e.4 Documentación
Completar `docs/mecanicas/intro-escotilla.md` (línea de tiempo final con los tiempos de `IntroConfig`, ruptura, lanzamiento, entrada del tentáculo, tabla de config completa, cómo probarlo y ajustar el "feel"). Actualizar `jugador.md` (`launch`), `tentaculo.md` (`enter`), `pantalla-titulo.md`, `ARQUITECTURA.md` (flujo de partida con intro), `README.md` y `docs/ROADMAP.md` (8d y 8e en Hecho al cierre).

**Criterios de aceptación (checklist para LT):**
- [ ] Tras los tres golpes la escotilla se rompe con un golpe final más fuerte y una ráfaga grande de gas.
- [ ] El jugador aparece y sale disparado hacia arriba desde la escotilla; no responde a las teclas durante un instante y luego recupera el control.
- [ ] La partida empieza en ese momento (HUD visible, la cámara empieza a subir tras su espera habitual).
- [ ] El tentáculo entra desde abajo un rato después y desde ahí es letal como antes.
- [ ] Si me quedo sin mover al jugador y cae, muere por caída sin que el tentáculo haga falta.
- [ ] R reinicia sin intro (escotilla rota, tentáculo activo desde el inicio); `Level.tscn` y `sandbox.tscn` con F6 siguen como antes.
- [ ] Ganar, perder y los mensajes de fin siguen funcionando.
- [ ] `docs/mecanicas/intro-escotilla.md` se entiende sin haber leído el código.

**Commit:** `paso8e: ruptura de la escotilla, lanzamiento y entrada del tentáculo`

> **Detenerse y esperar el "seguí" de LT.**

---

## Notas técnicas (aprendidas en los briefs 01 a 04)

- **Godot y `gh`:** ya están instalados **dentro del repo** en `.tools/` (carpeta excluida de git de forma local en `.git/info/exclude` y con un `.gdignore`): `.tools/godot` (4.7.2 headless, Linux) y `.tools/bin/gh`. Usarlos con `cd $HOME/mnt/escapa-del-tentaculo && .tools/godot --headless --path . ...` y `export PATH=$PWD/.tools/bin:$PATH`. Si `.tools/` no existe, reinstalar Godot desde `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` y `gh` desde la API de releases (`https://api.github.com/repos/cli/cli/releases/latest`, `gh_<versión>_linux_amd64.tar.gz`), avisando antes a LT (nombre, origen y tamaño). **No** dejar el token de `gh` dentro del repo.
- **Tras crear clases nuevas** (`class_name`), correr `.tools/godot --headless --path . --import` para registrarlas y generar los `.gd.uid` (se commitean).
- **Autenticación de `gh` (al final, antes del push):** flujo de dispositivo con client id `178c6fc778ccc68e1d6a` y scopes `repo read:org`. Primera llamada: `POST https://github.com/login/device/code`, guardar `device_code` en un archivo temporal **fuera del repo** (`$HOME/dc.json`) y mostrarle a LT `user_code` y `https://github.com/login/device`. Cuando LT confirme (segunda llamada, separada: los procesos en segundo plano no sobreviven a la llamada): `POST https://github.com/login/oauth/access_token` con `grant_type=urn:ietf:params:oauth:grant-type:device_code`, `GH_CONFIG_DIR=$HOME/ghcfg gh auth login --with-token`, `gh auth setup-git`, y **borrar** los archivos temporales del token. Usar `GH_CONFIG_DIR=$HOME/ghcfg` en cada comando `gh`.
- **Identidad de git:** no hay `user.name` configurado; usar `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com ...` en cada commit y **no** modificar la config. Terminar los commits con las líneas de atribución que indique el sistema. Agregar los archivos por nombre o carpeta (no `git add -A`).
- **Locks de git y permiso de borrado:** el shell no puede borrar `.git/index.lock`, `.git/HEAD.lock`, `.git/objects/maintenance.lock` ni los `tmp_obj_*` hasta que LT apruebe `device_request_delete_permission` para la carpeta del repo. **El permiso vale solo para la sesión**: pedirlo **una vez al empezar** (motivo: borrar locks de git y temporales) y, después de cada commit, limpiar con `find .git \( -name '*.lock' -o -name 'tmp_obj_*' \) -delete`. Usar `git --no-optional-locks status`.
- **Indentación:** escribir los `.gd` con tabulaciones y comprobarlo (`grep -c $'^\t'`).
- **`_ready` en subclases:** el `_ready` de una clase hija no llama al de la base: usar `super()`.
- **`.tscn` a mano:** las exportaciones de tipo nodo requieren `node_paths=PackedStringArray("nombre")` en el encabezado del nodo. Los `Resource` de config compartidos en la escena van como `ExtResource` (con su `.tres` visible), no embebidos. Formas de colisión propias por instancia: `resource_local_to_scene = true`.
- **Godot reescribe archivos** al abrir el editor (`unique_id`, `uid`, `project.godot`, `.tres`). Es esperable; los `.gd.uid` se commitean. Si LT tiene cambios de prueba en `.tscn`/`.tres`, un `git stash pop` puede dar conflicto: conservar ambos lados y **nunca descartar** cambios de LT sin que lo pida.
- **Pausa de nodos:** `process_mode = DISABLED` en un nodo detiene también a sus hijos (`_process`, física, `Timer`, `Tween` ligados al nodo, `Area2D`, `AnimationPlayer`); un hijo con `PROCESS_MODE_ALWAYS` sigue corriendo. Un `Tween` creado con `get_tree().create_tween()` no depende del nodo. `SceneTree.create_timer()` corre mientras el árbol no esté pausado. Comprobar siempre por simulación que lo que debe estar quieto lo está (comparar posiciones, `modulate` y `monitoring` antes y después de esperar varios segundos).
- **Simulación headless:** script `extends SceneTree` ejecutado con `timeout 170 .tools/godot --headless --path . -s $HOME/sims/<script>.gd`, guardado **fuera** del repo (`$HOME/sims/`). Detalles que costaron tiempo:
  - En `_init` el árbol todavía no está listo: llamar a una función `_run()` que empiece con `await process_frame`. El autoload no se puede nombrar como identificador global dentro de un script `-s`: `root.get_node("/root/GameManager")`.
  - Para escenas completas usar `change_scene_to_file(...)` y esperar ~20 frames.
  - Simular la tecla R con `InputEventAction` (`action = &"restart"`, `pressed = true`) y `Input.parse_input_event(e)`; esperar ~10 frames.
  - Un jugador quieto en el inicio muere por el tentáculo en ≈ 148 frames: en pruebas largas anular al tentáculo (`set_physics_process(false)` y `KillZone.monitoring = false`) o el estado pasa a `LOST`. La cámara tarda `start_delay` (2 s = 120 frames) en empezar a subir.
  - Para medir tiempos reales usar `await create_timer(t).timeout` en lugar de contar frames (en headless los frames no van a 60 fps fijos).
  - Un botón deshabilitado sigue emitiendo `pressed` si se llama a `pressed.emit()` a mano: probar el "doble clic" comprobando `disabled` y que `faded_out` se emitió una sola vez.
  - No encadenar dos simulaciones largas en un mismo comando: el límite de la herramienta es ~180 s.
  - Los avisos `ObjectDB instances were leaked` al salir del script son esperables.
- **Valores de prueba de LT:** los `.tres` son valores de prueba; no tocar `player_config.tres`, `scroll_config.tres`, `tentacle_config.tres` ni `level_config.tres` salvo que el paso lo pida.
- **`docs/.obsidian/`** está en `.gitignore`: no commitearlo.

## Cierre

1. `docs/ROADMAP.md`: pasos 8d y 8e en Hecho; 8c (táctil) pendiente para el final; decisiones nuevas anotadas; "Estado global" al día. Revisar que `ARQUITECTURA.md` refleje el árbol de escenas (con `Hatch`), las señales y el flujo de partida final con intro.
2. Si había cambios de prueba de LT apartados: `git stash pop` (avisar si hay conflicto; no resolver descartando sus cambios).
3. **Confirmación antes de tocar GitHub.** Mostrarle a LT **en un mensaje al chat**: el árbol de archivos nuevo o modificado, `git log --oneline main..HEAD` y `git diff --stat main`, y el contenido de los `.tres` nuevos. Esperar su confirmación explícita.
4. Con la confirmación: login de `gh` (ver notas), `git push -u origin feature/intro-escotilla`, `gh pr create --base main --title "Intro de la escotilla (pasos 8d y 8e)"` con la descripción tomada de los commits, y **mergear con `gh pr merge --merge`** (LT ya indicó que Cowork lo hace cuando él confirma). Luego `git checkout main` y `git pull`.
5. Cerrar diciéndole a LT cómo continuar: quedan el balance del MVP, el arte y audio (paso 9, incluyendo el sonido de los golpes y del gas) y los controles táctiles (paso 8c), y ofrecerle generar el brief 06.

## Resultado esperado

- Rama `feature/intro-escotilla` publicada, PR abierto y mergeado, con los commits `paso0`, `paso8d`, `paso8e` (más los de ajustes tras QA, si los hubo).
- Al pulsar JUGAR: nivel con escotilla abajo, tres golpes de cámara con gas, ruptura, jugador disparado hacia arriba, partida en marcha y, poco después, el tentáculo entrando desde abajo.
- Reinicio con R, `Level.tscn` y `sandbox.tscn` sin intro y sin regresiones.
- `docs/` con `intro-escotilla.md`, `ARQUITECTURA.md` al día y el roadmap listo para el siguiente brief.
