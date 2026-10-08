# Mecánica: niveles por segmentos

**Archivos:** `scripts/levels/level_segment.gd`, `level_config.gd`, `level_builder.gd`, `level_controller.gd`; escenas `scenes/levels/Level.tscn` y `scenes/levels/segments/*.tscn`; config `resources/configs/level_config.tres`.
**Depende de:** `GameManager` (ver `game-manager.md`), `ScrollCamera.set_stop_y()` (ver `scroll-camara.md`), `Door` (ver `puerta.md`) y las escenas de obstáculos y tanques.

## Propósito

Que cada partida se sienta distinta. Un nivel no es una escena fija: se arma en cada partida apilando **segmentos** escritos a mano (escenas reutilizables), elegidos al azar con una **seed** reproducible.

## Modelo en palabras simples

- Un **segmento** es una escena de 360 px de ancho y una altura fija (por defecto 640 px, una pantalla) con plataformas, obstáculos y tanques ya colocados.
- Un nivel es una **torre**: abajo el segmento de **inicio**, encima los segmentos **intermedios** y arriba el segmento **final** con la puerta.
- **Tiers.** Los intermedios se organizan en **tiers** (`LevelConfig.tiers`, una lista de [SegmentTier]). Cada partida recorre los tiers en orden: primero los segmentos del tier 1, después los del tier 2 y así hasta el último. Cada tier tiene su lista de candidatos (`segments`) y cuántos se usan por partida (`count_per_run`). Ejemplo previsto: 3 tiers de 30 candidatos y 10 por partida = 30 intermedios + inicio + final. Un tier sin segmentos se saltea con un aviso en la consola.
- **Sorteo dentro de un tier:** sin repetir mientras alcancen los candidatos (baraja con la seed). Si el tier tiene menos candidatos que `count_per_run`, se vuelve a barajar y se repiten, nunca el mismo dos veces seguidas.
- Con los valores actuales (solo el tier 1 con contenido) una partida tiene 12 segmentos (inicio + 10 + final).
- La **cámara** arranca mostrando el inicio y sube; al llegar al techo del segmento final se detiene con ese segmento completo a la vista.
- **Seed:** el `LevelBuilder` usa un `RandomNumberGenerator` propio, nunca el azar global. La misma seed y la misma config dan siempre el mismo nivel. Con `seed` = 0 en la config se sortea una seed nueva en cada partida; con un valor distinto de 0 el nivel es siempre el mismo. La seed de la partida se ve en el overlay F3 (`seed: N`): sirve para reportar "este nivel estuvo raro" y reproducirlo (poniéndola en `level_config.tres`).
- **R** recarga `Level.tscn`: con `seed` = 0 sale otro nivel.

## Contrato de un segmento

```
      x = 0                 x = 360
y=-H  +-----------------------+   <- techo del segmento (H = height)
      |                       |
      |   plataformas,        |
      |   obstáculos, tanques |
      |                       |
y=0   O-----------------------+   <- origen (0, 0) = esquina INFERIOR izquierda
```

- Ocupa **x ∈ [0, 360]** e **y ∈ [−640, 0]** en coordenadas locales: **todo segmento mide 360 × 640** (una pantalla), sin excepciones, para que cualquier combinación encaje y se diseñe viendo el segmento completo. El constructor coloca el origen en la Y del borde inferior.
- La raíz es un nodo con el script `LevelSegment` (`@tool`). En el editor dibuja el contorno blanco y muestra **advertencias** (icono amarillo en el árbol) si no tiene ningún `FuelTank` o si un hijo directo queda fuera del rectángulo (para un obstáculo se cuenta su bloque entero y, si es móvil, todo su recorrido).
- El alto es fijo (`LevelSegment.HEIGHT` = 640; la propiedad `height` es de solo lectura). `requires_fuel_tank` (por defecto activo) controla la advertencia del tanque.
- **Carpetas:** `scenes/levels/segments/start/` (inicios), `ship/` (tier 1, la nave: `Segment01`–`21` y las salidas `SegmentShipExit01`–`03`), `space/` (tier 2, el espacio: `SegmentSpace01`–`10` y entradas `SegmentSpaceEntry01`–`03`; ver `tier-espacio.md`), `end/` (finales). El tier 3 irá en `alien/`.
- **Inicio** (`SegmentStart01`–`SegmentStart10`, se sortea uno por partida entre `LevelConfig.start_segments`): miden 640 px como todos; el jugador sale volando de la escotilla y sube ~390 px (`launch_speed` = 520). Contrato de cada uno: suelo (`Floor`, y −20..0), un **pasillo central libre (x 132–228)** de punta a punta para el vuelo (ni plataformas ni paredes), tres tanques, un `Marker2D` **`PlayerSpawn`** sobre la plataforma más baja (solo se usa sin intro) y un `Marker2D` **`HatchAnchor`** en (180, −20) (centro del piso: ahí va la escotilla). Dificultad baja: solo `STATIC` y `ONE_WAY`, que se alternan a los costados del pasillo.
- **Final** (`SegmentEnd01`–`SegmentEnd10`, se sortea uno entre `LevelConfig.end_segments`): 640 px, un desafío corto (`BREAKABLE`, `TIMED`, `PULSE`, `LETHAL` fijo o móvil, plataformas móviles) y una **`Door`** (`GoalDoor`) sobre la plataforma de arriba (`Goal`), con un tanque.
- **Paredes** (todos los segmentos): dejan al menos 36 px libres arriba y abajo para que cualquier combinación de segmentos encaje; pueden estar pegadas a los costados o flotando. Ver `docs/mecanicas/paredes.md`.

### Reglas de diseño (criterio del autor; no se validan)

1. **Apoyos en las uniones:** una plataforma en los primeros ≈ 120 px (y > −120) y otra en los últimos ≈ 120 px (y < −520), para que el jugador siempre tenga dónde apoyarse al pasar de un segmento a otro.
2. **Nada peligroso en las uniones:** ningún obstáculo ni trampa a menos de ≈ 60 px del borde superior o inferior, así nunca se superponen con los del segmento vecino. Los actuales quedan a 150 px o más.
3. **Al menos un tanque alcanzable.** Los segmentos actuales tienen dos (uno "cómodo" y otro más arriesgado): un nivel de 8 segmentos necesita ≈ 4500 px de subida y un tanque de 40 u rinde ≈ 489 px, así que con un solo tanque por segmento el nivel no se puede completar.
4. Usar las escenas existentes (`Platform` en sus distintas tipologías — ver `plataformas.md` —, `FuelTank`) con configs por instancia.
5. **Referencias de alcance del salto (brief 06, ronda 2).** Con la gravedad única (250) y `jump_velocity` 260, el ápice del salto es ≈ 133 px y el alcance horizontal depende de cuánto se sube: +90 px de subida deja ≈ 53 px de desvío horizontal disponible, +100 px ≈ 60 px, +110 px ≈ 68 px, +120 px ≈ 76 px, +130 px ≈ 87 px (cerca del ápice). Para que un segmento sea cruzable saltando (sin combustible) conviene un margen del orden del 10-15 % bajo esos máximos: por ejemplo, Δy = 112 px con Δx = 60 px (usado en el piloto de `Segment01`). Un tanque de 40 u sigue rindiendo ≈ 489 px en vertical (ver `tanques.md`).

## Los segmentos del pool

| Escena | Idea |
|---|---|
| `Segment01` | Rediseño ronda 2: dos ramas con `ONE_WAY`/`BREAKABLE`, convergencia, `TIMED`/`PULSE` arriba |
| `Segment02` | Atajo `BREAKABLE` vs. compuerta `PULSE` con `LETHAL` fijo al lado; ferry (`STATIC moves=true`) con tanque encima |
| `Segment03` | `BREAKABLE` vs. `ONE_WAY` en paralelo; `TIMED` + `LETHAL` fijo (`Guard`) arriba |
| `Segment04` | `ONE_WAY` vs. ferry (`STATIC moves=true`); `PULSE` arriba |
| `Segment05` | `LETHAL` móvil horizontal (`Sweeper`) entre dos estáticas; `TIMED` arriba |
| `Segment06` | `PULSE` + `LETHAL` fijo (`Guard`); `BREAKABLE` arriba |
| `Segment07` | Escalera de `ONE_WAY` con un `LETHAL` fijo (`Guard`) al costado para esquivar de paso |
| `Segment08` | Cascada de `BREAKABLE` en paralelo a una ruta `TIMED` segura; convergen antes del final |
| `Segment09` | Corredor con dos `PULSE` en el mismo reloj: cruzar el primero, esperar, cruzar el segundo |
| `Segment10` | Dos `LETHAL` móviles (`Sweeper`) cruzándose en sentidos opuestos, con un `ONE_WAY` de bypass |
| `Segment11` | Ferry (`STATIC moves=true`) que desemboca en una `BREAKABLE`, alternativa por una `TIMED` |
| `Segment12` | `ONE_WAY` móvil (`moves=true`) junto a un `LETHAL` fijo |
| `Segment13` | Escalada ajustada `TIMED`/`PULSE` con una `BREAKABLE` de bonus a un lado (tanque extra) |
| `Segment14` | Tres caminos en paralelo (`ONE_WAY`, esquivar un `LETHAL` fijo, `BREAKABLE`) que convergen |
| `Segment15` | `LETHAL` móvil con recorrido **vertical** (`travel` en Y) en vez del habitual horizontal |
| `Segment16` | Compuerta `PULSE`, puente `ONE_WAY` móvil, `LETHAL` fijo y una `BREAKABLE` de bonus |

Los inicios tienen tres tanques (por su altura) y los finales uno.

## Parámetros (`LevelConfig`, `resources/configs/level_config.tres`)

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Nivel | `seed` | 0 | — | 0 = aleatoria en cada partida; distinto de 0 = fija (reproduce un nivel) |
| Segmentos | `start_segments` | `SegmentStart01`–`SegmentStart10` | — | Candidatos de inicio; se sortea uno por partida con la seed |
| Segmentos | `end_segments` | `SegmentEnd01`–`SegmentEnd10` | — | Candidatos de final; se sortea uno por partida con la seed |
| Segmentos | `tiers` | 3 tiers (el 1 con los 21 segmentos, el 2 y el 3 vacíos) | — | Lista de [SegmentTier], en el orden en que se recorren de abajo hacia arriba |
| Tier (`SegmentTier`) | `segments` | — | — | Escenas candidatas del tier |
| Tier (`SegmentTier`) | `count_per_run` | 10 | segmentos | Cuántos segmentos de este tier se usan por partida |
| Tier → Escenario | `display_name` | "La nave" / "El espacio" / "Dentro del alien" | — | Nombre del tier (depuración y docs) |
| Tier → Escenario | `entry_segments` | vacío | — | Segmentos de entrada (transición): se sortea uno y va antes de los segmentos del tier. Conservan su propio tileset. Vacío = sin transición |
| Tier → Escenario | `exit_segments` | tier 1: `SegmentShipExit01`–`03` | — | Segmentos de salida: se sortea uno y va después de los segmentos del tier |
| Tier → Escenario | `platform_tint` / `hazard_tint` | espacio: gris metálico / naranja | — | Color de las plataformas sólidas y de las letales del tier (alfa 0 = colores de cada tipo). Ver `Platform.set_tint()` |
| Tier → Escenario | `walls_tileset` | vacío | — | TileSet de las paredes del tier (mismas coordenadas de atlas que `walls_tileset.tres`). Vacío = el de cada segmento |
| Tier → Fondo | `background_color` | nave `#10141F`, espacio `#05060A` | — | Color de fondo del tier (alfa 0 = no cambia) |
| Tier → Fondo | `background_stars` | espacio: sí | — | Estrellas con parallax |
| Tier → Fondo | `background_fade` | 0,4 | s | Fundido al entrar al tier |
| Tier → Perseguidor | `pursuer_config` | vacío | — | `TentacleConfig` del perseguidor del tier (tentáculo, fuego, ácido). Vacío = sigue el anterior |
| Tier → Perseguidor | `pursuer_color` | rojo `#D83232` | — | Color placeholder del perseguidor; se aplica siempre al entrar al tier |
| Tier → Perseguidor | `pursuer_delay` | espacio: 1,5 | s | Segundos que tarda en aparecer el perseguidor al entrar al tier |
| Tier → Perseguidor | `pursuer_reset_position` | true | — | Con `pursuer_config`: al entrar al tier, el perseguidor vuelve a su distancia inicial (uno nuevo que aparece) |
| Tier → Jugador | `gravity_scale` | 1 | × | Multiplica la gravedad del jugador en el tier (ej.: 0,16 en el espacio) |
| Tier → Jugador | `air_drag_scale` | 1 (espacio 0,05) | × | Multiplica el frenado en el aire (`coasting_drag`): menos = más inercia |
| Tier → Jugador | `counter_thrust_scale` | 1 (espacio 0,45) | × | Multiplica la propulsión en contra del movimiento: menos = frenar cuesta más tiempo y combustible |

**Cambio de tier en la partida.** `LevelBuilder.get_tier_starts()` da la Y donde empieza cada tier. El segmento de inicio cuenta como parte del primer tier: su escenario se aplica desde el arranque. Para los siguientes, `LevelController` vigila al jugador y, al cruzar subiendo el borde de un tier, le aplica su escenario: `Tentacle.apply_pursuer(config, color, reset)` y `Player.set_physics_scales(gravedad, frenado)`, y emite `tier_entered(tier_index)` (`get_current_tier()` da el tier actual; -1 en el inicio). El tileset de paredes lo pone el `LevelBuilder` al armar. El HUD marca el inicio de cada tier (salvo el primero) en la línea de progreso.

Los valores son de prueba: el balance se hace con el MVP completo.

## API de `LevelBuilder`

Nodo `Node2D` (debe estar en el origen (0, 0)) con `@export var config: LevelConfig`.

| Función / señal | Descripción |
|---|---|
| `build(seed_override: int = 0) -> int` | Arma el nivel y devuelve la seed usada (limpia el anterior). Prioridad: `seed_override` ≠ 0, luego `config.seed` ≠ 0, luego una seed sorteada |
| `clear() -> void` | Elimina los segmentos |
| `get_player_spawn() -> Vector2` | Posición global del `PlayerSpawn` |
| `get_hatch_position() -> Vector2` | Posición global del `HatchAnchor` del segmento de inicio ((180, 620): centro del piso, con el pasillo del vuelo libre encima); ahí se ubica la `Hatch` de la intro |
| `get_camera_stop_y() -> float` | Y global del centro de la cámara para que el segmento final quede completo a la vista (se pasa a `ScrollCamera.set_stop_y`) |
| `get_segment_count() -> int` | Segmentos intermedios armados |
| `get_seed() -> int`, `get_sequence() -> PackedInt32Array`, `get_segments() -> Array[LevelSegment]`, `get_goal_door() -> Door` | Consultas (índices elegidos, segmentos de abajo hacia arriba, puerta del final). Con tiers, `get_sequence()` da el índice dentro de la lista de su tier |
| `get_start_index() -> int`, `get_end_index() -> int` | Índice del inicio y del final elegidos en `start_segments` / `end_segments` (-1 sin nivel). La misma seed repite los mismos |
| `get_tier_starts() -> Array[Dictionary]` | Inicio de cada tier armado, de abajo hacia arriba: `{tier, y}` (índice en `tiers` e Y global del borde inferior de su primer segmento, entrada incluida). Los tiers salteados no aparecen |
| `get_tier_sequence() -> PackedInt32Array` | El tier (0 = tier 1) de cada segmento intermedio, en el mismo orden que `get_sequence()`. Vacío en modo plano |
| señal `level_built(level_seed)` | Al terminar de armar el nivel |

## Estructura de `Level.tscn`

```
Level (Node2D)          script: level_controller.gd
├── LevelBuilder        script: level_builder.gd, config = level_config.tres
│   └── (segmentos, agregados al iniciar)
├── ScrollCamera
├── Hatch               scenes/intro/Hatch.tscn (escotilla de la intro; se ubica en el HatchAnchor)
├── Player
├── Tentacle            (export camera)
├── DebugOverlay        (F3: incluye la seed)
└── CaughtLayer         mensaje de fin de partida
```

Al iniciar, `LevelController` hace: `LevelBuilder.build()` → `Player.reset(get_player_spawn())` → `ScrollCamera.set_stop_y(get_camera_stop_y())` → conecta la puerta del final → `begin()` (que llama a `GameManager.start_run(seed)`). Con `LevelController.autostart = false` el nivel queda armado pero en pausa (`process_mode = DISABLED`) hasta que alguien llame a `begin()`; así `Main` lo muestra detrás del título. `begin()` es idempotente.

## Guía paso a paso: crear un segmento nuevo

1. **Escena nueva.** Crear una escena con raíz `Node2D`, guardarla en `scenes/levels/segments/` (`Segment07.tscn`) y adjuntarle el script `scripts/levels/level_segment.gd` (o "Nueva escena → Heredar" no hace falta: alcanza con el script).
2. **Altura.** En el inspector, `Height` (por defecto 640). Recordá que el origen es la esquina inferior izquierda: todo va con Y negativa (de 0 a −Height) y X de 0 a 360. El editor dibuja el contorno blanco.
3. **Apoyos.** Agregá plataformas (`StaticBody2D` en la capa 1 con un `Polygon2D` azul `#3A9BBF` y un `CollisionPolygon2D`; lo más fácil es duplicar una de otro segmento) en los primeros y en los últimos ≈ 120 px.
4. **Contenido.** Instanciá (Ctrl+Shift+A) `Platform` y `FuelTank` y ajustá `Size`, `Platform Type`, `Travel` y `Config` por instancia. Poné **al menos un tanque** (mejor dos, ver reglas). Mantené los obstáculos lejos de las uniones.
5. **Advertencias.** Si el árbol de escena muestra un icono amarillo en la raíz, pasá el cursor: dice si falta un tanque o si algo queda fuera del rectángulo.
6. **Verlo aislado.** Abrí la escena del segmento y ejecutá con F6: como es la escena actual, `LevelSegment` agrega una cámara centrada que lo encuadra completo (con zoom si es más alto que la pantalla) y se ven los obstáculos moverse; no hay jugador. Para **jugarlo**: poné solo ese segmento en `segment_pool` de una copia de `level_config.tres` (con `segment_count` = 1), asignala al `LevelBuilder` de `Level.tscn` y ejecutá con F6; acordate de volver a la config original.
7. **Agregarlo a un tier.** En `resources/configs/level_config.tres` (inspector, **Segmentos → Tiers → Tier N → Segments**), agregá la escena al final del arreglo del tier que corresponda. 
8. **Reproducir un nivel.** Si un nivel salió raro, copiá la seed del F3 en **Nivel → Seed** de `level_config.tres` y ejecutá `Level.tscn`; volvé a 0 para tener niveles aleatorios.

## Cómo probarlo

1. Abrir `scenes/levels/Level.tscn` y ejecutar con F6 (F3 para ver la seed). Aparece un nivel completo: inicio, 10 segmentos del tier 1 (hoy los únicos con contenido) y una puerta al final.
2. Reiniciar con R varias veces: cambia el orden de los segmentos.
3. Poner `seed` ≠ 0 en `level_config.tres`: el nivel se repite igual en cada reinicio y F3 muestra esa seed.
4. Llegar a la puerta: "ESCAPASTE" y la cámara se detiene con el segmento final completo a la vista.
5. Validación automática: un script headless (fuera del repo) arma 200 seeds y comprueba orden, apilado, ausencia de repeticiones consecutivas y reproducibilidad, y revisa cada segmento del pool (tanque, límites, sin advertencias).
