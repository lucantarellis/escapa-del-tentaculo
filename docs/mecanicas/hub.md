# Mecánica: hub (menú navegable)

**Archivos:** `scenes/hub/Hub.tscn`, `scripts/hub/hub.gd` (`Hub`), `scripts/hub/hub_door.gd` (`HubDoor`), `scripts/hub/hub_elevator.gd` (`HubElevator`), `scripts/hub/hub_config.gd` + `resources/configs/hub_config.tres` (`HubConfig`), `shaders/hub_space.gdshader`. Arte y coordenadas: `docs/arte/hub.md`.
**Depende de:** `Player`, `Market`, `WallsShip.tscn` (paredes de la nave), `ShipFloor`, `SheetSprite`, `LevelLighting` (luces y ambiente de la partida), `PlayerProgress` (sin progreso, la puerta del mercado no se abre).

## Propósito

Entrar al juego caminando por la nave **intacta e iluminada** (contraste con la partida a oscuras): Ajustes a la izquierda, Mercado a la derecha y el ascensor que lleva a la partida. Reemplaza al `TitleMenu` como entrada (`Main`). Al abrir el juego se muestra con la pantalla de inicio encima (ver `pantalla-titulo.md`).

## Qué hay

- **Sala fija de 360×640**: fondo animado `hub_bg`, espacio por los dos ventanales (shader: se repite, deriva ~3 px/s en una dirección que cambia despacio y rota ~0,25°/s cambiando de sentido cada 20–45 s), reflejo de las lámparas en el vidrio (`LIGHT_ONLY`), paredes de 24 px y techo con el hueco del ascensor pintados por código con el terreno de la nave (sin daño), piso `floor_ship` (fila 0 en y 596), lámparas con su `PointLight2D` y `CanvasModulate` claro (`ambient_color`).
- **Combustible infinito:** el hub recarga el tanque en cada cuadro.
- **Puertas (`HubDoor`):** se abren solas al entrar en el área de 48 px delante y se cierran al salir. Con la puerta abierta, caminar contra la pared 0,15 s entra. Al abrirse iluminan la sala (cian en Ajustes, ámbar en Mercado) con una luz en cono y un haz aditivo, con la intensidad atada a la animación y un titileo leve.
  - **Mercado:** fundido a negro, el jugador se congela y se abre el `Market`; al cerrarlo, fundido y el jugador vuelve delante de la puerta.
  - **Ajustes:** igual, con la pantalla de Ajustes y créditos (`SettingsScreen`, ver `ajustes.md`).
- **Ascensor (`HubElevator`):** plataforma a media pantalla (a ~280 px del piso: no se arranca sin querer) y dos mordazas con baliza. Parado encima 1 s → `arming` (ámbar); si se baja antes vuelve a `idle` (roja, late con el giro). Al completarse: `launched`, las mordazas se sueltan (`open`, verde) y se separan 6 px en 0,24 s; recién entonces se prenden las 4 llamas y la plataforma sube acelerando hasta 400 px/s con el jugador pegado (sin física ni input). La cámara la sigue por el hueco, y ambiente y lámparas se interpolan hacia la oscuridad de la partida. A los 560 px, fundido a negro y `launch_finished`.

## Flujo con `Main`

1. `Main` muestra el `Hub` (`GameManager` en `READY`: R no hace nada).
2. `launch_finished` → `Main` libera el hub, instancia `Level.tscn` (`autostart = false`), llama a `play_intro()` y aclara la pantalla en 0,3 s.
3. Tras ganar o perder, Escape vuelve a un hub nuevo. R repite la partida (intro incluida) sin pasar por el hub.

## Parámetros (`HubConfig`)

| Grupo | Parámetro | Defecto | Unidad | Qué hace |
|---|---|---|---|---|
| Ambiente | `ambient_color` | (0,74; 0,77; 0,84) | color | Oscuridad del hub (más claro que la partida) |
| Ambiente | `ceiling_light_*` | `#E7EFF2`, 0,9, 170 | color, energía, px | Lámparas de techo |
| Ambiente | `wall_light_*` | `#C8E7EA`, 0,5, 90 | color, energía, px | Apliques de pared |
| Ambiente | `fill_light_energy` / `fill_light_radius` | 0,35 / 260 | energía, px | Luz suave general desde abajo |
| Puertas | `door_trigger_width` | 48 | px | Área delante de la puerta que la abre |
| Puertas | `door_enter_push_time` | 0,15 | s | Empuje contra la pared para entrar |
| Puertas | `door_light_energy` / `door_light_range` / `door_light_flicker` | 0,9 / 110 / 0,05 | energía, px, fracción | Luz al abrirse |
| Puertas | `door_beam_alpha` / `door_beam_length` / `door_beam_height` | 0,35 / 80 / 70 | alfa, px, px | Haz visible |
| Puertas | `door_fade_time` | 0,25 | s | Fundido al entrar y salir |
| Ascensor | `elevator_arm_time` | 1,0 | s | Tiempo parado encima para armarlo |
| Ascensor | `clamp_open_offset` / `clamp_open_time` | 6 / 0,24 | px, s | Apertura de las mordazas |
| Ascensor | `elevator_max_speed` / `elevator_accel_time` | 400 / 1,2 | px/s, s | Subida |
| Ascensor | `elevator_ride_distance` | 560 | px | Distancia hasta el fundido |
| Ascensor | `launch_fade_time` | 0,3 | s | Fundido al terminar la subida |
| Ascensor | `beacon_energy` / `beacon_radius` / `beacon_low_energy` | 0,8 / 60 / 0,25 | energía, px | Luz de las balizas |
| Espacio | `space_drift_speed` / `space_drift_turn` | 3 / 0,05 | px/s, rad/s | Deriva |
| Espacio | `space_rotation_speed` / `space_rotation_flip_min` / `_max` | 0,25 / 20 / 45 | °/s, s | Rotación |

## Cómo probarlo

1. F5: aparece el hub iluminado, con el fondo y el espacio moviéndose por los ventanales.
2. Caminar hacia la derecha: la puerta del mercado se abre y tiñe la sala de ámbar. Seguir contra la pared: fundido y mercado. Volver: el jugador queda delante de la puerta.
3. A la izquierda, la puerta de Ajustes se abre (cian) y lleva a Ajustes.
4. Volar hasta la plataforma: tras 1 s parado se arma (ámbar); bajarse la desarma. Quedarse: se sueltan las mordazas, se prenden las llamas, sube con la cámara y arranca la intro de la escotilla.
5. Perder y Escape: vuelve al hub.
