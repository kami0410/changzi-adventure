shader_type canvas_item;

// Low health: the edge of the screen bleeds. Nothing is drawn in the middle,
// so the fight stays readable; the HUD fades the whole rect in and out.

uniform vec4 tint : source_color = vec4(0.72, 0.10, 0.10, 1.0);
uniform float reach : hint_range(0.1, 1.0) = 0.3;

void fragment() {
	vec2 from_centre = abs(UV - 0.5) * 2.0;
	float edge = max(from_centre.x, from_centre.y);
	float amount = smoothstep(1.0 - reach, 1.0, edge);
	COLOR = vec4(tint.rgb, amount * amount * 0.4 * COLOR.a);
}
