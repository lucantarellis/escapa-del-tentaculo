# Paredes de la nave (tilesets)

Arte cerrado el 18/11/2026. Editables en `assets/aseprite/environment/ship_walls/` (capas `color`, `normal` y, si corresponde, `emissive`). PNG exportados en `assets/sprites/environment/ship_walls/`. Tiles de 12 px, sin separación.

## Qué hay

| Set | Atlas | Modo de terreno | Contenido |
|---|---|---|---|
| `walls_ship` | 612×120 | esquinas y lados | 47 combinaciones + 4 diagonales (columnas 47–50). Filas = variantes: chapa lisa, con junta vertical, borde mordido ×2, remaches, grieta ×2, abolladura, rejilla, franja de peligro (solo con el borde de arriba expuesto). |
| `walls_ship_anim` | 96×84 | mismo terreno que `walls_ship` | 7 tiles animados de 8 frames (120 ms): rejilla con calor, panel de estado, alarma y alarma rota (borde de arriba y de abajo), cable con chispas (borde de abajo). |
| `dmg_hole` | 564×24 | esquinas y lados | Rotura: 47 combinaciones × 2 variantes. |
| `dmg_crack` | 96×384 | lados | Grieta incandescente: 16 × 2 variantes, animadas (8 frames). |
| `dmg_bile` | 96×1128 | esquinas y lados | Bilis: 47 × 2 variantes, animadas (gota que cae). |
| `dmg_patch` | 564×24 | esquinas y lados | Parche remachado: 47 × 2 variantes. |
| `det_pipe` | 192×24 | lados | Cañerías: 16 × 2 variantes. |
| `det_pipe_anim` | 96×24 | mismo terreno que `det_pipe` | Tramo horizontal con fuga de vapor, 2 variantes animadas. |

`ship_walls_layout.json` lista cada tile: posición en el atlas, bits de vecinos (`N, NE, E, SE, S, SW, W, NW` o solo lados), variante, probabilidad y, en los animados, frames y duración. Sirve para armar los `TileSet` por script sin cargar los bits a mano.

## TileSets de Godot (listos)

| Recurso | Uso |
|---|---|
| `resources/tilesets/walls_tileset_ship.tres` | Pared con colisión (capa física 1). Terreno `pared_nave` (esquinas y lados). Fuente 0: `walls_ship`; fuente 1: animados. |
| `resources/tilesets/ship_walls_overlay.tres` | Daño y detalle, sin colisión. Conjuntos de terreno: 0 `rotura`, 1 `grieta`, 2 `bilis`, 3 `parche`, 4 `caneria`. |
| `walls_tileset_ship_emissive.tres` / `ship_walls_overlay_emissive.tres` | Mismos ids de fuente y coordenadas, solo con lo que emite luz. Para la capa emisiva (ver abajo). |

Las texturas de los atlas son `CanvasTexture` (color + relieve), así que las luces 2D ya usan el relieve. Los tiles animados arrancan en un frame al azar.

### Cómo está armado en el juego

Los segmentos de la nave (`segments/ship/` y `segments/start/`) usan `scenes/levels/WallsShip.tscn` en lugar de `Walls.tscn`. Es un `TileMapLayer` llamado `Walls` (tileset `walls_tileset_ship.tres`, con colisión) con estos hijos:

| Nodo | Tileset | Para qué |
|---|---|---|
| `Emissive` | `walls_tileset_ship_emissive.tres` | Solo luz de la pared. Se llena solo; no pintar. |
| `Detalle` | `ship_walls_overlay.tres` | Parches y cañerías (sin colisión). |
| `Detalle/Emissive` | `ship_walls_overlay_emissive.tres` | Solo luz del detalle. No pintar. |
| `Dano` | `ship_walls_overlay.tres` | Roturas, grietas y bilis (sin colisión). |
| `Dano/Emissive` | `ship_walls_overlay_emissive.tres` | Solo luz del daño. No pintar. |

Las capas `Emissive` (script `scripts/levels/emissive_mirror.gd`) copian las celdas de la capa que tienen arriba y las dibujan con material sin sombreado. Las celdas copiadas no se guardan en la escena. Cada segmento migrado tiene `Walls` con "Editable Children" activado, así que `Detalle` y `Dano` se ven en el árbol.

`LevelBuilder` no cambia nada: el tier de la nave no define `walls_tileset`, y los tiers de espacio y alien siguen usando `Walls.tscn`.

### Cómo pintar un segmento a mano

1. Abrir el segmento. Seleccionar `Walls` y pintar la pared en la pestaña **Terrains** (conjunto 0, `pared_nave`) con el pincel o el rectángulo. Godot elige bordes, esquinas y variantes solo. Volver a pintar encima re-sortea las variantes.
2. **Diagonales:** no salen solas (probabilidad casi 0, porque comparten vecinos con las esquinas). Ponerlas a mano desde la pestaña **Tiles**, fuente 0, columnas 47–50 (◣ ◢ ◤ ◥), fila 0 o 1. Tienen colisión triangular.
3. **Daño y detalle:** seleccionar `Walls/Dano` o `Walls/Detalle` en el árbol (si no se ven, clic derecho en `Walls` → **Editable Children**). En el panel de TileMap, pestaña **Terrains**, elegir el conjunto (0 `rotura`, 1 `grieta`, 2 `bilis`, 3 `parche`, 4 `caneria`) y pintar. Pintar varias celdas juntas arma un agujero, mancha o caño continuo. Usar solo celdas que estén dentro de la pared, no en el borde. No pintar en los nodos `Emissive`.
4. Las alarmas, chispas, rejillas y paneles animados salen solos al pintar la pared (baja probabilidad). Para poner uno en un lugar puntual, pintarlo desde **Tiles**, fuente 1.

Los `.tres` se generan desde `ship_walls_layout.json` con un script de Godot que quedó fuera del repo; si cambia el arte, se regeneran desde el chat de arte.

## Cómo se arma en Godot

- **Capas (`TileMapLayer`)**, de atrás hacia adelante: pared (`walls_ship` + `walls_ship_anim`, con colisión), detalle (`dmg_patch`, `det_pipe`), daño (`dmg_hole`, `dmg_crack`, `dmg_bile`). Solo la pared tiene colisión: las capas de daño y detalle son visuales.
- Daño y detalle se pintan solo sobre celdas interiores de la pared. Pintar un grupo de celdas arma un agujero, grieta, mancha, parche o caño continuo; Godot elige la pieza según los vecinos. Las variantes con la misma combinación salen al azar según la probabilidad del JSON.
- **Diagonales:** colisión triangular como en el tileset actual; sus bits marcan como sólidos solo los catetos, así los tiles vecinos dibujan el borde donde está la hipotenusa.
- **Relieve:** `*_normal.png` en convención OpenGL (Y+ arriba). Usar `CanvasTexture` (difusa + normal) como textura del atlas; con `PointLight2D` y `CanvasModulate` oscuro la luz marca biseles, juntas, remaches y bordes de las roturas.
- **Emisivo:** `*_emissive.png` tiene solo los píxeles que emiten luz (alarmas, pantallas, rejillas, chispas, grietas, luz de la caja de cañerías). Falta en código: una capa duplicada por cada capa pintada, con el tileset `*_emissive.tres`, material sin sombreado (`CanvasItemMaterial` unshaded) y las mismas celdas que su capa original (copiar `tile_map_data` al cargar). Las fuentes sin píxeles emisivos no existen en esos tilesets y esas celdas se ignoran. Las válvulas de las cañerías son rojas pero no emiten.
- **Luces sugeridas:** una `PointLight2D` por grieta (naranja, suave), por alarma (roja, sigue el parpadeo) y la del astronauta. Iluminación general muy baja para que el jugador descubra la nave al subir.
- El fuego no va en las paredes: las paredes no dañan; el fuego queda en las plataformas letales y en el fondo.
