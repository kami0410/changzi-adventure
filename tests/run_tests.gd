extends SceneTree

var passed := 0
var failed := 0
var _check := Callable()
var _filter := ""


func _initialize() -> void:
	_filter = _read_filter()
	_check = func(actual, expected, label): _assert_eq(actual, expected, label)
	# Unit tests must never write the player's real profile.
	var flow := root.get_node_or_null("Flow") as GameFlow
	if flow != null:
		flow.auto_save = false

	var dir := DirAccess.open("res://tests")
	if dir == null:
		push_error("Cannot open res://tests")
		quit(1)
		return

	var names := dir.get_files()
	names.sort()
	for file_name in names:
		if not file_name.begins_with("test_") or not file_name.ends_with(".gd"):
			continue
		if _filter != "" and not file_name.contains(_filter):
			continue
		var script = load("res://tests/" + file_name)
		if script == null:
			failed += 1
			push_error("Failed to load test script: " + file_name)
			continue
		var test = script.new()
		if not test.has_method("run"):
			failed += 1
			push_error("Test script missing run(): " + file_name)
			continue
		test.run(_check)

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _read_filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""


func _assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])
