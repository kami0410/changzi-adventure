extends RefCounted

## 1.1 readability pass: surface edges, the HUD's health trail and danger
## frame, and the role outlines on actors.

func run(t: Callable) -> void:
	_test_surface_runs(t)
	_test_hud_danger(t)
	_test_role_looks(t)


func _test_surface_runs(t: Callable) -> void:
	var cells: Array[Vector2i] = [
		Vector2i(3, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(6, 1), Vector2i(0, 4),
	]
	var runs := SurfaceEdge.merge(cells)
	t.call(runs.size(), 3, "surface_edge_merges_touching_cells")
	t.call(runs[0], [Vector2i(1, 1), 3], "surface_edge_first_run")
	t.call(runs[1], [Vector2i(6, 1), 1], "surface_edge_gap_starts_new_run")
	t.call(runs[2], [Vector2i(0, 4), 1], "surface_edge_rows_are_separate")
	t.call(SurfaceEdge.merge([]).size(), 0, "surface_edge_empty")


func _test_hud_danger(t: Callable) -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud := (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate() as HUD
	root.add_child(hud)
	t.call(hud.is_danger_shown(), false, "hud_danger_hidden_at_start")
	hud._show_health(100, 100)
	t.call(hud.is_danger_shown(), false, "hud_danger_hidden_when_healthy")
	hud._show_health(30, 100)
	t.call(hud.is_danger_shown(), true, "hud_danger_shown_at_low_health")
	t.call(hud._trail_ratio > hud._health_ratio, true, "hud_health_trail_lingers")
	hud._show_health(0, 100)
	t.call(hud.is_danger_shown(), false, "hud_danger_hidden_when_dead")
	hud._show_health(80, 100)
	t.call(is_equal_approx(hud._trail_ratio, 0.8), true, "hud_heal_snaps_trail")
	hud.free()


func _test_role_looks(t: Callable) -> void:
	var sprite := Sprite2D.new()
	PixelSprite.apply_role(sprite, &"enemy")
	var material := sprite.material as ShaderMaterial
	t.call(material != null, true, "role_gives_material")
	if material != null:
		t.call(float(material.get_shader_parameter(&"outline_strength")) > 0.0, true, "enemy_role_has_outline")
	sprite.free()
