# Mercado — puesto y cara del vendedor

Escena que se ve **por encima de la UI del mercado** (sin mostrador). Mismo código visual que la nave: 2D frontal, piezas reutilizadas del fondo (`bg_ship_*`), luz desde Godot (nada horneado).

## Archivos
| Editable | Exportado |
|---|---|
| `assets/aseprite/ui/market/market_booth.aseprite` (360×208, 24 frames de 100 ms, tag `ambient` en bucle, capas `color` + `emissive`) | `assets/sprites/ui/market/market_booth.png`, `market_booth_emissive.png` (tira horizontal 8640×208), `market_booth.json` |
| `assets/aseprite/ui/market/market_face.aseprite` (93×55, 49 frames, capas `color` + `emissive`) | `assets/sprites/ui/market/market_face.png`, `market_face_emissive.png` (tira horizontal 4557×55), `market_face.json` (frames, duraciones, tags) |

## Ensamblado
- `market_booth` arriba de la pantalla, en (0,0), reproduciendo `ambient` en bucle (2,4 s). Ancho 360 = ancho del juego. Ambiente: datos y onda en la consola derecha, LED de las consolas, burbujas en la cápsula, LED en secuencia bajo la pantalla y en el soporte, luz de la puerta con franjas y luces de algunos ítems de los estantes.
- `market_booth_emissive` en la misma posición (LED, pantallas chicas, líquido de la cápsula).
- `market_face` encima, con su esquina superior izquierda en **(134, 59)** del booth (centro del sprite: **(180.5, 86.5)**). Tapa por completo el interior de la pantalla.
- `market_face_emissive` en la misma posición, como capa emisiva / add para el brillo cian.
- Luz sugerida en Godot: PointLight2D cian suave sobre la pantalla (180, 86) y un tubo cálido arriba de la ventanilla.

## Tags (duraciones por frame en el `.aseprite` / JSON)
| Tag | Frames | Loop | Uso |
|---|---|---|---|
| `idle` | 1–9 (~7,2 s) | sí | Parpadeo y mirada a los lados. Estado por defecto. |
| `browse` | 10–15 (~2 s) | sí | Mira hacia abajo (a la lista) mientras el jugador navega. |
| `buy` | 16–22 (~1,5 s) | no → `idle` | Compra: ojos ^ ^, sonrisa, suben dos monedas ámbar. |
| `deny` | 23–31 (~1,4 s) | no → `idle` | Sin monedas: la pantalla se tiñe de rojo (fondo bordó, cara roja), ceño, boca ondulada, sacudida de 2 px, pulso y vuelta al azul. |
| `enter` | 32–40 (~1,1 s) | no → `idle` | Pantalla se prende (raya → cara) y saluda. Al entrar al mercado. |
| `exit` | 41–49 (~1,6 s) | no, queda apagada | Guiño y apagado tipo CRT. Al salir del mercado. |

Descartado: reacción con "?" para ítems bloqueados.

---

# UI del mercado (mitad de abajo)

## Layout (pantalla 360×640)
- `y 0–207`: puesto + cara (arriba).
- `y 208–639` (360×432): UI, fondo `#0E1632`. Coordenadas abajo relativas a `y 208`.
  - Barra superior (y 4–27): ícono `hud_icon_coin` (10,6) + número (34, centro y 15); "+1 compra gratis" en texto `#FCD51D` (80, y 15), **no es botón**; botón **RESET** `mk_btn_reset` (276,4, 75×23).
  - Solapas (y 32–58): Movimiento 104 px, Supervivencia 130 px, Economía 96 px, separadas 2 px, desde x 8. Activa `mk_tab_active` (alto 27, desde y 32, se funde con el panel); inactivas `mk_tab_inactive` (alto 22, desde y 36).
  - Panel de lista `mk_panel_list` (8,58 → 351,322). Lista con scroll: filas de 27 px de alto cada 30 px (x 14–340); subencabezado de rama de 20 px (ícono `mk_branch_*` en x 15, título en mayúsculas `#63D6C5` en x 36 y una línea de 1 px `#3A9BBF` hasta x 338).
  - Scrollbar a la derecha (x 345, 3 px de ancho): `mk_scroll_track` + `mk_scroll_grabber`. Sin texto "más".
  - Panel de detalle `mk_panel_detail` (8,330 → 351,426): título `#E7EFF2` (16, +14), descripción de **una línea** `#C8E7EA` (16, +36), botones a +58 de 25 px de alto: **Volver** `mk_btn_secondary` (16, 81 px) y **Comprar** `mk_btn_primary` (derecha, 134 px; texto + ícono de moneda + precio en `#FCD51D`). Sin monedas o bloqueado: `mk_btn_primary_disabled`.

## Filas por estado
| Estado | Fondo | Texto nombre | Derecha |
|---|---|---|---|
| Comprado | `mk_row_own` (franja izquierda) | `#89D9EB` | `mk_icon_check` + "Comprado" `#63D6C5` |
| Comprable | `mk_row_buy` | `#E7EFF2` | moneda + precio `#FCD51D` |
| Sin monedas | `mk_row_buy` | `#89D9EB` | moneda + precio `#F62A19` |
| Bloqueado | `mk_row_lock` | `#6689B7` | `mk_icon_lock` (el motivo va en el detalle) |
| Foco | `mk_focus` encima, 1 px por fuera de la fila | — | — |

## Texto
Tiny5 16 px (`assets/fonts/Tiny5-Regular.ttf`), sombra 1 px `#050609` abajo a la derecha. Solapa activa `#E7EFF2`, inactiva `#3A9BBF`.

## Piezas
Editable: `assets/aseprite/ui/market/market_ui.aseprite` (atlas con un **slice por pieza**, con su centro 9-slice). Exportadas una por PNG en `assets/sprites/ui/market/`. Márgenes 9-slice (izq, arriba, der, abajo) para `StyleBoxTexture` / `NinePatchRect`, con `axis_stretch = STRETCH`:

| Pieza | Tamaño | Márgenes |
|---|---|---|
| `mk_panel_list`, `mk_panel_detail`, `mk_btn_reset` | 16×16 | 6,6,6,6 |
| `mk_tab_active`, `mk_tab_inactive`, `mk_row_buy`, `mk_row_lock`, `mk_focus`, `mk_btn_secondary`, `mk_btn_primary`, `mk_btn_primary_disabled` | 12×12 | 3,3,3,3 |
| `mk_row_own` | 12×12 | 5,3,3,3 |
| `mk_scroll_track` | 3×8 | 0,1,0,1 |
| `mk_scroll_grabber` | 3×8 | 0,2,0,1 |
| `mk_icon_check` 7×8, `mk_icon_lock` 9×13, `mk_branch_{dash,speed,tank,life,repair,coins}` 18×18 | — | sin 9-slice |

La moneda reutiliza `assets/sprites/ui/hud/hud_icon_coin.png`.
