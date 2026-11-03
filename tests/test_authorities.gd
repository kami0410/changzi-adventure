extends RefCounted


func run(t: Callable) -> void:
	var authorities := _load_all("res://resources/authorities")
	t.call(authorities.size(), 4, "authority_count")

	var ids: Dictionary = {}
	for authority in authorities:
		t.call(authority is AuthorityData, true, "authority_type")
		ids[authority.id] = true
	t.call(ids.has(&"rewrite"), true, "authority_rewrite")
	t.call(ids.has(&"revive"), true, "authority_revive")
	t.call(ids.has(&"devour"), true, "authority_devour")
	t.call(ids.has(&"archive"), true, "authority_archive")

	var run := RunState.new()
	run.reset_for_new_run(1)
	t.call(run.authority, null, "authority_default")
	run.set_authority(authorities[0])
	t.call(run.authority, authorities[0], "authority_set")


func _load_all(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var resource = load(path + "/" + file_name)
			if resource != null:
				result.append(resource)
	return result
