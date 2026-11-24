class_name LightingConfig
extends Resource
## Iluminación de la nave: oscuridad general y cada tipo de luz. Solo visual. Lo leen
## [LevelLighting] (oscuridad) y las luces de cada cosa (jugador, paredes, plataformas, recogibles).
## La luz de la escotilla está en [IntroConfig]. Ver `docs/mecanicas/iluminacion.md`.

@export_group("Oscuridad")
## Color por el que se multiplica el mundo en los tiers oscuros (`SegmentTier.dark_ambient`). Más
## oscuro = la nave se descubre con la luz del astronauta. El fondo, las capas emisivas y el HUD no
## se oscurecen.
@export var ambient_color: Color = Color(0.42, 0.44, 0.52)

## Altura de las luces sobre la pared (las texturas tienen relieve: con altura 0 la luz llega
## rasante y casi no ilumina las superficies planas). Más baja = más relieve y menos luz. Unidad: px.
@export var light_height: float = 40.0

@export_group("Astronauta")
## Luz principal: el jugador descubre la nave al subir.
@export var player_color: Color = Color(1.0, 0.95, 0.85)
@export var player_energy: float = 1.0
## Radio de la luz: hasta dónde llega como máximo. Unidad: px.
@export var player_radius: float = 170.0
## Altura de la luz del astronauta sobre la pared. Es lo que más decide hasta dónde se ve: una
## superficie plana a distancia d recibe ≈ altura / √(d² + altura²) de la luz. Con 35 px, a 250 px
## llega el 14 %; con 150 px, el 51 %. Más alta = ilumina más lejos y con menos relieve. Unidad: px.
@export var player_height: float = 150.0
## Cuánta luz queda a mitad del radio (0–1). Más alto = la luz se sostiene hasta el borde en vez de
## concentrarse en el centro. Las demás luces usan 0,45.
@export_range(0.1, 1.0, 0.05) var player_core: float = 0.8
## Si es false, el astronauta no se ilumina con su propia luz ni se oscurece: se dibuja siempre con
## su color. Así se puede subir `player_energy` para ver más lejos sin que el jugador se queme a
## blanco. Si es true, recibe luz y oscuridad como el resto.
@export var player_self_lit: bool = false
## Con `player_self_lit = false`: cuánto lo tiñe cada luz del entorno (alarmas, lámparas, recogibles,
## propulsores, luz del ascensor, etc.; no la suya). 0 = no lo afectan; 1 = a pleno de una luz fuerte
## toma su color. Se calcula con la textura de cada luz en el punto del astronauta.
@export_range(0.0, 1.0, 0.05) var player_light_tint: float = 0.6

@export_group("Grietas de las paredes")
@export var crack_color: Color = Color(1.0, 0.45, 0.15)
@export var crack_energy: float = 0.8
## Radio para una grieta de una celda; crece con el tamaño de la grieta. Unidad: px.
@export var crack_radius: float = 40.0
## Cuánto suma al radio cada celda extra de la misma grieta, y radio máximo. Unidad: px.
@export var crack_radius_per_cell: float = 6.0
@export var crack_radius_max: float = 90.0
## Cuánto titila (0 = fija).
@export_range(0.0, 1.0, 0.05) var crack_flicker: float = 0.25

@export_group("Alarmas de las paredes")
@export var alarm_color: Color = Color(1.0, 0.15, 0.1)
@export var alarm_energy: float = 0.6
## Energía de las alarmas rotas.
@export var alarm_broken_energy: float = 0.3
@export var alarm_radius: float = 50.0
## Ajuste fino de la fase entre la luz y el tile de la alarma. Tendría que quedar en 0: la luz y el
## tile comparten reloj. Si en pantalla la luz va adelantada o atrasada, mover de a 0,05. Unidad: s.
@export_range(-1.0, 1.0, 0.01) var alarm_phase_offset: float = 0.0

@export_group("Plataformas")
## Temporizada encendida (en el aviso parpadea; apagada no ilumina).
@export var timed_color: Color = Color(0.4, 0.95, 1.0)
@export var timed_energy: float = 0.7
@export var timed_radius: float = 50.0
## Parpadeo de la luz durante el aviso. Unidad: Hz.
@export var timed_warning_blink: float = 8.0
## Pulso en fase letal (titila con el rayo) y durante el aviso (tenue).
@export var pulse_color: Color = Color(0.6, 0.95, 1.0)
@export var pulse_energy: float = 1.0
@export var pulse_warning_energy: float = 0.25
@export var pulse_radius: float = 60.0
## Propulsores de las móviles.
@export var thruster_color: Color = Color(0.4, 0.6, 1.0)
@export var thruster_energy: float = 0.5
@export var thruster_radius: float = 26.0

@export_group("Recogibles")
## Luz cian tenue para que se lean de lejos. La moneda no la lleva salvo que se active acá.
@export var pickup_color: Color = Color(0.4, 0.9, 0.85)
@export var pickup_energy: float = 0.35
@export var pickup_radius: float = 28.0
@export var pickup_light_on_coins: bool = false
## Pico de energía durante el destello de recolección.
@export var pickup_collect_energy: float = 1.2

@export_group("Rendimiento")
## Las luces fijas de las paredes se apagan cuando quedan a más de esta distancia de la pantalla.
## Unidad: px.
@export var cull_margin: float = 120.0
