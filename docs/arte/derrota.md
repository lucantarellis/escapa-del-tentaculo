# Pantalla de derrota

Arte cerrado el 24/11/2026. Reemplaza el texto de derrota de `LevelController` (`DEATH_TEXTS`). Es una pantalla completa de UI, con las piezas del mercado (`mk_*`) y la fuente Tiny5. No usa iluminación: no hay capas `normal` ni `emissive`.

## Viñetas

Una viñeta por causa de muerte, en un `.aseprite` por variante: `assets/aseprite/ui/death/death_<muerte>_<variante>.aseprite` → `assets/sprites/ui/death/death_<muerte>_<variante>.png` (tira horizontal) + `.json` (duración de cada cuadro y tags). Lienzo **172×98**. Se muestra **a 2×** (344×196) con filtro nearest: la viñeta funciona como una cámara con zoom, y el resto de la pantalla queda a 1×.

| Archivo | Muerte | Tags |
|---|---|---|
| `death_captured_a` | Tentáculo o caída | `play` 1–24 (90 ms, una vez) · `end` 25–32 (120 ms, bucle) |
| `death_electrocuted_a` | Plataforma de pulso o letal fija | `play` 1–22 (90 ms, una vez) · `end` 23–30 (120 ms, bucle) |

- `play`: la muerte, con la cámara en movimiento (paralaje, temblor, destellos). `end`: la imagen final de la muerte, con la cámara quieta y movimiento mínimo. El primer cuadro de `end` continúa el movimiento del último de `play` (no se repite ningún cuadro), así que el paso no se nota ni frena las partículas.
- **CAPTURADO:** el tentáculo lo agarra de las piernas, lo golpea dos veces contra la pared (el visor se raja), lo enrolla, lo aprieta y lo levanta. En `end` queda colgando del tentáculo, flojo, con el visor roto; el tentáculo se balancea y se escapa gas.
- **ELECTROCUTADO:** sube hacia el rayo, recibe la descarga (destellos y esqueleto en negativo) y le revienta el casco. En `end` queda quemado flotando frente a la plataforma, humeando; la plataforma chisporrotea cada tanto.
- **Variantes:** para sumar otra animación a una muerte, agregar `death_<muerte>_b` con los mismos tags. El código elige una variante al azar.

## Armado (360×640)

| Elemento | Posición | Detalle |
|---|---|---|
| Fondo | toda la pantalla | `#0E1632` |
| Título | centro (180, 90) | Tiny5 32 px, `#F62A19`, sombra 1 px `#050609`. `CAPTURADO` / `ELECTROCUTADO`. |
| Marco de la viñeta | (4, 116), 352×204 | `mk_panel_list` (9-slice) |
| Viñeta | (8, 120), escala 2 | `AnimatedSprite2D` o `TextureRect` con las animaciones `play` y `end` |
| "● REPETICIÓN" | punto (14, 126)–(19, 131); texto a la izquierda en (24, 129) | Tiny5 16 px, `#F62A19`, sombra `#050609` |
| Línea de humor | centro (180, 340) | Tiny5 16 px, `#C8E7EA`, sombra `#050609` |
| Panel de datos | (8, 360), 344×104 | `mk_panel_detail` |
| Progreso | etiqueta (24, 382) `#63D6C5`; valor a la derecha en (336, 382) `#E7EFF2` | Barra (24, 394)–(335, 400): fondo `#101134`, borde `#324370`, relleno `#3A9BBF` |
| Récord | etiqueta (24, 418); valor a la derecha en (336, 418) | "NUEVO RÉCORD" `#FCD51D` centrado en (180, 418) si corresponde |
| Monedas | etiqueta (24, 446); `hud_icon_coin` + "+N" `#F8B842` a la derecha en (336, 446) | Monedas ganadas en la partida |
| REINTENTAR | (8, 484), 344×38 | `mk_btn_primary`, texto `#FCD51D`. Foco por defecto (`mk_focus` en (7, 483), 346×40) |
| VOLVER AL HUB | (8, 530), 344×38 | `mk_btn_secondary`, texto `#3A9BBF` |
| Versión | derecha en (348, 628) | Tiny5 16 px, `#6689B7` |

## Comportamiento

1. Al morir: fundido de 0,3 s a la pantalla. La viñeta reproduce `play` una vez y después `end` en bucle.
2. Tocar la viñeta durante `play` la salta directo a `end`.
3. La línea de humor y el panel de datos aparecen (fundido de 0,2 s) cuando termina `play` o cuando se salta.
4. Los botones están activos desde el primer cuadro.

## Causas, títulos y líneas

Las líneas de humor van en código: una lista por muerte, y se elige una al azar cada vez. Se pueden sumar todas las que quieran.

| Causas (`Player.die`) | Título | Viñetas | Líneas |
|---|---|---|---|
| `tentacle`, `fell` | CAPTURADO | `death_captured_*` | "Tentáculo 1 · Vos 0", "Seguro sabés jugar" |
| `pulse`, `lethal` | ELECTROCUTADO | `death_electrocuted_*` | "Era de 220." |

- No hay pantalla genérica. Las causas de los tiers 2 y 3 todavía no tienen pantalla; hasta que la tengan, mantener el texto actual.
- La victoria queda pendiente: depende de la pelea con el jefe.
