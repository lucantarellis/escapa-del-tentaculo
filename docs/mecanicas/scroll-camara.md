# Mecánica: scroll y cámara

**Archivos:** `scripts/camera/scroll_camera.gd`, `scripts/camera/scroll_config.gd`, `scenes/camera/ScrollCamera.tscn`, `resources/configs/scroll_config.tres`.
**Escena de prueba:** `scenes/levels/sandbox.tscn` (columna alta con la cámara instanciada).

## Propósito

La pantalla sube a velocidad configurable y empuja al jugador hacia arriba: quien se queda atrás cae fuera de pantalla y pierde (paso 3). La cámara también encierra al jugador con paredes invisibles laterales y superior.

## Modelo en palabras simples

- **La cámara sube, el mundo está quieto.** Cada tick de física (`_physics_process`) resta `scroll_speed × delta` a la posición Y de la cámara. No sigue al jugador: solo sube.
- **Sincronización con el jugador.** `process_callback` está en física y no hay suavizado de posición, así que cámara y jugador se actualizan en el mismo ciclo y no se desfasan. Con el snap a píxel activado, en pantallas con pocos píxeles por unidad puede notarse un salto de 1 px; si molesta, se decide con el arte final (escalado entero).
- **Espera inicial.** Durante `start_delay` la cámara está quieta. Se cuenta desde el inicio o el reinicio.
- **Aceleración opcional.** Con `scroll_acceleration` > 0 la velocidad crece desde `scroll_speed` hasta `max_scroll_speed`.
- **Fin opcional.** Con `stop_at_enabled`, la cámara se detiene cuando su centro llega a `stop_at_y` y emite `scroll_stopped`.
- **Límites.** `ScreenBounds` es un `StaticBody2D` (capa 1) hijo de la cámara, con tres formas rectangulares (izquierda, derecha, arriba) dimensionadas en `_ready` desde el tamaño visible (viewport ÷ zoom). Al ser hijo de la cámara, se mueve con ella. No hay pared inferior: caer bajo el borde inferior es derrota (paso 3). Las paredes laterales se extienden 64 px por encima y por debajo de la pantalla.
- **Coordenadas.** `stop_at_y` es la Y del **centro** de la cámara en coordenadas del mundo (Y negativa = arriba). El borde inferior visible es `centro + alto_visible / 2`.

## Parámetros (`ScrollConfig`)

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Scroll | `scroll_speed` | float | 40 | px/s | Velocidad de ascenso | Junto con el consumo de combustible, define la dificultad. Debe ser bastante menor que `max_speed` del jugador (180) |
| Scroll | `scroll_acceleration` | float | 0.0 | px/s² | Aumento progresivo (0 = constante) | Valores chicos (1–5) ya se sienten a lo largo de un nivel |
| Scroll | `max_scroll_speed` | float | 120 | px/s | Tope con aceleración | |
| Scroll | `start_delay` | float | 2.0 | s | Espera antes de subir | |
| Fin | `stop_at_enabled` | bool | false | — | Detener la cámara en `stop_at_y` | |
| Fin | `stop_at_y` | float | -2400 | px | Y del centro de la cámara donde se detiene | Ponerlo donde el borde superior alcance el final del nivel |
| Límites | `side_walls_enabled` | bool | true | — | Paredes laterales | |
| Límites | `top_wall_enabled` | bool | true | — | Pared superior | |
| Límites | `top_wall_margin` | float | 0 | px | Separación de la pared superior respecto del borde (positivo = más adentro) | Se aplica al construir los límites en `_ready` |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `scroll_started()` | La cámara empieza a subir (termina `start_delay` o se reanuda) |
| `scroll_stopped()` | La cámara deja de subir (`set_scrolling(false)`, llegó a `stop_at_y` o se reinició) |

## API pública

| Función | Descripción |
|---|---|
| `set_scrolling(enabled: bool) -> void` | Pausa o reanuda el scroll (al reanudar no repite `start_delay`) |
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

`has_reached_end() -> bool` indica si la cámara llegó a su tope (lo usa el tentáculo para seguir subiendo al final del nivel; se apaga con `reset()`).

## Cómo probarlo

1. Ejecutar `scenes/levels/sandbox.tscn` (F6). Tras 2 s la cámara sube.
2. Empujar al jugador contra los costados y hacia arriba: no debe poder salir.
3. Editar `scroll_config.tres` (por ejemplo `scroll_speed` o `scroll_acceleration`) y volver a ejecutar. Los valores que se ajustan mientras se prueba son de prueba, no de balance: no se anotan en `docs/TUNING_LOG.md`.

## Sandbox en columna

`sandbox.tscn` es ahora una columna de 360 px de ancho que va de Y = -1760 a Y = 640: suelo abajo, un techo de referencia arriba (Y = -1780) y plataformas cada 160 px. Las paredes laterales estáticas se quitaron: las reemplazan los límites de la cámara. La cámara arranca en (180, 320), es decir, mostrando Y de 0 a 640.
