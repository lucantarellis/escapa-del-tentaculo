shader_type canvas_item;
// Capa de fondo de la nave y del espacio: desenfoque (gaussiano 5×5) y niebla hacia un color oscuro.
// Ver scripts/levels/ship_background.gd, scripts/levels/space_background.gd, docs/arte/fondo-nave.md
// y docs/arte/fondo-espacio.md.

// Radio del desenfoque. 0 = nítida. Unidad: px de la textura.
uniform float blur_radius = 0.0;
// Color hacia el que se funde la capa (lejanía).
uniform vec4 fog_color : source_color = vec4(0.0549, 0.0863, 0.1961, 1.0);
// Cuánto se funde hacia fog_color. 0 = nada, 1 = todo el color de la niebla.
uniform float fog_amount : hint_range(0.0, 1.0) = 0.0;

// Color del vértice con el modulate del nodo (los fundidos), sin la textura: en fragment() el
// COLOR de entrada ya viene multiplicado por la textura, y usarlo de nuevo la oscurece al cuadrado.
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (blur_radius > 0.01) {
		vec4 sum = vec4(0.0);
		float weight_sum = 0.0;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				vec2 k = vec2(float(x), float(y));
				float w = exp(-dot(k, k) / 4.5);
				vec4 s = texture(TEXTURE, UV + k * (blur_radius * 0.5) * TEXTURE_PIXEL_SIZE);
				// Promedio con alfa premultiplicado: los bordes transparentes no se oscurecen.
				sum += vec4(s.rgb * s.a, s.a) * w;
				weight_sum += w;
			}
		}
		sum /= weight_sum;
		c = sum.a > 0.0001 ? vec4(sum.rgb / sum.a, sum.a) : vec4(0.0);
	}
	c.rgb = mix(c.rgb, fog_color.rgb, fog_amount);
	COLOR = c * vertex_color;
}
