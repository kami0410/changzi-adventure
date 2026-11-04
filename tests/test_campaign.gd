extends RefCounted

func run(t: Callable) -> void:
	_test_chapters(t)
	_test_endings(t)
	_test_profile_progress(t)
	_test_story_overlay(t)
	_test_stele(t)

func _test_chapters(t: Callable) -> void:
	t.call(CampaignData.chapter_count(), 4, "campaign_four_chapters")
	var boss_names: Array[String] = []
	for index in CampaignData.chapter_count():
		var chapter := CampaignData.chapter(index)
		t.call(chapter["rooms"].size(), 6, "chapter_%d_has_six_combat_encounters" % index)
		t.call(String(chapter["boss_name"]) != "", true, "chapter_%d_has_boss" % index)
		t.call(chapter["intro"].size() >= 2, true, "chapter_%d_has_intro" % index)
		t.call(chapter["outro"].size() >= 1, true, "chapter_%d_has_outro" % index)
		t.call(chapter["choice"]["options"].size(), 2, "chapter_%d_has_meaningful_choice" % index)
		boss_names.append(String(chapter["boss_name"]))
	var unique_bosses: Dictionary = {}
	for boss_name in boss_names:
		unique_bosses[boss_name] = true
	t.call(unique_bosses.size(), 4, "each_chapter_has_its_own_boss")
	t.call(CampaignData.chapter(-5)["number"], 1, "chapter_index_is_clamped")
	t.call(CampaignData.chapter(99)["number"], 4, "chapter_index_clamps_high")

func _test_endings(t: Callable) -> void:
	t.call(CampaignData.ending_for(false, 0, 3, false)["id"], &"interrupted", "loss_ending")
	t.call(CampaignData.ending_for(true, 10, 3, true)["id"], &"burned", "burn_choice_overrides_mercy")
	t.call(CampaignData.ending_for(true, 70, 3, false)["id"], &"abyss", "high_corruption_ending")
	t.call(CampaignData.ending_for(true, 10, 2, false)["id"], &"restored", "mercy_restores_archive")
	t.call(CampaignData.ending_for(true, 10, 0, false)["id"], &"unfinished", "neutral_ending")

func _test_profile_progress(t: Callable) -> void:
	var path := "user://test_campaign_profile.cfg"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var profile := Profile.new()
	profile.record_ending(&"restored")
	profile.record_ending(&"restored")
	profile.record_ending(&"burned")
	profile.runs_completed = 2
	profile.records_found = 3
	profile.save_profile(path)
	var loaded := Profile.new()
	t.call(loaded.load_profile(path), true, "campaign_profile_loads")
	t.call(loaded.endings.size(), 2, "endings_are_unique")
	t.call(loaded.runs_completed, 2, "runs_completed_persists")
	t.call(loaded.records_found, 3, "records_found_persists")
	profile.free()
	loaded.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)

func _test_story_overlay(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var overlay := StoryOverlay.new()
	tree.root.add_child(overlay)
	overlay.open_story("第一章", "被撕走的名册", ["第一行", "第二行"])
	t.call(overlay.is_open(), true, "story_overlay_opens")
	t.call(tree.paused, true, "story_overlay_pauses")
	overlay.close()
	t.call(overlay.is_open(), false, "story_overlay_closes")
	t.call(tree.paused, false, "story_overlay_restores_pause")
	var picked := [-1]
	overlay.choice_made.connect(func(index: int): picked[0] = index)
	overlay.open_choice("选择", "留下哪一页？", "选择会改变结局。", [{"label": "保存", "note": "仁慈"}, {"label": "焚毁", "note": "自由"}])
	# Option text is assigned after the button enters the tree (see
	# StoryOverlay.open_choice); both lines must still be present immediately.
	t.call(overlay._options.get_child_count(), 2, "story_choice_option_count")
	t.call(overlay._options.get_child(0).text, "保存\n仁慈", "story_choice_first_text")
	t.call(overlay._options.get_child(1).text, "焚毁\n自由", "story_choice_second_text")
	overlay.choose(1)
	t.call(picked[0], 1, "story_overlay_emits_choice")
	t.call(overlay.is_open(), false, "story_overlay_closes_after_choice")
	tree.paused = false
	tree.root.remove_child(overlay)
	overlay.free()

func _test_stele(t: Callable) -> void:
	var stele := preload("res://scenes/levels/memory_stele.tscn").instantiate() as MemoryStele
	t.call(stele.can_claim(), true, "stele_starts_unclaimed")
	var reward := stele.claim()
	t.call(reward.is_empty(), false, "stele_grants_reward")
	t.call(stele.is_claimed, true, "stele_marks_claimed")
	t.call(stele.claim().is_empty(), true, "stele_cannot_be_farmed")
	stele.free()
