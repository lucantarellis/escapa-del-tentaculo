class_name HubHintsConfig
extends Resource
## Textos, tiempos y posiciones del overlay de ayuda del hub ([HubHints]): las pistas de primera
## vez (caminar, volar, plataforma del ascensor) y la del mercado. Cambiar un texto o un tiempo es
## solo editar este recurso (`resources/configs/hub_hints_config.tres`). Todas las posiciones están
## en coordenadas del hub (360×640, esquina superior izquierda de cada pieza, salvo que diga
## "centro"). Ver `docs/mecanicas/overlay-hub.md`.

@export_group("Textos")
## Paso 1: rótulo debajo de las flechas. Solo visual.
@export var walk_label: String = "CAMINAR"
## Paso 2: las dos líneas del texto de volar. Solo visual.
@export var fly_line_1: String = "MANTENÉ"
@export var fly_line_2: String = "PARA VOLAR"
## Paso 3: las dos líneas del texto de la plataforma. Solo visual.
@export var platform_line_1: String = "SUBÍ ACÁ"
@export var platform_line_2: String = "Y ESPERÁ 1 s"
## Paso 4: texto del lado del mercado (alineado a la derecha). Solo visual.
@export var market_line_1: String = "GASTÁ TUS"
@export var market_line_2: String = "MONEDAS"
## Paso 4: texto del lado de Ajustes (alineado a la izquierda). Solo visual.
@export var settings_line_1: String = "AJUSTES Y"
@export var settings_line_2: String = "CRÉDITOS"
## Botón de Ajustes que repite los pasos 1 a 3. Solo visual.
@export var controls_button: String = "VER CONTROLES"

@export_group("Velo")
## Color del velo que oscurece el hub. Solo visual.
@export var veil_color: Color = Color("050609")
## Opacidad del velo en los pasos 1 a 3. Solo visual.
@export_range(0.0, 1.0, 0.01) var veil_alpha: float = 0.64
## Opacidad del velo en el paso del mercado (paso 4). Solo visual.
@export_range(0.0, 1.0, 0.01) var veil_alpha_market: float = 0.5
## Fundido del velo y de las piezas al aparecer o irse. Solo visual. Unidad: s.
@export_range(0.0, 2.0, 0.05) var veil_fade: float = 0.25

@export_group("Detección")
## Paso 1: cuánto tiene que moverse el jugador en horizontal desde que aparece la pista. Unidad: px.
@export var walk_distance: float = 24.0
## Paso 2: tiempo acumulado de propulsor para darlo por cumplido. Unidad: s.
@export var fly_time: float = 0.4
## Pausa entre un paso y el siguiente. Solo visual. Unidad: s.
@export var step_pause: float = 0.3

@export_group("Topes de tiempo")
## Segundos que dura cada pista como máximo antes de irse sola (0 = sin tope). Unidad: s.
@export var walk_max_time: float = 12.0
@export var fly_max_time: float = 12.0
## La pista de la plataforma es la más importante: con 0 no se va hasta que el jugador se sube.
@export var platform_max_time: float = 0.0
@export var market_max_time: float = 15.0

@export_group("Visual")
## Color del texto y de su sombra de 1 px (a +1, +1). Solo visual.
@export var text_color: Color = Color("E7EFF2")
@export var text_shadow: Color = Color("050609")
## Cada cuánto alterna la tecla entre reposo y pulsada. Solo visual. Unidad: s.
@export_range(0.05, 2.0, 0.05) var key_toggle_time: float = 0.5
## Teclas de caminar: true = se pulsan una por vez (izquierda, derecha, izquierda…); false =
## parpadean juntas. Solo visual.
@export var walk_keys_alternate: bool = true
## Recuadro punteado: largo del trazo y del hueco (px) y velocidad con la que avanza (px/s). Solo
## visual.
@export var dash_on: int = 4
@export var dash_off: int = 3
@export var dash_speed: float = 7.0

@export_group("Posiciones: paso 1 (caminar)")
## Solo visual.
@export var key_left_position: Vector2 = Vector2(150.0, 470.0)
@export var key_right_position: Vector2 = Vector2(182.0, 470.0)
## Centro del rótulo. Solo visual.
@export var walk_label_center: Vector2 = Vector2(180.0, 502.0)

@export_group("Posiciones: paso 2 (volar)")
## Solo visual.
@export var key_up_position: Vector2 = Vector2(168.0, 448.0)
@export var fly_chevrons_position: Vector2 = Vector2(176.0, 392.0)
## Centro de cada línea. Solo visual.
@export var fly_line_1_center: Vector2 = Vector2(180.0, 480.0)
@export var fly_line_2_center: Vector2 = Vector2(180.0, 498.0)

@export_group("Posiciones: paso 3 (plataforma)")
## Agujero del velo sobre la plataforma y recuadro punteado. Solo visual.
@export var platform_hole: Rect2 = Rect2(136.0, 312.0, 88.0, 31.0)
@export var platform_frame: Rect2 = Rect2(136.0, 312.0, 88.0, 31.0)
## Centro de cada línea. Solo visual.
@export var platform_line_1_center: Vector2 = Vector2(180.0, 246.0)
@export var platform_line_2_center: Vector2 = Vector2(180.0, 264.0)
@export var platform_arrow_position: Vector2 = Vector2(176.0, 288.0)
## Los dos chevrones a los lados de la plataforma. Solo visual.
@export var platform_chevrons_left_position: Vector2 = Vector2(108.0, 334.0)
@export var platform_chevrons_right_position: Vector2 = Vector2(244.0, 334.0)

@export_group("Posiciones: paso 4 (mercado)")
## Agujeros del velo sobre las dos puertas y recuadros punteados. Solo visual.
@export var settings_hole: Rect2 = Rect2(0.0, 486.0, 26.0, 126.0)
@export var market_hole: Rect2 = Rect2(335.0, 486.0, 25.0, 126.0)
@export var settings_frame: Rect2 = Rect2(0.0, 482.0, 29.0, 133.0)
@export var market_frame: Rect2 = Rect2(331.0, 482.0, 29.0, 133.0)
## Texto del mercado: x del borde derecho; y de cada línea (arriba). Solo visual.
@export var market_text_right: Vector2 = Vector2(326.0, 436.0)
@export var market_line_gap: float = 18.0
## Texto de Ajustes: x del borde izquierdo; y de cada línea (arriba). Solo visual.
@export var settings_text_left: Vector2 = Vector2(34.0, 436.0)
## Flechas laterales (la de Ajustes es la misma con `flip_h`). Solo visual.
@export var market_arrow_position: Vector2 = Vector2(296.0, 472.0)
@export var settings_arrow_position: Vector2 = Vector2(28.0, 472.0)

@export_group("Depuración")
## Solo para probar el arte: 1 (caminar), 2 (volar), 3 (plataforma) o 4 (mercado) muestra esa pista
## fija cada vez que el jugador toma el control en el hub, sin mirar ni tocar los flags. 0 = apagado.
@export_range(0, 4) var debug_preview_step: int = 0
