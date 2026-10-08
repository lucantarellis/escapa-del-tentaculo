# Mecánica: plataforma proyectil (`PROJECTILE`)

**Archivos:** `scripts/platforms/platform.gd` (tipo `PROJECTILE`), `platform_config.gd` (grupo "Proyectil"), escena `scenes/platforms/Platform.tscn` (nodos `TriggerArea` y `ExplosionArea`), config `resources/configs/platform_config.tres`. Relacionado: `scripts/levels/level_segment.gd` (`_get_child_rect` suma el recorrido del proyectil al chequeo de límites). Doc general de plataformas: `docs/mecanicas/plataformas.md`.

## Propósito

Una plataforma que es un proyectil: letal desde que aparece, quieta hasta que se cumple una condición, y después vuela en línea recta contra el jugador. Sirve para sorpresas controladas: algo que cruza la pantalla cuando entrás en una zona, o cuando te acercás.

## Modelo en palabras simples

1. **Quieta y letal.** Mientras espera ya es letal: tocarla mata (`Player.die(cause)`, `cause` por defecto `&"obstacle"`). No es sólida: el jugador la atraviesa y muere.
2. **Disparador (uno solo por plataforma, `projectile_trigger`):**
   - `CAMERA`: arranca cuando su rectángulo toca el rectángulo visible de la cámara activa. `projectile_screen_margin` lo adelanta (positivo) o lo atrasa (negativo). Si ya está dentro de la pantalla al empezar la partida, arranca en el primer frame.
   - `DISTANCE`: arranca cuando el cuerpo del jugador toca un círculo de radio `projectile_trigger_distance` centrado en la plataforma (se mide hasta el cuerpo del jugador, no hasta su centro).
3. **Demora.** Tras cumplirse el disparador espera `projectile_start_delay` s y recién ahí se mueve (con 0 arranca de inmediato).
4. **Vuelo.** Línea recta en la dirección de `travel`, a `projectile_speed`. No choca con paredes ni plataformas (salvo el rebote de abajo). Dispara una sola vez.
5. **Al golpear al jugador** lo mata y explota en ese punto, sea cual sea el final elegido.
6. **Final del recorrido (`projectile_end`):**
   - `EXPLODE`: al llegar a `inicial + travel` explota: zona letal circular de radio `explosion_radius` durante `explosion_duration` s; después desaparece. La explosión mata a un jugador vivo dentro del radio aunque no lo haya tocado el cuerpo.
   - `DESTROY`: al llegar a `inicial + travel` desaparece, sin explosión.
   - `BOUNCE`: no usa el largo de `travel`, solo su dirección. Rebota contra las 4 paredes de la **pantalla** (rectángulo visible de la cámara, techo y piso incluidos; esas paredes se mueven con la cámara). Rebota `projectile_bounce_count` veces; el choque siguiente la hace desaparecer. Solo cuenta un choque si va hacia afuera de esa pared. Un choque de esquina cuenta como dos rebotes (uno por eje).
7. **"Desaparecer"** significa ocultar y desactivar, no borrar (`queue_free`). Así `reset()` la revive. Con R el nivel se recarga entero, así que ahí nace de cero igual.

## Parámetros

### Por instancia (diseño de nivel)

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `platform_type` | enum | — | — | Poner `PROJECTILE` |
| `size` | Vector2 | (80, 12) | px | Tamaño del bloque (los de prueba usan 20×20) |
| `travel` | Vector2 | (120, 0) | px | Dirección y largo del recorrido |
| `projectile_trigger` | enum | `CAMERA` | — | `CAMERA` o `DISTANCE` |
| `projectile_end` | enum | `EXPLODE` | — | `EXPLODE`, `DESTROY` o `BOUNCE` |
| `cause` | StringName | `&"obstacle"` | — | Causa que recibe `Player.die` |
| `config` | PlatformConfig | `platform_config.tres` | — | Valores de tuning (ver abajo) |

### `PlatformConfig` (grupo "Proyectil")

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `projectile_speed` | float | 180 | px/s | Velocidad de vuelo |
| `projectile_trigger_distance` | float | 160 | px | Radio de disparo de `DISTANCE` |
| `projectile_start_delay` | float | 0,0 | s | Espera entre el disparo y el movimiento |
| `projectile_screen_margin` | float | 0 | px | Margen extra de pantalla para `CAMERA` |
| `projectile_bounce_count` | int | 3 | rebotes | Rebotes antes de desaparecer (`BOUNCE`) |
| `explosion_radius` | float | 48 | px | Radio de la zona letal de la explosión |
| `explosion_duration` | float | 0,3 | s | Duración de la zona letal de la explosión |

Estos valores son compartidos por todas las plataformas que usen el mismo `.tres`. Para un proyectil con velocidad o radios propios, duplicar `platform_config.tres` y asignarlo en esa instancia.

## Señales

| Señal | Cuándo se emite |
|---|---|
| `launched` | Se disparó y empezó a moverse |
| `exploded` | Explotó (al final del recorrido o al golpear al jugador) |
| `vanished` | Desapareció |
| `player_hit(cause)` | Golpeó (cuerpo o explosión) a un jugador vivo |

## Nodos y detalles de implementación

- `LethalArea` (ya existente): zona letal del cuerpo, activa desde el inicio hasta explotar o desaparecer.
- `TriggerArea` (`Area2D`, círculo, máscara 2 `player`): solo está activa mientras espera con `DISTANCE`.
- `ExplosionArea` (`Area2D`, círculo, máscara 2 `player`): solo está activa mientras explota.
- La cámara para `CAMERA` y para los rebotes es la activa del viewport (`get_viewport().get_camera_2d()`); no se busca ningún nodo hermano ni se toca `ScrollCamera`. Con una `ScrollCamera` usa su `get_visible_rect()`.
- El disparador `CAMERA` se calcula contra ese rectángulo en código y no con un `VisibleOnScreenNotifier2D`, que no funciona en modo headless y no se podría validar.
- `moves` se ignora en un `PROJECTILE`.
- Con `BOUNCE` el recorrido no se acota al segmento, por eso `level_segment.gd` solo suma `travel` al chequeo de límites con `EXPLODE` y `DESTROY`.
- Si la plataforma está fuera de pantalla y va hacia afuera, el rebote la devuelve hacia adentro al primer choque (cuenta como rebote). Para `BOUNCE` conviene el disparador `CAMERA`.
- Una plataforma que sube más lento que el scroll de la cámara choca seguido contra el piso de la pantalla y gasta sus rebotes rápido.

## Cómo probarla

1. Abrir un segmento que tenga un `PROJECTILE` (por ejemplo `Segment21`) y ejecutarlo con F6.
2. El segmento tiene seis proyectiles de 20×20, uno por combinación: `CamExplode`, `CamDestroy`, `CamBounce`, `DistExplode`, `DistDestroy`, `DistBounce`, cada uno junto a una plataforma fija para pararse. Los de `CAMERA` salen solos al entrar en pantalla; los de `DISTANCE` esperan a que te acerques.
3. Con F3 se ve la posición del jugador. En el editor, cada proyectil dibuja su dirección, el radio de disparo y el radio de explosión.

Validado en headless (ticks de física a 60 Hz): disparo por cámara y por distancia, velocidad medida 180 px/s, explosión de 18 ticks (0,3 s), rebotes (3 y desaparición al 4.º choque), muerte por golpe con explosión, radio de explosión (a 70 px sobrevive, a 40 px muere), `reset()` y demora de arranque.
