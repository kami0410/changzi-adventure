extends RefCounted

## Readable HUD: 12/16/20 text sizes, main info at least 16 by default,
## integer pixel scaling, and danger warnings with distinct shapes.

func run(t: Callable) -> void:
	_test_integer_scaling(t)
	_test_hud_text_scale(t)
	_test_settings_text_option(t)
	_test_danger_shapes(t)


func _test_integer_scaling(t: Callable) -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	t.call(project.contains("window/stretch/scale_mode=\"integer\""), true, "integer_pixel_scaling")
	t.call(project.contains("window/size/viewport_width=1280"), true, "native_width_1280")


func _test_hud_text_scale(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as HUD
	tree.root.add_child(hud)
	hud.apply_text_scale(16)
	t.call(hud.get_main_font_size(), 16, "hud_main_info_16px")
	var relics := hud.find_child("Relics", true, false) as Label
	t.call(relics.get_theme_font_size("font_size"), 12, "hud_aux_12px")
	hud.apply_text_scale(20)
	t.call(hud.get_main_font_size(), 20, "hud_main_info_20px")
	t.call(relics.get_theme_font_size("font_size"), 16, "hud_aux_follows_scale")
	hud.apply_text_scale(12)
	t.call(hud.get_main_font_size(), 12, "hud_main_info_12px")
	tree.root.remove_child(hud)
	hud.free()


func _test_settings_text_option(t: Callable) -> void:
	var flow := Engine.get_main_loop().root.get_node_or_null("Flow") as GameFlow
	var original := flow.profile.text_scale if flow != null and flow.profile != null else 16
	var tree := Engine.get_main_loop() as SceneTree
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as HUD
	tree.root.add_child(hud)
	var settings := preload("res://scenes/ui/settings_menu.tscn").instantiate() as SettingsMenu
	tree.root.add_child(settings)
	settings.open()
	var option := settings.find_child("TextScaleOption", true, false) as OptionButton
	t.call(option != null, true, "settings_has_text_scale_option")
	if option != null:
		t.call(option.item_count, 3, "settings_three_text_sizes")
	settings._set_text_scale(20)
	t.call(hud.get_main_font_size(), 20, "settings_applies_hud_text_size")
	if flow != null and flow.profile != null:
		t.call(flow.profile.text_scale, 20, "settings_saves_text_scale")
		flow.profile.text_scale = original
	tree.root.remove_child(settings)
	settings.free()
	tree.root.remove_child(hud)
	hud.free()


func _test_danger_shapes(t: Callable) -> void:
	t.call(InkWarning.SHAPE != HostileBolt.SHAPE, true, "ground_and_line_shapes_differ")
	t.call(HostileBolt.SHAPE != CombatFX.TELEGRAPH_SHAPE, true, "line_and_circle_shapes_differ")
	t.call(DangerShape.label(InkWarning.SHAPE), "地面矩形", "ground_shape_label")
	t.call(DangerShape.label(HostileBolt.SHAPE), "直线", "line_shape_label")
