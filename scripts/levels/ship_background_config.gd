class_name ShipBackgroundConfig
extends Resource
## Ajustes del fondo de la nave en parallax ([ShipBackground]). Todo es visual: no cambia el
## gameplay. Ver `docs/arte/fondo-nave.md`.

@export_group("Velocidad")
## Cuánto se mueve cada capa respecto de la cámara (1 = igual que el mundo, 0 = quieta).
@export_range(0.0, 1.0, 0.01) var far_scroll: float = 0.2
@export_range(0.0, 1.0, 0.01) var mid_scroll: float = 0.45
@export_range(0.0, 1.0, 0.01) var near_scroll: float = 0.75

@export_group("Desenfoque")
## Radio del desenfoque de cada capa. 0 = nítida. Unidad: px.
@export_range(0.0, 4.0, 0.25) var far_blur: float = 2.0
@export_range(0.0, 4.0, 0.25) var mid_blur: float = 1.0
@export_range(0.0, 4.0, 0.25) var near_blur: float = 0.0

@export_group("Niebla")
## Color hacia el que se funden las capas lejanas.
@export var fog_color: Color = Color("0E1632")
## Cuánto se funde cada capa hacia `fog_color`. 0 = nada, 1 = todo.
@export_range(0.0, 1.0, 0.05) var far_fog: float = 0.45
@export_range(0.0, 1.0, 0.05) var mid_fog: float = 0.2
@export_range(0.0, 1.0, 0.05) var near_fog: float = 0.0

@export_group("Emisivo")
## Opacidad de la capa emisiva (balizas, fuegos, pantallas) encima del color. 0–1.
@export_range(0.0, 1.0, 0.05) var emissive_strength: float = 1.0
## Si es true, la capa emisiva se suma (brilla más); si no, se dibuja encima normal.
@export var emissive_additive: bool = false

@export_group("Resplandores")
## Resplandor de las balizas de emergencia (sigue el giro del arte).
@export var beacon_color: Color = Color(1.0, 0.16, 0.12)
## Radio del resplandor. Unidad: px.
@export var beacon_radius: float = 26.0
## Intensidad máxima. 0–1.
@export_range(0.0, 1.0, 0.05) var beacon_intensity: float = 0.5
## Resplandor de los incendios.
@export var fire_color: Color = Color(1.0, 0.5, 0.15)
@export var fire_radius: float = 34.0
@export_range(0.0, 1.0, 0.05) var fire_intensity: float = 0.4
## Cuánto titila el fuego además de lo que ya hace el arte. 0 = nada.
@export_range(0.0, 1.0, 0.05) var fire_flicker: float = 0.25
## Destello de las chispas (solo en sus cuadros).
@export var spark_color: Color = Color(0.75, 0.9, 1.0)
@export var spark_radius: float = 14.0
@export_range(0.0, 1.0, 0.05) var spark_intensity: float = 0.6
