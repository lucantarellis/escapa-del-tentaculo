# Tier 2: el espacio

**Archivos:** segmentos en `scenes/levels/segments/space/` (`SegmentSpace01`–`10` y las entradas `SegmentSpaceEntry01`–`03`); evento `scripts/levels/tier_event.gd` (`TierEvent`); config del fuego `resources/configs/tentacle_config_fire.tres`; tileset `resources/tilesets/walls_tileset_space.tres` (imagen `assets/sprites/environment/placeholders/walls_placeholder_space.png`). Todo se asigna al tier 2 en `resources/configs/level_config.tres`.

## Historia

El jugador escapa de la nave al espacio y la nave explota detrás. Al entrar al tier se ve al alien huir hacia arriba a toda velocidad y, desde ahí, lo que persigue ya no es el tentáculo sino el **fuego** de la explosión.

## Qué cambia en este tier

| Qué | Cómo | Dónde se ajusta |
|---|---|---|
| Física | Gravedad casi nula y mucha inercia: `gravity_scale` 0,16 (≈ 40 px/s² con la gravedad actual de 250) y `air_drag_scale` 0,22 (≈ 20 px/s² de frenado en el aire, contra 90). Frenar también cuesta combustible | `level_config.tres` → Tiers → tier 2 → Jugador |
| Perseguidor | El fuego: arranca 150 px bajo la pantalla (`visible_height` −150) a 60 px/s, acelera 25 px/s² hasta 240 px/s. Color naranja rojizo `#FF5A28` | `tentacle_config_fire.tres` y `pursuer_color` del tier 2 |
| Paredes | Restos del casco: pocas, chicas y casi siempre flotando, en gris metálico | `walls_tileset_space.tres` (mismas coordenadas de atlas que el tileset de la nave) |
| Peligros | Escombros que se mueven (`moves`), metralla que sube desde abajo (`PROJECTILE` disparado al entrar en cámara, recorrido (0, −600), desaparece al final), metralla que rebota (`BOUNCE`), compuertas de fuego (`PULSE`) | Cada segmento |

Todos los valores son de prueba: el "se siente bien" de la física y del fuego es de LT.

## Transición (entrada del tier)

Cada `SegmentSpaceEntryNN` tiene un nodo **`TierEvent`** a 40 px del borde inferior (en el editor se ve como una línea naranja). Cuando el jugador lo cruza subiendo, sin perder el control:

1. sacude la cámara (`shake_amplitude` 18 px, `shake_duration` 0,9 s);
2. destello de pantalla completa (`flash_color`, `flash_alpha` 0,8, `flash_duration` 0,5 s);
3. la silueta del alien (placeholder violeta oscuro) cruza la pantalla hacia arriba por el fondo (`silhouette_delay` 0,25 s, `silhouette_duration` 1,1 s).

El cambio de física y de perseguidor no lo hace el evento: lo hace `LevelController` al cruzar el borde del tier (el borde inferior del segmento de entrada), así que coinciden. Los valores del evento son `@export` del nodo (inspector, por instancia). `TierEvent` sirve para cualquier tier: el tier 3 lo va a usar con otros valores.

## Cómo probarlo

1. F5 → JUGAR y subir hasta pasar los 5 segmentos de la nave: al entrar al espacio hay sacudida, destello y la silueta sube; el perseguidor pasa a ser naranja y el jugador flota.
2. Abrir un `SegmentSpaceNN` y ejecutarlo con F6 para verlo aislado (con la física normal: la del espacio se aplica solo dentro del nivel).
3. Ajustar `gravity_scale` / `air_drag_scale` del tier 2 y `tentacle_config_fire.tres` hasta que se sienta bien.
