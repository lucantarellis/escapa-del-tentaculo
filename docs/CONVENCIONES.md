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
5. Si el cambio altera la sensación de juego, anotarlo en `docs/TUNING_LOG.md`.

## 6. Git

- **Ramas:** una por brief, desde `main` (`feature/<tema>`). No se trabaja directo sobre `main`.
- **Commits:** uno por paso del brief, con el formato `pasoN: descripción` (ej. `paso1: jugador con jetpack, combustible y sandbox`).
- **Sin `git push`, `gh pr create` ni cambios en GitHub sin confirmación explícita de LT**, mostrando antes el árbol de archivos y el resumen de cambios.
- **Merge:** lo hace LT, avisando antes a su socio. Los `.tscn` dan conflictos fácilmente: coordinar quién toca cada escena.

## 7. Flujo de trabajo por brief

1. Copiar `docs/briefs/BRIEF_TEMPLATE.md` a `docs/briefs/brief-NN-<tema>.md` y completarlo.
2. Ejecutarlo paso a paso. Al final de cada paso: checklist de prueba, LT juega y da el "seguí".
3. Documentación es parte de "hecho": un documento por mecánica en `docs/mecanicas/`, y `ARQUITECTURA.md` al día.
4. Cambios de valores que modifican la sensación → `docs/TUNING_LOG.md`.
5. Al cerrar el brief, actualizar `docs/ROADMAP.md` (estado y decisiones).
