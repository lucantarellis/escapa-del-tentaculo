# Mecánica: overlay de ayuda del hub

Brief 11. Arte en `assets/sprites/ui/hub_hints/` (spec en `docs/arte/lista-assets.md`).

**Archivos:** `scripts/hub/hub_hints.gd` (`HubHints`), `scripts/hub/hub_hints_config.gd` (`HubHintsConfig`), `resources/configs/hub_hints_config.tres`. Lo crea `Hub` (`_build_hints`) y lo arranca cuando el jugador toma el control.

## Qué hace

Oscurece el hub con un velo translúcido y muestra una pista por vez. Va en su propio `CanvasLayer` (capa 80): encima del mundo del hub y debajo de su UI (capa 90: pantalla de inicio, Ajustes, Mercado y fundido). No bloquea input: el jugador se mueve con total libertad.

| Pista | Cuándo | Se va cuando |
|---|---|---|
| 1 Caminar (← →, "CAMINAR") | `hub_hints_seen == false` | se movió `walk_distance` px en horizontal desde que apareció, o a los `walk_max_time` |
| 2 Volar (↑, "MANTENÉ PARA VOLAR") | tras la 1 | acumuló `fly_time` s de propulsor, o a los `fly_max_time` |
| 3 Plataforma ("SUBÍ ACÁ Y ESPERÁ 1 s", plataforma destacada) | tras la 2 | el jugador se sube (o el ascensor se arma): cierra todo. Sin tope (`platform_max_time` = 0) |
| 4 Mercado ("GASTÁ TUS MONEDAS" / "AJUSTES Y CRÉDITOS", puertas destapadas) | `hub_hints_seen`, no `market_hint_done` y monedas > 0 (desde la segunda visita con monedas) | entra por la puerta del mercado, o a los `market_max_time` |

- **Saltos:** volar antes de caminar cumple caminar; subirse a la plataforma en cualquier momento cierra el overlay.
- Las puertas quedan tapadas por el velo en las pistas 1 a 3 y destapadas (agujeros) en la del mercado.
- **Pantallas abiertas:** con Ajustes o el Mercado abiertos el overlay se oculta y pausa (los tiempos no corren); vuelve al cerrarlas.
- **Control:** solo cuenta lo que hace el jugador con el control; congelado, entrando por una puerta o en el ascensor no mide nada.
- **Solo teclado:** las teclas salen de un único punto, `HubHints._glyphs_for_input()`, para sumar la versión táctil cuando estén los controles de celular (no implementada).
- Las dos teclas de caminar se pulsan una por vez (`walk_keys_alternate`); con `false` parpadean juntas.

## Flags (`progress.cfg`, `[meta]`)

- `hub_hints_seen`: se pone en `true` en `launch_started` del ascensor (`Hub._on_launch_started`), no al mostrarse; así se repite si se cierra el juego antes de jugar.
- `market_hint_done`: se pone en `true` al entrar por la puerta del mercado con la pista en pantalla, o al llegar a `market_max_time`. No se marca si el jugador se sube a la plataforma, borra el progreso o pulsa VER CONTROLES.
- Borrar progreso (`PlayerProgress.reset_all()`) los baja; al salir de Ajustes el overlay arranca de nuevo. Un `progress.cfg` viejo sin las claves los lee como `false`.

## VER CONTROLES

Fila en Ajustes → INFO (`controls_button`). Cierra Ajustes y, al salir de la puerta, el hub corre `HubHints.play_sequence()` (pistas 1 a 3) sin mirar ni tocar los flags.

## Datos: `HubHintsConfig`

Todo editable en `resources/configs/hub_hints_config.tres`. Las posiciones están en coordenadas del hub (360×640), "solo visual".

| Grupo | Variables (valor inicial) |
|---|---|
| Textos | `walk_label` "CAMINAR"; `fly_line_1/2` "MANTENÉ" / "PARA VOLAR"; `platform_line_1/2` "SUBÍ ACÁ" / "Y ESPERÁ 1 s"; `market_line_1/2` "GASTÁ TUS" / "MONEDAS"; `settings_line_1/2` "AJUSTES Y" / "CRÉDITOS"; `controls_button` "VER CONTROLES" |
| Velo | `veil_color` `#050609`; `veil_alpha` 0,64; `veil_alpha_market` 0,5; `veil_fade` 0,25 s |
| Detección | `walk_distance` 24 px; `fly_time` 0,4 s; `step_pause` 0,3 s |
| Topes (0 = sin tope) | `walk_max_time` 12 s; `fly_max_time` 12 s; `platform_max_time` 0; `market_max_time` 15 s |
| Visual | `text_color` `#E7EFF2`; `text_shadow` `#050609`; `key_toggle_time` 0,5 s; `walk_keys_alternate` true; `dash_on` 4; `dash_off` 3; `dash_speed` 7 px/s |
| Posiciones | teclas, chevrones, textos, flechas, agujeros del velo y recuadros de cada pista (ver el `.tres` o el script) |
| Depuración | `debug_preview_step`: 1 a 4 muestra esa pista fija al tomar el control, sin flags; 0 = apagado (dejarlo en 0) |

## Cómo probarlo

1. Cuenta nueva (Ajustes → Borrar progreso): caminar, volar y subirse a la plataforma; cada pista se va al hacer la acción.
2. Lanzar la partida, perder sin juntar monedas y volver: sin pistas. Repetir juntando monedas: aparece la del mercado.
3. Ajustes → VER CONTROLES: repite las tres primeras sin cambiar el progreso.
