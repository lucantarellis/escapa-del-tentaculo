class_name ProgressConfig
extends Resource
## Parámetros del progreso entre partidas: valores de arranque sin mejoras, mejoras del
## mercado, invulnerabilidad del dash y reparto de monedas en los niveles.
##
## Se edita desde el inspector sobre `resources/configs/progress_config.tres`. La capa de progreso
## se aplica POR ENCIMA de `player_config.tres` (que no se toca). Con `enabled` en false el juego
## se comporta como antes. Ver `docs/mecanicas/progreso-mercado.md`.

@export_group("General")
## Si es true, rige el progreso (valores base, mejoras y monedas). Con false se juega con
## `player_config.tres` tal cual, sin monedas ni mercado.
@export var enabled: bool = true
## Solo para pruebas: al abrir el juego, si tenés menos monedas que esto, se completan hasta
## este número. 0 = apagado. Unidad: monedas.
@export var debug_min_coins: int = 0
## Solo para pruebas: al abrir el juego, tus monedas pasan a valer exactamente este número (para
## arriba o para abajo) y se guarda. -1 = apagado. Si está activo, manda sobre `debug_min_coins`.
## Acordate de volverlo a -1 al terminar de probar. Unidad: monedas.
@export var debug_set_coins: int = -1

@export_group("Base sin mejoras")
## Combustible máximo (y inicial) sin ninguna mejora. Unidad: u.
@export var base_max_fuel: float = 100.0
## Distancia del dash sin mejoras (0 = sin dash). Unidad: px.
@export var base_dash_distance: float = 0.0

@export_group("Dash invulnerable")
## Cuánto después de empezar el dash empieza la invulnerabilidad. 0 = apenas arranca. Unidad: s.
@export var dash_invulnerable_start: float = 0.0
## Cuánto dura la invulnerabilidad, como porcentaje de la duración del dash (`dash_duration` del
## jugador): 100 = todo el dash. Se cuenta desde `dash_invulnerable_start`. Unidad: %.
@export_range(0.0, 100.0, 1.0) var dash_invulnerable_percent: float = 67.0
## Causas de muerte que la invulnerabilidad NO frena (la caída y el tentáculo).
@export var dash_unblockable_causes: Array[StringName] = [&"tentacle", &"fell", &"minor_tentacle"]

@export_group("Golpes y reaparición")
## Tras recibir un golpe que no mata (con puntos de golpe de más), el jugador no puede perder
## otro punto durante este tiempo (parpadea). No frena a las causas de `instakill_causes`.
## Unidad: s.
@export var hit_invulnerable_time: float = 1.5
## Causas de muerte que matan siempre, sin importar los puntos de golpe ni la invulnerabilidad
## tras un golpe: los perseguidores y la caída bajo la pantalla.
@export var instakill_causes: Array[StringName] = [&"tentacle", &"fell"]
## Con la mejora Reaparecer: cuánto más arriba que donde murió reaparece el jugador (se busca un
## lugar libre desde ahí hacia arriba). Unidad: px.
@export var respawn_height: float = 160.0
## Puntos de golpe con los que reaparece el jugador. Unidad: puntos.
@export var respawn_hit_points: int = 1

@export_group("Mejoras")
## Nodos del árbol de talentos, en el orden en que se muestran (las ramas aparecen en el orden en
## que sale su primer nodo).
@export var upgrades: Array[UpgradeData] = []

@export_group("Monedas en el nivel")
## Mínimo de monedas por segmento intermedio.
@export var coins_per_segment_min: int = 2
## Máximo de monedas por segmento intermedio.
@export var coins_per_segment_max: int = 4
## Distancia mínima al borde del segmento (para no pegarlas a la unión con otro segmento). Unidad: px.
@export var coin_edge_margin: float = 28.0
## Distancia mínima a plataformas, paredes, tanques y peligros. Unidad: px.
@export var coin_obstacle_margin: float = 26.0
## Distancia mínima entre dos monedas. Unidad: px.
@export var coin_min_separation: float = 44.0
## Intentos de ubicar cada moneda antes de rendirse (si no hay lugar, el segmento tiene menos). Unidad: intentos.
@export var coin_placement_tries: int = 40
