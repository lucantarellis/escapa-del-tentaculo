# Tier 3: dentro del alien

**Archivos:** segmentos en `scenes/levels/segments/alien/` (`SegmentAlien01`–`10` y las entradas `SegmentAlienEntry01`–`03`); finales con el jefe en `scenes/levels/segments/end/` (`SegmentBrain01`–`03`); scripts `scripts/boss/boss_brain.gd` (`BossBrain`) y `brain_node.gd` (`BrainNode`); config del ácido `resources/configs/tentacle_config_acid.tres`; tileset de carne `resources/tilesets/walls_tileset_alien.tres` (imagen `walls_placeholder_alien.png`). Todo se asigna en `resources/configs/level_config.tres` (tier 3 y `end_segments`).

## Historia

El alien estira una de sus extremidades para atrapar al jugador, pero este la atraviesa y queda **dentro de su carne**. Sube por los tejidos perseguido por el **ácido** hasta el **cerebro**, lo destruye y sale por el **ojo**.

## Transición (entrada del tier)

Cada `SegmentAlienEntryNN` empieza con la **piel de la extremidad**: una franja de carne de lado a lado (y −36 a −72) con una abertura central (x 144–216) por donde entra el jugador desde el espacio, y un pasillo libre encima (x 132–228 hasta y −280). Al cruzar el borde del tier cambian el fondo (rojo muy oscuro), la física (vuelve a la normal: el tier 3 no tiene multiplicadores) y el perseguidor, que aparece `pursuer_delay` 1 s después. Un `TierEvent` en y −90 marca la entrada: sacudida (14 px, 0,8 s), cámara lenta breve (0,4 durante 0,3 s) y destello violeta; sin explosión, restos ni eyección.

## Qué hay adentro

| Elemento | Qué es | Cómo está hecho |
|---|---|---|
| Paredes | Tejido: dominan la pantalla y forman pasillos que serpentean | Paredes (tiles) de carne `#6E2A3A`, unas 8 masas por segmento pegadas a los costados o flotando |
| Contracciones | El tejido se contrae: atravesable cuando está seguro, letal cuando se activa | `Platform` PULSE |
| Esfínteres | Se abren y se cierran | `Platform` TIMED |
| Membranas | Ceden al pisarlas | `Platform` BREAKABLE |
| Ácido y glóbulos | Charcos de ácido (fijos) y glóbulos que patrullan (móviles); tocarlos mata | `Platform` LETHAL (con `moves` los glóbulos) |
| Superficies | Tejido firme | `Platform` STATIC / ONE_WAY, teñidas de rosa carne (`platform_tint`) |

El color de lo letal sigue siendo rojo (convención). El perseguidor, el **ácido**, es verde amarillento `#B5D33A`: arranca 80 px bajo la pantalla a 50 px/s y acelera 6 px/s² hasta 150 px/s (más lento que el fuego: los pasillos son estrechos).

## Jefe: el cerebro (`SegmentBrainNN`, finales de la partida)

- **`BossBrain`**: el cerebro dibujado detrás (dos lóbulos) con 3 o 4 **puntos débiles** (`BrainNode`, hijos del nodo) que laten.
- **Se destruyen embistiéndolos con el dash.** Tocarlos sin dash no hace nada. Cada uno que cae sacude un poco la cámara.
- **El ojo** es la `Door` del segmento (`eye_path`): está cerrado (translúcido y sin detectar) hasta destruir el último punto débil. Entonces el cerebro muere (sacudida fuerte y se apaga) y el ojo se abre: tocarlo gana la partida ("ESCAPASTE").
- Alrededor hay contracciones, esfínteres y membranas para llegar a cada punto débil.

`end_segments` ahora sortea entre los 3 cerebros. Los 10 finales anteriores (`SegmentEnd01`–`10`) quedaron fuera del sorteo (sus archivos siguen en `segments/end/` hasta decidir si se borran o se reutilizan).

## Cómo probarlo

1. F5 → JUGAR y llegar al tier 3 (o bajar `count_per_run` de los tiers 1 y 2 en `level_config.tres` para llegar antes): se entra por la piel, cambia el fondo y aparece el ácido.
2. Abrir un `SegmentAlienNN` o `SegmentBrainNN` y ejecutarlo con F6 para verlo aislado.
3. En el cerebro: tocar un punto débil sin dash no hace nada; con dash se destruye; al caer el último se abre el ojo.
