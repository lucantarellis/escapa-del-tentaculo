# Mecánica: tentáculo y condición de derrota

**Archivos:** `scripts/tentacle/tentacle.gd`, `scripts/tentacle/tentacle_config.gd`, `scenes/tentacle/Tentacle.tscn`, `resources/configs/tentacle_config.tres`.
**Derrota:** `scripts/levels/level_controller.gd` y el autoload `GameManager` (mensaje y reinicio; ver `game-manager.md`).

## Propósito

Es la amenaza: una masa roja anclada al borde inferior de la pantalla que sube con la cámara. Si el jugador la toca, o cae por debajo del borde inferior, pierde. Obliga a subir sin quedarse atrás.

## Modelo en palabras simples

- **Anclado a la cámara.** En cada tick de física el tentáculo se coloca con su borde superior a `visible_height` px por encima del borde inferior de la pantalla (`camera.get_bottom_y() - visible_height`). Con `extra_rise_speed` > 0 sube además a esa velocidad, acumulándose: gana terreno sobre la cámara.
- **Final del nivel.** Cuando la cámara llega a su tope (`ScrollCamera.has_reached_end()`, por ejemplo al detenerse con el segmento final a la vista), el tentáculo no se queda quieto: sube a `end_rise_speed` (más `extra_rise_speed`) hasta cubrir toda la pantalla. Como el jugador no puede salir por arriba (pared de la cámara), no hay refugio: hay que llegar a la puerta antes de que lo alcance. Al ganar o perder el nivel congela el ascenso con `set_rising(false)`.
- **Cuerpo.** Un `Polygon2D` rojo cuyo borde superior son `wobble_segments + 1` puntos que suben y bajan con una onda senoidal (`wobble_amplitude`, `wobble_frequency`). El cuerpo siempre se extiende hasta 96 px por debajo del borde de la pantalla, así nunca queda un hueco aunque suba más rápido que la cámara.
- **Zona letal (`KillZone`, `Area2D`, capa 4, máscara 2).** Un rectángulo que empieza `kill_zone_inset` px *por debajo* del borde superior del polígono visible (margen de gracia: rozar la punta ondulante no mata) y llega hasta el fondo del cuerpo. Se redimensiona cada tick.
- **Dos formas de morir.** Contacto: la `KillZone` detecta al `Player` → causa `&"tentacle"`. Caída: si `kill_on_leaving_screen_bottom` está activo y el centro del jugador queda más de `screen_bottom_margin` px por debajo del borde inferior → causa `&"fell"`. En la práctica el contacto casi siempre ocurre antes (el tentáculo cubre el borde inferior); la caída es una red de seguridad, por ejemplo si `visible_height` se lleva a valores muy chicos o el jugador atraviesa la zona a mucha velocidad.
- **Efecto de la derrota.** El tentáculo emite `player_caught(cause)` y llama a `Player.die(cause)`, que desactiva el control y emite `died(cause)`. Quién decide qué pasa después (mensaje, reinicio) es el nivel o el game manager.

## Parámetros (`TentacleConfig`)

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Posición | `visible_height` | float | 70 | px | Cuánto se ve sobre el borde inferior | Más alto = más amenazante y menos espacio jugable |
| Posición | `extra_rise_speed` | float | 0.0 | px/s | Ascenso adicional respecto de la cámara | Usar valores chicos (2–10): se acumula y acaba tapando la pantalla |
| Final del nivel | `rise_after_camera_stops` | bool | true | — | Al detenerse la cámara en el final del nivel, el tentáculo sigue subiendo hasta cubrir la pantalla | Si se desactiva, quien llega al final queda a salvo mientras la cámara esté quieta |
| Final del nivel | `end_rise_speed` | float | 40 | px/s | Velocidad de ascenso con la cámara detenida (se suma a `extra_rise_speed`) | 40 = igual que el scroll: sigue como si la cámara no se hubiera detenido |
| Letalidad | `kill_zone_inset` | float | 10 | px | Margen de gracia bajo el borde visible | 0 = mata al rozar la punta |
| Letalidad | `kill_on_leaving_screen_bottom` | bool | true | — | Caer bajo la pantalla mata | |
| Letalidad | `screen_bottom_margin` | float | 24 | px | Cuánto bajo el borde cuenta como caída (desde el centro del jugador) | |
| Animación | `wobble_amplitude` | float | 6 | px | Ondulación del borde superior (0 = sin) | Solo visual; mantenerla menor que `kill_zone_inset` + algunos px |
| Animación | `wobble_frequency` | float | 2.0 | Hz | Velocidad de la ondulación | |
| Animación | `wobble_segments` | int | 12 | — | Puntos del borde superior | |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `player_caught(cause: StringName)` | El tentáculo atrapa al jugador: `&"tentacle"` (contacto) o `&"fell"` (caída bajo la pantalla) |

## API pública

| Función | Descripción |
|---|---|
| `set_rising(enabled: bool) -> void` | Activa o congela el ascenso (`extra_rise_speed` y `end_rise_speed`). `LevelController` lo congela al ganar o perder |
| `set_active(active: bool) -> void` | `false`: lo oculta, apaga `KillZone.monitoring`, el chequeo de caída (`_check_fell`) y la animación, y deja de seguir a la cámara. `true`: lo restaura y lo reubica. Estado inicial: activo (el sandbox no cambia). La intro lo apaga hasta empezar la partida |
| `is_active() -> bool` | true si está activo |
| `reset() -> void` | Anula el ascenso extra acumulado, reanuda el ascenso y vuelve al borde de la cámara |

Exportadas: `config: TentacleConfig` y `camera: ScrollCamera` (obligatoria; sin ella el tentáculo se desactiva y avisa con un error).

## Estructura de nodos

```
Tentacle (Node2D)          origen = borde superior (sin ondular), esquina izquierda de la pantalla
├── BodyPolygon (Polygon2D, rojo de la paleta)
└── KillZone (Area2D, capa 4, máscara 2)
    └── CollisionShape2D (RectangleShape2D, se redimensiona cada tick)
```

## Manejo de la derrota

El tentáculo llama a `Player.die(cause)`. `Player.died(cause)` llega a `LevelController`, que la pasa a `GameManager.notify_player_died`; el manager pasa a `LOST` y el controlador detiene el scroll y muestra "CAPTURADO — pulsá R para reiniciar" para `&"tentacle"` y `&"fell"` (mapa `DEATH_TEXTS`). R (acción `restart`) la maneja el `GameManager` y recarga la escena, lo que deja combustible, cámara y tentáculo en su estado inicial. Ver `game-manager.md`.

## Cómo probarlo

1. Ejecutar `scenes/levels/sandbox.tscn` (F6) y quedarse quieto sobre la plataforma de inicio: el tentáculo llega y aparece el mensaje.
2. Con R se reinicia. Editar `tentacle_config.tres` y repetir. Los valores que se ajustan mientras se prueba son de prueba, no de balance: no se anotan en `docs/TUNING_LOG.md`.

## Sandbox

El jugador arranca ahora sobre una plataforma de inicio (`StartPlatform`, Y = 560), porque el suelo (Y = 620) queda bajo el tentáculo visible.
