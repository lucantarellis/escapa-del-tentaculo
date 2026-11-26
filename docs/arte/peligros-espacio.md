# Peligros del espacio (tier 2)

Arte cerrado el 24/11/2026. Reemplaza los placeholders dibujados por código de `SpaceProjectile` (meteoro, cometa), `DebrisField` y `SatelliteLaser` (hoy `LaserTentacle`). Editables en `assets/aseprite/hazards/`; PNG y JSON en `assets/sprites/hazards/`. Arte nítido: brillos, haces y estelas los pone Godot (aditivos, partículas, `PointLight2D`).

## Tentáculo láser (reemplaza al satélite) — `laser_tentacle`

Decisión de LT: en lugar de satélites, **puntas de tentáculo del alien que asoman por los costados**, terminan en **un ojo**, buscan al jugador, lo fijan entrecerrando el ojo hasta que brilla y disparan el láser. Tallo delgado y anillado (violetas del tentáculo), sin ojos ni bocas en el cuerpo, con una onda que lo recorre.

- Lienzo 150×170; capas `color` y `emissive`; hoja en filas de 16 cuadros + `.json`.
- **Dibujado entrando desde el borde derecho**: la base está en **(149, 85)** del lienzo (pegada al borde de la pantalla). Para el borde izquierdo, espejar en horizontal (`flip_h`) y usar el ángulo espejado (180° − ángulo).
- Ángulos con la convención del código (0 = derecha, 90 = abajo): de **150° a 210° cada 5°** (13 ángulos). Mostrar el tag del ángulo más cercano al barrido actual.

| Tag | Cuadros | Uso (estado de `LaserTentacle`) |
|---|---|---|
| `emerge` | 8 × 80 ms | Al entrar en la vista: asoma con el ojo cerrado y lo abre (en 180°). Al irse, reproducir al revés. |
| `aim_150` … `aim_210` | 8 × 100 ms, bucle | AIM: ojo bien abierto, la onda recorre el tallo. Cambiar de tag según el ángulo del barrido, manteniendo el número de cuadro para que la onda no salte. |
| `lock_150` … `lock_210` | 6 × 70 ms | LOCK: el ojo se achica hasta una ranura que se carga (rojo → naranja → amarillo) y el tallo se encoge. Si `lock_time` dura otra cosa, estirar o recortar. |
| `fire_150` … `fire_210` | 6 × 80 ms | FIRE: ranura incandescente y retroceso. El haz sale de la boca del ojo. |
| (COOLDOWN) | — | Reproducir `lock_<ángulo>` al revés (el ojo se reabre) y volver a `aim`. |

- **Origen del haz:** `laser_tentacle_muzzle.json` tiene, por cuadro, la posición del ojo relativa a la base (`muzzle_per_frame[i]`, en px). El haz (núcleo `#FFE0D6`, borde rojo, resplandor) y el brillo de carga los dibuja Godot como hoy, desde ese punto.
- La línea de apuntado punteada sigue por código.
- El emisivo tiene solo el iris y el brillo del ojo.
- **Implementado (brief 10, paso 4a):** `LaserTentacle` (`scripts/hazards/laser_tentacle.gd`, `scenes/hazards/LaserTentacle.tscn`) con la hoja cargada por `HazardSheet`. La base del tentáculo va en el nodo, que se coloca en el borde de la pantalla (x = 0 o 360); el ojo de `muzzle_per_frame` es el origen del haz y del brillo de carga (aditivos, sin sombrear). El emisivo va en un `Sprite2D` sin sombrear.

## Meteoro — `meteor_head`

Roca chica del mismo marrón que los asteroides con la cara delantera incandescente. 24×24, capas `color` y `emissive`, tag `dir` con **16 cuadros = 16 direcciones** (cuadro k = dirección k × 22,5°, 0 = derecha, sentido horario en pantalla). Elegir el cuadro según la dirección de `travel`; no girar el sprite.

- **Implementado (brief 10, paso 4b):** `SpaceProjectile` con el grupo `Arte` (`head_sheet`, `directional_head`, `particle_sheet`, `glow_color`); el sprite de la cabeza no gira con el nodo.
- **Estela:** `CPUParticles2D` en espacio global, partículas de `particle_ember` (3×3, 4 cuadros = edad: amarillo → naranja → rojo → oscuro; `CanvasItemMaterial` con animación de partícula), soltadas detrás de la cabeza con algo de dispersión; más un resplandor aditivo naranja en la cabeza. Largo similar a `trail_length` (90 px).

## Cometa — `comet_head`

Núcleo de hielo azul y blanco. 24×24, capas `color` y `emissive`, tag `twinkle` (4 × 120 ms, bucle; destellos de hielo). No depende de la dirección.

- **Cola:** igual que la estela del meteoro pero con `particle_ice` (blanco → cian → azul) y más larga (~150 px). Recordar que la cola mata (`trail_lethal`): la colisión sigue siendo la de hoy.

## Campo de escombros — `debris_fragment`

Fragmentos de las mismas chapas que los restos a la deriva. 28×28, 6 diseños: tags `frag1` … `frag6`, cada uno con **36 cuadros = un giro completo cada 10°**. Cada trozo que orbita usa un diseño al azar y avanza de cuadro según su giro (no rotar el sprite). Los cuadros giran en sentido antihorario. **Implementado (brief 10, paso 4c):** `DebrisField` con un `Sprite2D` por trozo.

## Perseguidor de fuego — `fire_explosion`

Arte cerrado el 25/11/2026. El fuego de la nave que explota y sube persiguiendo al astronauta: **un frente de explosiones siempre en erupción** y, debajo, **un relleno lleno de explosiones que un degradado lava hasta el rojo plano**. Sin línea recta visible entre el frente y el relleno. Generador y maquetas en `art_src/fuego_perseguidor/v3/` (`expl3.py`, `mock4.py`, `mock4_x2.gif` = cómo se tiene que ver).

- Lienzo **84×76**, capas `color` y `emissive` (emisivo: solo fuego y brasas, sin humo). Hoja en filas de 16 cuadros + `.json` (Array con `frameTags`).
- **Pivote común (42, 40)**: centro del estallido en todas las variantes (en `d`, centro del conjunto). Se pueden espejar en horizontal (`flip_h`) al azar; no girar.

| Tag | Cuadros | Uso |
|---|---|---|
| `a` | 10 (50→120 ms, ~900 ms) | Frente. Mediana, cargada arriba-izquierda. Termina en humo que se desarma. |
| `b` | 10 (~900 ms) | Frente. Ancha y baja. |
| `c` | 8 (40→100 ms, ~590 ms) | Frente. Chica y rápida, rellena huecos. |
| `d` | 13 (~1,1 s) | Frente. Doble: segundo estallido 3 cuadros después, arriba-derecha. |
| `a_fill`, `b_fill`, `c_fill` | 5, 5, 4 | Relleno. Mismas explosiones sin motas de humo, cortadas antes del humo: se reproducen una vez y **se sostiene el último cuadro**. |

**Humo violeta — `fire_smoke`:** banda de humo detrás del frente (ambientación). Lienzo **80×60**, una capa `color` (sin emisivo), rampa `piedra_*`. Tags `a` (ancha), `b` (media), `c` (chica), 12 cuadros × 130 ms cada uno (~1,56 s, una vez): crece, sube y se apaga bocanada por bocanada. **Pivote común (40, 36).** Espejar al azar. Hoja en filas de 12 + `.json`.

**Ensamblado (valores de la maqueta, a ajustar en juego):**

**Todo se mide desde el borde del fuego** (el borde superior del perseguidor), no desde la pantalla: emisores, relleno, rojo plano, lavado y humo son hijos del nodo del perseguidor. Así funciona a cualquier altura: con el fuego lejos, el borde está debajo de la pantalla; cuando alcanza al astronauta, el borde sube y puede pasar el borde superior de la pantalla (se ve todo fuego lavado). Por eso el rojo plano tiene que llegar desde el borde hasta más allá de la parte de abajo de la pantalla en cualquier caso (por ejemplo, 1000 px de alto).

1. **Frente:** se mueve con el perseguidor. Cada 50 ms nacen 2–3 explosiones `a`/`b`/`c`/`d` (pesos 35/25/25/15), repartidas en 14 franjas a lo ancho (barajar las franjas para que no queden huecos), con el pivote entre 8 px arriba y 16 px abajo del borde; un 15% nace 14–26 px más arriba. Se hunden 20–45 px/s respecto del borde. Las más nuevas se dibujan encima. **Los cuadros de humo** (desde el cuadro 7 de `a`/`b`, 6 de `c`, 10 de `d`) se dibujan **detrás** de la capa de relleno.
2. **Relleno:** cada 50 ms nacen 3 explosiones `*_fill` (pesos `a` 35, `b` 40, `c` 25) en x al azar (−20 a 380), 8–50 px debajo del borde. Se dibujan **detrás** de las anteriores (las nuevas, al fondo). Quedan fijas en el mundo (no siguen al perseguidor): respecto del borde se hunden a la velocidad del perseguidor, con ±15% de variación para que no se muevan en bloque (en la maqueta, 80–110 px/s). Se liberan a 330 px del borde.
3. **Rojo plano** `#CD1417` desde 12 px debajo del borde hasta el fondo de la pantalla.
4. **Lavado:** overlay de color `#CD1417` sobre frente + relleno, con alpha en degradado (smoothstep) de 0 a 12–14 px bajo el borde a 1 a ~185 px. Reemplaza el degradado oscuro anterior.
5. **Glow** aditivo naranja con la capa `emissive` (y/o `PointLight2D` en el frente para iluminar asteroides con relieve). Filtro nearest.
6. En la maqueta la cámara sube a 120 px/s: el efecto de velocidad lo dan el fondo y las plataformas que pasan y el relleno que se queda atrás.
7. **Humo violeta:** cada 50 ms, con 75% de probabilidad, nace un `fire_smoke` (`a`/`b`/`c` al azar) en 9 franjas de 40 px barajadas, con el pivote 2–22 px **arriba** del borde. Sube 6–16 px/s respecto del borde (se mueve con el perseguidor). Va **detrás de todo** el fuego (humo marrón, relleno y frente) y no lleva lavado.
8. Con el borde fuera de la pantalla por abajo (más de ~100 px), se pueden pausar los emisores para ahorrar; al volver a acercarse, precargar ~1 s para que el muro aparezca lleno.

## Pantallas de derrota

El fuego necesita causa propia `fire` (CALCINADO; hoy mata con `tentacle`). Las causas `laser`, `meteor`, `comet` y `debris_field` todavía muestran el texto viejo; sus viñetas van con las pantallas de derrota del tier 2.
