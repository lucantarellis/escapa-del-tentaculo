# Mecánica: niveles por segmentos

**Archivos:** `scripts/levels/level_segment.gd`, `level_config.gd`, `level_builder.gd`, `level_controller.gd`; escenas `scenes/levels/Level.tscn` y `scenes/levels/segments/*.tscn`; config `resources/configs/level_config.tres`.
**Depende de:** `GameManager` (ver `game-manager.md`), `ScrollCamera.set_stop_y()` (ver `scroll-camara.md`), `Door` (ver `puerta.md`) y las escenas de obstáculos y tanques.

## Propósito

Que cada partida se sienta distinta. Un nivel no es una escena fija: se arma en cada partida apilando **segmentos** escritos a mano (escenas reutilizables), elegidos al azar con una **seed** reproducible.

## Modelo en palabras simples

- Un **segmento** es una escena de 360 px de ancho y una altura fija (por defecto 640 px, una pantalla) con plataformas, obstáculos y tanques ya colocados.
- Un nivel es una **torre**: abajo el segmento de **inicio**, encima `segment_count` segmentos **intermedios** elegidos del pool, y arriba el segmento **final** con la puerta. Con los valores actuales son 8 segmentos y 4480 px.
- La **cámara** arranca mostrando el inicio y sube; al llegar al techo del segmento final se detiene con ese segmento completo a la vista.
- **Seed:** el `LevelBuilder` usa un `RandomNumberGenerator` propio, nunca el azar global. La misma seed y la misma config dan siempre el mismo nivel. Con `seed` = 0 en la config se sortea una seed nueva en cada partida; con un valor distinto de 0 el nivel es siempre el mismo. La seed de la partida se ve en el overlay F3 (`seed: N`): sirve para reportar "este nivel estuvo raro" y reproducirlo (poniéndola en `level_config.tres`).
- **Sin repeticiones cercanas:** un segmento no se repite dentro de los últimos `avoid_repeat_window` elegidos. Con un pool chico la regla se relaja sola: primero solo evita repetir el inmediato anterior, y con un pool de un solo segmento lo repite.
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

- Ocupa **x ∈ [0, 360]** e **y ∈ [−height, 0]** en coordenadas locales. El constructor coloca el origen en la Y del borde inferior.
- La raíz es un nodo con el script `LevelSegment` (`@tool`). En el editor dibuja el contorno blanco y muestra **advertencias** (icono amarillo en el árbol) si no tiene ningún `FuelTank` o si un hijo directo queda fuera del rectángulo (para un obstáculo se cuenta su bloque entero y, si es móvil, todo su recorrido).
- `height` (px) es diseño de nivel. `requires_fuel_tank` (por defecto activo) controla la advertencia del tanque.
- **Inicio** (`SegmentStart.tscn`): suelo, plataforma de inicio y un `Marker2D` llamado **`PlayerSpawn`** (en (180, −92): equivale a la posición (180, 548) del sandbox cuando el borde inferior está en Y = 640).
- **Final** (`SegmentEnd.tscn`): plataformas y una **`Door`** cerca de la parte superior. Sin tentáculo ni requisitos extra.

### Reglas de diseño (criterio del autor; no se validan)

1. **Apoyos en las uniones:** una plataforma en los primeros ≈ 120 px (y > −120) y otra en los últimos ≈ 120 px (y < −520), para que el jugador siempre tenga dónde apoyarse al pasar de un segmento a otro.
2. **Nada peligroso en las uniones:** ningún obstáculo ni trampa a menos de ≈ 60 px del borde superior o inferior, así nunca se superponen con los del segmento vecino. Los actuales quedan a 150 px o más.
3. **Al menos un tanque alcanzable.** Los segmentos actuales tienen dos (uno "cómodo" y otro más arriesgado): un nivel de 8 segmentos necesita ≈ 4500 px de subida y un tanque de 40 u rinde ≈ 489 px, así que con un solo tanque por segmento el nivel no se puede completar.
4. Usar las escenas existentes (`Obstacle`, `MovingObstacle`, `PulseTrap`, `FuelTank`) con configs por instancia.
5. Referencias de alcance (ver `tanques.md`): un salto sin combustible llega a ≈ 61 px; un tanque de 40 u rinde ≈ 489 px en vertical. Las plataformas actuales están separadas ≈ 150–160 px.

## Los segmentos del pool

| Escena | Idea |
|---|---|
| `Segment01` | Plataformas escalonadas alternando izquierda/derecha; un tanque a mitad y otro cerca del techo |
| `Segment02` | Pasillo estrechado por dos bloques estáticos, con un tanque adentro; arriba, un obstáculo móvil horizontal |
| `Segment03` | Dos trampas intermitentes anchas con distinto desfase (`initial_offset`); tanques en plataformas |
| `Segment04` | Tanque en una repisa elevada 45 px que solo se alcanza saltando desde la plataforma vecina (sin combustible) |
| `Segment05` | Dos móviles horizontales que se cruzan en sentidos opuestos, con tanques en plataformas |
| `Segment06` | Tanque pegado a una trampa vertical; bloque estático sobre una plataforma alta |

`SegmentStart` y `SegmentEnd` tienen un tanque cada uno.

## Parámetros (`LevelConfig`, `resources/configs/level_config.tres`)

| Grupo | Variable | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| Nivel | `segment_count` | 6 | — | Cantidad de segmentos intermedios por partida |
| Nivel | `seed` | 0 | — | 0 = aleatoria en cada partida; distinto de 0 = fija (reproduce un nivel) |
| Nivel | `avoid_repeat_window` | 1 | — | Un segmento no se repite dentro de los últimos N elegidos |
| Segmentos | `start_segment` / `end_segment` | `SegmentStart` / `SegmentEnd` | — | Escenas fijas de inicio y final |
| Segmentos | `segment_pool` | los 6 intermedios | — | Escenas candidatas (`Array[PackedScene]`) |

Los valores son de prueba: el balance se hace con el MVP completo.

## API de `LevelBuilder`

Nodo `Node2D` (debe estar en el origen (0, 0)) con `@export var config: LevelConfig`.

| Función / señal | Descripción |
|---|---|
| `build(seed_override: int = 0) -> int` | Arma el nivel y devuelve la seed usada (limpia el anterior). Prioridad: `seed_override` ≠ 0, luego `config.seed` ≠ 0, luego una seed sorteada |
| `clear() -> void` | Elimina los segmentos |
| `get_player_spawn() -> Vector2` | Posición global del `PlayerSpawn` |
| `get_hatch_position() -> Vector2` | Posición global del `HatchAnchor` del segmento de inicio ((290, 620) en el nivel actual: fuera del alcance de `StartPlatform`, para poder lanzar al jugador hacia arriba); ahí se ubica la `Hatch` de la intro |
| `get_camera_stop_y() -> float` | Y global del centro de la cámara para que el segmento final quede completo a la vista (se pasa a `ScrollCamera.set_stop_y`) |
| `get_segment_count() -> int` | Segmentos intermedios armados |
| `get_seed() -> int`, `get_sequence() -> PackedInt32Array`, `get_segments() -> Array[LevelSegment]`, `get_goal_door() -> Door` | Consultas (índices del pool elegidos, segmentos de abajo hacia arriba, puerta del final) |
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
4. **Contenido.** Instanciá (Ctrl+Shift+A) `Obstacle`, `MovingObstacle`, `PulseTrap` y `FuelTank` y ajustá `Size`, `Travel` y `Config` por instancia. Poné **al menos un tanque** (mejor dos, ver reglas). Mantené los obstáculos lejos de las uniones.
5. **Advertencias.** Si el árbol de escena muestra un icono amarillo en la raíz, pasá el cursor: dice si falta un tanque o si algo queda fuera del rectángulo.
6. **Verlo aislado.** Abrí la escena del segmento y ejecutá con F6: como es la escena actual, `LevelSegment` agrega una cámara centrada que lo encuadra completo (con zoom si es más alto que la pantalla) y se ven los obstáculos moverse; no hay jugador. Para **jugarlo**: poné solo ese segmento en `segment_pool` de una copia de `level_config.tres` (con `segment_count` = 1), asignala al `LevelBuilder` de `Level.tscn` y ejecutá con F6; acordate de volver a la config original.
7. **Agregarlo al pool.** En `resources/configs/level_config.tres` (inspector, **Segmentos → Segment Pool**), agregá la escena al final del arreglo.
8. **Reproducir un nivel.** Si un nivel salió raro, copiá la seed del F3 en **Nivel → Seed** de `level_config.tres` y ejecutá `Level.tscn`; volvé a 0 para tener niveles aleatorios.

## Cómo probarlo

1. Abrir `scenes/levels/Level.tscn` y ejecutar con F6 (F3 para ver la seed). Aparece un nivel completo: inicio, 6 segmentos y una puerta al final.
2. Reiniciar con R varias veces: cambia el orden de los segmentos.
3. Poner `seed` ≠ 0 en `level_config.tres`: el nivel se repite igual en cada reinicio y F3 muestra esa seed.
4. Llegar a la puerta: "ESCAPASTE" y la cámara se detiene con el segmento final completo a la vista.
5. Validación automática: un script headless (fuera del repo) arma 200 seeds y comprueba orden, apilado, ausencia de repeticiones consecutivas y reproducibilidad, y revisa cada segmento del pool (tanque, límites, sin advertencias).
