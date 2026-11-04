extends RefCounted


func run(t: Callable) -> void:
	var scene = load("res://scenes/ui/ending_screen.tscn")
	t.call(scene != null, true, "ending_scene_loads")
	if scene == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	var flow := tree.root.get_node_or_null("Flow") as GameFlow
	var ending = scene.instantiate()
	tree.root.add_child(ending)
	var key := flow.prompt_label(&"restart") if flow != null else GameFlow.key_label(&"restart")
	ending.show_ending(true, 25)
	t.call(ending.visible, true, "ending_visible")
	t.call(ending.get_node("Center/Panel/Margin/VBox/Title").text, "史官归位", "ending_title_win")
	t.call(ending.get_node("Center/Panel/Margin/VBox/Reward").text, "记忆碎片 +25", "ending_reward")
	t.call(ending._hint != null and ending._hint.text.contains("回到最后的档案馆"), true,
		"ending_win_hint_destination")
	t.call(ending._hint != null and ending._hint.text.contains(key), true,
		"ending_win_hint_key")
	t.call(ending._hint.text, EndingHintData.format_hint(EndingHintData.pick(0, true), key),
		"ending_win_hint_matches_seed")
	var win_hint: String = ending._hint.text
	ending._refresh_prompts()
	t.call(ending._hint.text, win_hint, "ending_win_hint_stable_on_refresh")
	ending.show_ending(false, 10)
	t.call(ending.get_node("Center/Panel/Margin/VBox/Title").text, "记录中断", "ending_title_lose")
	t.call(ending._hint.text, EndingHintData.format_hint(EndingHintData.pick(0, false), key),
		"ending_lose_hint_matches_seed")
	t.call(ending._hint.text.contains("回到最后的档案馆"), true,
		"ending_lose_hint_destination")
	ending.show_campaign_ending(true, 5, {"title": "探针", "body": "探针"}, 0, 0, true, 777)
	t.call(ending._hint.text, EndingHintData.format_hint(EndingHintData.pick(777, true), key),
		"ending_hint_uses_run_seed")
	tree.root.remove_child(ending)
	ending.free()
