# Escapa del Tentáculo

Un astronauta escapa de un tentáculo alienígena dentro de una nave espacial, usando un jetpack para esquivar obstáculos mientras la pantalla sube a velocidad constante, hasta llegar a una puerta antes de que el tentáculo lo atrape.

## Requisitos

- Godot **4.7 stable**

## Cómo clonar y abrir el proyecto

```bash
git clone <url-del-repo>
```

Abrir la carpeta del proyecto desde Godot (Project Manager → Import → seleccionar `project.godot`).

## Estado actual

v0 — estructura inicial del proyecto. Sin lógica de gameplay implementada todavía (eso queda para iteraciones posteriores). Ya existe una escena de prueba (`scenes/levels/lvl1.tscn`) creada durante el setup inicial en el editor.

`scenes/main/Main.tscn` es la escena principal (`run/main_scene`), por ahora vacía. Diseño planeado para una iteración futura:

- Pantalla de título con el nombre del juego y un botón **Play**.
- De fondo, se ve la escena del nivel 1 (`scenes/levels/lvl1.tscn`).
- Al presionar Play, la pantalla de título se disuelve y arranca el gameplay.

## Estructura de carpetas

```
escapa-del-tentaculo/
├── project.godot
├── icon.svg
├── assets/
│   ├── sprites/
│   │   ├── player/         # sprite sheet del astronauta
│   │   ├── environment/    # tileset sci-fi (plataformas, paredes, puertas, ítems, trampas, decoración)
│   │   └── tentacle/       # sprite sheet del tentáculo (criatura)
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   ├── fonts/
│   └── palette.md          # paleta de colores compartida
├── scenes/
│   ├── main/                # escena principal (Main.tscn)
│   ├── player/
│   ├── obstacles/
│   ├── tentacle/
│   ├── ui/
│   └── levels/               # niveles jugables (incluye lvl1.tscn)
├── scripts/
│   ├── player/
│   ├── obstacles/
│   ├── tentacle/
│   ├── managers/
│   └── ui/
├── resources/
│   ├── tilesets/
│   └── themes/
├── autoload/
└── addons/
```
