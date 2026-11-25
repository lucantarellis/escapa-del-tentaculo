class_name SpaceDecorConfig
extends Resource
## Parámetros del decorado del espacio ([SpaceBackground]): capas de fondo con paralaje, desenfoque
## por capa y rocas desenfocadas del frente. Todo es solo visual: sin colisiones ni efecto en el
## juego. Ver `docs/arte/fondo-espacio.md`.

@export_group("Paralaje")
## Paralaje de la nebulosa y de las estrellas lejanas (0 = fijas, 1 = con el mundo).
@export_range(0.0, 1.0, 0.01) var far_parallax: float = 0.06
## Paralaje del planeta del anillo.
@export_range(0.0, 1.0, 0.01) var planet_parallax: float = 0.15
## Paralaje de las estrellas cercanas (las que titilan).
@export_range(0.0, 1.0, 0.01) var near_parallax: float = 0.3
## Paralaje de las rocas del frente (mayor que 1: se ven más cerca de la cámara que el mundo).
@export_range(0.0, 2.0, 0.01) var foreground_parallax: float = 1.4

@export_group("Desenfoque")
## Radio del desenfoque de la nebulosa lejana. 0 = nítida. Unidad: px.
@export_range(0.0, 6.0, 0.1) var nebula_blur: float = 1.2
## Radio del desenfoque del planeta. Unidad: px.
@export_range(0.0, 6.0, 0.1) var planet_blur: float = 0.6
## Radio del desenfoque de las rocas del frente. Unidad: px.
@export_range(0.0, 6.0, 0.1) var foreground_blur: float = 3.5

@export_group("Planeta")
## Esquina superior izquierda del planeta dentro de su tramo de `planet_loop`. Unidad: px.
@export var planet_origin: Vector2 = Vector2(220.0, 250.0)
## Largo del tramo del planeta: tras esta distancia (px de capa) vuelve a aparecer. Unidad: px.
@export var planet_loop: float = 1600.0

@export_group("Frente desenfocado")
## Largo del ciclo vertical del frente (el reparto se repite). 0 = sin rocas del frente. Unidad: px.
@export var foreground_loop: float = 4000.0
## Separación mínima entre una roca y la siguiente, que va del otro lado. Unidad: px.
@export var foreground_gap_min: float = 140.0
## Separación máxima entre una roca y la siguiente. Unidad: px.
@export var foreground_gap_max: float = 280.0
## Cuánto entra el centro de cada roca desde el borde de la pantalla: mínimo (negativo = afuera).
## Unidad: px.
@export var foreground_edge_min: float = -10.0
## Cuánto entra el centro de cada roca desde el borde de la pantalla: máximo. Unidad: px.
@export var foreground_edge_max: float = 40.0
## Distancia al centro de la pantalla desde la que las rocas empiezan a verse. Unidad: px.
@export var foreground_clear_radius: float = 90.0
## Opacidad de las rocas del frente.
@export_range(0.0, 1.0, 0.01) var foreground_alpha: float = 1.0
## Semilla del reparto de las rocas (mismo número, mismo reparto).
@export var foreground_seed: int = 1234

@export_group("Estrella fugaz")
## Segundos mínimos entre estrellas fugaces. 0 en el máximo = ninguna.
@export var shooting_min_interval: float = 6.0
## Segundos máximos entre estrellas fugaces.
@export var shooting_max_interval: float = 10.0
