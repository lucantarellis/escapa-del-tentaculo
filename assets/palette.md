# Paleta de colores — Rise or Die

Hay dos juegos de colores y no se mezclan: la **paleta de arte** (para dibujar sprites) y los **colores de placeholder** (los `Polygon2D` del código, que no cambian con el arte final).

## Paleta de arte (52 colores)

Consolidada el 18/11/2026 a partir de cuatro referencias:
- `assets/sprites/environment/fire_platform/`: 20 PNG de pixel art real con 24 colores exactos. Es la referencia de la línea nueva y manda sobre las demás.
- `assets/sprites/player/astronaut_spritesheet.png`, `assets/sprites/environment/scifi_tileset.png` y `assets/sprites/tentacle/tentacle_spritesheet.png`: sprite sheets con ruido (decenas de miles de tonos). Se agruparon por similitud de color sobre los píxeles de primer plano (sin el fondo negro) y se fusionaron los tonos a menos de ΔE 12 (CIELAB) de otro ya elegido.

Archivos para cargar en Aseprite: `assets/palette.gpl` y `assets/palette.hex`. Las columnas de origen indican en qué referencias aparece cada color (a ΔE ≤ 12).

### Base compartida

| Nombre | Hex | Origen |
|---|---|---|
| `negro` | `#050609` | fuego, paleta declarada en las hojas |
| `blanco_azulado` | `#C8E7EA` | astronauta, tileset, paleta declarada en las hojas |
| `brillo` | `#E7EFF2` | astronauta, tentáculo |

### Acero (nave, astronauta, tileset)

| Nombre | Hex | Origen |
|---|---|---|
| `acero_1` | `#0E1632` | astronauta, tileset, tentáculo |
| `acero_2` | `#1C273B` | astronauta, tileset |
| `acero_3` | `#232E52` | tileset |
| `acero_4` | `#324370` | astronauta, tileset |
| `acero_5` | `#4A648D` | tileset, tentáculo |
| `acero_6` | `#6689B7` | astronauta, tileset |
| `acero_7` | `#90AED3` | astronauta, tileset, tentáculo |

### Gris acero (trajes y metal)

| Nombre | Hex | Origen |
|---|---|---|
| `gris_1` | `#364761` | astronauta, tileset, tentáculo |
| `gris_2` | `#577384` | astronauta, tileset |
| `gris_3` | `#B0BBCE` | astronauta |

### Cian (energía, visor, luces)

| Nombre | Hex | Origen |
|---|---|---|
| `cian_1` | `#3A9BBF` | astronauta, tileset, paleta declarada en las hojas |
| `cian_2` | `#63D6C5` | paleta declarada en las hojas |
| `cian_3` | `#89D9EB` | tileset |

### Alien (tentáculo)

| Nombre | Hex | Origen |
|---|---|---|
| `alien_1` | `#110F35` | tileset, tentáculo |
| `alien_2` | `#191146` | tentáculo |
| `alien_3` | `#291C5F` | tentáculo |
| `alien_4` | `#3A2779` | tentáculo |
| `alien_5` | `#533C9A` | tentáculo |
| `alien_6` | `#7E57AE` | tentáculo |
| `alien_7` | `#A781CD` | tentáculo |
| `alien_8` | `#CBAADE` | tentáculo |
| `alien_brillo` | `#B46177` | tentáculo |

### Piedra (plataformas de fuego)

| Nombre | Hex | Origen |
|---|---|---|
| `piedra_1` | `#25162A` | fuego |
| `piedra_2` | `#362041` | fuego |
| `piedra_3` | `#452A56` | fuego |
| `piedra_4` | `#69437E` | fuego |
| `piedra_5` | `#754D8B` | fuego, tentáculo |
| `piedra_6` | `#845A9B` | fuego |
| `piedra_7` | `#9A6AB2` | fuego |

### Fuego y cálidos

| Nombre | Hex | Origen |
|---|---|---|
| `amarillo` | `#FCD51D` | fuego |
| `ambar` | `#F8B842` | astronauta |
| `naranja` | `#FC630D` | fuego |
| `rojo_vivo` | `#F62A19` | fuego |
| `rojo` | `#CD1417` | fuego, astronauta, tileset |
| `ladrillo` | `#A24621` | fuego |
| `oxido` | `#8E3E28` | fuego, astronauta |
| `vino` | `#71373C` | fuego |
| `vino_oscuro` | `#48151C` | astronauta, tileset |

### Tentáculo (carne del perseguidor de la nave)

Agregada el 18/11/2026 para el tentáculo nuevo: mezcla de un tercio entre la rampa `alien_*` y la de acero, más sombría que `alien_*`. Los rojos, ojos y dientes usan colores que ya estaban (`alien_brillo`, `vino`, `vino_oscuro`, `rojo`, `rojo_vivo`, `blanco_azulado`, `brillo`, `ambar`, `amarillo`, `negro`).

| Nombre | Hex | Uso |
|---|---|---|
| `tentaculo_1` | `#101134` | sombra profunda y pliegues |
| `tentaculo_2` | `#1A1842` | sombra |
| `tentaculo_3` | `#27225B` | tono base |
| `tentaculo_4` | `#373076` | medio |
| `tentaculo_5` | `#504996` | luz y filo del borde |
| `tentaculo_6` | `#9184C6` | brillo húmedo |
| `tentaculo_7` | `#B5BAE2` | brillo húmedo (núcleo) |

### Pus y baba

Agregada el 18/11/2026: verde enfermizo para baba, pus y pústulas del tentáculo. Sin contorno.

| Nombre | Hex | Uso |
|---|---|---|
| `pus_1` | `#2E4A14` | sombra de pústula |
| `pus_2` | `#5C8A1C` | pústula |
| `pus_3` | `#9DC42B` | baba |
| `pus_4` | `#D6E86A` | brillo de baba y gotas |

### Qué quedó afuera y qué se fusionó

- Las plataformas de fuego traen tonos casi iguales a los de la paleta: los tres negros (`#020001`, `#050103`, `#0A0209`) pasan a `negro`; `#66417B` a `piedra_4`; `#9E6EB6` y `#9667AF` a `piedra_7`; `#523363` a `piedra_3`; `#5E3B72` a `piedra_4`; `#5A303C` a `vino`; `#1B0918` a `piedra_1`. Los PNG actuales no se tocaron.
- Los acentos que ocupan ~1% o menos de las hojas y quedaron sin color propio: tono piel/crema del astronauta (`#BC8373`, `#F1DFBC`), crema `#F8C57D` y naranja claro `#ED782C`/`#F0742D`. Si hacen falta, se agregan como rampa nueva.
- La paleta del tentáculo que estaba "pendiente de aprobación" (`#3A1B5E`, `#B79FF1`) queda reemplazada por la rampa `alien_*`.
- `piedra_*` (violeta rojizo, de las plataformas de fuego) y `alien_*` (violeta azulado, del tentáculo) se superponen en luminosidad pero tienen tono distinto. Se dejaron las dos porque vienen de assets distintos; si se quiere una sola rampa violeta, hay que decidir cuál manda.

## Colores de placeholder (`Polygon2D`)

Los usa el código y los briefs para comunicar función mientras no hay arte final (ver `docs/CONVENCIONES.md`, sección 3b). No son parte de la paleta de arte, aunque tres coinciden exacto con ella.

| Color | Hex | Significado | En la paleta de arte |
|---|---|---|---|
| Rojo | `#D83232` | Letal | ≈ `rojo` (`#CD1417`) |
| Naranja | `#FF6B32` | Objetivo / meta | ≈ `naranja` (`#FC630D`) |
| Cian | `#63D6C5` | Recogible / bueno | `cian_2` (igual) |
| Azul frío | `#3A9BBF` | Plataformas | `cian_1` (igual) |
| Blanco azulado | `#C8E7EA` | Detalles | `blanco_azulado` (igual) |
| Negro | `#050609` | Contornos y fondo | `negro` (igual) |
