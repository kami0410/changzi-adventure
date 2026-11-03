extends SceneTree

## Builds resources/chapters/chapter_1_demo.tres (the Chapter 1 demo plan).
## Run: godot --headless --path . --script tools/build_ch1_plan.gd

const OUT := "res://resources/chapters/chapter_1_demo.tres"


func _initialize() -> void:
	var plan := ChapterPlanData.new()
	plan.chapter_id = &"ink_archive"
	plan.rooms = [
		{"id": "ch1_01", "type": "combat", "wave": [&"ink_hound", &"scribe_bug"], "reward_pool": "default", "platform_rows": [30]},
		{"id": "ch1_02", "type": "combat", "wave": [&"blank_man", &"ink_hound", &"scribe_bug"], "reward_pool": "default", "platform_rows": [30, 28]},
		{"id": "ch1_03", "type": "combat", "wave": [&"ink_bomber", &"page_swarm", &"ink_hound"], "reward_pool": "default", "platform_rows": [30]},
		{"id": "ch1_04", "type": "elite", "wave": [&"typo_beast", &"blank_man", &"blank_man"], "reward_pool": "elite", "platform_rows": [30, 28]},
		{"id": "ch1_05", "type": "event", "wave": [], "reward_pool": "event", "platform_rows": [30]},
		{"id": "ch1_06", "type": "combat", "wave": [&"ink_bomber", &"scribe_bug", &"ink_hound", &"page_swarm"], "reward_pool": "default", "platform_rows": [30]},
		{"id": "ch1_rest", "type": "rest", "wave": [], "reward_pool": "rest", "platform_rows": [30]},
		{"id": "ch1_boss", "type": "boss", "wave": [], "reward_pool": "boss", "platform_rows": [30]},
		{"id": "ch1_vault", "type": "vault", "wave": [], "reward_pool": "vault", "platform_rows": [30]},
	]
	plan.boss_scene = load("res://scenes/bosses/ink_archivist_ch1.tscn")
	plan.authority_pool = [
		load("res://resources/authorities/revive.tres") as AuthorityData,
		load("res://resources/authorities/rewrite.tres") as AuthorityData,
	]
	var directory := DirAccess.open("res://resources")
	if directory != null and not directory.dir_exists("chapters"):
		directory.make_dir("chapters")
	var error := ResourceSaver.save(plan, OUT)
	print("CH1 PLAN ", "saved" if error == OK else "error %d" % error)
	quit(0 if error == OK else 1)
