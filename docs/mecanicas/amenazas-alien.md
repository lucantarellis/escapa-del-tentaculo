# Amenazas del tier 3 (dentro del alien)

**Archivos:** `scripts/hazards/bile_wall.gd`, `scripts/hazards/antibody.gd`; escenas `scenes/hazards/BileWall.tscn` y `Antibody.tscn`. Se colocan en los `SegmentAlienNN`. Avisan antes de actuar. La bilis es verde (con borde rojo oscuro) por decisión de diseño: se lee como bilis y se distingue del ácido perseguidor (amarillo); el anticuerpo es rojo (letal) y se pone gris cuando es inofensivo. Solo actúan con el nodo a la vista. Placeholders con polígonos.

## Pared que escupe bilis (`BileWall`)

Un orificio en la cara de la pared del túnel. Cada `interval` s se hincha `warning_time` s (bulto que crece, parpadeo y línea tenue hacia donde va a escupir) y lanza un proyectil lento en línea recta. El proyectil mata al jugador y se disuelve contra cualquier pared o a los `max_range` px. Causa de muerte: `bile`.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `angle` | 0 | Dirección (0 derecha, 90 abajo, 180 izquierda). Unidad: ° |
| `projectile_speed` | 150 | Velocidad. Unidad: px/s |
| `bile_size` | 14 | Diámetro del proyectil. Unidad: px |
| `max_range` | 420 | Alcance. Unidad: px |
| `interval` | 3,0 | Tiempo entre escupitajos. Unidad: s |
| `warning_time` | 0,7 | Aviso previo. Unidad: s |
| `initial_delay` | 1,0 | Espera inicial. Unidad: s |

## Anticuerpo (`Antibody`)

Patrulla despacio un tramo recto (de su posición a posición + `travel`). Ciclo de ataque:

1. **Fija** (`lock_time`): si el jugador está a menos de `detect_radius`, se frena, tiembla cada vez más, parpadea en rojo claro, crece, el ojo gira hacia el jugador y una línea punteada los une. Al terminar **congela** el punto objetivo (el punto de su tramo más cercano al jugador en ese instante).
2. **Embiste**: se lanza en línea recta a `lunge_speed` hasta ese punto, sin seguir al jugador. Se esquiva yéndose del punto.
3. **Agotado** (`tired_time`): gris, brazos caídos, quieto e **inofensivo**. Es la ventana para pasar. Después vuelve a patrullar.

Nunca sale del tramo (no atraviesa paredes). Mata al tocarlo salvo agotado. Causa: `antibody`.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `travel` | (100, 0) | Recorrido de patrulla. Unidad: px |
| `patrol_speed` / `lunge_speed` | 35 / 150 | Velocidades. Unidad: px/s |
| `detect_radius` | 110 | Detección. Unidad: px |
| `lock_time` | 0,8 | Aviso (fijando). Unidad: s |
| `tired_time` | 2,2 | Agotado e inofensivo. Unidad: s |
| `body_radius` | 11 | Radio. Unidad: px |

## Colocación

| Segmento | Amenaza |
|---|---|
| `SegmentAlien01`, `03`, `07`, `09` | Pared de bilis (01 y 09 desde la izquierda, 03 y 07 desde la derecha) |
| `SegmentAlien08` | Pared de bilis (cerca del techo del segmento) |
| `SegmentAlien02`, `04`, `05`, `10` | Anticuerpo |
| `SegmentAlien06` | Sin amenazas nuevas por ahora (esperan cilios o tentáculos menores) |

Las posiciones se calcularon con un script a partir del túnel y las plataformas (lejos de ellas y fuera de los primeros y últimos 150 px del segmento). Se pueden mover a mano.

## Cómo probarlo

1. Abrir un `SegmentAlienNN` con F6 y esperar el aviso del orificio, o dejar que el anticuerpo patrulle.
2. Acercarse al anticuerpo (menos de 110 px): fija, embiste al punto fijado y se agota (gris, inofensivo).
3. Ajustar los tiempos y velocidades en el inspector de cada instancia.
