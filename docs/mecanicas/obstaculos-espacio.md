# Obstáculos del espacio (tier 2)

**Archivos:** `scripts/hazards/space_projectile.gd` (`SpaceProjectile`), escenas `scenes/hazards/Meteor.tscn` y `Comet.tscn`; se colocan en los segmentos `SegmentSpace01`–`10`.
**Depende de:** `ScrollCamera.get_visible_rect()` (ver `scroll-camara.md`), `Player.die()` (ver `jugador.md`).

## Propósito

El tier 2 no repite los obstáculos de la nave (compuertas, trampas, plataformas letales): usa peligros propios del espacio. Todos **avisan antes de ser letales**, para que cada muerte sea por error propio.

## Meteoro y cometa (`SpaceProjectile`)

Un solo script con dos escenas preconfiguradas.

- **Meteoro** (`Meteor.tscn`): roca ardiente (sprite `meteor_head`, 16 direcciones según el rumbo) con resplandor aditivo naranja y estela de 90 px de partículas `particle_ember` (solo visual). **Se rompe** contra lo sólido (asteroides, paredes): un asteroide sirve de escudo.
- **Cometa** (`Comet.tscn`): núcleo de hielo (sprite `comet_head`, destellos `twinkle`) con resplandor cian y cola larga (150 px) de partículas `particle_ice` que **también mata** (la colisión de la cola es la de siempre); atraviesa todo.
- El arte se elige con el grupo `Arte` del script: `head_sheet`, `directional_head`, `particle_sheet` y `glow_color`. La estela son `CPUParticles2D` en espacio global (4 cuadros por vida de la partícula): se estira en cualquier dirección y deja un rastro que se apaga solo al terminar el vuelo.

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
| `SegmentSpace03` | Tentáculo láser en el lado derecho |
| `SegmentSpace04` | Campo de escombros (radio 55, más chico por el espacio libre) |
| `SegmentSpace06` | Tentáculo láser en el lado izquierdo (barrido −35° a 20°: su espejo, 215°, pasa 5° del rango del arte; se dibuja con el tag de 210°) |
| `SegmentSpace07`, `10` | Campo de escombros (giro en sentidos opuestos) |
| `SegmentSpace09` | 2 tentáculos láser en lados opuestos (el segundo con `initial_delay` 2 s) |

Se quitaron de todos los segmentos del espacio las plataformas letales "en llamas" y los proyectiles `Platform` PROJECTILE de la nave.

## Campo de escombros (`DebrisField`)

Trozos de chapa (sprite `debris_fragment`: 6 diseños al azar, que giran mostrando un cuadro cada 10°) que orbitan un punto fijo; tocar uno mata (`debris_field`). La colisión sigue siendo un círculo de `chunk_size` × 0,45 de radio, más chico que el dibujo. El anillo de la órbita se dibuja tenue para que se lea el peligro.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `orbit_radius` | 70 | Radio de la órbita. Unidad: px |
| `chunk_count` | 5 | Cantidad de trozos |
| `angular_speed` | 55 | Giro. Unidad: °/s; negativo = antihorario |
| `chunk_size` | 18 | Tamaño de cada trozo. Unidad: px |
| `show_orbit` | true | Dibuja el anillo |

## Tentáculo láser (`LaserTentacle`)

Antes era un satélite (`SatelliteLaser`); desde el brief 10 es la punta de un tentáculo del alien que asoma por un costado de la pantalla y termina en un ojo. Solo actúa con el tentáculo dentro de la vista. Ciclo: ASOMA (`emerge`) → APUNTA (línea punteada tenue que barre de `angle_from` a `angle_to`, con el ojo abierto siguiendo el barrido) → FIJA (el ojo se achica y se carga de rojo a amarillo, la línea parpadea) → DISPARA (haz letal desde el ojo, `laser`; el tallo retrocede) → ENFRÍA (el ojo se reabre y el tentáculo vuelve al punto de partida), y repite (con `ping_pong` invierte el barrido). Solo mata durante DISPARA. Al salir de la zona de acción se retira (`emerge` al revés).

- **Posición:** el nodo va **en el borde de la pantalla** (x = 0 o x = 360): ahí está la base del tentáculo. Si `x` está en la mitad izquierda, el arte se espeja y se usa el ángulo espejado (180° − ángulo). Los ángulos del barrido siguen el código (0 = derecha, 90 = abajo); el arte cubre de 150° a 210° (o su espejo) de a 5°, y fuera de ese rango se usa el tag del extremo.
- **Origen del haz:** el ojo de cada cuadro (`laser_tentacle_muzzle.json`), no el nodo.
- El dibujo del tentáculo gira de a saltos de 5° (un tag por ángulo), pero el haz usa el ángulo real; la pose sigue al barrido a 90°/s como máximo.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `angle_from` / `angle_to` | 160 / 210 | Barrido. Unidad: ° |
| `beam_length` / `beam_width` | 700 / 14 | Tamaño del haz. Unidad: px |
| `aim_time` / `lock_time` / `fire_time` / `cooldown_time` | 1,4 / 0,4 / 0,5 / 2,0 | Tiempos (la animación de `lock` y `fire` se estira a estos tiempos). Unidad: s |
| `initial_delay` | 0 | Desfase desde que terminó de asomar. Unidad: s |

## Cómo probarlo

1. Abrir un `SegmentSpaceNN` con F6: el obstáculo avisa cuando su recorrido entra en la vista.
2. Ver el aviso, esquivar o esconderse detrás de un asteroide (el meteoro se rompe contra él).
3. Ajustar `speed`, `warning_time` y `repeat_interval` en el inspector de cada instancia.
