# Plataformas de la nave (sprites)

Arte cerrado el 19/11/2026. Editables en `assets/aseprite/environment/platforms/` (capas `color`, `normal` y, si corresponde, `emissive`; animaciones como tags). Hojas exportadas en `assets/sprites/environment/platforms/`: `<tipo>.png`, `<tipo>_normal.png`, `<tipo>_emissive.png` y `<tipo>.json` (formato Aseprite: duración de cada cuadro y tags). Resumen de módulos y tags en `platforms_layout.json`.

## Cómo están armadas

- **Módulos de 10 px de ancho**, como la piel de fuego pero más chicos: tapa izquierda (`L`), centros (`C0`, `C1`, …) y tapa derecha (`R`). En cada hoja los módulos van uno al lado del otro en ese orden (columna = módulo) y los cuadros de animación uno debajo del otro (fila = cuadro). Región de un módulo `m` en el cuadro `k`: `Rect2(m * 10, k * alto_cuadro, 10, alto_cuadro)`.
- Una plataforma de ancho `w` usa `L` + `(w / 10 − 2)` centros elegidos al azar + `R`. El ancho se ajusta al múltiplo de 10 más cercano (mínimo 20). Hoy casi todos los anchos ya son múltiplos de 10; cambian solo unas pocas instancias (116, 42,1, 142, 39,7 y una rompible de 6 px de alto).
- **Alto 12 px = alto de la colisión**: el borde superior del dibujo es el piso. Excepción: la rompible usa cuadros de 30 px de alto con la viga en las filas 2–13 (deja lugar a los pedazos que caen): desplazar el sprite −2 px en Y.
- Relieve en `_normal` (OpenGL, Y+ arriba) vía `CanvasTexture`; lo emisivo en `_emissive`, en un sprite hermano sin sombreado, con el mismo cuadro.

| Tipo (`platform_type`) | Hoja | Módulos | Tags (cuadros, ms) | Notas |
|---|---|---|---|---|
| `STATIC` | `platform_static` | L, C0, C1, R | `idle` | Viga doble T. |
| `ONE_WAY` | `platform_oneway` | L, C0, R | `idle` | Pasarela de chapa perforada con borde amarillo; huecos transparentes. |
| `BREAKABLE` | `platform_breakable` (cuadros de 30 px) | L, C0–C3, R | `idle` · `shake` (3 × 50) · `break_fall` (8 × 70) · `break_hit` (6 × 60) · `respawn` (4 × 80) | Ver abajo. Cada centro se rompe distinto. |
| `TIMED` | `platform_timed` | L, C0, C1, R | `on` (8 × 90, loop) · `warning` (6 × 110, loop) · `turn_off` (3 × 80) · `off` · `turn_on` (3 × 80) | Las tapas (emisores) quedan visibles en `off`. |
| `PULSE` | `platform_pulse` | L, C0–C2, R | `off` · `warn` (8 × 80, loop) · `on` (8 × 60, loop) | Postes con bobina; rayo en `on`. |
| móvil (`moves`) | `platform_thruster` (6×9) | — | `idle` (4 × 80, loop) | Dos propulsores debajo de cualquier plataforma móvil, a ~10 px de cada punta, pegados al borde inferior. |

## Qué animación usar en cada momento

- **BREAKABLE**
  - Quieta: `idle`.
  - El jugador se para encima (empieza `break_delay`): `shake`, y al romperse `break_fall` (los pedazos caen un poco y se deshacen en el aire).
  - `break_now()` por el dash con "Rompe plataformas" (cualquier dirección): directo `break_hit` (destello de un cuadro y se deshace en el lugar). Sin `shake` y sin empuje.
  - Al terminar la rotura el sprite queda oculto (la colisión ya se apagó); al reaparecer (`restored`) `respawn` y después `idle`.
- **TIMED**
  - Sólida: `on`. Los últimos ~0,7 s antes de apagarse: `warning`. Al apagarse: `turn_off` y luego `off` (emisores solos, sin colisión). Al volver: `turn_on` y luego `on`.
  - Hoy el cuerpo se oculta entero al apagarse; con los sprites deberían seguir visibles las tapas (`off`).
  - El aviso necesita un valor nuevo en `PlatformConfig` (por ejemplo `timed_warning_time`, 0,7 s), igual que `pulse_warning_time`.
- **PULSE**: `off` en fase segura, `warn` durante `pulse_warning_time`, `on` en fase letal. Reemplaza los colores de `_apply_pulse_visual()`.
- **Variedad**: centros al azar por módulo (semilla estable por nombre y posición, como el fuego) y cuadro inicial al azar en los loops de `on` y `warn`.
- **Luces sugeridas**: `PointLight2D` cian suave en la temporizada encendida y en la de pulso letal (que parpadee con el rayo); una chica azul en cada propulsor.

## Conectado en Godot

Lo dibuja `PlatformSkin` (`scripts/platforms/platform_skin.gd`), hijo `Skin` de cada `Platform` con sprites. Qué tag se muestra en cada estado y cómo se ajusta el tamaño: `docs/mecanicas/plataformas.md`, sección "Sprites de la nave". Si cambia el arte, alcanza con volver a exportar las hojas y el JSON con los mismos nombres y tags.

## Fuera de esta tanda

Letales sin fuego (guardias, barredoras, bloques chicos móviles, losas de 300×30) y el proyectil: se redefinen junto con los segmentos nuevos. Para lo letal permanente, la idea es reutilizar el rayo de la de pulso siempre prendido o la piel de fuego.
