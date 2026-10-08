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

Cada `SegmentSpaceEntryNN` empieza con el **casco exterior de la nave**: una franja de pared de lado a lado (y −36 a −72, con el tileset de la nave: las entradas conservan sus paredes) con una abertura en el centro (x ≈ 144–216) por donde sale el jugador. Justo encima (y −84) está el nodo **`TierEvent`** (en el editor, una línea naranja). Cuando el jugador lo cruza subiendo:

1. **Cámara lenta** un instante (`slow_motion_scale` 0,25 durante `slow_motion_duration` 0,35 s reales) y **destello** (`flash_alpha` 0,8, `flash_duration` 0,5 s).
2. **Explosión** desde el casco (`explosion_offset`): anillo naranja que se expande hasta `explosion_radius` 560 px en `explosion_duration` 0,8 s y `fire_particles` 70 partículas de fuego hacia arriba.
3. **Eyección:** el jugador recibe `eject_speed` 450 px/s hacia arriba y `eject_control_lock` 0,3 s sin control.
4. **Restos del casco letales** (`HullDebris`, `scripts/levels/hull_debris.gd`): `debris_count` 9 fragmentos rojos que aparecen a lo largo del casco (nunca a menos de `debris_min_player_distance` 70 px del jugador) y salen girando en direcciones al azar a 110–260 px/s. Durante `debris_grace_time` 0,25 s no matan; después, tocarlos mata con la causa `&"debris"`. Se borran al salir de la vista.
5. **Sacudida** fuerte (`shake_amplitude` 28 px, `shake_duration` 1,2 s) y la **silueta del alien** (escala 2, 0,8 s) huyendo hacia arriba por el fondo.

Al cruzar el borde del tier (el borde inferior de la entrada), `LevelController` cambia el **fondo** (del interior azul oscuro de la nave al negro del espacio con estrellas, fundido de 0,4 s; ver `LevelBackground`, `scripts/levels/level_background.gd`), el perseguidor (el fuego) y la física. Todos los valores del evento son `@export` del nodo `TierEvent` (inspector, por instancia); cada parte se apaga con su valor en 0 o su casilla. `TierEvent` sirve para cualquier tier.

## Cómo probarlo

1. F5 → JUGAR y subir hasta pasar los 5 segmentos de la nave: al entrar al espacio hay sacudida, destello y la silueta sube; el perseguidor pasa a ser naranja y el jugador flota.
2. Abrir un `SegmentSpaceNN` y ejecutarlo con F6 para verlo aislado (con la física normal: la del espacio se aplica solo dentro del nivel).
3. Ajustar `gravity_scale` / `air_drag_scale` del tier 2 y `tentacle_config_fire.tres` hasta que se sienta bien.
