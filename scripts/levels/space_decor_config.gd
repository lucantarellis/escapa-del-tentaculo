class_name SpaceDecorConfig
extends Resource
## Parámetros del decorado del espacio (capas de fondo y objetos desenfocados del frente) que dibuja
## [LevelBackground]. Todo es solo visual: sin colisiones ni efecto en el juego. Placeholder hasta
## el arte final.

@export_group("Estrellas")
## Estrellas del plano lejano (chicas y tenues). Solo visual.
@export var far_star_count: int = 70
## Parallax del plano lejano (0 = fijas, 1 = con el mundo).
@export_range(0.0, 1.0, 0.01) var far_parallax: float = 0.08
## Estrellas del plano cercano (algunas titilan).
@export var near_star_count: int = 35
## Parallax del plano cercano.
@export_range(0.0, 1.0, 0.01) var near_parallax: float = 0.25
## Velocidad del titilar. Unidad: rad/s.
@export var twinkle_speed: float = 1.6

@export_group("Nebulosa")
## Manchas de nebulosa.
@export var nebula_count: int = 3
## Opacidad de cada mancha (muy baja para no competir con el juego).
@export_range(0.0, 0.3, 0.005) var nebula_alpha: float = 0.09
## Parallax de la nebulosa.
@export_range(0.0, 1.0, 0.01) var nebula_parallax: float = 0.05
## Colores de las manchas (se reparten en orden).
@export var nebula_colors: PackedColorArray = PackedColorArray([Color("6A4FB0"), Color("2E6FB0"), Color("8A3F8F")])

@export_group("Planeta")
## Radio del planeta lejano. Unidad: px.
@export var planet_radius: float = 64.0
## Parallax del planeta.
@export_range(0.0, 1.0, 0.01) var planet_parallax: float = 0.1
## Largo del ciclo vertical del planeta: tras esta distancia (px de pantalla) reaparece. Unidad: px.
@export var planet_loop: float = 1500.0
## Color del planeta.
@export var planet_color: Color = Color("3B4A6B")
## Color del anillo.
@export var planet_ring_color: Color = Color("6B7A9B")

@export_group("Frente desenfocado")
## Objetos grandes y borrosos delante del jugador (roca y chatarra). 0 = ninguno.
@export var foreground_count: int = 5
## Parallax del frente (mayor que el mundo: se ven más cerca de la cámara).
@export_range(0.0, 2.0, 0.01) var foreground_parallax: float = 1.4
## Opacidad máxima del frente.
@export_range(0.0, 0.6, 0.01) var foreground_alpha: float = 0.22
## Distancia al centro de la pantalla desde la que el frente empieza a verse. Unidad: px.
@export var foreground_clear_radius: float = 90.0
## Largo del ciclo vertical del frente. Unidad: px.
@export var foreground_loop: float = 1300.0
## Color base del frente.
@export var foreground_color: Color = Color("4A5468")

@export_group("Estrella fugaz")
## Segundos mínimos entre estrellas fugaces. 0 en el máximo = ninguna.
@export var shooting_min_interval: float = 6.0
## Segundos máximos entre estrellas fugaces.
@export var shooting_max_interval: float = 10.0
