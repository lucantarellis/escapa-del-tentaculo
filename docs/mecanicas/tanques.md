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

## Dibujo

Hijo `Skin` (`PickupSkin`, hoja `pickup_tank`): tambor de 200 L de 12×16 px en un cuadro de 38×38, con aura cian detrás y partes cian emisivas encima (ver "Recogibles con sprites" más abajo). Al recogerlo se reproduce el destello `collect` (0,4 s) y recién ahí se oculta; con `reset()` vuelve a `idle`.

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

## Recogibles con sprites

Moneda, tanque, impulso y los tres reparadores se dibujan con `PickupSkin` (`scripts/pickups/pickup_skin.gd`); arte y hojas en `docs/arte/recogibles.md`.

- **Capas:** aura (detrás, sin sombreado), ítem y emisivo (encima, sin sombreado), tres `AnimatedSprite2D` que siguen el cuadro del ítem. `SpriteFrames` armados desde el JSON de Aseprite y compartidos entre instancias.
- **Animación:** `idle` (8 cuadros, 120 ms, loop) arranca en un cuadro al azar; `collect` (8 cuadros, 50 ms, sin loop) al recoger. El vaivén lo sigue haciendo cada recogible moviendo el `Skin`.
- **Al terminar `collect`:** la moneda se libera (`queue_free`); tanque, impulso y reparadores se ocultan (no se liberan: el tanque puede reaparecer o resetearse). La colisión se apaga y el efecto se aplica al recoger, no al terminar el destello.
- **Hoja por recogible:** tanque `pickup_tank`, moneda `pickup_coin`, impulso `pickup_boost`, reparador llave `pickup_wrench`, venda `pickup_tape` (cinta selladora), botiquín `pickup_toolbox` (caja de herramientas). Las colisiones no cambiaron.
- **Editor:** `PickupSkin` es `@tool`; muestra el primer cuadro del ítem elegido en `sheet`.
- **Luz opcional:** un `PointLight2D` cian chico por recogible queda para el paso de iluminación.

## Estructura de nodos

```
FuelTank (Area2D, capa 6, máscara 2)   script: fuel_tank.gd
├── Skin (PickupSkin)                  se mueve con el vaivén
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

## Mejora de tanques

Con el progreso activo (ver `progreso-mercado.md`), según la carga comprada en el árbol (Carga de 100, Carga completa) cada tanque da ese valor cuando es mayor que `fuel_amount`. El `.tres` no cambia.

## Cómo probarlo

1. Ejecutar `scenes/levels/Level.tscn` (F6) con F3 activo: el overlay muestra el combustible.
2. Tocar un tanque: el combustible sube y el tanque desaparece. R reinicia y vuelve a estar.
3. Vaciar el combustible propulsando y recoger un tanque: vuelve el color normal y se puede propulsar de nuevo.
4. En `fuel_tank_config.tres` (con el juego cerrado): probar `only_if_not_full` y `respawn_time` > 0.
