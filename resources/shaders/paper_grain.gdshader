// Paper grain for archive-page panels (1.0). A compact take on the ideas in
// Paper Shaders' paper-texture (Apache-2.0, asset library entry 0012): fine
// grain, curly fibres and two soft fold lines, drawn as a light overlay under
// the panel's contents. Written from scratch; no upstream code is copied.
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shadow : source_color = vec4(0.05, 0.04, 0.03, 1.0);
uniform vec4 light : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float seed = 7.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV / max(TEXTURE_PIXEL_SIZE, vec2(1e-4));
	vec2 size = 1.0 / max(TEXTURE_PIXEL_SIZE, vec2(1e-4));
	// Fine grain, two pixels wide so it survives the pixel-art upscale.
	float grain = hash(floor(px / 2.0)) - 0.5;
	// Fibres: noise stretched along x, then folded into thin curly threads.
	float fibre = 1.0 - smoothstep(0.0, 0.06, abs(fbm(px * vec2(0.012, 0.05)) - 0.5));
	// Two soft fold lines, a third and two thirds across.
	float fold_x = 1.0 - smoothstep(0.0, 6.0, abs(px.x - size.x * 0.33));
	float fold_y = 1.0 - smoothstep(0.0, 6.0, abs(px.y - size.y * 0.62));
	// Age: blotches darker toward the edges.
	vec2 c = UV - 0.5;
	float age = smoothstep(0.25, 0.75, length(c * vec2(1.0, 1.3))) * (0.6 + 0.4 * fbm(px * 0.01));
	float dark = clamp(grain * 0.5 + age * 0.9 + fold_x * 0.25 + fold_y * 0.2, 0.0, 1.0);
	float bright = fibre * 0.5;
	vec4 out_color = mix(vec4(shadow.rgb, dark), vec4(light.rgb, bright), step(dark, bright));
	out_color.a *= strength * 0.35;
	COLOR = out_color;
}
