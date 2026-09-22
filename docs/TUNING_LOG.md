# Registro de tuning — Escapa del Tentáculo

Registro del balance de los valores de configuración (`resources/configs/*.tres`). Desde el brief 06 **cada cambio acordado en una ronda de tuning se anota** (una fila por parámetro, con evidencia). Sirve para volver atrás y para entender por qué un valor es el que es. Los valores de prueba que LT ajustó a mano antes del brief 06 solo figuran donde se indica.

Regla: las simulaciones informan, no deciden. Ante una discrepancia entre lo simulado y lo que siente LT, gana LT.

## Objetivos de diseño

Definidos por LT en el Paso 0 del brief 06 (2026-09-21):

| Tema | Objetivo (palabras de LT) |
|---|---|
| Duración de una partida completa (intro incluida) | ~3 minutos para un jugador competente |
| Victoria de un jugador competente (no experto) | ~25–30 % |
| Muertes | Todas deben sentirse por error propio o por desconocimiento del juego. Que las muertes "enseñen" al jugador a prevenirla en la próxima run |
| Prioridades | Tensión, exigencia, y exploración/descubrimiento: que el jugador aprenda de los elementos del juego a medida que los encuentra o entiende más sus mecánicas |

Consecuencias de diseño anotadas por Claude (a validar con LT): no debe haber ruido letal inevitable (cada segmento debe ser legible y resoluble); los avisos de peligro tienen que ser claros; la exploración/descubrimiento pide elementos que se aprendan al encontrarlos, y con el contenido actual (6 segmentos, 4 elementos) eso es limitado (posible tema para el brief 07, fuera del alcance de este brief).

## Línea de base (Paso 0, sin cambiar ningún valor)

Medida el 2026-09-21 sobre `main` (`8c39640`). **Cómo se midió:** réplica en Python del movimiento vertical de `player.gd` a 60 Hz (`thrust`, tope de velocidad, freno, gravedad con transición, caída máxima) con los `.tres` actuales; sin colisiones. Validada contra las referencias de `tanques.md` (con `gravity_with_fuel` = 30 da 507 px por tanque, contra ~489 medidos en el juego). Estructura de segmentos leída con un script headless de Godot (`SceneTree`), no jugada.

### Física con los `.tres` actuales (`gravity_with_fuel` 150)

| Medida | Valor | Nota |
|---|---|---|
| Subida de un tanque (40 u, 2,67 s de propulsión) | ~488 px, ~3,1 s hasta el ápice | Igual a la referencia de `tanques.md` (~489); casi no depende de la gravedad (471–499 px entre 80 y 250) |
| Velocidad de ascenso a fondo | ~177 px/s | tope `max_speed` 180 menos la gravedad |
| Coste de mantenerse en el aire (flotar) | 3,2 u/s (`gravedad / thrust × 15`) | 100 u alcanzan ~31 s en el aire sin moverse |
| Coste de subir al ritmo del scroll (40 px/s) con propulsión intermitente | ~4,6 u/s | ≈ 0,108 u/px |
| Coste de subir a fondo | 0,085 u/px | Es el mínimo por píxel |
| Salto sin combustible | ~55 px (referencia medida en juego: ~61 px) | |
| Salto con combustible (`jump_requires_empty_fuel = false`) | ~139 px | Con 30 de gravedad serían 280 px |
| Altura del vuelo de la intro | ~653 px (`launch_speed² / (2 × (drag + gravedad))`) | Cabe en el segmento de inicio (1100 px) |

### Nivel (seed al azar, 6 intermedios)

| Medida | Valor | Nota |
|---|---|---|
| Altura total | 5580 px = 1100 (inicio) + 6 × 640 + 640 (final) | |
| Recorrido de la cámara | 4940 px (`5580 − 640`) | La cámara se detiene con el final a la vista |
| Tiempo de la cámara hasta el final | 123,5 s a 40 px/s | |
| Duración de la intro hasta el lanzamiento | ~3,3 s (0,6 + 2 × 1,0 + 0,7) + 0,35 s de ruptura | |
| Duración total hasta que la cámara llega al final | ~129 s (intro + `start_delay` 2 s + 123,5 s) | **Objetivo: ~180 s. Faltan ~50 s** |
| Tiempo que tiene el jugador tras detenerse la cámara | ~13–15 s | El tentáculo sigue subiendo a 40 px/s (`end_rise_speed`) |
| Tiempo del tentáculo hasta un jugador quieto | ~6,5 s a media pantalla, ~13 s pegado al techo | El borde letal queda 60 px sobre el borde inferior (`visible_height` 70 − `kill_zone_inset` 10); un jugador quieto pierde 40 px/s de altura relativa |
| Entrada del tentáculo en la intro | 1,5 s de espera + 1,0 s de entrada tras la ruptura | |

### Combustible por nivel

| Medida | Valor |
|---|---|
| Tanques | 16 (3 inicio + 2 × 6 intermedios + 1 final) = 640 u, más 100 u de partida = 740 u |
| Subida total necesaria | ~4650 px (~5300 px hasta la puerta menos ~650 px del vuelo gratuito de la intro) |
| Combustible mínimo teórico (subida a fondo, 0,085 u/px) | ~394 u |
| Holgura teórica | 740 / 394 ≈ 1,9× para un recorrido perfecto (sin tener en cuenta que el sobrante sobre `max_fuel` 100 se pierde ni el tiempo en el aire) |
| Coste de estar 30 s en el aire sin apoyarse | ~96 u (≈ 2,4 tanques) |

Lectura: el combustible parece generoso para un recorrido perfecto y solo se vuelve limitante cuando el jugador flota o se apoya poco. Si LT quiere 25–30 % de victoria, la dificultad tendrá que venir más del tiempo, de los obstáculos y de la lectura de los segmentos que del combustible, salvo que las rondas indiquen otra cosa.

### Segmentos (estructura, sin recorrido jugado)

| Segmento | Tanques (x, y locales) | Peligros | Plataformas |
|---|---|---|---|
| `SegmentStart` (1100 px) | 3: (275,−258), (275,−578), (275,−898) | ninguno | 8 |
| `Segment01` | 2: (110,−358), (250,−508) | ninguno | 5 |
| `Segment02` | 2: (180,−250), (60,−518) | 2 bloques estáticos, 1 móvil | 3 |
| `Segment03` | 2: (180,−458), (260,−168) | 2 `PulseTrap` | 4 |
| `Segment04` | 2: (336,−411), (100,−518) | ninguno (tanque en repisa: solo por salto) | 6 |
| `Segment05` | 2: (180,−158), (180,−468) | 2 móviles horizontales | 4 |
| `Segment06` | 2: (250,−268), (180,−608) | 1 `PulseTrap`, 1 bloque estático | 4 |
| `SegmentEnd` (640 px) | 1: (260,−208) | ninguno | 4 |

**Alcanzabilidad:** en el Paso 0 solo se midió el presupuesto por segmento (cada uno de 640 px cuesta ~54 u de subida a fondo; sus dos tanques dan 80 u) y no se simuló un recorrido (bot). Los pares de peligros y tanques que más riesgo de "injusticia" tienen a priori (`Segment06`: tanque pegado a una `PulseTrap`; `Segment05`: móviles que se cruzan) se revisan en la ronda de obstáculos. Ningún segmento se declaró imposible; esto **no** está verificado con un bot.

### Lo que la línea de base marca para el backlog

1. La duración (~129 s) queda corta frente a los ~3 min pedidos: hay que alargar el nivel (más segmentos, con el pool actual se repetirán más) o bajar `scroll_speed` (~28 px/s con el nivel actual daría ~180 s).
2. El combustible es holgado en teoría: la dificultad no puede depender de él si se quiere exigir.
3. Con `gravity_with_fuel` 150 flotar cuesta 3,2 u/s y el salto con combustible da ~139 px; ambos definen cuánto "pelea" el jetpack.

## Ronda 2: combustible y saltos tácticos (en curso)

**Objetivo de LT:** que el salto (sin gastar combustible) alcance la mayoría de las plataformas, y que usar el jetpack sea una decisión táctica del jugador, no un requisito. Esta ronda toca `Nivel` (diseño de segmentos) y `Combustible` (backlog áreas 2 y 5) antes que `Duración` (área 3), porque el layout de las plataformas condiciona cómo se arman los segmentos nuevos para alargar el nivel.

**Medición del alcance real del salto** (`jump_velocity` 260, gravedad única 250, `coasting_drag` 90 en el aire — sin tocar la física del jugador, ronda 1 queda cerrada), contra la geometría real de los 8 `.tscn` (leída con un script headless, no solo la referencia general del documento):

| Subida (Δy) | Horizontal máximo disponible en ese punto (Δx) |
|---|---|
| +90 px | ~53 px |
| +100 px | ~60 px |
| +110 px | ~68 px |
| +120 px | ~76 px |
| +130 px | ~87 px (cerca del ápice, 133 px) |

Los escalones actuales de los 8 segmentos suben ~150 px con ~130–160 px de desvío horizontal: fuera del alcance del salto en cualquier combinación (por eso hoy, en la práctica, subir requiere combustible casi todo el tiempo). LT decidió no tocar la física del salto (`coasting_drag`, `jump_velocity`) y en cambio achicar los huecos entre plataformas.

**Piloto en `Segment01`** (el resto de los segmentos no se tocó todavía): 6 plataformas en vez de 5, escalones uniformes de Δy = 112 px y Δx = 60 px (margen de ~9 px sobre el máximo medido de 69,2 px, para tolerar imprecisión del jugador). Primera y última plataforma se mantuvieron en su Y original (respetan la regla de apoyos en las uniones). Los 2 tanques se reubicaron sobre las plataformas 3 y 5 del nuevo camino (antes estaban descolgados del layout viejo).

| Ronda | Fecha | Parámetro / archivo | Valor anterior | Valor nuevo | Evidencia | Cómo se sintió |
|---|---|---|---|---|---|---|
| 2 (piloto) | 2026-09-22 | `scenes/levels/segments/Segment01.tscn` (plataformas y tanques) | 5 plataformas, escalones ~150 px Δy / ~130–160 px Δx | 6 plataformas, escalones 112 px Δy / 60 px Δx uniformes | Simulación del alcance del salto (tabla arriba) + validación headless: `has_fuel_tank()=true`, `get_out_of_bounds_children()=[]`, sin advertencias del `@tool`, las 3 escenas (`Main`, `Level`, `sandbox`) cargan sin error | Pendiente: LT lo juega aislado (F6 sobre `Segment01.tscn`) antes de replicar a los otros 7 segmentos |
| 2 | 2026-09-22 | `scripts/platforms/platform.gd`, `_apply_solid()` (código) | `_apply_solid(solid)` fijaba `_body.visible = solid`, así que `LETHAL` (que llama `_apply_solid(false)` para no colisionar) quedaba invisible en juego real, aunque se veía bien en el editor (`@tool`) | `_apply_solid(solid, body_visible = solid)`: `LETHAL` ahora llama `_apply_solid(false, true)` — no sólido pero visible. BREAKABLE al romperse sigue usando `_apply_solid(false)` (sin el segundo argumento), así que se sigue ocultando como corresponde | LT: reportó con capturas y log que `Sweeper` (Segment05, LETHAL móvil) mataba sin verse en pantalla. Confirmado headless: antes del fix, `LETHAL._body.visible=false`; después, `true` (estático y móvil). Regresión: `platform_test2` a `test6` y `check_seg_generic.gd` en los 6 segmentos, sin cambios de comportamiento salvo el bug arreglado | Pendiente que LT confirme jugando: Segment05 (Sweeper), Segment03/06 (Guard), Segment02 (Hazard) |

## Ronda 2: 10 segmentos nuevos para variedad de seeds

LT, tras confirmar que el fix de visibilidad de `LETHAL` quedó bien ("perfecto, ahora no está más el bug y las plataformas letales rojas son visibles"): "generarás 10 segmentos más y con esto tendremos mayor variedad en los seeds". Se diseñaron `Segment07`–`Segment16` (280–340 px de alto cada uno, más cortos que el estándar previo de 360, siguiendo el pedido de la ronda anterior de segmentos "un poco más cortos"), combinando las tipologías de `Platform` de formas no usadas todavía en el pool: escalera `ONE_WAY` con `LETHAL` de esquive, cascada de `BREAKABLE` contra ruta `TIMED`, corredor de doble `PULSE` en el mismo reloj, cruce de dos `LETHAL` móviles con bypass `ONE_WAY`, ferry hacia una `BREAKABLE`, `ONE_WAY` móvil (tipo no probado antes), escalada ajustada `TIMED`/`PULSE` con bonus `BREAKABLE`, tres caminos en paralelo, `LETHAL` móvil con recorrido **vertical** (todas las anteriores eran horizontales) y un cierre mixto con varias mecánicas juntas.

`resources/configs/level_config.tres`: `segment_pool` pasó de 6 a 16 escenas (se agregaron `Segment07`–`Segment16`). `avoid_repeat_window` subió de 1 a 3 (con un pool más grande, evitar repetir solo el último elegido dejaba poca variedad real). `segment_count` se dejó en 6 sin cambios: cuánto dura una partida es una decisión de diseño aparte (ver "Pendiente del backlog": duración), no algo que se deba mover al ampliar el pool.

Validado headless: los 16 segmentos del pool pasan `check_seg_generic.gd` (tanque presente, sin salidas de los límites, sin advertencias); las escenas `Main`, `Level` y `sandbox` cargan sin error; `LevelBuilder.build()` con 7 seeds distintas arma los 6 segmentos intermedios sin fallar y elige de los 16 índices del pool (se confirmó reparto entre todos, no solo los primeros 6); `platform_test2`–`test5` y el test de visibilidad de `LETHAL` siguen pasando sin cambios. De paso se encontró y borró una carpeta suelta (`Claude outputs/`, sin trackear en git) que había quedado de un paso anterior de esta sesión y rompía el reimport del proyecto (clase `Platform` duplicada).

Pendiente que LT juegue los 10 segmentos nuevos (aislados con F6, como se explica en `niveles-por-segmentos.md`, o directamente F5 con varias seeds) para confirmar que los saltos son alcanzables y que las combinaciones nuevas se sienten bien — en particular el `LETHAL` vertical (`Segment15`) y el `ONE_WAY` móvil (`Segment12`), que son mecánicas nuevas sin precedente en el pool.

## Cambios (una fila por parámetro)

| Ronda | Fecha | Parámetro | Valor anterior | Valor nuevo | Evidencia | Cómo se sintió |
|---|---|---|---|---|---|---|
| pre-tuning (brief 01) | 2026-09-20 | `gravity_with_fuel` | 30 | 150 | Juego de LT: con 30 el jugador quedaba flotando (el freno de 90 lo anulaba) | Reemplazado en la ronda 1 (ver abajo): con 150 el ascenso se sentía controlable, pero el salto se sentía más alto que el jetpack y la caída lenta y "clunky" |
| pre-tuning (brief 01) | 2026-09-20 | `wall_bounce` | 0.25 | 0.15 | Juego de LT | Ronda 1: bien así, no se toca |
| 1 | 2026-09-22 | `gravity_with_fuel` | 150 | 250 | LT pidió gravedad única (que no cambie al quedarse sin combustible) y una caída menos lenta. Simulación: a 250, caer 1 s da 127 px (76 px a 150); el ascenso a fondo con el jetpack baja solo de 177 a ~165 px/s | LT (checklist ronda 2 de esa sub-vuelta): "todos los cambios son buenos, el sistema se siente mucho mejor" |
| 1 | 2026-09-22 | `gravity_without_fuel` | 500 | 250 | Igualada a `gravity_with_fuel` a pedido explícito de LT ("debería ser la misma gravedad con y sin combustible, debemos encontrar el sweet spot"). Confirmado por simulación headless: `get_current_gravity()` da 250 tanto con combustible como después de vaciarlo | LT: bien, sensación mucho mejor |
| 1 | 2026-09-22 | `jump_velocity` | 260 (sin cambio) | 260 | Con la gravedad unificada en 250, el salto da ≈133 px de altura (antes ≈139 px con combustible o ≈55 px vacío, según el caso). Se deja sin cambiar hasta ver cómo se siente con la gravedad nueva | LT no pidió más cambios en la altura del salto; se deja en 260 |
| 1 | 2026-09-22 | `counter_thrust_multiplier` | 1.5 | 0.9 | LT: "el freno es demasiado brusco, cambio la dirección hacia abajo y ya empiezo a bajar". Simulación: frenar desde 180 px/s tarda 183 ms con 1.5 y 267 ms con 0.9 (no depende de la gravedad) | LT: freno más suave, bien |
| 1 | 2026-09-22 | `walk_acceleration` | 600 | 700 | LT: "caminar y saltar se siente muy tosco". Ajuste especulativo para emparejar el caminar con la sensación del jetpack (`thrust_acceleration` 700) | LT: "el salto con dirección funciona, creo que era una cuestión de la velocidad" |
| 1 | 2026-09-22 | `walk_max_speed` | 100 | 140 | Mismo motivo que `walk_acceleration`: 100 px/s es bajo frente a `max_speed` 180 del jetpack | LT: caminar se siente bien, resolvió el problema de "solo salta hacia arriba" |
| 1 | 2026-09-22 | `ground_friction` (parámetro nuevo, `PlayerConfig`) | — (no existía; el frenado en el piso usaba `coasting_drag`, 90) | 900 | LT tras jugar la primera parte de la ronda 1: "el jugador se desliza por las plataformas... debería ser menor el deslizamiento porque ya tiene los pies sobre la tierra". Requería código (frenado del piso separado del aire): LT eligió esa opción en vez de subir `coasting_drag` (que también habría frenado la inercia en el aire). Con 900, frenar desde `walk_max_speed` (140) tarda ≈0,16 s, contra ≈1,56 s que tardaría con `coasting_drag` (90) | LT: "caminar y frenar se siente bien", "el frenado tiene sentido, está bien". **Ronda 1 cerrada** ("no tengo más comentarios para esta etapa") |

### Nota de la ronda 1: caminar y saltar sin combustible (resuelta)

LT reportó que sin combustible "caminar y saltar no se puede, solo salta en dirección hacia arriba". Revisando `player.gd` no encontré una razón de código para que el salto perdiera el control horizontal (caminar no depende del combustible y esa velocidad se conserva al saltar). Se subió `walk_max_speed` a 140 por otro motivo (sensación tosca) y, jugado, resolvió también este punto: LT confirmó "el salto con dirección funciona, creo que era una cuestión de la velocidad". No hizo falta tocar código para esto.

### Código: `ground_friction` (ronda 1, commit aparte de los `.tres`)

`player_config.gd`: nuevo `@export var ground_friction: float = 900.0` en el grupo "Caminar", con comentario `##` explicando el porqué. `player.gd`, rama `elif not walking` de `_physics_process`: en vez de frenar siempre con `config.coasting_drag`, usa `config.ground_friction` si `on_floor` y `config.coasting_drag` si no (el frenado en el aire no cambió). `coasting_drag` se sigue usando igual que antes en `_apply_thrust` y `_apply_walk` (topes de velocidad), no se tocó. Validado: las tres escenas (`Main`, `Level`, `sandbox`) cargan sin errores por script headless; GDScript con tabulaciones (`grep -c $'^\t'` sobre `player.gd`: 158 líneas indentadas, sin cambios de estilo).

### Pendiente del backlog (anotado, no aplicado todavía)

- **Duración (LT, punto 1 de la ronda 1):** extender el nivel con más segmentos en vez de bajar `scroll_speed`. Se trabaja después de cerrar el layout de plataformas de la ronda 2 (el número de segmentos y su contenido dependen de cómo terminen los saltos).
- **Tentáculo con ataques (LT):** a futuro se puede sumar riesgo más allá de la velocidad de ascenso. Fuera de alcance del brief 06 salvo que LT lo pida entrar.
- **Exploración/descubrimiento de mecánicas (LT):** usar elementos existentes de forma que el jugador los descubra en juego. Se retoma cuando se trabaje el diseño de segmentos; no genera nivel nuevo ni arte nuevo.
- **Redecidir tanques (`fuel_amount`, cantidad por segmento):** se hace en la ronda 2, una vez que LT confirme el layout piloto de `Segment01` (para no rediseñar la ubicación de tanques dos veces).

## Valores finales del MVP

Se completa al cierre ("tuning cerrado").
