shader_type canvas_item;
// Fuga de gas del traje (ver `Player._burst_leak`): las bocanadas de la escotilla (`gas_puff_*`)
// recoloreadas por color exacto para que se vean más frías y brillantes, con la misma animación
// por partícula que `CanvasItemMaterial.particles_animation` (cuadros horizontales, sin bucle).
// Solo visual.

uniform int particles_anim_h_frames = 4;
uniform int particles_anim_v_frames = 1;
uniform bool particles_anim_loop = false;
uniform vec4 from_dark : source_color = vec4(0.4, 0.537, 0.718, 1.0);
uniform vec4 to_dark : source_color = vec4(0.227, 0.608, 0.749, 1.0);
uniform vec4 from_mid : source_color = vec4(0.565, 0.682, 0.827, 1.0);
uniform vec4 to_mid : source_color = vec4(0.537, 0.851, 0.922, 1.0);
uniform vec4 from_light : source_color = vec4(0.784, 0.906, 0.918, 1.0);
uniform vec4 to_light : source_color = vec4(0.906, 0.937, 0.949, 1.0);

void vertex() {
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	VERTEX.xy /= vec2(h_frames, v_frames);
	float total = float(particles_anim_h_frames * particles_anim_v_frames);
	float frame = floor(INSTANCE_CUSTOM.z * total);
	if (!particles_anim_loop) {
		frame = clamp(frame, 0.0, total - 1.0);
	} else {
		frame = mod(frame, total);
	}
	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(frame, h_frames) / h_frames, floor((frame + 0.5) / h_frames) / v_frames);
}

vec3 recolor(vec3 c) {
	if (distance(c, from_dark.rgb) < 0.02) return to_dark.rgb;
	if (distance(c, from_mid.rgb) < 0.02) return to_mid.rgb;
	if (distance(c, from_light.rgb) < 0.02) return to_light.rgb;
	return c;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	tex.rgb = recolor(tex.rgb);
	COLOR = tex * COLOR;
}
