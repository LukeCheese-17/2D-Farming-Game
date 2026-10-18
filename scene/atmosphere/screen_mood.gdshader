shader_type canvas_item;
// Post-process for the game world: mutes colours, tints by time of day and darkens the edges.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0);
uniform float desaturation : hint_range(0.0, 1.0) = 0.3;
uniform float vignette : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(gray), desaturation) * tint.rgb;
	vec2 from_center = (SCREEN_UV - 0.5) * vec2(1.5, 1.0);
	float edge = smoothstep(0.3, 0.8, length(from_center));
	color *= 1.0 - edge * vignette;
	COLOR = vec4(color, 1.0);
}
