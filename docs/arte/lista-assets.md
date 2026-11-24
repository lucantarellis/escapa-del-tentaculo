# Lista de assets a pasar a la línea de arte nueva

Relevamiento del 15/11/2026 sobre `main-g` (997e813). La referencia de la línea nueva es la plataforma letal con fuego (`assets/sprites/environment/fire_platform/`). Los tamaños salen de colisiones y variables exportadas, no del arte. Entre paréntesis, en cuántos segmentos aparece (de 72).

Marcar con `[x]` a medida que se termina. Última actualización: 23/11/2026 (brief 08: escotilla, tentáculo, HUD, mercado, gas y efectos).

# Prioridad de ataque

0. **Decisión previa:** astronauta y tentáculo de la nave. Están en pantalla todo el tiempo; si no siguen la línea nueva desentonan con todo. Definir esto antes de empezar fija el estilo de referencia.
1. **P1: Limpieza.** Es sencilla; se saca de encima primero.
2. **P2: Entorno base.** Aparece en casi todos los segmentos y ocupa más pantalla: paredes (72/72), plataformas (66), tanque (72), monedas (las reparte un spawner en cada segmento) y fondos por tier.
3. **P3: Peligros y perseguidores.** Definen cada tier: espacio y alien, más el fuego y el ácido que persiguen.
4. **P4: Meta, intro y escenas de transición.** Se ven una vez por partida o por tier.
5. **P5: UI.** HUD, título, mercado y tipografía.

# Checklist por categoría

## 0. Decisión previa
- [x] Astronauta: rehecho a 1× en `assets/aseprite/player/astronaut/astronaut.aseprite` (lienzo 32×40, figura 23×32; la colisión sigue en 16×24). Capas `cuerpo` y `visor_reflejo`. 63 frames, tags `idle`, `walk`, `jump`, `thrust`, `thrust_side` y los mismos con `_dano_1` y `_dano_2`. Llama: `assets/aseprite/player/astronaut/astronaut_flame.aseprite` → `assets/sprites/player/astronaut/astronaut_flame.png` (tira 24×14, 3 frames de 8×14, 70 ms; sale de la mochila: centro en (−8, +20) respecto del centro del astronauta, espejar con el sprite y dibujar detrás). Conectado en el brief 07 (`docs/mecanicas/jugador.md`); `assets/sprites/Astronaut/` borrado.
- [x] Tentáculo de la nave: rehecho como mar de tentáculos en `assets/aseprite/tentacle/`. `front/tentacle_front_01..04` (300×384, base abajo al centro; tags `idle_a`, `idle_b`, `reach`, `grab`, `retract`; 01 y 03 miran a la derecha, 02 y 04 a la izquierda), `fill/tentacle_fill_01..05` (300×360, tag `idle`), `flesh/tentacle_flesh` (360×400, tag `idle`, respiración sutil) y `flesh/tentacle_flesh_deep` (360×120, se repite hacia abajo). Orden de dibujo: fill, front, flesh, flesh_deep. Una sola colisión. Conectado en el brief 07 (`TentacleSea`, `docs/mecanicas/tentaculo.md`); el frente viejo con doblez y sus sprites se borraron.

## Limpieza (P1)
- [x] `scifi_tileset.png`, `astronaut_spritesheet.png`, `tentacle_spritesheet.png` y los sprites viejos del tentáculo (`completos`, `enrollado`, `entrada_lateral`, `escenas`, `movimiento`, `puntas`, `segmentos`, `variantes`, `vertical`): borrados en el brief 07.
- [ ] Los 3 `walls_placeholder*` y `walls_tileset.tres`: los siguen usando el espacio, el alien y el final; reemplazar al entrar el arte final de esas paredes.

## Entorno base (P2)
- [x] Paredes de la nave: tilesets en `assets/aseprite/environment/ship_walls/` → `assets/sprites/environment/ship_walls/` (pared con 47 combinaciones + diagonales, variantes y tiles animados; capas de rotura, grieta incandescente, bilis, parche remachado y cañerías; cada uno con relieve y emisivo). Detalle y armado: `docs/arte/paredes-nave.md`. TileSets en `resources/tilesets/walls_tileset_ship.tres` y `ship_walls_overlay.tres` (+ emisivos). Conectado en el brief 07: los 34 segmentos de la nave y de inicio usan `WallsShip.tscn` con capas `Detalle`/`Dano` y emisivas; luces de grietas y alarmas en `WallLights`. Pintar daño y detalle a mano (LT).
- [ ] Paredes del espacio: ídem (los 13 asteroides las reutilizan).
- [ ] Paredes del alien: ídem.
- [x] Plataforma estática: `assets/aseprite/environment/platforms/platform_static.aseprite`. Ver `docs/arte/plataformas-nave.md`.
- [x] Plataforma de un solo sentido: `platform_oneway.aseprite`.
- [x] Plataforma rompible: `platform_breakable.aseprite` (`idle`, `shake`, `break_fall`, `break_hit`, `respawn`).
- [x] Plataforma temporizada: `platform_timed.aseprite` (`on`, `warning`, `turn_off`, `off`, `turn_on`).
- [x] Plataforma de pulso: `platform_pulse.aseprite` (`off`, `warn`, `on`). Propulsores de móviles: `platform_thruster.aseprite`. Todas conectadas en el brief 07 (`PlatformSkin`).
- [ ] Plataforma proyectil (16 px): pospuesta, se redefine con los segmentos nuevos.
- [ ] Plataforma letal con fuego: aplicar `fire_skin` en las plataformas letales de los segmentos (la escena de prueba `FirePlatformTest.tscn` se borró).
- [x] Fondo de la nave: 3 capas × 3 tramos en `assets/aseprite/environment/background_ship/`. Ver `docs/arte/fondo-nave.md`.
- [ ] Fondo del espacio, con estrellas y decoración.
- [ ] Fondo del alien.
- [x] Piso del segmento de inicio (10 segmentos): 3/4, módulos de 20×27 + piezas 2D para paredes laterales. `floor_ship`. Guía: `docs/arte/piso-y-escotilla.md`.

## Recogibles (P2 y P3)
- [x] Tanque de combustible, 12×16 (P2): tambor de 200 L. `pickup_tank`.
- [x] Moneda, 16 px (P2): ficha octogonal con el logo de la nave (planeta con órbita). `pickup_coin`.
- [x] Impulso, 20 px (P3). `pickup_boost`.
- [x] Reparador +1: llave, 22 px (P3). `pickup_wrench`.
- [x] Reparador +2: cinta selladora en 3/4, 22 px (P3). `pickup_tape`.
- [x] Reparador completo + escudo: caja de herramientas, 22 px (P3). `pickup_toolbox`.
- Editables en `assets/aseprite/pickups/`, hojas en `assets/sprites/pickups/`. Guía: `docs/arte/recogibles.md`.

## Peligros del espacio (P3)
- [ ] Meteoro (16 px, estela de 90) y su marca de aviso.
- [ ] Cometa y su línea punteada de recorrido.
- [ ] Satélite láser: cuerpo, línea de apuntado y haz letal de 700×14.
- [ ] Campo de escombros: fragmentos de 18 px y anillo de órbita de 70 px.
- [ ] Fragmentos del casco, que salen de la explosión.
- [ ] Perseguidor: fuego.

## Peligros del alien (P3)
- [ ] Anticuerpo (11 px de radio), con sus estados de patrulla, fijado y ataque.
- [ ] Pared de bilis: orificio, bulto de aviso y proyectil de 14 px.
- [ ] Tentáculo menor, de 150 px de largo y 14 de base.
- [ ] Contracciones, esfínteres y membranas.
- [ ] Perseguidor: ácido.

## Meta, intro y transiciones (P4)
- [ ] Puerta, 48×72 (11 segmentos). En pausa: puede desaparecer si hay pelea con el jefe final.
- [x] Escotilla de la intro: 3/4, cuadros de 144×96 con golpes, ruptura y rota; abolladura en domo con desgarro en V; capas color, relieve y emisiva (la capa `glow` se eliminó: la luz es de Godot); fragmentos aparte. `assets/sprites/intro/`. Ver brief 08.
- [x] Gas de la escotilla: 3 formas de bocanada de 14×14, 4 cuadros c/u (`gas_puff_a/b/c`). También se reutiliza para la fuga del traje a 1 golpe. `assets/aseprite/fx/gas_puff.aseprite`, guía `docs/arte/efectos.md`.
- [x] Ventanal de la nave con vidrios (3 segmentos): 2D, `window_breach` + succión + vidrios; el tentáculo reutiliza `tentacle_front`. Guía: `docs/arte/ventanal.md`.
- [ ] Membrana de carne y tentáculo vertical del final del espacio.
- [ ] Explosión de cambio de tier: anillo, fuego y destello (7 segmentos).
- [ ] Luz de apertura y haz de salida del tier 3, con venas y motas.

## Efectos del jugador (P4)
- [x] Escudo ovalado: `player_shield` (54×74; `loop` y `pop`).
- [x] Efecto de reparación: `player_repair` (32×40; cruz, chispas y crucecitas) + shader de barrido cian sobre el cuerpo (código).
- [x] Efecto de dash: sin arte, rastro de "fantasmas" por código.
- [x] Efecto de reaparición: `player_respawn` (32×56; `vanish` en el lugar viejo y `respawn` en el nuevo).
- [x] Fuga del traje a 1 golpe: reutiliza el gas con recolor y dirección al azar (código).
- Editables en `assets/aseprite/fx/`, hojas en `assets/sprites/fx/`. Guía: `docs/arte/efectos.md`.

## UI (P5)
- [x] Barra de combustible.
- [x] Progreso, con marcas de récord y de tiers.
- [x] Marcador del tentáculo en el progreso (relleno rojo + calavera).
- [x] Vida: celdas de integridad del traje + escudo.
- [x] Ícono del contador de monedas.
- [x] Barrita de enfriamiento del dash. (HUD completo: `docs/arte/hud.md`)
- [x] Pantalla de inicio: logo animado `title_logo` (RISE cian, DIE rojo, OR en placa, tentáculos del juego) sobre el hub oscurecido, "TOCÁ PARA EMPEZAR" y versión. Guía `docs/arte/titulo.md`.
- [x] Hub: puertas a Ajustes (izquierda) y Mercado (derecha), en perspectiva dentro de la pared, con cartel e iluminación desde Godot. `assets/aseprite/environment/hub_doors/`, guía `docs/arte/hub.md`.
- [x] Hub: sala iluminada de una pantalla, ascensor con propulsores en su muelle (plataforma, mordazas, rieles) y lámparas. `assets/aseprite/environment/hub/`, guía `docs/arte/hub.md`.
- [x] Ajustes y créditos: pantallas de UI con piezas del mercado + `settings_ui` (barra deslizante, interruptor, botón de peligro, flechas, íconos). Guía `docs/arte/ajustes.md`.
- [x] Mercado: puesto con ambiente animado (`market_booth`), vendedor-pantalla con 6 animaciones (`market_face`) y UI en piezas 9-slice (`market_ui`: solapas, filas por estado, botones, scrollbar). Guía: `docs/arte/mercado.md`.
- [x] Mercado: un ícono por rama (`mk_branch_{dash,speed,tank,life,repair,coins}`); se decidió uno por rama + nivel en vez de uno por mejora.
- [x] Tipografía: Tiny5 (OFL) en `assets/fonts/` para HUD, mercado y menús; 16 px mínimo, siempre múltiplos de 8. El logo del título está dibujado (ver `docs/arte/titulo.md`).
- [x] Pantalla de derrota: viñetas `death_captured_a` y `death_electrocuted_a` (`assets/aseprite/ui/death/`), armado y comportamiento en `docs/arte/derrota.md`. Integrada en el juego (brief 09; ver `docs/mecanicas/pantalla-derrota.md`).
- [x] Logo del estudio: tele con el bebé, `studio_logo` (`assets/aseprite/ui/logo/`); ver `docs/arte/logo-estudio.md`. Opción B isométrica guardada aparte (`studio_logo_b.aseprite`), sin usar.
- [ ] Pantallas de derrota de los tiers 2 y 3, y pantalla de victoria (depende del jefe).

## Fuera de esta lista
- Audio: `assets/audio/sfx` y `assets/audio/music` están vacías.
