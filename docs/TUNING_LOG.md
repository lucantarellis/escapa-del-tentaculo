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

## Cambios (una fila por parámetro)

| Ronda | Fecha | Parámetro | Valor anterior | Valor nuevo | Evidencia | Cómo se sintió |
|---|---|---|---|---|---|---|
| pre-tuning (brief 01) | 2026-09-20 | `gravity_with_fuel` | 30 | 150 | Juego de LT: con 30 el jugador quedaba flotando (el freno de 90 lo anulaba) | Reemplazado en la ronda 1 (ver abajo): con 150 el ascenso se sentía controlable, pero el salto se sentía más alto que el jetpack y la caída lenta y "clunky" |
| pre-tuning (brief 01) | 2026-09-20 | `wall_bounce` | 0.25 | 0.15 | Juego de LT | Ronda 1: bien así, no se toca |
| 1 | 2026-09-22 | `gravity_with_fuel` | 150 | 250 | LT pidió gravedad única (que no cambie al quedarse sin combustible) y una caída menos lenta. Simulación: a 250, caer 1 s da 127 px (76 px a 150); el ascenso a fondo con el jetpack baja solo de 177 a ~165 px/s | Pendiente de que LT lo juegue (checklist ronda 2) |
| 1 | 2026-09-22 | `gravity_without_fuel` | 500 | 250 | Igualada a `gravity_with_fuel` a pedido explícito de LT ("debería ser la misma gravedad con y sin combustible, debemos encontrar el sweet spot"). Confirmado por simulación headless: `get_current_gravity()` da 250 tanto con combustible como después de vaciarlo | Pendiente |
| 1 | 2026-09-22 | `jump_velocity` | 260 (sin cambio) | 260 | Con la gravedad unificada en 250, el salto da ≈133 px de altura (antes ≈139 px con combustible o ≈55 px vacío, según el caso). Se deja sin cambiar hasta ver cómo se siente con la gravedad nueva | Pendiente. Si sigue sintiéndose "más alto que el jetpack" se ajusta en la ronda 2 |
| 1 | 2026-09-22 | `counter_thrust_multiplier` | 1.5 | 0.9 | LT: "el freno es demasiado brusco, cambio la dirección hacia abajo y ya empiezo a bajar". Simulación: frenar desde 180 px/s tarda 183 ms con 1.5 y 267 ms con 0.9 (no depende de la gravedad) | Pendiente |
| 1 | 2026-09-22 | `walk_acceleration` | 600 | 700 | LT: "caminar y saltar se siente muy tosco". Ajuste especulativo para emparejar el caminar con la sensación del jetpack (`thrust_acceleration` 700); a confirmar jugando | Pendiente |
| 1 | 2026-09-22 | `walk_max_speed` | 100 | 140 | Mismo motivo que `walk_acceleration`: 100 px/s es bajo frente a `max_speed` 180 del jetpack, lo que puede hacer que el impulso horizontal de un salto se note poco | Pendiente |

### Nota de la ronda 1: caminar y saltar sin combustible

LT reportó que sin combustible "caminar y saltar no se puede, solo salta en dirección hacia arriba". Revisando `player.gd`: el salto (`_try_jump`) no depende del combustible salvo que `jump_requires_empty_fuel` lo pida (está en `false`), y caminar (`_apply_walk`) tampoco consume ni depende de combustible; la velocidad horizontal de caminar se conserva al saltar y decae con `coasting_drag` en el aire. No encontré una razón en el código para que el salto pierda el control horizontal por completo. Dos hipótesis, para confirmar jugando con los valores nuevos (`walk_max_speed` 140, `coasting_drag` sin cambiar en 90): (a) es un problema de sensación por velocidades bajas, que esta ronda ya ajusta; (b) el jugador quiere control horizontal en el aire independiente del combustible (hoy en el aire sin apoyo el movimiento horizontal es propulsión, que si no hay combustible no hace nada) — **si esto último es lo que hace falta, es un cambio de mecánica (código), y lo consulto antes de tocar nada.**

### Pendiente del backlog (anotado, no aplicado en esta ronda)

- **Duración (LT, punto 1):** extender el nivel con más segmentos en vez de bajar `scroll_speed`. Se trabaja en la ronda de "Nivel" (backlog área 5), no en esta.
- **Exigencia por salto/combustible (LT, puntos 2 y 5):** diseñar para que la mayoría de las plataformas se alcancen saltando, y usar el combustible como decisión táctica, no como requisito. Necesita el bot de alcanzabilidad (herramienta pendiente) antes de tocar el diseño de segmentos.
- **Tentáculo con ataques (LT, punto 4):** a futuro se puede sumar riesgo más allá de la velocidad de ascenso. Fuera de alcance del brief 06 salvo que LT lo pida entrar.
- **Exploración/descubrimiento de mecánicas (LT, punto 6):** usar elementos existentes de forma que el jugador los descubra en juego (por ejemplo, introducir un tipo de obstáculo o pickup ya construido en un segmento donde antes no aparecía). Se retoma cuando se trabaje el diseño de segmentos; no genera nivel nuevo ni arte nuevo.

## Valores finales del MVP

Se completa al cierre ("tuning cerrado").
