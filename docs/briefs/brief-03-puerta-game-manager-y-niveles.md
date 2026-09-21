# Brief 03 — Puerta, game manager y niveles por segmentos (pasos 0, 5, 6 y 7) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork). No hace falta adjuntar nada: todo el contexto está acá y en `docs/` del repo (que Claude puede leer en la carpeta conectada).

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior y el jugador usa un jetpack con combustible limitado para esquivar obstáculos, recoger tanques y llegar a una puerta antes de que lo atrapen.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D. Viewport vertical **360×640** (ventana de PC a 1,5×).
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). **Rama base:** `main`. Trabaja LT con un socio, que **no toca nada hasta que esté el MVP**: no hay que avisarle de nada.
- **Estado del repo:** `main` incluye el brief 01 (PR #1: proyecto, jugador, cámara, tentáculo) y el brief 02 (PR #2: obstáculos y tanques). Leer **antes de escribir código**: `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md` y `docs/mecanicas/*.md`.
- **Alcance de este brief:** paso 0 (preparación), paso 5 (puerta y victoria), paso 6 (game manager y ciclo de partida) y paso 7 (niveles **por segmentos**). **Fuera de alcance:** pantalla de título, UI (barra de combustible, etc.), controles táctiles, arte final, audio, puntaje, balance. Todo lo visual sigue siendo `Polygon2D` placeholder.

## Qué necesita aportar LT

1. Pegar este brief en la conversación nueva. Nada más.
2. Carpeta del repo conectada a la sesión. `git` y `gh` deben poder operar (ver "Notas técnicas").
3. Jugar cada paso y responder la checklist con el formato `1. OK / 2. KO (motivo)`.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- **Fin de partida (MVP):** al llegar a la puerta el jugador **gana y el juego termina**; para volver a jugar hay que reiniciar (R). Un sistema de puntos u otra progresión queda **a definir más adelante** (no implementar puntaje, pero no cerrar la puerta: ver GameManager).
- **Niveles por segmentos (primordial):** cada partida debe sentirse distinta. Un nivel se arma en cada partida ensamblando **segmentos** escritos a mano (escenas reutilizables) elegidos al azar, con una semilla (seed) reproducible.
- **Balance:** se deja para cuando el MVP esté listo. Los valores de las configs son de prueba. **No anotar nada en `docs/TUNING_LOG.md`** (solo se usa para pruebas reales de balance, a pedido de LT).
- Control por acciones del Input Map: propulsar en 4 direcciones (WASD/flechas), `jump` (Espacio), `restart` (R), `debug_toggle` (F3). La muerte es siempre `Player.die(cause)`, que emite `Player.died(cause)`.
- **Todo valor de gameplay es variable exportada** en un `Resource` de configuración (`resources/configs/*.tres`). Lo que es diseño de nivel (tamaño, posición) va en la instancia.
- **Documentación obligatoria**: cualquier persona debe entender el código leyendo `docs/` y los comentarios.
- **Colores de placeholder:** rojo `#D83232` = letal, cian `#63D6C5` = recogible. **Nuevo en este brief:** naranja `#FF6B32` = objetivo/meta (la puerta). Documentar en `CONVENCIONES.md`.
- **Propuestas de Claude (LT las validará jugando; si hay un problema, avisar):**
  - `GameManager` es un **autoload** (un script cargado durante todo el juego, accesible por nombre desde cualquier lugar, que sobrevive al reinicio de escena). Lleva el estado de la partida y avisa con señales; no conoce nodos de la escena. **Validado por LT.**
  - UI del MVP = solo el mensaje de fin de partida (victoria o derrota) + el overlay F3 existente.
  - Un segmento mide 360 px de ancho por una altura fija (por defecto 640 px, una pantalla).

## Reglas de trabajo

1. **Gates:** al terminar cada paso, detenerse, entregar la checklist y esperar el "seguí" de LT. Cowork no puede jugar; el juicio de "se siente bien" es de LT.
2. **Git:** rama `feature/puerta-game-manager-niveles` desde `main` actualizado. Un commit por paso (`pasoN: descripción`); los ajustes tras el QA de LT pueden ir en un commit `pasoN: ajustes tras QA`. **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y el resumen de cambios (ver Cierre).
3. **No modificar** `Main.tscn`, `lvl1.tscn`, los sprite sheets ni el renderer (solo reportar cuál está en uso). No agregar assets. **No cambiar la escena principal** del proyecto (`run/main_scene`): las escenas nuevas se prueban con F6. `project.godot` solo se toca para registrar el autoload (paso 6).
4. **GDScript tipado** en todo (variables, parámetros, retornos), indentado con **tabulaciones**. Comentarios `##` en cada clase, variable exportada, señal y función pública. Comentarios en español, identificadores en inglés.
5. **Variables exportadas agrupadas** con `@export_group`, con unidad en el comentario (px, px/s, s, u).
6. **Sin valores hardcodeados**: si un número afecta el gameplay va en un `Resource`. Lo puramente visual o estructural va como `const` con comentario `## ... Solo visual.` / `Estructural.`
7. **Validación por CLI** tras cada paso: `godot --headless --path . --quit`, un script que cargue e instancie todas las escenas y scripts, y **simulación headless** de los comportamientos nuevos (ver "Notas técnicas"). Reportar errores. Guardar los scripts de prueba **fuera** del repo.
8. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.
9. **`TUNING_LOG.md`:** no se toca (ver Decisiones).

## Estado actual del código (resumen para no tener que descubrirlo)

### Capas de colisión 2D (ya nombradas en el proyecto)

| Capa | Nombre | Valor (bit) | Uso |
|---|---|---|---|
| 1 | `world` | 1 | Suelo, paredes, plataformas, límites de pantalla |
| 2 | `player` | 2 | Jugador |
| 3 | `obstacles` | 4 | Obstáculos y trampas |
| 4 | `tentacle` | 8 | Zona letal del tentáculo |
| 5 | `goal` | 16 | **Puerta (la usa este brief)** |
| 6 | `pickups` | 32 | Tanques |

Áreas (`Area2D`) de peligro, meta o recogible: máscara 2 (detectan al jugador), sin colisión física con él.

### API existente que se usa

| Elemento | Detalle |
|---|---|
| `Player` (grupo `player`, `class_name Player`, `CharacterBody2D` 16×24 px) | `die(cause)`, `add_fuel(amount)`, `is_alive()`, `get_fuel()`, `get_fuel_ratio()`, `is_fuel_empty()`, `reset(spawn)`; señales `died(cause)`, `fuel_changed`, `fuel_depleted`, `fuel_refilled`, `thrust_started/stopped`, `jumped`. Config `PlayerConfig` (`max_fuel` 100, consumo 15 u/s, salto ≈ 61 px sin combustible; un tanque de 40 u da ≈ 489 px de subida vertical) |
| `ScrollCamera` (`Camera2D`) | `get_visible_rect()`, `get_bottom_y()`, `set_scrolling(bool)`, `reset()`; señales `scroll_started/stopped`. Config `ScrollConfig`: `scroll_speed` 40 px/s, `start_delay` 2 s, `stop_at_enabled` / `stop_at_y` (**Y del centro de la cámara**, no del borde), paredes laterales y superior que siguen a la cámara (`ScreenBounds`) |
| `Tentacle` | `player_caught(cause)`, `reset()`; export `camera` (obligatoria). Mata por contacto (`&"tentacle"`) o caída bajo la pantalla (`&"fell"`) llamando a `Player.die` |
| `Obstacle` / `MovingObstacle` / `PulseTrap` (`Area2D`, `@tool`) | Matan con causa `&"obstacle"` / `&"trap"`. `size`, `travel`, `config` por instancia. Origen = centro del bloque. `PulseTrap` es sólida mientras es segura. Configs en `resources/configs/`. Ver `docs/mecanicas/obstaculos.md` |
| `FuelTank` (`Area2D`) | `collected(amount)`, `reset()`, `is_available()`. Config `FuelTankConfig` (`fuel_amount` 40). Ver `docs/mecanicas/tanques.md` |
| `sandbox_controller.gd` | **TEMPORAL**: escucha `Player.died`, muestra el mensaje según la causa (`DEATH_TEXTS`), detiene el scroll y recarga la escena con `restart`. Lo reemplaza el game manager (paso 6) |
| `scenes/levels/sandbox.tscn` | Escena de prueba: columna alta con plataformas, 6 obstáculos, 4 tanques. Hay que conservarla jugable |

Colores de placeholder de plataformas: azul frío `#3A9BBF` (`Color(0.2275, 0.6078, 0.749, 1)`). Paleta completa en `assets/palette.md`.

### Nombres y estilo

- Archivos `.gd`: `snake_case`. Escenas `.tscn` y `class_name`: `PascalCase`. Variables y funciones: `snake_case`. Constantes: `UPPER_SNAKE`.
- Señales hacia arriba, llamadas hacia abajo: una escena hija emite señales; el padre la controla llamando a su API. Una hija no busca a su padre ni a sus hermanas.
- Textos de UI en español rioplatense ("pulsá R para reiniciar").

---

## PASO 0 — Preparación

**Objetivo:** rama, brief y documentación listos.

### 0.1 Rama y working tree
Si hay cambios sin commitear (valores de prueba de LT), apartarlos con `git stash push -m "valores de prueba LT"` y devolverlos al final; **no** subirlos. Luego `git checkout main`, `git pull`, `git checkout -b feature/puerta-game-manager-niveles`. Confirmar árbol limpio.

### 0.2 Brief y docs
- Copiar este brief a `docs/briefs/brief-03-puerta-game-manager-y-niveles.md` (si LT ya lo dejó ahí sin trackear, solo commitearlo).
- `docs/ROADMAP.md`: corregir "Estado global" (hoy dice que los pasos 4 y 4b están pendientes de merge: ya están en `main`, PR #2); marcar los pasos 5, 6 y 7 "En brief / brief-03"; redefinir el paso 7 como **"Niveles por segmentos"** (en vez de "Nivel de prueba jugable"); agregar a la tabla de decisiones: fin de partida MVP, niveles por segmentos con seed, `GameManager` como autoload, naranja = meta, UI del MVP mínima; y quitar de "Riesgos" la decisión abierta "niveles fijos o por segmentos" (resuelta: segmentos).
- `docs/CONVENCIONES.md`: agregar naranja `#FF6B32` = objetivo/meta a "Colores de placeholder".

**Criterios de aceptación:**
- [ ] `git status` limpio en la rama nueva y `docs/` actualizado como arriba.

**Commit:** `paso0: preparación del brief 03`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 5 — Puerta y victoria

**Objetivo:** una puerta de meta que, al tocarla, gana la partida. Provisorio hasta el paso 6: se prueba en el sandbox con el controlador temporal.

### 5.1 Puerta: `scenes/goal/Door.tscn` + `scripts/goal/door.gd`
- `class_name Door extends Area2D`, `@tool`. Capa 5 (valor 16), máscara 2.
- Nodos: `Body` (`Polygon2D`, naranja `#FF6B32`) y `CollisionShape2D` (`RectangleShape2D`, forma única por instancia: `resource_local_to_scene = true` en la escena). Origen = centro.
- `@export_group("Forma") @export var size: Vector2 = Vector2(48, 72)` (px), con setter que regenera polígono y forma (también en el editor). Detalle visual opcional (marco o "picaporte") con un `Polygon2D` extra en blanco azulado `#C8E7EA`. **Sin config `Resource`**: no hay valores de gameplay más allá del tamaño (de nivel).
- **Señal:** `player_reached()`. Al entrar un `Player` **vivo**: emitir `player_reached()` una sola vez (ignorar reingresos). **No** llama a `Player`: la reacción es del nivel/manager (señales hacia arriba).
- **API pública:** `reset() -> void` (vuelve a poder activarse).

### 5.2 Jugador: estado "ganó"
Tras ganar, el jugador no debe seguir propulsando ni gastando combustible, y **ni el tentáculo ni un obstáculo pueden matarlo después**. Propuesta: agregar a `Player` la función `win() -> void` (desactiva el control, velocidad cero, emite `won()`), y que `is_alive()` devuelva `false` desde ese momento (documentar que significa "partida en curso para el jugador", no solo "no murió"); así los peligros existentes, que ya ignoran a un jugador no vivo, no necesitan cambios. Si se elige otra solución, justificarla y verificar lo mismo por simulación. Actualizar `docs/mecanicas/jugador.md`.

### 5.3 Sandbox y controlador temporal
- En `sandbox.tscn` agregar una `Door` cerca de la cima (la plataforma más alta), con un nombre claro. Dejar el resto intacto.
- `sandbox_controller.gd` (sigue TEMPORAL): conectar `Door.player_reached` → llamar `Player.win()`, mostrar en el `Label` "ESCAPASTE — pulsá R para reiniciar" y `ScrollCamera.set_scrolling(false)`. El `restart` sigue recargando la escena.
- **Verificar por simulación:** tras ganar, el tentáculo no lo mata aunque lo alcance, y un obstáculo tampoco.

### 5.4 Documentación
`docs/mecanicas/puerta.md` (propósito, modelo, señales, API, estructura de nodos, cómo colocarla, cómo probarla) y actualizar `ARQUITECTURA.md` (árbol, señales, causas/estado de fin) y `README.md` (carpetas nuevas).

**Criterios de aceptación (checklist para LT):**
- [ ] Llegar a la puerta muestra "ESCAPASTE — pulsá R para reiniciar" y la cámara se detiene.
- [ ] Tras ganar no se puede seguir moviendo al jugador ni gasta combustible.
- [ ] Tras ganar, el tentáculo (o un obstáculo) ya no lo mata.
- [ ] R reinicia y la puerta vuelve a funcionar.
- [ ] Cambiar `size` de la puerta en el inspector cambia forma y área (también en el editor).
- [ ] Las muertes por tentáculo, caída, obstáculo y trampa siguen funcionando (regresión).

**Commit:** `paso5: puerta y victoria`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 6 — Game manager y ciclo de partida

**Objetivo:** un solo lugar que sabe en qué estado está la partida, reemplazando al controlador temporal.

### 6.1 `GameManager` (autoload): `scripts/managers/game_manager.gd`
Registrarlo como autoload `GameManager` editando la sección `[autoload]` de `project.godot` (`GameManager="*res://scripts/managers/game_manager.gd"`). La carpeta raíz `autoload/` ya existe vacía: revisar `README.md`/`ARQUITECTURA.md` y elegir dónde vive el script; documentarlo.

- `enum State { READY, PLAYING, WON, LOST }`.
- **Señales:** `run_started(seed: int)`, `run_won()`, `run_lost(cause: StringName)`, `state_changed(new_state: State, old_state: State)`.
- **API pública:** `start_run(seed: int = 0) -> void` (pasa a `PLAYING`), `notify_player_died(cause: StringName) -> void`, `notify_goal_reached() -> void`, `restart() -> void` (recarga la escena actual), `get_state() -> State`, `get_current_seed() -> int`, `get_last_death_cause() -> StringName`.
- **Reglas:** las transiciones solo valen desde `PLAYING`; cualquier notificación posterior se ignora (por ejemplo, morir después de ganar). No conoce nodos de la escena (no hace `get_node` a nada); solo señales y estado. Escucha la acción `restart` (R) en `_unhandled_input` y llama a `restart()`.
- **Pensado para crecer:** no implementar puntaje, pero dejar el estado desacoplado (un puntaje futuro se agregaría acá sin tocar el nivel). Documentar cómo.

### 6.2 `LevelController` reemplaza a `sandbox_controller.gd`
- `scripts/levels/level_controller.gd`, script raíz de los niveles jugables (incluido `sandbox.tscn`). Conecta `Player.died` → `GameManager.notify_player_died`, `Door.player_reached` → `GameManager.notify_goal_reached`, y llama `GameManager.start_run()` al iniciar.
- Escucha `GameManager.state_changed` y reacciona: en `WON` llama `Player.win()`, detiene el scroll y muestra el mensaje de victoria; en `LOST` detiene el scroll y muestra el mensaje según la causa (mismo mapa `DEATH_TEXTS` que hoy: `&"tentacle"`/`&"fell"` → "CAPTURADO — pulsá R para reiniciar", `&"obstacle"`/`&"trap"` → "GOLPEADO — pulsá R para reiniciar", otra → "PERDISTE — pulsá R para reiniciar"). Los textos y el mapa son `const` visuales.
- Eliminar `sandbox_controller.gd` (y su `.uid`); `sandbox.tscn` pasa a usar `LevelController`. Actualizar `ARQUITECTURA.md` (flujo de partida final, autoload, señales, receptores de `died` y `player_reached`).

### 6.3 Documentación
`docs/mecanicas/game-manager.md`: qué es un autoload y por qué se eligió, máquina de estados (tabla de transiciones), señales, API, cómo reaccionar a un estado desde otra escena, cómo agregar puntaje más adelante, cómo probar.

**Criterios de aceptación (checklist para LT):**
- [ ] Ganar y perder siguen mostrando su mensaje y R reinicia (regresión de los pasos 4 y 5).
- [ ] Cada causa de muerte muestra el texto correcto (tentáculo, caída, obstáculo, trampa).
- [ ] Ganar y luego ser alcanzado por el tentáculo no cambia el resultado (sigue "ESCAPASTE").
- [ ] El overlay F3 y los tanques siguen funcionando.
- [ ] `docs/` explica el game manager de forma que se entienda sin haber leído el código.

**Commit:** `paso6: game manager y ciclo de partida`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 7 — Niveles por segmentos

**Objetivo:** que cada partida arme un nivel distinto ensamblando segmentos escritos a mano, con seed reproducible, y que el nivel termine en una puerta.

### 7.1 Contrato de un segmento: `scripts/levels/level_segment.gd` + escenas en `scenes/levels/segments/`
- `class_name LevelSegment extends Node2D`, `@tool`. Un segmento ocupa el rectángulo **x ∈ [0, 360], y ∈ [−height, 0]** en coordenadas locales (**origen = esquina inferior izquierda**); se coloca en el mundo con su origen en la Y de su borde inferior.
- `@export var height: float = 640.0` (px, diseño de nivel). En el editor dibuja el contorno del segmento (`_draw` solo con `Engine.is_editor_hint()`).
- `_get_configuration_warnings()` (`@tool`): avisa si el segmento no contiene ningún `FuelTank` (los segmentos intermedios deben tener al menos uno) o si algún hijo directo queda fuera del rectángulo.
- Reglas de diseño (escribirlas en la doc, son criterio del autor del segmento, no se validan): apoyos (plataformas) en los primeros ≈ 120 px y en los últimos ≈ 120 px, para que el jugador siempre tenga dónde apoyarse al pasar de un segmento a otro; al menos un tanque alcanzable; usar las escenas existentes (`Obstacle`, `MovingObstacle`, `PulseTrap`, `FuelTank`) con configs por instancia; recordar que un salto sin combustible llega ≈ 61 px y que un tanque de 40 u rinde ≈ 489 px en vertical.
- **Segmento de inicio:** `SegmentStart.tscn` (altura 640): suelo, plataforma de inicio y un `Marker2D` llamado `PlayerSpawn` (posición equivalente a la del sandbox: (180, 548) en coordenadas de un segmento cuyo borde inferior está en Y = 640).
- **Segmento final:** `SegmentEnd.tscn` (altura 640): plataformas y una `Door` cerca de la parte superior; sin tentáculo ni requisitos extra.
- **Segmentos intermedios:** crear **6** (`Segment01.tscn` … `Segment06.tscn`), variados (por ejemplo: plataformas escalonadas con tanque; pasillo estrechado por bloque estático y móvil; dos trampas con distinto desfase; tanque en plataforma alta que solo se alcanza saltando; móviles cruzados; tanque junto a una trampa). Todos con al menos un tanque. **No copiar el sandbox**: son piezas nuevas y más cortas.

### 7.2 Configuración y generador
- `scripts/levels/level_config.gd` (`class_name LevelConfig extends Resource`) con instancia por defecto `resources/configs/level_config.tres`:

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Nivel | `segment_count` | 6 | — | Cantidad de segmentos intermedios por partida |
| Nivel | `seed` | 0 | — | 0 = aleatoria en cada partida; distinto de 0 = fija (para reproducir un nivel) |
| Nivel | `avoid_repeat_window` | 1 | — | Un segmento no se repite dentro de los últimos N elegidos (con un pool chico se relaja solo cuando no hay opciones) |
| Segmentos | `start_segment` / `end_segment` | `SegmentStart` / `SegmentEnd` | — | Escenas fijas de inicio y final |
| Segmentos | `segment_pool` | los 6 intermedios | — | Escenas candidatas (`Array[PackedScene]`) |

- `scripts/levels/level_builder.gd` (`class_name LevelBuilder extends Node2D`), export `config: LevelConfig`. Usa un `RandomNumberGenerator` propio con la seed (**nunca** el `randi()` global) para que la misma seed dé el mismo nivel.
- **API pública:** `build(seed_override: int = 0) -> int` (arma el nivel y devuelve la seed usada; limpia el anterior si lo hay), `clear() -> void`, `get_player_spawn() -> Vector2` (posición global), `get_camera_stop_y() -> float` (Y global del centro de la cámara para que el segmento final quede completo a la vista), `get_segment_count() -> int`. **Señal:** `level_built(seed: int)`.
- Apilado: el segmento de inicio con su borde inferior en Y = 640 (la cámara arranca mostrando 0–640); cada segmento siguiente arriba del anterior (sumando su `height`); el final va último.
- **Cámara:** el constructor no modifica el `.tres` compartido de `ScrollConfig`. Agregar a `ScrollCamera` una función pública `set_stop_y(y: float) -> void` (activa el tope en esa Y solo para la instancia) y documentarla en `scroll-camara.md`.

### 7.3 Escena jugable `scenes/levels/Level.tscn`
Raíz con `LevelController`; hijos `LevelBuilder`, `ScrollCamera`, `Player`, `Tentacle`, `DebugOverlay`, capa de mensaje. Al iniciar: construir el nivel, ubicar al jugador en `get_player_spawn()`, fijar el tope de cámara con `get_camera_stop_y()` y llamar `GameManager.start_run(seed)`. **R construye un nivel nuevo** (`restart()` recarga la escena; con `seed` = 0 sale otro nivel, con seed fija sale el mismo). El overlay F3 muestra además la **seed** de la partida (para poder reportar "este nivel estuvo raro").

Probar `Level.tscn` con **F6**. **No** cambiar la escena principal: al final del paso, preguntarle a LT si quiere que `Level.tscn` pase a ser la escena principal (F5).

### 7.4 Documentación
`docs/mecanicas/niveles-por-segmentos.md`: propósito, modelo (cómo se arma un nivel, seed y reproducibilidad), contrato del segmento con un diagrama simple de coordenadas, tablas de `LevelConfig`, API de `LevelBuilder`, **guía paso a paso para crear un segmento nuevo** (escena, altura, qué poner, reglas de diseño, cómo agregarlo al pool, cómo verlo aislado con F6), cómo probar. Actualizar `ARQUITECTURA.md`, `README.md` y `ROADMAP.md`.

### 7.5 Validación por simulación (script fuera del repo)
- Construir **200 seeds** distintas: sin errores; cada nivel tiene inicio + `segment_count` intermedios + final, en ese orden y apilados sin huecos ni solapes; no hay repeticiones dentro de la ventana cuando el pool lo permite.
- La misma seed produce el mismo nivel (misma secuencia de segmentos); seeds distintas producen secuencias distintas (medir cuántas de las 200 son distintas).
- Cada segmento del pool: dentro del rectángulo de 360 × `height`, con al menos un `FuelTank`, sin advertencias de configuración.
- Corrida de 300 frames de `Level.tscn` con jugador quieto: el tentáculo lo mata y el manager pasa a `LOST`; teletransportar al jugador a la puerta: pasa a `WON`; reinicio: nuevo nivel (seed distinta cuando `seed` = 0).

**Criterios de aceptación (checklist para LT):**
- [ ] Al iniciar con F6 aparece un nivel completo: inicio, segmentos y una puerta al final.
- [ ] Reiniciando con R varias veces, el nivel cambia (orden de segmentos distinto).
- [ ] Con `seed` distinta de 0 en `level_config.tres`, el nivel se repite igual en cada reinicio; la seed se ve en F3.
- [ ] Se puede llegar a la puerta y ganar ("ESCAPASTE"); la cámara se detiene con el segmento final completo a la vista.
- [ ] Se pasa de un segmento al siguiente sin quedar trabado ni con obstáculos superpuestos en las uniones.
- [ ] Los 6 segmentos se sienten distintos y todos tienen algún tanque.
- [ ] `docs/mecanicas/niveles-por-segmentos.md` explica cómo crear un segmento nuevo de forma que LT pueda hacerlo sin ayuda.
- [ ] Ganar, perder y reiniciar siguen funcionando; el sandbox sigue jugable (regresión).

**Commit:** `paso7: niveles por segmentos`

> **Detenerse y esperar el "seguí" de LT.**

---

## Notas técnicas (aprendidas en los briefs 01 y 02)

- **Godot y `gh` en el shell local:** el shell del equipo de LT (`device_bash`) es una VM Linux. Godot 4.7.2 headless: `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`, instalado **fuera del repo** (por ejemplo `~/godot`, con un enlace `~/godot/godot`). Tras crear clases nuevas (`class_name`), correr `godot --headless --path . --import` para registrarlas y generar los `.gd.uid`. `gh`: la última versión sale de la API de releases (`https://api.github.com/repos/cli/cli/releases/latest`), se descarga `gh_<versión>_linux_amd64.tar.gz` y se copia el binario a `~/bin`. Si no están (la VM puede reiniciarse), reinstalarlos.
- **Autenticación de `gh`:** flujo de dispositivo con client id `178c6fc778ccc68e1d6a` y scopes `repo read:org`: primero `POST https://github.com/login/device/code` (guardar `device_code`, mostrarle a LT `user_code` y `https://github.com/login/device`); cuando LT confirme, `POST https://github.com/login/oauth/access_token` con `grant_type=urn:ietf:params:oauth:grant-type:device_code`; `gh auth login --with-token`, luego `gh auth setup-git`. Hacerlo en **dos llamadas separadas** (los procesos en segundo plano no sobreviven a la llamada) y borrar los archivos temporales del token.
- **Identidad de git:** no hay `user.name` configurado; usar `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com ...` en cada commit y **no** modificar la config. Terminar los commits con las líneas de atribución que indique el sistema.
- **Locks de git:** el shell no puede borrar `.git/index.lock`, `.git/HEAD.lock`, `.git/objects/maintenance.lock` ni los `tmp_obj_*` que git deja hasta que LT apruebe `device_request_delete_permission` para la carpeta del repo. **El permiso puede vencer entre sesiones/días**: si un `rm` falla con "Operation not permitted", pedirlo de nuevo con un motivo claro (archivos a borrar). Revisar `find .git -name '*.lock'` tras cada commit. Usar `git --no-optional-locks status` para no generar locks. Si un `git stash` falla a medias puede dejar un stash duplicado: verificar con `git stash list` y comparar antes de borrar uno.
- **Indentación:** escribir los `.gd` con tabulaciones y comprobarlo (`grep -c $'^\t'`).
- **`_ready` en subclases:** en GDScript el `_ready` de una clase hija **no** llama al de la base: usar `super()` (así falló `MovingObstacle` en el brief 02). Un valor por defecto cambiado en `_init` de una subclase no se respeta al instanciar una escena heredada: fijarlo en la escena.
- **`.tscn` a mano:** las exportaciones de tipo nodo requieren `node_paths=PackedStringArray("nombre")` en el encabezado del nodo. Las formas de colisión propias por instancia se marcan `resource_local_to_scene = true`. Las escenas heredadas se declaran `[node name="X" instance=ExtResource("base")]`. Los `Resource` de config compartidos en la escena van como `ExtResource` (con su archivo `.tres` visible), no como sub-recurso embebido: LT no los encuentra si están embebidos. Máscaras de colisión: capa 5 = 16, capa 6 = 32.
- **Godot reescribe archivos** al abrir el editor (`unique_id`, `uid`, `project.godot`, `.tres` sin los valores por defecto). Es esperable; los `.gd.uid` se commitean. Si LT tiene cambios de prueba en `.tscn`/`.tres`, un `git stash pop` puede dar conflicto en los `.tscn` (a veces solo por ese ruido): resolver conservando ambos lados, verificar comparando sin `unique_id`/`uid`, y **nunca descartar** cambios de LT sin que lo pida.
- **Simulación headless:** script `extends SceneTree` ejecutado con `godot --headless --path . -s ruta/al/script.gd`, guardado **fuera** del repo. Instanciar la escena, mover acciones con `Input.action_press`, avanzar con `await physics_frame`. Cada corrida en pocos cientos de frames y con `timeout` (el shell corta a los 180 s). Un autoload no se puede nombrar como identificador global dentro de un script `-s`: accederlo con `root.get_node("/root/GameManager")`. Para probar detección con un jugador quieto: crear el `Player` con la posición **antes** de `add_child` y una copia de su config con gravedad 0 (cambiar `global_position` después de agregarlo, con la física desactivada, no llega al servidor de física). Hacer `reset()` con el jugador encima de un tanque lo recoge de nuevo al instante (es lo esperado). Un tentáculo con `extra_rise_speed` > 0 alcanza a un jugador quieto en el inicio en segundos: los valores de prueba de LT cambian los tiempos de las simulaciones.
- **Valores de prueba de LT:** los `.tres` son valores de prueba; no tocar `player_config.tres`, `scroll_config.tres` ni `tentacle_config.tres` salvo que el paso lo pida.

## Cierre

1. `docs/ROADMAP.md`: pasos 5, 6 y 7 en Hecho; decisiones nuevas anotadas; "Estado global" al día. Revisar que `ARQUITECTURA.md` refleje el árbol de escenas, las señales, el autoload y el flujo de partida finales.
2. Si había cambios de prueba de LT apartados: `git stash pop` (avisar si hay conflicto; no resolver descartando sus cambios).
3. **Confirmación antes de tocar GitHub.** Mostrarle a LT: el árbol de archivos nuevo o modificado, `git log --oneline` y `git diff --stat main`, y el contenido de los `.tres` nuevos. Esperar su confirmación explícita.
4. Con la confirmación: `git push -u origin feature/puerta-game-manager-niveles`, `gh pr create --base main --title "Puerta, game manager y niveles por segmentos (pasos 5 a 7)"` con la descripción tomada de los commits, y **mergear con `gh pr merge --merge`** (LT ya indicó que Cowork lo hace cuando él confirma). Luego `git checkout main` y `git pull`.
5. Cerrar diciéndole a LT cómo continuar: quedan la pantalla de título, la UI mínima y los controles táctiles (paso 8), el arte y audio (paso 9) y el balance del MVP.

## Resultado esperado

- Rama `feature/puerta-game-manager-niveles` publicada, PR abierto y mergeado, con los commits `paso0`, `paso5`, `paso6`, `paso7` (más los de ajustes tras QA, si los hubo).
- Un juego jugable de punta a punta: cada partida arma un nivel distinto (seed reproducible), se gana en la puerta ("ESCAPASTE") o se pierde por el tentáculo, la caída, un obstáculo o una trampa, y R reinicia con un nivel nuevo.
- `GameManager` (autoload) con estados y señales, listo para sumar puntaje más adelante.
- `docs/` con un documento por mecánica nueva (`puerta.md`, `game-manager.md`, `niveles-por-segmentos.md`), guía para crear segmentos, `ARQUITECTURA.md` al día y el roadmap listo para el brief 04 (título, UI mínima y controles táctiles).
