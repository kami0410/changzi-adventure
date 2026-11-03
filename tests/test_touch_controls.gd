extends RefCounted


func run(t: Callable) -> void:
	var scene = load("res://scenes/ui/touch_controls.tscn")
	t.call(scene != null, true, "touch_scene_loads")
	if scene == null:
		return
	var controls = scene.instantiate()
	t.call(controls.get_node_or_null("Left") is Button, true, "touch_left_button")
	t.call(controls.get_node_or_null("Right") is Button, true, "touch_right_button")
	t.call(controls.get_node_or_null("Attack") is Button, true, "touch_attack_button")
	t.call(controls.get_node_or_null("Jump") is Button, true, "touch_jump_button")
	t.call(controls.get_node_or_null("Dodge") is Button, true, "touch_dodge_button")
	t.call(controls.get_node_or_null("Interact") is Button, true, "touch_interact_button")
	t.call(controls.get_node_or_null("Cast1") is Button, true, "touch_cast1_button")
	t.call(controls.get_node_or_null("Cast2") is Button, true, "touch_cast2_button")
	controls.free()
