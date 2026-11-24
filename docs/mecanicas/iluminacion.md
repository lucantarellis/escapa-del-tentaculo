# Mecánica: iluminación de la nave

**Archivos:** `scripts/levels/level_lighting.gd` (`LevelLighting`, nodo `Lighting` de `Level.tscn`), `scripts/levels/lighting_config.gd` + `resources/configs/lighting_config.tres` (`LightingConfig`), `scripts/levels/wall_lights.gd` (`WallLights`, nodo `Lights` de `scenes/levels/WallsShip.tscn`). Luces en `player.gd`, `platform.gd`, `pickup_skin.gd` y `hatch.gd` (esta con valores en `IntroConfig`).

## Modelo

- **Oscuridad:** `Lighting` es un `CanvasModulate`. En los tiers con `SegmentTier.dark_ambient = true` (hoy "La nave") multiplica el mundo por `ambient_color` (~45 %); en los demás vuelve a blanco, con el mismo fundido que el fondo. Al romperse el ventanal de la salida se aclara junto con el cambio de fondo.
- **Qué no se oscurece:** el fondo en parallax y las estrellas (`LevelBackground`, otra capa), el HUD y los menús (`CanvasLayer`), y todo lo que tiene material sin sombreado: capas emisivas de paredes, plataformas, piso, escotilla, recogibles y el aura de los recogibles. Comprobado con render real.
- **Relieve:** paredes, plataformas, piso, escotilla, fragmentos y ventanal usan `CanvasTexture` con normal map, así que las luces marcan biseles, juntas y roturas según de dónde vienen. Las luces tienen altura (`light_height`, 40 px): con altura 0 la luz llega rasante y no ilumina lo plano.
- **Luces** (todas `PointLight2D` sin sombras, textura radial compartida de `LevelLighting.make_light`):

| Luz | Dónde | Comportamiento |
|---|---|---|
| Astronauta | hija del `Player` | Fija; es la principal. Tiene altura propia (`player_height`, 150) y curva más plana (`player_core`, 0,8) para llegar lejos; con `player_self_lit = false` el astronauta se dibuja sin sombreado, así su luz no lo quema. Para que igual lo afecte el entorno, cada frame se tiñe (`Player._update_environment_tint`) con todas las luces del grupo `env_lights` (las de `make_light`, menos la suya): se acerca a su color según energía × textura de la luz en su posición × `player_light_tint` (0,6) |
| Grietas | `WallLights`, una por grieta (celdas vecinas de la fuente 1 de `Dano`) | Naranja, titila; el radio crece con el tamaño de la grieta |
| Alarmas | `WallLights`, una por tile de alarma (fuente 1 de la pared, (0,2)–(0,5)) | Roja (las rotas más tenues). Se prende y apaga con el cuadro del tile: los tiles de alarma (0,2)–(0,5) de `walls_tileset_ship` y su versión emisiva corren en modo sincronizado (todas las alarmas en el mismo cuadro) y la luz calcula el cuadro con el autoload `AlarmClock`, el mismo reloj que usa Godot para animar los tiles. Encendida en los cuadros 2–5 (sanas) y 0, 3 y 6 (rotas); `WallLights.ALARM_ON_FRAMES` |
| Temporizada | hija de la `Platform` | Encendida fija, aviso que parpadea, apagada nada |
| Pulso | hija de la `Platform` | Letal: titila con el rayo; aviso: tenue; seguro: nada |
| Propulsores | hija de las plataformas móviles con sprites | Azul chica, fija |
| Recogibles | hija del `PickupSkin` | Cian tenue; destello al recoger. La moneda no la lleva (`pickup_light_on_coins`) |
| Escotilla | `Hatch/Light` | Ver `intro-escotilla.md` |

- **Rendimiento:** las luces de las paredes se apagan a más de `cull_margin` (120 px) de la pantalla; las demás son pocas por pantalla y Godot descarta las que no tocan la vista.

## Ajustes (`lighting_config.tres`)

**Hasta dónde ilumina el astronauta:** lo decide sobre todo la **altura**, no el radio. Con relieve, una superficie plana a distancia *d* recibe ≈ altura / √(d² + altura²) de la luz: con 35 px, a 250 px llega el 14 %; con 150 px, el 51 %. Para ver más lejos: subir `player_height` (y después `player_core`); el radio solo corta dónde termina. `player_energy` aclara todo por igual; con `player_self_lit = false` se puede subir sin que el jugador se queme.


Color de la oscuridad, altura de las luces, y color, energía y radio de cada tipo (grupos Astronauta, Grietas, Alarmas, Plataformas, Recogibles, Rendimiento). Todo es visual. `alarm_phase_offset` (0) corrige a mano un desfase entre la luz y el tile.

**Alarmas sincronizadas:** `AlarmClock` (`scripts/managers/alarm_clock.gd`) suma el `delta` de `_process`, que avanza igual que el tiempo con el que Godot anima los tiles en modo `ANIMATION_MODE_DEFAULT`. Si se redibuja la animación de la alarma, actualizar `ALARM_ON_FRAMES`; las duraciones por cuadro las lee del TileSet.

## Cómo probar

1. F5 → JUGAR: la nave arranca oscura; la escotilla tiñe de rojo el piso al romperse y el astronauta ilumina lo que tiene cerca.
2. Subir: pasar junto a una temporizada (luz cian que parpadea antes de apagarse) y una de pulso (luz que titila con el rayo).
3. Al romperse el ventanal, el mundo vuelve a la luz normal del espacio.
