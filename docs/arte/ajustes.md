# Ajustes y créditos

Pantallas **completas de UI** (sin ilustración), con las piezas del mercado (`docs/arte/mercado.md`, `assets/sprites/ui/market/mk_*`) más las piezas nuevas de este documento. Fondo `#0E1632`. Texto Tiny5 16 px con sombra 1 px `#050609`.

## Piezas nuevas
Editable: `assets/aseprite/ui/settings/settings_ui.aseprite` (atlas con un slice por pieza y su centro 9-slice). Exportadas en `assets/sprites/ui/settings/`.

| Pieza | Tamaño | 9-slice (izq, arriba, der, abajo) | Uso |
|---|---|---|---|
| `st_slider_track` | 12×7 | 3,3,3,3 | fondo de la barra deslizante |
| `st_slider_fill` | 12×7 | 3,3,3,3 | relleno (ancho = valor) |
| `st_slider_knob` | 9×11 | — | perilla, centrada en el borde del relleno |
| `st_toggle_on` / `st_toggle_off` | 28×14 | — | interruptor |
| `st_btn_danger` | 12×12 | 3,3,3,3 | botón rojo (Borrar progreso / Borrar) |
| `st_arrow_left` / `st_arrow_right` | 4×7 | — | selector de idioma; `arrow_right` también en filas que abren otra pantalla |
| `st_icon_sound` / `_game` / `_info` / `_data` | 16×16 | — | íconos de los subencabezados |
| `st_icon_gear` | 16×16 | — | ícono del título "AJUSTES" |

## Pantalla de ajustes (360×640)
- Título: `st_icon_gear` en (12, 12) + "AJUSTES" `#89D9EB` (36, centro y 20).
- Panel `mk_panel_list` (8, 44, 344×348). Dentro, subencabezados como en el mercado (ícono en x 15, título `#63D6C5` en x 36, línea `#3A9BBF`) y filas `mk_row_buy` de 27 px cada 31 px (x 14–344):
  - **SONIDO** (`st_icon_sound`): **Música** y **Efectos**: barra de x 150 a x 300 (alto 7, en y+10), perilla, valor "NN%" alineado a la derecha en x 336.
  - **JUEGO** (`st_icon_game`): **Vibración** (interruptor en x 308, y+7); **Idioma** ("‹ Español ›": flechas en x 220 y x 316, valor centrado en x 270; izquierda/derecha cambian).
  - **INFO** (`st_icon_info`): **Créditos ›** (abre la pantalla de créditos) y **VER CONTROLES ›** (misma fila, con la flecha `st_arrow_right`; repite las pistas del hub; brief 11).
  - **DATOS** (`st_icon_data`): **Borrar progreso** (`st_btn_danger`, texto `#F62A19` centrado).
- **Volver** `mk_btn_secondary` (8, 401, 120×30). Versión del juego abajo a la derecha (`#6689B7`).
- Foco con `mk_focus` (1 px por fuera de la fila). Navegable con teclado/joystick y táctil.

## Confirmación de borrar progreso
Capa oscura (`#050609` al ~70 %) sobre la pantalla, `mk_panel_detail` (24, 220, 312×150): "¿Borrar progreso?" `#E7EFF2`, "Se pierden monedas / y mejoras." `#C8E7EA`; botones **Cancelar** (`mk_btn_secondary`, foco por defecto) y **Borrar** (`st_btn_danger`).

## Pantalla de créditos
Mismo armado: título con `st_icon_info` + "CRÉDITOS", panel con texto centrado (nombre del juego `#E7EFF2`; rubros `#63D6C5`; nombres `#C8E7EA`), **Volver** abajo. Contenido a definir por LT; **Tiny5 (SIL OFL) tiene que figurar** (lo pide su licencia) y "Hecho con Godot".
