extends RefCounted

## First-run onboarding: tutorial steps persist, the training stele takes a
## hit, the title exposes New Game with confirmation, and pause actions ask.

func run(t: Callable) -> void:
	_test_profile_flag(t)
	_test_tutorial_flow(t)
	_test_training_dummy(t)
	_test_title_entries(t)
	_test_new_game_order(t)
	_test_pause_confirmation(t)


func _test_profile_flag(t: Callable) -> void:
	var path := "user://test_tutorial_profile.cfg"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var profile := Profile.new()
	t.call(profile.tutorial_done, false, "tutorial_starts_undone")
	profile.tutorial_done = true
	profile.save_profile(path)
	var loaded := Profile.new()
	loaded.load_profile(path)
	t.call(loaded.tutorial_done, true, "tutorial_done_persists")
	profile.free()
	loaded.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)


func _test_tutorial_flow(t: Callable) -> void:
	var original: Profile = Flow.profile
	var profile := Profile.new()
	Flow.profile = profile
	var tree := Engine.get_main_loop() as SceneTree
	var flow := TutorialFlow.new()
	tree.root.add_child(flow)
	flow.start_if_needed()
	t.call(flow.is_active(), true, "tutorial_starts_on_first_hub")
	t.call(flow.get_hint().contains("按 C"), true, "tutorial_first_hint_codex")
	flow.on_codex_opened()
	t.call(flow.get_hint().contains("装备"), true, "tutorial_second_hint_equip")
	flow.on_phrase_equipped()
	t.call(flow.get_hint().contains("训练碑"), true, "tutorial_third_hint_dummy")
	flow.on_training_hit()
	t.call(flow.is_active(), false, "tutorial_completes")
	t.call(profile.tutorial_done, true, "tutorial_marks_profile")
	tree.root.remove_child(flow)
	flow.free()
	Flow.profile = original
	profile.free()


func _test_training_dummy(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	tree.root.add_child(parent)
	var dummy := TrainingDummy.new()
	parent.add_child(dummy)
	var hits: Array[int] = []
	dummy.hit.connect(func(amount: int): hits.append(amount))
	dummy.take_damage(17)
	t.call(hits, [17], "training_dummy_emits_hit")
	t.call(dummy.health, dummy.max_health - 17, "training_dummy_takes_damage")
	t.call(dummy.health > 0, true, "training_dummy_never_dies")
	tree.root.remove_child(parent)
	parent.free()


func _test_title_entries(t: Callable) -> void:
	var original: Profile = Flow.profile
	var profile := Profile.new()
	profile.memory_fragments = 10
	Flow.profile = profile
	var title := TitleScreen.new()
	title._build()
	t.call(title.find_child("SettingsButton", true, false) != null, true, "title_has_settings")
	t.call(title.find_child("NewGameButton", true, false) != null, true, "title_has_new_game_with_progress")
	title.new_game_requested.connect(func(): pass)
	title._confirm_new_game()
	var confirm := title.find_child("NewGameConfirm", true, false) as ConfirmPanel
	t.call(confirm != null, true, "new_game_asks_confirmation")
	t.call(confirm != null and confirm.is_open(), true, "new_game_confirmation_open")
	if confirm != null:
		confirm.cancel()
		t.call(not confirm.is_open(), true, "new_game_confirmation_cancel_closes")
	title.free()
	Flow.profile = original
	profile.free()


## The Hub reads Flow.profile inside the new_game_requested handler. If the
## signal fires before reset_profile(), it binds to the instance being freed.
func _test_new_game_order(t: Callable) -> void:
	var original_profile: Profile = Flow.profile
	var original_path := Flow.profile_path
	var original_run := Flow.run_save_path
	var original_save := Flow.auto_save
	Flow.auto_save = false
	Flow.profile_path = "user://test_new_game_profile.cfg"
	Flow.run_save_path = "user://test_new_game_run.cfg"
	var previous := Profile.new()
	Flow.profile = previous
	var seen: Array[Profile] = []
	var title := TitleScreen.new()
	title._flow = Flow
	title.new_game_requested.connect(func(): seen.append(Flow.profile))
	title._start_new_game()
	t.call(seen.size(), 1, "new_game_emits_once")
	t.call(seen.size() == 1 and seen[0] == Flow.profile, true, "new_game_signal_sees_new_profile")
	t.call(Flow.profile != previous, true, "new_game_replaces_profile")
	t.call(Flow.profile != null and Flow.profile.memory_fragments == 0, true, "new_game_profile_is_fresh")
	title.free()
	var created: Profile = Flow.profile
	Flow.profile = original_profile
	Flow.profile_path = original_path
	Flow.run_save_path = original_run
	Flow.auto_save = original_save
	if created != null:
		created.free()


func _test_pause_confirmation(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var menu := preload("res://scenes/ui/pause_menu.tscn").instantiate() as PauseMenu
	menu.managed = true
	tree.root.add_child(menu)
	menu._on_restart_pressed()
	t.call(menu._confirm != null, true, "restart_asks_confirmation")
	if menu._confirm != null:
		t.call(menu._confirm.dialog_text.contains("重新开始"), true, "restart_confirmation_text")
		menu._confirm.hide()
	menu._on_quit_pressed()
	t.call(menu._confirm != null, true, "quit_asks_confirmation")
	if menu._confirm != null:
		t.call(menu._confirm.dialog_text.contains("放弃本局"), true, "quit_confirmation_text")
		menu._confirm.hide()
	# The two buttons share one dialog. It must only ever hold one armed action:
	# before, each press added a one-shot connection, so cancelling 退出 and then
	# confirming 重新开始 ran both handlers and abandoned the run as well.
	menu._on_quit_pressed()
	t.call(menu._confirm_action.get_method() == &"_do_quit", true, "quit_confirmation_armed")
	menu._on_restart_pressed()
	t.call(menu._confirm_action.get_method() == &"_do_restart", true,
		"rearming_replaces_previous_action")
	t.call(menu._confirm.confirmed.get_connections().size(), 1,
		"confirmation_holds_one_connection")
	menu._on_quit_pressed()
	t.call(menu._confirm_action.get_method() == &"_do_quit", true, "third_confirmation_arms_quit")
	t.call(menu._confirm.confirmed.get_connections().size(), 1,
		"confirmation_still_holds_one_connection")
	if menu._confirm != null:
		menu._confirm.hide()
	menu._on_quit_pressed()
	menu._clear_confirm()
	t.call(menu._confirm_action.is_valid(), false, "cancelled_confirmation_disarmed")
	if menu._confirm != null:
		menu._confirm.hide()
	tree.root.remove_child(menu)
	menu.free()
	tree.paused = false
