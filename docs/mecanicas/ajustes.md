# Mecánica: Ajustes y créditos

**Archivos:** `scenes/ui/Settings.tscn`, `scripts/ui/settings_screen.gd` (`SettingsScreen`), `scripts/ui/ui_kit.gd` (`UiKit`, piezas de UI compartidas), `scripts/managers/game_settings.gd` (autoload `GameSettings`), `default_bus_layout.tres` (buses `Music` y `SFX`). Arte y medidas: `docs/arte/ajustes.md`.

## Cómo se entra

Por la puerta de Ajustes del hub (izquierda): el jugador se pierde en el hueco, fundido a negro y se abre la pantalla. **Volver** o Escape cierran (un solo fundido; la pantalla no se oculta hasta estar en negro) y el jugador sale de la puerta. Desde Créditos, Volver o Escape vuelven a Ajustes; desde la confirmación, Escape cancela.

## Ajustes

| Sección | Fila | Qué hace |
|---|---|---|
| SONIDO | Música / Efectos | Barra deslizante 0–100 % (izquierda/derecha de a 10 %, o tocar/arrastrar). Mueve el volumen del bus `Music` / `SFX` al instante (en 0 se silencia). |
| JUEGO | Vibración | Interruptor. Con la vibración activa, el celular vibra en cada golpe de la escotilla (80 ms), en su ruptura (250 ms), al recibir un golpe (80 ms) y al morir (200 ms). |
| JUEGO | Idioma | "‹ Español ›": izquierda/derecha (o tocar las flechas) recorren `GameSettings.LANGUAGES` y llaman a `TranslationServer.set_locale`. Hoy hay un solo idioma: queda preparado para sumar traducciones. |
| INFO | Créditos › | Abre la pantalla de créditos. |
| INFO | VER CONTROLES › | Cierra Ajustes y, al salir de la puerta, el hub repite las pistas de ayuda 1 a 3 (caminar, volar, plataforma) sin tocar los flags del progreso. El texto del botón es `controls_button` de `HubHintsConfig`. Ver `overlay-hub.md`. |
| DATOS | Borrar progreso | Pide confirmación (capa oscura; **Cancelar** tiene el foco). **Borrar** llama a `PlayerProgress.reset_all()`: monedas y mejoras a cero (los nodos regalados siguen) y el overlay de ayuda del hub vuelve a aparecer. |

Abajo a la derecha, la versión (`application/config/version`, hoy 0.8). Navegación: arriba/abajo recorre las filas y baja a Volver; izquierda/derecha ajustan la fila con foco.

Todo se guarda en `user://settings.cfg` en cada cambio y se aplica al abrir el juego (`GameSettings._ready`). `GameSettings.vibrate(ms)` es el único lugar que hace vibrar.

## Créditos

Título del juego, **Hecho por:** Luca 'LT' Cantarelli y Guido Robles; **Tipografía:** Tiny5, The Tiny5 Project Authors, SIL Open Font License 1.1 (la licencia pide que figure); **Motor:** Hecho con Godot. El texto está en `SettingsScreen.CREDITS`.

## Cómo probarlo

1. F5, caminar a la izquierda y empujar contra la puerta de Ajustes.
2. Mover Música y Efectos con izquierda/derecha y con el mouse: el porcentaje cambia.
3. Vibración: el interruptor cambia (la vibración se nota solo en el celular).
4. Créditos › y Volver.
5. Borrar progreso → Cancelar (no pasa nada) → Borrar (el mercado queda en 0).
6. Cerrar el juego y volver a abrir: los ajustes siguen.
