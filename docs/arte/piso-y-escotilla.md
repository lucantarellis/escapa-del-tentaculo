# Piso del segmento de inicio y escotilla de la intro

## Piso (`floor_ship`)

- Editable: `assets/aseprite/environment/floor_ship/floor_ship.aseprite` (capas `normal` oculta, `color`, `emissive`).
- Hojas: `assets/sprites/environment/floor_ship/floor_ship.png`, `_normal.png`, `_emissive.png` + `floor_ship_layout.json`.
- **Vista 3/4:** cara superior de chapa (se ve desde arriba) y frente de la viga. Las plataformas siguen en 2D.
- Módulos de **20×27 px**, uno al lado del otro en una sola fila (módulo *i* en x = 20·i). Lista y uso en el JSON.
- **Colisión sin cambios** (banda de 360×20). El sprite empieza **7 px por encima** de la línea de colisión: el astronauta pisa la mitad de la cara superior. Ubicar cada módulo en `(x, -27)` respecto del borde inferior del piso (o `y = -20 - 7`).
- Armado sugerido para 360 px (18 módulos): relleno variado con `plain_a`/`plain_b`, una `joint` cada 3–5, alguna `rivet`/`vent`/`dent`, `hazard` justo a los lados de la escotilla (módulos 5 y 12 si está centrada) y `cable` de a 2 o más. Semilla estable por segmento para que no cambie en cada partida.
- **Si a futuro hay paredes a los costados:** `wall2d` debajo de la pared (bloque 2D con el estilo de las paredes) y `end_l`/`end_r` como remate entre la pared 2D y el piso 3/4. Hoy no se usan.
- Emisivo: solo el rojo tenue de las rejillas.

## Escotilla (`hatch`)

- Editable: `assets/aseprite/intro/hatch.aseprite` (capas `normal` oculta, `color`, `emissive`).
- Hojas verticales de **144×96** por cuadro: `assets/sprites/intro/hatch.png` (+ `hatch.json` con tags y duraciones), `hatch_normal.png`, `hatch_emissive.png`.
- **Origen:** el centro del borde superior del piso (línea de colisión) está en **(72, 64)** del cuadro. Con `centered = true`, `offset = (0, -16)`.
- Medidas respecto del origen: marco de x −64 a +64; cara superior del marco de y −15 a −2; frente del marco de −1 a +5. Hojas abiertas hasta y ≈ −62.
- Cambios para `hatch.gd`: `FRAME_TOP` pasa a **−15** (punto de salida del jugador). `FRAME_HALF_WIDTH` sigue en 64.

### Tags

| Tag | Cuadros | Duración | Uso |
|---|---|---|---|
| `closed` | 1–4 | 220 ms, loop | Cerrada; la rendija del centro respira en rojo muy tenue |
| `hit_1` | 5–7 | 60, 80, 120 ms | Golpe 1: impacto (destello, hojas saltan) y queda abombada |
| `idle_1` | 8–11 | 200 ms, loop | Estado tras el golpe 1 |
| `hit_2` / `idle_2` | 12–14 / 15–18 | igual | Golpe 2, más abombada y más luz |
| `hit_3` / `idle_3` | 19–21 / 22–25 | igual | Golpe 3 |
| `break` | 26–31 | 50, 50, 60, 70, 80, 100 ms (0,41 s) | Ruptura: destello, las hojas se abren con rebote |
| `broken` | 32–35 | 160 ms, loop | Rota: hueco rojo que respira |

- Golpe *k* (`hit()`): reproducir `hit_k` y al terminar `idle_k`. Si `hit_count` > 3, los golpes extra repiten `hit_3`.
- `break_open()`: reproducir `break`, emitir `break_finished` al terminar y pasar a `broken`. `set_broken(true)` va directo a `broken`; `set_broken(false)` a `closed`.
- Las hojas ya no se rotan por código: la sacudida (`_visual.position`), el gas y los fragmentos siguen en código.

### Capas en Godot

- `color` con relieve (`CanvasTexture` con `hatch_normal.png`).
- `emissive` encima, sin sombreado: rendija y hueco rojos, destello.
- La luz que se escapa (haz y halo aditivos y sin sombreado) la dibuja Godot desde el desgarro central (`Hatch._setup_light`); el arte ya no trae capa `glow`.
- La abolladura es un domo: reposo de 4, 8 y 12 px tras cada golpe; el desgarro en V crece con cada golpe.
- Un `PointLight2D` rojo (≈ `#CD1417`) debajo de la escotilla, con energía según el estado: casi nula cerrada, sube con cada golpe, pico en la ruptura y queda media cuando está rota. Así la luz también ilumina el astronauta, el piso y las paredes. Valores en `IntroConfig`.

## Fragmentos (`hatch_debris`)

- Editable: `assets/aseprite/intro/hatch_debris.aseprite`. Hoja `assets/sprites/intro/hatch_debris.png` (+ `_normal`): 6 cuadros de 12×12, uno por fragmento (dos con franja de peligro).
- El código los lanza y los rota como hoy (`DEBRIS_*`), eligiendo un cuadro al azar por fragmento. Reemplazan los cuadrados de `DEBRIS_SIZE`.

## Pendiente

- Gas de la escotilla: sigue con las partículas actuales; falta una textura chica de bocanada (ver lista de assets).
