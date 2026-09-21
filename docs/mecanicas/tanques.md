# Mecánica: tanques de combustible

**Archivos:** `scripts/pickups/fuel_tank.gd`, `scripts/pickups/fuel_tank_config.gd`, `scenes/pickups/FuelTank.tscn`, `resources/configs/fuel_tank_config.tres`.
**Depende de:** `Player.add_fuel()`, `Player.get_fuel()` y `PlayerConfig.max_fuel` (ver `jugador.md`).

## Propósito

Es la única forma de recuperar combustible. Convierte el combustible limitado en decisiones de recorrido: hay que llegar al próximo tanque antes de quedarse sin él. También son una herramienta de diseño de niveles: dónde se ponen y cuánto recargan define el ritmo y el riesgo.

## Modelo en palabras simples

- **`Area2D` recogible** (capa 6 `pickups`, máscara 2 `player`). No colisiona físicamente: el jugador lo atraviesa.
- **Al tocarlo** un `Player` vivo: se le suma `fuel_amount` con `Player.add_fuel()` (el jugador recorta en `max_fuel`), se emite `collected(amount)`, el tanque se oculta y deja de detectar. Un jugador muerto no lo recoge.
- **Un solo uso o reaparición.** Con `respawn_time` = 0 el tanque no vuelve; con `respawn_time` > 0 reaparece pasado ese tiempo (se cuenta en `_physics_process`, no con un `Timer`, para que `reset()` pueda cancelarlo).
- **`only_if_not_full`.** Si está activo, con el combustible lleno el tanque no se consume y queda esperando. Si el jugador está encima y gasta combustible, lo recoge en ese momento (el tanque revisa los cuerpos superpuestos en cada tick mientras está en este modo).
- **Recarga que sobra.** `collected(amount)` informa la cantidad *ofrecida*; lo que excede `max_fuel` se pierde.
- **Vaivén.** El dibujo sube y baja con un seno (`bob_amplitude`, `bob_frequency`); el área de detección no se mueve.
- **Reutilizable.** Es una escena por instancia, configurable con su `config`. Para que un tanque recargue otra cantidad, duplicar el `.tres` y asignarlo en su `Config`.

## Colores (placeholder)

Cuerpo cian `#63D6C5` (convención: cian = recogible) con un detalle blanco azulado `#C8E7EA`. Tamaño 12×16 px.

## Parámetros (`FuelTankConfig`)

| Grupo | Variable | Tipo | Valor inicial | Unidad | Efecto | Consejo de tuning |
|---|---|---|---|---|---|---|
| Recarga | `fuel_amount` | float | 40 | u | Combustible que suma | Con `max_fuel` = 100 son 0,4 tanques; ver "Diseño de niveles" |
| Recarga | `only_if_not_full` | bool | false | — | No se recoge con el tanque del jugador lleno | Útil para que no se "desperdicien" tanques al principio |
| Recarga | `respawn_time` | float | 0 | s | Tiempo hasta reaparecer (0 = un solo uso) | Con reaparición se puede "farmear" un tanque: úsalo con cuidado |
| Visual | `bob_amplitude` | float | 3 | px | Vaivén vertical (0 = quieto) | Solo visual |
| Visual | `bob_frequency` | float | 1.0 | Hz | Velocidad del vaivén | Solo visual |

## Señales

| Señal | Cuándo se emite |
|---|---|
| `collected(amount: float)` | Un jugador recogió el tanque. `amount` es `fuel_amount` |

## API pública

| Función | Descripción |
|---|---|
| `is_available() -> bool` | true si el tanque está visible y recogible |
| `reset() -> void` | Lo deja disponible y cancela una reaparición pendiente. Si el jugador está encima en ese momento, lo recoge de nuevo al instante |

## Estructura de nodos

```
FuelTank (Area2D, capa 6, máscara 2)   script: fuel_tank.gd
├── Body (Polygon2D, cian)             se mueve con el vaivén
│   └── Detail (Polygon2D, blanco azulado)
└── CollisionShape2D (RectangleShape2D 12×16)
```

## Diseño de niveles

Con los valores por defecto (`PlayerConfig`: consumo 15 u/s, `max_fuel` 100), medido en simulación headless:

| Dato | Valor medido | Cómo se midió |
|---|---|---|
| Duración de la propulsión con un tanque de 40 u | ≈ 2,7 s | 40 u ÷ 15 u/s |
| Altura máxima subiendo en vertical con 40 u | ≈ 489 px | Jugador aislado, mantiene "arriba" hasta agotar el combustible, con `gravity_with_fuel` = 150 |
| Ídem con 60 u | ≈ 727 px | Ídem |
| Altura de un salto sin combustible | ≈ 61 px | Desde una plataforma, `jump_velocity` 260 y gravedad 500 |

Son cifras de referencia (sin obstáculos, sin scroll, sin steering lateral): sirven para ordenar magnitudes, no para dimensionar al píxel. Se redescubren jugando y cambian con `PlayerConfig`.

Cómo influye cada decisión:

- **`fuel_amount`**: es el radio de acción entre tanques. Cuanto más alto, más aire para explorar; cuanto más bajo, más presión por encadenar tanques.
- **Distancia entre tanques**: la variable central. Si es menor que lo que rinde un tanque, hay margen y el jugador puede desviarse; si se acerca al límite (≈ 85 % de lo que rinde), hay que ir directo y sin errores. Si lo supera, el tramo es imposible sin un tanque intermedio.
- **Posición**: un tanque a los lados de un obstáculo o una trampa obliga a arriesgar para recargar; uno sobre una plataforma alta obliga a tener una superficie y saltar (el salto solo llega a ~60 px).
- **Espiral de muerte** (`ROADMAP.md`, sección 6): sin combustible lejos de una superficie, el jugador cae hacia el tentáculo. Regla práctica: poner un tanque antes de que el jugador pueda estar más lejos de una superficie de lo que un salto cubre, o dejar siempre una plataforma cerca de cada tanque.
- **Scroll**: la cámara sube sola y ayuda a alcanzar tanques altos; con menos scroll, los mismos tanques quedan más "caros".

### Los cuatro tanques del sandbox

| Nodo | Posición | Qué prueba |
|---|---|---|
| `FuelTank1` | (150, 438) | En la ruta habitual, sobre `Platform1` y bajo `Obstacle1` |
| `FuelTank2` | (335, 265) | Sobre `FuelLedge` (nueva plataforma en x 318–352, y 275, 45 px sobre `Platform2`). Sin combustible se alcanza saltando desde el sector derecho de `Platform2` (probado desde x ≈ 270–285; desde el borde mismo choca contra la plataforma) |
| `FuelTank3` | (176, -290) | Junto a `PulseTrap2` (a 8 px de su borde): hay que acercarse a la trampa para recargar |
| `FuelTank4` | (110, -700) | ≈ 410 px sobre `FuelTank3` (≈ 84 % de lo que rinde un tanque de 40 u): se llega yendo de tanque en tanque con poco margen |

## Cómo probarlo

1. Abrir `scenes/levels/sandbox.tscn` (F6) con F3 activo: el overlay muestra el combustible.
2. Tocar `FuelTank1`: el combustible sube 40 (hasta 100) y el tanque desaparece. R reinicia y vuelve a estar.
3. Vaciar el combustible propulsando y recoger un tanque: vuelve el color normal y se puede propulsar de nuevo.
4. Sin combustible, subir a `Platform2`, caminar hasta su sector derecho y saltar hacia `FuelTank2`.
5. En `fuel_tank_config.tres` (con el juego cerrado): probar `only_if_not_full` y `respawn_time` > 0.
