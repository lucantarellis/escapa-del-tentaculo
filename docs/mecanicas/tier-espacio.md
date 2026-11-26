# Tier 2: el espacio

**Archivos:** segmentos en `scenes/levels/segments/space/` (`SegmentSpace01`–`10` y las entradas `SegmentSpaceEntry01`–`03`) y salidas de la nave en `scenes/levels/segments/ship/` (`SegmentShipExit01`–`03`); scripts `scripts/levels/window_breach.gd` (`WindowBreach`), `tier_event.gd` (`TierEvent`), `hull_debris.gd` (`HullDebris`), `level_background.gd` (`LevelBackground`) y `space_background.gd` (`SpaceBackground`); config del fuego `resources/configs/tentacle_config_fire.tres`; asteroides `scenes/levels/Asteroid.tscn` (`scripts/levels/asteroid.gd`). Todo se asigna en `resources/configs/level_config.tres`.

## Historia

Al final de la nave, el alien rompe un ventanal del techo con un tentáculo. La descompresión arrastra al jugador afuera. Ya en el espacio, un instante después, la nave explota abajo: restos en llamas salen despedidos y el **fuego** de la explosión pasa a ser lo que persigue al jugador. El alien huye hacia arriba.

## Secuencia de la transición

1. **Salida de la nave (`SegmentShipExitNN`, último segmento del tier 1, `exit_segments`).** Arriba hay un techo de lado a lado con un hueco central (x 144–216) cerrado por un **vidrio** (`WindowBreach`, en y −582). Bajo el hueco queda un pasillo libre (x 132–228, y −300 a −564). Cuando el jugador llega a `trigger_distance` (260 px) bajo el vidrio, un tentáculo del alien (`tentacle_front` dado vuelta, detrás del techo) baja por el hueco con `reach`; cuando su punta dibujada toca el vidrio, el vidrio se raja y estalla (`crack` → `shatter` → `broken`), sacudida 14 px / 0,6 s, vidrios (`window_shards`) y líneas de aire (`window_wind`, se desvanecen al terminar la succión), y empieza la **descompresión**. El tentáculo entra con `grab` hacia el jugador (sin colisión), se retira con `retract` (sube `tentacle_ascent_distance`, 900 px) y se libera. Para que nunca se vea el corte de la base del sprite, encima de la base se dibuja un tronco (`Trunk`): las últimas 60 filas del cuadro repetidas en espejo hasta 1400 px hacia arriba, así el tentáculo viene "desde el alien", fuera de la pantalla. Tiempos en el grupo "Tentáculo" de `WindowBreach` (`tentacle_start_height`, `tentacle_descent_time`, `tentacle_grab_depth`, `tentacle_ascent_time`, `tentacle_ascent_distance`). Arte: `docs/arte/ventanal.md`. **Mientras el vidrio está sano, la cámara no sube más allá del techo** (`ScrollCamera.set_view_ceiling`): el ventanal queda arriba del todo y no se ve lo que hay del otro lado. Al romperse se libera la cámara y el fondo pasa al del tier siguiente (el espacio) en ese momento (`LevelController._on_window_broken`), sin esperar a que el jugador cruce el borde del tier. Con la descompresión: el aire lo arrastra hacia el hueco (`pull_acceleration` 1500 px/s², hasta `pull_max_speed` 560 px/s, dentro de `pull_radius` 480 px, como mucho `pull_duration` 3 s). El jugador no pierde el control. Medido sin tocar nada: sale por el hueco en ~0,7 s y su impulso lo lleva más de 300 px dentro del espacio.
2. **Entrada al espacio (`SegmentSpaceEntryNN`, `entry_segments` del tier 2).** Al cruzar su borde, `LevelController` cambia el fondo (negro con estrellas), la física y el perseguidor, que aparece recién `pursuer_delay` (1,5 s) después. Toda la entrada tiene un **pasillo libre (x 110–250)** de punta a punta: solo asteroides a los costados.
3. **Las explosiones (`TierEvent`, en y −260 de la entrada).** Al cruzarlo, tras `explosion_delay` (0,5 s), la nave estalla en cadena: `explosion_waves` 3 explosiones separadas `explosion_wave_interval` 2,2 s. La primera, desde la nave abajo (`explosion_offset` (180, 360)), trae cámara lenta (0,25 durante 0,35 s), destello, un empujón (`eject_speed` 220 px/s) y la silueta del alien huyendo; las siguientes salen desde debajo de la pantalla, con la **misma sacudida** (`wave_shake_scale` y `wave_shake_duration_scale` = 1) y su anillo de fuego. **Aviso previo:** `warning_time` (0,7 s) antes de cada explosión el borde inferior de la pantalla parpadea en naranja (`warning_blinks` 3) y la cámara tiembla apenas (`warning_shake_amplitude` 3 px); antes de la primera dura lo que falte de `explosion_delay` (0,5 s). La señal `warning_started(lead)` queda lista para el sonido de aviso (pendiente: paso de audio). Cada una lanza `debris_count` 8 **restos letales** (`HullDebris`) que entran por el borde inferior a 220–380 px/s y salen **en direcciones al azar** hacia arriba (`debris_aim_at_player` = false, abanico de ±`debris_random_angle` 55°; con `debris_aim_at_player` = true apuntarían hacia adelante del jugador, `debris_lead` 0,5 s, ±30° de desvío); miden 18 px, nunca aparecen a menos de 60 px del jugador en horizontal y no matan los primeros 0,25 s. **Si chocan con algo sólido** (asteroides, paredes, restos metálicos) **se rompen**. Causa de muerte `&"debris"`.

Cada parte se ajusta con los `@export` de `WindowBreach` y de `TierEvent` en cada segmento (inspector).

## Qué hay en el espacio

| Elemento | Qué es | Cómo está hecho |
|---|---|---|
| Superficies | **Asteroides** de roca de 4 tamaños (chico 48 × 48 px, mediano 96 × 48, grande 120 × 72 y gigante 144 × 96, este último solo en `SegmentSpace05`), 10 variantes de cada uno; flotan (van y vienen) y los chicos y medianos pueden girar; donde parar y recargar. Cada segmento mezcla tamaños (`SegmentSpace04` y `09` tienen solo chicos: su espacio libre es justo) | Instancias de `Asteroid.tscn` (ver "Asteroides" más abajo) con `drift` (vaivén, 8–18 px), `drift_period` (3–6 s) y `spin_speed` (°/s; 0 en los grandes y gigantes y en ~40 % de los chicos, si no 6–14 °/s). Son cuerpos cinemáticos, así que te llevan si estás parado encima |
| Impulsos | Flechas cian: al tocarlas, 1 s de propulsión y velocidad máxima ×1,8; en el espacio casi no se frena, así que la velocidad ganada se conserva | `SpeedBoost` (`scenes/pickups/SpeedBoost.tscn`, config `speed_boost_config.tres`: `duration`, `multiplier`, `fuel_amount`). 2 por segmento del espacio y por entrada |
| Restos a la deriva | Chapas de la nave que se mueven despacio y se pueden pisar | `Platform` STATIC con `moves`, que el `LevelBuilder` vuelve `BREAKABLE` (`force_breakable`) y dibuja con la hoja `platform_debris` (`debris_platforms` del tier): chapas arrancadas con brasas, sin propulsores. Se sacuden al pisarlas, se parten en trozos que se separan sin caer y, una vez rotas, **no vuelven** en toda la partida. El dash las revienta con un destello. Ver `plataformas.md` |
| Meteoros y cometas | Cruzan la pantalla avisando antes (marca en el borde; el cometa, además, la línea de su recorrido); tocarlos mata. El meteoro se rompe contra los asteroides | `SpaceProjectile` (`Meteor.tscn`, `Comet.tscn`). Ver `obstaculos-espacio.md` |
| Campo de escombros | Trozos que orbitan un punto; tocarlos mata | `DebrisField`. Ver `obstaculos-espacio.md` |
| Satélite láser | Apunta, fija y dispara un haz; solo mata al disparar | `SatelliteLaser`. Ver `obstaculos-espacio.md` |
| Tanques | Cápsulas de la nave flotando sobre los asteroides | `FuelTank` |

PULSE, TIMED y BREAKABLE no aparecen en el espacio (son mecanismos de la nave).

## Asteroides (`Asteroid`)

Escena `scenes/levels/Asteroid.tscn` (raíz `AnimatableBody2D`, script `scripts/levels/asteroid.gd`); arte en `assets/sprites/environment/asteroids/` (guía: `docs/arte/asteroides.md`). Cada asteroide arma por código su `Sprite2D` (`CanvasTexture` con color y normal map, filtro nearest) y su `CollisionPolygon2D` (de `asteroid_shapes.json`). Es sólido (capa 1 `world`): el jugador se para encima y el asteroide lo lleva; el meteoro y los restos de la explosión se rompen contra él. Se dibuja detrás del jugador (`z_index` −1, como las paredes). El origen del nodo es el centro del asteroide y el eje de giro.

- **Giro por cuadros:** el sprite nunca se rota. Los chicos y medianos tienen 72 cuadros (uno cada 5°, con el normal map ya girado). El código acumula el ángulo con `spin_speed` y rota **solo el cuerpo** (la colisión) en pasos de 5°; el sprite se contrarrota y muestra el cuadro de la rotación que el cuerpo tiene al dibujar (con `sync_to_physics` la rotación nueva se aplica en el paso de física siguiente: así el dibujo y la colisión coinciden siempre). El jugador parado encima avanza con cada paso (un salto de ~2–4 px cada vez que cambia el cuadro, igual que el dibujo).
- **Grandes y gigantes:** un solo cuadro; no giran aunque tengan `spin_speed`.
- **Monedas:** `CoinSpawner` reserva el área que el asteroide puede ocupar con el giro y el vaivén (`get_reserved_rect()`).
- En el editor se ve quieto, en el cuadro 0, con su colisión.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `size` | Chico | Chico, mediano, grande o gigante |
| `variant` | 0 | Variante 1–10; 0 = una al azar, estable para el mismo nombre y posición |
| `drift` | (0, 10) | Vaivén máximo respecto de su posición. Unidad: px |
| `drift_period` / `drift_offset` | 4 / 0 | Duración de un vaivén y desfase. Unidad: s |
| `spin_speed` | 0 | Giro (positivo = horario). Solo chicos y medianos. Unidad: °/s |

**Colocación (25/11, brief 10):** cada asteroide de tiles se reemplazó por la variante del tamaño más parecido (sin repetir variante dentro del segmento), conservando su lugar y su movimiento. Los de 84 × 48 de las entradas pasaron a medianos; los de 108 × 72, a grandes (con el centro corrido 6 px para que el dibujo quede donde estaban los tiles). Pasaron a `spin_speed` 0 los grandes y gigantes que giraban: `SegmentSpace03` `Asteroid3`, `SegmentSpace05` `Asteroid4` y `SegmentSpace08` `Asteroid3`. El dibujo es más irregular que el bloque de tiles: la superficie útil es un poco menor.

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

Dibujado por `SpaceBackground` (`scripts/levels/space_background.gd`, escena `scenes/levels/SpaceBackground.tscn`), hijo de `LevelBackground`, que lo muestra con fundido cuando el tier pide estrellas (`background_stars`). Es el mismo cielo de los ventanales del hub, con arte en `assets/sprites/environment/background_space/` (guía: `docs/arte/fondo-espacio.md`). Se parametriza en `SpaceDecorConfig` (propiedad `decor` del nodo `Background`; vacío = valores por defecto). Es solo visual, sin colisión. Las capas se mueven a mano con la Y de la cámara (la capa de pantalla −10 no sigue al mundo) y el desenfoque lo pone `shaders/background_layer.gdshader` (el de la nave).

| Capa | Paralaje | Desenfoque | Animación |
|---|---|---|---|
| Nebulosa lejana (`space_far_nebula`, 360×1200, se repite) | 0,06 | 1,2 px | — |
| Estrellas lejanas y sol (`space_far_stars`, alineada con la nebulosa) | 0,06 | no | — |
| Planeta del anillo (`space_planet_ringed`, 168×168) | 0,15 | 0,6 px | `rotate`, 24 cuadros de 150 ms |
| Estrellas cercanas (`space_stars_near`, 360×640, se repite) | 0,3 | no | `twinkle`, 8 cuadros de 150 ms |
| Estrella fugaz | — | no | Por código, cada 6–10 s, en los costados y muy tenue |
| Rocas del frente (`space_front_rocks`, 50 piezas), capa 5 delante del jugador | 1,4 | 3,5 px | — |

- **Planeta:** una vez por tramo de `planet_loop` (1600 px), con la esquina superior izquierda en `planet_origin` (220, 250): queda cortado por el borde derecho.
- **Rocas del frente:** reparto con semilla (`foreground_seed`): una cada `foreground_gap_min`–`max` (140–280 px), alternando izquierda y derecha, con el centro entre `foreground_edge_min` y `max` (−10 a 40 px) del borde, sin repetir la pieza de la anterior. El reparto se repite cada `foreground_loop` (4000 px). Se espejan al azar y nunca giran. Se apagan hacia el centro desde `foreground_clear_radius` (90 px) para no tapar el juego. Cada pieza se recorta del atlas en su propia textura con 8 px de borde transparente, así el desenfoque no toma píxeles de las vecinas.
- **Filtro:** las capas desenfocadas usan filtro lineal (el desenfoque toma medios píxeles, como en la nave); las nítidas (estrellas), nearest.

| Propiedad de `SpaceDecorConfig` | Defecto | Descripción |
|---|---|---|
| `far_parallax` / `planet_parallax` / `near_parallax` / `foreground_parallax` | 0,06 / 0,15 / 0,3 / 1,4 | Paralaje de cada capa |
| `nebula_blur` / `planet_blur` / `foreground_blur` | 1,2 / 0,6 / 3,5 | Radio del desenfoque. Unidad: px |
| `planet_origin` / `planet_loop` | (220, 250) / 1600 | Posición en el tramo y largo del tramo. Unidad: px |
| `foreground_loop` | 4000 | Ciclo del reparto de rocas (0 = sin rocas). Unidad: px |
| `foreground_gap_min` / `foreground_gap_max` | 140 / 280 | Separación entre rocas. Unidad: px |
| `foreground_edge_min` / `foreground_edge_max` | −10 / 40 | Cuánto entra el centro de la roca desde el borde. Unidad: px |
| `foreground_clear_radius` / `foreground_alpha` / `foreground_seed` | 90 / 1,0 / 1234 | Zona libre del centro, opacidad y semilla |
| `shooting_min_interval` / `shooting_max_interval` | 6 / 10 | Segundos entre estrellas fugaces (0 en el máximo = ninguna) |

## Salida del tier: el tentáculo del alien (`SegmentSpaceExit01`)

Último segmento del espacio (`exit_segments` del tier 2; por ahora 1 variante, el objetivo son 10). Hace el papel del "ventanal" del tier 1: la transición al tier 3 es **entrar por la punta de un tentáculo del alien**.

- **El tentáculo (`FleshMembrane`, punta en y −400):** un tentáculo de carne **vertical** (anillos, ventosas, late y ondula) que baja desde arriba con la **punta redondeada hacia el jugador** y tapa el único hueco de una masa de carne (capa `Limb`, desde y −470 hacia arriba, con el tileset del tier 3 vía el grupo `keep_tileset`). El hueco mide 110 px de ancho y se cierra a 72 px arriba, donde empalma con la abertura de la piel del tier 3. Baja mientras la cámara se acerca (empieza al asomar por el borde superior y termina de bajar al subir unos 160 px). No hay otro camino que entrar por la punta.
- **Romperlo:** al tocar la punta (sin habilidad extra) estalla con un **estallido de sangre**: instante congelado de 0,06 s, cámara lenta (0,3 durante 0,3 s), sacudida de 16 px por 0,6 s, destello rojo, un anillo de sangre que se expande, 70 gotas y 6 trozos de la punta que salen despedidos. Queda abierto el interior del tentáculo (más oscuro, con el borde desgarrado), por donde el jugador sigue con su velocidad hacia la piel del tier 3 (`SegmentAlienEntryNN`), donde cambian el fondo, la física y el perseguidor.
- **Ganchos de sonido:** señales `membrane_hit` (golpe) y `broken` (rotura) para el paso de audio.
- Un `TierEvent` en y −110 avisa con un temblor (1,6 s, 8 px) y una franja violeta-rojiza; sin explosión ni restos. Hay 2 tanques de combustible.

| Propiedad de `FleshMembrane` | Defecto | Descripción |
|---|---|---|
| `length` | 250 | Largo del cuerpo desde la punta hacia arriba. Unidad: px |
| `half_width_tip` / `half_width_top` | 55 / 36 | Semiancho cerca de la punta y arriba del todo. Unidad: px |
| `cap_length` | 70 | Largo de la punta redondeada. Unidad: px |
| `approach_distance` / `grow_span` / `drop_distance` | 330 / 160 / 300 | Cuándo baja, cuánto tarda y cuánto recorre. Unidad: px |
| `freeze_time` / `slow_scale` / `slow_time` | 0,06 / 0,3 / 0,3 | Instante congelado y cámara lenta (tiempo real). Unidad: s |
| `shake_amplitude` / `shake_duration` | 16 / 0,6 | Sacudida de cámara |
| `flash_color` / `flash_alpha` | rojo / 0,55 | Destello |
| `blood_count` | 70 | Gotas de sangre |
