# Mecánica: logo del estudio

Al abrir el juego, `Main` muestra el logo del estudio (`scenes/ui/StudioLogo.tscn`, `scripts/ui/studio_logo.gd`) en una capa encima de todo (110). Cuando termina en negro, arma el hub con la pantalla de inicio y aclara en 0,3 s. Arte en `docs/arte/logo-estudio.md`.

Secuencia: la tele entra con un fundido (pantalla vacía, `empty`), espera, cruza el reflejo (`reflect`), pausa corta, el bebé aparece de golpe (`pop`) y a la vez el texto, saluda en bucle (`wave`) un rato y todo funde a negro. Cualquier tecla, botón de joystick, clic o toque lo saltea (fundido corto). Los tiempos de cada cuadro salen del JSON; los de la secuencia, de `StudioLogoConfig`.

## `StudioLogoConfig` (`resources/configs/studio_logo_config.tres`)

| Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|
| `enabled` | bool | true | — | Con false el juego arranca directo en la pantalla de inicio |
| `studio_name` | String | `__________` | — | Línea de arriba (blanca) |
| `studio_label` | String | `ESTUDIO` | — | Línea de abajo (gris) |
| `fade_in_time` | float | 0,3 | s | Fundido de entrada de la tele |
| `empty_hold` | float | 0,3 | s | Pantalla vacía antes del reflejo |
| `pre_pop_pause` | float | 0,2 | s | Pausa entre el reflejo y el bebé |
| `hold_time` | float | 1,8 | s | Bebé y texto en pantalla antes del fundido |
| `fade_out_time` | float | 0,3 | s | Fundido a negro al terminar |
| `skip_fade_time` | float | 0,15 | s | Fundido a negro al saltearlo |
