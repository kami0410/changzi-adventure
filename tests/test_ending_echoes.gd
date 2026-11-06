extends RefCounted

## 叙事审计 E3：五结局 × 五 NPC 余味、每结局的「笑面史官 / 最后一页」回收、
## 结束屏与画廊的展示读取，以及结局判定 / 存档格式不变的回归锁。
##
## 余味只存在于 EndingEchoData，不写进 Profile；未解锁结局在画廊里仍是原来的
## 占位文案，不泄露任何余味。

const EXPECTED_IDS: Array[StringName] = [
	&"restored", &"burned", &"abyss", &"unfinished", &"interrupted",
]
const EXPECTED_NPCS: Array[StringName] = [
	&"luchen", &"ayan", &"guru", &"wenjin", &"baiyu",
]
const EXPECTED_TITLES: Dictionary = {
	&"restored": "复原",
	&"burned": "焚毁档案",
	&"abyss": "深渊回响",
	&"unfinished": "未完的注脚",
	&"interrupted": "记录中断",
}
const EXPECTED_BODIES: Dictionary = {
	&"restored": "三页名册重新对齐。失踪者的名字回到纸上，\n昌子的名字也终于有了下一行。最后的档案馆亮起了灯。",
	&"burned": "名册在舞台上烧了三天三夜。世界失去了历史，\n但从此没有人能用过去命令任何人。昌子第一次听见海的声音。",
	&"abyss": "你写下最后一页时，墨自己动了起来。\n昌子成为污染的一部分，也成为唯一还记得世界的人。档案继续生长。",
	&"unfinished": "名册补全了，却仍有一页空白。昌子合上档案，\n知道下一次潮水会带来新的名字——而昌子会记得回来。",
	&"interrupted": "污染吞没了这一页。昌子的名字从档案中淡去，\n但记忆碎片已经被写下——下一次，你会记得更多。",
}
const FORBIDDEN_MARKERS: Array[String] = ["TODO", "TBD", "%s", "占位", "待补", "待定", "？？？"]
const ENDING_PUNCTUATION := "。！？…"


func run(t: Callable) -> void:
	_test_coverage(t)
	_test_text_quality(t)
	_test_thematic_mapping(t)
	_test_ending_screen(t)
	_test_gallery(t)
	_test_save_format(t)
	_test_ending_regression(t)


func _test_coverage(t: Callable) -> void:
	t.call(EndingEchoData.ending_ids(), EXPECTED_IDS, "echo_ending_order")
	t.call(EndingEchoData.ending_ids().size(), CampaignData.ending_count(),
		"echo_ending_count_matches_campaign")
	for index in CampaignData.ending_count():
		var entry := CampaignData.ending(index)
		var ending_id := StringName(entry.get("id", &""))
		t.call(EndingEchoData.has_ending(ending_id), true,
			"echo_has_%s" % String(ending_id))
		t.call(EndingEchoData.coda_for(ending_id).is_empty(), false,
			"echo_coda_present_%s" % String(ending_id))
		var echoes := EndingEchoData.echoes_for(ending_id)
		t.call(echoes.size(), EXPECTED_NPCS.size(),
			"echo_five_npcs_%s" % String(ending_id))
		for npc_id in EXPECTED_NPCS:
			t.call(echoes.has(npc_id), true,
				"echo_%s_has_%s" % [String(ending_id), String(npc_id)])
			t.call(EndingEchoData.echo_for(ending_id, npc_id).is_empty(), false,
				"echo_%s_%s_nonempty" % [String(ending_id), String(npc_id)])
		# Returning a copy keeps callers from editing the authored table.
		echoes.clear()
		t.call(EndingEchoData.echoes_for(ending_id).size(), EXPECTED_NPCS.size(),
			"echo_copy_%s" % String(ending_id))


func _test_text_quality(t: Callable) -> void:
	var seen: Dictionary = {}
	for ending_id in EXPECTED_IDS:
		var coda := EndingEchoData.coda_for(ending_id)
		t.call(coda.strip_edges(), coda, "echo_coda_no_outer_space_%s" % String(ending_id))
		t.call(ENDING_PUNCTUATION.contains(coda.substr(coda.length() - 1, 1)), true,
			"echo_coda_punctuation_%s" % String(ending_id))
		for npc_id in EXPECTED_NPCS:
			var line := EndingEchoData.echo_for(ending_id, npc_id)
			var label := "%s_%s" % [String(ending_id), String(npc_id)]
			t.call(line.strip_edges(), line, "echo_no_outer_space_" + label)
			t.call(line.contains(EndingEchoData.npc_name(npc_id)), true,
				"echo_names_speaker_" + label)
			t.call(ENDING_PUNCTUATION.contains(line.substr(line.length() - 1, 1)), true,
				"echo_punctuation_" + label)
			for marker in FORBIDDEN_MARKERS:
				t.call(line.contains(marker), false, "echo_marker_%s_%s" % [label, marker])
			t.call(seen.has(line), false, "echo_unique_" + label)
			seen[line] = true
	t.call(seen.size(), EXPECTED_IDS.size() * EXPECTED_NPCS.size(), "echo_all_25_unique")


func _test_thematic_mapping(t: Callable) -> void:
	# 圣经每个结局的收束不同：这些关键词把「余味」钉在对应结局上，防止整组串位。
	t.call(EndingEchoData.echo_for(&"restored", &"guru").contains("这个不卖，借你"), true,
		"echo_restored_guru_bible_line")
	t.call(EndingEchoData.echo_for(&"restored", &"luchen").contains("文件夹"), true,
		"echo_restored_luchen_folder")
	t.call(EndingEchoData.echo_for(&"restored", &"wenjin").contains("自己的名字"), true,
		"echo_restored_wenjin_name")
	t.call(EndingEchoData.echo_for(&"restored", &"baiyu").contains("路"), true,
		"echo_restored_baiyu_road")
	for npc_id in EXPECTED_NPCS:
		var burned := EndingEchoData.echo_for(&"burned", npc_id)
		t.call(burned.contains("烧") or burned.contains("火"), true,
			"echo_burned_fire_%s" % String(npc_id))
	for ending_id in EXPECTED_IDS:
		var coda := EndingEchoData.coda_for(ending_id)
		t.call(coda.contains("最后一页"), true,
			"echo_coda_last_page_%s" % String(ending_id))
		t.call(coda.contains("笑面史官"), true,
			"echo_coda_smiling_archivist_%s" % String(ending_id))
		var display := EndingEchoData.display_text(ending_id)
		for npc_id in EXPECTED_NPCS:
			t.call(display.contains(EndingEchoData.echo_for(ending_id, npc_id)), true,
				"echo_display_%s_%s" % [String(ending_id), String(npc_id)])
		t.call(display.contains(coda), true, "echo_display_coda_%s" % String(ending_id))
	# 未收录 / 空 id 安全。
	t.call(EndingEchoData.has_ending(&"missing"), false, "echo_unknown_ending")
	t.call(EndingEchoData.echoes_for(&"missing").is_empty(), true, "echo_unknown_empty")
	t.call(EndingEchoData.echo_for(&"restored", &"missing"), "", "echo_unknown_npc")
	t.call(EndingEchoData.coda_for(&"missing"), "", "echo_unknown_coda")
	t.call(EndingEchoData.display_text(&"missing"), "", "echo_unknown_display")
	t.call(EndingEchoData.npc_name(&"missing"), "", "echo_unknown_name")


func _test_ending_screen(t: Callable) -> void:
	var scene = load("res://scenes/ui/ending_screen.tscn")
	t.call(scene != null, true, "echo_ending_scene_loads")
	if scene == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	var screen = scene.instantiate()
	tree.root.add_child(screen)
	var echoes := screen.get_node_or_null("Center/Panel/Margin/VBox/Echoes") as Label
	t.call(echoes != null, true, "echo_screen_has_label")
	var body := screen.get_node_or_null("Center/Panel/Margin/VBox/Body") as Label
	var abyss := CampaignData.ending_by_id(&"abyss")
	screen.show_campaign_ending(true, 12, abyss, 4, 9, false, 42)
	if echoes != null:
		t.call(echoes.text, EndingEchoData.display_text(&"abyss"), "echo_screen_abyss_text")
		t.call(echoes.text.contains(EndingEchoData.echo_for(&"abyss", &"guru")), true,
			"echo_screen_abyss_guru")
		t.call(echoes.text.contains(EndingEchoData.echo_for(&"restored", &"guru")), false,
			"echo_screen_no_restored_leak")
	if body != null:
		t.call(body.text.begins_with(String(abyss.get("body", ""))), true,
			"echo_screen_body_unchanged")
	# 换一个结局时整块替换，不残留上一局。
	screen.show_campaign_ending(true, 3, CampaignData.ending_by_id(&"burned"), 1, 2)
	if echoes != null:
		t.call(echoes.text, EndingEchoData.display_text(&"burned"), "echo_screen_switch")
		t.call(echoes.text.contains(EndingEchoData.echo_for(&"abyss", &"guru")), false,
			"echo_screen_no_abyss_after_switch")
	# 旧调用 / 未知结局没有余味可显示。
	screen.show_ending(true, 25)
	if echoes != null:
		t.call(echoes.text, "", "echo_screen_legacy_empty")
	screen.show_campaign_ending(true, 5, {"title": "探针", "body": "探针"}, 0, 0)
	if echoes != null:
		t.call(echoes.text, "", "echo_screen_unknown_empty")
	tree.root.remove_child(screen)
	screen.free()


func _test_gallery(t: Callable) -> void:
	var profile := Profile.new()
	profile.record_ending(&"restored")
	var gallery := EndingGalleryUI.new()
	gallery.open(profile)
	t.call(gallery.get_entry_text(0).contains(EndingEchoData.coda_for(&"restored")), true,
		"echo_gallery_restored_coda")
	for npc_id in EXPECTED_NPCS:
		t.call(gallery.get_entry_text(0).contains(
			EndingEchoData.echo_for(&"restored", npc_id)), true,
			"echo_gallery_restored_%s" % String(npc_id))
	# 未解锁的「焚毁档案」不得泄露任何余味或回收段。
	var locked_text := gallery.get_entry_text(1)
	for npc_id in EXPECTED_NPCS:
		t.call(locked_text.contains(EndingEchoData.echo_for(&"burned", npc_id)), false,
			"echo_gallery_locked_%s" % String(npc_id))
	t.call(locked_text.contains(EndingEchoData.coda_for(&"burned")), false,
		"echo_gallery_locked_coda")
	t.call(locked_text.contains(EndingGalleryUI.LOCKED_BODY), true,
		"echo_gallery_locked_placeholder")
	if gallery._rows.size() > 1:
		var echo_label: Label = gallery._rows[1]["echo"]
		t.call(echo_label.text, "", "echo_gallery_locked_echo_label_empty")
	# 旧存档里的未知 id 仍不解锁任何条目、不显示余味。
	profile.record_ending(&"legacy_unknown_ending")
	gallery._refresh()
	t.call(gallery._count_label.text, "已记录 1 / 5", "echo_gallery_unknown_id_ignored")
	gallery.close()
	gallery.free()
	profile.free()


func _test_save_format(t: Callable) -> void:
	var path := "user://test_ending_echoes_save.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var profile := Profile.new()
	profile.record_ending(&"restored")
	profile.record_ending(&"abyss")
	profile.save_profile(path)
	var config := ConfigFile.new()
	t.call(config.load(path), OK, "echo_save_loads")
	t.call(config.get_value("progress", "endings", []), ["restored", "abyss"],
		"echo_save_endings_ids_only")
	t.call(config.has_section_key("progress", "ending_echoes"), false,
		"echo_save_no_echo_key")
	t.call(FileAccess.get_file_as_string(path).contains("笑面史官"), false,
		"echo_save_no_echo_text")
	var loaded := Profile.new()
	t.call(loaded.load_profile(path), true, "echo_save_profile_reloads")
	t.call(loaded.endings, ["restored", "abyss"], "echo_save_endings_roundtrip")
	loaded.free()
	profile.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_ending_regression(t: Callable) -> void:
	# 5 个 id、标题、现有 2 句正文与判定逻辑一字不改。
	for index in EXPECTED_IDS.size():
		var entry := CampaignData.ending(index)
		var ending_id: StringName = EXPECTED_IDS[index]
		t.call(String(entry.get("id", "")), String(ending_id), "echo_regression_id_%d" % index)
		t.call(String(entry.get("title", "")), EXPECTED_TITLES[ending_id],
			"echo_regression_title_%d" % index)
		t.call(String(entry.get("body", "")), EXPECTED_BODIES[ending_id],
			"echo_regression_body_%d" % index)
		t.call(CampaignData.ending_by_id(ending_id), entry,
			"echo_regression_lookup_%d" % index)
	t.call(String(CampaignData.ending_for(false, 0, 0, false).get("id", "")), "interrupted",
		"echo_regression_death")
	t.call(String(CampaignData.ending_for(true, 0, 0, true).get("id", "")), "burned",
		"echo_regression_burned")
	t.call(String(CampaignData.ending_for(true, 60, 0, false).get("id", "")), "abyss",
		"echo_regression_abyss")
	t.call(String(CampaignData.ending_for(true, 59, 2, false).get("id", "")), "restored",
		"echo_regression_restored")
	t.call(String(CampaignData.ending_for(true, 59, 1, false).get("id", "")), "unfinished",
		"echo_regression_unfinished")
