# Tier 3: dentro del alien

**Archivos:** segmentos en `scenes/levels/segments/alien/` (`SegmentAlien01`–`10` y las entradas `SegmentAlienEntry01`–`03`); final en `scenes/levels/segments/end/` (`SegmentFinal01`); config del ácido `resources/configs/tentacle_config_acid.tres`; tileset de carne `resources/tilesets/walls_tileset_alien.tres` (imagen `walls_placeholder_alien.png`). Todo se asigna en `resources/configs/level_config.tres` (tier 3 y `end_segments`).

## Historia

El alien estira una de sus extremidades para atrapar al jugador, pero este la atraviesa y queda **dentro de su carne**. Sube por los tejidos perseguido por el **ácido** hasta una **abertura** por la que sale.

## Transición (entrada del tier)

Cada `SegmentAlienEntryNN` empieza con la **piel de la extremidad**: una franja de carne de lado a lado (y −36 a −72) con una abertura central (x 144–216) por donde entra el jugador desde el espacio, y un pasillo libre encima (x 132–228 hasta y −280). Al cruzar el borde del tier cambian el fondo (rojo muy oscuro), la física (vuelve a la normal: el tier 3 no tiene multiplicadores) y el perseguidor, que aparece `pursuer_delay` 1 s después. Un `TierEvent` en y −90 marca la entrada: sacudida (14 px, 0,8 s), cámara lenta breve (0,4 durante 0,3 s) y destello violeta; sin explosión, restos ni eyección.

## Qué hay adentro

| Elemento | Qué es | Cómo está hecho |
|---|---|---|
| Paredes | Un solo macizo de tejido, sin masas sueltas, con un **túnel continuo** que serpentea de abajo (centro) a arriba (centro) y se ensancha en cámaras alrededor de las plataformas y tanques. Libre ≈ 50–60 % de la pantalla; ancho del túnel ≈ 136–148 px | Paredes (tiles) de carne `#6E2A3A`, generadas con un script a partir de la posición de las plataformas (las uniones entre segmentos son siempre en x = 180) |
| Contracciones | El tejido se contrae: atravesable cuando está seguro, letal cuando se activa | `Platform` PULSE |
| Esfínteres | Se abren y se cierran | `Platform` TIMED |
| Membranas | Ceden al pisarlas | `Platform` BREAKABLE |
| Ácido y glóbulos | Charcos de ácido (fijos) y glóbulos que patrullan (móviles); tocarlos mata | `Platform` LETHAL (con `moves` los glóbulos) |
| Superficies | Tejido firme | `Platform` STATIC / ONE_WAY, teñidas de rosa carne (`platform_tint`) |

El color de lo letal sigue siendo rojo (convención). El perseguidor, el **ácido**, es verde amarillento `#B5D33A`: arranca 80 px bajo la pantalla a 50 px/s y acelera 6 px/s² hasta 150 px/s (más lento que el fuego: los pasillos son estrechos).

## Amenazas propias del tier

Paredes que escupen bilis, anticuerpos y tentáculos menores (ver `amenazas-alien.md`).

## Confinamiento y viñeta

Los 10 `SegmentAlienNN` son túneles continuos (ver "Paredes"). Se comprobó que en todos hay camino libre desde la entrada inferior hasta la salida superior y que todas las plataformas y tanques son alcanzables. El tier 3 tiene además una **viñeta** (`background_vignette` 0,6 en el tier): los bordes de la pantalla se oscurecen en rojo muy oscuro y laten despacio. Se configura por tier en `SegmentTier` (grupo "Fondo"); 0 = sin viñeta.

## Final: la abertura en el techo (`SegmentFinal01`, final de la partida)

El jefe (el cerebro con puntos débiles) **se eliminó**. El final es un túnel como los otros, pero que se cierra en **embudo** hacia una **abertura** central en el techo (x 144–216, 72 px): al atravesarla el jugador gana ("ESCAPASTE"). `opens_top` apaga la pared superior de la cámara y una `Door` invisible (72 × 44 px) está justo encima del borde de la pantalla: se gana recién cuando el jugador sale entero. Usa el tileset del tier 3. No hay puerta visible.

**Recorrido (de abajo hacia arriba):** es el clímax y usa las amenazas del tier.

| Zona | Altura (y) | Qué hay |
|---|---|---|
| Entrada | −40 a −260 | Dos tentáculos menores en paredes opuestas, desfasados (0,5 s y 1,9 s), más una plataforma de contracción |
| Cruce | −280 a −450 | Dos paredes de bilis enfrentadas (a distinta altura) y un tanque de combustible sobre una plataforma de un solo sentido |
| Embudo | −460 a −640 | Un anticuerpo patrullando, un tanque, una pared de bilis y un tentáculo menor justo antes de la boca |

**La salida es lo único luminoso del tier** (`ExitBeacon`, sin flechas ni texto): un haz de luz blanco-celeste que baja desde la abertura y late con la viñeta (`OpeningLight`), motas de luz que suben por el haz y se escapan por la abertura, y venas finas sobre la pared, pegadas al borde del túnel y convergiendo hacia la abertura, con un pulso de luz que corre hacia arriba. Las venas se calculan a partir de las celdas de la capa `Walls` del segmento. Solo se dibuja con el tramo a la vista.

| Propiedad de `ExitBeacon` | Defecto | Descripción |
|---|---|---|
| `light_color` | `#C8E7EA` | Color de la luz |
| `opening_left` / `opening_right` | 144 / 216 | Borde de la abertura. Unidad: px |
| `particle_count` / `particle_start_y` / `particle_speed` | 26 / −300 / 38 | Motas: cantidad, altura de inicio (y local) y velocidad (px/s) |
| `vein_start_y` / `pulse_speed` / `vein_alpha` | −260 / 150 / 0,16 | Venas: altura de inicio, velocidad del pulso (px/s) y opacidad en reposo |

- Pendiente: afinar el anticuerpo (ver `amenazas-alien.md`) y la dificultad del final tras probarlo.
- Objetivo a futuro: 10 finales distintos. Por ahora hay 1.

## Cómo probarlo

1. F5 → JUGAR y llegar al tier 3 (o bajar `count_per_run` de los tiers 1 y 2 en `level_config.tres` para llegar antes): se entra por la piel, cambia el fondo y aparece el ácido.
2. Abrir un `SegmentAlienNN` o `SegmentFinal01` y ejecutarlo con F6 para verlo aislado.
3. En el final: subir hasta la abertura del techo y atravesarla; debe aparecer "ESCAPASTE".
