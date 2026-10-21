# Tier 2: el espacio

**Archivos:** segmentos en `scenes/levels/segments/space/` (`SegmentSpace01`–`10` y las entradas `SegmentSpaceEntry01`–`03`) y salidas de la nave en `scenes/levels/segments/ship/` (`SegmentShipExit01`–`03`); scripts `scripts/levels/window_breach.gd` (`WindowBreach`), `tier_event.gd` (`TierEvent`), `hull_debris.gd` (`HullDebris`) y `level_background.gd` (`LevelBackground`); config del fuego `resources/configs/tentacle_config_fire.tres`; tileset de roca `resources/tilesets/walls_tileset_space.tres` (imagen `assets/sprites/environment/placeholders/walls_placeholder_space.png`). Todo se asigna en `resources/configs/level_config.tres`.

## Historia

Al final de la nave, el alien rompe un ventanal del techo con un tentáculo. La descompresión arrastra al jugador afuera. Ya en el espacio, un instante después, la nave explota abajo: restos en llamas salen despedidos y el **fuego** de la explosión pasa a ser lo que persigue al jugador. El alien huye hacia arriba.

## Secuencia de la transición

1. **Salida de la nave (`SegmentShipExitNN`, último segmento del tier 1, `exit_segments`).** Arriba hay un techo de lado a lado con un hueco central (x 144–216) cerrado por un **vidrio** (`WindowBreach`, en y −582). Bajo el hueco queda un pasillo libre (x 132–228, y −300 a −564). Cuando el jugador llega a `trigger_distance` (260 px) bajo el vidrio, un tentáculo violeta lo rompe desde afuera (sacudida 14 px / 0,6 s y vidrios) y empieza la **descompresión**: el aire lo arrastra hacia el hueco (`pull_acceleration` 1500 px/s², hasta `pull_max_speed` 560 px/s, dentro de `pull_radius` 480 px, como mucho `pull_duration` 3 s). El jugador no pierde el control. Medido sin tocar nada: sale por el hueco en ~0,7 s y su impulso lo lleva más de 300 px dentro del espacio.
2. **Entrada al espacio (`SegmentSpaceEntryNN`, `entry_segments` del tier 2).** Al cruzar su borde, `LevelController` cambia el fondo (negro con estrellas), la física y el perseguidor, que aparece recién `pursuer_delay` (1,5 s) después. Toda la entrada tiene un **pasillo libre (x 110–250)** de punta a punta: solo asteroides a los costados.
3. **Las explosiones (`TierEvent`, en y −260 de la entrada).** Al cruzarlo, tras `explosion_delay` (0,5 s), la nave estalla en cadena: `explosion_waves` 3 explosiones separadas `explosion_wave_interval` 2,2 s. La primera, desde la nave abajo (`explosion_offset` (180, 360)), trae cámara lenta (0,25 durante 0,35 s), destello, un empujón (`eject_speed` 220 px/s) y la silueta del alien huyendo; las siguientes salen desde debajo de la pantalla, con la **misma sacudida** (`wave_shake_scale` y `wave_shake_duration_scale` = 1) y su anillo de fuego. **Aviso previo:** `warning_time` (0,7 s) antes de cada explosión el borde inferior de la pantalla parpadea en naranja (`warning_blinks` 3) y la cámara tiembla apenas (`warning_shake_amplitude` 3 px); antes de la primera dura lo que falte de `explosion_delay` (0,5 s). La señal `warning_started(lead)` queda lista para el sonido de aviso (pendiente: paso de audio). Cada una lanza `debris_count` 8 **restos letales** (`HullDebris`) que entran por el borde inferior a 220–380 px/s y salen **en direcciones al azar** hacia arriba (`debris_aim_at_player` = false, abanico de ±`debris_random_angle` 55°; con `debris_aim_at_player` = true apuntarían hacia adelante del jugador, `debris_lead` 0,5 s, ±30° de desvío); miden 18 px, nunca aparecen a menos de 60 px del jugador en horizontal y no matan los primeros 0,25 s. **Si chocan con algo sólido** (asteroides, paredes, restos metálicos) **se rompen**. Causa de muerte `&"debris"`.

Cada parte se ajusta con los `@export` de `WindowBreach` y de `TierEvent` en cada segmento (inspector).

## Qué hay en el espacio

| Elemento | Qué es | Cómo está hecho |
|---|---|---|
| Superficies | **Asteroides** de roca de 4 tamaños (chico 48 × 48 px, mediano 96 × 48, grande 120 × 72 y gigante 144 × 96, este último solo en `SegmentSpace05`) y formas irregulares; flotan (van y vienen) y algunos giran; donde parar y recargar. Cada segmento mezcla tamaños (`SegmentSpace04` y `09` tienen solo chicos: su espacio libre es justo) | Nodos `Asteroid` (`scripts/levels/asteroid.gd`): una capa de tiles por asteroide con `drift` (vaivén, 8–18 px), `drift_period` (3–6 s) y `spin_speed` (°/s; 0 en los grandes y en ~40 % de los chicos, si no 6–14 °/s). Usan cuerpos cinemáticos, así que te llevan si estás parado encima. Tileset de roca `#7A6A5A` |
| Impulsos | Flechas cian: al tocarlas, 1 s de propulsión y velocidad máxima ×1,8; en el espacio casi no se frena, así que la velocidad ganada se conserva | `SpeedBoost` (`scenes/pickups/SpeedBoost.tscn`, config `speed_boost_config.tres`: `duration`, `multiplier`, `fuel_amount`). 2 por segmento del espacio y por entrada |
| Restos a la deriva | Chapas de la nave que se mueven despacio y se pueden pisar | `Platform` STATIC con `moves`, teñidas de gris metálico (`platform_tint` del tier) |
| Meteoros y cometas | Cruzan la pantalla avisando antes (marca en el borde; el cometa, además, la línea de su recorrido); tocarlos mata. El meteoro se rompe contra los asteroides | `SpaceProjectile` (`Meteor.tscn`, `Comet.tscn`). Ver `obstaculos-espacio.md` |
| Campo de escombros | Trozos que orbitan un punto; tocarlos mata | `DebrisField`. Ver `obstaculos-espacio.md` |
| Satélite láser | Apunta, fija y dispara un haz; solo mata al disparar | `SatelliteLaser`. Ver `obstaculos-espacio.md` |
| Tanques | Cápsulas de la nave flotando sobre los asteroides | `FuelTank` |

PULSE, TIMED y BREAKABLE no aparecen en el espacio (son mecanismos de la nave).

## Física y perseguidor

| Qué | Valor | Dónde |
|---|---|---|
| Gravedad | `gravity_scale` 0,16 (≈ 40 px/s²) | Tier 2 → Jugador |
| Frenado en el aire | `air_drag_scale` 0,05 (≈ 4,5 px/s²): casi no se frena solo (de 200 px/s queda 195 tras 1 s) | Tier 2 → Jugador |
| Frenar propulsando | `counter_thrust_scale` 0,45: frenar de 250 px/s a 0 tarda 0,88 s y gasta el doble de combustible que en la nave (0,40 s) | Tier 2 → Jugador |
| Fuego | Arranca 150 px bajo la pantalla a 60 px/s y acelera 25 px/s² hasta 280 px/s (cada vez más rápido: los impulsos permiten sacarle ventaja); aparece 1,5 s después de entrar | `tentacle_config_fire.tres`, `pursuer_delay` |

El tier 2 usa **5 segmentos por partida** (`count_per_run`, igual que los otros tiers; se probó con 8 y LT lo dejó en 5).

Todos los valores son de prueba: el "se siente bien" es de LT.

## Cómo probarlo

1. F5 → JUGAR y subir hasta la salida de la nave: el alien rompe el ventanal, la descompresión te saca, la nave explota abajo, aparecen los restos y, un poco después, el fuego.
2. Abrir un `SegmentSpaceNN` y ejecutarlo con F6 para verlo aislado (con la física normal: la del espacio se aplica solo dentro del nivel).
3. Ajustar `gravity_scale` / `air_drag_scale` del tier 2 y `tentacle_config_fire.tres` hasta que se sienta bien.

## Decorado de fondo

Dibujado por `LevelBackground` (con las estrellas del tier) y parametrizado en `SpaceDecorConfig` (se asigna en la propiedad `decor` del nodo `Background`; vacío = valores por defecto). Es solo visual, sin colisión.

| Capa | Parallax | Descripción |
|---|---|---|
| Nebulosa | 0,05 | 3 manchas suaves de poca opacidad |
| Planeta lejano | 0,10 | Planeta con anillo; reaparece cada `planet_loop` px |
| Estrellas lejanas / cercanas | 0,08 / 0,25 | Las cercanas titilan |
| Estrella fugaz | — | Cada 6–10 s, en los costados y muy tenue |
| Frente desenfocado | 1,4 | Rocas y chatarra borrosas (capa 5, delante del jugador); solo se ven hacia los costados y se apagan hacia el centro (`foreground_clear_radius`) para no tapar el juego |

## Salida del tier: el tentáculo del alien (`SegmentSpaceExit01`)

Último segmento del espacio (`exit_segments` del tier 2; por ahora 1 variante, el objetivo son 10). La transición al tier 3 es **entrar rompiendo la carne de un tentáculo del alien**.

- **Cuerpo:** la capa `Limb` (carne, con el tileset del tier 3 vía el grupo `keep_tileset`, que `LevelBuilder` respeta) forma el cuerpo del tentáculo en **embudo**: abierto de lado a lado abajo y cerrándose hacia arriba. La punta es la membrana.
- **Anticipo:** a 1100 px antes de la membrana, un tentáculo gigante (dibujado con polígonos, sin colisión ni daño, detrás del jugador) entra por un costado (**izquierda o derecha, sorteado por partida**), sube más rápido que la cámara, se adelanta al jugador y se posa sobre la membrana.
- **Membrana (`FleshMembrane`, y= −540):** domo de carne que late, con venas. Tocarla basta para romperla (sin habilidad extra): instante congelado de 0,06 s, cámara lenta (0,3 durante 0,3 s), sacudida de 16 px por 0,6 s, destello rojizo, cuatro colgajos que salen despedidos y 28 trozos de carne. El jugador conserva su velocidad y sigue hacia la piel del tier 3 (`SegmentAlienEntryNN`), donde cambian el fondo, la física y el perseguidor.
- **Ganchos de sonido:** señales `membrane_hit` (golpe) y `broken` (desgarro) para el paso de audio.
- Un `TierEvent` en y −110 avisa con un temblor (1,6 s, 8 px) y una franja violeta-rojiza; sin explosión ni restos. Hay 2 tanques de combustible.

| Propiedad de `FleshMembrane` | Defecto | Descripción |
|---|---|---|
| `approach_distance` | 1100 | Distancia desde la que entra el tentáculo. Unidad: px |
| `random_side` / `side` | true / 1 | Sorteo del costado (o fijo: −1 izquierda, 1 derecha) |
| `width_base` / `width_tip` | 120 / 96 | Ancho del tentáculo. Unidad: px |
| `membrane_width` / `membrane_bulge` | 132 / 46 | Tamaño de la membrana. Unidad: px |
| `freeze_time` / `slow_scale` / `slow_time` | 0,06 / 0,3 / 0,3 | Instante congelado y cámara lenta (tiempo real). Unidad: s |
| `shake_amplitude` / `shake_duration` | 16 / 0,6 | Sacudida de cámara |
| `flash_color` / `flash_alpha` | rojizo / 0,5 | Destello |
| `splatter_count` | 28 | Trozos de carne |
