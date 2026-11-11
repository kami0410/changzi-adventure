shader_type canvas_item;

// Depth haze (1.1): one veil between the painted backdrop and the play plane.
// It darkens and cools everything behind the actors so silhouettes and
// platforms read, opens a soft pool of light around the player, and closes
// the frame with a vignette. No screen read: a single blended quad.

uniform vec4 haze_color : source_color = vec4(0.024, 0.07, 0.1, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.34;
// Player position in this item's local pixels.
uniform vec2 focus = vec2(0.0, 0.0);
uniform float focus_radius = 260.0;
uniform float focus_clear : hint_range(0.0, 1.0) = 0.6;
// The pool is also a faint backlight, so a dark figure stands against it.
uniform vec4 pool_color : source_color = vec4(0.42, 0.72, 0.72, 1.0);
uniform float pool_light : hint_range(0.0, 1.0) = 0.16;
// Half the visible size in local pixels, for the vignette.
uniform vec2 view_half = vec2(640.0, 360.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.42;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	float pool = 1.0 - smoothstep(focus_radius * 0.25, focus_radius, distance(local, focus));
	float veil = density * (1.0 - pool * focus_clear);
	vec2 edge = abs(local) / max(view_half, vec2(1.0));
	float rim = smoothstep(0.55, 1.15, length(edge * vec2(0.9, 1.0)));
	float alpha = clamp(veil + rim * vignette, 0.0, 0.92);
	float glow = pool * pool * pool_light;
	vec3 tone = mix(haze_color.rgb, pool_color.rgb, glow / max(alpha + glow, 0.001));
	COLOR = vec4(tone, clamp(alpha + glow, 0.0, 0.92));
}
