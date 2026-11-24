# Mecánica: pantalla de derrota

Brief 09. Arte y armado en `docs/arte/derrota.md`.

## Qué hace

Al perder (`GameManager` pasa a `LOST`), `LevelController` busca la causa (`GameManager.get_last_death_cause()`) en `DeathScreenConfig`. Si tiene entrada, abre la pantalla de derrota (`scenes/ui/DeathScreen.tscn`, `scripts/ui/death_screen.gd`) en la capa de mensajes (`CaughtLayer`, capa 90, encima del HUD). Si no tiene, sigue mostrando el texto de siempre (`DEATH_TEXTS`). No hay pantalla genérica: las causas de los tiers 2 y 3 siguen con texto hasta tener su pantalla. La victoria no cambia.

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

## Causas

`Platform` avisa `pulse` (PULSE en ON) y `lethal` (LETHAL), salvo que la instancia tenga otra `cause` distinta de `obstacle` (ver `plataformas.md`). Ninguna de las dos está en `dash_unblockable_causes`, `instakill_causes` ni `no_respawn_causes`: se comportan como un golpe común.

## Para sumar contenido

- **Otra línea:** agregarla a `lines` de la entrada.
- **Otra variante de viñeta:** exportar `death_<muerte>_b.png` + `.json` (tags `play` y `end`) y agregar el nombre a `vignettes`.
- **Otra muerte:** nueva `DeathScreenEntry` con sus causas, título, viñetas y líneas.
