# Mecánica: pantalla de inicio

**Archivos:** `scripts/ui/start_screen.gd` (`StartScreen`), `shaders/start_backdrop.gdshader`. La crea el `Hub` (`show_start_screen = true`) dentro de su capa `Ui`. Arte y medidas: `docs/arte/titulo.md`. Reemplaza al `TitleMenu` (borrado en el brief 08, 8d).

## Qué hace

Al abrir el juego, `Main` muestra el hub con la pantalla de inicio encima. El hub sigue vivo detrás (fondo animado, espacio por los ventanales), oscurecido, desenfocado ~1 px y con viñeta (shader sobre la pantalla: mezcla con `#0E1632` al 65 %). El jugador no está en escena (congelado, oculto y sin colisión) hasta que se toca.

1. **Entrada:** pausa de 0,5 s (`INTRO_DELAY`) con el hub a la vista; después `title_letters` baja desde y −220 hasta su lugar (0,5 s ease-out cúbica pasándose 10 px y 0,2 s de vuelta). Al llegar, `title_tentacles_back` y `title_tentacles_front` reproducen `emerge` (sale el humo y de ahí los tentáculos) y pasan a `idle` en bucle.
2. **"TOCÁ PARA EMPEZAR"** (Tiny5 16 px `#E7EFF2`, centrado en (180, 520)) aparece y parpadea 0,6 s / 0,6 s. La versión (`v` + `application/config/version`) va abajo a la derecha en `#6689B7`.
3. **Al tocar** (tecla, botón del joystick, toque o clic): el texto se oculta y el jugador aparece en el piso, al centro (180, 591), con la animación de reaparición (`Player.play_appear`); mientras, todo se funde en 0,5 s y se libera. Las teclas (barra espaciadora incluida) se leen en `_input`, antes que la interfaz.

Tocar durante la entrada la saltea (queda en `idle` con el texto). Al volver de una partida (Escape tras ganar o perder) se vuelve al hub sin la pantalla de inicio.

## Cómo probarlo

1. F5: el logo cae con rebote, salen los tentáculos del humo y aparece el texto parpadeando; atrás se ve el hub oscuro.
2. Tocar o apretar una tecla: se funde y se puede caminar.
3. F5 y tocar enseguida: la entrada se saltea.
