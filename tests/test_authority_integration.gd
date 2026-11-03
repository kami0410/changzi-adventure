extends RefCounted

## Authority is a run-long rule, not flavour text: revive and rewrite each work
## exactly once, and the boss choice UI reports the picked option.

const REVIVE_PATH := "res://resources/authorities/revive.tres"
const REWRITE_PATH := "res://resources/authorities/rewrite.tres"


func run(t: Callable) -> void:
	_test_revive_once(t)
	_test_rewrite_once(t)
	_test_choice_ui(t)
	_test_rewrite_button(t)
	_test_hud_slot(t)


func _test_revive_once(t: Callable) -> void:
	var revive := load(REVIVE_PATH) as AuthorityData
	var run_state := RunState.new()
	run_state.reset_for_new_run(5)
	var controller := AuthorityController.new()
	var flags := controller.apply(revive, run_state)
	t.call(flags.get("revive", false), true, "revive_flag_set")
	t.call(run_state.authority, revive, "authority_stored_on_run")
	t.call(controller.can_revive(), true, "revive_available")
	t.call(controller.consume_revive(), true, "revive_first_death")
	t.call(controller.consume_revive(), false, "revive_second_death")
	t.call(controller.can_revive(), false, "revive_spent")


func _test_rewrite_once(t: Callable) -> void:
	var rewrite := load(REWRITE_PATH) as AuthorityData
	var run_state := RunState.new()
	run_state.reset_for_new_run(6)
	var controller := AuthorityController.new()
	var flags := controller.apply(rewrite, run_state)
	t.call(flags.get("rewrite", false), true, "rewrite_flag_set")
	t.call(controller.can_rewrite(), true, "rewrite_available")
	t.call(controller.consume_rewrite(), true, "rewrite_first_reroll")
	t.call(controller.consume_rewrite(), false, "rewrite_second_reroll")
	t.call(controller.can_rewrite(), false, "rewrite_spent")


func _test_choice_ui(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var ui := AuthorityChoiceUI.new()
	tree.root.add_child(ui)
	var picked: Array[int] = []
	ui.chosen.connect(func(index: int): picked.append(index))
	var options: Array[AuthorityData] = [
		load(REVIVE_PATH) as AuthorityData,
		load(REWRITE_PATH) as AuthorityData,
	]
	ui.open(options)
	t.call(ui.visible, true, "authority_ui_opens")
	t.call(ui.get_button_count(), 2, "authority_ui_two_choices")
	t.call(tree.paused, true, "authority_ui_pauses")
	ui._choose(1)
	t.call(picked, [1], "authority_ui_emits_choice")
	t.call(ui.visible, false, "authority_ui_closes")
	t.call(tree.paused, false, "authority_ui_restores_pause")
	tree.root.remove_child(ui)
	ui.free()
	tree.paused = false


func _test_rewrite_button(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var reward := RewardChoice.new()
	tree.root.add_child(reward)
	var requests := [0]
	reward.reroll_requested.connect(func(): requests[0] += 1)
	reward.open_choices([{"kind": &"relic", "title": "测试", "description": "测试"}])
	reward.set_reroll_available(true)
	t.call(reward._reroll.visible, true, "rewrite_button_visible")
	reward._reroll.pressed.emit()
	t.call(requests[0], 1, "rewrite_button_requests_reroll")
	reward.set_reroll_available(false)
	t.call(reward._reroll.visible, false, "rewrite_button_hides_after_use")
	reward.hide()
	tree.root.remove_child(reward)
	reward.free()


func _test_hud_slot(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as HUD
	tree.root.add_child(hud)
	hud.set_authority("续命", true)
	var label := hud.find_child("Authority", true, false) as Label
	t.call(label != null, true, "hud_authority_label_exists")
	if label != null:
		t.call(label.text.contains("续命") and label.text.contains("可用"), true, "hud_authority_available")
	hud.set_authority("续命", false)
	if label != null:
		t.call(label.text.contains("已用"), true, "hud_authority_spent")
	tree.root.remove_child(hud)
	hud.free()
