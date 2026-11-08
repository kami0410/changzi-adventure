extends RefCounted

## Chapter 2/3/4 enemy art audit (passes 38, 49, 62 and 78). Only enemies with a
## dedicated sprite in the repo may be wired into ENEMY_ART; the rest keep the
## Chapter 1 fallback until art exists. This file locks the audit result so
## adding a sprite without wiring it — or wiring a Chapter 1 painting under a
## Chapter 2/3/4 id — fails the suite instead of silently regressing enemy art.

const GAME_SCRIPT_PATH := "res://scripts/game.gd"
const CH1_ENEMIES: Array[StringName] = [
	&"ink_hound", &"scribe_bug", &"blank_man", &"hanging_scribe",
	&"echo_enemy", &"typo_beast", &"ink_bomber", &"page_swarm",
]
const CH2_ENEMIES: Array[StringName] = [
	&"breath_hound", &"lung_moth", &"rust_whisperer", &"choir_summoner",
	&"collapse_husk",
]
## Pass 78 wired the last four Chapter 2 enemies after the user supplied the
## paintings (breath_hound in one file, the other three in a triptych). Every
## Chapter 2 enemy now owns its PNG, so the missing list is empty.
const CH2_WIRED: Array[StringName] = [
	&"breath_hound", &"lung_moth", &"rust_whisperer", &"choir_summoner",
	&"collapse_husk",
]
const CH2_MISSING: Array[StringName] = []
## Chapter 3 audit (pass 49, gap closed in pass 78): the six waves of
## ROOM_WAVES[2] reference these eight enemies, taken from the waves that
## really spawn (not the plan file). All eight own a dedicated sprite now.
const CH3_ENEMIES: Array[StringName] = [
	&"mirror_sniper", &"hanging_scribe", &"echo_enemy", &"typo_beast",
	&"page_swarm", &"rust_whisperer", &"lung_moth", &"collapse_husk",
]
const CH3_WIRED: Array[StringName] = [
	&"mirror_sniper", &"hanging_scribe", &"echo_enemy", &"typo_beast",
	&"page_swarm", &"rust_whisperer", &"lung_moth", &"collapse_husk",
]
const CH3_MISSING: Array[StringName] = []
## `echo_enemy` is the spawn/scene id; its data resource keeps the older
## `amnesiac_echo` name. Every other enemy uses `<id>.tres`.
const CH3_DATA_ALIASES: Dictionary = {&"echo_enemy": &"amnesiac_echo"}
## Chapter 4 audit (pass 62): the six waves of ROOM_WAVES[3] reference these
## seven ids. All seven own a dedicated PNG and render at white, so the missing
## list is empty. `mask_enemy` and `seat_husk` are art variants: they reuse the
## hanging-scribe / collapse-husk scenes and data resources, but each ships its
## own painting (not a fallback). The legacy chapter-4 room groups additionally
## field `echo_enemy`, which already owns chapter-1 art and is locked by the
## CH1/CH3 lists; ROOM_WAVES[3] itself does not name it.
const CH4_ENEMIES: Array[StringName] = [
	&"mask_enemy", &"seat_husk", &"choir_summoner", &"page_swarm",
	&"mirror_sniper", &"typo_beast", &"ink_bomber",
]
const CH4_WIRED: Array[StringName] = [
	&"mask_enemy", &"seat_husk", &"choir_summoner", &"page_swarm",
	&"mirror_sniper", &"typo_beast", &"ink_bomber",
]
const CH4_MISSING: Array[StringName] = []
## Variant id -> base enemy whose scene and data resource it reuses.
const CH4_ART_VARIANTS: Dictionary = {
	&"mask_enemy": &"hanging_scribe", &"seat_husk": &"collapse_husk",
}


func run(t: Callable) -> void:
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "enemy_art_game_script_loads")
	if game_script == null:
		return
	var constants := game_script.get_script_constant_map()
	var art: Dictionary = constants.get("ENEMY_ART", {})
	var fallback: Dictionary = constants.get("ENEMY_ART_FALLBACK", {})
	var scenes: Dictionary = constants.get("ENEMY_SCENES", {})
	var tint: Color = constants.get("ENEMY_FALLBACK_TINT", Color.WHITE)
	t.call(not art.is_empty(), true, "enemy_art_table_present")
	t.call(constants.has("ENEMY_ART_FALLBACK"), true, "enemy_art_fallback_table_present")
	# Pass 78 closed the last art gap: every enemy that spawns in Chapters 1–4
	# owns its painting, so nothing may sit on the fallback path.
	t.call(fallback.is_empty(), true, "enemy_art_no_fallback_gaps")
	t.call(tint != Color.WHITE, true, "enemy_fallback_tint_marks_reused_art")

	# Chapter 1 art stays exactly where it was: every original enemy owns its
	# own painting and never enters the fallback table.
	for id in CH1_ENEMIES:
		t.call(art.has(id), true, "ch1_enemy_%s_keeps_own_art" % id)
		t.call(fallback.has(id), false, "ch1_enemy_%s_not_on_fallback" % id)
		_assert_own_sprite(t, art, id, "ch1")

	for id in CH2_ENEMIES:
		t.call(scenes.has(id), true, "ch2_enemy_%s_has_scene" % id)
		t.call(art.has(id) or fallback.has(id), true, "ch2_enemy_%s_resolves_art" % id)
		t.call(not (art.has(id) and fallback.has(id)), true,
			"ch2_enemy_%s_has_single_art_source" % id)
		t.call(ResourceLoader.exists("res://resources/enemies/%s.tres" % id), true,
			"ch2_enemy_%s_has_data" % id)

	for id in CH2_WIRED:
		t.call(art.has(id), true, "ch2_enemy_%s_wired_to_art" % id)
		t.call(fallback.has(id), false, "ch2_enemy_%s_not_on_fallback" % id)
		_assert_own_sprite(t, art, id, "ch2")
		# "No longer falls back" also means no green fallback tint.
		t.call(_art_tint(id, fallback, tint), Color.WHITE,
			"ch2_enemy_%s_no_fallback_tint" % id)

	for id in CH2_MISSING:
		t.call(fallback.has(id), true, "ch2_enemy_%s_keeps_fallback" % id)
		t.call(art.has(id), false, "ch2_enemy_%s_not_falsely_wired" % id)
		var source: StringName = fallback[id]
		t.call(art.has(source), true, "ch2_enemy_%s_fallback_source_exists" % id)
		t.call(not CH2_ENEMIES.has(source), true,
			"ch2_enemy_%s_fallback_is_chapter_1_art" % id)
		t.call(_art_tint(id, fallback, tint), tint,
			"ch2_enemy_%s_uses_fallback_tint" % id)
		# No dedicated sprite at the standard path yet. If art is added later
		# this fails until the enemy is wired into ENEMY_ART and moved out of
		# CH2_MISSING.
		t.call(FileAccess.file_exists("res://assets/sprites/enemies/%s.png" % id), false,
			"ch2_enemy_%s_has_no_dedicated_sprite_yet" % id)
	# The Chapter 2 art gap is closed (pass 78); keep the list empty so a future
	# gap has to be declared and audited instead of silently reappearing.
	t.call(CH2_MISSING.is_empty(), true, "ch2_no_missing_enemy_art")

	# --- Chapter 3: same audit against the waves that really spawn.
	for id in CH3_ENEMIES:
		t.call(scenes.has(id), true, "ch3_enemy_%s_has_scene" % id)
		t.call(art.has(id) or fallback.has(id), true, "ch3_enemy_%s_resolves_art" % id)
		t.call(not (art.has(id) and fallback.has(id)), true,
			"ch3_enemy_%s_has_single_art_source" % id)
		var data_id: StringName = CH3_DATA_ALIASES.get(id, id)
		t.call(ResourceLoader.exists("res://resources/enemies/%s.tres" % data_id), true,
			"ch3_enemy_%s_has_data" % id)

	for id in CH3_WIRED:
		t.call(art.has(id), true, "ch3_enemy_%s_wired_to_art" % id)
		t.call(fallback.has(id), false, "ch3_enemy_%s_not_on_fallback" % id)
		_assert_own_sprite(t, art, id, "ch3")
		t.call(_art_tint(id, fallback, tint), Color.WHITE,
			"ch3_enemy_%s_no_fallback_tint" % id)

	for id in CH3_MISSING:
		t.call(fallback.has(id), true, "ch3_enemy_%s_keeps_fallback" % id)
		t.call(art.has(id), false, "ch3_enemy_%s_not_falsely_wired" % id)
		var source: StringName = fallback[id]
		t.call(art.has(source), true, "ch3_enemy_%s_fallback_source_exists" % id)
		t.call(CH1_ENEMIES.has(source), true,
			"ch3_enemy_%s_fallback_is_chapter_1_art" % id)
		t.call(_art_tint(id, fallback, tint), tint,
			"ch3_enemy_%s_uses_fallback_tint" % id)
		# Missing art stays missing on purpose this pass; adding a sprite later
		# fails here until it is wired into ENEMY_ART and moved out of
		# CH3_MISSING (no silent half-wiring).
		t.call(FileAccess.file_exists("res://assets/sprites/enemies/%s.png" % id), false,
			"ch3_enemy_%s_has_no_dedicated_sprite_yet" % id)
	# The three Chapter 3 borrows were wired in pass 78 along with Chapter 2.
	t.call(CH3_MISSING.is_empty(), true, "ch3_no_missing_enemy_art")

	# The audit set is derived from ROOM_WAVES[2] (chapter 3's six real waves),
	# so a wave edit that introduces an unaudited enemy fails here.
	var waves: Array = constants.get("ROOM_WAVES", [])
	t.call(waves.size() >= 3, true, "enemy_art_room_waves_present")
	if waves.size() >= 3:
		var wave_ids: Dictionary = {}
		for wave in waves[2]:
			for id in wave:
				wave_ids[id] = true
		t.call(wave_ids.size(), CH3_ENEMIES.size(), "ch3_wave_enemy_count")
		for id in CH3_ENEMIES:
			t.call(wave_ids.has(id), true, "ch3_wave_uses_%s" % id)
		for id in wave_ids:
			t.call(CH3_ENEMIES.has(id), true, "ch3_wave_enemy_%s_audited" % id)
			t.call(art.has(id) or fallback.has(id), true,
				"ch3_wave_enemy_%s_resolves_art" % id)

	# --- Chapter 4: same audit against ROOM_WAVES[3], the six waves the plan
	# reuses verbatim. The two art variants keep their base scene/data but must
	# paint themselves, so they are neither missing art nor a reused fallback.
	for id in CH4_ENEMIES:
		t.call(scenes.has(id), true, "ch4_enemy_%s_has_scene" % id)
		t.call(art.has(id) or fallback.has(id), true, "ch4_enemy_%s_resolves_art" % id)
		t.call(not (art.has(id) and fallback.has(id)), true,
			"ch4_enemy_%s_has_single_art_source" % id)
		var data_id: StringName = CH4_ART_VARIANTS.get(id, id)
		t.call(ResourceLoader.exists("res://resources/enemies/%s.tres" % data_id), true,
			"ch4_enemy_%s_has_data" % id)
		if CH4_ART_VARIANTS.has(id):
			var base: StringName = CH4_ART_VARIANTS[id]
			if scenes.has(id) and scenes.has(base):
				t.call((scenes[id] as PackedScene).resource_path,
					(scenes[base] as PackedScene).resource_path,
					"ch4_enemy_%s_reuses_base_scene" % id)
			# Compare against what the base enemy would paint: hanging_scribe
			# owns art, collapse_husk borrows blank_man through the fallback.
			var base_art: StringName = fallback.get(base, base)
			t.call(art.has(id) and art.has(base_art) and art[id] != art[base_art], true,
				"ch4_enemy_%s_has_own_painting" % id)

	for id in CH4_WIRED:
		t.call(art.has(id), true, "ch4_enemy_%s_wired_to_art" % id)
		t.call(fallback.has(id), false, "ch4_enemy_%s_not_on_fallback" % id)
		_assert_own_sprite(t, art, id, "ch4")
		t.call(_art_tint(id, fallback, tint), Color.WHITE,
			"ch4_enemy_%s_no_fallback_tint" % id)

	# Chapter 4 is the first chapter with no art gap: every enemy it spawns has
	# a dedicated painting. Nothing new is drawn here; the list just stays empty.
	t.call(CH4_MISSING.is_empty(), true, "ch4_no_missing_enemy_art")

	# Derive the audit set from ROOM_WAVES[3] too, so a wave edit that swaps in
	# an unaudited enemy fails instead of shipping a silent fallback.
	t.call(waves.size() >= 4, true, "enemy_art_chapter_4_waves_present")
	if waves.size() >= 4:
		var ch4_wave_ids: Dictionary = {}
		for wave in waves[3]:
			for id in wave:
				ch4_wave_ids[id] = true
		t.call(ch4_wave_ids.size(), CH4_ENEMIES.size(), "ch4_wave_enemy_count")
		for id in CH4_ENEMIES:
			t.call(ch4_wave_ids.has(id), true, "ch4_wave_uses_%s" % id)
		for id in ch4_wave_ids:
			t.call(CH4_ENEMIES.has(id), true, "ch4_wave_enemy_%s_audited" % id)
			t.call(art.has(id) or fallback.has(id), true,
				"ch4_wave_enemy_%s_resolves_art" % id)


## Mirrors the tint rule in Game._spawn_group(): fallback art is tinted, a
## dedicated sprite renders at white.
func _art_tint(id: StringName, fallback: Dictionary, tint: Color) -> Color:
	return tint if fallback.has(id) else Color.WHITE


func _assert_own_sprite(t: Callable, art: Dictionary, id: StringName, prefix: String) -> void:
	var texture := art[id] as Texture2D
	t.call(texture != null, true, "%s_enemy_%s_has_texture" % [prefix, id])
	if texture == null:
		return
	t.call(texture.resource_path, "res://assets/sprites/enemies/%s.png" % id,
		"%s_enemy_%s_uses_own_sprite" % [prefix, id])
	t.call(FileAccess.file_exists(texture.resource_path), true,
		"%s_enemy_%s_sprite_file_exists" % [prefix, id])
	# Every enemy painting ships on the same 96x96 canvas (art spec §规格).
	t.call(texture.get_size(), Vector2(96.0, 96.0),
		"%s_enemy_%s_sprite_is_96x96" % [prefix, id])
	var image := texture.get_image()
	t.call(image != null and image.get_width() > 0 and image.get_height() > 0, true,
		"%s_enemy_%s_sprite_is_valid_png" % [prefix, id])
