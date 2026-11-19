# Brief 07 — Arte nuevo de la nave en Godot: astronauta, tentáculo, paredes, plataformas, fondo, recogibles, piso, escotilla, ventanal e iluminación — "Rise or Die"

Brief autocontenido para pegar en una conversación nueva de Claude (Cowork). Todo el contexto está acá y en `docs/` del repo, que Claude puede leer en la carpeta conectada.

## Contexto

- **Juego:** un astronauta escapa de un tentáculo alienígena subiendo con un jetpack dentro de una nave que se está destruyendo; la pantalla sube y el tentáculo lo persigue desde abajo. Título actual: "Rise or Die".
- **Stack:** Godot **4.7.2 stable**, GDScript **tipado**, 2D. Viewport **360×640**. Pixel art a 1×.
- **Repo:** https://github.com/lucantarellis/escapa-del-tentaculo (privado). Carpeta local conectada: `C:\Users\lucan\Desktop\Gamedev\escapa-del-tentaculo` (`$HOME/mnt/escapa-del-tentaculo` en el shell). Rama actual de LT: `main-l`; confirmar con LT la rama base antes de crear la del brief.
- **Leer antes de trabajar:** `docs/CONVENCIONES.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md`, `docs/arte/SPRITES.md`, `docs/arte/lista-assets.md`, **`docs/arte/paredes-nave.md`**, **`docs/arte/plataformas-nave.md`**, **`docs/arte/fondo-nave.md`**, **`docs/arte/recogibles.md`**, **`docs/arte/piso-y-escotilla.md`**, **`docs/arte/ventanal.md`**, `docs/mecanicas/jugador.md`, `docs/mecanicas/tentaculo.md`, `docs/mecanicas/plataformas.md`, `docs/mecanicas/paredes.md`, `docs/mecanicas/intro-escotilla.md`, `docs/mecanicas/tier-espacio.md`, y los scripts `scripts/player/player.gd`, `scripts/tentacle/tentacle.gd`, `scripts/tentacle/tentacle_front.gd`, `scripts/platforms/platform.gd`, `scripts/platforms/platform_config.gd`, `scripts/levels/level_controller.gd`, `scripts/levels/level_builder.gd`, `scripts/levels/level_background.gd`, `scripts/levels/window_breach.gd`, `scripts/intro/hatch.gd`, `scripts/intro/intro_config.gd`, los scripts de `scripts/pickups/` y las escenas de `scenes/pickups/`, `scenes/intro/Hatch.tscn`, `scenes/levels/segments/start/` y `scenes/levels/segments/ship/SegmentShipExit*`.
- **Alcance:** conectar el arte nuevo de la fase de la nave: astronauta (con daño y llama), mar de tentáculos, paredes (tilesets con daño y detalle), plataformas (estática, un sentido, rompible, temporizada, pulso y propulsores de las móviles), fondo en parallax, recogibles (tanque, moneda, impulso y los tres reparadores), piso de los segmentos de inicio, escotilla de la intro, ventanal de salida e iluminación dinámica (oscuridad general, relieve y capas emisivas).
- **Fuera de alcance:** dibujar o editar arte; tuning de gameplay; otros tiers (espacio, alien); letales sin fuego y plataforma proyectil (se redefinen con los segmentos nuevos); puerta de salida (en pausa); partículas de gas (se dejan preparadas); audio.

## Qué necesita aportar LT

1. Pegar este brief. Carpeta del repo conectada.
2. Aseprite instalado en su PC (y en la de Guido) y la ruta del ejecutable para configurar el addon.
3. Abrir el proyecto en el editor cuando se le pida (importaciones) y probar cada paso con el checklist.
4. Lo que el **Paso 0** detecte como pendiente de su lado (ver ahí).

## Arte disponible (no modificar)

Todos los editables finales están en `assets/aseprite/` y se versionan (`.gitignore` tiene `!assets/aseprite/**/*.aseprite`). `art_src/` es de borradores locales: no se toca ni se referencia. Ningún color fuera de `assets/palette.hex`.

### Astronauta — `assets/aseprite/player/astronaut/astronaut.aseprite`
- Lienzo 32×40; figura 23×32. **La colisión sigue en 16×24** (no cambiarla). Mira a la derecha; se espeja con `flip_h`.
- Capas: `cuerpo` y `visor_reflejo` (brillo del visor, aparte para teñirlo por tier con `modulate` o un shader más adelante).
- 63 frames. Tags:

| Tag | Frames | Duración |
|---|---|---|
| `idle` | 1–4 | 300, 220, 220, 160 ms |
| `walk` (trote) | 5–10 | 100 ms |
| `jump` | 11–13 | 80, 120, 120 ms (no loop: queda en el último) |
| `thrust` | 14–17 | 110 ms |
| `thrust_side` | 18–21 | 110 ms |
| `*_dano_1` | 22–42 | igual que los anteriores |
| `*_dano_2` | 43–63 | igual que los anteriores |

- Elección: estado base según el movimiento (`thrust_side` si hay entrada o velocidad horizontal durante la propulsión, si no `thrust`; en suelo `walk`/`idle`; en el aire sin propulsar `jump`). Sufijo por golpes recibidos: 0 → sin sufijo, 1 → `_dano_1`, 2 o más → `_dano_2` (hoy `player.gd` usa `hits_taken = _max_hp - _hp` con `hit_sprites`; reemplazarlo por este esquema).
- Al cambiar de sufijo, conservar el frame relativo de la animación para que no salte.
- Punto de fuga de gas para partículas futuras en daño 2: (−2, +9) desde el centro del sprite; espejar X con el sprite. Dejarlo como `Marker2D` o constante, sin partículas.

### Llama — `assets/aseprite/player/astronaut/astronaut_flame.aseprite`
- Tira de 3 frames de 8×14, 70 ms, loop (también exportada a `assets/sprites/player/astronaut/astronaut_flame.png`).
- Centro en (−8, +20) desde el centro del astronauta; con el sprite espejado, X → +8. Se dibuja **detrás** del cuerpo. Visible solo mientras propulsa.

### Tentáculo de la nave (perseguidor de la fase 1)
Una sola amenaza con **una sola colisión** (la `KillZone` rectangular actual no cambia). Los sprites lo representan como un mar de tentáculos de altura pareja que sale de una masa de tentáculos grandes tumbados.

| Archivo | Tamaño | Tags | Notas |
|---|---|---|---|
| `tentacle/front/tentacle_front_01..04` | 300×384, base abajo al centro | `idle_a` 1–12 (100 ms), `idle_b` 13–24 (110), `reach` 25–30 (90), `grab` 31–38 (80), `retract` 39–44 (100) | Dirección natural: 01 y 03 a la derecha, 02 y 04 a la izquierda |
| `tentacle/fill/tentacle_fill_01..05` | 300×360 | `idle` 12 frames | Fila de atrás, `modulate` ~0,6 |
| `tentacle/flesh/tentacle_flesh` | 360×400 (ancho de pantalla; no se repite en X) | `idle` 12 frames, 100 ms | Respira sutil; tapa las bases |
| `tentacle/flesh/tentacle_flesh_deep` | 360×120 | sin animación | Se repite hacia abajo si la masa supera 400 px |

- Orden de dibujo (atrás → adelante): relleno → tentáculos de adelante → `tentacle_flesh` → `tentacle_flesh_deep`.
- Ubicación (maqueta aprobada): borde superior de `tentacle_flesh` sobre la línea de base; bases de adelante ~85 px por debajo de esa línea y las de relleno ~60 px.
- Densidad: ~12 de relleno cada ~34 px y ~8 de adelante cada ~52 px en 360 de ancho, misma línea de base (±6 px).
- **Alternar** izquierda/derecha al ubicar los de adelante (espejar con `flip_h` según su dirección natural).
- Variedad: frame inicial al azar, `speed_scale` 0,85–1,15, y al terminar cada ciclo elegir `idle_a`/`idle_b` al azar.
- `retract` termina en la pose del frame 1 de `idle_a` y `reach` arranca de esa pose: disparar `reach` al terminar un ciclo de `idle_a`. Secuencia `reach` → `grab` → `retract` → idle.
- El shader `tentacle_bend` **no** se aplica a estos sprites.
- Los mismos `SpriteFrames` se reutilizan dados vuelta (`flip_v`) para el tentáculo que rompe el ventanal (ver "Ventanal").

### Paredes de la nave — detalle completo en `docs/arte/paredes-nave.md`
- Editables `assets/aseprite/environment/ship_walls/`; PNG (color, `_normal`, `_emissive`) y `ship_walls_layout.json` en `assets/sprites/environment/ship_walls/`.
- **TileSets ya generados y probados:** `resources/tilesets/walls_tileset_ship.tres` (pared con colisión, terreno `pared_nave`, tiles animados) y `ship_walls_overlay.tres` (terrenos `rotura`, `grieta`, `bilis`, `parche`, `caneria`, sin colisión), más sus `*_emissive.tres` (mismos ids y coordenadas, solo píxeles que emiten). Texturas `CanvasTexture` con relieve.
- LT pasa los segmentos de la nave al terreno nuevo y pinta los daños **a mano** (guía en el doc). Capas por segmento: pared (`walls_tileset_ship.tres`), `Detalle` y `Dano` (`ship_walls_overlay.tres`). El techo de los segmentos de salida también es pared y se migra igual.

### Plataformas de la nave — detalle completo en `docs/arte/plataformas-nave.md`
- Editables `assets/aseprite/environment/platforms/`; hojas (color, `_normal`, `_emissive`) + JSON de Aseprite (tags y duraciones) en `assets/sprites/environment/platforms/`; resumen en `platforms_layout.json`.
- Módulos de **10 px**: tapa `L`, centros `C0…`, tapa `R`; columna = módulo, fila = cuadro. Alto 12 px = colisión (la rompible usa cuadros de 30 px con la viga en y = 2–13).
- Tags: rompible `idle`, `shake`, `break_fall`, `break_hit`, `respawn`; temporizada `on`, `warning`, `turn_off`, `off`, `turn_on`; pulso `off`, `warn`, `on`; propulsor `idle`.

### Fondo de la nave — detalle completo en `docs/arte/fondo-nave.md`
- Editables `assets/aseprite/environment/background_ship/` (9 archivos: 3 capas × 3 tramos, capas `color` y `emissive`, 8 cuadros de 120 ms). Hojas + JSON en `assets/sprites/environment/background_ship/`; puntos de luz por tramo en `bg_ship_lights.json`.
- Capas: lejana (`far`, eje del reactor), media (`mid`, paredes con máquinas, cables, balizas e incendios) y cercana (`near`, caños y cables en los bordes). Tramos de 360×320 que encajan en cualquier orden.
- Assets nítidos: el desenfoque por capa y la niebla los pone Godot. No hay luz general: solo balizas rojas, fuegos, chispas y pantallas.

### Recogibles — detalle completo en `docs/arte/recogibles.md`
- Editables `assets/aseprite/pickups/pickup_{tank,coin,boost,wrench,tape,toolbox}.aseprite`; hojas verticales + JSON en `assets/sprites/pickups/`: `pickup_<n>.png` (color), `pickup_<n>_aura.png` (aura cian, detrás, sin sombreado), `pickup_<n>_emissive.png` (partes cian, encima, sin sombreado).
- Cuadros de 38 (tanque, moneda), 42 (impulso) y 44 px (reparadores), con el ítem centrado: el pivote es el centro de la colisión actual, que no cambia.
- Tags: `idle` 1–8 (120 ms, loop) y `collect` 9–16 (50 ms, sin loop).
- Reparadores: llave → `pickup_wrench` (+1), cinta → `pickup_tape` (+2), caja → `pickup_toolbox` (todo + escudo). Reemplazan los polígonos de `repairer.gd`.

### Piso de los segmentos de inicio — detalle completo en `docs/arte/piso-y-escotilla.md`
- Editable `assets/aseprite/environment/floor_ship/floor_ship.aseprite`; hojas (color, `_normal`, `_emissive`) + `floor_ship_layout.json` en `assets/sprites/environment/floor_ship/`.
- **Vista 3/4** (cara superior de chapa + frente de viga). 11 módulos de **20×27 px** en una fila: rellenos, junta, remaches, rejilla, abolladura, peligro, caño y tres piezas 2D (`wall2d`, `end_l`, `end_r`) para cuando haya paredes a los costados (hoy no se usan).
- La colisión del piso no cambia: el sprite empieza **7 px por encima** de la línea de colisión.

### Escotilla de la intro — detalle completo en `docs/arte/piso-y-escotilla.md`
- Editable `assets/aseprite/intro/hatch.aseprite`; hojas verticales de 144×96 en `assets/sprites/intro/`: `hatch.png` (+ `hatch.json`), `hatch_normal.png`, `hatch_emissive.png` y `hatch_glow.png` (luz que se escapa, aditiva). Origen (centro del borde superior del piso) en (72, 64) del cuadro.
- Tags: `closed`, `hit_1`/`idle_1`, `hit_2`/`idle_2`, `hit_3`/`idle_3`, `break`, `broken`.
- Fragmentos: `assets/aseprite/intro/hatch_debris.aseprite` → `assets/sprites/intro/hatch_debris.png` (+ `_normal`), 6 cuadros de 12×12.

### Ventanal de salida — detalle completo en `docs/arte/ventanal.md`
- **2D.** Editables en `assets/aseprite/environment/window/`; hojas en `assets/sprites/environment/window/`:
  - `window_breach.png` (+ JSON y `_normal`): cuadros de 96×112, origen (centro del vidrio = posición de `WindowBreach`) en (48, 34). Vidrio de 72×36 con marco solo a los costados. Tags `intact` (loop), `crack`, `shatter`, `broken`.
  - `window_wind.png` (+ JSON): succión, 4 cuadros en loop, mismo origen.
  - `window_shards.png`: 6 cuadros de 6×6 para las partículas de vidrio.
- El techo es pared normal (tileset de la nave). El tentáculo es `tentacle_front` dado vuelta: no hay arte nuevo.

## Decisiones ya tomadas (no reabrir; si hay un problema, avisar antes)

- Herramienta de importación de personajes: **Aseprite Wizard** (addon MIT de viniciusgerevini, rama `godot_4`). Paredes, plataformas, fondo, recogibles, piso, escotilla y ventanal usan las hojas PNG + JSON exportadas (no necesitan el addon).
- No se modifica el arte ni los `.aseprite`. Si algo no encaja (tamaño, tag, pivote), avisar a LT: se corrige en el chat de arte.
- Colisiones del jugador, del tentáculo, de las paredes, de las plataformas, de los recogibles, del piso y del vidrio sin cambios (salvo el redondeo de ancho de plataformas a múltiplos de 10 px).
- Las paredes no hacen daño: no llevan fuego. El fuego queda en las plataformas letales (`fire_skin`) y en el fondo.
- Rompible: **pisada** → `shake` y después `break_fall`; **dash** (`break_now()`, cualquier dirección) → directo `break_hit`, sin aviso ni empuje.
- Temporizada: el aviso respira (`warning`) y se apaga con la misma transición con que aparece; al apagarse **las tapas quedan visibles** (`off`).
- Fondo: infinito e independiente de la cantidad de segmentos (tramos que se reciclan al azar); nunca compite con paredes y plataformas; desenfoque y niebla por shader, no en el arte.
- Recogibles: la mecánica de los reparadores no cambia en este brief (solo el arte).
- Piso y escotilla en 3/4; paredes, techo, ventanal, plataformas y tentáculo en 2D. Las hojas de la escotilla se animan por cuadros (no se rotan por código); la sacudida, el gas y los fragmentos siguen en código.
- Ventanal: el tentáculo entra con `reach`, rompe el vidrio al tocarlo, intenta agarrar al jugador (`grab`) sin alcanzarlo y se retira (`retract`). La descompresión no cambia.
- Todo valor de gameplay o de tiempo va en `Resource` de config; lo visual va como `const` con comentario `## ... Solo visual.`
- Los otros perseguidores y tiers siguen como están; el arte nuevo aplica solo a la nave. (LT y Guido evalúan quitar el tier 3, alargar la nave y una pelea final con el alien; no se toca en este brief.)

## Reglas de trabajo

1. Detenerse al final de cada paso y esperar el "seguí" de LT.
2. Git: rama `feature/arte-nave` desde la base que confirme LT. Un commit por paso. **Sin `git push` ni cambios en GitHub** sin confirmación explícita, mostrando antes árbol de archivos y resumen. Identidad: `git -c user.name=lucantarellis -c user.email=lucantarelli.s@gmail.com`. Agregar archivos por nombre (no `git add -A`). Hay cambios sin commitear de LT (`level_config.tres`, `FirePlatformTest.tscn`, entre otros): no tocarlos ni incluirlos sin preguntar; si estorban, `git stash` con mensaje y devolverlos al final.
3. GDScript tipado, tabulaciones, `##` en español en la API pública (`docs/CONVENCIONES.md`).
4. Permiso de borrado: pedirlo una vez al empezar (locks de git y temporales). Limpiar `.git` tras cada commit: `find .git \( -name '*.lock' -o -name 'tmp_obj_*' \) -delete`.
5. Validación por CLI tras cada paso con `.tools/godot --headless --path . --quit` y carga de escenas (ver notas técnicas del brief 06 en `docs/briefs/brief-06-tuning-mvp.md`). El importador de Wizard necesita el ejecutable de Aseprite, que no existe en el shell Linux: ver Paso 1.
6. Si el brief contradice el repo, avisar antes de seguir.
7. **LT quiere entender qué le toca a él.** Cada vez que algo dependa de una acción suya (instalar, configurar, pintar, probar), explicarlo en pasos concretos y ofrecer dos caminos: que Claude lo haga directamente si se puede desde el shell, o que lo haga en un ejemplo (un segmento, una plataforma) para que LT vea cómo y siga solo.

## Pasos

### Paso 0 — Chequeo de requisitos (antes de tocar nada)

**Objetivo:** que LT sepa qué falta de su lado, qué puede hacer Claude por él y qué conviene ver en un ejemplo.

Revisar el repo y entregar a LT una **lista de pendientes** en tres columnas: *qué falta*, *quién* (LT / Claude / LT con ejemplo de Claude) y *cómo*. Como mínimo, verificar:

1. **Arte sin commitear:** `git status` de `assets/aseprite/`, `assets/sprites/player/astronaut/`, `assets/sprites/environment/ship_walls/`, `assets/sprites/environment/platforms/`, `assets/sprites/environment/background_ship/`, `assets/sprites/environment/floor_ship/`, `assets/sprites/environment/window/`, `assets/sprites/pickups/`, `assets/sprites/intro/`, `resources/tilesets/*ship*`, `assets/palette.*`, `docs/arte/`. Proponer incluirlos en el primer commit (con sus `.import`).
2. **`.import` generados** para los PNG nuevos (si faltan, `.tools/godot --headless --path . --import`).
3. **Aseprite instalado** y su ruta (LT) y **Aseprite Wizard** en `addons/` (Claude puede descargarlo si la red lo permite; si no, LT desde AssetLib, con los pasos).
4. **Segmentos de la nave pasados a la pared nueva:** listar cuáles de `scenes/levels/segments/ship/` (incluidas las salidas con techo) y `start/` siguen usando `walls_tileset.tres`. Ofrecer: (a) que Claude migre **uno** por script (convertir las celdas viejas al terreno `pared_nave` con `set_cells_terrain_connect` y las diagonales a mano según su orientación) para que LT vea el resultado y siga a mano; (b) que Claude migre todos por script y LT solo revise y pinte los daños; (c) que LT lo haga a mano con la guía de `docs/arte/paredes-nave.md`.
5. **Capas de daño y detalle pintadas** (opcional para avanzar): si ningún segmento las tiene, ofrecer pintar un ejemplo en un segmento.
6. **Anchos de plataformas que no son múltiplo de 10** (hoy pocos: 116, 42,1, 142, 39,7 y una rompible de 6 px de alto): listarlos y proponer redondearlos.
7. Cualquier otra cosa del brief que no coincida con el repo.

Esperar la respuesta de LT sobre cada pendiente antes de seguir.

**Commit (si corresponde):** `paso0: arte nuevo de la nave y requisitos`

### Paso 1 — Aseprite Wizard y forma de importar

1. Copiar este brief a `docs/briefs/brief-07-arte-nave.md`.
2. Instalar y activar Aseprite Wizard en `addons/AsepriteWizard/` (según lo acordado en el Paso 0).
3. **Preguntarle a LT (AskUserQuestion)** cómo importar personajes, explicando el costo:
   - **A. Importador automático** (`.aseprite` → `SpriteFrames` al importar). Más simple; requiere Aseprite configurado en **todas** las máquinas y no funciona en el Godot headless del shell.
   - **B. Recursos generados y versionados** (dock del Wizard: PNG + `SpriteFrames` `.tres`). Funciona sin Aseprite en otras máquinas y en headless; hay que reimportar desde el dock cuando cambia el arte. **Recomendada.**
4. Configurar la ruta del ejecutable (LT, con los pasos exactos). Con B, generar los recursos del astronauta, la llama y el tentáculo; la capa `visor_reflejo` en un `SpriteFrames` aparte.

**Criterios de aceptación:**
- [ ] El addon aparece activo en el editor sin errores.
- [ ] Los `.aseprite` de personajes se importan con sus tags y duraciones correctas.

**Commit:** `paso1: aseprite wizard y recursos de personajes`

### Paso 2 — Astronauta

**Entregables:** `Player.tscn` con `AnimatedSprite2D` (cuerpo) + `AnimatedSprite2D` (visor, encima) + `AnimatedSprite2D` (llama, detrás); `player.gd` con la elección de animación y sufijo de daño; `Marker2D` de fuga de gas.

**Especificación:** ver "Arte disponible". El `Polygon2D` placeholder queda transparente u oculto. Mantener el tinte rojizo con combustible vacío si sigue en el código. Revisar que la colisión no se desfase respecto del sprite (lienzo 32×40, pies abajo).

**Criterios de aceptación:**
- [ ] Idle, trote, salto, propulsión vertical y lateral se ven según el movimiento y se espejan bien.
- [ ] Al recibir 1 y 2 golpes cambia a `_dano_1`/`_dano_2` sin saltos de frame.
- [ ] La llama sale de la mochila, detrás del cuerpo, del lado correcto, solo al propulsar.
- [ ] Los pies apoyan en el suelo y la colisión no cambió.

**Commit:** `paso2: astronauta con sprites animados`

### Paso 3 — Mar de tentáculos (nave)

**Entregables:** escena o nodo visual nuevo para el perseguidor de la nave (por ejemplo `scenes/tentacle/TentacleSea.tscn` + `scripts/tentacle/tentacle_sea.gd`), conectado a `Tentacle.tscn` en lugar del frente con doblez **solo para el tier de la nave**; config en `TentacleConfig` o un `Resource` propio (densidad, offsets, rango de `speed_scale`, `modulate` del relleno, intervalo de `reach`, umbral de `grab`).

**Especificación:** capas, orden, ubicación, densidad, alternancia, variedad y secuencia según "Arte disponible". `tentacle_flesh_deep` repetido hacia abajo hasta cubrir la profundidad que hoy cubre `BodyPolygon`. Todo es visual: la `KillZone` no cambia. Mantener `set_active`, `enter` y `apply_pursuer`.

**Criterios de aceptación:**
- [ ] Mar de tentáculos de altura pareja, bases tapadas por la carne, sin cortes.
- [ ] Los de adelante se curvan hacia lados alternados; ninguno se mueve igual al de al lado.
- [ ] `reach`/`grab` se disparan y vuelven a idle sin saltos.
- [ ] La muerte por tentáculo ocurre donde ocurría antes; espacio y alien siguen como antes; intro y R funcionan.

**Commit:** `paso3: mar de tentaculos para la nave`

### Paso 4 — Paredes de la nave

**Entregables:** segmentos de la nave con los tilesets nuevos (según lo acordado en el Paso 0, techo de las salidas incluido) y la **capa emisiva** de paredes, daño y detalle.

**Especificación:** ver `docs/arte/paredes-nave.md`. Capa emisiva: por cada `TileMapLayer` pintado, un hermano con el tileset `*_emissive.tres`, material `CanvasItemMaterial` en modo sin sombreado y las mismas celdas (copiar `tile_map_data` al cargar, o un script `@tool` que lo mantenga sincronizado en el editor). Las fuentes que no existen en el tileset emisivo se ignoran. Si los segmentos se arman por `LevelBuilder`, revisar que las capas nuevas viajen con el segmento.

**Criterios de aceptación:**
- [ ] Las paredes de los segmentos de la nave se ven con el arte nuevo, con bordes y esquinas correctos y colisión igual que antes (diagonales incluidas).
- [ ] Los tiles animados (alarmas, rejillas, paneles, chispas, grietas, bilis, fuga de vapor) se mueven y no están sincronizados entre sí.
- [ ] Las capas de daño y detalle no tienen colisión.

**Commit:** `paso4: paredes de la nave con tilesets nuevos`

### Paso 5 — Plataformas de la nave

**Entregables:** `platform.gd`/`Platform.tscn` dibujando los módulos en lugar del `Polygon2D` para `STATIC`, `ONE_WAY`, `BREAKABLE`, `TIMED` y `PULSE` (con `LETHAL` + `fire_skin` como ya está; el resto de `LETHAL` y `PROJECTILE` siguen con el bloque de color); propulsores en las móviles; `timed_warning_time` nuevo en `PlatformConfig`.

**Especificación:** ver `docs/arte/plataformas-nave.md` (recorte de módulos, ancho redondeado a 10 px, offset −2 px de la rompible, qué tag usar en cada estado, propulsores a ~10 px de cada punta). Seguir el patrón de la piel de fuego (sprites por módulo, `SpriteFrames` cacheados, variante y cuadro inicial al azar con semilla estable). Relieve vía `CanvasTexture`; emisivo en un sprite hermano sin sombreado con el mismo cuadro. `@tool`: que se vean en el editor. `set_tint` por tier no aplica a las plataformas con sprites de la nave.

**Criterios de aceptación:**
- [ ] Cada tipo se ve con su arte y su ancho, en el editor y en juego.
- [ ] Rompible: al pisarla tiembla y cae deshaciéndose; con el dash se rompe al instante con el destello; reaparece con `respawn`.
- [ ] Temporizada: respira antes de apagarse, se apaga con transición, quedan los emisores, vuelve a encenderse con transición.
- [ ] Pulso: segura vacía, aviso con chispas, letal con rayo; mata solo en `on`.
- [ ] Las móviles llevan propulsores y el jugador sigue moviéndose con ellas.

**Commit:** `paso5: plataformas de la nave con sprites`

### Paso 6 — Fondo de la nave

**Entregables:** fondo en parallax para el tier de la nave (por ejemplo `scenes/levels/ShipBackground.tscn` + `scripts/levels/ship_background.gd`), integrado con `LevelBackground`/`SegmentTier` para que se active al entrar a la nave y se desactive al pasar al espacio; `background_config.tres` con velocidades, radios de desenfoque, color e intensidad de la niebla e intensidad de las luces.

**Especificación:** ver `docs/arte/fondo-nave.md`. Una `Parallax2D` por capa con 3 tramos apilados que se reciclan al azar al salir de cámara (sin repetir el mismo dos veces seguidas), loop de 8 cuadros con cuadro inicial al azar, shader de desenfoque por capa, `modulate` de niebla, capa emisiva encima sin oscurecer y resplandores en los puntos de `bg_ship_lights.json` (balizas siguiendo el giro, fuegos que titilan, chispas en sus cuadros). El fondo no lo oscurece el `CanvasModulate` del mundo.

**Criterios de aceptación:**
- [ ] El fondo sube con la cámara a tres velocidades distintas y nunca se corta, aunque el nivel tenga el doble de segmentos.
- [ ] La capa lejana se ve desenfocada, la media apenas, la cercana nítida.
- [ ] Balizas, fuegos y chispas brillan; el resto queda oscuro y no compite con paredes ni plataformas.
- [ ] Al pasar al espacio vuelve el fondo de estrellas como antes.

**Commit:** `paso6: fondo de la nave en parallax`

### Paso 7 — Recogibles

**Entregables:** `Coin.tscn`, `FuelTank.tscn`, `SpeedBoost.tscn` y `Repairer.tscn` con sprites animados en lugar de los placeholders (aura detrás, color, emisivo encima) y la animación de recolección.

**Especificación:** ver `docs/arte/recogibles.md`. Un `AnimatedSprite2D` por capa con los mismos tags (o uno principal y dos hermanos que copien `frame`), `centered = true`, cuadro inicial de `idle` al azar para que no latan sincronizados. Aura y emisivo con `CanvasItemMaterial` sin sombreado. El `Repairer` elige la hoja según su tipo. Al recoger: desactivar la colisión, cortar el balanceo, aplicar el efecto como hoy, reproducir `collect` y liberar el nodo al terminar (en vez de ocultarlo en el acto). Si un spawner reutiliza nodos, volver a `idle` al reaparecer. Colisiones sin cambios.

**Criterios de aceptación:**
- [ ] Cada recogible se ve con su arte, con el aura respirando y el balanceo de siempre; la moneda gira.
- [ ] Los tres reparadores se distinguen (llave, cinta, caja con escudo).
- [ ] Al recogerlos aparece el destello y el anillo se desvanece; el efecto (combustible, monedas, impulso, vida, escudo) se aplica igual que antes y una sola vez.
- [ ] La colisión es la misma que antes.

**Commit:** `paso7: recogibles con sprites`

### Paso 8 — Piso de inicio, escotilla y ventanal

**Entregables:** piso de los 10 `SegmentStart*` con los módulos de `floor_ship` (en lugar del `Polygon2D`); `Hatch.tscn`/`hatch.gd` con los sprites de la escotilla, la capa `glow`, los fragmentos nuevos y un `PointLight2D` rojo; `WindowBreach` con los sprites del ventanal, la succión, los vidrios y el tentáculo dado vuelta.

**Especificación:** ver `docs/arte/piso-y-escotilla.md` y `docs/arte/ventanal.md`.
- Piso: un nodo (por ejemplo `ShipFloor` con script `@tool`) que arma 18 módulos de 20 px sobre la banda de 360 px, con semilla estable por segmento, `hazard` a los lados de la escotilla y `cable` de a 2 o más. Sprite 7 px por encima de la línea de colisión. Relieve vía `CanvasTexture`; emisivo sin sombreado. El `StaticBody2D`/`CollisionPolygon2D` del piso no cambia. Las piezas `wall2d`/`end_l`/`end_r` quedan disponibles pero no se usan.
- Escotilla: `AnimatedSprite2D` para `color` (con relieve), `emissive` y `glow` (estos dos sin sombreado; `glow` en modo aditivo) dentro de `Visual`, sincronizados. `hit()` → `hit_k` y luego `idle_k` (k = golpes, máximo 3); `break_open()` → `break`, `break_finished` al terminar y después `broken`; `set_broken()` → `broken` o `closed`. Las hojas ya no se rotan por código; se quitan los `Polygon2D` (`Frame`, `Hole`, `Glow`, `LeafLeft`, `LeafRight`). `FRAME_TOP` pasa a −15. Fragmentos: cuadro al azar de `hatch_debris` en lugar de los cuadrados. `PointLight2D` rojo con energía por estado (valores en `IntroConfig`): casi nula cerrada, sube con cada golpe, pico en la ruptura, media rota.
- Ventanal: `AnimatedSprite2D` del vidrio (`intact` en loop; al romper `crack` → `shatter` → `broken`) en lugar del `Polygon2D`; `window_wind` encima, sin sombreado, visible solo durante la descompresión con fundido de salida; partículas de vidrio con `window_shards`. Tentáculo: `tentacle_front` con `flip_v`, **detrás** del techo, centrado en el hueco: baja con `reach`; cuando la punta llega al vidrio dispara la rotura (vidrio, sacudida, vidrios, succión, señal `broken`); ya adentro `grab` sin colisión; después `retract` y sube hasta salir, y se libera. Tiempos en `@export` del `WindowBreach`. Colisión del vidrio y descompresión sin cambios.
- La sacudida, el gas, la secuencia de la intro y el lanzamiento del jugador no cambian.

**Criterios de aceptación:**
- [ ] El piso se ve en 3/4 en los 10 segmentos de inicio, sin cortes, y el astronauta pisa en el mismo lugar que antes.
- [ ] La escotilla se ve cerrada con la rendija tenue; cada golpe la abomba más y deja escapar más luz roja hacia arriba.
- [ ] Al romperse, destello, las hojas se abren con rebote, salen los fragmentos y el jugador sale disparado desde el centro superior de la escotilla.
- [ ] La luz roja ilumina el entorno según el estado; sin intro (`set_broken`) se ve rota desde el inicio.
- [ ] En la salida de la nave el tentáculo entra por el ventanal, el vidrio se raja y se rompe al tocarlo, intenta agarrar al jugador y se retira; la succión saca al jugador como antes y las líneas de aire se apagan al terminar.

**Commit:** `paso8: piso de inicio, escotilla y ventanal con sprites`

### Paso 9 — Iluminación

**Entregables:** `CanvasModulate` oscuro en el nivel de la nave, `PointLight2D` en el astronauta y en las fuentes de luz (grietas, alarmas, temporizada encendida, pulso letal, propulsores, escotilla y, opcional, un cian tenue en los recogibles), y un `Resource` de config (`lighting_config.tres`) con color e intensidad de la oscuridad y de cada tipo de luz.

**Especificación:** el relieve de paredes, plataformas, piso, escotilla y ventanal ya viene en las texturas (`CanvasTexture`); las capas emisivas no se oscurecen. La luz del astronauta es la principal: el jugador descubre la nave al subir. La luz ambiente tiene que dejar paredes y plataformas más claras que el fondo (en las pruebas del chat de arte, ~50 %). Las luces de alarma siguen el parpadeo del tile; la del pulso letal parpadea con el rayo. Cuidar el rendimiento (pocas luces activas en pantalla; apagar las que salen de cámara). La UI y el HUD no se oscurecen.

**Criterios de aceptación:**
- [ ] La nave se ve oscura y el entorno se descubre alrededor del astronauta.
- [ ] Los biseles, juntas y roturas reaccionan a la luz según de dónde viene.
- [ ] Grietas, alarmas, puentes, rayos, escotilla y recogibles brillan en la oscuridad; paredes y plataformas siempre se leen sobre el fondo.
- [ ] HUD y menús se ven igual que antes; el juego corre fluido.

**Commit:** `paso9: iluminacion de la nave`

### Paso 10 — Limpieza y documentación

1. Listar a LT lo que queda sin uso (`assets/sprites/Astronaut/`, sprites viejos del tentáculo, `tentacle_front.gd` y el shader `tentacle_bend`, `walls_placeholder.png` y `walls_tileset.tres` si ya no los usa ningún segmento de la nave, el dibujo por polígonos de `repairer.gd`, `hatch.gd` y `window_breach.gd`, el `Polygon2D` del piso) y borrar solo lo que LT confirme.
2. Actualizar `docs/arte/lista-assets.md`, `docs/arte/SPRITES.md` (cómo reimportar), `docs/mecanicas/jugador.md`, `tentaculo.md`, `plataformas.md`, `paredes.md`, `intro-escotilla.md`, `tier-espacio.md` (ventanal), la doc de recogibles, `docs/ARQUITECTURA.md` y `docs/ROADMAP.md`.

**Commit:** `paso10: limpieza de arte viejo y documentacion`

## Cierre

Mostrarle a LT árbol de archivos, `git log --oneline` de la rama y `git diff --stat` contra la base. Con su confirmación explícita: push, PR y merge (flujo de `gh` del brief 06). Si había cambios de LT apartados, `git stash pop` sin descartar nada. Terminar con la lista de lo que LT tiene pendiente (si quedó algo del Paso 0) y cómo hacerlo.

## Resultado esperado

La fase de la nave se ve con el arte nuevo: astronauta y tentáculo animados, paredes con daño y detalle, plataformas con sus estados, un pozo industrial de fondo con profundidad, recogibles con aura y destello, un piso en 3/4 con la escotilla que revienta dejando escapar la luz roja, un ventanal que el tentáculo atraviesa para intentar atrapar al jugador antes de que la descompresión lo saque, y una nave a oscuras que el jugador descubre con su luz. Sin cambios de gameplay ni de colisiones, con el arte viejo retirado y la documentación al día.
