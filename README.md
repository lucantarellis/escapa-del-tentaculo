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

`scenes/main/Main.tscn` es la escena principal (`run/main_scene`): muestra la pantalla de título (nombre del juego y un botón **JUGAR**) sobre el nivel ya armado y quieto (`scenes/levels/Level.tscn`). Al pulsar JUGAR el título se disuelve, una escotilla golpea tres veces (vibración de cámara y gas), se rompe, el jugador sale disparado hacia arriba, arranca el gameplay y poco después entra el tentáculo (ver `docs/mecanicas/intro-escotilla.md`); R reinicia directo al juego, repitiendo la intro (sin título). Ver `docs/mecanicas/pantalla-titulo.md`.

Durante la partida hay un HUD mínimo (barra de combustible a la izquierda y progreso del nivel a la derecha). Ver `docs/mecanicas/hud.md`.

## Controles

| Acción | Teclas |
|---|---|
| Propulsar (izquierda / derecha / arriba / abajo) | A D W S o flechas |
| Saltar (solo sin combustible y apoyado en una superficie) | Espacio |
| Reiniciar (directo al juego, sin volver al título) | R |
| Mostrar u ocultar el overlay de debug | F3 |

## Documentación

Toda la documentación vive en [`docs/`](docs/):

- [`ROADMAP.md`](docs/ROADMAP.md): plan, decisiones de diseño y estado por paso.
- [`CONVENCIONES.md`](docs/CONVENCIONES.md): nombres, tipado, capas, input, configuración y git.
- [`ARQUITECTURA.md`](docs/ARQUITECTURA.md): árbol de escenas, señales y flujo de partida.
- [`TUNING_LOG.md`](docs/TUNING_LOG.md): registro de ajustes de valores.
- [`mecanicas/`](docs/mecanicas/): un documento por mecánica.
- [`briefs/`](docs/briefs/): briefs de trabajo y su plantilla.

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
│   ├── camera/
│   ├── main/                # escena principal (Main.tscn)
│   ├── player/
│   ├── obstacles/
│   ├── goal/                # puerta de meta
│   ├── pickups/
│   ├── tentacle/
│   ├── ui/                  # DebugOverlay, TitleMenu, Hud
│   └── levels/               # niveles jugables: Level.tscn (por segmentos), sandbox.tscn, lvl1.tscn
│       └── segments/         # segmentos (piezas de nivel reutilizables)
├── scripts/
│   ├── camera/
│   ├── player/
│   ├── obstacles/
│   ├── goal/
│   ├── pickups/
│   ├── tentacle/
│   ├── main/                # main.gd (escena principal: título + nivel)
│   ├── managers/            # game_manager.gd (autoload GameManager)
│   ├── levels/              # level_controller.gd, level_builder.gd, level_segment.gd, level_config.gd
│   └── ui/                  # debug_overlay.gd, title_menu.gd, title_config.gd, hud.gd
├── resources/
│   ├── configs/            # Resource de configuración (.tres) con los valores de gameplay
│   ├── tilesets/
│   └── themes/
├── autoload/               # reservada para escenas autoload (el GameManager es un script en scripts/managers/)
├── docs/                   # roadmap, convenciones, arquitectura, mecánicas y briefs
│   ├── mecanicas/
│   └── briefs/
└── addons/
```
