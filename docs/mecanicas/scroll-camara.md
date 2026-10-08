# Mecánica: scroll y cámara

**Archivos:** `scripts/camera/scroll_camera.gd`, `scripts/camera/scroll_config.gd`, `scenes/camera/ScrollCamera.tscn`, `resources/configs/scroll_config.tres`.
**Escena de prueba:** `scenes/levels/Level.tscn` (F6).

## Propósito

La cámara **sigue al jugador**: sube cuando él sube y baja cuando él baja, y lo mantiene en una zona fija de la pantalla. Lo que empuja es el tentáculo (ver `tentaculo.md`), que sube solo. La cámara también encierra al jugador con paredes invisibles laterales y superior.

Existe un modo anterior (`follow_player` apagado): la cámara sube sola a `scroll_speed` y empuja al jugador hacia arriba.

## Modelo en palabras simples

- **Sigue al jugador (por defecto, `follow_player`).** Cada tick de física la cámara se acerca a la Y que deja al jugador a `follow_screen_ratio` de la altura de la pantalla medida desde arriba (0,6 = a 60 %, algo por debajo del centro, para ver más hacia arriba). Sube y baja. El acercamiento es suave: cubre la fracción `1 - e^(-follow_smoothing × delta)` de la distancia por tick (con 6, queda a menos del 0,3 % en 1 s; con 0 va pegada).
- **Nunca baja de donde arrancó (`follow_stay_above_start`, por defecto true).** El jugador aparece más abajo que el 60 % de la pantalla (86 % en el nivel armado); sin este límite la cámara bajaría ~164 px al empezar y se vería el vacío. Con el límite la cámara sube con el jugador y vuelve hasta su posición inicial, no más abajo. Con false baja sin límite.
- **Modo anterior (`follow_player` = false).** Cada tick resta `scroll_speed × delta` a la Y de la cámara (con aceleración opcional). No mira al jugador: solo sube, y el tentáculo va anclado a su borde inferior.
- **Sincronización con el jugador.** `process_callback` está en física y no hay suavizado de posición, así que cámara y jugador se actualizan en el mismo ciclo y no se desfasan. Con el snap a píxel activado, en pantallas con pocos píxeles por unidad puede notarse un salto de 1 px; si molesta, se decide con el arte final (escalado entero).
- **Espera inicial.** En el modo anterior, durante `start_delay` la cámara está quieta. Siguiendo al jugador no hay espera: la cámara se queda en su posición inicial hasta que el jugador sube por encima de la altura deseada (con `follow_screen_ratio` 0,6 y cámara en 320, Y < 384) y desde ahí lo sigue sin salto. `is_scroll_active()` sí respeta `start_delay` (lo usa el tentáculo para empezar a subir).
- **Aceleración opcional (solo modo anterior).** Con `scroll_acceleration` > 0 la velocidad crece desde `scroll_speed` hasta `max_scroll_speed`.
- **Fin opcional.** Con `stop_at_enabled` (o `set_stop_y`), la cámara no sube más allá de `stop_at_y`. En el modo anterior se detiene ahí y emite `scroll_stopped`. Siguiendo al jugador solo se limita la altura: `has_reached_end()` es true mientras esté en el tope y vuelve a false si el jugador baja.
- **Límites.** `ScreenBounds` es un `StaticBody2D` (capa 1) hijo de la cámara, con tres formas rectangulares (izquierda, derecha, arriba) dimensionadas en `_ready` desde el tamaño visible (viewport ÷ zoom). Al ser hijo de la cámara, se mueve con ella. No hay pared inferior: caer bajo el borde inferior es derrota (paso 3). Las paredes laterales se extienden 64 px por encima y por debajo de la pantalla.
- **Coordenadas.** `stop_at_y` es la Y del **centro** de la cámara en coordenadas del mundo (Y negativa = arriba). El borde inferior visible es `centro + alto_visible / 2`.

## Parámetros (`ScrollConfig`)

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Seguimiento | `follow_player` | bool | true | — | La cámara sigue al jugador (sube y baja). false = modo anterior | |
| Seguimiento | `follow_screen_ratio` | float | 0.6 | fracción | Dónde se ve al jugador, desde el borde superior (0 arriba, 1 abajo) | Más alto = ve más hacia arriba |
| Seguimiento | `follow_smoothing` | float | 6.0 | 1/s | Qué tan pegada va la cámara (0 = pegada) | Más bajo = más suave y con más retraso |
| Seguimiento | `follow_stay_above_start` | bool | true | — | La cámara no baja de su posición inicial | Apagarlo muestra el vacío al empezar |
| Scroll | `scroll_speed` | float | 40 | px/s | Velocidad de ascenso. Solo con `follow_player` apagado | Junto con el consumo de combustible, define la dificultad. Debe ser bastante menor que `max_speed` del jugador (180) |
| Scroll | `scroll_acceleration` | float | 0.0 | px/s² | Aumento progresivo (0 = constante). Solo con `follow_player` apagado | Valores chicos (1–5) ya se sienten a lo largo de un nivel |
| Scroll | `max_scroll_speed` | float | 120 | px/s | Tope con aceleración. Solo con `follow_player` apagado | |
| Scroll | `start_delay` | float | 2.0 | s | Espera antes de subir (modo anterior) y antes de que el tentáculo empiece a subir. La cámara que sigue al jugador no la espera | |
| Fin | `stop_at_enabled` | bool | false | — | Detener la cámara en `stop_at_y` | |
| Fin | `stop_at_y` | float | -2400 | px | Y del centro de la cámara donde se detiene | Ponerlo donde el borde superior alcance el final del nivel |
| Límites | `side_walls_enabled` | bool | true | — | Paredes laterales | |
| Límites | `top_wall_enabled` | bool | true | — | Pared superior | |
| Límites | `top_wall_margin` | float | 0 | px | Separación de la pared superior respecto del borde (positivo = más adentro) | Se aplica al construir los límites en `_ready` |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `scroll_started()` | La cámara se pone en marcha (termina `start_delay` o se reanuda) |
| `scroll_stopped()` | La cámara se detiene (`set_scrolling(false)`, llegó a `stop_at_y` en el modo anterior o se reinició) |

## API pública

| Función | Descripción |
|---|---|
| `set_scrolling(enabled: bool) -> void` | Pausa o reanuda el scroll (al reanudar no repite `start_delay`) |
| `is_scroll_active() -> bool` | true mientras la cámara está activa (pasó `start_delay` y no está pausada ni detenida). El tentáculo lo usa para empezar a subir |
| `is_following_player() -> bool` | true si `follow_player` está activo. El tentáculo lo usa para elegir su modelo |
| `get_bottom_y() -> float` | Y (mundo) del borde inferior de la pantalla. La usa el tentáculo |
| `get_visible_rect() -> Rect2` | Rectángulo del mundo que se ve ahora |
| `follow_up(target: Node2D, top_margin: float) -> void` | Hace que la cámara suba lo necesario para que `target` no quede a menos de `top_margin` px del borde superior (solo sube; respeta el tope de scroll; el scroll normal sigue). La usa la intro durante el vuelo |
| `stop_following() -> void`, `is_following() -> bool` | Deja de seguir / consulta. `reset()` también lo cancela |
| `shake(amplitude: float, duration: float) -> void` | Vibra `Camera2D.offset` (magnitud `amplitude` px que decae a 0 en `duration` s; termina en `Vector2.ZERO`). No toca `global_position`. Usa un `Tween` del `SceneTree`, así que sigue corriendo con el nivel en pausa. Una llamada nueva pisa la anterior. La usa la intro (`docs/mecanicas/intro-escotilla.md`) |
| `reset() -> void` | Vuelve a la posición inicial (la de la escena) y reinicia velocidad, espera y estado de fin. Cancela la vibración |

## Estructura de nodos

```
ScrollCamera (Camera2D, process_callback = Physics, sin suavizado)
└── ScreenBounds (StaticBody2D, capa 1)
    ├── LeftShape (CollisionShape2D)
    ├── RightShape (CollisionShape2D)
    └── TopShape (CollisionShape2D)
```

## Tope por instancia (`set_stop_y`)

`set_stop_y(y: float) -> void` activa un tope de scroll en la Y `y` (Y mundo del **centro** de la cámara) solo para esa instancia, sin tocar el `ScrollConfig` compartido; pisa a `stop_at_enabled` / `stop_at_y`. Lo usa `LevelController` con `LevelBuilder.get_camera_stop_y()` para que el segmento final quede completo a la vista. Ver `niveles-por-segmentos.md`.

`has_reached_end() -> bool` indica si la cámara llegó a su tope (lo usa el tentáculo en el modo anterior para seguir subiendo al final del nivel; se apaga con `reset()`).

## Cómo probarlo

1. Ejecutar `scenes/levels/Level.tscn` (F6). Subir con el jetpack: la cámara se queda quieta hasta que pasás la altura deseada y desde ahí te sigue sin salto, manteniéndote a ~60 % de la altura. Bajar: la cámara baja con vos, pero no por debajo de su posición inicial.
2. Empujar al jugador contra los costados y hacia arriba: no debe poder salir.
3. Para ver el modo anterior, poner `follow_player` en false en `scroll_config.tres`: la cámara sube sola a `scroll_speed`.
4. Editar `scroll_config.tres` (por ejemplo `scroll_speed` o `scroll_acceleration`) y volver a ejecutar. Los valores que se ajustan mientras se prueba son de prueba, no de balance: no se anotan en `docs/TUNING_LOG.md`.
