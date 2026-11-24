shader_type canvas_item;
render_mode unshaded;
// Destello de reparación sobre el cuerpo del astronauta (ver `Player._play_repair_flash`).
// Una banda cian de `band_px` px recorre el cuadro de abajo hacia arriba según `progress` (0 → 1);
// en el primer tramo (`dither_until`) suma un tinte en tramado (píxel sí, píxel no). Solo visual.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Bordes superior e inferior del cuadro en coordenadas locales del sprite (px).
uniform float frame_top = -20.0;
uniform float frame_bottom = 20.0;
uniform float band_px = 3.0;
uniform vec4 band_color : source_color = vec4(0.537, 0.851, 0.922, 1.0);
uniform vec4 dither_color : source_color = vec4(0.388, 0.839, 0.773, 1.0);
uniform float dither_until : hint_range(0.0, 1.0) = 0.25;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	vec2 px = floor(local_pos);
	// Fila de arriba de la banda: arranca debajo del cuadro y termina arriba de todo.
	float band_top = floor(mix(frame_bottom, frame_top - band_px, progress));
	bool in_band = px.y >= band_top && px.y < band_top + band_px;
	if (tex.a > 0.0) {
		if (progress < dither_until && mod(px.x + px.y, 2.0) == 0.0) {
			tex.rgb = dither_color.rgb;
		}
		if (in_band) {
			tex.rgb = band_color.rgb;
		}
	}
	COLOR = tex;
}
