# Brief 02 — Obstáculos y tanques de combustible (pasos 0, 4 y 4b) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork), junto con `ROADMAP.md` y `BRIEF_TEMPLATE.md` adjuntos. Da todo el contexto necesario sin depender de conversaciones previas.

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior y el jugador usa un jetpack con combustible limitado para esquivar obstáculos y llegar a una puerta antes de que lo atrapen.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D.
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). **Rama base:** `main`. El socio de LT es colaborador.
- **Estado del repo:** `main` incluye el brief 01 mergeado (PR #1, pasos 0 a 3 del roadmap): configuración de proyecto, jugador con jetpack, cámara con scroll, tentáculo, overlay de debug, escena de prueba `scenes/levels/sandbox.tscn` (columna alta con plataformas) y toda la documentación en `docs/` (`ROADMAP`, `CONVENCIONES`, `ARQUITECTURA`, `TUNING_LOG`, `mecanicas/*`). Leer `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md` y `docs/mecanicas/*.md` antes de escribir código.
- **Alcance de este brief:** paso 0 (preparación), paso 4 (obstáculos: estático, móvil y trampa intermitente) y paso 4b (tanques de combustible). **Fuera de alcance:** puerta y victoria, game manager, UI, sprites finales. Todo lo visual sigue siendo `Polygon2D` placeholder con colores de `assets/palette.md`.

## Qué necesita aportar LT

1. Adjuntos: `ROADMAP.md`, `BRIEF_TEMPLATE.md` y este brief.
2. Ruta local del repo clonado (carpeta conectada a la sesión). `git` y `gh` operativos.
3. Working tree: LT tiene **cambios de prueba sin commitear** en `resources/configs/scroll_config.tres`, `resources/configs/tentacle_config.tres` y `scenes/levels/sandbox.tscn` (valores de tuning que **no** deben subirse). Antes de crear la rama hay que apartarlos con `git stash push -m "valores de prueba LT"` (paso 0) y devolverlos al final con `git stash pop`.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- Control por acciones del Input Map: propulsar en 4 direcciones (WASD/flechas), `jump` (Espacio), `restart` (R), `debug_toggle` (F3). Apoyado en una superficie el eje horizontal se camina sin gastar combustible.
- Combustible limitado; se recarga **solo con tanques** llamando a `Player.add_fuel(amount)`.
- Sin combustible: la gravedad sube y el jugador puede saltar desde una superficie (la regla exacta es configurable en `PlayerConfig`; LT tiene sus valores de prueba en `player_config.tres`).
- Contacto con obstáculo = derrota. La muerte es siempre `Player.die(cause)`, que emite `Player.died(cause)`.
- **Todo valor de gameplay es variable exportada** en un `Resource` de configuración, para poder iterar y descubrir qué es divertido.
- **Documentación obligatoria**: cualquier persona debe entender el código leyendo `docs/` y los comentarios.
- Niveles fijos o por segmentos: abierto. Por eso obstáculos y tanques son **escenas reutilizables**, configurables por instancia.
- Convención visual de placeholders (nueva): **rojo `#D83232` = letal** (el tentáculo ya lo es), **cian `#63D6C5` = recogible/bueno**. Se documenta en `CONVENCIONES.md`.

## Reglas de trabajo

1. **Gates:** al terminar cada paso, detenerse, entregar la checklist de prueba y esperar el "seguí" de LT. Cowork no puede jugar el juego; el juicio de "se siente bien" es de LT.
2. **Git:** crear la rama `feature/obstaculos-tanques` desde `main` actualizado. Un commit por paso (`pasoN: descripción`). **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y un resumen de cambios (ver Cierre).
3. **No modificar** `Main.tscn`, `lvl1.tscn` ni los sprite sheets. No agregar assets. En `sandbox.tscn` solo agregar lo que pide este brief.
4. **GDScript tipado** en todo (variables, parámetros, retornos), indentado con tabulaciones. Comentarios `##` en cada clase, variable exportada, señal y función pública.
5. **Variables exportadas agrupadas** con `@export_group`. Unidades en el comentario (px, px/s, px/s², s, u).
6. **Sin valores hardcodeados**: si un número afecta el gameplay, va en un `Resource` de configuración (`resources/configs/*.tres`). Los valores puramente visuales o estructurales van como `const` con comentario `## ... Solo visual.` / `Estructural.`
7. **Renderer:** no cambiar el renderer ni el driver gráfico; solo reportar cuál está en uso.
8. **Validación por CLI** tras cada paso: `godot --headless --path . --quit` y un script que cargue e instancie todas las escenas y scripts, más una **simulación headless** de los comportamientos nuevos (ver "Notas técnicas"). Reportar errores.
9. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.
10. **Merge:** lo hace LT (o lo pide explícitamente a Cowork con `gh pr merge --merge`), avisando antes a su socio por los conflictos en los `.tscn`.

## Notas técnicas (aprendidas en el brief 01)

- **Godot y `gh` en el shell local:** el shell del equipo de LT (`device_bash`) es una VM Linux; Godot 4.7.2 headless se descarga de `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` y se instala **fuera del repo** (por ejemplo `~/godot`). `gh` se instala igual en `~/bin`. Si no están (la VM puede reiniciarse), reinstalarlos. La autenticación de `gh`: flujo de dispositivo (client id `178c6fc778ccc68e1d6a`, scopes `repo read:org`) en dos llamadas separadas, porque los procesos en segundo plano no sobreviven a la llamada; LT ingresa el código en `github.com/login/device`. Luego `gh auth setup-git`.
- **Identidad de git:** no hay `user.name` configurado; usar `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com ...` en cada commit y **no** modificar la config.
- **`index.lock`:** git puede dejar `.git/index.lock` y el shell no puede borrarlo hasta que LT apruebe `device_request_delete_permission` para la carpeta del repo. Pedirlo una sola vez, con motivo claro. Usar `git --no-optional-locks status` para no generar el lock.
- **Indentación:** escribir los `.gd` con tabulaciones (convertir si hace falta).
- **`.tscn` a mano:** las exportaciones de tipo nodo requieren `node_paths=PackedStringArray("nombre")` en el encabezado del nodo, si no la referencia queda nula (así falló el overlay en el brief 01). Las máscaras de colisión son bits: capa 3 = valor 4, capa 6 = valor 32.
- **Godot reescribe archivos** al abrir el editor (`unique_id`, `uid`, `project.godot`, `.tres` sin los valores por defecto). Es esperable; los `.gd.uid` se commitean.
- **Simulación headless:** script `extends SceneTree` ejecutado con `godot --headless --path . -s ruta/al/script.gd` (guardar los scripts de prueba **fuera** del repo), instancia la escena, mueve acciones con `Input.action_press` y avanza con `await physics_frame`. Mantener cada corrida en unos pocos cientos de frames y usar `timeout` (el shell corta a los 180 s). Recargar escenas con `get_tree().reload_current_scene()` y esperar ~10 frames.
- **Valores de prueba de LT en `main`:** `player_config.tres` tiene `gravity_with_fuel = 150`, `jump_requires_empty_fuel = false`, `wall_bounce = 0.15`. No tocarlos.

## Tabla de referencia

### Capas de colisión 2D (ya nombradas en el proyecto)

| Capa | Nombre | Valor (bit) | Uso |
|---|---|---|---|
| 1 | `world` | 1 | Suelo, paredes, plataformas, límites de pantalla |
| 2 | `player` | 2 | Jugador |
| 3 | `obstacles` | 4 | Obstáculos y trampas |
| 4 | `tentacle` | 8 | Zona letal del tentáculo |
| 5 | `goal` | 16 | Puerta |
| 6 | `pickups` | 32 | Tanques de combustible y otros recogibles |

Obstáculos y tanques: `Area2D` con **máscara 2** (detectan al jugador); no colisionan físicamente con él.

### API existente que se usa

| Elemento | Detalle |
|---|---|
| `Player` (grupo `player`, `class_name Player`) | `die(cause: StringName)`, `add_fuel(amount: float)`, `is_alive() -> bool`, `get_fuel()`, `reset(spawn)`; señales `died(cause)`, `fuel_changed`, `fuel_depleted`, `fuel_refilled` |
| `ScrollCamera` | `get_visible_rect() -> Rect2`, `get_bottom_y() -> float`, `set_scrolling(bool)`, `reset()` |
| `Tentacle` | `player_caught(cause)`, `reset()` |
| `sandbox_controller.gd` | TEMPORAL; hoy escucha `Tentacle.player_caught` y recarga la escena con `restart` |

### Nombres y estilo

- Archivos `.gd`: `snake_case`. Escenas `.tscn` y `class_name`: `PascalCase`. Variables y funciones: `snake_case`. Constantes: `UPPER_SNAKE`.
- Identificadores en inglés. Comentarios y documentos en español.
- Señales hacia arriba, llamadas hacia abajo.

---

## PASO 0 — Preparación

**Objetivo:** dejar la rama, el brief, el roadmap y el controlador temporal listos para los pasos 4 y 4b.

### 0.1 Rama y working tree

`git stash push -m "valores de prueba LT"` (si hay cambios sin commitear), `git checkout main`, `git pull`, `git checkout -b feature/obstaculos-tanques`. Confirmar que el árbol queda limpio.

### 0.2 Brief y roadmap

- Copiar este brief a `docs/briefs/brief-02-obstaculos-y-tanques.md` (si LT ya lo dejó ahí sin trackear, solo commitearlo).
- `docs/ROADMAP.md`: corregir "Estado global" (el brief 01 ya está mergeado a `main`), marcar los pasos 4 y 4b como "En brief / brief-02", y agregar a la tabla de decisiones la convención de colores (rojo = letal, cian = recogible) y que obstáculos y tanques son escenas reutilizables configurables por instancia.
- `docs/CONVENCIONES.md`: agregar sección "Colores de placeholder" y una nota sobre escenas de nivel reutilizables con `@tool` (ver paso 4).

### 0.3 Controlador temporal escucha `Player.died`

Hoy `sandbox_controller.gd` escucha `Tentacle.player_caught`. Con varios orígenes de muerte conviene escuchar `Player.died(cause)`:

- Conectar `Player.died` (referencia por `@onready`/grupo `player`) y dejar de conectar `Tentacle.player_caught`.
- Al recibir la muerte: mostrar el `Label` con texto según la causa (`&"tentacle"` y `&"fell"` → "CAPTURADO — pulsá R para reiniciar"; `&"obstacle"` y `&"trap"` → "GOLPEADO — pulsá R para reiniciar"; cualquier otra → "PERDISTE — pulsá R para reiniciar") y `ScrollCamera.set_scrolling(false)`. El mapeo causa→texto va en un `Dictionary` constante del script.
- Seguir marcado como TEMPORAL (lo reemplaza el game manager, paso 6). Actualizar `ARQUITECTURA.md` (receptor de `died`).

**Criterios de aceptación:**
- [ ] El proyecto abre en Godot 4.7.2 sin errores ni advertencias nuevas.
- [ ] Morir por el tentáculo sigue mostrando el mensaje y R reinicia (regresión).
- [ ] `git status` limpio en la rama nueva; `docs/` actualizado como arriba.

**Commit:** `paso0: preparación del brief 02 y controlador escucha Player.died`

> **Detenerse aquí y esperar el "seguí" de LT.**

---

## PASO 4 — Obstáculos

**Objetivo:** tres escenas de peligro reutilizables (bloque estático, bloque móvil y trampa intermitente), configurables por instancia, que matan al contacto.

### 4.1 Obstáculo estático: `scenes/obstacles/Obstacle.tscn` + `scripts/obstacles/obstacle.gd`

- `class_name Obstacle extends Area2D`, marcado `@tool` para que el tamaño se vea al editarlo. Capa 3 (valor 4), máscara 2.
- Nodos: `Body` (`Polygon2D`, rojo `#D83232`) y `CollisionShape2D` (`RectangleShape2D`). Ambos se regeneran cuando cambia `size`, y se crea una forma nueva por instancia (no compartir el sub-recurso).
- `@export_group("Forma") @export var size: Vector2 = Vector2(48, 48)` (px), con setter que actualiza polígono y forma (también en el editor). Es diseño de nivel, no tuning.
- `@export_group("Letalidad") @export var cause: StringName = &"obstacle"`: causa que se pasa a `Player.die`.
- **Señal:** `player_hit(cause: StringName)`.
- Al entrar un `Player` vivo: emitir `player_hit(cause)` y llamar a `Player.die(cause)`. Ignorar si el jugador ya está muerto.
- **API pública:** `set_active(active: bool) -> void` (activa/desactiva la detección con `set_deferred("monitoring", ...)`; la usan las trampas).

### 4.2 Obstáculo móvil: `scenes/obstacles/MovingObstacle.tscn` + `scripts/obstacles/moving_obstacle.gd`

- `class_name MovingObstacle extends Obstacle` (`@tool`). Se mueve en `_physics_process` yendo y viniendo entre su posición inicial y `inicial + travel`.
- Configuración: `scripts/obstacles/moving_obstacle_config.gd` (`class_name MovingObstacleConfig extends Resource`), instancia por defecto en `resources/configs/moving_obstacle_config.tres`.

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Movimiento | `speed` | 60 | px/s | Velocidad de desplazamiento |
| Movimiento | `pause_at_ends` | 0.5 | s | Pausa en cada extremo |
| Movimiento | `ease_at_ends` | true | — | Si es true, acelera y frena suave cerca de los extremos |
| Movimiento | `start_delay` | 0.0 | s | Espera antes de empezar (para desfasar varias instancias) |

- Por instancia (diseño de nivel): `@export var travel: Vector2 = Vector2(120, 0)` (px, desplazamiento del extremo final respecto del inicial) y `@export var config: MovingObstacleConfig`.
- En el editor (`@tool`) dibujar la trayectoria con un `Line2D` hijo o `_draw` (solo con `Engine.is_editor_hint()`), para poder colocarlos a ojo.
- **API pública:** `reset() -> void` (vuelve al inicio y reinicia el ciclo).

### 4.3 Trampa intermitente: `scenes/obstacles/PulseTrap.tscn` + `scripts/obstacles/pulse_trap.gd`

- `class_name PulseTrap extends Obstacle` (`@tool`; `cause` por defecto `&"trap"`). Alterna entre inactiva (segura) y activa (letal).
- Configuración: `scripts/obstacles/pulse_trap_config.gd` (`class_name PulseTrapConfig extends Resource`), instancia en `resources/configs/pulse_trap_config.tres`.

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Ciclo | `on_time` | 1.5 | s | Tiempo activa (letal) |
| Ciclo | `off_time` | 1.5 | s | Tiempo inactiva (segura) |
| Ciclo | `warning_time` | 0.5 | s | Últimos segundos del `off_time` en que parpadea avisando (se recorta a `off_time`) |
| Ciclo | `initial_offset` | 0.0 | s | Desfase del ciclo al empezar |

- Visual: inactiva = azul frío `#3A9BBF` con alfa 0.35; aviso = parpadeo blanco azulado `#C8E7EA`; activa = rojo `#D83232`. Las frecuencias/colores de parpadeo son `const` visuales.
- **Si el jugador está dentro cuando se activa, muere** (verificarlo en la simulación: al reactivar `monitoring` con un cuerpo ya superpuesto, comprobar que llega `body_entered`; si no, revisar con `get_overlapping_bodies()` en el frame de activación).
- **Señales:** `activated()`, `deactivated()`. **API pública:** `reset()`.

### 4.4 Sandbox

En `scenes/levels/sandbox.tscn`, instanciar en el primer tramo sobre el inicio (entre las plataformas 1 y 6): 2 `Obstacle` estáticos (uno que estreche un pasillo, uno grande), 2 `MovingObstacle` (uno horizontal, uno vertical, con `start_delay` distinto) y 2 `PulseTrap` (una ancha, una angosta, con `initial_offset` distinto). Con nombres claros (`Obstacle1`, `MovingObstacle1`, `PulseTrap1`, ...). Dejar el resto del sandbox intacto.

### 4.5 Documentación

- `docs/mecanicas/obstaculos.md`: propósito, modelo (qué mata, cómo se detecta, por qué son `Area2D`), tablas completas de parámetros de las tres configs (nombre, tipo, valor inicial, unidad, efecto, consejo de tuning), señales, API pública, estructura de nodos, cómo colocarlos en un nivel (tamaño, `travel`, `@tool`), cómo probarlos.
- Actualizar `ARQUITECTURA.md` (árbol de escenas, tabla de señales) y `CONVENCIONES.md` si hace falta.

**Criterios de aceptación (checklist para LT):**
- [ ] El obstáculo estático mata al tocarlo y aparece "GOLPEADO — pulsá R para reiniciar"; R reinicia.
- [ ] Cambiar `size` en el inspector cambia forma visible y área letal (también en el editor).
- [ ] El obstáculo móvil va y viene con pausas; `speed`, `pause_at_ends` y `ease_at_ends` se ajustan desde el `.tres` sin tocar código.
- [ ] Dos instancias con distinto `start_delay` o `travel` se comportan de forma independiente.
- [ ] La trampa alterna segura/aviso/letal con los tiempos configurados; si está activa (o se activa) sobre el jugador, muere.
- [ ] Con la trampa inactiva o en aviso se puede atravesar sin morir.
- [ ] El tentáculo y la caída siguen matando (regresión).

**Commit:** `paso4: obstáculos estático, móvil y trampa intermitente`

> **Detenerse y esperar el "seguí" de LT.** Los ajustes de valores se anotan en `TUNING_LOG.md`.

---

## PASO 4b — Tanques de combustible

**Objetivo:** recogibles que recargan combustible, colocables como herramienta de diseño de niveles (por ejemplo en plataformas elevadas que solo se alcanzan saltando).

### 4b.1 Configuración: `scripts/pickups/fuel_tank_config.gd`

`class_name FuelTankConfig extends Resource`. Instancia por defecto en `resources/configs/fuel_tank_config.tres`. Crear la carpeta `scripts/pickups/` y `scenes/pickups/` (con `.gitkeep` si hace falta).

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Recarga | `fuel_amount` | 40 | u | Combustible que suma al recogerlo |
| Recarga | `only_if_not_full` | false | — | Si es true, no se recoge con el tanque del jugador lleno |
| Recarga | `respawn_time` | 0.0 | s | Tiempo hasta reaparecer (0 = un solo uso) |
| Visual | `bob_amplitude` | 3 | px | Vaivén vertical de la animación (0 = quieto) |
| Visual | `bob_frequency` | 1.0 | Hz | Velocidad del vaivén |

### 4b.2 Tanque: `scenes/pickups/FuelTank.tscn` + `scripts/pickups/fuel_tank.gd`

- `class_name FuelTank extends Area2D`, capa 6 (valor 32), máscara 2. Nodos: `Body` (`Polygon2D`, cian `#63D6C5` con un detalle blanco azulado `#C8E7EA`, unos 12×16 px) y `CollisionShape2D`.
- `@export var config: FuelTankConfig` (con el `.tres` asignado).
- Al entrar un `Player` vivo: si `only_if_not_full` y el combustible está lleno, ignorar; si no, `player.add_fuel(config.fuel_amount)`, emitir `collected(amount)`, ocultar y desactivar el tanque (`set_deferred`) y, si `respawn_time` > 0, reactivarlo tras ese tiempo.
- Animación de vaivén con seno (`bob_*`) en `_process`, solo visual.
- **Señal:** `collected(amount: float)`. **API pública:** `reset() -> void` (vuelve a estar disponible), `is_available() -> bool`.

### 4b.3 Sandbox

En `sandbox.tscn`, agregar 4 `FuelTank`: uno en la ruta habitual, uno sobre una plataforma alta que solo se alcance saltando (sin combustible), uno junto a un obstáculo o trampa, y uno colocado tal que se pueda ir "de tanque en tanque" con poco margen. Dejar el resto intacto.

### 4b.4 Documentación

- `docs/mecanicas/tanques.md` con la misma estructura que los demás documentos de mecánica, incluyendo una sección "Diseño de niveles": cómo influyen `fuel_amount`, la distancia entre tanques y la posición (el riesgo de la "espiral de muerte" sin combustible está en `ROADMAP.md`, sección 6).
- Actualizar `ARQUITECTURA.md`, `README.md` (carpetas nuevas) y `TUNING_LOG.md` solo si LT ajusta valores.

**Criterios de aceptación (checklist para LT):**
- [ ] Tocar un tanque suma `fuel_amount` (el overlay F3 lo refleja) y el tanque desaparece.
- [ ] Sin combustible, recoger un tanque devuelve el color normal y permite propulsar de nuevo.
- [ ] El tanque de la plataforma alta solo se alcanza saltando sin combustible.
- [ ] Con `only_if_not_full = true` no se recoge con el tanque lleno; con `respawn_time` > 0 reaparece.
- [ ] `fuel_amount`, `respawn_time` y `bob_*` se ajustan desde el `.tres` sin tocar código.
- [ ] R reinicia y los tanques vuelven a estar disponibles.

**Commit:** `paso4b: tanques de combustible`

> **Detenerse y esperar el "seguí" de LT.**

---

## Cierre

1. Actualizar `docs/ROADMAP.md`: marcar los pasos 4 y 4b como Hecho y anotar decisiones nuevas o ajustes de valores relevantes.
2. Revisar que `ARQUITECTURA.md` refleje el árbol de escenas y las señales finales.
3. `git stash pop` para devolver a LT sus valores de prueba (avisar si hay conflicto; no resolver descartando sus cambios).
4. **Confirmación antes de tocar GitHub.** Mostrarle a LT: el árbol de archivos nuevo o modificado, `git log --oneline` y `git diff --stat main`, y el contenido de los `.tres` nuevos. Esperar su confirmación explícita.
5. Con la confirmación: `git push -u origin feature/obstaculos-tanques` y `gh pr create --base main --title "Obstáculos y tanques (pasos 4 y 4b)"` con la descripción tomada de los commits. **No mergear** salvo pedido explícito de LT, avisando antes a su socio por los `.tscn`.

## Resultado esperado

- Rama `feature/obstaculos-tanques` publicada y PR abierto, con tres commits (`paso0`, `paso4`, `paso4b`).
- Un sandbox jugable con obstáculos estáticos, móviles y trampas intermitentes que matan, y tanques que recargan combustible; sin combustible se puede saltar a un tanque elevado.
- Toda la sensación ajustable desde `.tres` (`moving_obstacle_config`, `pulse_trap_config`, `fuel_tank_config`, además de los tres existentes).
- `docs/` con un documento por mecánica nueva (`obstaculos.md`, `tanques.md`), `ARQUITECTURA.md` al día y el roadmap con los pasos 4 y 4b en Hecho, listo para el brief 03 (puerta y game manager, pasos 5 y 6).
