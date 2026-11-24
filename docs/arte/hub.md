# Hub (menú navegable)

La nave **intacta** (sin ataque) como menú: el jugador camina y vuela con el jetpack. Ajustes a la izquierda, Mercado a la derecha, plataforma-ascensor a media pantalla que lleva a la partida. Este documento se completa a medida que se cierra el arte de cada parte.

## Puertas (Ajustes y Mercado)

Editables: `assets/aseprite/environment/hub_doors/door_settings.aseprite`, `door_market.aseprite`.
Exportadas: `assets/sprites/environment/hub_doors/door_{settings,market}.png`, `_emissive.png`, `_normal.png` (tiras horizontales de 16 cuadros de 25×125) y `.json` (duraciones y tags).

### Forma
- Puerta en **perspectiva 2,5D**, metida en la pared lateral: ocupa 24 px de ancho de pared. La de Ajustes va en la pared izquierda; la del Mercado es su espejo en la derecha.
- Ajustes: marco cercano (alto) a la izquierda, dentro de la pared; marco lejano (bajo) contra el borde interno de la pared.
- Base: el marco cercano apoya en la **línea de adelante** del piso y el lejano en la **línea de atrás** (la cara superior de `floor_ship` mide 14 px). El triángulo bajo la base usa las mismas filas de color que el piso: no hay costura.
- Cartel en la misma cara y perspectiva, encima de la hoja: engranaje (Ajustes) y moneda del HUD (Mercado). Si cambia la moneda, regenerar el cartel.
- LED de estado en la esquina del cartel.

### Ensamblado
- **Ajustes:** la columna 24 del sprite es la primera columna fuera de la pared (borde interno). La fila **110** del sprite coincide con la fila 0 (borde de atrás) de `floor_ship`.
- **Mercado:** espejo: la columna 0 es la primera fuera de la pared derecha; misma fila 110.
- La pared del hub tiene que tener al menos 24 px de ancho a la altura de las puertas.
- Capas: `color` como textura, `normal` como mapa de relieve (`CanvasTexture`, mismo criterio que paredes y plataformas) y `emissive` sin oscurecer (cartel, LED, hueco iluminado).

### Tags
| Tag | Cuadros | Duración | Uso |
|---|---|---|---|
| `closed` | 1–2 | 600 ms c/u, bucle | LED rojo latiendo |
| `opening` | 3–8 | 60 ms c/u (0,36 s) | la hoja sube; LED ámbar titila; el hueco se ilumina desde abajo |
| `open` | 9–10 | 400 ms c/u, bucle | hueco iluminado (cian en Ajustes, ámbar en Mercado); LED verde |
| `closing` | 11–16 | 60 ms c/u | inverso de `opening` |

### Comportamiento (código)
- Se abre sola cuando el jugador entra en un área de ~48 px delante de la puerta (y en el piso); se cierra al salir del área.
- **Entrar:** con la puerta abierta, si el jugador sigue caminando hacia la pared (input hacia la pared ~0,15 s contra el borde), fundido a negro y se abre Ajustes o Mercado.

### Iluminación al abrir (todo en Godot, sin arte)
Misma lógica que la luz de la escotilla (brief 08, sección 1): luz real + haz visible aditivo, con la intensidad atada al estado.
- **Color:** Ajustes `#89D9EB` (cian); Mercado `#F8B842` (ámbar).
- **`PointLight2D`** en el centro del hueco, desplazada ~10 px hacia el centro de la sala, con textura de **cono horizontal** hacia la sala (`GradientTexture2D` radial recortado, ~70° de apertura) que ilumine el piso, el astronauta y la pared de enfrente cercana. Sombras opcionales.
- **Haz visible:** `Sprite2D` con `CanvasItemMaterial.blend_mode = ADD`, degradé suave generado en Godot (trapecio que sale del hueco, se abre hacia el centro y cae sobre el piso, alfa de 0,35 en la puerta a 0 a ~80 px). Puede llevar el mismo desenfoque/niebla que el fondo.
- **Curva de intensidad:** `closed` 0; `opening` sube de 0 al máximo siguiendo la hoja (0,36 s); `open` máximo con un leve titileo (±5 %, lento); `closing` baja a 0 en 0,36 s.
- Valores (energía, alcance, alfa del haz) en el `LightingConfig` o en un config del hub.

## Sala del hub, ascensor y transición a la partida

Pantalla fija de **360×640** (cámara quieta mientras el jugador está en el hub).

### Armado (coordenadas de pantalla)
- **Fondo:** `hub_bg` (360×640, 24 cuadros de 100 ms, tag `ambient` en bucle; capas color y emisiva). Capa lejana de la nave con su animación de luces + máquinas sanas de la capa media (cápsula con burbujas, consolas con datos/onda/LED, puerta con franjas y luz que titila), **sin fuegos ni daño**. Va en (0,0), detrás de todo lo demás del hub; el emisivo encima sin oscurecer. Los huecos de los ventanales son transparentes.
- **Ventanales:** `hub_window` (88×340; color + normal) en **(31, 46)** y **(241, 46)**: llegan desde y 386 hasta justo abajo de las lámparas del techo. Vidrio transparente con borde cian y un brillo chico en la esquina.
  - **Reflejo de las lámparas:** `hub_window_glass` (78×330, tramado cian muy ralo) en (36, 51) y (246, 51), con `CanvasItemMaterial.light_mode = LIGHT_ONLY`: solo se ve donde llegan las luces de las lámparas, como reflejo en el vidrio.
  - **Espacio detrás:** `hub_space` (1600×1200, **se repite sin costura en las 4 direcciones**): nebulosas violeta/azul/rosada, planeta con anillos, gigante gaseoso, sol, lunas y planetas chicos, galaxia espiral, cinturón de asteroides, cometa. Se dibuja detrás de los huecos (un `ColorRect`/`TextureRect` de pantalla completa detrás del fondo, o recortado a los ventanales) con un **shader** que: (1) repite la textura (`repeat_enable`, filtro nearest); (2) aplica una **deriva** en una dirección que cambia despacio (velocidad ~3 px/s, ángulo que vaga con ruido o seno lento), y (3) **rota** la vista muy lento (≈1° cada 3–5 s, cambiando de sentido cada tanto). La rotación va en el shader (rotar UV), no rotando un sprite, para no dejar huecos ni bordes serruchados. Los dos ventanales muestran la misma escena (una sola vista detrás de la pared).
- **Paredes:** 24 px de ancho (x 0–23 y 336–359), del techo al piso, pintadas con el tileset de la nave **sin daño** (sin capas `Dano`). El ancho coincide con el de las puertas.
- **Techo:** franja de pared de y 0–35 entre x 24–131 y 228–335; **hueco del ascensor** en x 132–227 (96 px) que sigue hacia arriba.
- **Piso:** `floor_ship` de lado a lado, con su fila 0 (borde de atrás) en **y 596**.
- **Puertas:** ver arriba (Ajustes a la izquierda, Mercado a la derecha), fila 110 del sprite en y 596.
- **Rieles del ascensor:** `elevator_rail.png` (6×24, se repite en vertical) en **x 126** y **x 228**, desde y 0 hasta el piso; `elevator_rail_base.png` (12×5) al pie de cada uno en (123, 598) y (225, 598).
- **Lámparas** (solo emisivo de arte; la luz la pone Godot): `lamp_ceiling.png` (58×5) bajo el techo en (52, 36) y (250, 36); `lamp_wall.png` (5×10) en la pared izquierda en x 24, y 150 / 300 / 450, y espejada en la derecha en x 331.

### Ascensor
- **Plataforma** `elevator_platform` (80×24; capas color, normal, emisiva): en reposo con su esquina superior izquierda en **(140, 316)** (centrada, a media pantalla). Colisión: la de una plataforma estática de 80 px (tapa de 12 px). Debajo lleva 4 toberas en x 12, 28, 46, 62 (locales), y 17.
  - Tags: `idle` (1–2, LED apagados), `arming` (3–10, 125 ms c/u: la tira de 8 LED se llena de ámbar en 1 s), `launched` (11, LED verdes).
- **Mordazas del muelle** `elevator_clamp` (18×32; capas color, normal, emisiva), con **baliza giratoria** arriba y franjas de peligro: izquierda en **(122, 300)**; derecha **espejada** en **(220, 300)**.
  - Tags: `idle` (1–8, 100 ms, bucle: baliza **roja** girando, llama la atención hacia el ascensor), `arming` (9–16, 60 ms, bucle: baliza **ámbar** más rápida), `open` (17: baliza **verde** fija, mordaza suelta).
  - **Luz de la baliza (Godot):** `PointLight2D` en cada baliza (≈ 7 px desde el borde exterior, 10 px por encima de la plataforma), radio ~60 px, del color del estado: roja que **late con el giro** (fuerte en los cuadros 1–5 del ciclo, baja en 6–8), ámbar constante al armarse, verde al soltar.
- **Llamas:** se reutiliza `platform_thruster` (4 `AnimatedSprite2D` en las toberas, esquina superior izquierda en (x, 17) locales). Solo durante la subida.

### Secuencia (código)
1. El jugador llega a la plataforma con el jetpack (está a ~280 px del piso, a propósito: no se arranca una partida sin querer).
2. **Parado encima ~1 s** → `arming`. Si se baja antes, vuelve a `idle` (la tira se vacía).
3. Al completar: `launched`; las mordazas pasan a `open` y **se separan con transición**: tween de 6 px hacia afuera en 0,24 s (ease-out), no de golpe. Recién cuando terminan de abrirse se prenden las 4 llamas y la plataforma arranca.
4. La plataforma sube acelerando (ease-in hasta ~400 px/s) con el jugador encima (bloquear input). La **cámara la sigue** por el hueco; las luces del hub quedan abajo y el ambiente pasa a la oscuridad de la partida.
5. Al llegar al nivel de la escotilla, fundido corto y arranca la intro (golpes) en el piso de inicio, como hoy.

### Iluminación del hub (Godot)
- La nave está intacta y **iluminada**, para contrastar con la partida a oscuras: `CanvasModulate` del hub mucho más claro que `dark_ambient` (p. ej. ~70–80 % de brillo, levemente frío) y menos niebla sobre el fondo.
- `PointLight2D` por lámpara (las lámparas del arte son solo el emisivo): techo `#E7EFF2` (radio ~170 px), apliques `#C8E7EA` (radio ~90 px, más tenues); una luz suave general desde abajo-centro. Estas luces son las que se reflejan en el vidrio de los ventanales (`hub_window_glass`).
- Al subir el ascensor, interpolar ambiente y luces hacia los valores de la partida.
- Valores en un config del hub (`hub_config.tres` o en `LightingConfig`).
