# Mecánica: paredes pintadas con tiles

**Archivos:** escena `scenes/levels/Walls.tscn` (un `TileMapLayer`); TileSet `resources/tilesets/walls_tileset.tres`; imagen placeholder `assets/sprites/environment/placeholders/walls_placeholder.png`. Chequeo de límites en `scripts/levels/level_segment.gd` (`_get_child_rect`).

## Propósito

Pintar a mano, celda por celda, las partes del mapa que son pared, sin tener que armar cada pared como una `Platform`. Las plataformas siguen igual: las paredes son una herramienta aparte para dar forma al espacio (bordes, pasillos, esquinas).

## Modelo en palabras simples

- Cada segmento (`scenes/levels/segments/*.tscn`) tiene un hijo `Walls`: una instancia de `Walls.tscn`, vacía hasta que se pinta.
- La grilla es de **12×12 px** (30 columnas en los 360 px de ancho del segmento; 12 px es también el alto de las plataformas, así que las paredes alinean con ellas).
- Las paredes son **sólidas desde cualquier lado** y no matan: misma capa de colisión que las plataformas (capa 1 `world`), así que el jugador choca contra ellas sin cambiar nada en su código.
- Se dibujan **detrás** del resto (`z_index = -1`).
- `LevelSegment` avisa en el editor (icono de advertencia) si alguna celda pintada queda fuera del rectángulo del segmento (x 0..360, y −height..0).

## Tiles disponibles

| Tile | Atlas | Alternativa | Forma | Uso |
|---|---|---|---|---|
| Sólido | (0, 0) | 0 | Cuadrado completo | Pared |
| Diagonal | (1, 0) | 0 | Triángulo, mitad inferior izquierda llena | Esquina / rampa |
| Diagonal | (1, 0) | 1 | Mitad inferior derecha llena | Esquina / rampa |
| Diagonal | (1, 0) | 2 | Mitad superior izquierda llena | Esquina / techo |
| Diagonal | (1, 0) | 3 | Mitad superior derecha llena | Esquina / techo |

Cada orientación de la diagonal es una **alternativa** del mismo tile con su propio polígono de colisión, así que la colisión coincide siempre con lo que se ve (verificado con una prueba headless de las cuatro). Color placeholder: celeste `#3A9BBF`, el mismo que la plataforma `STATIC`.

## Cómo pintar

1. Abrir el segmento y seleccionar el nodo `Walls`.
2. En el panel inferior, pestaña **TileMap** → **Tiles**: elegir el tile (las cuatro diagonales aparecen como alternativas al lado del tile diagonal).
3. Pintar con clic izquierdo, borrar con clic derecho. Herramientas útiles: rectángulo (R), línea (L), relleno (B).
4. También se puede rotar o espejar al pintar (Z/X, C/V en el editor); la colisión acompaña la transformación.

## Cómo reemplazarlo por el tilemap real (etapa de arte)

- Todo vive en `walls_tileset.tres`: agregar el atlas del tileset final como una fuente nueva (o reemplazar la textura de la fuente 0 manteniendo las coordenadas de atlas) y dibujar los polígonos de colisión de cada tile en la capa de física 0.
- Si se reemplaza la fuente 0 conservando las coordenadas (0,0) y (1,0) y las alternativas 0–3, todo lo ya pintado en los segmentos pasa a verse con el arte nuevo sin tocar los segmentos.
- Para bordes automáticos se puede agregar un *terrain set* al TileSet más adelante.

## Parámetros

No hay valores de gameplay: el tamaño de tile (12 px) y la capa de colisión son estructurales y viven en el TileSet. Qué celdas son pared es diseño de nivel (por segmento).
