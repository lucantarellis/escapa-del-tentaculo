# Mecánica: puerta de meta

**Archivos:** `scripts/goal/door.gd`, `scenes/goal/Door.tscn`.
**Depende de:** `Player.is_alive()` (ver `jugador.md`). No tiene config `Resource`: el único valor propio es el tamaño, que es diseño de nivel.

## Propósito

Es el objetivo del juego: llegar a la puerta antes de que el tentáculo atrape al jugador. Al tocarla, la partida se gana.

## Modelo en palabras simples

- **`Area2D` de meta** (capa 5 `goal`, máscara 2 `player`). No colisiona físicamente: el jugador la atraviesa.
- **Al entrar un `Player` vivo** emite `player_reached()` **una sola vez**; los reingresos se ignoran hasta llamar a `reset()`.
- **No llama a `Player`.** La puerta solo avisa (señales hacia arriba). Quien reacciona es el nivel (`LevelController`) o el game manager: llaman a `Player.win()`, detienen el scroll y muestran el mensaje.
- **Estado "ganó" del jugador.** `Player.win()` desactiva el control, deja al jugador quieto y hace que `is_alive()` devuelva `false`. Como el tentáculo, los obstáculos y los tanques ya ignoran a un jugador no vivo, nada puede matarlo después de ganar ni hace falta tocar esos scripts. Ojo: `is_alive()` significa "la partida sigue en curso para el jugador", no solo "no murió"; para saber si ganó usar `Player.has_won()`.
- **`@tool`.** El tamaño se ve y se ajusta en el editor.

## Color (placeholder)

Cuerpo naranja `#FF6B32` (convención: naranja = objetivo/meta) con un picaporte blanco azulado `#C8E7EA`.

## Parámetros

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto |
|---|---|---|---|---|---|
| Forma | `size` | Vector2 | (48, 72) | px | Ancho y alto de la puerta y de su área. Se ajusta por instancia (diseño de nivel) |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `player_reached()` | Un jugador vivo entró en la puerta. Una sola vez hasta `reset()` |

## API pública

| Función | Descripción |
|---|---|
| `reset() -> void` | Vuelve a dejarla lista para activarse. Si el jugador está encima, se activa de nuevo al instante |

## Estructura de nodos

```
Door (Area2D, capa 5, máscara 2)   script: door.gd
├── Body (Polygon2D, naranja)
│   └── Handle (Polygon2D, blanco azulado)
└── CollisionShape2D (RectangleShape2D, única por instancia)
```

## Cómo colocarla

1. Instanciar `scenes/goal/Door.tscn` en el nivel. El origen es el centro: para apoyarla sobre una plataforma, `y = y_de_la_plataforma − alto / 2`.
2. Ajustar `Size` en el inspector si hace falta.
3. Conectar `player_reached` (el nivel lo hace en su controlador).

## Cómo probarla

1. Abrir `scenes/levels/sandbox.tscn` y ejecutar con F6. La puerta `GoalDoor` está sobre la plataforma más alta.
2. Llegar hasta ella: aparece "ESCAPASTE — pulsá R para reiniciar" y la cámara se detiene. El jugador ya no se mueve, no gasta combustible y ni el tentáculo ni un obstáculo lo matan.
3. R reinicia y la puerta vuelve a funcionar.
