class_name DangerShape
extends RefCounted

## Colour-blind safe danger language: every warning reads by shape first,
## colour second. Attacks expose their shape as a constant for tests/UI.
enum { CIRCLE, CONE, LINE, GROUND }

static func color(shape: int) -> Color:
	match shape:
		CONE:
			return Color("f3a57a")
		LINE:
			return Color("f5ab7f")
		GROUND:
			return Color("eb8f96")
	return Color("d96a7a")

static func label(shape: int) -> String:
	match shape:
		CONE:
			return "扇形"
		LINE:
			return "直线"
		GROUND:
			return "地面矩形"
	return "圆形"
