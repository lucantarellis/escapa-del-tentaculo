# Mecánica: HUD "pantalla del traje" (combustible, progreso, monedas y vida)

**Archivos:** `scenes/ui/Hud.tscn`, `scripts/ui/hud.gd` (`Hud`, `CanvasLayer` capa 80). Arte: `assets/sprites/ui/hud/` (especificación en `docs/arte/hud.md`). Fuente: Tiny5 (`assets/fonts/`, SIL OFL), importada sin antialiasing ni hinting.
**Depende de:** `Player.fuel_changed`, `fuel_depleted`, `fuel_refilled`, `hit_points_changed`, `shield_changed`, `get_fuel_ratio()`, `is_fuel_empty()`, `has_shield()` y la posición del jugador; `Tentacle.is_active()` y su posición; `PlayerProgress.run_coins_changed`; `LevelController` (le asigna el rango de progreso, el récord y los tiers, y lo muestra).

## Propósito

Mostrar, de forma discreta y con estética de display del traje, cuánto combustible queda, cuánto falta para la puerta, dónde está el tentáculo, las monedas y la integridad del traje. Es de **solo lectura**: nunca modifica el juego. Único número: las monedas.

## Qué muestra

- **Combustible** (borde izquierdo): `TextureProgressBar` vertical (`hud_fuel_under/progress/over`, 11×206; área útil de 5×200 en x 6, centrada en alto). Crece hacia arriba con `Player.get_fuel_ratio()`. Con el tanque vacío el relleno pasa a `hud_fuel_progress_empty` (rojo). Ícono `fuel` debajo.
- **Progreso** (borde derecho, mismas medidas): `TextureProgressBar` con `hud_progress_under/danger/over`. El relleno **rojo sube desde abajo hasta el tentáculo** (`get_tentacle_progress()`), sin ondulación; vacío mientras el tentáculo está inactivo (intro). Ícono `goal` arriba (la puerta).
- **Marcadores** a la izquierda de la barra de progreso, cada uno centrado en su altura y con una **línea de 1 px que cruza la barra** (desde 3 px a su izquierda hasta su borde derecho):
  - `player`: línea `#E7EFF2` (encima de todo).
  - `skull`: en el borde del rojo, línea `#F62A19`. Solo con el tentáculo activo.
  - `record`: línea `#63D6C5` punteada (1 px sí, 1 no). Solo si hay récord.
  - **Tiers:** línea `#C8E7EA` dentro de la barra + 2 px afuera a la derecha, en cada Y de `set_tier_marks` (cualquier cantidad).
- **Monedas** (arriba a la izquierda): ícono `coin` (18×18) en (6, 6) y el número de monedas juntadas en la partida con Tiny5 16 px `#89D9EB` y sombra de 1 px `#050609`; borde superior de los dígitos en (27, 12). Sigue a `PlayerProgress.run_coins_changed`; se oculta con el progreso apagado. Ver `progreso-mercado.md`.
- **Vida** (debajo de la moneda, y 28): una celda `cell_full` / `cell_empty` (11×8, cada 13 px) por punto de golpe máximo, solo si el máximo es mayor que 1. Al perder una, parpadea 3 veces antes de quedar vacía. Siguen a `Player.hit_points_changed`.
- **Escudo:** ícono `shield` a continuación de las celdas (+2 px; en su lugar si no se ven) mientras está activo (`Player.shield_changed`).
- **Enfriamiento del dash:** no es parte del HUD; lo dibuja `DashCooldownBar` sobre el jugador con `hud_dash_under/progress` (18×5, de izquierda a derecha). Ver `jugador.md`.

Barras, íconos y líneas con opacidad 0,7 (`HUD_ALPHA`); monedas, celdas y escudo 0,9 (`STATUS_ALPHA`). Todo a 1× con filtro nearest. Los valores son `const` visuales en `hud.gd`; no hay valores de gameplay, por eso no tiene `Resource` de configuración.

## Cómo se calcula el progreso

```
progreso = clamp((start_y − player.global_position.y) / (start_y − end_y), 0, 1)
```

`start_y` es la Y global del spawn y `end_y` la de la puerta (Y crece hacia abajo, así que subir reduce la Y). El `LevelController` lo fija tras armar el nivel con `Hud.set_progress_range(start_y, end_y)`: en `Level.tscn`, la Y del jugador en el spawn y la de la puerta del segmento final. Bajo el spawn vale 0. Se recalcula en `_process`.

## Cuándo se ve

- **No** aparece en el título: con `autostart = false` el `LevelController` lo oculta y lo muestra en `begin()`.
- Durante la partida está visible. Tras ganar o perder queda visible (congelado) por debajo del mensaje de fin (capa 90).
- Con R (con `Main`) se reconstruye el nivel entero, así que el HUD arranca de cero (combustible según `starting_fuel`, progreso 0). En `Level.tscn` (F6) también hay HUD.

## API pública

| Elemento | Descripción |
|---|---|
| `player` (`@export`) | Jugador a observar, asignado desde la escena que instancia el HUD |
| `tentacle` (`@export`) | Tentáculo a observar para el relleno rojo y la calavera (opcional) |
| `set_progress_range(start_y, end_y)` | Fija el rango del progreso (Y globales del spawn y de la puerta) |
| `set_record(progress)` | Muestra el marcador del récord (0..1; 0 = sin récord) |
| `set_tier_marks(ys)` | Marcas donde empieza cada tier (Y globales de `LevelBuilder.get_tier_starts()`) |
| `get_progress() -> float` | Progreso actual 0..1 |
| `get_tentacle_progress() -> float` | Altura del tentáculo en la barra de progreso, 0..1 |
| `get_fuel_ratio() -> float` | Proporción de combustible mostrada 0..1 |
| `is_fuel_shown_empty() -> bool` | true si la barra muestra el relleno rojo de tanque vacío |

## Récord y tiers

- **Récord:** lo guarda `RunRecords` (`scripts/managers/run_records.gd`) en `user://records.cfg` al terminar cada partida. Si la partida lo supera, el mensaje de fin agrega "NUEVO RÉCORD" y el marcador se mueve. Como todo segmento mide 640 px, el progreso de partidas distintas es comparable. `RunRecords.clear()` lo borra (pruebas).
- **Tiers:** una marca por cada Y que pase el `LevelController` (hoy, donde empieza cada tier salvo el primero).

## Cómo probarlo

1. F5 → JUGAR: aparecen las dos barras con sus íconos; en el título no se ven.
2. Propulsar: el combustible baja; vacío se pone rojo; al recoger un tanque vuelve a naranja.
3. Subir: el ícono del jugador y su línea suben por la barra de la derecha.
4. Tras la intro: el rojo sube desde abajo con el tentáculo y la calavera queda en su borde.
5. Con mejoras de vida: las celdas se ven; al recibir un golpe, la celda parpadea y queda vacía. Con el escudo del botiquín aparece el ícono al lado.
6. Dash: la barrita sobre el personaje se llena durante el enfriamiento.
