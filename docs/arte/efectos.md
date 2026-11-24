# Efectos: gas, escudo, reparación, reaparición y fuga del traje

Editables en `assets/aseprite/fx/`, exportados en `assets/sprites/fx/`. Solo colores de la paleta. Las tiras son horizontales; las de jugador traen `.json` con duraciones y tags. Las capas `emissive` son copia del color (todo el efecto brilla).

## Gas de la escotilla
- `gas_puff.aseprite` (14×14, tags `puff_a`, `puff_b`, `puff_c`, 4 cuadros c/u) → `gas_puff_a.png`, `gas_puff_b.png`, `gas_puff_c.png` (56×14).
- Tres formas: redonda, alta y ancha de dos lóbulos, con distintos tamaños. Cada tira es la vida de una bocanada: nace densa, crece, se ralea con tramado, queda en un hilo.
- Godot: **3 `CPUParticles2D`** (uno por forma) en `Hatch.tscn`, repartiendo `gas_amount`. Cada uno con su textura y `CanvasItemMaterial` con `particles_animation = true`, `particles_anim_h_frames = 4`, `particles_anim_loop = false`, `anim_speed_min/max = 1` (recorre los 4 cuadros en la vida de la partícula). `scale_amount = 1` (no escalar: deforma el pixel art). El desvanecimiento sigue con `color_ramp`.

## Escudo
- `player_shield.aseprite` (54×74; óvalo de 38×58 centrado) → `player_shield.png` / `_emissive.png` / `.json`.
- Tags: `loop` (1–8, 90 ms, bucle: brillo que gira por el borde) y `pop` (9–13, 60 ms, una vez: destello y el aro se parte en trozos que salen).
- Godot: `AnimatedSprite2D` centrado en `SHIELD_CENTER` del jugador, reemplaza al `Line2D`. `loop` mientras dura; `pop` al absorber un golpe o al vencer; el parpadeo previo a vencer sigue por código (`SHIELD_BLINK_TIME`).

## Reparación
- `player_repair.aseprite` (32×40, misma celda que el astronauta) → `player_repair.png` / `_emissive.png` / `.json`. Tag `repair` (9 cuadros, ~0,7 s): cruz cian con destello que sube, 12 chispas ámbar→naranja y 5 crucecitas que suben.
- Godot: `AnimatedSprite2D` en la misma posición que `Body/Sprite` ((0,−8)), una vez por cada `heal()` con resultado > 0.
- **Shader sobre el cuerpo** (sin arte), 0,6 s: una banda cian `#89D9EB` de 3 px que recorre el sprite de abajo hacia arriba, y en los primeros ~0,15 s un tinte `#63D6C5` en tramado (píxel sí, píxel no). Uniform `progress` 0→1 animado con tween.

## Reaparición (mejora "Reaparecer")
- `player_respawn.aseprite` (32×56; las 40 filas de abajo coinciden con la celda del astronauta) → `player_respawn.png` / `_emissive.png` / `.json`.
- Tags: `vanish` (1–6, 60 ms): destello vertical que se cierra con chispas, en el lugar donde el jugador habría muerto. `respawn` (7–14, 70 ms): haz que baja, se abre un aro en los pies y se cierra.
- Godot: ambos a (0,−16) respecto del jugador. Al `respawned`: `vanish` en la posición vieja (nodo suelto en el nivel) y `respawn` en la nueva; el astronauta aparece con fundido de alfa desde el 3.er cuadro de `respawn` (por código).

## Fuga del traje (a 1 punto de golpe)
Sin arte nuevo: reutiliza `gas_puff_a/b/c`.
- Activa mientras `hp == 1` (y no muerto); se apaga al curarse.
- **Dirección al azar en 360°** alrededor del centro del cuerpo (≈ (0, −8) del jugador): en cada ráfaga se elige un ángulo nuevo, a **más de 60°** del anterior para que no repita la zona. El punto de salida va en el borde del traje: centro + (10·cos θ, 13·sin θ). Las partículas salen en ese ángulo ±15°.
- Un solo `CPUParticles2D` que se reposiciona y reorienta (`position`, `direction`) antes de cada ráfaga.
- Ráfagas cortas tipo "fsss": 2–4 partículas cada 0,5–0,9 s (al azar), vida 0,4 s, velocidad 40–70 px/s con `damping` alto, `local_coords = false`.
- Para que no se vea igual que la escotilla: **shader de recolor** (por color exacto) `#6689B7→#3A9BBF`, `#90AED3→#89D9EB`, `#C8E7EA→#E7EFF2` (gas más frío y brillante), y animación más rápida (vida corta).
