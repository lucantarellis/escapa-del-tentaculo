# Brief 06 — Tuning del MVP (rondas iterativas) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork). No hace falta adjuntar nada: todo el contexto está acá y en `docs/` del repo (que Claude puede leer en la carpeta conectada).

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior y el jugador usa un jetpack con combustible limitado para esquivar obstáculos, recoger tanques y llegar a una puerta antes de que lo atrapen. Al pulsar JUGAR (y con cada R) hay una intro: una escotilla recibe tres golpes con gas, se rompe, el jugador sale disparado hacia arriba (la cámara lo sigue) y poco después entra el tentáculo.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D. Viewport vertical **360×640** (ventana de PC a 1,5×). Todo con polígonos placeholder.
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). **Rama base:** `main`. Trabaja LT con un socio, que **no toca nada hasta que esté el MVP**: no hay que avisarle de nada.
- **Estado del repo:** `main` incluye los briefs 01 a 05 (PR #1 a #5): mecánicas base, obstáculos y tanques, puerta + game manager + niveles por segmentos, título + HUD e intro de la escotilla. El MVP es jugable de punta a punta. Leer **antes de trabajar**: `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md`, `docs/TUNING_LOG.md` y `docs/mecanicas/*.md` (en especial `jugador.md`, `scroll-camara.md`, `tentaculo.md`, `tanques.md`, `obstaculos.md`, `niveles-por-segmentos.md` e `intro-escotilla.md`).
- **Alcance de este brief:** el **balance del MVP** (paso "balance" que el roadmap dejó para cuando el MVP estuviera listo), trabajado en **rondas**: Claude propone qué tunear y un checklist, LT juega y responde, Claude simula y ajusta, y se repite. **Fuera de alcance:** arte final, audio (paso 9), controles táctiles (paso 8c), mecánicas nuevas, pausa, puntaje. Si el tuning revela que falta una mecánica o que hay que cambiar código, **se avisa a LT antes** y se decide juntos (ver "Reglas de trabajo").

## Qué necesita aportar LT

1. Pegar este brief en la conversación nueva. Nada más.
2. Carpeta del repo conectada a la sesión. `git` y `gh` deben poder operar (ver "Notas técnicas": Godot y `gh` ya están instalados en `.tools/`; el login de `gh` y el permiso de borrado se piden en cada conversación).
3. **Jugar cada ronda** y responder su checklist (formato `1. OK / 2. KO (motivo)` más comentarios libres, y los números que se piden). **El "se siente bien" es siempre de LT**: las simulaciones informan, no deciden.
4. Contestar unas pocas preguntas al empezar (objetivos de diseño, ver Paso 0).

## Método de trabajo (el proceso que definió LT)

Cada **ronda** repite este ciclo. Claude no avanza de una ronda a la siguiente sin el "seguí" de LT.

1. **Claude lista** qué cosas conviene tunear en esa ronda (con el porqué: hipótesis, medición o comentario previo de LT) y entrega un **checklist de prueba** para jugar, con items observables y, cuando aplique, algo para medir o anotar (por ejemplo "cuántos tanques recogiste", "en qué segmento moriste", "cuánto tardaste").
2. **LT juega y responde** con OK/KO por item, comentarios y cualquier otra observación.
3. **Claude simula** con los cambios propuestos por los comentarios o por lo que salió en la prueba (ver "Simulaciones disponibles"), compara contra la línea de base y **propone valores concretos**. Aplica en los `.tres` solo los cambios acordados en el checklist o aprobados por LT.
4. **Claude actualiza `docs/TUNING_LOG.md`** (una fila por parámetro cambiado, con evidencia) y el resto de documentos afectados (`docs/mecanicas/*.md` con los valores por defecto documentados, `docs/ROADMAP.md`).
5. **Claude lista lo que queda pendiente de tunear** y entrega el **checklist de la ronda siguiente**.
6. Se vuelve al punto 2.

La sesión termina cuando LT declara **"tuning cerrado"** (ver Cierre); no hay una cantidad fija de rondas.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- **Tema:** todo valor de gameplay o de tiempo es variable exportada en un `Resource` de configuración (`resources/configs/*.tres`); lo puramente visual va como `const` con comentario `## ... Solo visual.` / `Estructural.`. El tuning se hace **cambiando `.tres`**, no scripts.
- **`TUNING_LOG.md` se usa en este brief.** Hasta ahora los valores de los `.tres` eran de prueba y no se anotaban; **desde este brief cada cambio acordado en una ronda se registra**. Las dos filas actuales (`gravity_with_fuel` 30 → 150 y `wall_bounce` 0.25 → 0.15, ajustes de LT del brief 01, con "cómo se sintió" pendiente) se completan preguntándole a LT en la ronda que corresponda.
- **Los `.tres` de `player_config`, `scroll_config`, `tentacle_config`, `level_config` y `intro_config` pasan a ser editables por Claude en este brief**, pero **solo** para los parámetros acordados en la ronda. Nunca se tocan por iniciativa propia valores que LT ajustó a mano sin que la ronda lo pida.
- **Guardarraíl de LT:** ninguna simulación reemplaza el juicio de LT. Ante una discrepancia entre lo simulado y lo que LT siente, **gana LT**, y se ajusta el modelo o la simulación.
- **Colores de placeholder:** rojo `#D83232` = letal, cian `#63D6C5` = recogible, naranja `#FF6B32` = objetivo/meta, azul frío `#3A9BBF` = plataformas, blanco azulado `#C8E7EA` = detalles. Paleta completa en `assets/palette.md`.
- **Intro:** se reproduce al pulsar JUGAR y con cada R (dura ~3,3 s hasta la ruptura); `Level.tscn` y `sandbox.tscn` con F6 la saltan (nivel ya en juego, jugador en el `PlayerSpawn`). Su feel (ritmo, fuerza, gas, vuelo) **se afina en este brief**; la "escotilla centrada", el pasillo central libre del segmento de inicio (1100 px) y la cámara que sigue al jugador en el vuelo **no se reabren**.
- **Input:** no tocar el Input Map ni los controles.
- **Tanques:** `fuel_amount` 40 u con `max_fuel` 100, un solo uso. Un tanque medido en simulación rinde ~489 px de subida vertical y un salto sin combustible ~61 px (referencias en `docs/mecanicas/tanques.md`; **revalidar** con los valores actuales de `player_config.tres`).

## Estado actual de los valores (línea de partida, a revalidar en el Paso 0)

| Área | Parámetro | Valor | Nota |
|---|---|---|---|
| Jugador | `thrust_acceleration` / `max_speed` / `coasting_drag` | 700 / 180 / 90 | px/s², px/s, px/s² |
| Jugador | `counter_thrust_multiplier` | 1.5 | |
| Jugador | `walk_acceleration` / `walk_max_speed` | 600 / 100 | |
| Jugador | `gravity_with_fuel` | **150** (script: 30) | ajuste de LT |
| Jugador | `gravity_without_fuel` / `gravity_transition_time` / `max_fall_speed` | 500 / 0.5 / 400 | |
| Jugador | `max_fuel` / `starting_fuel` / `fuel_consumption_per_second` | 100 / 100 / 15 | 100 u ≈ 6,7 s de propulsión |
| Jugador | `jump_velocity` / `jump_requires_empty_fuel` | 260 / **false** (script: true) | decisión abierta, ver ronda 1 |
| Jugador | `wall_bounce` / `bounce_min_speed` | **0.15** (script: 0.25) / 40 | ajuste de LT |
| Tanque | `fuel_amount` | 40 | `respawn_time` 0 (un solo uso) |
| Cámara | `scroll_speed` / `start_delay` / `scroll_acceleration` | 40 / 2.0 / 0 | px/s, s, px/s² |
| Tentáculo | `visible_height` / `extra_rise_speed` / `end_rise_speed` | 70 / 0 / 40 | px, px/s, px/s |
| Tentáculo | `kill_zone_inset` / `screen_bottom_margin` | 10 / 24 | |
| Nivel | `segment_count` / `avoid_repeat_window` / `seed` | 6 / 1 / 0 (azar) | Nivel = inicio (1100 px) + 6 intermedios (640 px c/u) + final |
| Intro | golpes / vuelo | ver `intro_config.tres` | `launch_speed` 560, `control_lock_time` 0.5, `camera_follow_margin` 120, `tentacle_entry_delay` 1.5, `tentacle_entry_duration` 1.0 |

Además hay configs por instancia de obstáculos y trampas (`moving_obstacle_config.tres`, `moving_obstacle_vertical_config.tres`, `pulse_trap_config.tres`, `pulse_trap_offset_config.tres`) y el contenido de los segmentos (`scenes/levels/segments/*.tscn`): obstáculos, trampas, plataformas y tanques colocados a mano. **Nota:** el diseño de los segmentos (posiciones y cantidad de tanques, obstáculos) es parte del balance y **puede cambiarse** con acuerdo de LT en la ronda, con las mismas reglas de `docs/mecanicas/niveles-por-segmentos.md`.

## Áreas candidatas de tuning (backlog inicial; Claude lo ordena y lo ajusta en el Paso 0)

Orden sugerido: primero lo que condiciona todo lo demás.

1. **Movimiento del jugador:** `thrust_acceleration`, `max_speed`, `coasting_drag`, `counter_thrust_multiplier`, `gravity_with_fuel` (150 vs. 30: define si el jetpack "flota" o "pelea"), caminar y salto. Decidir `jump_requires_empty_fuel` (LT lo probó en `false`, el default del script es `true`) y `wall_bounce`.
2. **Combustible:** `max_fuel`, `starting_fuel`, `fuel_consumption_per_second`, `fuel_amount` del tanque, regeneración pasiva (hoy 0). Objetivo: cuánto rinde un tanque y cuánta holgura queda.
3. **Scroll y tentáculo:** `scroll_speed`, `start_delay`, `scroll_acceleration`, `visible_height`, `extra_rise_speed`, `end_rise_speed`. Objetivo: presión constante pero justa.
4. **Intro (feel):** ritmo (`first_hit_delay`, `hit_interval`, `pre_break_pause`; hoy son ~3,3 s por reinicio, lo que puede cansar), fuerza (`shake_*`, `break_*`, `hit_escalation`), gas, vuelo (`launch_speed`, `control_lock_time`, `camera_follow_*`) y entrada del tentáculo (`tentacle_entry_*`). Recalibrar el vuelo si cambian `gravity_with_fuel` o `coasting_drag` (la altura es `launch_speed² / (2 × (drag + gravedad))`).
5. **Nivel:** largo total (`segment_count`, altura del segmento de inicio), repetición de segmentos, y **dificultad por segmento** (¿alguno es demasiado fácil o imposible?), tanques por segmento (hoy dos por segmento intermedio, tres en el inicio, uno en el final).
6. **Obstáculos y trampas:** velocidades, recorridos, tiempos de aviso/activación de `PulseTrap`.
7. **Espiral de muerte sin combustible:** qué pasa si el jugador se queda sin combustible lejos de una superficie (riesgo abierto del roadmap): tolerancia del salto, holgura de tanques, gravedad sin combustible.
8. **Curva de dificultad y duración de partida:** cómo se siente el conjunto y cuánto dura un intento.

## Reglas de trabajo

1. **Gates:** al terminar cada ronda, detenerse, entregar el checklist siguiente y esperar las respuestas y el "seguí" de LT. Cowork no puede jugar.
2. **Git:** rama `feature/tuning-mvp` desde `main` actualizado. **Un commit por ronda**, con mensaje `tuning-rN: <resumen de los parámetros>`. Los cambios de código (si un hallazgo los requiere y LT los aprueba) van en un commit aparte de los `.tres`: `tuning-rN: código — <motivo>`. **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y el resumen de cambios (ver Cierre).
3. **No modificar** `lvl1.tscn`, los sprite sheets ni el renderer (solo reportar cuál está en uso). No agregar assets. **No cambiar** `run/main_scene`. `project.godot` solo se toca si una ronda lo pide.
4. **Solo `.tres` y diseño de segmentos:** el tuning cambia los `.tres` acordados y, con aprobación de LT, los `.tscn` de segmentos. Si hace falta código (por ejemplo, un parámetro que hoy está hardcodeado y debe pasar a un `Resource`, o una mecánica nueva), **avisar a LT y esperar su aprobación antes** de escribir código.
5. **GDScript tipado**, tabulaciones, comentarios `##` en español en toda API pública si se escribe código (ver `docs/CONVENCIONES.md`).
6. **Cada cambio tiene evidencia:** en el `TUNING_LOG.md`, columnas de evidencia (simulación, juego de LT o ambas) y "cómo se sintió". Los valores **sin acuerdo** de LT no se aplican; se proponen.
7. **Documentación:** al cambiar un valor por defecto documentado (tablas de `docs/mecanicas/*.md`, por ejemplo `tanques.md`), actualizar el documento en la misma ronda. Cualquier persona debe entender por qué un valor es el que es leyendo `TUNING_LOG.md`.
8. **Validación por CLI** tras cada ronda: `.tools/godot --headless --path . --quit`, un script que cargue e instancie todas las escenas y scripts, y las simulaciones de regresión que apliquen (ver "Simulaciones disponibles"). Reportar errores. Guardar los scripts de simulación **fuera** del repo (ver Notas técnicas); los **resultados** (tablas, mediciones) sí van al `TUNING_LOG.md`.
9. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.
10. **Regresión:** el título, la intro, el HUD, R, `Level.tscn` y `sandbox.tscn` deben seguir funcionando en todas las rondas.

## Simulaciones disponibles (herramientas de Claude; los scripts viven fuera del repo)

Las simulaciones **complementan** la prueba de LT: sirven para medir, comparar valores y detectar imposibles; no para decidir cómo se siente.

- **Mediciones de física:** altura y duración de un tanque de propulsión, alcance de un salto, tiempo de caída, distancia recorrida por la inercia, velocidad y aceleración efectivas con los `.tres` actuales.
- **Presupuesto de combustible por nivel:** altura total del nivel, cuántos tanques hay, cuánta propulsión permiten, y cuánta holgura queda respecto de un recorrido "razonable".
- **Alcanzabilidad por segmento:** para cada segmento, si hay un camino jugable con el combustible que llega, y cuál es el margen (por ejemplo con un **bot simple** que propulsa hacia el próximo objetivo; solo indicativo, no reemplaza a un humano).
- **Tiempos:** cuánto tarda la cámara en llegar al final (`altura / scroll_speed`), cuánto le lleva al tentáculo alcanzar a un jugador quieto, cuánto dura un recorrido óptimo frente a `scroll_speed`.
- **Comparativas antes/después** de cada cambio propuesto (misma seed, `seed_override` para reproducir niveles).
- **Regresión:** repetir las simulaciones de los briefs anteriores que puedan verse afectadas (título, intro completa, R, `Level.tscn` y sandbox solos, ganar, perder, caída con y sin tentáculo).

## Pasos

### Paso 0 — Preparación y línea de base

**Objetivo:** rama lista, valores actuales medidos y objetivos de diseño acordados con LT. Sin cambiar ningún valor todavía.

1. Si hay cambios sin commitear (valores de prueba de LT), apartarlos con `git stash push -m "valores de prueba LT"` y devolverlos al final; **no** subirlos. Luego `git checkout main`, `git pull`, `git checkout -b feature/tuning-mvp`. Confirmar árbol limpio (ignorar `.tools/`).
2. Copiar este brief a `docs/briefs/brief-06-tuning-mvp.md` (si LT ya lo dejó ahí sin trackear, solo commitearlo).
3. **Preguntarle a LT (con `AskUserQuestion`) los objetivos de diseño**, que definen qué es "bien balanceado": duración objetivo de una partida completa, porcentaje de victoria que quiere en un jugador competente, tolerancia a "morir por injusticia" (ruido) frente a "morir por error propio", y qué priorizar (accesible, exigente, tenso). Anotarlos en `docs/TUNING_LOG.md` (sección "Objetivos de diseño") y en el `ROADMAP.md`.
4. **Medir la línea de base** con simulación y guardar la tabla en `docs/TUNING_LOG.md` (sección "Línea de base"): altura y duración de un tanque, alcance de salto, altura total del nivel, cantidad de tanques y presupuesto de propulsión por nivel, tiempo de la cámara hasta el final, tiempo del tentáculo hasta un jugador quieto, alcanzabilidad por segmento, duración de la intro.
5. **Ampliar el formato de `docs/TUNING_LOG.md`:** agregar columnas `Ronda` y `Evidencia`, migrar las dos filas existentes (dejando "cómo se sintió" pendiente hasta preguntarle a LT), y agregar las secciones "Objetivos de diseño" y "Línea de base".
6. **Ordenar el backlog** (áreas candidatas de arriba) según lo que muestre la línea de base y los objetivos, y dárselo a LT junto con el **checklist de la ronda 1** (ver Paso 1).

**Criterios de aceptación (checklist para LT):**
- [ ] Los objetivos de diseño quedaron anotados como LT los dijo.
- [ ] La línea de base es entendible (tabla con valores y cómo se midieron) y `TUNING_LOG.md` tiene el formato nuevo.
- [ ] El backlog ordenado y la ronda 1 propuesta tienen sentido.

**Documentación a escribir:** `docs/TUNING_LOG.md`, `docs/ROADMAP.md` (estado y decisión de tener rondas de tuning).

**Commit:** `paso0: preparación del brief 06 y línea de base`

> **Detenerse y esperar el "seguí" de LT.**

---

### Paso N — Ronda N de tuning (se repite hasta el cierre)

**Objetivo:** mejorar un conjunto acotado de parámetros, con evidencia de simulación y del juego de LT.

**Forma de cada ronda:**

1. **Propuesta de Claude (ronda N):** qué áreas/parámetros entran, por qué, valores candidatos y el checklist para jugar. Máximo unos pocos parámetros relacionados por ronda (no cambiar todo a la vez: se pierde la causa del efecto). Formato del checklist:
   - Items numerados, cada uno con un comportamiento **observable** ("¿el vuelo de la intro llega a la altura esperada sin chocar?") y, si aplica, un dato para anotar ("tanques recogidos", "segmento donde moriste", "segundos que sobreviviste").
   - Instrucciones de cómo probar (F5 con `Main` para la intro y el flujo completo; F6 sobre `Level.tscn` para saltar la intro; `seed` fija en `level_config.tres` cuando se quiera repetir el mismo nivel; F3 abre el overlay de debug).
   - Un espacio para "comentarios libres".
2. **Respuestas de LT:** `1. OK / 2. KO (motivo)`, comentarios libres, y los datos pedidos.
3. **Claude simula y propone:** compara (antes/después) con la línea de base, contrasta con lo que dijo LT, y propone los valores de la próxima versión con la evidencia. Si un cambio requiere código o rediseñar un segmento, lo consulta.
4. **Claude aplica lo acordado** en los `.tres` (y segmentos si LT lo aprobó), ejecuta la validación por CLI y las simulaciones de regresión, y **actualiza `TUNING_LOG.md`** (una fila por parámetro: ronda, parámetro, valor anterior, nuevo, evidencia, cómo se sintió) y los documentos afectados.
5. **Claude entrega:** el resumen de la ronda (qué cambió y por qué), la **lista de pendientes de tuning** (lo que queda del backlog y lo nuevo que surgió) y el **checklist de la ronda siguiente**.

**Criterios de aceptación de una ronda:**
- [ ] Los valores nuevos están en los `.tres` y en `TUNING_LOG.md`, con evidencia.
- [ ] Las simulaciones de regresión y la carga de todas las escenas pasan sin errores.
- [ ] LT recibió el checklist de la ronda siguiente y la lista de pendientes.

**Commit:** `tuning-rN: <resumen>` (el código, si lo hubo, en un commit aparte).

> **Detenerse y esperar las respuestas de LT y su "seguí" antes de la siguiente ronda.**

---

## Notas técnicas (aprendidas en los briefs 01 a 05)

- **Godot y `gh`:** ya están instalados **dentro del repo** en `.tools/` (excluida de git de forma local en `.git/info/exclude` y con un `.gdignore`): `.tools/godot` (4.7.2 headless, Linux) y `.tools/bin/gh`. Usarlos con `cd $HOME/mnt/escapa-del-tentaculo && .tools/godot --headless --path . ...` y `export PATH=$PWD/.tools/bin:$PATH`. Si `.tools/` no existe, reinstalar Godot desde `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` y `gh` desde la API de releases (`https://api.github.com/repos/cli/cli/releases/latest`, `gh_<versión>_linux_amd64.tar.gz`), avisando antes a LT (nombre, origen y tamaño). **No** dejar el token de `gh` dentro del repo.
- **Tras crear clases nuevas** (`class_name`), correr `.tools/godot --headless --path . --import` para registrarlas y generar los `.gd.uid` (se commitean).
- **Autenticación de `gh` (al final, antes del push):** flujo de dispositivo con client id `178c6fc778ccc68e1d6a` y scopes `repo read:org`. Primera llamada: `POST https://github.com/login/device/code`, guardar `device_code` en un archivo temporal **fuera del repo** (`$HOME/dc.json`) y mostrarle a LT `user_code` y `https://github.com/login/device`. Cuando LT confirme (segunda llamada, separada: los procesos en segundo plano no sobreviven a la llamada): `POST https://github.com/login/oauth/access_token` con `grant_type=urn:ietf:params:oauth:grant-type:device_code`, `GH_CONFIG_DIR=$HOME/ghcfg gh auth login --with-token`, `gh auth setup-git`, y **borrar** los archivos temporales del token. Usar `GH_CONFIG_DIR=$HOME/ghcfg` en cada comando `gh`.
- **Identidad de git:** no hay `user.name` configurado; usar `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com ...` en cada commit y **no** modificar la config. Terminar los commits con las líneas de atribución que indique el sistema. Agregar los archivos por nombre o carpeta (no `git add -A`).
- **Locks de git y permiso de borrado:** el shell no puede borrar `.git/index.lock`, `.git/HEAD.lock`, `.git/objects/maintenance.lock` ni los `tmp_obj_*` hasta que LT apruebe `device_request_delete_permission` para la carpeta del repo. **El permiso vale solo para la sesión**: pedirlo **una vez al empezar** (motivo: borrar locks de git y temporales) y, después de cada commit, limpiar con `find .git \( -name '*.lock' -o -name 'tmp_obj_*' \) -delete`. Usar `git --no-optional-locks status`.
- **Indentación:** escribir los `.gd` con tabulaciones y comprobarlo (`grep -c $'^\t'`). Los `.tres` y `.tscn` no se indentan.
- **`.tscn` a mano:** las exportaciones de tipo nodo requieren `node_paths=PackedStringArray("nombre")` en el encabezado del nodo. Los `Resource` de config compartidos en la escena van como `ExtResource` (con su `.tres` visible), no embebidos. Formas de colisión propias por instancia: `resource_local_to_scene = true`.
- **Godot reescribe archivos** al abrir el editor (`unique_id`, `uid`, `project.godot`, `.tres`). Es esperable. Si LT tiene cambios de prueba en `.tscn`/`.tres`, un `git stash pop` puede dar conflicto: conservar ambos lados y **nunca descartar** cambios de LT sin que lo pida.
- **Editar `.tres` por CLI:** son texto plano; cambiar una línea `clave = valor` con un script (por ejemplo `python3` con lectura y escritura, o `sed -i`) y **verificar con `git diff`** que solo cambió lo acordado.
- **Pausa de nodos:** `process_mode = DISABLED` detiene también a los hijos (`_process`, física, `Timer`, `Tween` ligados al nodo, `Area2D`); un hijo con `PROCESS_MODE_ALWAYS` sigue corriendo. Un `Tween` creado con `get_tree().create_tween()` no depende del nodo. `SceneTree.create_timer()` corre mientras el árbol no esté pausado.
- **Simulación headless:** script `extends SceneTree` ejecutado con `timeout 170 .tools/godot --headless --path . -s $HOME/sims/<script>.gd` y `timeout_ms` de la herramienta en 175000 (el límite por llamada es ~180 s), guardado **fuera** del repo (`$HOME/sims/`). Redirigir la salida a un archivo y filtrarla (`grep -v "^\["`). Detalles que costaron tiempo:
  - En `_init` el árbol todavía no está listo: llamar a una función `_run()` que empiece con `await process_frame`.
  - **No referenciar autoloads ni `class_name` del juego con tipos en el script `-s`** (`GameManager`, `Main`, `LevelController`, `Player`...): el script no compila. Usar `root.get_node("/root/GameManager")` y variables sin tipo (`var level = ...`).
  - Para escenas completas usar `change_scene_to_file(...)` y esperar ~20 frames. Para simular gameplay sin la intro cargar `Level.tscn` directo (arranca solo con el jugador en el `PlayerSpawn`); para probar la intro cargar `Main.tscn` y emitir `main._title_menu.faded_out` (la intro dura ~3,3 s hasta la ruptura).
  - Simular teclas con `Input.action_press(&"move_up")` / `action_release`, o con `InputEventAction` + `Input.parse_input_event`; R con `action = &"restart"`.
  - **En headless los frames no van a 60 fps fijos:** medir tiempos con `await create_timer(t).timeout` y `Time.get_ticks_msec()`, no contando frames. Para medir física con precisión, muestrear en `process_frame` y calcular con las posiciones/velocidades reales.
  - Un jugador quieto en el inicio muere por el tentáculo tras unos segundos: en pruebas largas anular al tentáculo (`set_physics_process(false)` y `KillZone.monitoring = false`) o el estado pasa a `LOST`. Para medir a un jugador sin control, dejar de presionar acciones.
  - Para comparar niveles, `LevelBuilder.build(seed_override)` o `level_config.seed`; `LevelBuilder.get_sequence()` devuelve los segmentos elegidos.
  - No encadenar dos simulaciones largas en un mismo comando. Los avisos `ObjectDB instances were leaked` al salir son esperables.
- **`docs/.obsidian/`** está en `.gitignore`: no commitearlo.

## Cierre

Lo dispara LT diciendo **"tuning cerrado"** (o cuando los objetivos de diseño del Paso 0 se cumplan a su juicio).

1. `docs/TUNING_LOG.md`: revisar que cada valor final tenga su fila con evidencia y que las "sensaciones pendientes" estén completas o marcadas como tales. Agregar una sección "Valores finales del MVP" (tabla con todos los parámetros y su valor).
2. `docs/ROADMAP.md`: marcar el balance del MVP como Hecho, decisiones nuevas anotadas, riesgos abiertos actualizados (espiral de muerte, curva de dificultad), "Estado global" al día. Actualizar `docs/mecanicas/*.md` con los valores por defecto nuevos donde estén documentados.
3. Si había cambios de prueba de LT apartados: `git stash pop` (avisar si hay conflicto; no resolver descartando sus cambios).
4. **Confirmación antes de tocar GitHub.** Mostrarle a LT **en un mensaje al chat**: el árbol de archivos nuevo o modificado, `git log --oneline main..HEAD` y `git diff --stat main`, y los cambios de los `.tres` (`git diff main -- resources/configs`). Esperar su confirmación explícita.
5. Con la confirmación: login de `gh` (ver notas), `git push -u origin feature/tuning-mvp`, `gh pr create --base main --title "Tuning del MVP (brief 06)"` con la descripción tomada de los commits y del `TUNING_LOG.md`, y **mergear con `gh pr merge --merge`** (LT ya indicó que Cowork lo hace cuando él confirma). Luego `git checkout main` y `git pull`.
6. Cerrar diciéndole a LT cómo continuar: arte y audio (paso 9, incluido el sonido de los golpes, del gas y de la ruptura), controles táctiles (paso 8c) y ofrecerle generar el brief 07.

## Resultado esperado

- Rama `feature/tuning-mvp` publicada, PR abierto y mergeado, con el commit `paso0` y un commit por ronda (`tuning-rN`).
- `docs/TUNING_LOG.md` completo: objetivos de diseño, línea de base, una fila por cada parámetro cambiado (con evidencia y cómo se sintió) y los valores finales.
- Un MVP balanceado según los objetivos que definió LT, con la intro afinada, y sin regresiones (título, intro, R, HUD, `Level.tscn`, sandbox, ganar y perder).
- Roadmap listo para el brief 07 (arte y audio, o táctil).
