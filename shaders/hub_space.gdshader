shader_type canvas_item;
// Espacio que se ve por los ventanales del hub (ver `Hub._process`): repite `hub_space` en las 4
// direcciones, lo desplaza (`drift`, px) y lo rota alrededor del centro de la pantalla (`angle`,
// rad). Rotar las UV evita bordes serruchados en el contorno. Solo visual.

uniform sampler2D space_texture : repeat_enable, filter_nearest;
uniform vec2 texture_size = vec2(1600.0, 1200.0);
uniform vec2 rect_size = vec2(360.0, 640.0);
uniform vec2 drift = vec2(0.0);
uniform float angle = 0.0;

void fragment() {
	vec2 p = floor(UV * rect_size) - rect_size * 0.5;
	float c = cos(angle);
	float s = sin(angle);
	vec2 rotated = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
	vec2 sample_px = floor(rotated + drift);
	COLOR = texture(space_texture, (sample_px + 0.5) / texture_size);
}
