class_name ChapterAtmosphere
extends RefCounted

## Borrowed MDS atmosphere for the four continuous chapters (the "only borrow
## atmosphere" option from docs/research/metroidvania-developer-system.md):
## each chapter gets weather sized to its whole 12000 px strip, and each boss
## arena gets an animated background behind the fight. The level structure,
## rooms and camera stay ours; MDS only draws.
##
## Specs use MDSEnvironment's weather syntax. Effects sit in front of the
## backdrop and behind actors (z between the art and the floor), so they read
## as air, not as a filter over the characters.

const WEATHER := {
	&"ink_archive": "fog(color=#1d3a44, density=0.32, ground=0.85, ground_height=0.3, drift=14), embers(kind=ash, density=0.22, hot_color=#9fd8cf, cool_color=#3b6b70, rise_speed=-28, drift=10)",
	&"breathing_ruins": "fog(color=#3b4a3a, density=0.4, ground=0.7, drift=30), fireflies(color=#b9cf7a, color_b=#e2f0a8, density=0.25, speed=0.5, blink=0.4)",
	&"lightless_sea": "fog(color=#1a2440, density=0.45, ground=1, ground_height=0.25, drift=-20), rain(density=0.25, angle=-8, fall_speed=900, mist=0.2, color=Color(0.55, 0.65, 0.85, 0.35))",
	&"smiling_theater": "embers(kind=ash, density=0.3, hot_color=#e8d2b0, cool_color=#7a5a4a, rise_speed=-20, drift=6), light_shafts(color=Color(0.85, 0.95, 0.9, 0.22), angle=6, spread=260, motes=0.5)",
}

const BOSS_BACKGROUND := {
	&"ink_archive": {"style": "void_pulse", "color_a": Color("#05080c"), "color_b": Color("#12303a"), "color_c": Color("#8fe8dc"), "color_d": Color("#2a5560")},
	&"breathing_ruins": {"style": "spore_drift", "color_a": Color("#080b08"), "color_b": Color("#1f2a1a"), "color_c": Color("#c8d68a"), "color_d": Color("#5a6b3a")},
	&"lightless_sea": {"style": "deep_water", "color_a": Color("#03050c"), "color_b": Color("#0c1630"), "color_c": Color("#7fa8d8"), "color_d": Color("#1c2c5a")},
	&"smiling_theater": {"style": "blood_moon", "color_a": Color("#0b0508"), "color_b": Color("#2a0d14"), "color_c": Color("#e0b06a"), "color_d": Color("#6a1a24")},
}

## Arena size behind a boss fight (local to the boss room's centre).
const BOSS_RECT := Rect2(-700, -460, 1400, 760)
const WEATHER_HEIGHT := 720.0
## Effects draw in front of the far art (-10..-8) and behind actors (0).
const WEATHER_Z := -3
const BACKGROUND_Z := -7


## Adds weather across a chapter level. Returns the weather root or null.
static func add_weather(level: Node2D, chapter_id: StringName, width: float) -> Node2D:
	var spec: String = WEATHER.get(chapter_id, "")
	if spec.is_empty():
		return null
	var weather := MDSEnvironment.build(spec, Rect2(0, 0, width, WEATHER_HEIGHT))
	if weather == null:
		return null
	weather.name = "ChapterWeather"
	for effect in MDSEnvironment.effects_in(weather):
		effect.z_index = WEATHER_Z
		effect.z_as_relative = false
		# Weather is visual only: it must never push or hurt the player.
		effect.affect_groups = PackedStringArray()
	level.add_child(weather)
	return weather


## Adds an animated background behind a boss room. Returns it or null.
static func add_boss_background(room: Node2D, chapter_id: StringName) -> Node2D:
	var look: Dictionary = BOSS_BACKGROUND.get(chapter_id, {})
	if look.is_empty():
		return null
	var background := MDSAnimatedBackground.new()
	background.name = "BossBackground"
	if background.use_style(String(look["style"])):
		background.apply_look(background.style)
	for key in ["color_a", "color_b", "color_c", "color_d"]:
		background.set(key, look[key])
	background.brightness = 0.85
	background.vignette = 0.5
	background.follow_camera = false
	background.fit_to(BOSS_RECT)
	background.z_index = BACKGROUND_Z
	background.z_as_relative = false
	background.affect_groups = PackedStringArray()
	# Dark until the fight: start() fades it in when the boss room locks.
	background.activation = MDSEnvironmentEffect.Activation.MANUAL
	background.fade_time = 1.6
	room.add_child(background)
	return background


## Fades in the boss room's animated background (call when the fight starts).
static func start_boss_background(room: Node2D) -> void:
	var background := room.get_node_or_null("BossBackground") as MDSEnvironmentEffect
	if background != null:
		background.start()
