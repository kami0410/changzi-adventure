// Room transition as spreading ink (1.0). Ported from gl-transitions
// "InkBleed" by gre (MIT, asset library entry 0017): the incoming ink blooms
// from a few drops with curling, wispy edges and a darker rim.
//
// Applied to the MDS fade rect: its colour alpha is the progress. Fading out
// (0 -> 1) the ink covers the old room; fading in (1 -> 0) it recedes from
// the new one. At 1 the frame is fully covered, at 0 fully clear, so the MDS
// timing and every caller waiting for the fade are unchanged.
shader_type canvas_item;

uniform vec4 ink : source_color = vec4(0.027, 0.035, 0.05, 1.0);
uniform vec4 rim_color : source_color = vec4(0.56, 0.91, 0.86, 1.0);
uniform float drops = 4.0;
uniform float tendrils = 0.7;
uniform float seed = 3.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
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
		v += a * vnoise(p);
		p = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6)) * p + 7.3;
		a *= 0.5;
	}
	return v / 0.9375;
}

void fragment() {
	float p = clamp(COLOR.a, 0.0, 1.0);
	if (p <= 0.0005) {
		COLOR = vec4(0.0);
	} else if (p >= 0.9995) {
		COLOR = ink;
	} else {
		float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		vec2 uv = SCREEN_UV;
		vec2 q = vec2(uv.x * ratio, uv.y);
		vec2 o = vec2(seed * 3.1, seed * 1.7);
		vec2 sq = q * 2.2 + o;
		vec2 w1 = vec2(fbm(sq + vec2(0.0, 0.6 * p)), fbm(sq + vec2(5.2, 1.3) - vec2(0.5 * p, 0.0)));
		vec2 w2 = vec2(fbm(sq + 3.0 * w1 + vec2(1.7, 9.2)), fbm(sq + 3.0 * w1 + vec2(8.3, 2.8)));
		float swirl = fbm(sq * 0.8 + 2.5 * w2) - 0.5;
		vec2 flow = w2 - 0.5;
		float amp = 0.05 + 0.35 * tendrils;
		float n = clamp(floor(drops + 0.5), 1.0, 8.0);
		float rim_w = 0.1;
		float feather = 0.05;
		float margin = 1.2 * amp + rim_w + 0.08;
		float f = -1e3;
		float fs = -1e3;
		for (int i = 0; i < 8; i++) {
			float fi = float(i);
			if (fi < n) {
				vec2 hs = vec2(fi * 7.13 + seed, fi * 3.71 - seed);
				vec2 c = vec2(mix(0.15, 0.85, hash(hs)) * ratio, mix(0.15, 0.85, hash(hs + 19.7)));
				float start = 0.2 * fi / n;
				float s = clamp((p - start) / (1.0 - start), 0.0, 1.0);
				vec2 m = max(c, vec2(ratio, 1.0) - c);
				float far = length(m) + margin;
				float s3 = s * s * s;
				float r = (far + 0.02) * s * (0.35 + 0.65 * s3 * s3) - 0.02;
				float reach = amp * min(1.0, max(r, 0.0) * 5.0);
				float g = r - length(q - c + 1.3 * reach * flow) + reach * 0.9 * swirl;
				f = max(f, g);
				fs = max(fs, g - 0.15 * (1.0 - min(1.0, s * 12.0)));
			}
		}
		float inside = smoothstep(-0.003, 0.003, f);
		float wisp = 1.0 - smoothstep(0.0, 0.08, abs(fbm(sq * 2.0 + 5.0 * w2) - 0.5));
		float soft = smoothstep(-feather, 0.0, fs) * (0.35 + 0.4 * wisp);
		float haze = 0.35 * wisp * (1.0 - smoothstep(0.0, 0.1, -fs));
		float cover = max(inside, max(soft, haze));
		// A thin verdigris glint rides the front of the ink.
		float edge = (1.0 - smoothstep(0.0, rim_w, f)) * inside;
		vec3 color = mix(ink.rgb, rim_color.rgb, 0.35 * edge * (1.0 - p));
		COLOR = vec4(color, cover);
	}
}
