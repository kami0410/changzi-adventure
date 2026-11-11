extends SceneTree

## Regression (1.1.1): the real way into a level. Boots the Hub like the game does, lets the
## background warmup run for a moment, then asks for a run the way the Hub
## door does. Prints a heartbeat so a hang is visible as silence.
##   godot --path . -s res://tests/repro_enter_level.gd -- --wait=1.0

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var wait := 1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--wait="):
			wait = float(argument.trim_prefix("--wait="))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(wait).timeout
	print("REPRO warmup progress before entering: %.2f" % Warmup.progress())
	var started := Time.get_ticks_msec()
	hub._on_run_requested()
	print("REPRO door returned after %d ms" % (Time.get_ticks_msec() - started))
	for second in 6:
		await create_timer(1.0).timeout
		print("REPRO alive %d s, scene=%s" % [second + 1, current_scene.name if current_scene != null else "null"])
	quit()
