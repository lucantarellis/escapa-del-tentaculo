# Mecánica: pantalla de derrota

Brief 09. Arte y armado en `docs/arte/derrota.md`.

## Qué hace

Al perder (`GameManager` pasa a `LOST`), `LevelController` busca la causa (`GameManager.get_last_death_cause()`) en `DeathScreenConfig`. Si tiene entrada, abre la pantalla de derrota (`scenes/ui/DeathScreen.tscn`, `scripts/ui/death_screen.gd`) en la capa de mensajes (`CaughtLayer`, capa 90, encima del HUD). Si no tiene, sigue mostrando el texto de siempre (`DEATH_TEXTS`, que queda como respaldo). No hay pantalla genérica: las causas sin entrada (`obstacle`, `trap` y las del tier 3, descartado por ahora: `antibody`, `bile`, `minor_tentacle`) siguen con texto. La victoria no cambia.

- Título (CAPTURADO, ELECTROCUTADO…), viñeta animada a 2× en un marco `mk_panel_list` con el rótulo "● REPETICIÓN", línea de humor, panel de datos (`mk_panel_detail`) y botones.
- **Viñeta:** `SheetSprite` con `assets/sprites/ui/death/<nombre>.png` + `.json`. Reproduce `play` una vez y después `end` en bucle (tiempos de cada cuadro del JSON). Tocar o hacer clic en la viñeta durante `play` la salta a `end`.
- **Línea de humor y panel de datos:** aparecen con un fundido (`reveal_time`) al terminar `play` o al saltarlo.
- **Datos:** progreso de la partida (con barra), mejor progreso (con "NUEVO RÉCORD" si lo superó) y monedas ganadas en la partida (`PlayerProgress.get_run_coins()`). El récord se registra igual que antes (`RunRecords.submit_progress`).
- **Botones** (activos desde el primer cuadro): REINTENTAR (foco por defecto) = R, llama a `GameManager.restart()`. VOLVER AL HUB = Escape: la pantalla emite `hub_requested`, `LevelController` lo reenvía (`LevelController.hub_requested`) y `Main` vuelve al hub. Con el nivel solo (F6) nadie lo escucha y reinicia. R y Escape siguen andando como antes.
- Navegable con teclado o joystick (arriba/abajo cambia de botón, aceptar lo pulsa) y táctil.
- Fundido de entrada de la pantalla: `fade_in_time`.
- Versión del juego abajo a la derecha.

## Datos: `DeathScreenConfig`

`resources/configs/death_screen_config.tres`. Sumar una muerte, una viñeta o una línea es solo editar este recurso.

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `entries` | Array[`DeathScreenEntry`] | 2 entradas (abajo) | — | Una por muerte |
| `fade_in_time` | float | 0,3 | s | Fundido de entrada de la pantalla |
| `reveal_time` | float | 0,2 | s | Fundido de la línea de humor y del panel de datos |

Cada `DeathScreenEntry` (`scripts/ui/death_screen_entry.gd`):

| Variable | Tipo | Efecto |
|---|---|---|
| `causes` | Array[StringName] | Causas de `Player.die` que muestran esta muerte |
| `title` | String | Título grande |
| `vignettes` | Array[String] | Nombres de las viñetas (sin extensión) en `assets/sprites/ui/death/`; se elige una al azar |
| `lines` | Array[String] | Líneas de humor; se elige una al azar |

Valores iniciales:

| Causas | Título | Viñetas | Líneas |
|---|---|---|---|
| `tentacle`, `fell` | CAPTURADO | `death_captured_a` | "Tentáculo 1 · Vos 0", "Seguro sabés jugar" |
| `pulse`, `lethal` | ELECTROCUTADO | `death_electrocuted_a` | "Era de 220." |
| `fire` | CALCINADO | `death_scorched_a` | "Bien cocido." |
| `laser` | VAPORIZADO | `death_vaporized_a` | "Quedaron las botas." |
| `meteor` | IMPACTADO | `death_impacted_a` | "Mirá para arriba la próxima." |
| `comet` | CONGELADO | `death_frozen_a` | "Se te enfrió el asunto." |
| `debris_field`, `debris` | APLASTADO | `death_crushed_a` (provisoria) | "Pesaba más de lo que parecía." |

Las líneas del tier 2 son provisorias: se cambian editando `lines` en el Resource.

## Causas

`Platform` avisa `pulse` (PULSE en ON) y `lethal` (LETHAL), salvo que la instancia tenga otra `cause` distinta de `obstacle` (ver `plataformas.md`). Ninguna de las dos está en `dash_unblockable_causes`, `instakill_causes` ni `no_respawn_causes`: se comportan como un golpe común.

**Tier 2 (espacio):** este brief solo les suma pantalla; las reglas de `ProgressConfig` no cambian. `laser`, `meteor`, `comet`, `debris_field` y `debris` siguen siendo golpes comunes (no están en ninguna de las tres listas). `fire` sigue en las tres de siempre (`dash_unblockable_causes`, `instakill_causes` y `no_respawn_causes`).

**Caída en el espacio = `fire`.** `TentacleConfig.fall_cause` es la causa al caer bajo el borde inferior de la pantalla: `fell` por defecto (nave, tier 1: CAPTURADO) y `fire` en `tentacle_config_fire.tres` (tier 2: CALCINADO). Sin comparar el nombre del tier en el código. Consecuencia, aceptada por LT: en el espacio la caída cuenta como el fuego y entra en `no_respawn_causes`, así que Reaparecer no la evita (en la nave sí).

## Para sumar contenido

- **Otra línea:** agregarla a `lines` de la entrada.
- **Otra variante de viñeta:** exportar `death_<muerte>_b.png` + `.json` (tags `play` y `end`) y agregar el nombre a `vignettes`.
- **Otra muerte:** nueva `DeathScreenEntry` con sus causas, título, viñetas y líneas.
