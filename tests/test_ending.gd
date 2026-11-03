extends RefCounted


func run(t: Callable) -> void:
	var scene = load("res://scenes/ui/ending_screen.tscn")
	t.call(scene != null, true, "ending_scene_loads")
	if scene == null:
		return
	var ending = scene.instantiate()
	ending.show_ending(true, 25)
	t.call(ending.visible, true, "ending_visible")
	t.call(ending.get_node("Center/Panel/Margin/VBox/Title").text, "史官归位", "ending_title_win")
	t.call(ending.get_node("Center/Panel/Margin/VBox/Reward").text, "记忆碎片 +25", "ending_reward")
	ending.show_ending(false, 10)
	t.call(ending.get_node("Center/Panel/Margin/VBox/Title").text, "记录中断", "ending_title_lose")
	ending.free()
