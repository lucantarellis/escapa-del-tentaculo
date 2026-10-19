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

Paredes que escupen bilis, anticuerpos, cilios y tentáculos menores (ver `amenazas-alien.md`).

## Confinamiento y viñeta

Los 10 `SegmentAlienNN` son túneles continuos (ver "Paredes"). Se comprobó que en todos hay camino libre desde la entrada inferior hasta la salida superior y que todas las plataformas y tanques son alcanzables. El tier 3 tiene además una **viñeta** (`background_vignette` 0,6 en el tier): los bordes de la pantalla se oscurecen en rojo muy oscuro y laten despacio. Se configura por tier en `SegmentTier` (grupo "Fondo"); 0 = sin viñeta.

## Final: la abertura en el techo (`SegmentFinal01`, final de la partida)

El jefe (el cerebro con puntos débiles) **se eliminó**. El final es un segmento normal cuyo techo tiene una **abertura central** (x 144–216, arriba de la pantalla): al atravesarla el jugador gana ("ESCAPASTE"). `opens_top` apaga la pared superior de la cámara y una `Door` invisible (72 × 44 px) está justo encima del borde de la pantalla: se gana recién cuando el jugador sale entero. Usa el tileset del tier 3. No hay puerta visible; solo un haz de luz provisional (`OpeningLight`).

- Pendiente (ronda A, paso 6): que la salida sea lo único luminoso del tier, con una corriente de partículas y venas que laten hacia ella (sin flechas ni texto), y que el camino hasta ella sea **desafiante** (es el clímax) usando las amenazas nuevas del tier 3.
- Objetivo a futuro: 10 finales distintos. Por ahora hay 1.

## Cómo probarlo

1. F5 → JUGAR y llegar al tier 3 (o bajar `count_per_run` de los tiers 1 y 2 en `level_config.tres` para llegar antes): se entra por la piel, cambia el fondo y aparece el ácido.
2. Abrir un `SegmentAlienNN` o `SegmentFinal01` y ejecutarlo con F6 para verlo aislado.
3. En el final: subir hasta la abertura del techo y atravesarla; debe aparecer "ESCAPASTE".
