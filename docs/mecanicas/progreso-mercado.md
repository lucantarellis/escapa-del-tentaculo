# Mecánica: progreso entre partidas y mercado

**Archivos:** `scripts/progress/player_progress.gd` (autoload `PlayerProgress`), `scripts/progress/upgrade_data.gd` (un nodo del árbol), `scripts/progress/progress_config.gd`, `resources/configs/progress_config.tres`, `resources/configs/upgrades/*.tres`, `scripts/pickups/coin.gd`, `coin_config.gd`, `scenes/pickups/Coin.tscn`, `resources/configs/coin_config.tres`, `scripts/levels/coin_spawner.gd`, `scripts/ui/market.gd`, `scenes/ui/Market.tscn`.

## Propósito

Que el juego sea progresivo. Sin compras el jugador arranca con lo mínimo (100 de combustible, tanques de 60 y sin dash), y terminar los tres tiers es casi imposible. En cada partida junta monedas; con ellas compra nodos de un **árbol de talentos** en el mercado del título y la próxima partida es más alcanzable.

## Modelo

- **Capa por encima de `player_config.tres`.** El archivo balanceado de LT no se toca. Al crearse, el [`Player`] pide una **copia** de su config con las mejoras aplicadas (`PlayerProgress.apply_to_player_config`). Con `ProgressConfig.enabled = false` se juega exactamente como antes (sin monedas, sin mercado, sin contador).
- **Valores base** (`ProgressConfig`): combustible máximo e inicial 100 u, dash 0 px (sin dash; `can_dash()` da `false`). Los tanques dan lo que diga `fuel_tank_config.tres` (60) o más, según la carga comprada. Las monedas valen lo de `coin_config.tres` (1) o más, según la mejora.
- **Monedas.** Se reparten solas en los segmentos intermedios (`CoinSpawner`, llamado por `LevelBuilder`) y se juntan tocándolas. Las de la partida se suman a las guardadas cuando termina (ganar, perder o R) o se cierra el juego; nunca se suman dos veces.
- **Guardado:** `user://progress.cfg` (monedas y nodos comprados; los regalados no se guardan). Lleva `meta/tree_version`: si el archivo es de otra versión del árbol, se empieza de cero una sola vez. Los récords siguen en `user://records.cfg`.
- **Compras con el nivel ya armado.** El `Player` escucha `upgrade_purchased` y reaplica el progreso (así lo comprado en el mercado del título vale en la primera partida).

## Árbol de talentos

Cada nodo es un `.tres` de `UpgradeData` en `resources/configs/upgrades/` y se compra una sola vez. Tiene `branch`, `requires_id` (el nodo anterior de la cadena), `price`, `owned_by_default`, `locked`, `effect`, `value` y `extra_value`. Si dos nodos comprados tienen el mismo efecto manda el de mayor `value`. Los nodos con `locked = true` (hoy: rompe plataformas, invulnerable largo, reparadores y escudos) se ven con "PRÓXIMAMENTE", no se compran y no hacen nada: reservan lugar para próximas iteraciones. Los precios son provisorios (se cambian en cada `.tres`).

| Rama | Nodo (id) | Efecto | Precio | Requiere |
|---|---|---|---|---|
| Dash | Dash corto (`dash`) | dash de 90 px | 20 | — |
| Dash | Dash largo (`dash_long`) | dash de 130 px | 40 | `dash` |
| Dash | Rompe plataformas (`dash_break`) | (candado) | 60 | `dash_long` |
| Dash | Invulnerable (`dash_invuln`) | invulnerable el 67% del dash, desde el momento 0 | 50 | `dash_long` |
| Dash | Invulnerable largo (`dash_invuln_long`) | (candado) | 80 | `dash_invuln` |
| Dash | Dash gratis (`dash_free`) | el dash no gasta combustible | 120 | `dash_invuln` |
| Tanque | Tanque 100 (`tank_1`) | capacidad 100 (regalado) | — | — |
| Tanque | Carga de 60 (`charge_1`) | cada tanque da 60 (regalado) | — | `tank_1` |
| Tanque | Tanque 250 (`tank_2`) | capacidad 250 | 25 | `charge_1` |
| Tanque | Carga de 100 (`charge_2`) | cada tanque da 100 | 20 | `tank_2` |
| Tanque | Tanque 500 (`tank_3`) | capacidad 500 | 60 | `charge_2` |
| Tanque | Carga completa (`charge_3`) | cada tanque llena el combustible | 50 | `tank_3` |
| Velocidad | Propulsión veloz (`speed`) | tope 210 px/s (antes 180) y aceleración 900 px/s² (antes 700); solo propulsión, no caminar | 40 | — |
| Monedas | Monedas x2 / x3 / x10 (`coin_2`, `coin_3`, `coin_10`) | cada moneda vale 2 / 3 / 10 | 30 / 80 / 250 | el anterior |
| Vidas | 1 vida (`life_1`) | aguantás 1 golpe letal (2 puntos de golpe) | 30 | — |
| Vidas | 2 vidas (`life_2`) | aguantás 2 golpes letales (3 puntos de golpe) | 60 | `life_1` |
| Vidas | Reaparecer (`life_respawn`) | una vez por partida, al morir volvés más arriba con 1 punto | 100 | `life_2` |
| Reparadores | Reparador I, II, III, Escudo 10 s, Escudo eterno (`repair_1`, `repair_2`, `repair_3`, `shield_10`, `shield_inf`) | (candado) | 40 a 150 | `life_2`, luego el anterior |

Decisión provisoria: "Invulnerable" pide Dash largo y no "Rompe plataformas" (que todavía no existe), y "Dash gratis" pide Invulnerable, para que se puedan probar. Se cambia con `requires_id`.

Velocidad: con la física actual (propulsión contraria al 90%) la distancia para frenar a tope es casi igual (~26 px antes, ~27 px con la perk), así que no cuesta más frenar.

El dash dura siempre `dash_duration` = 0,15 s (valor de `player_config.tres`): el corto va a 600 px/s y el largo a unos 867 px/s.

## Compras gratis por fase

La **primera vez** que se completa una fase se gana una compra gratis (una por fase, para siempre):

| Fase | Se completa cuando... |
|---|---|
| 1 (la nave) | el jugador cruza al segundo tier (el espacio) |
| 2 (el espacio) | el jugador cruza al tercer tier (el alien) |
| 3 (el alien) | el jugador llega a la puerta final (`WON`) |

- Cuenta aunque después muera en la partida. Si se pasan dos fases por primera vez en la misma partida, se suman dos. Repetir una fase que ya se completó no suma nada.
- La **próxima compra** del mercado no gasta monedas: usa una compra gratis, aunque haya 0 monedas. Valen los requisitos del árbol (no se saltea el orden ni los nodos con candado). Los nodos que cuestan 0 no gastan compras gratis.
- En el mercado, junto a las monedas se ve `Gratis: N`, y los nodos comprables dicen `GRATIS` en lugar del precio (y el detalle lo aclara).
- **Reset all** borra las compras y las monedas, pero NO las fases completadas: devuelve todas las compras gratis, incluso las ya gastadas. Disponibles = fases completadas − usadas desde el último Reset all.
- Al completar una fase por primera vez, el nivel muestra unos segundos el aviso "¡FASE N COMPLETADA! Ganaste una compra gratis" (`LevelController`, constantes `NOTICE_*`).
- Se guarda en `user://progress.cfg`, sección `[free_buys]` (`phases`, `used`). Las fases que se pasaron antes de existir esta mejora no cuentan: arranca en 0.
- Pendiente: cuando exista el jefe final, la fase 3 se completará al llegar a él o derrotarlo (hoy es la puerta).

## Puntos de golpe y Reaparecer

"Vida" en el árbol significa **punto de golpe**: cuántos golpes aguanta el jugador. Sin compras tiene 1 punto (el primer golpe letal mata, como siempre); con 1 vida tiene 2 y con 2 vidas tiene 3 (`hit_points` es el total). Se implementa en `Player.die(cause)`:

1. Primero rige la invulnerabilidad del dash (si está activa).
2. Las causas de `instakill_causes` (`&"tentacle"` y `&"fell"`: los perseguidores y la caída bajo la pantalla) matan siempre, sin importar los puntos ni la invulnerabilidad tras un golpe.
3. Cualquier otra causa (obstáculo, trampa, escombros, láser, mini tentáculo, etc.) resta 1 punto si hay más de 1 y el jugador sobrevive. Tras el golpe queda `hit_invulnerable_time` (1,5 s) sin poder perder otro punto, parpadeando.
4. Con la mejora Reaparecer y sin usarla en la partida, en lugar de morir (con cualquier causa, perseguidores incluidos) el jugador reaparece `respawn_height` px más arriba (160; se busca un lugar libre en 6 alturas cercanas), con `respawn_hit_points` (1) y la invulnerabilidad de un golpe. Es una sola vez por partida: `Player.reset()` (R o partida nueva) la devuelve. No se emite `died`, así que el juego no termina.

Los puntos se ven como corazones provisorios bajo las monedas (solo con más de 1 punto). Para ponerle sprites al jugador: en `Player.tscn`, nodo raíz, grupo Visual, `hit_sprites` (1.º sin golpes, 2.º con 1 golpe, 3.º con 2; si hay menos se repite el último). Se muestran en `Body/Sprite`. Con la lista vacía el cuerpo placeholder se oscurece con cada golpe.

Parámetros (`ProgressConfig`, grupo "Golpes y reaparición"): `hit_invulnerable_time` 1,5 s, `instakill_causes` [tentacle, fell], `respawn_height` 160 px, `respawn_hit_points` 1.

## Dash invulnerable

La invulnerabilidad arranca en `dash_invulnerable_start` (0 s: apenas empieza el dash) y dura `dash_invulnerable_percent` (67%) de `dash_duration`, o sea 0,1005 s de 0,15 s (6 de los 9 ticks del dash a 60 fps). En esa ventana `Player.die(cause)` se ignora, salvo para las causas de `dash_unblockable_causes` (`&"tentacle"`, `&"fell"`, `&"minor_tentacle"`). Antes y después de la ventana el jugador es vulnerable. Las plataformas letales fijas matan solo al entrar: si un dash termina dentro de una, el jugador sobrevive hasta salir y volver a tocarla.

## Parámetros (`ProgressConfig`, `progress_config.tres`)

| Grupo | Parámetro | Valor | Unidad | Qué hace |
|---|---|---|---|---|
| General | `enabled` | true | — | Apaga o enciende todo el progreso |
| General | `debug_min_coins` | 0 | monedas | Para pruebas: al abrir el juego completa las monedas hasta este número |
| General | `debug_set_free_buys` | -1 | compras | Para pruebas: al abrir el juego fija las compras gratis disponibles en exactamente este número (marca las primeras N fases como completadas y pone en 0 las usadas; -1 = apagado) |
| General | `debug_set_coins` | -1 | monedas | Para pruebas: al abrir el juego fija las monedas en exactamente este número (-1 = apagado; manda sobre `debug_min_coins`) |
| Base | `base_max_fuel` | 100 | u | Combustible sin mejoras |
| Base | `base_dash_distance` | 0 | px | Dash sin mejoras (0 = sin dash) |
| Dash invulnerable | `dash_invulnerable_start` | 0 | s | Cuándo empieza, desde que arranca el dash |
| Dash invulnerable | `dash_invulnerable_percent` | 67 | % | Cuánto dura, como porcentaje de `dash_duration` |
| Golpes y reaparición | `hit_invulnerable_time` | 1,5 | s | Invulnerabilidad tras un golpe que no mata |
| Golpes y reaparición | `instakill_causes` | tentacle, fell | — | Causas que matan siempre |
| Golpes y reaparición | `respawn_height` | 160 | px | Cuánto más arriba reaparece |
| Golpes y reaparición | `respawn_hit_points` | 1 | puntos | Puntos con los que reaparece |
| Monedas | `coins_per_segment_min` / `max` | 2 / 4 | monedas | Cuántas por segmento intermedio |
| Monedas | `coin_edge_margin` | 28 | px | Distancia al borde del segmento |
| Monedas | `coin_obstacle_margin` | 26 | px | Distancia a plataformas, paredes, tanques y peligros |
| Monedas | `coin_min_separation` | 44 | px | Distancia entre dos monedas |
| Monedas | `coin_placement_tries` | 40 | intentos | Si no hay lugar, el segmento tiene menos monedas |

El valor de cada moneda (`CoinConfig.value`, 1) y el vaivén están en `coin_config.tres`.

## Reparto de monedas

`CoinSpawner` no toca los `.tscn`: lee lo que ya tiene cada segmento (plataformas con su recorrido, puertas, tanques, cuerpos estáticos, cualquier otro nodo con posición y las celdas pintadas de las paredes) y sortea puntos libres. Usa un `RandomNumberGenerator` propio (`seed + 1000003`): la misma seed da las mismas monedas y no cambia los segmentos elegidos. No pone monedas en el inicio, en los segmentos de entrada o salida de tier ni en el final. No comprueba que el lugar sea alcanzable: en túneles cerrados una moneda podría quedar en un hueco inaccesible.

## Señales y API

- `PlayerProgress.coins_changed(total)`, `run_coins_changed(run_total)`, `upgrade_purchased(id)`, `free_buys_changed(available)` y `phase_completed(phase)` (solo la primera vez que se completa esa fase).
- `PlayerProgress.complete_phase(phase) -> bool` (true si era la primera vez), `get_free_buys()`, `is_phase_completed(phase)`, `is_free_buy(id)` (comprar ese nodo gastaría una compra gratis). `LevelController` llama a `complete_phase` al cruzar de tier y al ganar.
- `PlayerProgress`: `is_enabled()`, `get_coins()`, `get_run_coins()`, `add_run_coins(n)`, `bank_run()`, `is_owned(id)`, `get_upgrade(id)`, `get_block_reason(id)` (`owned`, `locked`, `requires`, `coins` o vacío), `can_buy(id)`, `buy(id)`, `reset_all()`, `get_effect_value(effect, fallback)`, `has_effect(effect)`, `apply_to_player_config(base)`, `get_tank_amount(base)`, `get_coin_value(base)`, `get_dash_invulnerability()`, `get_survival()`.
- `Coin.collected(value)`: `CoinSpawner` la conecta con `PlayerProgress.add_run_coins`.
- `Player.is_dash_invulnerable()`, `get_hit_points()`, `get_max_hit_points()`, `is_hit_invulnerable()`, `can_respawn()`; señales `hit_points_changed(current, maximum)`, `hit_taken(cause)` y `respawned(at)`.
- `PlayerProgress.progress_reset()`: se emite al hacer `reset_all()`; el `Player` vuelve a su config sin compras.
- `Market.closed`, `Market.open()`, `Market.close()`, `Market.show_branch(id)`, `Market.get_node_button(id)`. El `TitleMenu` lo contiene y lo abre con su botón MERCADO; el HUD muestra las monedas de la partida arriba a la izquierda.

## Nodos

`TitleMenu` → `Center/Box/MarketButton` y `Market` (pantalla completa, oculta). `Market` → `Margin/Box` con título, monedas, `Tabs` (una solapa por rama, creadas por código), `Scroll/Nodes` (los nodos de la rama activa como botones unidos por líneas), `DetailPanel` (qué hace, cuánto cuesta y qué falta del nodo seleccionado) y VOLVER. En la línea de monedas, a la derecha, está el botón **Reset all** (`CoinsRow/ResetButton`): el primer toque pide confirmación ("¿Seguro?", rojo, se cancela a los 3 s o al tocar otra cosa) y el segundo borra monedas y compras (los nodos regalados siguen). Tocar un nodo lo selecciona y, si se puede, lo compra. `Hud` → `CoinLabel`.

## Cómo probarlo

1. Con el juego cerrado, poner `debug_min_coins = 200` en `progress_config.tres` para tener monedas de entrada (volver a 0 después).
2. F5: en el título, MERCADO. Cambiar de rama con las solapas, tocar nodos y ver el detalle de abajo (cuesta, "te faltan N", "Primero comprá: ...", "Próximamente"). Los comprados se ven cian, los comprables naranja. Escape o VOLVER cierran.
3. JUGAR: sin compras, combustible 100 en la barra y Shift no hace nada. Con dash comprado, Shift lanza el dash (90 o 130 px). Con Propulsión veloz se acelera más rápido y se llega a 210 px/s. Con Dash gratis la barra de combustible no baja al dashear.
4. Juntar monedas durante la partida (contador arriba a la izquierda); perder o ganar las guarda. Tras terminar, Escape vuelve al título y MERCADO muestra las monedas guardadas.
5. Con la invulnerabilidad: dashear contra un obstáculo o una trampa durante los primeros 2/3 del dash debería salvarte; el tentáculo y la caída siguen matando.
6. Para jugar como antes: `enabled = false`.
7. Compras gratis: con `debug_set_free_buys = 2` en `progress_config.tres` (volver a -1 después) el mercado muestra `Gratis: 2` y los nodos dicen GRATIS; al comprar uno baja a 1 y no se gastan monedas. Jugando de verdad: cruzar al espacio (o al alien) por primera vez muestra el aviso y suma 1. Reset all devuelve las gratis.
8. Para empezar de cero desde el juego: botón **Reset all** del mercado (dos toques). Si `debug_set_coins` está activo, al abrir el juego las monedas vuelven a ese número. O bien: borrar `user://progress.cfg` (en Godot: Proyecto → Abrir carpeta de datos de usuario del proyecto) o subir `TREE_VERSION` en `player_progress.gd`.

## Limitaciones conocidas

- El mercado solo se abre desde el título. Tras ganar o perder, Escape vuelve al título y R repite la partida directo (sin título). No hay pausa durante la partida.
- Reparadores, escudo, rompe plataformas e invulnerable largo son nodos con candado sin efecto: se implementan en próximos pasos.
- Las monedas se reparten automáticamente y no hay forma de ubicarlas a mano en un segmento.
