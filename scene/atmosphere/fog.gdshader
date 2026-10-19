shader_type canvas_item;
// Drifting ground fog. Two scrolling noise layers, anchored to the world so the fog
// stays put when the camera moves, snapped to 2px blocks and a few alpha steps to
// match the pixel art.

uniform sampler2D noise_a : repeat_enable, filter_linear;
uniform sampler2D noise_b : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.78, 0.8, 0.84, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.3;
uniform vec2 wind = vec2(0.01, 0.003);
// World pixels to noise UV.
uniform float scale = 0.0035;
uniform float alpha_steps = 6.0;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv = floor(world_position / 2.0) * 2.0 * scale;
	float a = texture(noise_a, uv + TIME * wind).r;
	float b = texture(noise_b, uv * 1.7 - TIME * wind * 1.4).r;
	float fog = smoothstep(0.35, 0.85, a * 0.6 + b * 0.4) * density;
	fog = floor(fog * alpha_steps + 0.5) / alpha_steps;
	COLOR = vec4(fog_color.rgb, fog);
}
