extends RefCounted

## 1.0 art pack: the ten creature monsters have six drawn action strips each,
## CreatureArt picks the strip from the enemy's state, and the four new
## monsters are registered with their own behaviour scripts.

const IDS := [
	&"watcher_eye", &"ink_wisp", &"skull_lantern", &"abyss_jelly", &"name_snake", &"echo_bat",
	&"rust_bellman", &"drowned_scribe", &"spine_centipede", &"string_puppet",
]
const COUNTS := {&"idle": 4, &"move": 4, &"windup": 2, &"attack": 3, &"hurt": 1, &"death": 5}


func run(t: Callable) -> void:
	_test_manifest(t)
	_test_pick(t)
	_test_registration(t)
	_test_art_pack_files(t)


func _test_manifest(t: Callable) -> void:
	t.call(CreatureArt.manifest().size(), IDS.size(), "creature_manifest_count")
	for id in IDS:
		t.call(CreatureArt.has(id), true, "creature_has_%s" % id)
		var anims := CreatureArt.animations_for(id)
		for anim in COUNTS:
			t.call(anims.has(anim), true, "creature_%s_has_%s" % [id, anim])
			if not anims.has(anim):
				continue
			var frames: Array = anims[anim]["frames"]
			t.call(frames.size(), COUNTS[anim], "creature_%s_%s_frames" % [id, anim])
			var first := frames[0] as Texture2D
			t.call(first != null and first.get_width() > 0, true, "creature_%s_%s_texture" % [id, anim])
			# Every frame shares one opaque rect, so the feet never jump.
			t.call(PixelSprite.opaque_rect(frames[0]), PixelSprite.opaque_rect(frames[frames.size() - 1]),
				"creature_%s_%s_shared_rect" % [id, anim])
		t.call(CreatureArt.death_length(id) > 0.3, true, "creature_%s_death_length" % id)
	t.call(CreatureArt.display_scale(&"ink_wisp"), 2.0, "creature_wisp_scale")
	t.call(CreatureArt.display_scale(&"rust_bellman"), 1.0, "creature_default_scale")


func _test_pick(t: Callable) -> void:
	var enemy := Enemy.new()
	var art := CreatureArt.new()
	art.bind(enemy, &"rust_bellman", Sprite2D.new())
	t.call(art.pick(), &"idle", "creature_pick_idle")
	enemy.velocity = Vector2(80, 0)
	t.call(art.pick(), &"move", "creature_pick_move")
	enemy.velocity = Vector2.ZERO
	enemy.state = Enemy.STATE_ATTACK
	enemy._attack_windup_left = 0.2
	t.call(art.pick(), &"windup", "creature_pick_windup")
	enemy._attack_windup_left = 0.0
	t.call(art.pick(), &"attack", "creature_pick_attack")
	enemy.state = Enemy.STATE_IDLE
	art._on_damaged(3)
	t.call(art.pick(), &"hurt", "creature_pick_hurt")
	enemy.dead = true
	t.call(art.pick(), &"death", "creature_pick_death")
	art.free()
	enemy.free()
	# Subclasses with their own timers map them onto windup/attack.
	var charger := ChargerEnemy.new()
	charger.state = Enemy.STATE_ATTACK
	charger._charge_windup_left = 0.3
	t.call(charger.creature_phase(), &"windup", "creature_charger_windup")
	charger._charge_windup_left = 0.0
	t.call(charger.creature_phase(), &"attack", "creature_charger_attack")
	charger.free()
	var pulse := PulseEnemy.new()
	t.call(pulse.creature_phase(), &"windup", "creature_pulse_windup")
	pulse._pulsed = true
	t.call(pulse.creature_phase(), &"attack", "creature_pulse_attack")
	pulse.free()
	var wisp := KamikazeEnemy.new()
	t.call(wisp.creature_phase(), &"windup", "creature_kamikaze_fuse")
	wisp.free()


func _test_registration(t: Callable) -> void:
	var game_script := load("res://scripts/game.gd") as GDScript
	var scenes: Dictionary = game_script.get_script_constant_map()["ENEMY_SCENES"]
	var rosters: Array = game_script.get_script_constant_map()["CHAPTER_CREATURES"]
	var expected := {
		&"rust_bellman": "BellEnemy", &"drowned_scribe": "PageThrowerEnemy",
		&"spine_centipede": "ChargerEnemy", &"string_puppet": "PuppetEnemy",
	}
	for id in expected:
		t.call(scenes.has(id), true, "creature_scene_registered_%s" % id)
		if not scenes.has(id):
			continue
		var enemy := (scenes[id] as PackedScene).instantiate() as Enemy
		t.call(enemy != null, true, "creature_scene_is_enemy_%s" % id)
		if enemy == null:
			continue
		t.call((enemy.get_script() as Script).get_global_name(), StringName(expected[id]), "creature_behavior_%s" % id)
		t.call(enemy.data != null and enemy.data.id == id, true, "creature_data_%s" % id)
		enemy.free()
	# Each chapter features its own new monster first.
	t.call(rosters[0][0], &"spine_centipede", "creature_roster_ch1")
	t.call(rosters[1][0], &"rust_bellman", "creature_roster_ch2")
	t.call(rosters[2][0], &"drowned_scribe", "creature_roster_ch3")
	t.call(rosters[3][0], &"string_puppet", "creature_roster_ch4")
	for chapter in rosters.size():
		for id in rosters[chapter]:
			t.call(CreatureArt.has(id), true, "creature_roster_has_art_%d_%s" % [chapter, id])


func _test_art_pack_files(t: Callable) -> void:
	for name in ["roll_0", "roll_7", "airdash_0", "airdash_2", "finisher_0", "finisher_4"]:
		t.call(ResourceLoader.exists("res://assets/sprites/player/frames/%s.png" % name), true, "art_player_%s" % name)
	t.call(Player.ROLL_FRAMES.size(), 8, "art_player_roll_frames")
	t.call(Player.AIRDASH_FRAMES.size(), 3, "art_player_airdash_frames")
	t.call(Player.FINISHER_FRAMES.size(), 5, "art_player_finisher_frames")
	for chapter in [2, 3, 4]:
		for theme in RoomDressing.REGION_THEMES.values():
			var path := "res://assets/backgrounds/layers/ch%d_mid_%s.png" % [chapter, theme]
			var region_chapter_themes := []
			for region in RoomDressing.REGION_THEMES:
				if String(region).begins_with("ch%d_" % chapter):
					region_chapter_themes.append(RoomDressing.REGION_THEMES[region])
			if theme in region_chapter_themes:
				t.call(ResourceLoader.exists(path), true, "art_mid_layer_%d_%s" % [chapter, theme])
	t.call(RoomDressing.REGION_THEMES.size(), 27, "art_region_theme_count")
	for name in ["lift_car", "lift_rail", "lift_panel_idle", "lift_panel_active"]:
		t.call(ResourceLoader.exists("res://assets/sprites/props/%s.png" % name), true, "art_lift_%s" % name)
	for modifier in [EncounterVariation.ELITE, EncounterVariation.SWIFT, EncounterVariation.HORDE]:
		t.call(EncounterVariation.modifier_icon(modifier) != null, true, "art_affix_icon_%s" % modifier)
	t.call(EncounterVariation.modifier_icon(EncounterVariation.NONE), null, "art_affix_icon_none")
	t.call(ResourceLoader.exists(TitleScreen.KEY_ART), true, "art_title_key_art")
	var ayan := load("res://assets/sprites/npcs/ayan.png") as Texture2D
	t.call(ayan != null and ayan.get_width() == 128, true, "art_ayan_forge_god_sprite")
	for chapter in range(1, 5):
		var props := load("res://assets/sprites/props/dressing_ch%d.png" % chapter) as Texture2D
		t.call(props != null and props.get_width() == 512, true, "art_props_ch%d_eight_slots" % chapter)
