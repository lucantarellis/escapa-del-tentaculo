class_name HudConfig
extends Resource
## Ajustes del HUD ([Hud]) que no son layout fijo: escala de la vida y las monedas, y la alerta de
## combustible crítico. Ver `docs/mecanicas/hud.md`.

@export_group("Estado")
## Escala entera de la esquina de arriba (monedas, celdas de vida y escudo). Pixel art: solo
## enteros. Solo visual.
@export_range(1, 3, 1) var status_scale: int = 2

@export_group("Alerta de combustible")
## Debajo de esta proporción del tanque aparece la alerta (0..1). 0 la apaga.
@export_range(0.0, 1.0, 0.05) var fuel_alert_threshold: float = 0.25
## Parpadeo de la alerta: tiempo visible y tiempo oculto. Solo visual. Unidad: s.
@export_range(0.05, 2.0, 0.05) var fuel_alert_on_time: float = 0.45
@export_range(0.05, 2.0, 0.05) var fuel_alert_off_time: float = 0.2
## Texto de la alerta; `%d` es el porcentaje que queda. Solo visual.
@export var fuel_alert_text: String = "COMBUSTIBLE %d%%"
## Texto con el tanque vacío. Solo visual.
@export var fuel_empty_text: String = "SIN COMBUSTIBLE"
