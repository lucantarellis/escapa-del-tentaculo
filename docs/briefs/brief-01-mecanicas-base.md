# Brief 01 — Mecánicas base (pasos 0 a 3) — "Escapa del Tentáculo"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork), junto con `ROADMAP.md` y `BRIEF_TEMPLATE.md` adjuntos. Da todo el contexto necesario sin depender de conversaciones previas.

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior y el jugador usa un jetpack con combustible limitado para esquivar obstáculos y llegar a una puerta antes de que lo atrapen.
- **Stack:** Godot **4.7.2 stable**, GDScript **con tipado estático**, 2D.
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado, rama `main`). El socio de LT ya es colaborador.
- **Estado del repo:** v0 publicada. Contiene la estructura de carpetas, `project.godot` con `run/main_scene="res://scenes/main/Main.tscn"` (escena vacía), `README.md`, `.gitignore`, `assets/palette.md`, los sprite sheets del astronauta y del tileset, y `scenes/levels/lvl1.tscn` (nivel preexistente).
- **Alcance de este brief:** pasos 0 a 3 del `ROADMAP.md`: preparación, jugador con jetpack, scroll/cámara y tentáculo. **Fuera de alcance:** obstáculos, tanques, puerta, game manager, UI, sprites finales. Todo lo visual es `Polygon2D` placeholder con colores de `assets/palette.md`.

## Qué necesita aportar LT

1. Adjuntos: `ROADMAP.md`, `BRIEF_TEMPLATE.md` y este brief.
2. Ruta local del repo clonado. `gh` autenticado (`gh auth status`).
3. Opcional: ruta del ejecutable de Godot 4.7.2, para validar por línea de comandos.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- Control: mantener apretada una dirección propulsa en esa dirección (4 direcciones, combinables).
- Gravedad casi nula (pero no cero) con combustible. Inercia con deriva suave.
- Combustible limitado, se recarga solo con tanques (paso 4b, fuera de alcance; solo dejar la API `add_fuel`).
- Sin combustible: la gravedad sube y el jugador puede saltar desde una superficie.
- Prototipo en PC con teclado; versión final en móvil. Por eso el input va siempre por acciones.
- **Todo valor de gameplay es variable exportada** en un `Resource` de configuración, para poder iterar y descubrir qué es divertido.
- **Documentación obligatoria**: cualquier persona debe entender el código leyendo `docs/` y los comentarios.

## Reglas de trabajo

1. **Gates:** al terminar cada paso, detenerse, entregar la checklist de prueba y esperar el "seguí" de LT. Cowork no puede jugar el juego; el juicio de "se siente bien" es de LT.
2. **Git:** crear la rama `feature/mecanicas-base` desde `main`. Un commit por paso. **No hacer `git push` ni tocar GitHub sin confirmación explícita**, mostrando antes el árbol de archivos y un resumen de cambios (ver Cierre).
3. **No modificar:** `Main.tscn`, `lvl1.tscn`, ni los sprite sheets. No agregar assets.
4. **GDScript tipado** en todo (variables, parámetros, retornos). Comentarios de documentación con `##` en cada clase, variable exportada, señal y función pública.
5. **Variables exportadas agrupadas** con `@export_group`. Unidades en el comentario (px, px/s, px/s², s).
6. **Sin valores hardcodeados**: si un número afecta el gameplay, va en un `Resource` de configuración.
7. **Renderer:** no cambiar el renderer ni el driver gráfico del proyecto; solo reportar cuál está en uso.
8. **Validación:** si hay Godot disponible por CLI, correr `godot --headless --path . --quit` tras cada paso y reportar errores. Si no, indicar a LT abrir el editor y revisar el panel de salida.
9. **Sin shell:** si Cowork no tiene acceso a terminal (como en la v0), escribe los archivos y le da a LT los comandos `git`/`gh` para correr él mismo.
10. **Discrepancias:** si el estado real del repo no coincide con este brief, avisar antes de continuar.

## Tabla de referencia

### Capas de colisión 2D

| Capa | Nombre | Uso |
|---|---|---|
| 1 | `world` | Suelo, paredes, plataformas, límites de pantalla (StaticBody2D) |
| 2 | `player` | Jugador |
| 3 | `obstacles` | Obstáculos y trampas |
| 4 | `tentacle` | Zona letal del tentáculo |
| 5 | `goal` | Puerta |
| 6 | `pickups` | Tanques de combustible y otros recogibles |

El jugador: layer 2, mask 1. Las `Area2D` de peligro o recogible detectan con mask 2.

### Acciones del Input Map

| Acción | Teclas | Uso |
|---|---|---|
| `move_left` | A, ← | Propulsar a la izquierda |
| `move_right` | D, → | Propulsar a la derecha |
| `move_up` | W, ↑ | Propulsar hacia arriba |
| `move_down` | S, ↓ | Propulsar hacia abajo |
| `jump` | Espacio | Saltar (sin combustible) |
| `restart` | R | Reiniciar (temporal) |
| `debug_toggle` | F3 | Mostrar u ocultar el overlay de debug |

Usar `physical_keycode`. Códigos: A=65, D=68, S=83, W=87, R=82, Espacio=32, ←=4194319, ↑=4194320, →=4194321, ↓=4194322, F3=4194334. Si se edita `project.godot` a mano, verificar abriendo el proyecto: el editor lo regenera.

### Nombres y estilo

- Archivos `.gd`: `snake_case`. Escenas `.tscn` y `class_name`: `PascalCase`. Variables y funciones: `snake_case`. Constantes: `UPPER_SNAKE`.
- Identificadores en inglés. Comentarios y documentos en español.
- Señales hacia arriba, llamadas hacia abajo.

---

## PASO 0 — Preparación

**Objetivo:** dejar el proyecto configurado y documentado para que los pasos 1 a 3 no tengan que decidir infraestructura.

### 0.1 Configuración de proyecto

- **Viewport:** 360×640 (vertical). `display/window/size/viewport_width=360`, `viewport_height=640`.
- **Ventana en PC:** override 540×960 (`window_width_override`, `window_height_override`) para que entre en pantallas de 1080p.
- **Stretch:** `mode="canvas_items"`, `aspect="keep"`, escalado fraccional durante el prototipo. El escalado entero (pixel-perfect) se decide con el arte final.
- **Orientación** (para el móvil final): `display/window/handheld/orientation` en vertical.
- **Pixel art:** filtro de textura por defecto en `Nearest` y snap de transformaciones 2D a píxel.
- **Física:** 60 ticks por segundo. Nombrar las capas 2D de la tabla de arriba (`layer_names/2d_physics/layer_N`).
- **Input Map:** crear las acciones de la tabla de arriba.

### 0.2 Carpetas nuevas (con `.gitkeep` si quedan vacías)

```
resources/configs/
scenes/camera/
scripts/camera/
docs/mecanicas/
docs/briefs/
```

### 0.3 Documentación base

Crear en `docs/`:

- `ROADMAP.md` (el adjunto, tal cual).
- `briefs/BRIEF_TEMPLATE.md` (el adjunto) y `briefs/brief-01-mecanicas-base.md` (este brief).
- `CONVENCIONES.md`: nombres y estilo, política de tipado y comentarios `##`, tabla de capas, tabla de acciones, patrón de configuración con `Resource` (cómo agregar un parámetro nuevo), convención de commits (`pasoN: descripción`) y flujo de ramas.
- `ARQUITECTURA.md`: esqueleto con secciones "Árbol de escenas", "Señales" (tabla emisor, señal, receptor), "Autoloads" (ninguno por ahora) y "Flujo de una partida". Se completa en cada paso.
- `TUNING_LOG.md`: tabla vacía con columnas fecha, parámetro, valor anterior, valor nuevo, cómo se sintió.
- `mecanicas/.gitkeep`.

Actualizar `README.md`: sección de controles, enlace a `docs/`, y las carpetas nuevas.

**Criterios de aceptación:**
- [ ] El proyecto abre en Godot 4.7.2 sin errores ni advertencias nuevas.
- [ ] Input Map y nombres de capas visibles en Project Settings.
- [ ] Viewport 360×640 al ejecutar.
- [ ] `docs/` completo como arriba.

**Commit:** `paso0: configuración de proyecto, convenciones y documentación base`

> **Detenerse aquí y esperar el "seguí" de LT.**

---

## PASO 1 — Jugador con jetpack

**Objetivo:** un personaje controlable con propulsión en 4 direcciones, inercia, combustible, gravedad dependiente del combustible y salto, con todo parametrizado y una escena de prueba.

### 1.1 Configuración: `scripts/player/player_config.gd`

`class_name PlayerConfig extends Resource`. Instancia por defecto en `resources/configs/player_config.tres`. Los valores son un **punto de partida**, no una decisión: LT los ajusta jugando.

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Propulsión | `thrust_acceleration` | 700 | px/s² | Aceleración al mantener una dirección |
| Propulsión | `max_speed` | 180 | px/s | Tope de velocidad |
| Propulsión | `counter_thrust_multiplier` | 1.5 | × | Multiplica la aceleración cuando la entrada se opone a la velocidad actual (facilita frenar) |
| Propulsión | `coasting_drag` | 90 | px/s² | Frenado cuando no hay entrada. Define la "deriva suave" |
| Gravedad | `gravity_with_fuel` | 30 | px/s² | Gravedad casi nula mientras hay combustible |
| Gravedad | `gravity_without_fuel` | 500 | px/s² | Gravedad cuando el combustible está vacío |
| Gravedad | `gravity_transition_time` | 0.5 | s | Tiempo de interpolación entre ambos valores |
| Gravedad | `max_fall_speed` | 400 | px/s | Velocidad máxima de caída |
| Combustible | `max_fuel` | 100 | u | Capacidad |
| Combustible | `starting_fuel` | 100 | u | Combustible inicial |
| Combustible | `fuel_consumption_per_second` | 15 | u/s | Consumo mientras se propulsa |
| Combustible | `min_fuel_to_thrust` | 0.0 | u | Por debajo de este valor no se puede propulsar |
| Combustible | `fuel_regen_per_second` | 0.0 | u/s | Regeneración pasiva (0 = solo tanques) |
| Salto | `jump_velocity` | 260 | px/s | Velocidad vertical hacia arriba del salto |
| Salto | `jump_requires_empty_fuel` | true | — | Si es true, solo se salta sin combustible |
| Salto | `jump_empty_threshold` | 0.0 | u | Combustible ≤ este valor cuenta como vacío |
| Salto | `jump_requires_floor` | true | — | Si es true, solo se salta apoyado en una superficie |
| Colisión | `wall_bounce` | 0.25 | 0 a 1 | 0 = se detiene o desliza, 1 = rebote elástico |

### 1.2 Jugador: `scenes/player/Player.tscn` + `scripts/player/player.gd`

- `class_name Player extends CharacterBody2D`, capa 2, máscara 1, en el grupo `player`.
- Nodos: `Polygon2D` de cuerpo (rectángulo 16×24, color naranja de la paleta), `CollisionShape2D` acorde, y un `Polygon2D` pequeño `ThrustIndicator` (color blanco azulado) que aparece en la dirección de propulsión.
- Feedback placeholder: el cuerpo cambia a rojo de la paleta cuando no hay combustible.
- `@export var config: PlayerConfig` (con el `.tres` por defecto asignado).
- Toda la lógica de movimiento en `_physics_process`, usando `Input.get_vector("move_left", "move_right", "move_up", "move_down")`.
- Comportamiento:
  - Con entrada y combustible sobre `min_fuel_to_thrust`: acelerar en esa dirección (con `counter_thrust_multiplier` si se opone a la velocidad), consumir combustible, limitar a `max_speed`.
  - Sin entrada (o sin combustible): frenar con `coasting_drag`.
  - Gravedad: interpolar entre `gravity_with_fuel` y `gravity_without_fuel` según haya combustible, en `gravity_transition_time`. Limitar la caída a `max_fall_speed`.
  - Salto: si se pulsa `jump` y se cumplen las condiciones de `jump_*`, aplicar `jump_velocity` hacia arriba.
  - Colisiones: usar `wall_bounce` para reflejar la velocidad al chocar.
- **Señales:** `fuel_changed(current: float, maximum: float)`, `fuel_depleted()`, `fuel_refilled()`, `thrust_started()`, `thrust_stopped()`, `jumped()`, `died(cause: StringName)`.
- **API pública:** `add_fuel(amount: float) -> void`, `get_fuel_ratio() -> float`, `is_fuel_empty() -> bool`, `die(cause: StringName) -> void` (desactiva el control y emite `died`), `reset(spawn_position: Vector2) -> void`.

### 1.3 Overlay de debug: `scenes/ui/DebugOverlay.tscn` + `scripts/ui/debug_overlay.gd`

`CanvasLayer` con `Label`, alternado con `debug_toggle`. Muestra: velocidad (vector y módulo), combustible actual/máximo, gravedad actual, `on_floor`, si está propulsando, si puede saltar, FPS. Recibe una referencia al `Player` por `@export`.

### 1.4 Escena de prueba: `scenes/levels/sandbox.tscn`

`Node2D` con: `Player`, `DebugOverlay`, un recinto cerrado de 360×640 (suelo, techo y dos paredes) y 3 plataformas intermedias. Todo `StaticBody2D` en capa 1 con `Polygon2D` azul frío + `CollisionPolygon2D`. Dejar `sandbox.tscn` como escena de ejecución para pruebas (F6 en el editor); **no** cambiar `run/main_scene`.

### 1.5 Documentación

- `docs/mecanicas/jugador.md`: propósito, modelo físico en palabras simples (por qué la gravedad depende del combustible), tabla completa de parámetros (nombre, tipo, valor inicial, unidad, efecto, consejo de tuning), señales, API pública, estructura de nodos, cómo probarlo.
- Actualizar `ARQUITECTURA.md` (árbol de escenas y señales).

**Criterios de aceptación (checklist para LT):**
- [ ] Al mantener una dirección, el personaje acelera hacia allí y alcanza un tope.
- [ ] Al soltar, deriva y frena de a poco.
- [ ] Propulsar en sentido opuesto al movimiento frena más rápido.
- [ ] El combustible baja mientras se propulsa y el overlay lo refleja.
- [ ] Al llegar a 0, el personaje cambia a rojo, cae con gravedad normal y no puede propulsar.
- [ ] Sin combustible y apoyado en una superficie, Espacio salta. Con combustible, no.
- [ ] Cambiar valores en `player_config.tres` cambia el comportamiento sin tocar código.
- [ ] Al chocar con una pared, rebota según `wall_bounce`.

**Commit:** `paso1: jugador con jetpack, combustible y sandbox`

> **Detenerse y esperar el "seguí" de LT.** LT juega y decide si el movimiento se siente bien antes de continuar. Los ajustes de valores se anotan en `TUNING_LOG.md`.

---

## PASO 2 — Scroll y cámara

**Objetivo:** una cámara que sube a velocidad configurable y mantiene al jugador dentro de la pantalla.

### 2.1 Configuración: `scripts/camera/scroll_config.gd`

`class_name ScrollConfig extends Resource`. Instancia en `resources/configs/scroll_config.tres`.

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Scroll | `scroll_speed` | 40 | px/s | Velocidad de ascenso |
| Scroll | `scroll_acceleration` | 0.0 | px/s² | Aumento progresivo de la velocidad (0 = constante) |
| Scroll | `max_scroll_speed` | 120 | px/s | Tope cuando hay aceleración |
| Scroll | `start_delay` | 2.0 | s | Espera antes de empezar a subir |
| Fin | `stop_at_enabled` | false | — | Si es true, la cámara se detiene en `stop_at_y` |
| Fin | `stop_at_y` | -2400 | px | Coordenada Y donde se detiene |
| Límites | `side_walls_enabled` | true | — | Paredes invisibles laterales |
| Límites | `top_wall_enabled` | true | — | Pared invisible superior |
| Límites | `top_wall_margin` | 0 | px | Separación de la pared superior respecto del borde |

### 2.2 Cámara: `scenes/camera/ScrollCamera.tscn` + `scripts/camera/scroll_camera.gd`

- `class_name ScrollCamera extends Camera2D`. Sube en `_physics_process` (`process_callback` en física, sin suavizado de posición) para quedar sincronizada con el jugador.
- Hijo `ScreenBounds` (`StaticBody2D`, capa 1) con formas de colisión izquierda, derecha y superior dimensionadas desde el tamaño del viewport en `_ready`. Se mueven con la cámara.
- **Señales:** `scroll_started()`, `scroll_stopped()`.
- **API pública:** `set_scrolling(enabled: bool) -> void`, `get_bottom_y() -> float`, `get_visible_rect() -> Rect2`, `reset() -> void`.

### 2.3 Cambios en `sandbox.tscn`

Convertir el recinto en una columna alta (360 px de ancho, unos 2400 px de alto) con plataformas repartidas a distintas alturas. Quitar las paredes laterales estáticas (las reemplazan los límites de cámara) y mantener el suelo. Agregar `ScrollCamera` y ubicar al jugador cerca del borde inferior de la vista inicial.

### 2.4 Documentación

- `docs/mecanicas/scroll-camara.md` con la misma estructura que `jugador.md`.
- Actualizar `ARQUITECTURA.md`.

**Criterios de aceptación:**
- [ ] Tras `start_delay`, la cámara sube a `scroll_speed` de forma constante.
- [ ] El jugador no puede salir por los costados ni por arriba.
- [ ] Cambiar `scroll_speed` en el `.tres` cambia la velocidad sin tocar código.
- [ ] Con `scroll_acceleration` > 0 la velocidad crece hasta `max_scroll_speed`.
- [ ] Con `stop_at_enabled`, la cámara se detiene en `stop_at_y` y emite `scroll_stopped`.
- [ ] Mientras la cámara sube, el jugador y los polígonos no tiemblan ni se desfasan visualmente.

**Commit:** `paso2: cámara con scroll y límites de pantalla`

> **Detenerse y esperar el "seguí" de LT.**

---

## PASO 3 — Tentáculo y condición de derrota

**Objetivo:** una amenaza anclada al borde inferior de la cámara, con derrota por contacto o por caída fuera de pantalla.

### 3.1 Configuración: `scripts/tentacle/tentacle_config.gd`

`class_name TentacleConfig extends Resource`. Instancia en `resources/configs/tentacle_config.tres`.

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Posición | `visible_height` | 70 | px | Cuánto del tentáculo se ve sobre el borde inferior |
| Posición | `extra_rise_speed` | 0.0 | px/s | Velocidad adicional respecto de la cámara (0 = pegado al borde) |
| Letalidad | `kill_zone_inset` | 10 | px | Margen de gracia: la zona letal es más baja que el polígono visible |
| Letalidad | `kill_on_leaving_screen_bottom` | true | — | Caer bajo el borde inferior también mata |
| Letalidad | `screen_bottom_margin` | 24 | px | Cuánto por debajo del borde cuenta como caída |
| Animación | `wobble_amplitude` | 6 | px | Ondulación del borde superior (0 = sin ondulación) |
| Animación | `wobble_frequency` | 2.0 | Hz | Velocidad de la ondulación |
| Animación | `wobble_segments` | 12 | — | Cantidad de puntos del borde superior |

### 3.2 Tentáculo: `scenes/tentacle/Tentacle.tscn` + `scripts/tentacle/tentacle.gd`

- `class_name Tentacle extends Node2D`. Nodos: `BodyPolygon` (`Polygon2D`, rojo de la paleta, borde superior ondulado con seno según `wobble_*`), `KillZone` (`Area2D`, capa 4, máscara 2) con su `CollisionShape2D`.
- `@export var config: TentacleConfig` y `@export var camera: ScrollCamera`.
- Sigue a la cámara en `_physics_process`: posición vertical = `camera.get_bottom_y() - visible_height` más el acumulado de `extra_rise_speed`.
- **Señal:** `player_caught(cause: StringName)`, con causa `&"tentacle"` o `&"fell"`.
- Al detectar al jugador en la zona (o caído bajo el borde), emite la señal y llama a `Player.die(cause)`.

### 3.3 Manejo temporal de derrota

En un script `scripts/levels/sandbox_controller.gd` en la raíz de `sandbox.tscn`: al recibir `player_caught`, mostrar un `Label` "CAPTURADO — pulsá R para reiniciar" y detener el scroll; con `restart`, recargar la escena. **Marcar el script como TEMPORAL** en un comentario: lo reemplaza el game manager (paso 6).

### 3.4 Documentación

- `docs/mecanicas/tentaculo.md` con la misma estructura.
- Actualizar `ARQUITECTURA.md` (tabla de señales: `player_caught` y `died`).

**Criterios de aceptación:**
- [ ] El tentáculo se ve pegado al borde inferior y sube con la cámara.
- [ ] Tocarlo mata al jugador y aparece el mensaje.
- [ ] Caer por debajo del borde inferior también mata.
- [ ] R reinicia la partida con el combustible y la cámara en su estado inicial.
- [ ] `visible_height`, `extra_rise_speed` y `wobble_*` se ajustan desde el `.tres`.
- [ ] Con `extra_rise_speed` > 0, el tentáculo gana terreno sobre la cámara.

**Commit:** `paso3: tentáculo, derrota por contacto y por caída`

> **Detenerse y esperar el "seguí" de LT.**

---

## Cierre

1. Actualizar `docs/ROADMAP.md`: marcar los pasos 0 a 3 como Hecho y anotar decisiones nuevas o ajustes de valores relevantes.
2. Revisar que `ARQUITECTURA.md` refleje el árbol de escenas y las señales finales.
3. **Confirmación antes de tocar GitHub.** Mostrarle a LT:
   - El árbol de archivos nuevo o modificado.
   - Un resumen de cambios por commit (`git log --oneline` y `git diff --stat main`).
   - El contenido de `CONVENCIONES.md` y de los `.tres` de configuración.
   Esperar su confirmación explícita.
4. Con la confirmación: `git push -u origin feature/mecanicas-base` y `gh pr create --base main --title "Mecánicas base (pasos 0 a 3)"` con la descripción tomada de los commits. **No mergear:** el merge lo hace LT, avisando antes a su socio para evitar conflictos en los `.tscn`.

## Resultado esperado

- Rama `feature/mecanicas-base` publicada y PR abierto, con cuatro commits (uno por paso).
- Un prototipo jugable en `scenes/levels/sandbox.tscn`: astronauta con jetpack y combustible, cámara que sube, tentáculo que mata, reinicio con R.
- Toda la sensación de juego ajustable desde tres `.tres` (`player_config`, `scroll_config`, `tentacle_config`).
- `docs/` con roadmap, convenciones, arquitectura, un documento por mecánica y el registro de tuning, de modo que cualquier persona pueda entender el código y crear el siguiente brief desde la plantilla.
