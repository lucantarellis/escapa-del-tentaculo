# Mecánica: plataformas

**Archivos:** `scripts/platforms/platform.gd`, `platform_config.gd`; escena `scenes/platforms/Platform.tscn`; config `resources/configs/platform_config.tres`. Fix relacionado: `scripts/levels/level_segment.gd` (`_get_child_rect`) reconoce `Platform` igual que `Obstacle`/`Door` para el chequeo de límites del segmento.

## Propósito

Hasta la ronda 2 cada plataforma de un segmento era un `StaticBody2D` armado a mano (`Polygon2D` + `CollisionPolygon2D` con las cuatro esquinas escritas a mano). Para poder variar el tipo de plataforma sin repetir esa estructura y sin tocar código en cada segmento, `Platform` la reemplaza por una escena única, parametrizada por `size` y `platform_type`, siguiendo el mismo patrón que `obstacles/` (`Obstacle` + `size` + `Config`).

## Tipologías (`platform_type`)

| Tipo | Comportamiento | Color placeholder |
|---|---|---|
| `STATIC` | Sólida siempre, colisiona desde cualquier lado. Es la plataforma "de toda la vida". | Celeste `#3A9BBF` |
| `ONE_WAY` | Sólida solo desde arriba: se puede saltar a través desde abajo o los costados, y caer de nuevo a través de ella. | Verde `#8CC94C` |
| `BREAKABLE` | Se rompe (deja de ser sólida) después de `break_delay` segundos parada encima, y vuelve a aparecer tras `respawn_time`. | Naranja `#E59A4C` |
| `TIMED` | Alterna sólida/ausente en un ciclo fijo: `timed_on_duration` sólida, `timed_off_duration` ausente, repite. | Violeta `#B364C9` |

## Modelo en palabras simples

- **Es un `StaticBody2D`** (capa 1 `world`, máscara 0), igual que antes: el jugador choca físicamente contra ella (a diferencia de `Obstacle`, que es un `Area2D` letal). `size` regenera el polígono visual y la forma de colisión (`RectangleShape2D`); el origen del nodo es el **centro** del bloque, igual que `Obstacle`/`Door` (antes era la esquina inferior izquierda de la lista de puntos).
- **`ONE_WAY`** usa la propiedad nativa `one_way_collision` del `CollisionShape2D`, con un margen (`one_way_margin` en `PlatformConfig`, 5 px por defecto) más grande que el default del motor (1 px) para que no se atraviese al caer rápido. Validado en una prueba headless aislada: el jugador atraviesa subiendo y aterriza normalmente al caer. **Ojo:** la ronda anterior encontramos un bug de one-way en una prueba encadenada (subir y bajar por la misma trayectoria varias veces); esta prueba nueva es más simple, así que conviene confirmarlo también jugando, no solo con la simulación.
- **`BREAKABLE`** usa un sensor (`Area2D` hijo, `StepSensor`) pegado al borde superior del bloque que detecta cuándo el jugador está parado encima; ahí arranca la cuenta de `break_delay`. Al romperse, se desactiva la colisión (diferido, seguro dentro de física) y se oculta; después de `respawn_time` vuelve. En la prueba headless se rompió ~0,45 s después de empezar a caer el jugador — con `break_delay` = 0,15 s por defecto, se sintió bastante inmediata (el sensor puede activarse un poco antes de que el juego marque `on_floor`). Si en el playtest se siente "se rompe apenas la toco", es cuestión de subir `break_delay` en el config, no un bug.
- **`TIMED`** no necesita detectar al jugador: un timer interno alterna sólida/ausente. Si el jugador está parado encima cuando se desactiva, cae (no hay red de seguridad, es la gracia del tipo).
- **Todas comparten forma y tuning-vs-diseño**: `size` y `platform_type` son diseño de nivel (se editan por instancia); los tiempos (`break_delay`, `respawn_time`, `timed_on_duration`, `timed_off_duration`, `timed_start_on`, `one_way_margin`) son tuning y viven en `PlatformConfig` (`resources/configs/platform_config.tres`). Para que una instancia tenga tiempos propios, duplicar el `.tres` o hacerlo único en el inspector.
- **`@tool`**: en el editor se ve el color según el tipo y el nombre del tipo dibujado arriba del bloque, para identificarlas de un vistazo sin correr el juego.

## Parámetros

### Por instancia (diseño de nivel)

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `size` | Vector2 | (80, 12) | px | Tamaño del bloque (ancho, alto) |
| `platform_type` | enum | `STATIC` | — | Tipología (ver tabla arriba) |
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

## Señales

| Señal | Cuándo se emite |
|---|---|
| `breaking_started` | Una `BREAKABLE` empezó a romperse (el jugador se paró encima) |
| `broke` | Una `BREAKABLE` se rompió |
| `restored` | Una `BREAKABLE` o `TIMED` volvió a estar sólida |

## API pública

| Función | Descripción |
|---|---|
| `reset() -> void` | Vuelve al estado inicial: sólida, sin romper, fase temporizada de arranque |

## Cómo probarlas

Ver el flujo de QA por segmento en `docs/mecanicas/niveles-por-segmentos.md` (`LevelSegmentQA.tscn` + `level_config_segment_qa.tres`). `Segment01` tiene ejemplos de los cuatro tipos: `Start`/`Converge1`/`Converge2`/`End` son `STATIC`; `Branch1Near`/`Branch2Right` son `ONE_WAY`; `Branch1Far` es `BREAKABLE`; `BonusLedge`/`Branch2Left` son `TIMED`.

## Pendiente

- Confirmar la sensación de `break_delay` y `one_way_margin` jugando (ver notas arriba).
- Evaluar si conviene una quinta tipología para "romper desde abajo" (golpear el borde inferior), pedida por LT junto con plataformas verticales, resbaladizas y trampolín — no implementadas todavía.
