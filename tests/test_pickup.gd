extends RefCounted


func run(t: Callable) -> void:
	var scene = load("res://scenes/combat/pickup.tscn")
	t.call(scene != null, true, "pickup_scene_loads")
	if scene == null:
		return
	var pickup = scene.instantiate()
	t.call(pickup is Pickup, true, "pickup_script")
	t.call(pickup.get_node_or_null("Visual") is Polygon2D, true, "pickup_visual")
	t.call(pickup.get_node_or_null("Label") is Label, true, "pickup_label")

	var player := Player.new()
	player.add_to_group("player")
	var received: Array = []
	pickup.collected.connect(func(kind, resource): received.append([kind, resource]))
	pickup._on_body_entered(player)
	t.call(received.size(), 0, "pickup_waits_for_interact")
	t.call(pickup.can_collect(), true, "pickup_can_collect_near")
	t.call(pickup.try_collect(), true, "pickup_try_collect")
	t.call(received.size(), 1, "pickup_collect_signal")
	t.call(received[0][0], &"word", "pickup_kind")

	player.free()
