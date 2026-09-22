# Mecánica: plataformas

**Archivos:** `scripts/platforms/platform.gd`, `platform_config.gd`; escena `scenes/platforms/Platform.tscn`; config `resources/configs/platform_config.tres`. Fix relacionado: `scripts/levels/level_segment.gd` (`_get_child_rect`) reconoce `Platform` igual que `Obstacle`/`Door` para el chequeo de límites del segmento.

## Propósito

Todo lo que el jugador pisa, esquiva o lo mata en un segmento es una sola cosa: `Platform`. Antes había dos sistemas separados solo porque tenían nombres distintos (`Platform` para lo sólido, `Obstacle`/`MovingObstacle`/`PulseTrap` para lo letal) — se unificaron en la ronda 2 en un solo tipo, con dos ejes independientes:

- **`platform_type`**: qué hace al tocarla — sólida siempre, solo desde arriba, se rompe, aparece y desaparece, mata siempre, o alterna entre segura y letal.
- **`moves`**: si además va y viene entre dos puntos. Es independiente del tipo: una plataforma sólida puede moverse (te lleva con ella) y una letal también (el viejo `MovingObstacle`).

`Obstacle`, `MovingObstacle` y `PulseTrap` (`scripts/obstacles/`) siguen existiendo porque todavía los usan `sandbox.tscn` y los segmentos 02, 03, 05 y 06 — se migran a `Platform` cuando se rediseñen esos segmentos con el sistema nuevo. No agregar instancias nuevas de esos tres: para cualquier plataforma nueva, usar `Platform`.

## Tipologías (`platform_type`)

| Tipo | Comportamiento | Color placeholder | Reemplaza a |
|---|---|---|---|
| `STATIC` | Sólida siempre, colisiona desde cualquier lado. | Celeste `#3A9BBF` | (plataformas de antes) |
| `ONE_WAY` | Sólida solo desde arriba: se puede saltar a través desde abajo o los costados, y caer de nuevo a través de ella. | Verde `#8CC94C` | — |
| `BREAKABLE` | Se rompe (deja de ser sólida) después de `break_delay` segundos parada encima, y vuelve a aparecer tras `respawn_time`. No mata directamente: el riesgo es la caída. | Naranja `#E59A4C` | — |
| `TIMED` | Alterna sólida/ausente en un ciclo fijo: `timed_on_duration` sólida, `timed_off_duration` ausente. Si el jugador está en medio cuando le tocaría volverse sólida, espera a que se libere (no lo empuja). | Violeta `#B364C9` | — |
| `LETHAL` | Nunca sólida, siempre letal al tocarla. | Rojo `#D83232` | `Obstacle` |
| `PULSE` | Alterna segura y sólida (con aviso parpadeante) / letal, en un ciclo fijo. | Azul `#3A9BBF` (segura) → blanco parpadeante (aviso) → rojo `#D83232` (letal) | `PulseTrap` |

`moves = true` (cualquier tipo) reemplaza a `MovingObstacle` cuando además `platform_type = LETHAL`, y agrega "plataforma móvil que se puede pisar" cuando el tipo es sólido — algo que no existía antes.

## Modelo en palabras simples

- **Es un `AnimatableBody2D`** (subtipo de `StaticBody2D`, capa 1 `world`, máscara 0): el jugador choca físicamente contra ella cuando es sólida. `sync_to_physics` hace que, si se mueve (`moves = true`), el jugador parado encima se mueva con ella en vez de quedarse atrás. `size` regenera el polígono visual y la forma de colisión; el origen del nodo es el **centro** del bloque.
- **Letalidad** (`LETHAL`, y `PULSE` en fase ON) usa un `Area2D` hijo (`LethalArea`, capa 0, máscara 2 `player`) del tamaño completo del bloque: si un `Player` vivo la toca, `Player.die(cause)`. `cause` es configurable por instancia, igual que en el viejo `Obstacle`.
- **`ONE_WAY`** usa la propiedad nativa `one_way_collision` del `CollisionShape2D`, con margen configurable (`one_way_margin`, 5 px por defecto, más grande que el default del motor de 1 px). Validado en una prueba headless aislada: el jugador atraviesa subiendo y aterriza normal al caer. Ojo: la ronda anterior encontramos un bug de one-way en una prueba más encadenada — confirmado ahora por LT jugando que funciona bien.
- **`BREAKABLE`** usa un sensor (`StepSensor`, franja fina pegada al borde superior) para detectar "parado encima" y arrancar la cuenta de `break_delay`. Feedback de LT: con el valor por defecto (0,15 s) no da tiempo de reaccionar — **queda así a propósito**, es la plataforma-trampa: parece un buen camino pero desaparece apenas la pisás.
- **`TIMED`** usa un segundo sensor (`FootprintSensor`, del tamaño completo) solo para revisar, antes de volverse sólida, si el jugador está en medio — si lo está, espera a que se libere en vez de empujarlo (bug encontrado y arreglado en el playtest de LT).
- **`PULSE`** es una máquina de tres fases (segura → aviso parpadeante → letal → repite), igual que el viejo `PulseTrap`: mientras es segura, es sólida (se puede parar encima); al activarse, dejar de ser sólida y pasa a matar.
- **`moves`** reutiliza el mismo cálculo de recorrido que el viejo `MovingObstacle` (velocidad, pausa en los extremos, suavizado, `start_delay`), pero como propiedad independiente del tipo: aplica iguales a `STATIC` (plataforma móvil pisable) que a `LETHAL` (bloque móvil letal).
- **Diseño de nivel vs. tuning**: `size`, `platform_type`, `moves`, `travel` y `cause` son diseño de nivel (por instancia). Los tiempos (`break_delay`, `respawn_time`, `timed_on_duration`, `timed_off_duration`, `timed_start_on`, `one_way_margin`, `moving_*`, `pulse_*`) son tuning y viven en `PlatformConfig` (`resources/configs/platform_config.tres`). Para que una instancia tenga tiempos propios, duplicar el `.tres` o hacerlo único en el inspector.
- **`@tool`**: en el editor se ve el color según el tipo/fase, el nombre del tipo arriba del bloque, y si `moves` es true, la trayectoria dibujada en rojo.

## Parámetros

### Por instancia (diseño de nivel)

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `size` | Vector2 | (80, 12) | px | Tamaño del bloque |
| `platform_type` | enum | `STATIC` | — | Tipología (ver tabla arriba) |
| `cause` | StringName | `&"obstacle"` | — | Causa que recibe `Player.die` (solo LETHAL / PULSE en ON) |
| `moves` | bool | false | — | Si va y viene entre su posición inicial y `inicial + travel` |
| `travel` | Vector2 | (120, 0) | px | Desplazamiento del extremo final (solo si `moves`) |
| `config` | PlatformConfig | `platform_config.tres` | — | Tiempos (ver abajo) |

### `PlatformConfig`

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|---|
| Rompible | `break_delay` | float | 0,15 | s | Segundos parado encima antes de romperse |
| Rompible | `respawn_time` | float | 2,0 | s | Segundos hasta que reaparece |
| Temporizada | `timed_on_duration` | float | 2,0 | s | Segundos sólida por ciclo |
| Temporizada | `timed_off_duration` | float | 1,0 | s | Segundos ausente por ciclo |
| Temporizada | `timed_start_on` | bool | true | — | Si el ciclo empieza sólida o ausente |
| One-way | `one_way_margin` | float | 5,0 | px | Margen de colisión de un solo sentido |
| Movimiento | `moving_speed` | float | 60 | px/s | Velocidad media de desplazamiento |
| Movimiento | `moving_pause_at_ends` | float | 0,5 | s | Pausa en cada extremo |
| Movimiento | `moving_ease_at_ends` | bool | true | — | Acelera/frena suave cerca de los extremos |
| Movimiento | `moving_start_delay` | float | 0,0 | s | Espera antes de empezar (desfasar instancias) |
| Pulso | `pulse_on_time` | float | 1,5 | s | Tiempo letal por ciclo |
| Pulso | `pulse_off_time` | float | 1,5 | s | Tiempo segura por ciclo (incluye el aviso) |
| Pulso | `pulse_warning_time` | float | 0,5 | s | Últimos segundos seguros en que parpadea |
| Pulso | `pulse_initial_offset` | float | 0,0 | s | Desfase del ciclo al empezar |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `breaking_started` | Una `BREAKABLE` empezó a romperse |
| `broke` | Una `BREAKABLE` se rompió |
| `restored` | Una `BREAKABLE`, `TIMED` o `PULSE` volvió a estar sólida/segura |
| `player_hit(cause)` | Un `Player` vivo tocó la plataforma en fase letal |

## API pública

| Función | Descripción |
|---|---|
| `reset() -> void` | Vuelve al estado inicial: posición de origen, sin romper, fase de arranque |

## Cómo probarlas

Ver el flujo de QA por segmento en `docs/mecanicas/niveles-por-segmentos.md` (`LevelSegmentQA.tscn` + `level_config_segment_qa.tres`). `Segment01` tiene ejemplos de `STATIC`, `ONE_WAY`, `BREAKABLE` y `TIMED`. Los tipos `LETHAL`, `PULSE` y `moves` todavía no tienen ejemplo en un segmento — validados por ahora solo con pruebas headless (`$HOME/sims/platform_test5.gd`).

## Feedback de LT (ronda 2) y estado

- One-way: confirmado que funciona bien jugando.
- Rompible: se queda como trampa a propósito (no da tiempo de reaccionar).
- Temporizada: arreglado el bug de empujar al jugador al reaparecer encima suyo.
- **Letal invisible durante el juego (bug, arreglado)**: `LETHAL` desactiva la colisión física con `_apply_solid(false)`, y esa función también ocultaba el bloque (`_body.visible = false`) como efecto secundario — pensada originalmente para BREAKABLE, donde sí tiene sentido que el bloque desaparezca al romperse. Resultado: toda plataforma `LETHAL` (Sweeper, Guard, Hazard) era invisible en juego real aunque se veía bien en el editor (el `@tool` dibuja la etiqueta de tipo por separado con `_draw()`, lo cual ocultaba el problema ahí). Arreglado separando ambos conceptos: `_apply_solid(solid, body_visible)` ahora permite no ser sólido y seguir visible; `LETHAL` usa `_apply_solid(false, true)`. Esto también aplica al caso de `Guard` en Segment03/06 reportado antes: aunque ese golpe puntual se confirmó geométricamente real (rozó una esquina), es probable que tampoco se viera el bloque en pantalla en ese momento por el mismo bug, lo que lo hizo sentir más injusto de lo que era.
- Pendiente: más diversidad de ubicación y tipos por segmento (en curso).
- Pendiente: evaluar una quinta tipología para "romper desde abajo" (golpear el borde inferior), y mecánicas no implementadas: plataformas resbaladizas, trampolín, corriente de aire.
