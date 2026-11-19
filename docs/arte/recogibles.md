# Recogibles

Seis recogibles, un `.aseprite` por ítem. Todos tienen un aura cian: una línea a 2 px del contorno (1 px de separación y después la línea) que respira en loop.

## Archivos

| Ítem | Editable | Hoja | Cuadro | Ítem dentro del cuadro | Colisión actual |
|---|---|---|---|---|---|
| Tanque (tambor 200 L) | `assets/aseprite/pickups/pickup_tank.aseprite` | `assets/sprites/pickups/pickup_tank*.png` | 38×38 | 12×16 | rect 12×16 |
| Moneda (ficha) | `pickup_coin.aseprite` | `pickup_coin*.png` | 38×38 | 16×16 | radio 8 |
| Impulso | `pickup_boost.aseprite` | `pickup_boost*.png` | 42×42 | 20×20 | radio 10 |
| Llave (+1) | `pickup_wrench.aseprite` | `pickup_wrench*.png` | 44×44 | 22×22 | radio 11 |
| Cinta (+2) | `pickup_tape.aseprite` | `pickup_tape*.png` | 44×44 | 22×22 | radio 11 |
| Caja + escudo (todo + escudo) | `pickup_toolbox.aseprite` | `pickup_toolbox*.png` | 44×44 | 22×22 | radio 11 |

- El cuadro es más grande que el ítem porque el destello de recolección se expande. **El ítem está centrado en el cuadro**: con `centered = true` el pivote coincide con el centro de la colisión y no hace falta offset. Las colisiones no cambian.
- La cinta tiene una tira suelta que se sale un poco por abajo del círculo de colisión. Es solo visual.
- Los colores de la llave, la cinta y la caja ya no se dibujan con polígonos en `repairer.gd`: cada tipo usa su hoja.

## Capas y hojas

Cada `.aseprite` tiene tres capas, exportadas como hojas verticales (una columna, un frame por fila):

- `color` → `pickup_<n>.png` + `pickup_<n>.json` (frames, duraciones y tags). Es el ítem.
- `aura` → `pickup_<n>_aura.png`. Va **detrás** del ítem, sin luz (`CanvasItemMaterial` unshaded) para que se vea en la oscuridad.
- `emissive` → `pickup_<n>_emissive.png`. Las partes cian del ítem (etiqueta, logo, escudo, flecha). Va **encima**, unshaded, igual que en paredes y plataformas.

## Tags

| Tag | Frames | Duración | Loop | Uso |
|---|---|---|---|---|
| `idle` | 1–8 | 120 ms | sí | En reposo. Incluye el giro de la ficha, el brillo diagonal del metal y la respiración del aura. El balanceo vertical lo sigue haciendo el código (`bob_amplitude`/`bob_frequency`). |
| `collect` | 9–16 | 50 ms (400 ms total) | no | Al recoger: destello blanco, anillo cian con chispas que se expande y se desvanece a cero. En estos frames la capa `aura` está vacía y `emissive` es igual a `color` (todo el efecto es luz). |

Al recoger: desactivar la colisión, frenar el balanceo, reproducir `collect` y liberar el nodo al terminar (`animation_finished`), en vez de ocultarlo en el acto.

Opcional: un `PointLight2D` cian chico y tenue en cada recogible ayuda a que se lean de lejos; durante `collect` se puede subir la energía y apagarla al terminar.

## Si editás un ítem en Aseprite

1. Dibujá en `color`. Si tocás partes cian, copialas también a `emissive`.
2. Si cambia la silueta, el aura hay que rehacerla (2 px del contorno): pedile a Claude que la regenere, o redibujala a mano en la capa `aura`.
3. Exportá con File > Export Sprite Sheet: Vertical, una capa por vez, mismo nombre de archivo. El JSON solo hace falta para `color`.
