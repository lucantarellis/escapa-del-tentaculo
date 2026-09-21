# Brief 04 — Pantalla de título y HUD mínimo (pasos 0, 8 y 8b) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork). No hace falta adjuntar nada: todo el contexto está acá y en `docs/` del repo (que Claude puede leer en la carpeta conectada).

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior (y, al detenerse la cámara en el final del nivel, sigue subiendo hasta cubrir la pantalla) y el jugador usa un jetpack con combustible limitado para esquivar obstáculos, recoger tanques y llegar a una puerta antes de que lo atrapen.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D. Viewport vertical **360×640** (ventana de PC a 1,5×).
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). **Rama base:** `main`. Trabaja LT con un socio, que **no toca nada hasta que esté el MVP**: no hay que avisarle de nada.
- **Estado del repo:** `main` incluye los briefs 01 (PR #1: proyecto, jugador, cámara, tentáculo), 02 (PR #2: obstáculos y tanques) y 03 (PR #3: puerta, game manager y niveles por segmentos). El juego ya es jugable de punta a punta desde `scenes/levels/Level.tscn` (F6): nivel armado con segmentos y seed, victoria en la puerta, derrota por tentáculo/caída/obstáculo/trampa, R reinicia con un nivel nuevo. Leer **antes de escribir código**: `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md` y `docs/mecanicas/*.md` (en especial `game-manager.md`, `niveles-por-segmentos.md`, `jugador.md` y `scroll-camara.md`).
- **Alcance de este brief:** paso 0 (preparación), paso 8 (pantalla de título y transición al juego) y paso 8b (HUD mínimo: barra de combustible y progreso del nivel). **Fuera de alcance:** controles táctiles (se dejan para el final, ver decisiones), arte final, audio, puntaje, balance, opciones/ajustes, pantalla de créditos, pausa. Todo lo visual sigue siendo placeholder (`Polygon2D`, `ColorRect`, `Label`, `Button` con estilo simple).

## Qué necesita aportar LT

1. Pegar este brief en la conversación nueva. Nada más.
2. Carpeta del repo conectada a la sesión. `git` y `gh` deben poder operar (ver "Notas técnicas": Godot y `gh` ya están instalados en `.tools/` dentro del repo; el login de `gh` y el permiso de borrado se piden en cada conversación).
3. Jugar cada paso y responder la checklist con el formato `1. OK / 2. KO (motivo)`.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- **Escena principal = pantalla de título.** `run/main_scene` sigue siendo `scenes/main/Main.tscn` (hoy vacía). `Level.tscn` **no** es la escena principal. Main muestra el título del juego y un botón grande de jugar; al pulsarlo el menú **se disuelve hasta quedar transparente** y el juego arranca **sobre la escena de juego correspondiente** (`Level.tscn`, ya cargada detrás). *(LT, cierre del brief 03.)*
- **Transición: menú sobre el juego ya cargado.** `Main.tscn` instancia `Level.tscn` detrás del menú, en pausa; al pulsar Play el menú se disuelve y el juego arranca. **R reinicia directo al juego** (un nivel nuevo), sin volver al título. *(LT.)*
- **Controles: solo teclado por ahora.** Los controles táctiles (paso 8c) se implementan **al final**, cuando lo demás esté cerrado. No tocar el Input Map ni agregar controles táctiles en este brief. *(LT.)*
- **HUD muy minimalista:** solo **barra de combustible** y **progreso del nivel**. Nada más (ni puntaje, ni seed en pantalla, ni botón de reinicio, ni distancia numérica). El overlay F3 existente no se toca. *(LT.)*
- **Control por acciones del Input Map** (ya definidas, no cambiar): propulsar en 4 direcciones (WASD/flechas), `jump` (Espacio), `restart` (R), `debug_toggle` (F3).
- **Todo valor de gameplay es variable exportada** en un `Resource` de configuración (`resources/configs/*.tres`). Lo puramente visual o estructural va como `const` con comentario `## ... Solo visual.` / `Estructural.`.
- **Balance:** se deja para cuando el MVP esté listo. Los valores de las configs son de prueba. **No anotar nada en `docs/TUNING_LOG.md`** (solo se usa para pruebas reales de balance, a pedido de LT).
- **Documentación obligatoria**: cualquier persona debe entender el código leyendo `docs/` y los comentarios.
- **Colores de placeholder:** rojo `#D83232` = letal, cian `#63D6C5` = recogible, naranja `#FF6B32` = objetivo/meta, azul frío `#3A9BBF` = plataformas, blanco azulado `#C8E7EA` = detalles. Paleta completa en `assets/palette.md`. El jugador es naranja con combustible y rojo sin combustible (coherencia: la barra de combustible usa esos mismos colores).
- **Propuestas de Claude (LT las validará jugando; si hay un problema, avisar):**
  - **Reinicio con Main:** `GameManager.restart()` sigue recargando la escena actual **si nadie más se hace cargo**; agregar la señal `restart_requested` y que `restart()` la emita y solo recargue la escena si **no hay ninguna conexión** a esa señal. `Main` se conecta y reconstruye únicamente su instancia de `Level` (liberarla e instanciarla de nuevo), sin pasar por el título. Así `Level.tscn` sigue funcionando solo con F6 (sin Main) y el sandbox también.
  - **Inicio del juego tras el título:** `LevelController` gana `@export var autostart: bool = true` y una función pública `begin() -> void`. Con `autostart` en `false` arma el nivel (para verlo de fondo) pero **no** llama a `GameManager.start_run()` ni deja que la cámara/tentáculo/jugador avancen hasta `begin()`. Ver el detalle en el paso 8.
  - **HUD de solo lectura:** el HUD nunca modifica el juego; lee al `Player` por señales (`fuel_changed`, `fuel_depleted`, `fuel_refilled`) y su posición.

## Reglas de trabajo

1. **Gates:** al terminar cada paso, detenerse, entregar la checklist y esperar el "seguí" de LT. Cowork no puede jugar; el juicio de "se siente bien" es de LT.
2. **Git:** rama `feature/titulo-y-hud` desde `main` actualizado. Un commit por paso (`pasoN: descripción`); los ajustes tras el QA de LT pueden ir en un commit `pasoN: ajustes tras QA`. **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y el resumen de cambios (ver Cierre).
3. **No modificar** `lvl1.tscn`, los sprite sheets ni el renderer (solo reportar cuál está en uso). No agregar assets (ni fuentes ni imágenes). `Main.tscn` **sí** se modifica en el paso 8 (es su objetivo). **No cambiar** `run/main_scene`. `project.godot` solo se toca si el paso lo pide.
4. **GDScript tipado** en todo (variables, parámetros, retornos), indentado con **tabulaciones**. Comentarios `##` en cada clase, variable exportada, señal y función pública. Comentarios en español, identificadores en inglés. Textos de UI en español rioplatense.
5. **Variables exportadas agrupadas** con `@export_group`, con unidad en el comentario (px, px/s, s, u).
6. **Sin valores hardcodeados**: si un número afecta el gameplay o el tiempo de una transición va en un `Resource`. Lo puramente visual (colores, tamaños de fuente, márgenes) va como `const` con comentario `## ... Solo visual.` / `Estructural.`
7. **Validación por CLI** tras cada paso: `.tools/godot --headless --path . --quit`, un script que cargue e instancie todas las escenas y scripts, y **simulación headless** de los comportamientos nuevos (ver "Notas técnicas"). Reportar errores. Guardar los scripts de prueba **fuera** del repo.
8. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.
9. **`TUNING_LOG.md`:** no se toca (ver Decisiones).
10. **Regresión:** `Level.tscn` (F6 directo, sin pasar por Main) y `sandbox.tscn` deben seguir jugables en todos los pasos.

## Estado actual del código (resumen para no tener que descubrirlo)

### Piezas que se usan

| Elemento | Detalle |
|---|---|
| `GameManager` (autoload, `scripts/managers/game_manager.gd`) | Estados `READY`, `PLAYING`, `WON`, `LOST`. Señales `run_started(seed)`, `run_won()`, `run_lost(cause)`, `state_changed(new, old)`. API: `start_run(seed)`, `notify_player_died(cause)`, `notify_goal_reached()`, `restart()` (hoy: pasa a `READY` y recarga la escena actual), `get_state()`, `get_current_seed()`, `get_last_death_cause()`. Escucha la acción `restart` (R) en `_unhandled_input`. Ver `docs/mecanicas/game-manager.md` |
| `LevelController` (`scripts/levels/level_controller.gd`, raíz de `Level.tscn` y `sandbox.tscn`) | En `_ready`: si tiene un hijo `LevelBuilder`, arma el nivel (`build()`), `Player.reset(spawn)`, `ScrollCamera.set_stop_y()`, toma la puerta del segmento final; conecta `Player.died` y `Door.player_reached` con el manager; escucha `state_changed` (en `WON`: `Player.win()`, detiene scroll, congela el tentáculo y muestra el mensaje; en `LOST`: detiene scroll, congela el tentáculo y muestra el mensaje por causa); llama `GameManager.start_run(seed)`. Suelta su conexión en `_exit_tree` |
| `LevelBuilder` | `build(seed_override)`, `get_player_spawn()`, `get_camera_stop_y()`, `get_segments()`, `get_goal_door()`, `get_seed()`. Un nivel = inicio + 6 intermedios + final = 8 segmentos de 640 px = 4480 px; el spawn está en (180, 548) y la puerta cerca de Y = −4376 (con los valores actuales) |
| `Player` (`class_name Player`, grupo `player`) | Señales `fuel_changed(current, maximum)`, `fuel_depleted`, `fuel_refilled`, `died`, `won`. `get_fuel()`, `get_fuel_ratio()`, `is_fuel_empty()`, `is_alive()`, `has_won()`, `reset(spawn)`. `PlayerConfig.max_fuel` = 100. Cuerpo naranja con combustible, rojo sin él |
| `ScrollCamera` | `set_scrolling(bool)`, `set_stop_y(y)`, `has_reached_end()`, `get_visible_rect()`, `get_bottom_y()`, `reset()`; `_start_position` se toma en `_ready`; espera `start_delay` (2 s) antes de subir |
| `Tentacle` | `set_rising(bool)`, `reset()`; sigue subiendo al final del nivel (`end_rise_speed`) |
| `DebugOverlay` (F3) | `CanvasLayer` capa 100; muestra velocidad, combustible, gravedad, suelo, propulsión, salto, seed y FPS |
| `Level.tscn` | Raíz `LevelController`; hijos `LevelBuilder`, `ScrollCamera`, `Player`, `Tentacle`, `DebugOverlay`, `CaughtLayer` (mensaje de fin de partida, capa 90) |
| `Main.tscn` | Hoy solo un `Node2D` vacío llamado `Main`. **Es la escena principal (F5)** |

### Capas de UI existentes

`CaughtLayer` = 90 (mensaje de fin), `DebugOverlay` = 100. El HUD debe quedar **debajo** del mensaje de fin (capa 80) y el menú de título **encima** de todo lo del juego pero **debajo** del overlay F3 (capa 95).

### Nombres y estilo

- Archivos `.gd`: `snake_case`. Escenas `.tscn` y `class_name`: `PascalCase`. Variables y funciones: `snake_case`. Constantes: `UPPER_SNAKE`.
- Señales hacia arriba, llamadas hacia abajo: una escena hija emite señales; el padre la controla llamando a su API. Una hija no busca a su padre ni a sus hermanas.
- Textos de UI en español rioplatense ("pulsá R para reiniciar").

---

## PASO 0 — Preparación

**Objetivo:** rama, brief y documentación listos.

### 0.1 Rama y working tree
Si hay cambios sin commitear (valores de prueba de LT), apartarlos con `git stash push -m "valores de prueba LT"` y devolverlos al final; **no** subirlos. Luego `git checkout main`, `git pull`, `git checkout -b feature/titulo-y-hud`. Confirmar árbol limpio (ignorar `.tools/`, que está excluido de forma local).

### 0.2 Brief y docs
- Copiar este brief a `docs/briefs/brief-04-titulo-y-hud.md` (si LT ya lo dejó ahí sin trackear, solo commitearlo).
- `docs/ROADMAP.md`: corregir "Estado global" (los pasos 5, 6 y 7 ya están en `main`, PR #3; el brief 04 está en curso); dividir el paso 8 en **8** (pantalla de título y transición), **8b** (HUD mínimo) y **8c** (controles táctiles, **diferido al final**, después del arte y el balance); marcar 8 y 8b "En brief / brief-04" y 8c "Pendiente (al final)". Agregar a la tabla de decisiones: HUD minimalista (combustible y progreso), transición con menú sobre el juego cargado y R sin pasar por el título, táctil al final. Actualizar la sección 5 (detalle de pasos) con los tres pasos.
- Verificar que `docs/.obsidian/` sigue en `.gitignore` y que `git status` no lo lista.

**Criterios de aceptación:**
- [ ] `git status` limpio en la rama nueva y `docs/` actualizado como arriba.

**Commit:** `paso0: preparación del brief 04`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 8 — Pantalla de título y transición al juego

**Objetivo:** al abrir el juego (F5) se ve el título con un botón grande de jugar sobre el nivel ya armado y quieto; al pulsarlo el menú se disuelve y la partida arranca.

### 8.1 Comportamiento
1. **Al abrir el juego:** `Main` instancia `Level.tscn` como hijo (detrás) y encima un menú con el **título** del juego ("ESCAPA DEL TENTÁCULO") y un **botón grande "JUGAR"** centrado. Se ve el nivel de fondo (el inicio, con el astronauta y el tentáculo abajo), **sin movimiento**: ni scroll, ni tentáculo, ni obstáculos móviles/trampas animados, ni jugador propulsando; y la partida **no** está en `PLAYING` todavía.
2. **Al pulsar el botón** (clic, Enter o Espacio): el botón se deshabilita (no se puede pulsar dos veces) y el menú se **disuelve** (fundido de opacidad a 0) durante `fade_duration` segundos. Al terminar el fundido, el menú se elimina y el juego arranca: `LevelController.begin()` → `GameManager.start_run(seed)`, y todo lo que estaba quieto se pone en marcha (la cuenta de `start_delay` de la cámara empieza recién ahí).
3. **R durante la partida** reinicia **sin volver al título**: se reconstruye la instancia de `Level` con un nivel nuevo (seed nueva si `level_config.seed` = 0) y la partida arranca de inmediato (sin menú ni fundido).
4. **Regresión:** `Level.tscn` abierto solo con F6 (sin Main) y `sandbox.tscn` funcionan como antes: arrancan al instante y R recarga la escena (porque no hay nadie conectado a `restart_requested`).

### 8.2 Diseño propuesto (validar; si hay un problema, avisar)
- **`GameManager`:** agregar la señal `restart_requested()`. `restart()` pasa a `READY`, emite `restart_requested` y **solo si no hay conexiones** llama a `get_tree().reload_current_scene()`. Documentar en `game-manager.md` y actualizar la tabla de transiciones.
- **`LevelController`:** `@export var autostart: bool = true`. Con `autostart` en `false`, `_ready` arma el nivel y ubica al jugador pero deja todo en pausa (opciones: `process_mode = PROCESS_MODE_DISABLED` en el nodo raíz del nivel y volver a `PROCESS_MODE_INHERIT` en `begin()`; o `set_process/set_physics_process` selectivos; **elegir la más simple y comprobar que los `Area2D`, las trampas y los `Tween`/`Timer` quedan realmente quietos**) y **no** llama a `GameManager.start_run()`. `begin() -> void` reanuda y llama a `GameManager.start_run(seed)`. Como el nivel está en pausa, el `DebugOverlay` (F3) y el mensaje de fin no deben depender de él estando activo.
- **`Main`:** `scenes/main/Main.tscn` con script `scripts/main/main.gd` (`class_name Main extends Node`). Nodos: `Main` → `LevelHolder` (`Node`, aquí vive la instancia de `Level`) y `TitleLayer` (`CanvasLayer`, capa 90 o la que corresponda según "Capas de UI") con `TitleMenu` (escena aparte, ver abajo). Instancia `Level.tscn` con `autostart = false` (asignarlo **antes** de `add_child`). Escucha `TitleMenu.play_pressed`, y después del fundido llama a `level.begin()`. Se conecta a `GameManager.restart_requested` y reconstruye el `Level` (libera el actual, instancia uno nuevo con `autostart = true`).
- **`TitleMenu`:** `scenes/ui/TitleMenu.tscn` + `scripts/ui/title_menu.gd` (`class_name TitleMenu extends Control`). Señal `play_pressed()`. Función pública `play_fade_out() -> void` (o el propio menú hace el fundido y emite `faded_out()`); elegir y documentar. Nodos: fondo semitransparente opcional (`ColorRect` oscuro con opacidad baja, para que se lea el título sin tapar el nivel), `Label` con el título y `Button` grande. Todo con `anchors` que se adapten al viewport 360×640.
- **Configuración:** `scripts/ui/title_config.gd` (`class_name TitleConfig extends Resource`) + `resources/configs/title_config.tres`:

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Transición | `fade_duration` | 0.8 | s | Duración del fundido del menú a transparente |
| Transición | `fade_delay` | 0.0 | s | Espera entre pulsar el botón y empezar el fundido |
| Textos | `title_text` | "ESCAPA DEL TENTÁCULO" | — | Título del juego |
| Textos | `play_text` | "JUGAR" | — | Texto del botón |

  (Los textos son de UI, no gameplay, pero conviene tenerlos editables desde el inspector; si preferís `const`, justificarlo.)
- **Input:** el botón toma el foco al abrir para que Enter/Espacio lo activen (`ui_accept`); no agregar acciones nuevas al Input Map. Mientras el menú esté visible, R **no** debe reiniciar nada útil: si el manager está en `READY` (título), R no hace nada (ya lo cubre la regla de estados; comprobarlo).
- **Estilo placeholder:** título grande (≈ 28–32 px) y botón grande (mínimo 200×64 px, para que después sirva con el dedo), colores de la paleta (blanco azulado `#C8E7EA` para el título con contorno oscuro como el mensaje de fin; botón naranja `#FF6B32`, texto oscuro). Solo `const` visuales.

### 8.3 Validación por simulación (script fuera del repo)
- Cargar `Main.tscn`: existe una instancia de `Level` y el `TitleMenu` visible; `GameManager.get_state()` es `READY`; tras 120 frames la cámara **no** se movió, el tentáculo no cambió de posición y el jugador sigue en el spawn.
- Simular la pulsación del botón: el botón queda deshabilitado; durante el fundido `modulate.a` baja de 1 a 0 (medir a mitad); al terminar el menú ya no existe (`is_instance_valid` false) y el estado es `PLAYING` con seed ≠ 0; tras `start_delay` + unos frames la cámara sube.
- Pulsar el botón dos veces seguidas no arranca dos partidas ni duplica el fundido.
- R en `PLAYING` (acción `restart` por `Input.parse_input_event`): el `Level` es otra instancia, la seed cambió (con `seed` = 0), el estado vuelve a `PLAYING`, **no** aparece el menú y solo hay **una** instancia de `Level` (sin fugas).
- R en `WON` y en `LOST`: mismo resultado que arriba y el mensaje de fin desaparece.
- R durante el título (`READY`): no cambia nada.
- `Level.tscn` cargado solo (`change_scene_to_file`): arranca solo (`PLAYING`), R recarga la escena. `sandbox.tscn`: ídem.

### 8.4 Documentación
`docs/mecanicas/pantalla-titulo.md` (propósito, flujo título → juego → reinicio, diagrama de nodos de `Main`, `TitleConfig`, señales, cómo probarlo). Actualizar `game-manager.md` (señal `restart_requested`, regla de recarga), `ARQUITECTURA.md` (árbol de `Main`, señales, flujo de partida con título), `README.md` (descripción de `Main.tscn`, ya no está "vacía"; carpeta `scripts/main/`) y `docs/mecanicas/niveles-por-segmentos.md` (`autostart` y `begin()` en `LevelController`).

**Criterios de aceptación (checklist para LT):**
- [ ] Con F5 se ve el título y un botón grande de jugar sobre el nivel; nada se mueve detrás.
- [ ] Al pulsar el botón (clic y también Enter/Espacio) el menú se disuelve hasta desaparecer y luego el juego arranca (la cámara empieza a subir después del fundido).
- [ ] Pulsar el botón varias veces rápido no rompe nada.
- [ ] R en medio de la partida, tras ganar y tras perder reinicia con un nivel nuevo, **sin** volver al título.
- [ ] `Level.tscn` con F6 y `sandbox.tscn` con F6 siguen funcionando como antes (arrancan solos y R los recarga).
- [ ] Ganar, perder y los mensajes de fin siguen funcionando.
- [ ] `docs/mecanicas/pantalla-titulo.md` se entiende sin haber leído el código.

**Commit:** `paso8: pantalla de título y transición al juego`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 8b — HUD mínimo (combustible y progreso)

**Objetivo:** durante la partida se ve, de forma muy discreta, cuánto combustible queda y cuánto falta para la puerta.

### 8b.1 Comportamiento
- **Barra de combustible:** una barra fina y discreta (por ejemplo vertical, pegada al borde izquierdo, o una barra horizontal delgada arriba a la izquierda; elegir una y documentarla) que representa `Player.get_fuel_ratio()`. Color **naranja `#FF6B32`** con combustible y **rojo `#D83232`** cuando está vacío (mismos colores que el cuerpo del jugador). Sin números ni etiquetas. Se actualiza con la señal `Player.fuel_changed`; el cambio de color con `fuel_depleted` / `fuel_refilled`.
- **Progreso del nivel:** un indicador fino (por ejemplo una línea vertical delgada pegada al borde derecho con un marcador) que muestra la **altura recorrida** del jugador entre el spawn y la puerta: 0 % abajo, 100 % arriba (la puerta, con una marca naranja `#FF6B32` en el extremo). Se calcula con la Y del jugador entre la Y del spawn y la Y de la puerta, acotado a 0..1. Sin números.
- **Minimalismo:** opacidad baja (≈ 0,6–0,8), anchos de unos 4–6 px, sin marcos ni fondos pesados. Que no tape el juego ni compita con el mensaje de fin de partida.
- **Cuándo se ve:** durante la partida (desde que el juego arranca tras el título). **No** se muestra en el título. Tras ganar o perder puede quedar visible (congelado) debajo del mensaje de fin.
- **Solo lectura:** el HUD no modifica el juego.

### 8b.2 Diseño propuesto (validar; si hay un problema, avisar)
- **`Hud`:** `scenes/ui/Hud.tscn` + `scripts/ui/hud.gd` (`class_name Hud extends CanvasLayer`, capa 80). `@export var player: Player` (asignado desde el nivel, como `DebugOverlay`). Función pública `set_progress_range(start_y: float, end_y: float) -> void` (Y global del spawn y de la puerta), que llama `LevelController` tras armar el nivel. El HUD actualiza el progreso en `_process` leyendo `player.global_position.y`. Barras hechas con `ColorRect` (sin assets).
- **Instancia en el nivel:** `Level.tscn` (y `sandbox.tscn`, para que siga siendo un banco de pruebas completo) instancian el `Hud`; el `LevelController` llama `set_progress_range` con `get_player_spawn().y` y la Y de la puerta (`get_goal_door().global_position.y`; en el sandbox, la de `GoalDoor`). El `Hud` arranca oculto si el nivel está en pausa por el título y se muestra en `begin()` (o cuando el estado pasa a `PLAYING`).
- **Configuración:** los valores visuales (anchos, márgenes, opacidad, colores) van como `const` con comentario `Solo visual.`; no hay valores de gameplay. Si algún número afecta la lectura del juego (por ejemplo cuánto suaviza la barra), va en un `HudConfig` (`Resource`) con instancia por defecto `resources/configs/hud_config.tres`.

### 8b.3 Validación por simulación (script fuera del repo)
- Al iniciar, la barra de combustible está llena (ratio 1.0) y el progreso en 0.
- `Player.add_fuel`/consumo: la barra sigue `get_fuel_ratio()`; con combustible vacío la barra cambia a rojo, y al recoger un tanque vuelve a naranja.
- Teletransportar al jugador a la mitad entre spawn y puerta: progreso ≈ 0,5; a la puerta: 1,0; por debajo del spawn: 0 (acotado).
- El HUD no aparece mientras el título está visible y aparece al empezar la partida; tras R sigue visible y se reinicia (barra llena, progreso 0).
- `Level.tscn` solo (F6) y `sandbox.tscn` muestran el HUD; el mensaje de fin de partida queda por encima.

### 8b.4 Documentación
`docs/mecanicas/hud.md` (propósito, qué muestra y de dónde lee, cómo se calcula el progreso, cómo probarlo). Actualizar `ARQUITECTURA.md`, `README.md` y `docs/ROADMAP.md` (pasos 8 y 8b en Hecho al cierre).

**Criterios de aceptación (checklist para LT):**
- [ ] Se ve una barra de combustible muy discreta que baja al propulsar y sube al recoger tanques; se pone roja al quedar vacía.
- [ ] Se ve un indicador de progreso muy discreto que avanza a medida que se sube y llega al 100 % en la puerta.
- [ ] El HUD no aparece en el título y sí durante la partida; no tapa el juego ni el mensaje de fin.
- [ ] R reinicia el HUD (combustible lleno, progreso en 0).
- [ ] `Level.tscn` con F6 y `sandbox.tscn` con F6 muestran el HUD y siguen funcionando.
- [ ] `docs/mecanicas/hud.md` se entiende sin haber leído el código.

**Commit:** `paso8b: HUD mínimo de combustible y progreso`

> **Detenerse y esperar el "seguí" de LT.**

---

## Notas técnicas (aprendidas en los briefs 01 a 03)

- **Godot y `gh`:** ya están instalados **dentro del repo** en `.tools/` (carpeta excluida de git de forma local en `.git/info/exclude` y con un `.gdignore` para que Godot no la escanee): `.tools/godot` (4.7.2 headless, Linux) y `.tools/bin/gh`. Usarlos con `cd $HOME/mnt/escapa-del-tentaculo && .tools/godot --headless --path . ...` y `export PATH=$PWD/.tools/bin:$PATH`. Si `.tools/` no existe (por ejemplo en otra máquina), reinstalar Godot desde `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` y `gh` desde la API de releases (`https://api.github.com/repos/cli/cli/releases/latest`, archivo `gh_<versión>_linux_amd64.tar.gz`), y avisar a LT antes de descargar (nombre, origen y tamaño). **No** dejar el token de `gh` dentro del repo.
- **Tras crear clases nuevas** (`class_name`), correr `.tools/godot --headless --path . --import` para registrarlas y generar los `.gd.uid` (se commitean).
- **Autenticación de `gh` (al final, antes del push):** flujo de dispositivo con client id `178c6fc778ccc68e1d6a` y scopes `repo read:org`. Primera llamada: `POST https://github.com/login/device/code`, guardar `device_code` en un archivo temporal **fuera del repo** (por ejemplo `$HOME/dc.json`) y mostrarle a LT `user_code` y `https://github.com/login/device`. Cuando LT confirme (segunda llamada, separada: los procesos en segundo plano no sobreviven a la llamada): `POST https://github.com/login/oauth/access_token` con `grant_type=urn:ietf:params:oauth:grant-type:device_code`, `GH_CONFIG_DIR=$HOME/ghcfg gh auth login --with-token`, `gh auth setup-git`, y **borrar** los archivos temporales del token. Usar `GH_CONFIG_DIR=$HOME/ghcfg` (fuera del repo) en cada comando `gh`.
- **Identidad de git:** no hay `user.name` configurado; usar `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com ...` en cada commit y **no** modificar la config. Terminar los commits con las líneas de atribución que indique el sistema. Agregar los archivos por nombre o carpeta (no `git add -A`).
- **Locks de git y permiso de borrado:** el shell no puede borrar `.git/index.lock`, `.git/HEAD.lock`, `.git/objects/maintenance.lock` ni los `tmp_obj_*` que git deja, hasta que LT apruebe `device_request_delete_permission` para la carpeta del repo. **El permiso vale solo para la sesión (conversación)**: pedirlo **una vez al empezar** con un motivo claro (borrar locks de git y temporales) y, después de cada commit, limpiar con `find .git \( -name '*.lock' -o -name 'tmp_obj_*' \) -delete`. Usar `git --no-optional-locks status` para no generar locks.
- **Indentación:** escribir los `.gd` con tabulaciones y comprobarlo (`grep -c $'^\t'`).
- **`_ready` en subclases:** en GDScript el `_ready` de una clase hija **no** llama al de la base: usar `super()`.
- **`.tscn` a mano:** las exportaciones de tipo nodo requieren `node_paths=PackedStringArray("nombre")` en el encabezado del nodo. Las formas de colisión propias por instancia se marcan `resource_local_to_scene = true`. Los `Resource` de config compartidos en la escena van como `ExtResource` (con su archivo `.tres` visible), no como sub-recurso embebido: LT no los encuentra si están embebidos. Máscaras de colisión: capa 5 = 16, capa 6 = 32.
- **Godot reescribe archivos** al abrir el editor (`unique_id`, `uid`, `project.godot`, `.tres` sin los valores por defecto). Es esperable; los `.gd.uid` se commitean. Si LT tiene cambios de prueba en `.tscn`/`.tres`, un `git stash pop` puede dar conflicto: resolver conservando ambos lados y **nunca descartar** cambios de LT sin que lo pida.
- **Simulación headless:** script `extends SceneTree` ejecutado con `timeout 170 .tools/godot --headless --path . -s $HOME/sims/<script>.gd`, guardado **fuera** del repo (por ejemplo `$HOME/sims/`). Detalles que costaron tiempo:
  - En `_init` el árbol todavía no está listo: empezar con `await process_frame`. El autoload no se puede nombrar como identificador global dentro de un script `-s`: `root.get_node("/root/GameManager")`.
  - Para escenas completas usar `change_scene_to_file(...)` y esperar frames (a veces `current_scene` sigue en `null` 4 frames después; esperar hasta ~20). Tras un `restart()` (recarga) esperar también ~20 frames.
  - Simular la tecla R con `InputEventAction` (`action = &"restart"`, `pressed = true`) y `Input.parse_input_event(e)`.
  - Un jugador quieto en el inicio muere por el tentáculo en ≈ 148 frames (con los valores de prueba actuales): en pruebas largas, anular al tentáculo (`set_physics_process(false)` y `KillZone.monitoring = false`) o el estado pasa a `LOST`. La cámara tarda `start_delay` (2 s = 120 frames) en empezar a subir.
  - Para teletransportar al jugador con la física activa alcanza con asignar `global_position`. Para copiar su config sin gravedad: `config.duplicate()` con `gravity_with_fuel = 0` y `gravity_without_fuel = 0`.
  - Los avisos `ObjectDB instances were leaked` al salir del script son esperables.
- **Valores de prueba de LT:** los `.tres` son valores de prueba; no tocar `player_config.tres`, `scroll_config.tres`, `tentacle_config.tres` ni `level_config.tres` salvo que el paso lo pida.
- **`docs/.obsidian/`** está en `.gitignore` (LT lee los `.md` con Obsidian): no commitearlo.

## Cierre

1. `docs/ROADMAP.md`: pasos 8 y 8b en Hecho; 8c (táctil) pendiente para el final; decisiones nuevas anotadas; "Estado global" al día. Revisar que `ARQUITECTURA.md` refleje el árbol de escenas (con `Main`), las señales y el flujo de partida finales.
2. Si había cambios de prueba de LT apartados: `git stash pop` (avisar si hay conflicto; no resolver descartando sus cambios).
3. **Confirmación antes de tocar GitHub.** Mostrarle a LT: el árbol de archivos nuevo o modificado, `git log --oneline main..HEAD` y `git diff --stat main`, y el contenido de los `.tres` nuevos. Esperar su confirmación explícita.
4. Con la confirmación: login de `gh` (ver notas), `git push -u origin feature/titulo-y-hud`, `gh pr create --base main --title "Pantalla de título y HUD mínimo (pasos 8 y 8b)"` con la descripción tomada de los commits, y **mergear con `gh pr merge --merge`** (LT ya indicó que Cowork lo hace cuando él confirma). Luego `git checkout main` y `git pull`.
5. Cerrar diciéndole a LT cómo continuar: quedan el balance del MVP, el arte y audio (paso 9) y los controles táctiles (paso 8c), y ofrecerle generar el brief 05.

## Resultado esperado

- Rama `feature/titulo-y-hud` publicada, PR abierto y mergeado, con los commits `paso0`, `paso8`, `paso8b` (más los de ajustes tras QA, si los hubo).
- Un juego que **abre en la pantalla de título** (F5): título y botón grande de jugar sobre el nivel quieto; al pulsar, el menú se disuelve y arranca la partida; R reinicia directo al juego con un nivel nuevo.
- HUD mínimo con barra de combustible y progreso del nivel.
- `docs/` con `pantalla-titulo.md` y `hud.md`, `ARQUITECTURA.md` al día y el roadmap listo para el siguiente brief (balance, arte/audio y táctil).
