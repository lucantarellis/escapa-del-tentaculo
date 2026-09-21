# Convenciones — Escapa del Tentáculo

Reglas del proyecto. Si algo no está acá, seguir el estilo del código existente y agregarlo a este documento.

## 1. Nombres y estilo

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos `.gd` | `snake_case` | `player_config.gd` |
| Escenas `.tscn` | `PascalCase` | `ScrollCamera.tscn` |
| `class_name` | `PascalCase` | `PlayerConfig` |
| Variables y funciones | `snake_case` | `thrust_acceleration`, `add_fuel()` |
| Constantes | `UPPER_SNAKE` | `MAX_SEGMENTS` |
| Señales | `snake_case`, verbo en pasado o participio | `fuel_depleted` |

- Identificadores en **inglés**. Comentarios y documentos en **español**.
- **Señales hacia arriba, llamadas hacia abajo:** una escena hija emite señales; el padre la controla llamando a su API pública. Una hija no busca a su padre ni a sus hermanas.
- Indentación con tabulaciones en `.gd` (estándar del editor de Godot).

## 2. Tipado y comentarios

- **GDScript con tipado estático en todo:** variables, parámetros y retornos (`var speed: float = 0.0`, `func add_fuel(amount: float) -> void`). Evitar `:=` cuando el tipo no sea evidente.
- **Comentarios `##`** (aparecen en la ayuda del editor) en cada clase, variable exportada, señal y función pública. Comentarios `#` para explicar el porqué de una línea puntual.
- **Variables exportadas agrupadas** con `@export_group("Nombre")`. La unidad va en el comentario: px, px/s, px/s², s, u (unidades de combustible).

```gdscript
@export_group("Propulsión")
## Aceleración al mantener una dirección. Unidad: px/s².
@export var thrust_acceleration: float = 700.0
```

## 3. Capas de colisión 2D

| Capa | Nombre | Uso |
|---|---|---|
| 1 | `world` | Suelo, paredes, plataformas, límites de pantalla (`StaticBody2D`) |
| 2 | `player` | Jugador |
| 3 | `obstacles` | Obstáculos y trampas |
| 4 | `tentacle` | Zona letal del tentáculo |
| 5 | `goal` | Puerta |
| 6 | `pickups` | Tanques de combustible y otros recogibles |

El jugador: layer 2, mask 1. Las `Area2D` de peligro o recogible detectan con mask 2. Los nombres están cargados en Project Settings → Layer Names → 2D Physics.

## 3b. Colores de placeholder

Mientras no haya arte final, el color de un `Polygon2D` comunica su función. Paleta completa en `assets/palette.md`.

| Color | Significado | Ejemplos |
|---|---|---|
| Rojo `#D83232` | **Letal**: tocarlo mata | Tentáculo, obstáculos, trampa activa |
| Cian `#63D6C5` | **Recogible / bueno** | Tanque de combustible |

## 3c. Escenas de nivel reutilizables con `@tool`

Obstáculos y tanques se colocan a mano en los niveles. Para poder verlos y ajustarlos en el editor:

- Las propiedades de diseño de nivel (por ejemplo `size`, `travel`) son `@export` con **setter** que actualiza el visual y la colisión, y el script lleva `@tool`.
- Todo código de juego (`_physics_process`, señales) debe salir temprano con `if Engine.is_editor_hint(): return`. El dibujo de ayudas (trayectorias) solo corre en el editor.
- Cada instancia crea sus propias formas de colisión (no compartir el sub-recurso `Shape2D` entre instancias, o cambiar una cambia todas).
- Lo que es tuning (velocidades, tiempos) va en un `Resource` de configuración; lo que es diseño de nivel (tamaño, recorrido) va en la instancia.

## 4. Acciones del Input Map

El código usa siempre **acciones**, nunca teclas, para poder agregar controles táctiles sin tocar la lógica.

| Acción | Teclas | Uso |
|---|---|---|
| `move_left` | A, ← | Propulsar a la izquierda |
| `move_right` | D, → | Propulsar a la derecha |
| `move_up` | W, ↑ | Propulsar hacia arriba |
| `move_down` | S, ↓ | Propulsar hacia abajo |
| `jump` | Espacio | Saltar (sin combustible) |
| `restart` | R | Reiniciar (temporal) |
| `debug_toggle` | F3 | Mostrar u ocultar el overlay de debug |

Las teclas están definidas con `physical_keycode` (posición física, independiente del idioma del teclado).

## 5. Configuración con `Resource`

Ningún número que afecte el gameplay va escrito en un script. Vive en un `Resource` de configuración editable desde el inspector y guardado como `.tres` en `resources/configs/`.

Existentes (a medida que se implementen los pasos): `PlayerConfig`, `ScrollConfig`, `TentacleConfig`.

### Cómo agregar un parámetro nuevo

1. Agregar la variable `@export` en el script de la config (`scripts/<área>/<x>_config.gd`), dentro del `@export_group` que corresponda, con comentario `##` que incluya la unidad y el efecto.
2. Usarla en el script de la mecánica leyendo `config.<variable>`. Nunca copiarla a una constante.
3. Abrir el `.tres` en el inspector y confirmar el valor por defecto (el `.tres` solo guarda los valores distintos del default del script; si se quiere explícito, editarlo).
4. Agregar una fila a la tabla de parámetros de `docs/mecanicas/<mecánica>.md`.
5. `docs/TUNING_LOG.md` solo se usa para pruebas reales de balance, y cuando LT lo pide. Los valores que se ajustan mientras se prueba una checklist son valores de prueba: no se anotan.

## 6. Git

- **Ramas:** una por brief, desde `main` (`feature/<tema>`). No se trabaja directo sobre `main`.
- **Commits:** uno por paso del brief, con el formato `pasoN: descripción` (ej. `paso1: jugador con jetpack, combustible y sandbox`).
- **Sin `git push`, `gh pr create` ni cambios en GitHub sin confirmación explícita de LT**, mostrando antes el árbol de archivos y el resumen de cambios.
- **Merge:** lo hace LT, avisando antes a su socio. Los `.tscn` dan conflictos fácilmente: coordinar quién toca cada escena.

## 7. Flujo de trabajo por brief

1. Copiar `docs/briefs/BRIEF_TEMPLATE.md` a `docs/briefs/brief-NN-<tema>.md` y completarlo.
2. Ejecutarlo paso a paso. Al final de cada paso: checklist de prueba, LT juega y da el "seguí".
3. Documentación es parte de "hecho": un documento por mecánica en `docs/mecanicas/`, y `ARQUITECTURA.md` al día.
4. `docs/TUNING_LOG.md` es solo para pruebas reales de balance (a pedido de LT), no para los valores de prueba de cada checklist.
5. Al cerrar el brief, actualizar `docs/ROADMAP.md` (estado y decisiones).
