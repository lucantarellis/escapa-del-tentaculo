# Cómo se crean los sprites

Guía para los chats de sprites (Claude con el MCP de Aseprite). Leer completa antes de dibujar.

## Antes de empezar

1. Leer este archivo, `docs/arte/lista-assets.md` (qué falta y de qué tamaño) y `assets/palette.md`.
2. Referencia de estilo: el arte de la nave (`assets/sprites/environment/`, `player/astronaut/`, `tentacle/ship/`).
3. Un chat por categoría de la lista (entorno base, recogibles, peligros del espacio, peligros del alien, meta e intro, UI; astronauta y tentáculo aparte). Si el chat toca otra categoría, avisar antes.

## Rutas

| Qué | Dónde | Git |
|---|---|---|
| Editable final | `C:\Users\lucan\Desktop\Gamedev\escapa-del-tentaculo\assets\aseprite\<ruta>\<nombre>.aseprite` | versionado (lo importa Aseprite Wizard) |
| Borradores y pruebas | `C:\Users\lucan\Desktop\Gamedev\escapa-del-tentaculo\art_src\aseprite\<ruta>\` | ignorado |
| Export PNG (si hace falta) | `C:\Users\lucan\Desktop\Gamedev\escapa-del-tentaculo\assets\sprites\<ruta>\<nombre>.png` | versionado |

- `<ruta>` y `<nombre>` son idénticos en `assets/aseprite/` y `assets/sprites/`.
- Aseprite Wizard (addon de Godot) importa los `.aseprite` con sus tags como `SpriteFrames`. Requiere el addon en `addons/` y la ruta del ejecutable de Aseprite configurada en cada PC.
- Frames temporales, zips y borradores van en `art_src/` y se borran al cerrar el asset. Ejemplo: `art_src/hull_debris/`.
- El MCP trabaja con rutas absolutas de Windows; crear la subcarpeta de `<ruta>` si no existe.
- Nombres en `snake_case`, sin acentos ni mayúsculas.
- No se mueven ni se renombran assets existentes. El astronauta vive en `player/astronaut/` (la carpeta vieja `Astronaut/` se borró).

## Reglas de dibujo

- Un `.aseprite` por asset; las animaciones son tags dentro del mismo archivo.
- Fondo transparente, modo RGBA, sin antialiasing ni semitransparencias, salvo efectos que lo pidan.
- Tamaño del asset: el de `lista-assets.md` (sale de colisiones y variables exportadas). Tiles de 12 px; segmentos de 360×640.
- Solo colores de `assets/palette.gpl`. Al terminar, revisar que no haya colores fuera de la paleta.
- Animaciones: tira horizontal, frames del mismo tamaño y sin separación, como `particle_ember` o `hull_chips`.

## Flujo por asset

1. `create_canvas` con la ruta absoluta del editable y el tamaño exacto.
2. Cargar la paleta y dibujar con `draw_rows` (leyenda con los hex de la paleta). Para piezas grandes, partir en pasadas.
3. `view_sprite` después de cada pasada y corregir.
4. `export_sprite` (PNG, escala 1) a la ruta espejo en `assets/sprites/`.
5. Tildar el asset en `docs/arte/lista-assets.md` y decir en qué escena o script hay que conectarlo. No se editan escenas ni scripts desde este chat.
6. Para que Godot genere el `.import`, abrir el proyecto en el editor; el `.png` y su `.png.import` se commitean juntos.

## Reimportar en Godot

Hay dos caminos, según cómo se conectó el asset:

- **Con Aseprite Wizard** (astronauta y llama en `assets/sprites/player/astronaut/`, mar de tentáculos en `assets/sprites/tentacle/ship/`): son `SpriteFrames` generados (`.res` + PNG) y versionados. Después de guardar el `.aseprite`, en Godot abrir el dock de Aseprite Wizard, elegir el archivo y **Import** con el mismo destino. **"Round FPS" apagado** (si no, cambia la duración de los cuadros). Commitear el `.res` y el PNG juntos. Todo se importa con loop: los tags que se usan una vez los apaga el código (`jump` del jugador; `reach`, `grab`, `retract` del tentáculo).
- **Hojas + JSON de Aseprite** (plataformas, recogibles, fondo, piso, escotilla, ventanal, paredes): el código lee el PNG (y `_normal`, `_emissive`, `_aura` si existen) y el JSON (duración de cada cuadro y tags) por nombre. Exportar con **File > Export Sprite Sheet**, vertical u horizontal como el original, mismo nombre de archivo, JSON en formato Array con `frameTags`. No hace falta tocar escenas ni código mientras no cambien los nombres de los tags ni el tamaño del cuadro.
- **Paredes:** los `.tres` de los tilesets se generan desde `ship_walls_layout.json` con un script fuera del repo; si cambia el arte, regenerarlos desde el chat de arte.

## No hacer

- No sobrescribir un PNG existente: se exporta con otro nombre y se decide el reemplazo aparte.
- No hacer commit ni push. Lo decide LT después de probar en Godot.
- No guardar nada en la raíz del repo ni en carpetas nuevas fuera de `art_src/`, `assets/aseprite/` y `assets/sprites/`.

## Herramientas del MCP

Probadas: `create_canvas`, `draw_rows`, `view_sprite`, `export_sprite`, `get_sprite_info`. Sin probar todavía en este proyecto: `set_palette`, `export_spritesheet`, `set_tag`, `get_color_stats`, `lint_sprite`, `import_image_as_layer`.
