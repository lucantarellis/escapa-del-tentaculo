# HUD — "pantalla del traje"

Lecturas cian tipo display del traje, sobre la oscuridad. Mismo layout y tamaños que el HUD actual (`scenes/ui/Hud.tscn`, `scripts/ui/hud.gd`): combustible vertical a la izquierda, progreso vertical a la derecha, monedas y vida arriba a la izquierda, opacidad general 0,7–0,85. Todo a 1×.

## Archivos

Editables en `assets/aseprite/ui/hud/`; PNG en `assets/sprites/ui/hud/`.

| Editable | PNG | Tamaño | Uso |
|---|---|---|---|
| `hud_fuel.aseprite` (capas `under`, `progress`, `progress_empty`, `over`) | `hud_fuel_under.png`, `hud_fuel_progress.png`, `hud_fuel_progress_empty.png`, `hud_fuel_over.png` | 11×206 | `TextureProgressBar` vertical (`FILL_BOTTOM_TO_TOP`). `progress` naranja; con el tanque vacío usar `progress_empty` (rojo) |
| `hud_progress.aseprite` (capas `under`, `danger`, `over`) | `hud_progress_under.png`, `hud_progress_danger.png`, `hud_progress_over.png` | 11×206 | Barra de progreso. `danger` es el relleno rojo hasta el tentáculo (segundo `TextureProgressBar`, misma posición) |
| `hud_dash.aseprite` (capas `under`, `progress`) | `hud_dash_under.png`, `hud_dash_progress.png` | 18×5 | Enfriamiento del dash, sobre el personaje (reemplaza el dibujo de `DashCooldownBar`); `FILL_LEFT_TO_RIGHT` |
| `hud_icons.aseprite` (un cuadro por ícono, tag = nombre) | `hud_icon_<nombre>.png` (recortados) | ver abajo | Íconos sueltos (`TextureRect`) |

- Área útil de las barras: **x 3–7, y 3–202** dentro de los 11×206 (5×200, igual que hoy). `TextureProgressBar.texture_progress_offset` = (0, 0): las tres capas comparten lienzo.
- El relleno ya viene en segmentos (1 px de separación cada 5 px).

## Íconos

| Nombre | Tamaño | Dónde |
|---|---|---|
| `coin` | 18×18 | Arriba a la izquierda (x 6, y 6); número al lado (x 27, y 12) |
| `cell_full` / `cell_empty` | 11×8 | Celdas de integridad (vida), debajo de la moneda (y 28), cada 13 px; una por punto de golpe máximo |
| `shield` | 11×12 | A continuación de las celdas (+2 px), solo con el escudo activo |
| `fuel` | 12×16 | Debajo de la barra de combustible (centrado, 3 px abajo) |
| `goal` | 13×9 | Arriba de la barra de progreso (3 px arriba) |
| `player` | 11×14 | A la izquierda de la barra de progreso, centrado en la altura del jugador |
| `skull` | 11×10 | A la izquierda de la barra de progreso, centrado en el borde superior del relleno rojo (tentáculo) |
| `record` | 10×12 | A la izquierda de la barra de progreso, centrado en el récord |

## Líneas (las dibuja el código, 1 px)

Cruzan la barra de progreso de lado a lado (desde 3 px a la izquierda de la barra hasta su borde derecho) a la altura de cada marcador:
- Jugador: `#E7EFF2` (continua).
- Récord: `#63D6C5` punteada (1 px sí, 1 no).
- Tentáculo: `#F62A19` (continua), en el borde superior del relleno rojo.
- Tiers: `#C8E7EA`, dentro de la barra + 2 px afuera a la derecha, en cada Y de `set_tier_marks` (cualquier cantidad de tiers; sin tiers no hay marcas).

## Comportamiento

- Combustible: vacío → `progress_empty`; con poco combustible (≤ 25 %) se puede hacer parpadear el `over` (opcional).
- Vida: al perder una celda, que parpadee 2–3 veces antes de quedar vacía (código). Las celdas se ven siempre que haya más de 1 punto de golpe máximo (regla actual).
- Monedas: número con **Tiny5** (`assets/fonts/Tiny5-Regular.ttf`, licencia SIL OFL en `assets/fonts/Tiny5-OFL.txt`) a **16 px** (mínimo del juego), color `#89D9EB`, sombra 1 px `#050609`. Tamaños de fuente siempre múltiplos de 8 para que quede nítida.
- Opacidad general como hoy (`HUD_ALPHA`).
