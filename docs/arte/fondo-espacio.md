# Fondo del espacio (tier 2)

Arte cerrado el 24/11/2026. Reemplaza lo que hoy dibuja `LevelBackground` por código para el tier 2 (nebulosa, planeta, estrellas y frente desenfocado). Las estrellas fugaces siguen por código.

Es **el mismo cielo que se ve por los ventanales del hub** (`hub_space`): misma nebulosa, el mismo sol y el planeta del anillo, ahora visto más cerca. (El gigante naranja se descartó: competía en color con los asteroides.)

Todo el arte es **nítido**. El desenfoque, la luz y los destellos los pone Godot, salvo el destello del sol, que está dibujado. Editables en `assets/aseprite/environment/background_space/`; PNG y JSON en `assets/sprites/environment/background_space/`.

## Capas, de atrás hacia adelante

| # | Archivo | Tamaño | Animación | Paralaje | Desenfoque en Godot | Notas |
|---|---|---|---|---|---|---|
| 1 | `space_far_nebula` | 360×1200 | — | 0,06 | gaussiano ~1,2 px | Se repite en vertical sin costura. Solo nebulosa y fondo, sin estrellas. |
| 2 | `space_far_stars` | 360×1200 | — | 0,06 | **ninguno** | Estrellas, galaxia y sol de la misma franja, separados para que no se pierdan al desenfocar. Va exactamente alineada con la 1. |
| 3 | `space_planet_ringed` | 168×168 | `rotate`, 24 cuadros de 150 ms, bucle | 0,15 | ~0,6 px | Planeta del anillo (84 px sin el anillo); las bandas y una mancha clara avanzan con la rotación. |
| 4 | `space_stars_near` | 360×640 | `twinkle`, 8 cuadros de 150 ms, bucle | 0,3 | ninguno | Estrellas brillantes que titilan. Se repite en vertical. |
| — | (plano de juego) | | | 1 | ninguno | Jugador, asteroides, peligros: el plano de foco. |
| 5 | `space_front_rocks` | atlas 1500×750 | — | 1,4 | gaussiano fuerte, ~3,5 px | 50 piezas sueltas (slices `rock_01`–`rock_50`): rocas de todo tipo, astillas, grupos de fragmentos, cristales, hielo, chatarra (chapas, vigas, caños, panel solar). Delante del jugador (capa 5 de hoy). |

- **Planeta:** dentro de un tramo de 1600 px de la capa media que se repite, con su esquina superior izquierda en (220, 250): queda cortado por el borde derecho. Ajustable en el config.
- **Rocas del frente:** el código reparte piezas al azar solo en los costados (alternando izquierda y derecha, centradas cerca del borde, cada 140–280 px), sin repetir la misma pieza seguida. Respetar el `foreground_clear_radius` actual para no tapar el centro. Se pueden espejar horizontalmente para sumar variedad (no girar: ver "Giro").
- **Desenfoque:** shader de blur gaussiano por capa (por ejemplo un `CanvasLayer` por capa con un `ColorRect` + `BackBufferCopy`, o un shader en cada `Sprite2D`/`TextureRect`). Radios en `SpaceDecorConfig`, para ajustarlos sin tocar el arte.
- **Filtro nearest** en todas las texturas.

## Giro

Ninguna pieza de este fondo gira. Girar pixel art en el motor a ángulos que no son múltiplos de 90° rompe los contornos (filtro nearest) o mezcla colores fuera de paleta (filtro suave). Lo que tenga que girar (los asteroides del juego) se dibuja con cuadros pre-renderizados por ángulo: ver `docs/arte/asteroides.md`.
