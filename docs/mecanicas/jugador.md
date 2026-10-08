# Mecánica: jugador con jetpack

**Archivos:** `scripts/player/player.gd`, `scripts/player/player_config.gd`, `scripts/player/dash_cooldown_bar.gd`, `scenes/player/Player.tscn`, `resources/configs/player_config.tres`.
**Escena de prueba:** `scenes/levels/sandbox.tscn` (F6 en el editor). **Overlay de debug:** `scenes/ui/DebugOverlay.tscn` (F3).

## Propósito

Un astronauta que se mueve con un jetpack de combustible limitado. Es la mecánica central del juego: todo lo demás (scroll, tentáculo, obstáculos, tanques) existe para poner a prueba cómo se maneja el jetpack.

## Modelo físico en palabras simples

- **Propulsión.** Mientras se mantiene una dirección (WASD o flechas), el jugador *acelera* en esa dirección hasta un tope (`max_speed`). No hay velocidad instantánea: hay inercia.
- **Frenado suave.** Al soltar, la velocidad baja de a poco (`coasting_drag`). Ese valor define qué tan "flotante" se siente.
- **Contra-empuje.** Si se propulsa en sentido opuesto al movimiento, la aceleración se multiplica (`counter_thrust_multiplier`) en ese eje, para poder frenar rápido. Se evalúa por eje: en una diagonal, solo se potencia el eje que se opone.
- **Caminar.** Apoyado en una superficie, el eje horizontal se *camina*: acelera hasta `walk_max_speed` sin gastar combustible, tenga o no. El jetpack solo interviene para subir (arriba consume combustible). En el aire, la propulsión funciona como se describe arriba. Al soltar la entrada estando apoyado y sin propulsar, se frena con `ground_friction` (brief 06, ronda 1: antes usaba `coasting_drag`, el frenado del aire, y el jugador se deslizaba de más con los pies en el piso).
- **Gravedad única (brief 06, ronda 1).** `gravity_with_fuel` y `gravity_without_fuel` se llevaron al mismo valor: la gravedad ya no cambia al quedarse sin combustible. `gravity_transition_time` queda sin efecto práctico (ambas gravedades son iguales) pero no se quitó del código.
- **Salto.** Sin combustible y apoyado en una superficie, `jump` da un impulso hacia arriba (`jump_velocity`). Sirve para llegar a un tanque elevado. Con combustible no se puede saltar (configurable).
- **Rebote.** Al chocar contra una superficie a más de `bounce_min_speed`, se devuelve una fracción (`wall_bounce`) de la velocidad de impacto. Con 0 se detiene o desliza; con 1 rebota de forma elástica.
- **Dash lateral.** Con `dash` (Shift) el jugador se lanza en línea recta `dash_distance` px en `dash_duration` s, sin gravedad y sin control, en el aire o en el piso. Va hacia el lado que se mantiene (A/D o flechas); si no se mantiene ninguno, hacia el último lado pulsado (al empezar, derecha). Si además se mantiene arriba (W o ↑), sale en **diagonal hacia arriba** a 45°, recorriendo `dash_diagonal_distance` px en total en el mismo tiempo. Cuesta `dash_fuel_cost` u fijos (si hay menos, no se hace) y tiene un enfriamiento de `dash_cooldown` s contado desde que arranca. Al terminar queda con velocidad 0. Si choca con una pared o un techo se detiene ahí, sin rebote. **No es invulnerable:** un obstáculo o trampa en el camino lo mata (`obstacle` / `trap`). Mientras dura el enfriamiento aparece una barrita sobre la cabeza que se llena y desaparece (`show_cooldown_bar` la activa o desactiva).
- **Orden de cálculo por frame** (`_physics_process`): entrada → enfriamiento y dash (si está en curso, reemplaza todo lo que sigue) → caminar (si está apoyado) y/o propulsión, o frenado → gravedad → salto → movimiento y rebote → consumo de combustible → visuales.

## Parámetros (`PlayerConfig`)

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Propulsión | `thrust_acceleration` | float | 700 | px/s² | Aceleración al mantener una dirección | Más alto = respuesta más nerviosa |
| Propulsión | `max_speed` | float | 180 | px/s | Tope de velocidad al propulsar | Relacionarlo con `scroll_speed`: debe poder superarlo con margen |
| Propulsión | `counter_thrust_multiplier` | float | 0.9 | × | Multiplica la aceleración al oponerse a la velocidad | Brief 06, ronda 1: bajado de 1.5 (frenaba de forma muy brusca) |
| Propulsión | `coasting_drag` | float | 90 | px/s² | Frenado sin entrada | Bajo = deriva larga; alto = frena seco |
| Caminar | `walk_acceleration` | float | 700 | px/s² | Aceleración horizontal apoyado. No gasta combustible | Brief 06, ronda 1: subido de 600 |
| Caminar | `walk_max_speed` | float | 140 | px/s | Velocidad máxima caminando | Brief 06, ronda 1: subido de 100 (se sentía tosco) |
| Caminar | `ground_friction` | float | 900 | px/s² | Frenado horizontal apoyado y sin propulsar | Brief 06, ronda 1: parámetro nuevo (antes se usaba `coasting_drag`, pensado para el aire; LT reportó deslizamiento en el piso) |
| Gravedad | `gravity_with_fuel` | float | 250 | px/s² | Gravedad con combustible | Brief 06, ronda 1: unificada con `gravity_without_fuel` |
| Gravedad | `gravity_without_fuel` | float | 250 | px/s² | Gravedad sin combustible | Brief 06, ronda 1: igualada a `gravity_with_fuel` a pedido de LT |
| Gravedad | `gravity_transition_time` | float | 0.5 | s | Interpolación entre ambas gravedades | 0 = cambio instantáneo |
| Gravedad | `max_fall_speed` | float | 400 | px/s | Tope de velocidad de caída | Limita la caída, no frena una caída que ya lo superaba |
| Combustible | `max_fuel` | float | 100 | u | Capacidad | |
| Combustible | `starting_fuel` | float | 100 | u | Combustible al iniciar | |
| Combustible | `fuel_consumption_per_second` | float | 15 | u/s | Consumo mientras se propulsa | Con 15 u/s hay ~6,7 s de propulsión continua. Una de las dos variables de dificultad |
| Combustible | `min_fuel_to_thrust` | float | 0.0 | u | Umbral mínimo para propulsar | |
| Combustible | `fuel_regen_per_second` | float | 0.0 | u/s | Regeneración pasiva | 0 = solo tanques |
| Salto | `jump_velocity` | float | 260 | px/s | Impulso vertical del salto | Con gravedad 250 (única) sube ≈ 133 px; a revisar en próximas rondas |
| Salto | `jump_requires_empty_fuel` | bool | true | — | Solo saltar sin combustible | |
| Salto | `jump_empty_threshold` | float | 0.0 | u | Combustible ≤ este valor = "vacío" | También define gravedad alta y color rojo |
| Salto | `jump_requires_floor` | bool | true | — | Solo saltar apoyado | |
| Dash | `dash_distance` | float | 90 | px | Distancia que recorre el dash | Más alto = cruza más espacio de un tirón |
| Dash | `dash_diagonal_distance` | float | 90 | px | Distancia total del dash en diagonal hacia arriba (45°) | 0 desactiva solo el dash diagonal |
| Dash | `dash_duration` | float | 0.15 | s | Duración del dash (velocidad = distancia / duración) | Mínimo efectivo 0.01 |
| Dash | `dash_cooldown` | float | 1.0 | s | Espera entre dashes, contada desde que empieza uno | 0 = sin espera |
| Dash | `dash_fuel_cost` | float | 10 | u | Combustible fijo por dash | 7 o 12 para variar la dificultad. Con menos que esto no hay dash |
| Dash | `show_cooldown_bar` | bool | true | — | Muestra la barrita de enfriamiento sobre el jugador | Solo visual |
| Colisión | `wall_bounce` | float | 0.25 | 0 a 1 | Rebote al chocar | |
| Colisión | `bounce_min_speed` | float | 40 | px/s | Impacto mínimo para rebotar | **Parámetro agregado** (no estaba en el brief): sin él el jugador vibra al apoyarse |

> **Nota histórica.** Antes del brief 06 la gravedad con combustible (30) era menor que `coasting_drag` (90) y el jugador quedaba casi flotando al soltar. Desde el brief 06, ronda 1, la gravedad es única (250, igual con y sin combustible) y ya no depende de este balance.

## Señales

| Señal | Cuándo se emite |
|---|---|
| `fuel_changed(current, maximum)` | Cada vez que cambia el combustible (y al iniciar / reiniciar) |
| `fuel_depleted()` | Al quedar vacío |
| `fuel_refilled()` | Al recuperar combustible estando vacío |
| `thrust_started()` / `thrust_stopped()` | Al empezar / dejar de propulsar |
| `jumped()` | Al saltar |
| `died(cause: StringName)` | Al morir |
| `won()` | Al ganar (`win()`) |

## API pública

| Función | Descripción |
|---|---|
| `add_fuel(amount: float) -> void` | Suma combustible (tope `max_fuel`). Para los tanques (paso 4b) |
| `get_fuel_ratio() -> float` | Combustible de 0 a 1 |
| `is_fuel_empty() -> bool` | true si combustible ≤ `jump_empty_threshold` |
| `die(cause: StringName) -> void` | Desactiva el control y emite `died` |
| `win() -> void` | Desactiva el control, deja al jugador quieto y emite `won`. Se ignora si ya murió o ya ganó. Desde ahí `is_alive()` es `false`, así que ningún peligro lo afecta |
| `has_won() -> bool` | true si ganó |
| `reset(spawn_position: Vector2) -> void` | Vuelve a vivo, quieto y con combustible inicial. También lo descongela |
| `apply_config(config: PlayerConfig) -> void` | Cambia la config en plena partida (al entrar a un tier); conserva el combustible recortado al máximo nuevo |
| `launch(launch_velocity: Vector2, control_lock: float) -> void` | Descongela, asigna `velocity` y bloquea el Input (propulsión, caminata y salto) `control_lock` s; la inercia, la gravedad y las colisiones siguen. `reset()` anula el bloqueo. La usa la intro al romperse la escotilla |
| `is_control_locked() -> bool` | true mientras dura el bloqueo del Input |
| `set_frozen(frozen: bool) -> void` | `true`: oculta el cuerpo y el indicador de propulsión, detiene `_physics_process` y desactiva la colisión. `false`: lo revierte. La intro lo usa mientras el jugador está "detrás de la escotilla" |
| `is_frozen() -> bool` | true si está congelado |
| `can_dash() -> bool` | true si puede hacer un dash ya: vivo, sin bloqueo de control, sin dash en curso, sin enfriamiento y con combustible suficiente |
| `is_dashing() -> bool` | true mientras dura el dash |
| `get_dash_cooldown_ratio() -> float` | Avance del enfriamiento de 0 a 1 (1 = listo). Lo usa la barrita |
| `get_fuel() -> float`, `is_thrusting() -> bool`, `can_jump() -> bool`, `get_current_gravity() -> float`, `is_alive() -> bool` | Consultas de estado (agregadas; las usa el overlay de debug). Ojo: `is_alive()` es "la partida sigue en curso para el jugador": devuelve `false` tras morir **y** tras ganar |

## Estructura de nodos

```
Player (CharacterBody2D, grupo "player", capa 2, máscara 1)
├── Body (Polygon2D, 16×24, naranja; rojo sin combustible)
├── CollisionShape2D (RectangleShape2D 16×24)
├── ThrustIndicator (Polygon2D pequeño, blanco azulado, aparece hacia la dirección de propulsión)
└── DashCooldownBar (Node2D con `DashCooldownBar`, 16×3 px sobre la cabeza, blanco azulado; solo visible durante el enfriamiento)
```

## Cómo probarlo

1. Abrir `scenes/levels/sandbox.tscn` y ejecutar con F6.
2. Mover con WASD o flechas; F3 muestra u oculta el overlay con velocidad, combustible, gravedad y estado.
3. Shift hace el dash (con W apretado, en diagonal hacia arriba): probar a la izquierda y a la derecha, en el aire y en el piso, contra una pared, con poco combustible (con menos de `dash_fuel_cost` no sale) y viendo la barrita durante 1 s.
4. Editar `resources/configs/player_config.tres` en el inspector (con el juego cerrado) y volver a ejecutar. Los valores que se ajustan mientras se prueba son de prueba, no de balance: no se anotan en `docs/TUNING_LOG.md`.
