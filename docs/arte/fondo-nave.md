# Fondo de la nave (parallax)

Arte cerrado el 19/11/2026. Editables en `assets/aseprite/environment/background_ship/` (capas `color` y `emissive`, 8 cuadros de 120 ms, tag `loop`). Hojas exportadas en `assets/sprites/environment/background_ship/`: `<tramo>.png` y `<tramo>_emissive.png` (cuadros uno debajo del otro, 360×320 cada uno) y `<tramo>.json` (formato Aseprite). Puntos de luz por tramo en `bg_ship_lights.json`.

## Idea

Un pozo vertical industrial de la nave, a oscuras: eje del reactor al fondo, paredes cargadas de máquinas, pasarelas, cables y caños. **No hay luz general**: solo balizas rojas de emergencia, incendios, chispas y pantallas. El fondo es contexto: nunca compite con paredes ni plataformas (sin superficies horizontales con borde marcado, sin amarillo de seguridad ni cian de los puentes).

## Capas y tramos

| Capa | Tramos | Qué tiene | Velocidad (`scroll_scale.y`) | Desenfoque | Oscurecido |
|---|---|---|---|---|---|
| Lejana (`far`) | `bg_ship_far_01..03` | Eje del reactor con anillos de luces muertas, costillas, pasarelas lejanas | ~0,2 | fuerte (~2 px de radio) | ~55 % |
| Media (`mid`) | `bg_ship_mid_01..03` | Paredes de chapa con máquinas (tanques, consolas, puertas forzadas, racks, ventiladores, carteles), pasarela rota, cables con origen, balizas, incendios (máquina, caño cortado, cubierta, brasas) | ~0,45 | suave (~1 px) | ~80 % |
| Cercana (`near`) | `bg_ship_near_01..03` | Caños anchos en los bordes con abrazaderas y cables de cuatro tipos, algunos cortados con chispas | ~0,75 | ninguno (nítida) | sin cambio |

- **Los tramos encajan en cualquier orden**: columnas, paredes, costillas, caños y bordes están siempre en el mismo lugar y los ritmos verticales dividen 320.
- **Los assets van nítidos.** El desenfoque y la niebla los pone Godot.

## Cómo se arma en Godot

- **Fondo infinito, independiente de los segmentos:** una `Parallax2D` por capa (detrás del mundo; la lejana más atrás), con 3 `AnimatedSprite2D` (o `Sprite2D` con región por cuadro) apilados de 320 px. Cuando un tramo sale por abajo de la cámara, se mueve arriba del todo y se le asigna otro tramo al azar de esa capa (evitar repetir el mismo dos veces seguidas). Así sirve igual con 10 o con 20 segmentos.
- **Animación:** los 8 cuadros en loop a 120 ms; arrancar cada tramo en un cuadro al azar.
- **Desenfoque:** shader de desenfoque (gaussiano de 2 pasadas o `textureLod` sobre un `BackBufferCopy`/`SubViewport` por capa) con el radio de la tabla. Ajustable en la config.
- **Niebla:** `modulate` por capa hacia un azul muy oscuro (por ejemplo `#0E1632` a 45 % en la lejana y 20 % en la media).
- **Emisivo:** el `_emissive` va en un sprite hermano encima, sin desenfoque fuerte y sin oscurecer, con material sin sombreado (aditivo opcional), así las balizas, fuegos, chispas y pantallas brillan a través de la niebla.
- **Luces:** `bg_ship_lights.json` trae por tramo los puntos de `beacon` (con su `phase` de giro), `fire` y `spark` en coordenadas del tramo. Poner un resplandor (sprite radial suave o `PointLight2D` que solo afecte a esa capa) en cada uno: rojo para las balizas siguiendo el giro (intensidad según el cuadro), naranja que titila para los fuegos, y un destello corto para las chispas (cuadros 1–3 y 7 del loop).
- **Oscuridad del juego:** el fondo no lo oscurece el `CanvasModulate` del mundo; ya viene oscuro. La luz ambiente del mundo tiene que dejar las paredes y plataformas más claras que el fondo (en las pruebas, ~50 %).
- **Todo ajustable en un `Resource`** (por ejemplo `background_config.tres`): velocidades, radios de desenfoque, color e intensidad de la niebla, intensidad de cada tipo de luz.

## Conectado en Godot (Paso 6 del brief 07)

- **Archivos:** `scenes/levels/ShipBackground.tscn` + `scripts/levels/ship_background.gd` (`ShipBackground`), shader `shaders/background_layer.gdshader` (desenfoque gaussiano 5×5 + niebla), ajustes en `resources/configs/ship_background_config.tres` (`ShipBackgroundConfig`: velocidad, desenfoque y niebla por capa, emisivo, color/radio/intensidad de cada tipo de resplandor).
- **Dónde vive:** `LevelBackground` (capa de pantalla −10) lo instancia detrás de las estrellas. Se muestra en los tiers con `SegmentTier.background_ship = true` (hoy, "La nave") y se funde con el mismo `background_fade` al pasar al espacio.
- **Parallax a mano en lugar de `Parallax2D`:** el fondo está en una capa de pantalla, así que el desplazamiento se calcula desde la Y de la cámara (como las estrellas) y se redondea al píxel. Los tramos de cada capa salen de `bg_ship_lights.json` (campo `layer`); para sumar un tramo alcanza con exportarlo y agregarlo a ese JSON.
- **Resplandores:** manchas radiales aditivas en cada punto de `bg_ship_lights.json`. La intensidad de cada cuadro se mide en los píxeles del emisivo alrededor del punto, así las balizas siguen su giro y las chispas aparecen en sus cuadros sin tablas a mano; los fuegos suman un titileo propio (`fire_flicker`).
- **Emisivo:** sprite encima de cada tramo, sin niebla ni desenfoque.

## Más adelante

Tramos especiales en puntos fijos (fondo del pozo al arrancar, salida al espacio al final de la nave), disparados por el código igual que hoy cambia el fondo al entrar a un tier.

## Reglas para tramos nuevos

- Nada animado ni emisivo (fuegos, humo, chispas, cables que se balancean) a menos de ~40 px del borde superior o inferior del tramo: si se corta en el borde, el tramo de arriba no lo continúa.
- Todo cable sale de algo visible: caja de conexión sobre una abrazadera, la parte de abajo de una pasarela (con su grampa), una consola o una puerta.
- Todo fuego sale de algo: el techo de una máquina, un caño cortado (el caño se dibuja), una cornisa rota o el borde de una brecha.
- Nada que cruce todo el ancho como una línea fina: las pasarelas lejanas van de costilla a costilla, con ménsulas.
