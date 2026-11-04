extends RefCounted

## Ending ids are already persisted by Profile (a plain string list). The
## gallery must derive its unlock state from that list, show placeholders for
## the rest, and leave old saves with unknown ids readable.

func run(t: Callable) -> void:
	_test_campaign_endings(t)
	_test_profile_ids(t)
	_test_gallery(t)
	_test_title_entry(t)
	_test_old_save(t)


func _test_campaign_endings(t: Callable) -> void:
	t.call(CampaignData.ending_count(), 5, "ending_count")
	var seen: Dictionary = {}
	for index in CampaignData.ending_count():
		var entry := CampaignData.ending(index)
		var ending_id := StringName(entry.get("id", &""))
		t.call(ending_id == &"", false, "ending_%d_has_id" % index)
		t.call(seen.has(ending_id), false, "ending_%d_id_unique" % index)
		seen[ending_id] = true
		t.call(String(entry.get("title", "")).is_empty(), false, "ending_%d_has_title" % index)
		t.call(String(entry.get("body", "")).is_empty(), false, "ending_%d_has_body" % index)
		t.call(CampaignData.ending_by_id(ending_id), entry, "ending_%d_by_id" % index)
	# GDD §12.2 order: 复原、焚毁档案、深渊回响、未完的注脚、记录中断.
	t.call(String(CampaignData.ending(0).get("id", "")), "restored", "ending_order_restored")
	t.call(String(CampaignData.ending(1).get("id", "")), "burned", "ending_order_burned")
	t.call(String(CampaignData.ending(2).get("id", "")), "abyss", "ending_order_abyss")
	t.call(String(CampaignData.ending(3).get("id", "")), "unfinished", "ending_order_unfinished")
	t.call(String(CampaignData.ending(4).get("id", "")), "interrupted", "ending_order_interrupted")
	t.call(CampaignData.ending_by_id(&"missing").is_empty(), true, "ending_missing_empty")

	# The result page still maps every branch to the authored text.
	t.call(String(CampaignData.ending_for(false, 0, 0, false).get("id", "")), "interrupted",
		"ending_for_death")
	t.call(String(CampaignData.ending_for(true, 0, 0, true).get("id", "")), "burned",
		"ending_for_burned")
	t.call(String(CampaignData.ending_for(true, 60, 0, false).get("id", "")), "abyss",
		"ending_for_abyss")
	t.call(String(CampaignData.ending_for(true, 59, 2, false).get("id", "")), "restored",
		"ending_for_restored")
	t.call(String(CampaignData.ending_for(true, 59, 1, false).get("id", "")), "unfinished",
		"ending_for_unfinished")
	t.call(String(CampaignData.ending_for(true, 0, 0, true).get("body", "")),
		String(CampaignData.ending_by_id(&"burned").get("body", "")),
		"ending_for_returns_authored_body")


func _test_profile_ids(t: Callable) -> void:
	var profile := Profile.new()
	profile.record_ending(&"restored")
	profile.record_ending(&"restored")
	profile.record_ending(&"abyss")
	t.call(profile.endings, ["restored", "abyss"], "ending_profile_ids_only")
	t.call(profile.endings.has("restored"), true, "ending_profile_has_id")
	profile.free()


func _test_gallery(t: Callable) -> void:
	var profile := Profile.new()
	profile.record_ending(&"restored")
	profile.record_ending(&"abyss")
	var gallery := EndingGalleryUI.new()
	gallery.open(profile)
	t.call(gallery.is_open(), true, "gallery_opens")
	t.call(gallery.get_entry_count(), CampaignData.ending_count(), "gallery_entry_count")
	t.call(gallery.is_unlocked(0), true, "gallery_restored_unlocked")
	t.call(gallery.is_unlocked(1), false, "gallery_burned_locked")
	t.call(gallery.is_unlocked(2), true, "gallery_abyss_unlocked")
	t.call(gallery.is_unlocked(3), false, "gallery_unfinished_locked")
	t.call(gallery.is_unlocked(4), false, "gallery_interrupted_locked")
	t.call(gallery.get_entry_text(0).contains("复原"), true, "gallery_unlocked_title")
	t.call(gallery.get_entry_text(0).contains(
		String(CampaignData.ending_by_id(&"restored").get("body", ""))), true,
		"gallery_unlocked_body")
	t.call(gallery.get_entry_text(1).contains(EndingGalleryUI.LOCKED_TITLE), true,
		"gallery_locked_placeholder_title")
	t.call(gallery.get_entry_text(1).contains(EndingGalleryUI.LOCKED_BODY), true,
		"gallery_locked_placeholder_body")
	t.call(gallery.get_entry_text(1).contains(
		String(CampaignData.ending_by_id(&"burned").get("body", ""))), false,
		"gallery_locked_body_hidden")
	t.call(gallery.get_entry_text(-1), "", "gallery_text_out_of_range")
	t.call(gallery.is_unlocked(99), false, "gallery_unlock_out_of_range")
	t.call(gallery._count_label.text, "已记录 2 / 5", "gallery_count_label")
	var closed: Array[bool] = []
	gallery.closed.connect(func(): closed.append(true))
	gallery.close()
	t.call(gallery.is_open(), false, "gallery_closes")
	t.call(closed.size(), 1, "gallery_close_signal")

	# A null profile is a fully locked gallery, not an error.
	var locked_gallery := EndingGalleryUI.new()
	locked_gallery.open(null)
	t.call(locked_gallery.is_open(), true, "gallery_null_opens")
	var unlocked_count := 0
	for index in locked_gallery.get_entry_count():
		if locked_gallery.is_unlocked(index):
			unlocked_count += 1
	t.call(unlocked_count, 0, "gallery_null_all_locked")
	locked_gallery.close()
	gallery.free()
	locked_gallery.free()
	profile.free()


func _test_title_entry(t: Callable) -> void:
	var title := TitleScreen.new()
	title._build()
	var button := title.find_child("EndingGalleryButton", true, false) as Button
	t.call(button != null, true, "title_has_ending_gallery_button")
	t.call(button != null and button.text == "结局画廊", true, "title_gallery_button_text")
	if button != null:
		title._open_ending_gallery()
		var gallery := title.find_child("EndingGallery", true, false) as EndingGalleryUI
		t.call(gallery != null, true, "title_gallery_built")
		t.call(gallery != null and gallery.is_open(), true, "title_gallery_opens")
		if gallery != null:
			gallery.close()
			t.call(gallery.is_open(), false, "title_gallery_closes")
	title.free()


func _test_old_save(t: Callable) -> void:
	var path := "user://test_ending_gallery_save.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("progress", "endings", ["restored", "legacy_unknown_ending"])
	config.save(path)
	var profile := Profile.new()
	t.call(profile.load_profile(path), true, "ending_old_save_loads")
	t.call(profile.endings.has("restored"), true, "ending_old_save_has_known")
	t.call(profile.endings.has("legacy_unknown_ending"), true, "ending_old_save_keeps_unknown")
	var gallery := EndingGalleryUI.new()
	gallery.open(profile)
	t.call(gallery.is_unlocked(0), true, "ending_old_save_unlocks_known")
	t.call(gallery._count_label.text, "已记录 1 / 5", "ending_old_save_ignores_unknown")
	gallery.close()
	gallery.free()
	profile.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
