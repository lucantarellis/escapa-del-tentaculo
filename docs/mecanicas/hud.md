# Mecánica: HUD mínimo (combustible y progreso)

**Archivos:** `scenes/ui/Hud.tscn`, `scripts/ui/hud.gd` (`Hud`, `CanvasLayer` capa 80).
**Depende de:** `Player.fuel_changed`, `fuel_depleted`, `fuel_refilled`, `get_fuel_ratio()`, `is_fuel_empty()` y la posición del jugador; `LevelController` (le asigna el rango de progreso y lo muestra).

## Propósito

Mostrar, de forma muy discreta, cuánto combustible queda y cuánto falta para la puerta. Es de **solo lectura**: nunca modifica el juego. Sin números ni etiquetas.

## Qué muestra

- **Barra de combustible** (borde izquierdo, vertical, 5 px de ancho, 200 px de alto, centrada): crece hacia arriba y representa `Player.get_fuel_ratio()`. Es **naranja `#FF6B32`** con combustible y **roja `#D83232`** cuando está vacío (mismos colores que el cuerpo del jugador). Se actualiza con `fuel_changed`; el color cambia con `fuel_depleted` / `fuel_refilled`.
- **Progreso del nivel** (borde derecho, línea vertical de las mismas medidas): un marcador blanco azulado `#C8E7EA` sube desde abajo (0 %, el spawn) hasta arriba (100 %, la puerta), donde hay una marca naranja `#FF6B32`.

Todo con opacidad 0,7 (fondos de barra más tenues). Los valores son `const` visuales en `hud.gd`; no hay valores de gameplay, por eso no tiene `Resource` de configuración.

## Cómo se calcula el progreso

```
progreso = clamp((start_y − player.global_position.y) / (start_y − end_y), 0, 1)
```

`start_y` es la Y global del spawn y `end_y` la de la puerta (Y crece hacia abajo, así que subir reduce la Y). El `LevelController` lo fija tras armar el nivel con `Hud.set_progress_range(start_y, end_y)`: en `Level.tscn`, la Y del jugador en el spawn y la de la puerta del segmento final; en el sandbox, la Y inicial del jugador y la de `GoalDoor`. Bajo el spawn vale 0. Se recalcula en `_process`.

## Cuándo se ve

- **No** aparece en el título: con `autostart = false` el `LevelController` lo oculta y lo muestra en `begin()`.
- Durante la partida está visible. Tras ganar o perder queda visible (congelado) por debajo del mensaje de fin (capa 90).
- Con R (con `Main`) se reconstruye el nivel entero, así que el HUD arranca de cero (combustible según `starting_fuel`, progreso 0). En `Level.tscn` y `sandbox.tscn` también hay HUD.

## API pública

| Elemento | Descripción |
|---|---|
| `player` (`@export`) | Jugador a observar, asignado desde la escena que instancia el HUD |
| `set_progress_range(start_y, end_y)` | Fija el rango del progreso (Y globales del spawn y de la puerta) |
| `get_progress() -> float` | Progreso actual 0..1 |
| `get_fuel_ratio() -> float` | Proporción de combustible mostrada 0..1 |
| `get_fuel_color() -> Color` | Color actual de la barra de combustible |

## Cómo probarlo

1. F5 → JUGAR: aparecen las dos barras a los costados. En el título no se ven.
2. Propulsar: la barra izquierda baja; al vaciarse se pone roja; al recoger un tanque vuelve a naranja y sube.
3. Subir: el marcador de la derecha avanza y llega arriba al alcanzar la puerta.
4. Ganar o perder: el HUD queda debajo del mensaje. R reinicia con la barra llena y el progreso en 0.
5. F6 sobre `Level.tscn` y sobre `sandbox.tscn`: el HUD también aparece.
