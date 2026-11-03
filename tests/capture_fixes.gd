extends SceneTree

## Focused captures for the 0.9.1 playability fixes: dialogue portrait and its
## in-panel 言灵 button, reward cards at rest, the help page, and the polluted HUD.
## Run windowed (screenshots need a renderer):
##   Godot --path . --resolution 1280x720 --script tests/capture_fixes.gd -- --out-dir=res://artifacts/ui

var _dir := "res://artifacts/ui"
var _host: Control


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))

	_host = Control.new()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_host)
	var bg := ColorRect.new()
	bg.color = Color("0b1018")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(bg)

	var reward := RewardChoice.new()
	_host.add_child(reward)
	reward.open_choices([
		{"kind": &"relic", "title": "不朽档案", "description": "每局一次：致命伤害后\n以 40 生命复活。\n污染 +4"},
		{"kind": &"word", "title": "新词 · 追猎", "description": "鸦群掠过档案馆时落下\n的羽。每一根都记得回\n去的路。\n加入词库，按 C 组合新短语。"},
		{"kind": &"rest", "title": "修补记忆", "description": "恢复 35 生命与 45 墨量。\n污染降低 8。"},
	])
	await create_timer(0.3).timeout
	await _capture("fix_reward")
	reward.hide()
	_host.remove_child(reward)
	reward.free()

	var dialogue := preload("res://scenes/ui/dialogue_ui.tscn").instantiate() as DialogueUI
	_host.add_child(dialogue)
	dialogue.set_inspiration_enabled(true)
	dialogue.open_dialogue("阿砚", [
		"刀口又卷了？拿过来。别碰炉子，烫。",
		"这把剑的基底我还能再救一页。前提是你别再拿它去劈石头。",
	])
	await create_timer(0.45).timeout
	await _capture("fix_dialogue")
	dialogue.close()
	_host.remove_child(dialogue)
	dialogue.free()

	var help := HelpUI.new()
	_host.add_child(help)
	help.open()
	await create_timer(0.3).timeout
	await _capture("fix_help")
	help.close()
	_host.remove_child(help)
	help.free()

	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as HUD
	_host.add_child(hud)
	var run := RunState.new()
	run.reset_for_new_run(5)
	run.add_corruption(76)
	hud.bind_run_state(run)
	await create_timer(0.25).timeout
	await _capture("fix_corruption_hud")
	quit()


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_dir.path_join(file + ".png"))
	print("CAPTURE ", file)
