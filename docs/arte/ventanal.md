# Ventanal del techo (salida de la nave)

Lo usa `WindowBreach` en los segmentos de salida (`SegmentShipExit01`–`03`). Todo en **2D**.

## Techo

- No lleva arte propio: es el tileset de paredes de la nave (`walls_tileset_ship.tres`, terreno `pared_nave`). Las 3 filas de tiles del techo (y −600 a −564, hueco x 144–216) se migran como el resto de las paredes.

## Ventanal (`window_breach`)

- Editable: `assets/aseprite/environment/window/window_breach.aseprite` (capas `normal` oculta y `color`).
- Hojas verticales de **96×112** por cuadro: `assets/sprites/environment/window/window_breach.png` (+ `window_breach.json`) y `window_breach_normal.png`.
- **Origen:** el centro del vidrio (la posición de `WindowBreach`) está en **(48, 34)** del cuadro. Con `centered = true`, `offset = (0, 22)`.
- Vidrio de 72×36 (igual que `glass_size`), **transparente** (solo bordes y reflejos; el fondo del espacio se ve a través), con **marco solo a los costados** (jambas de 5 px dentro del hueco). Arriba y abajo es todo vidrio, así al romperse queda el hueco libre para el tentáculo.

| Tag | Cuadros | Duración | Uso |
|---|---|---|---|
| `intact` | 1–8 | 150 ms, loop | Sano; un brillo cruza el vidrio cada tanto |
| `crack` | 9–10 | 50 ms | La punta del tentáculo toca el vidrio: telaraña de grietas |
| `shatter` | 11–14 | 50, 60, 70, 80 ms | El vidrio se desarma en pedazos que caen hacia adentro |
| `broken` | 15 | — | Quedan restos dentados en las jambas |

## Succión (`window_wind`)

- `assets/aseprite/environment/window/window_wind.aseprite` → `window_wind.png` (+ JSON): 4 cuadros de 96×112, 70 ms, loop, mismo origen que el ventanal.
- Líneas de aire que convergen hacia el hueco. Visible solo durante la descompresión: aparece con la rotura y se desvanece (alfa) cuando termina `pull_duration` o el jugador sale. Sin sombreado.

## Vidrios (`window_shards`)

- `window_shards.png`: 6 cuadros de 6×6. Textura de las partículas de vidrio (`_play_shards`), un cuadro al azar por partícula en lugar del cuadrado de color.

## Tentáculo

- **No hay arte nuevo:** se usa el `tentacle_front` aprobado (cualquier variante) **dado vuelta** (`flip_v`), por **detrás** del techo (el techo lo recorta y se lo ve pasar por el hueco), centrado en x del vidrio.
- Secuencia (reemplaza el `Polygon2D` violeta de `_play_tentacle`):
  1. Al disparar la rotura, el tentáculo baja desde arriba del techo reproduciendo `reach`.
  2. Cuando la punta llega al vidrio: ventanal `crack` → `shatter` → `broken`, sacudida de cámara, vidrios y empieza la succión.
  3. Ya adentro reproduce `grab` hacia el jugador (no lo alcanza; no tiene colisión).
  4. `retract` y sube hasta salir de cuadro; se libera el nodo.
- Duraciones en `@export` del `WindowBreach` (bajada, pausa del `grab`, subida); la succión no depende de que el tentáculo termine.
