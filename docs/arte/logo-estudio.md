# Logo del estudio

Pantalla en negro antes de la pantalla de inicio. Una tele vieja de tubo en perspectiva (tres cuartos, con antenas, perillas, parlante, patas y cola), en líneas blancas `#E7EFF2` con detalles en `#6689B7` y reflejo en `#B0BBCE`. Al terminar el reflejo, aparece en la pantalla un bebé riéndose y saludando (por Guido, que fue papá). Debajo, centrado: el nombre del estudio (por ahora `__________`) y `ESTUDIO`, en Tiny5 16 px.

| Archivo | Tamaño | Tags |
|---|---|---|
| `assets/aseprite/ui/logo/studio_logo.aseprite` → `assets/sprites/ui/logo/studio_logo.png` + `.json` | 104×84 por cuadro, se muestra a 2× | `empty` 1 (100 ms) · `reflect` 2–13 (70 ms) · `pop` 14–16 (destello 60 ms, bebé al 125 % y al 92 %, 70 ms) · `wave` 17–18 (200 ms, bucle) |

- Solo colores de la paleta. Sin capas `normal` ni `emissive` (no usa iluminación).
- El bebé está dibujado sobre el plano de la pantalla, en la misma perspectiva que la tele.
- Se generó por código (Python) y se cargó a Aseprite. Hay una opción B en isométrica en revisión.
