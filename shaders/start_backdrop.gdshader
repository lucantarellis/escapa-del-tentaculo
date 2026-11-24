shader_type canvas_item;
// Fondo de la pantalla de inicio (ver `StartScreen`): toma lo que hay detrás (el hub en vivo), lo
// desenfoca ~1 px, lo mezcla con `tint` (oscurece) y le suma una viñeta. Solo visual.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 tint : source_color = vec4(0.055, 0.086, 0.196, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.65;
uniform float blur_px = 1.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_px;
	vec3 c = texture(screen_texture, SCREEN_UV).rgb * 0.4;
	c += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)).rgb * 0.15;
	c += texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0)).rgb * 0.15;
	c += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)).rgb * 0.15;
	c += texture(screen_texture, SCREEN_UV - vec2(0.0, px.y)).rgb * 0.15;
	c = mix(c, tint.rgb, tint_amount);
	float d = distance(UV, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.3, 0.75, d);
	COLOR = vec4(c, 1.0);
}
