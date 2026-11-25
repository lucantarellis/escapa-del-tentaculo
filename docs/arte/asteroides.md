# Asteroides (tier 2)

Arte cerrado el 24/11/2026. Reemplazan a los asteroides de tiles (`Asteroid`, una `TileMapLayer` con el tileset provisorio `walls_placeholder_space`). Editables en `assets/aseprite/environment/asteroids/`; PNG y JSON en `assets/sprites/environment/asteroids/`.

## Estilo

Roca partida y gastada, tallada en caras planas, con el mismo lenguaje que las paredes y plataformas de la nave: contorno negro de 1 px, colores planos, aristas con filo claro u oscuro, cráteres chicos tallados, alguna fractura y motas. Luz desde arriba a la izquierda. Rampa: `piedra_1` `#25162A`, `vino_oscuro` `#48151C`, `vino` `#71373C` y `roca_luz` `#8A5550` (color nuevo de la paleta, ver `assets/palette.md`).

## Archivos

10 variantes por tamaño (40 en total). Cada `.aseprite` tiene las capas `color` y `normal` (normal map en convención OpenGL, Y+ arriba). Exportados como `<nombre>.png` (color) y `<nombre>_normal.png`.

| Tamaño | Forma base | Archivos | Lienzo | Giro |
|---|---|---|---|---|
| Chico | 48×48 | `asteroid_small_01`–`10` | 70×70 | **Sí**: tag `spin`, 72 cuadros (cada 5°, en sentido antihorario), tira horizontal + `.json` |
| Mediano | 96×48 | `asteroid_medium_01`–`10` | 110×110 | **Sí**: igual que el chico |
| Grande | 120×72 | `asteroid_large_01`–`10` | 120×72 | No (un cuadro) |
| Gigante | 144×96 | `asteroid_giant_01`–`10` | 144×96 | No (un cuadro) |

- **Pivote:** el centro del lienzo es el centro del asteroide y el eje de giro.
- **Giro sin girar el sprite:** el nodo no se rota para el dibujo. Con `spin_speed` (°/s), el código lleva un ángulo acumulado y muestra el cuadro `round(ángulo / 5) mod 72` del tag `spin` (sentido: el cuadro N está girado N × 5° en sentido antihorario; para girar en sentido horario, recorrer los cuadros al revés). El normal map de cada cuadro ya viene girado, así que la luz no gira con la roca.
- **Colisión:** `asteroid_shapes.json` tiene, para cada nombre, el polígono del contorno sin girar (en px, con origen en el centro). Usar un `CollisionPolygon2D` con ese polígono; en los que giran, rotar solo la colisión (`rotation` del cuerpo) con el mismo ángulo que el cuadro mostrado (redondeado a 5°, para que coincida con el dibujo).
- **Cuerpo:** mantener el comportamiento actual (vaivén con `drift`, cuerpo cinemático para llevar al jugador parado encima).
- Mostrar con filtro nearest y con `CanvasTexture` (color + normal), como las plataformas de la nave.

## En los segmentos

Hoy cada asteroide es una capa de tiles pintada a mano. Hay que reemplazar cada uno por la variante del tamaño más parecido (chico, mediano, grande o gigante), elegida al azar con semilla estable por segmento, conservando su posición, `drift`, `drift_period`, `drift_offset` y `spin_speed`. Los grandes y gigantes no giran: si alguno tiene `spin_speed` distinto de 0, pasarlo a 0.
