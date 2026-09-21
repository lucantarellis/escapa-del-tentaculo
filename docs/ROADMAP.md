# Roadmap — Escapa del Tentáculo

**Última actualización:** 2026-09-21
**Estado global:** v0 publicada. Mecánicas base (pasos 0 a 3) mergeadas a `main` (brief 01, PR #1). Obstáculos y tanques (pasos 4 y 4b) implementados y probados por LT en la rama `feature/obstaculos-tanques` (brief 02), pendientes de PR y merge a `main`.
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
| 5 | Puerta y victoria | Pendiente | — |
| 6 | Game manager y ciclo de partida | Pendiente | — |
| 7 | Nivel de prueba jugable | Pendiente | — |
| 8 | Pantalla de título, UI mínima, controles táctiles | Pendiente | — |
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

### Paso 7 — Nivel de prueba
`lvl1` armado con los bloques anteriores y jugado repetidamente para rebalancear.

### Paso 8 — Título, UI y táctil
Pantalla de título (ya descrita en el README), UI de combustible y distancia, y controles táctiles para la versión móvil (joystick o zonas táctiles que emitan las mismas acciones del Input Map).

### Paso 9 — Arte y audio
Integración de los tres sprite sheets (astronauta, tileset, tentáculo; el del tentáculo sigue pendiente de aprobación), audio y pulido.

## 6. Riesgos y decisiones abiertas

- **Espiral de muerte sin combustible.** Si el jugador se queda sin combustible lejos de una superficie, cae hacia el tentáculo. Hay que decidir en el diseño de niveles cuántos tanques hay y qué tan a mano quedan.
- **Niveles fijos o por segmentos.** Abierto. Si es por segmentos, los obstáculos y tanques deben ser escenas reutilizables desde el paso 4.
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
