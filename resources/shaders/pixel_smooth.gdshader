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
// 1.1 readability: actors in a fight get the whole silhouette traced (edge
// texels only, so the art keeps its size), so a dark body never sinks into a
// dark room. 0 keeps the single lit rim (NPCs, props).
uniform vec4 outline_color : source_color = vec4(0.56, 0.91, 0.86, 1.0);
uniform float outline_strength : hint_range(0.0, 1.0) = 0.0;
// Edge width in screen pixels.
uniform float edge_pixels = 1.0;

// In a canvas_item fragment COLOR already holds the vertex colour multiplied
// by the texture sample, so "sample * COLOR" would square the art (every actor
// came out far darker than painted). The modulate is carried separately.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = UV * texture_size;
	vec2 seam = floor(texel + 0.5);
	vec2 texels_per_pixel = max(fwidth(texel), vec2(0.0001));
	vec2 crisp = seam + clamp((texel - seam) / texels_per_pixel, -0.5, 0.5);
	vec4 color = texture(TEXTURE, crisp / texture_size);
	if ((rim_strength > 0.0 || outline_strength > 0.0) && color.a > 0.5) {
		float facing = dFdx(UV.x) >= 0.0 ? 1.0 : -1.0;
		vec2 centre = floor(texel) + 0.5;
		// Art drawn smaller than its texels (high-resolution frames) still gets
		// an edge about one screen pixel wide.
		float reach = max(1.0, max(texels_per_pixel.x, texels_per_pixel.y) * edge_pixels);
		vec2 toward_light = vec2(facing, -1.0) * reach;
		float lit = 1.0 - texture(TEXTURE, (centre + toward_light) / texture_size).a;
		float top = 1.0 - texture(TEXTURE, (centre + vec2(0.0, -reach)) / texture_size).a;
		if (outline_strength > 0.0) {
			float open_side = 1.0 - min(
				min(texture(TEXTURE, (centre + vec2(-reach, 0.0)) / texture_size).a,
					texture(TEXTURE, (centre + vec2(reach, 0.0)) / texture_size).a),
				texture(TEXTURE, (centre + vec2(0.0, reach)) / texture_size).a);
			color.rgb = mix(color.rgb, outline_color.rgb, max(open_side, top) * outline_strength);
		}
		float edge = max(lit, top * 0.6);
		color.rgb = mix(color.rgb, rim_color.rgb, edge * rim_strength);
	}
	COLOR = color * modulate;
}
