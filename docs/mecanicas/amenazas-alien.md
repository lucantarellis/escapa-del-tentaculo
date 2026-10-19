# Amenazas del tier 3 (dentro del alien)

**Archivos:** `scripts/hazards/bile_wall.gd`, `scripts/hazards/antibody.gd`; escenas `scenes/hazards/BileWall.tscn` y `Antibody.tscn`. Se colocan en los `SegmentAlienNN`. Todas son rojas (letal) y avisan antes de actuar. Solo actúan con el nodo a la vista. Placeholders con polígonos.

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

Patrulla un tramo recto (de su posición a posición + `travel`). Si el jugador pasa a menos de `detect_radius`, se lanza durante `chase_time` s a `chase_speed` hacia el punto de su tramo más cercano al jugador (nunca sale del tramo, así no atraviesa paredes); luego descansa `recover_time` s sin detectar. Se pone rojo claro al lanzarse. Tocarlo mata. Causa: `antibody`.

| Propiedad | Defecto | Descripción |
|---|---|---|
| `travel` | (100, 0) | Recorrido de patrulla. Unidad: px |
| `patrol_speed` / `chase_speed` | 40 / 120 | Velocidades. Unidad: px/s |
| `detect_radius` | 140 | Detección. Unidad: px |
| `chase_time` / `recover_time` | 1,8 / 1,5 | Embestida y descanso. Unidad: s |
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
2. Acercarse al anticuerpo (menos de 140 px): se lanza durante 1,8 s y después se agota.
3. Ajustar los tiempos y velocidades en el inspector de cada instancia.
