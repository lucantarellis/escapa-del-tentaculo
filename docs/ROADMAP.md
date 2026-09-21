# Roadmap — Escapa del Tentáculo

**Última actualización:** 2026-09-21
**Estado global:** v0 publicada. Mecánicas base (pasos 0 a 3) mergeadas a `main` (brief 01, PR #1). Obstáculos y tanques (pasos 4 y 4b) mergeados a `main` (brief 02, PR #2). Puerta, game manager y niveles por segmentos (pasos 5, 6 y 7) mergeados a `main` (brief 03, PR #3). Pantalla de título (paso 8) y HUD mínimo (paso 8b) hechos, probados por LT y mergeados a `main` (brief 04, PR #4). Brief 05 en curso (rama `feature/intro-escotilla`): intro de la escotilla, pasos 8d y 8e. Los controles táctiles (paso 8c) quedan para el final, después del arte y el balance.
**Cómo usar este documento:** es la fuente de verdad del plan. Cada brief para Cowork se genera desde `docs/briefs/BRIEF_TEMPLATE.md` y, al cerrarse, actualiza la tabla de estado (sección 4) y el registro de decisiones (sección 2).

---

## 1. Visión y alcance

Un astronauta escapa de un tentáculo alienígena dentro de una nave. La pantalla sube a velocidad constante, el tentáculo permanece al borde inferior y el jugador usa un jetpack con combustible limitado para esquivar obstáculos y llegar a una puerta antes de ser atrapado.

**Etapa actual:** prototipo de mecánicas con polígonos placeholder (`Polygon2D`). Nada de arte final hasta que las mecánicas se sientan bien. El arte (sprite sheets del astronauta, tileset y tentáculo) se integra en la etapa final.

## 2. Decisiones de diseño

| Tema | Decisión | Origen |
|---|---|---|
| Motor / lenguaje | Godot 4.7.2 stable, GDScript con tipado estático | LT |
| Estilo | 2D, pixel art. Placeholders con `Polygon2D` durante el prototipo | LT |
| Plataforma | Prototipo en PC con teclado. Versión final en móvil (táctil) | LT |
| Orientación / viewport | Vertical, 360×640 (escala 1.5× a 540×960 en la ventana de PC) | Propuesta de Claude, pendiente de validar jugando |
| Control | Mantener apretada una dirección propulsa en esa dirección (arriba, abajo, izquierda, derecha; combinables) | LT |
| Física | Gravedad casi nula, pero no cero, mientras hay combustible. Movimiento con inercia configurable, arrancando con deriva suave | LT |
| Combustible | Cantidad limitada. Se recarga solo con tanques recogibles | LT (límite) / Propuesta de Claude (solo con tanques) |
| Sin combustible | La gravedad sube a un valor normal y el jugador puede saltar desde una superficie para alcanzar un tanque elevado | LT (salto) / Propuesta de Claude (detalle), parametrizado |
| Scroll | La cámara sube a velocidad constante configurable | Propuesta de Claude |
| Tentáculo | Anclado al borde inferior de la cámara. Contacto = derrota | LT |
| Parametrización | Todo valor de gameplay es una variable exportada en un `Resource` de configuración, para iterar y descubrir qué es divertido | LT |
| Documentación | Obligatoria: cualquier persona debe poder entender el código leyendo `docs/` y los comentarios | LT |
| Teclas | WASD y flechas para propulsar, Espacio para saltar, R reinicia, F3 debug | Propuesta de Claude |
| Idioma | Identificadores de código en inglés; comentarios y documentos en español | Propuesta de Claude |
| Caminar | Apoyado en una superficie, el eje horizontal se camina sin gastar combustible (con o sin él). El jetpack solo se usa para subir. Parámetros `walk_acceleration` y `walk_max_speed` | LT (brief 01, paso 1) |
| Salto con combustible | `jump_requires_empty_fuel` es configurable; LT lo dejó en `false` en sus pruebas para poder saltar y propulsar a la vez. El default del script sigue en `true`: decidir el valor final al balancear | LT (a decidir) |
| Coordenada de `stop_at_y` | Es la Y (mundo) del centro de la cámara, no del borde | Propuesta de Claude (brief 01, paso 2) |
| Tentáculo: caída | La zona letal se extiende 96 px bajo la pantalla, por lo que la muerte por caída (`&"fell"`) es una red de seguridad: normalmente el contacto ocurre antes | Propuesta de Claude (brief 01, paso 3) |
| Colores de placeholder | Rojo `#D83232` = letal (tentáculo, obstáculos, trampa activa). Cian `#63D6C5` = recogible / bueno (tanques) | LT (brief 02) |
| Obstáculos y tanques | Son escenas reutilizables, configurables por instancia (tamaño, recorrido, config `.tres`), para que el diseño de niveles (fijo o por segmentos) siga abierto | LT (brief 02) |
| Valores de prueba | Los `.tres` de configuración son valores de prueba de LT, no finales. Sus ajustes durante las pruebas no se registran en `docs/TUNING_LOG.md` (solo se usa para pruebas reales de balance) | LT |
| Trampa intermitente | Es sólida mientras es segura (inactiva o en aviso) para poder apoyarse encima; al activarse pasa a letal | LT (brief 02, paso 4) |
| Causas de muerte | `&"tentacle"`, `&"fell"`, `&"obstacle"`, `&"trap"`. La muerte es siempre `Player.die(cause)` y el controlador escucha `Player.died(cause)` | Propuesta de Claude (brief 02) |
| Fin de partida (MVP) | Al llegar a la puerta el jugador gana y el juego termina; se reinicia con R. Puntaje u otra progresión: a definir más adelante (no implementado, pero el estado queda desacoplado) | LT (brief 03) |
| Niveles por segmentos | Cada partida ensambla segmentos escritos a mano (escenas de 360 px de ancho) elegidos al azar con una seed reproducible. Resuelve la decisión abierta de niveles fijos vs. por segmentos | LT (brief 03) |
| `GameManager` | Autoload que lleva el estado de la partida (`READY`, `PLAYING`, `WON`, `LOST`) y avisa con señales; no conoce nodos de la escena | Propuesta de Claude, validada por LT (brief 03) |
| Naranja = meta | Naranja `#FF6B32` = objetivo/meta (la puerta) | LT (brief 03) |
| UI del MVP | Solo el mensaje de fin de partida (victoria o derrota) y el overlay F3 existente; el resto de la UI queda para los pasos 8 y 8b | Propuesta de Claude (brief 03) |
| HUD minimalista | Solo barra de combustible y progreso del nivel (altura recorrida entre spawn y puerta). Sin puntaje, seed, botón de reinicio ni distancia numérica. Solo lectura | LT (brief 04) |
| Transición título → juego | `Main` instancia `Level.tscn` detrás del menú, en pausa; al pulsar JUGAR el menú se disuelve y la partida arranca. R reinicia directo al juego (nivel nuevo) sin volver al título | LT (brief 04) |
| Intro de la escotilla | Al pulsar JUGAR la cámara vibra tres veces (golpes del tentáculo) con gas que escapa de una escotilla en la parte inferior del nivel; la escotilla se rompe, el jugador (que estaba detrás, no visible) sale disparado hacia arriba y al rato aparece el tentáculo como hoy. R repite la intro (decisión posterior de LT: antes la saltaba). Todo con polígonos placeholder | LT (post-QA del brief 04); se implementa en el brief 05 |
| Intro: director y escena propia | La secuencia la orquesta `IntroDirector` (llama hacia abajo a `Hatch`, `ScrollCamera`, `Player` y `Tentacle`; emite `hit`, `broken`, `finished`). La escotilla es una escena propia (`Hatch.tscn`). Todos los tiempos y magnitudes viven en `IntroConfig` | Propuesta de Claude (brief 05), pendiente de validar jugando |
| Intro: cuándo se reproduce | Al pulsar JUGAR y con cada R (`Main` reconstruye el nivel y llama a `LevelController.play_intro()`). `Level.tscn` (F6) y `sandbox.tscn` solos la saltan: escotilla ya rota, tentáculo activo desde el primer frame y jugador en el `PlayerSpawn` (sin lanzamiento). R durante la intro no hace nada (`GameManager` en `READY`) | Propuesta de Claude (brief 05) |
| Intro: `start_delay` | Sin cambios: la cámara empieza a subir `start_delay` s después de la ruptura (inicio de la partida) | Propuesta de Claude (brief 05) |
| Intro: escotilla centrada y vuelo | La escotilla va centrada. El segmento de inicio mide 1100 px con un pasillo central libre para el vuelo (~640 px de altura); durante el vuelo la cámara sube lo necesario para que el jugador nunca salga de la vista (`ScrollCamera.follow_up`) | LT (QA del paso 8e) |
| Controles táctiles | Se implementan al final (paso 8c), cuando lo demás esté cerrado. Mientras tanto, solo teclado | LT (brief 04) |
| Escena principal | `run/main_scene` seguirá siendo `Main.tscn`, que será la pantalla de título: título del juego y un botón grande de "jugar". Al pulsarlo el menú se disuelve hasta quedar transparente e inicia el juego sobre la escena de juego correspondiente (`Level.tscn`). `Level.tscn` no es la escena principal | LT (brief 03, cierre); se implementa en el paso 8 |
| Tentáculo al final del nivel | Cuando la cámara se detiene en el final del nivel, el tentáculo sigue subiendo (`end_rise_speed`) hasta cubrir la pantalla: no hay refugio esperando. Se congela al ganar o perder | LT (QA del paso 7) |
| Tanques por segmento | Los segmentos tienen dos tanques cada uno (más uno en inicio y final): con uno solo un nivel de 8 segmentos no se puede completar con los valores de prueba. Se rebalancea con el MVP | Propuesta de Claude (brief 03, paso 7) |
| Tanques | `fuel_amount` 40 u (con `max_fuel` 100), un solo uso por defecto (`respawn_time` 0). El sobrante sobre `max_fuel` se pierde. Un tanque medido en simulación rinde ~489 px de subida vertical y un salto sin combustible ~61 px (referencias para el diseño de niveles, ver `docs/mecanicas/tanques.md`) | Propuesta de Claude (brief 02, paso 4b), probado por LT |

## 3. Principios de ingeniería

1. **Parametrizar todo.** Sin números mágicos en scripts. Los valores viven en `Resource` (`PlayerConfig`, `ScrollConfig`, `TentacleConfig`, …) editables desde el inspector y guardados como `.tres` en `resources/configs/`.
2. **Documentar como parte de "hecho".** Comentarios `##` en clases, variables exportadas, señales y funciones públicas (aparecen en la ayuda del editor). Un documento por mecánica en `docs/mecanicas/`.
3. **Input por acciones, nunca por teclas.** Facilita el control táctil final sin tocar la lógica del jugador.
4. **Señales hacia arriba, llamadas hacia abajo.** Una escena hija emite señales; el padre la controla. Evita dependencias cruzadas entre escenas.
5. **Un paso = algo jugable.** Al cerrar cada paso hay una checklist de prueba manual que LT juega antes de seguir.
6. **Registro de tuning.** `docs/TUNING_LOG.md` es solo para pruebas reales de balance, cuando LT lo pide. Los valores que LT ajusta mientras prueba una checklist son valores de prueba y no se anotan.
7. **Git.** Rama por brief, un commit por paso, sin push ni PR sin confirmación de LT. Los `.tscn` dan conflictos de merge: LT y su socio coordinan quién toca cada escena.

## 4. Estado por paso

| # | Paso | Estado | Brief |
|---|---|---|---|
| — | v0: estructura y repo | Hecho | brief v0 |
| 0 | Preparación: input, capas, viewport, convenciones, docs | Hecho | brief-01 |
| 1 | Jugador con jetpack y combustible | Hecho | brief-01 |
| 2 | Scroll y cámara | Hecho | brief-01 |
| 3 | Tentáculo y condición de derrota | Hecho | brief-01 |
| 4 | Obstáculos | Hecho | brief-02 |
| 4b | Tanques de combustible | Hecho | brief-02 |
| 5 | Puerta y victoria | Hecho | brief-03 |
| 6 | Game manager y ciclo de partida | Hecho | brief-03 |
| 7 | Niveles por segmentos | Hecho | brief-03 |
| 8 | Pantalla de título y transición al juego | Hecho | brief-04 |
| 8b | HUD mínimo (combustible y progreso) | Hecho | brief-04 |
| 8d | Intro de la escotilla: escotilla, tres golpes de cámara y gas | En brief | brief-05 |
| 8e | Intro de la escotilla: ruptura, lanzamiento del jugador y entrada del tentáculo | En brief | brief-05 |
| 8c | Controles táctiles | Pendiente (al final, tras arte y balance) | — |
| 9 | Arte final, audio y pulido | Pendiente | — |

Estados posibles: Pendiente, En brief, En curso, Hecho.

## 5. Detalle de pasos

### Paso 0 — Preparación
Configurar viewport y stretch, Input Map, nombres de capas de colisión, y crear la documentación base (`CONVENCIONES.md`, `ARQUITECTURA.md`, `TUNING_LOG.md`, plantilla de briefs).
**Hecho cuando:** el proyecto abre sin errores y las convenciones están escritas.

### Paso 1 — Jugador con jetpack
Personaje con propulsión en 4 direcciones, inercia, combustible, gravedad dependiente del combustible y salto sin combustible. Escena de prueba `sandbox` y overlay de debug.
**Hecho cuando:** todos los valores son ajustables desde un `PlayerConfig` y el movimiento se puede jugar y calibrar.

### Paso 2 — Scroll y cámara
Cámara que sube a velocidad configurable, con paredes invisibles laterales y superior que siguen a la cámara.
**Hecho cuando:** el jugador no puede salir por los lados ni por arriba y la velocidad de scroll es un parámetro.

### Paso 3 — Tentáculo
Placeholder anclado al borde inferior, con zona letal. Caer bajo la pantalla también mata. Reinicio temporal con R.
**Hecho cuando:** existe derrota por contacto y por caída, con señal `player_caught`.

### Paso 4 — Obstáculos
Un bloque estático primero (valida colisión y muerte). Luego variantes móviles y trampas, cada una como escena reutilizable.
**Hecho (brief 02):** `Obstacle`, `MovingObstacle` y `PulseTrap` con sus configs. Ver `docs/mecanicas/obstaculos.md`.

### Paso 4b — Tanques de combustible
Recogible que llama a `Player.add_fuel()`. Su ubicación (por ejemplo en plataformas elevadas, que solo se alcanzan saltando) es una herramienta de diseño de niveles.
**Hecho (brief 02):** `FuelTank` con `FuelTankConfig`; 4 tanques en el sandbox. Ver `docs/mecanicas/tanques.md`.

### Paso 5 — Puerta y victoria
`Area2D` al final del nivel. Al entrar el jugador, se gana.

### Paso 6 — Game manager
Autoload con estados (jugando, ganó, perdió) y reinicio. Reemplaza el reinicio temporal del paso 3.

### Paso 7 — Niveles por segmentos
Cada partida arma un nivel distinto ensamblando segmentos (escenas escritas a mano) elegidos al azar con una seed reproducible; el nivel termina en una puerta. El balance se hace después, con el MVP completo.

### Paso 8 — Pantalla de título y transición
Pantalla de título en `Main.tscn` (escena principal): título del juego y un botón grande de jugar sobre `Level.tscn` ya armado y en pausa. Al pulsarlo el menú se disuelve hasta quedar transparente y arranca la partida. R reinicia directo al juego con un nivel nuevo (señal `restart_requested` del `GameManager`; `LevelController` gana `autostart` y `begin()`).
**Hecho cuando:** F5 abre el título, JUGAR inicia la partida tras el fundido y R reinicia sin volver al título; `Level.tscn` y `sandbox.tscn` siguen funcionando solos con F6.

### Paso 8b — HUD mínimo
Barra de combustible (naranja, roja al vaciarse) y progreso del nivel (0 % en el spawn, 100 % en la puerta), muy discretos, de solo lectura, visibles solo durante la partida.
**Hecho cuando:** ambos indicadores siguen al jugador, se reinician con R y no tapan el juego ni el mensaje de fin.

### Paso 8d — Intro de la escotilla: golpes y gas
Al pulsar JUGAR se ve una escotilla abajo (sin tentáculo ni jugador); la cámara vibra tres veces y en cada golpe sale gas. Nuevos: `IntroConfig`, `Hatch`, `IntroDirector`, `ScrollCamera.shake`, `Player.set_frozen`, `Tentacle.set_active`, `LevelController.play_intro()`. Al terminar los golpes la partida arranca como hoy.
**Hecho cuando:** la secuencia de golpes se ve y se siente bien, no se mueve nada más durante la intro y R, `Level.tscn` y `sandbox.tscn` siguen sin intro.

### Paso 8e — Intro de la escotilla: ruptura y lanzamiento
Tras el tercer golpe la escotilla se rompe, el jugador sale disparado hacia arriba (`Player.launch`, control bloqueado un instante), empieza la partida y, tras un retraso, el tentáculo entra desde abajo (`Tentacle.enter`). La red de seguridad de caída está activa desde el inicio de la partida.
**Hecho cuando:** la secuencia completa funciona y ganar, perder y R siguen igual.

### Paso 8c — Controles táctiles (diferido al final)
Joystick o zonas táctiles que emitan las mismas acciones del Input Map, para la versión móvil. Se hace después del arte y el balance.

### Paso 9 — Arte y audio
Integración de los tres sprite sheets (astronauta, tileset, tentáculo; el del tentáculo sigue pendiente de aprobación), audio y pulido.

## 6. Riesgos y decisiones abiertas

- **Espiral de muerte sin combustible.** Si el jugador se queda sin combustible lejos de una superficie, cae hacia el tentáculo. Hay que decidir en el diseño de niveles cuántos tanques hay y qué tan a mano quedan.
- **Controles táctiles.** Propulsión en 4 direcciones mantenida por dedo sugiere joystick virtual. Conviene prototiparlo antes de la etapa final, no después.
- **Muerte por caída sin probar por LT.** El checklist del paso 3 (caer bajo el borde) se verificó por simulación, pero LT no lo probó jugando.
- **Comportamiento del tentáculo.** Por ahora solo sube con la cámara. Ataques o variaciones quedan para más adelante.
- **Escalado pixel-perfect.** Durante el prototipo se usa escalado fraccional. La decisión de escalado entero se toma con el arte final.
- **Curva de dificultad.** La velocidad de scroll y el consumo de combustible son las dos variables que más la definen.

## 7. Backlog de ideas (sin compromiso)

- Panel de tuning en juego con sliders sobre los `Resource` de configuración.
- Presets de configuración (por ejemplo "flotante", "arcade") como archivos `.tres` intercambiables.
- Aceleración progresiva del scroll a lo largo del nivel.
- Coyote time en el salto.

## 8. Cómo crear un brief nuevo

1. Copiar `docs/briefs/BRIEF_TEMPLATE.md` a `docs/briefs/brief-NN-<tema>.md`.
2. Completar contexto, decisiones ya tomadas y pasos, tomando las secciones 2 y 3 de este roadmap como fuente.
3. Pegarlo en una conversación nueva de Claude (Cowork) junto con este roadmap.
4. Al terminar, actualizar la tabla de la sección 4 y las secciones 2 y 6 si hubo decisiones nuevas.
