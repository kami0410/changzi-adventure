shader_type canvas_item;

// Crisp pixel art at any scale, rotation or squash, plus the world's one light:
// a sickly-cyan rim from the upper right (docs/memory/decisions/2026-11-02-art-spec.md).
//
// Sampling: each screen pixel samples the nearest texel centre; only the single
// screen pixel straddling a texel edge blends, so texels never come out uneven
// and edges never shimmer. The CanvasItem using this must use linear filtering.
//
// Rim: an opaque texel whose neighbour toward the light is transparent is on the
// lit edge and is tinted. The light stays fixed in screen space: when the art is
// mirrored (negative x scale) the texture-space direction flips with it.

uniform vec4 rim_color : source_color = vec4(0.56, 0.91, 0.86, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = UV * texture_size;
	vec2 seam = floor(texel + 0.5);
	vec2 texels_per_pixel = max(fwidth(texel), vec2(0.0001));
	vec2 crisp = seam + clamp((texel - seam) / texels_per_pixel, -0.5, 0.5);
	vec4 color = texture(TEXTURE, crisp / texture_size);
	if (rim_strength > 0.0 && color.a > 0.5) {
		float facing = dFdx(UV.x) >= 0.0 ? 1.0 : -1.0;
		vec2 centre = floor(texel) + 0.5;
		vec2 toward_light = vec2(facing, -1.0);
		float lit = 1.0 - texture(TEXTURE, (centre + toward_light) / texture_size).a;
		float top = 1.0 - texture(TEXTURE, (centre + vec2(0.0, -1.0)) / texture_size).a;
		float edge = max(lit, top * 0.6);
		color.rgb = mix(color.rgb, rim_color.rgb, edge * rim_strength);
	}
	COLOR = color * COLOR;
}
