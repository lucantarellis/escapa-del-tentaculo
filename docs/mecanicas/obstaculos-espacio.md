# Obstáculos del espacio (tier 2)

**Archivos:** `scripts/hazards/space_projectile.gd` (`SpaceProjectile`), escenas `scenes/hazards/Meteor.tscn` y `Comet.tscn`; se colocan en los segmentos `SegmentSpace01`–`10`.
**Depende de:** `ScrollCamera.get_visible_rect()` (ver `scroll-camara.md`), `Player.die()` (ver `jugador.md`).
**Pendiente (ronda A, paso 3c):** campo de escombros y láser de satélite; se agregan a esta página.

## Propósito

El tier 2 no repite los obstáculos de la nave (compuertas, trampas, plataformas letales): usa peligros propios del espacio. Todos **avisan antes de ser letales**, para que cada muerte sea por error propio.

## Meteoro y cometa (`SpaceProjectile`)

Un solo script con dos escenas preconfiguradas.

- **Meteoro** (`Meteor.tscn`): roca rápida con halo, núcleo caliente y estela de 90 px (solo visual). **Se rompe** contra lo sólido (asteroides, paredes): un asteroide sirve de escudo.
- **Cometa** (`Comet.tscn`): cabeza grande y estela larga (150 px) que **también mata**; atraviesa todo.

Ciclo:

1. **Espera** fuera de la pantalla, en el punto de partida (la posición del nodo).
2. Cuando su recorrido entra en la vista de la cámara (y pasó `initial_delay`), **avisa** `warning_time` s: una **flecha** parpadeante (trazo corto desde el borde por donde entra y la punta **adelante**, hacia donde va; si el trazo saliera de la punta se leería como una estela y parecería ir al revés). El cometa dibuja la línea punteada de todo el recorrido visible, con un punto en el borde de entrada y la punta de flecha al final. Si el recorrido sale de la vista, el aviso se cancela.
3. **Cruza** en línea recta a `speed` px/s. Si toca al jugador vivo, lo mata (`Player.die(cause)`).
4. Si `repeat_interval` > 0 espera ese tiempo y vuelve a avisar mientras su recorrido siga a la vista; con 0 pasa una sola vez.

Las paredes invisibles de la cámara no lo rompen (los proyectiles nacen fuera de la pantalla). Se ve en el editor como una línea desde el punto de partida hasta el final del recorrido.

### Parámetros

| Grupo | Variable | Meteoro | Cometa | Efecto |
|---|---|---|---|---|
| Trayectoria | `travel` | por instancia | por instancia | Vector del punto de partida al final. Unidad: px |
| Trayectoria | `speed` | 180 (rápidos: 250–270) | 320–340 | Unidad: px/s |
| Forma | `size` | 22–24 (chicos: 16) | 24 | Tamaño de la cabeza. Unidad: px |
| Forma | `trail_length` | 90 | 150 | Largo de la estela. Unidad: px |
| Forma | `trail_lethal` | no | sí | La estela mata |
| Forma | `breaks_on_solid` | sí | no | Se rompe contra lo sólido |
| Aviso | `warning_time` | 1,0 | 1,3 | Unidad: s |
| Aviso | `show_path` | no | sí | Línea punteada de todo el recorrido |
| Ciclo | `initial_delay` | por instancia | por instancia | Desfase para no sincronizar varios. Unidad: s |
| Ciclo | `repeat_interval` | 3,5–5 | 7 | 0 = una sola vez. Unidad: s |
| — | `cause` | `&"meteor"` | `&"comet"` | Causa de muerte |

### Señales y API

| Función | Descripción |
|---|---|
| `reset() -> void` | Vuelve a esperar, quieto y fuera de la pantalla |

### Colocación en los segmentos

| Segmento | Obstáculos |
|---|---|
| `SegmentSpace01` | 2 meteoros desde lados opuestos |
| `SegmentSpace02` | 1 cometa en diagonal |
| `SegmentSpace05` | 2 meteoros desde lados opuestos |
| `SegmentSpace06` | 1 meteoro |
| `SegmentSpace07` | 1 cometa en diagonal |
| `SegmentSpace08` | 3 meteoros chicos y rápidos, escalonados |
| `SegmentSpace10` | 2 cometas cruzados, desfasados 3,5 s |
| `SegmentSpace03` | Satélite láser en el lado derecho |
| `SegmentSpace04` | Campo de escombros (radio 55, más chico por el espacio libre) |
| `SegmentSpace06` | Satélite láser en el lado izquierdo |
| `SegmentSpace07`, `10` | Campo de escombros (giro en sentidos opuestos) |
| `SegmentSpace09` | 2 satélites láser en lados opuestos (el segundo con `initial_delay` 2 s) |

Se quitaron de todos los segmentos del espacio las plataformas letales "en llamas" y los proyectiles `Platform` PROJECTILE de la nave.

## Campo de escombros (`DebrisField`)

Trozos rojos que orbitan un punto fijo; tocar uno mata (`debris_field`). El anillo de la órbita se dibuja tenue para que se lea el peligro.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `orbit_radius` | 70 | Radio de la órbita. Unidad: px |
| `chunk_count` | 5 | Cantidad de trozos |
| `angular_speed` | 55 | Giro. Unidad: °/s; negativo = antihorario |
| `chunk_size` | 18 | Tamaño de cada trozo. Unidad: px |
| `show_orbit` | true | Dibuja el anillo |

## Satélite láser (`SatelliteLaser`)

Solo actúa con el satélite dentro de la vista. Ciclo: APUNTA (línea tenue que barre de `angle_from` a `angle_to`) → FIJA (parpadeo) → DISPARA (haz letal, `laser`) → ENFRÍA, y vuelve a empezar (con `ping_pong` invierte el barrido). Solo mata durante DISPARA.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `angle_from` / `angle_to` | 160 / 210 | Barrido. Unidad: ° |
| `beam_length` / `beam_width` | 700 / 14 | Tamaño del haz. Unidad: px |
| `aim_time` / `lock_time` / `fire_time` / `cooldown_time` | 1,4 / 0,4 / 0,5 / 2,0 | Tiempos. Unidad: s |
| `initial_delay` | 0 | Desfase. Unidad: s |

## Cómo probarlo

1. Abrir un `SegmentSpaceNN` con F6: el obstáculo avisa cuando su recorrido entra en la vista.
2. Ver el aviso, esquivar o esconderse detrás de un asteroide (el meteoro se rompe contra él).
3. Ajustar `speed`, `warning_time` y `repeat_interval` en el inspector de cada instancia.
