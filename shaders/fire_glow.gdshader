shader_type canvas_item;
render_mode blend_add, unshaded;
// Glow del fuego del espacio: la capa emisiva de las explosiones, desenfocada (gaussiano 5×5),
// teñida y sumada encima. El alfa del modulate de cada cuadro lo apaga donde el lavado ya tapó
// el fuego. Ver scripts/tentacle/fire_chaser.gd y docs/arte/peligros-espacio.md.

// Color con el que se tiñe el brillo.
uniform vec4 glow_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
// Fuerza del brillo (multiplica la luz sumada).
uniform float intensity = 0.8;
// Radio del desenfoque. Unidad: px de la textura (el emisivo deja 3 px libres en cada cuadro).
uniform float blur_radius = 3.0;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 sum = vec4(0.0);
	float weight_sum = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 k = vec2(float(x), float(y));
			float w = exp(-dot(k, k) / 4.5);
			vec4 s = texture(TEXTURE, UV + k * (blur_radius * 0.5) * TEXTURE_PIXEL_SIZE);
			sum += vec4(s.rgb * s.a, s.a) * w;
			weight_sum += w;
		}
	}
	sum /= weight_sum;
	vec3 light = sum.rgb * glow_color.rgb;
	COLOR = vec4(light, intensity * vertex_color.a);
}
