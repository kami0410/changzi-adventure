extends RefCounted

const REWRITE_PATH := "res://resources/authorities/rewrite.tres"
const REVIVE_PATH := "res://resources/authorities/revive.tres"
const DEVOUR_PATH := "res://resources/authorities/devour.tres"
const ARCHIVE_PATH := "res://resources/authorities/archive.tres"


func run(t: Callable) -> void:
	_test_each_authority(t)
	_test_devour_damage_marker(t)
	_test_null_and_fallback(t)


func _make_run(seed_value: int = 1) -> RunState:
	var run := RunState.new()
	run.reset_for_new_run(seed_value)
	return run


func _test_each_authority(t: Callable) -> void:
	var run := _make_run()
	var rewrite := load(REWRITE_PATH) as AuthorityData
	var revive := load(REVIVE_PATH) as AuthorityData
	var devour := load(DEVOUR_PATH) as AuthorityData
	var archive := load(ARCHIVE_PATH) as AuthorityData
	t.call(rewrite != null and revive != null and devour != null and archive != null, true, "authority_resources_load")

	var rewrite_result := AuthorityEffects.apply(run, rewrite)
	t.call(rewrite_result["rewrite"], true, "rewrite_flag")
	t.call(rewrite_result["revive"], false, "rewrite_no_revive")
	t.call(run.authority, rewrite, "rewrite_sets_run_authority")

	var revive_result := AuthorityEffects.apply(run, revive)
	t.call(revive_result["revive"], true, "revive_flag")
	t.call(revive_result["devour"], false, "revive_no_devour")
	t.call(run.authority, revive, "revive_sets_run_authority")

	var archive_result := AuthorityEffects.apply(run, archive)
	t.call(archive_result["archive"], true, "archive_flag")
	t.call(archive_result["rewrite"], false, "archive_no_rewrite")
	t.call(run.authority, archive, "archive_sets_run_authority")


func _test_devour_damage_marker(t: Callable) -> void:
	var run := _make_run()
	var devour := load(DEVOUR_PATH) as AuthorityData
	run.corruption = 40
	var result := AuthorityEffects.apply(run, devour)
	t.call(result["devour"], true, "devour_flag")
	t.call(result["damage_bonus"], 40, "devour_damage_bonus_from_corruption")
	t.call(result.get("temporary", false), true, "devour_temporary_marker")
	t.call(run.corruption, 40, "devour_does_not_mutate_corruption")
	t.call(run.authority, devour, "devour_sets_run_authority")


func _test_null_and_fallback(t: Callable) -> void:
	var run := _make_run()
	var empty := AuthorityEffects.apply(run, null)
	t.call(empty["revive"], false, "null_authority_revive")
	t.call(empty["rewrite"], false, "null_authority_rewrite")
	t.call(empty["devour"], false, "null_authority_devour")
	t.call(empty["archive"], false, "null_authority_archive")

	var null_run_result := AuthorityEffects.apply(null, load(REVIVE_PATH) as AuthorityData)
	t.call(null_run_result["revive"], false, "null_run_safe")

	var custom := AuthorityData.new()
	custom.id = &"revive"
	custom.effect_id = &""
	var fallback_result := AuthorityEffects.apply(run, custom)
	t.call(fallback_result["revive"], true, "effect_id_falls_back_to_id")
	t.call(run.authority, custom, "fallback_sets_authority")

	var unknown := AuthorityData.new()
	unknown.id = &"unknown"
	unknown.effect_id = &"mystery"
	var unknown_result := AuthorityEffects.apply(run, unknown)
	t.call(unknown_result["revive"], false, "unknown_effect_no_flag")
	t.call(unknown_result["devour"], false, "unknown_effect_no_devour")
