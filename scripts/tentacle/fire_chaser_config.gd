class_name FireChaserConfig
extends Resource
## Parámetros del perseguidor de fuego del espacio ([FireChaser]): cómo nacen y se mueven las
## explosiones del frente, las del relleno y el humo violeta. Todo se mide desde el borde superior
## del perseguidor (y positiva = hacia abajo). Valores de la maqueta
## `art_src/fuego_perseguidor/v3/mock5.py`, a ajustar en juego. Se edita sobre
## `resources/configs/fire_chaser_config.tres`. Ver `docs/arte/peligros-espacio.md`.

@export_group("Ritmo")
## Cada cuánto nacen explosiones y humo. Unidad: s.
@export var spawn_interval: float = 0.05

@export_group("Frente")
## Explosiones del frente que nacen en cada tanda (mínimo).
@export_range(0, 10) var front_per_tick: int = 2
## Probabilidad de una explosión extra en la tanda. Unidad: 0–1.
@export_range(0.0, 1.0, 0.01) var front_extra_chance: float = 0.33
## Franjas a lo ancho de la pantalla: se barajan y se usan todas antes de repetir, así no quedan
## huecos en el muro.
@export_range(1, 40) var front_lanes: int = 14
## Pesos de las variantes `a`, `b`, `c` y `d` (mediana, ancha, chica, doble).
@export var front_weights: PackedFloat32Array = PackedFloat32Array([35.0, 25.0, 25.0, 15.0])
## Rango vertical del pivote al nacer, respecto del borde (negativo = arriba). Unidad: px.
@export var front_y_min: float = -8.0
@export var front_y_max: float = 16.0
## Probabilidad de que una explosión nazca más arriba que el resto (rompe la línea del borde).
## Unidad: 0–1.
@export_range(0.0, 1.0, 0.01) var front_high_chance: float = 0.15
## Cuánto más arriba del borde nacen esas explosiones. Unidad: px.
@export var front_high_min: float = 14.0
@export var front_high_max: float = 26.0
## Velocidad con la que se hunden respecto del borde. Unidad: px/s.
@export var front_sink_min: float = 20.0
@export var front_sink_max: float = 45.0
## Máximo de explosiones del frente vivas (si se llega, se recicla la más vieja).
@export_range(1, 300) var front_max: int = 60

@export_group("Relleno")
## Explosiones de relleno que nacen en cada tanda.
@export_range(0, 10) var fill_per_tick: int = 3
## Pesos de `a_fill`, `b_fill` y `c_fill`.
@export var fill_weights: PackedFloat32Array = PackedFloat32Array([35.0, 40.0, 25.0])
## Cuánto se pasan de los costados de la pantalla al nacer. Unidad: px.
@export var fill_x_margin: float = 20.0
## Rango vertical del pivote al nacer, debajo del borde. Unidad: px.
@export var fill_y_min: float = 8.0
@export var fill_y_max: float = 50.0
## Se quedan atrás al subir: respecto del borde se hunden a la velocidad del perseguidor
## multiplicada por un factor al azar en este rango (para que no se muevan en bloque). 1 = fijas en
## el mundo. Los valores de la maqueta (80–110 px/s con el fuego a 120 px/s) dan 0,67–0,92: un poco
## menos que fijas, así el relleno queda más tupido.
@export var fill_speed_factor_min: float = 0.67
@export var fill_speed_factor_max: float = 0.92
## Profundidad bajo el borde a la que se liberan. Unidad: px.
@export var fill_release_depth: float = 330.0
## Máximo de explosiones de relleno vivas (si se llega, se recicla la más vieja, que es la más
## hundida). Tiene que alcanzar para que las recicladas ya estén lavadas del todo (~185 px bajo el
## borde) aun con el perseguidor lento: a 60 px/s hacen falta ~210.
@export_range(1, 400) var fill_max: int = 220

@export_group("Humo violeta")
## Probabilidad de que nazca un humo en cada tanda. Unidad: 0–1.
@export_range(0.0, 1.0, 0.01) var smoke_chance: float = 0.75
## Franjas a lo ancho de la pantalla (barajadas, como las del frente).
@export_range(1, 20) var smoke_lanes: int = 9
## Altura del pivote al nacer, arriba del borde. Unidad: px.
@export var smoke_y_min: float = 2.0
@export var smoke_y_max: float = 22.0
## Velocidad con la que sube respecto del borde. Unidad: px/s.
@export var smoke_rise_min: float = 6.0
@export var smoke_rise_max: float = 16.0
## Máximo de humos vivos.
@export_range(1, 100) var smoke_max: int = 25

@export_group("Rojo plano")
## Distancia bajo el borde desde la que se pinta el rojo plano. Unidad: px.
@export var red_offset: float = 12.0
## Alto mínimo del rojo plano (además, siempre llega hasta pasado el fondo de la pantalla).
## Unidad: px.
@export var red_min_height: float = 1000.0

@export_group("Lavado")
## El fuego (frente, humo del frente y relleno) se lava hacia el rojo plano con un degradado suave
## (smoothstep): sin lavar a esta distancia bajo el borde y lavado del todo a la otra. Unidad: px.
@export var wash_start: float = 14.0
@export var wash_end: float = 184.0

@export_group("Glow")
## Fuerza del brillo aditivo de la capa emisiva (0 = sin glow).
@export_range(0.0, 3.0, 0.05) var glow_intensity: float = 0.35
## Cuánto brilla el relleno respecto del frente (además se apaga con el lavado). Se suman muchas
## explosiones encimadas: con 1 el relleno se quema y deja de verse lavado. Unidad: 0–1.
@export_range(0.0, 1.0, 0.05) var glow_fill_factor: float = 0.25
## Radio del desenfoque del brillo (más de 3 se corta en el borde de cada cuadro). Unidad: px.
@export_range(0.0, 3.0, 0.1) var glow_blur: float = 3.0
## Escala del brillo alrededor del pivote de cada explosión: más de 1 lo hace salir del dibujo como
## un halo.
@export_range(1.0, 3.0, 0.05) var glow_scale: float = 1.5
## Color con el que se tiñe el brillo.
@export var glow_color: Color = Color(1.0, 0.55, 0.2, 1.0)

@export_group("Luz")
## Luces puntuales a lo largo del frente (iluminan asteroides y plataformas con relieve y tiñen al
## astronauta). 0 = sin luz.
@export_range(0, 8) var light_count: int = 3
## Color, fuerza y radio de cada luz. Unidad del radio: px.
@export var light_color: Color = Color(1.0, 0.5, 0.2, 1.0)
@export var light_energy: float = 1.2
@export var light_radius: float = 190.0
## Altura de las luces respecto del borde (negativo = arriba). Unidad: px.
@export var light_y: float = -6.0
## Cuánto titila la fuerza de la luz (0 = fija; 0,25 = ±25 %). Unidad: 0–1.
@export_range(0.0, 1.0, 0.01) var light_flicker: float = 0.25
## Velocidad del titileo. Unidad: Hz.
@export var light_flicker_speed: float = 6.0

@export_group("Ahorro")
## Con el borde más de esto debajo del fondo de la pantalla se pausan los emisores. Unidad: px.
@export var pause_margin: float = 100.0
## Al volver a acercarse, se simula este tiempo para que el muro aparezca lleno. Unidad: s.
@export var prewarm_time: float = 1.0
