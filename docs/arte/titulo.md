# Pantalla de inicio y logo

## Logo "RISE OR DIE"
- Editable: `assets/aseprite/ui/title/title_logo.aseprite` (360×206, 38 cuadros). Capas: `tentacles_back` (incluye la masa de humo), `letters`, `tentacles_front`. Tags: **`emerge`** (1–14, 70 ms: 4 cuadros en que aparece el humo + 10 en que los tentáculos suben desde adentro del humo, frenando) e **`idle`** (15–38, 100 ms, bucle de 2,4 s). El último cuadro de `emerge` empalma con el primero de `idle` (el balanceo sigue sin salto).
- Exportados en `assets/sprites/ui/title/` (tres sprites que Godot anima por separado, mismo origen y mismo tamaño de cuadro 360×206):
  - `title_tentacles_back.png` + `.json` (tags `emerge`, `idle`) — se dibuja **detrás** de las letras.
  - `title_letters.png` (imagen fija) — Godot la mueve en la entrada.
  - `title_tentacles_front.png` + `.json` (tags `emerge`, `idle`) — se dibuja **delante** de las letras.
- Letras: **RISE** cian-blanco, **DIE** rojo con grietas y chorreados, **OR** centrado en placa amarilla con franjas de peligro. Tentáculos con el lenguaje de los del juego, distintos entre sí (alto, grosor, inclinación, curva).

## Pantalla (360×640)
- **Fondo:** el hub en vivo (con su animación y el espacio por los ventanales) **oscurecido al ~35 %**, desenfocado ~1 px y con viñeta. En Godot: `ColorRect` encima del hub con shader de desenfoque + color `#0E1632` a ~65 % y viñeta, o un `BackBufferCopy` con `textureLod`.
- Los tres sprites del logo van con su esquina superior izquierda en **(0, 110)**.
- **Entrada:**
  1. `title_letters` baja desde y −220 hasta 110 en 0,7 s (ease-out cúbica) con un rebote leve de ~10 px. Los tentáculos todavía no se ven.
  2. Al terminar, `title_tentacles_back` y `title_tentacles_front` reproducen `emerge` (una vez, ~1 s): aparece el humo en su lugar final y de ahí salen los tentáculos.
  3. Al terminar `emerge`, pasan a `idle` en bucle y aparece "TOCÁ PARA EMPEZAR".
- **"TOCÁ PARA EMPEZAR"**: Tiny5 16 px `#E7EFF2`, sombra 1 px `#050609`, centrado en (180, 520); parpadea 0,6 s visible / 0,6 s oculto.
- **Versión** "v0.8": Tiny5 16 px `#6689B7`, sombra `#050609`, alineada a la derecha en (348, 628). Leerla de la configuración del proyecto (`application/config/version`).
- **Al tocar** (cualquier tecla/botón/toque): el texto se oculta, logo y capa oscura se funden en 0,5 s y queda el hub con control del jugador.
