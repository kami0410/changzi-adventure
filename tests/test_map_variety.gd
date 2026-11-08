extends RefCounted

## Per-run variety: Chapter 1 platform layouts and encounter variation are
## seeded by the run, stable on reload, and stay inside the movement budget.

const ROOM_SCENE := "res://scenes/mds/ch1_02.tscn"
const POOL: Array[StringName] = [&"ink_bomber", &"scribe_bug", &"page_swarm", &"ink_hound", &"blank_man"]


func run(t: Callable) -> void:
	_test_patterns_reachable(t)
	_test_layout_seeded(t)
	_test_variation(t)
	_test_room_variety(t)


func _test_patterns_reachable(t: Callable) -> void:
	var all_ok := true
	for pattern in MDSChapterRoom.PATTERNS:
		for entry in pattern:
			if int(entry[1]) != 1:
				continue
			# An upper platform needs a lower one within 120 px edge to edge.
			var reachable := false
			for other in pattern:
				if int(other[1]) == 0 and absf(float(other[0]) - float(entry[0])) - 240.0 <= 120.0:
					reachable = true
			if not reachable:
				all_ok = false
		for entry in pattern:
			var left := float(entry[0]) - 120.0
			if left < 32.0 or left + 240.0 > 1248.0:
				all_ok = false
	t.call(all_ok, true, "ch1_patterns_reachable_and_inside_room")
	t.call(MDSChapterRoom.PATTERNS.size() >= 8, true, "ch1_has_eight_layouts")


func _test_layout_seeded(t: Callable) -> void:
	var scene := load(ROOM_SCENE) as PackedScene
	var room := scene.instantiate() as MDSChapterRoom
	t.call(room.effective_pattern(), Vector2i(room.platform_pattern % 3, 0), "no_run_keeps_authored_pattern")
	var seen := {}
	for seed_value in range(1, 41):
		room.layout_seed = seed_value
		seen[room.effective_pattern()] = true
	t.call(seen.size() >= 8, true, "runs_get_varied_layouts")
	# Seeded picks never put a platform over an arrival point.
	var clear_ok := true
	for seed_value in range(1, 81):
		room.layout_seed = seed_value
		var pick := room.effective_pattern()
		if not room.pattern_allowed(pick.x, pick.y == 1):
			clear_ok = false
	t.call(clear_ok, true, "seeded_layouts_keep_arrivals_clear")
	var vault_room := scene.instantiate() as MDSChapterRoom
	vault_room.has_vault_gate = true
	var vault_ok := true
	for seed_value in range(1, 81):
		vault_room.layout_seed = seed_value
		var pick := vault_room.effective_pattern()
		for entry in MDSChapterRoom.PATTERNS[pick.x]:
			var x: float = entry[0]
			if pick.y == 1:
				x = MDSChapterRoom.WIDTH - x
			if x + 120.0 > MDSChapterRoom.VAULT_CLEAR.x and x - 120.0 < MDSChapterRoom.VAULT_CLEAR.y:
				vault_ok = false
	t.call(vault_ok, true, "vault_door_never_under_a_platform")
	vault_room.free()
	room.layout_seed = 1234
	var once := room.effective_pattern()
	t.call(room.effective_pattern(), once, "same_run_same_layout")
	room.free()
	var rest := scene.instantiate() as MDSChapterRoom
	rest.kind = MDSChapterRoom.Kind.REST
	rest.layout_seed = 1234
	t.call(rest.effective_pattern(), Vector2i(rest.platform_pattern % 3, 0), "rest_rooms_not_randomised")
	rest.free()


func _test_variation(t: Callable) -> void:
	var first: Array = [&"ink_bomber", &"scribe_bug"]
	var a := EncounterVariation.roll(first, [], POOL, 77, "0/ch1_01/Arena", 0)
	var b := EncounterVariation.roll(first, [], POOL, 77, "0/ch1_01/Arena", 0)
	t.call(a, b, "variation_deterministic_per_run")
	var modifiers := {}
	var extra := 0
	var swaps := 0
	for seed_value in range(1, 201):
		var v := EncounterVariation.roll(first, [], POOL, seed_value, "0/ch1_01/Arena", 2)
		modifiers[v["modifier"]] = true
		var total: int = (v["first"] as Array).size() + (v["rest"] as Array).size()
		if total > 2:
			extra += 1
		if v["first"] != first:
			swaps += 1
		for id in v["first"] + v["rest"]:
			if not POOL.has(StringName(id)):
				t.call(id, "pool id", "variation_uses_chapter_roster")
				return
		if v["modifier"] == EncounterVariation.ELITE:
			t.call(int(v["elite"]) >= 0 and int(v["elite"]) < total, true, "elite_index_valid")
		if v["modifier"] == EncounterVariation.HORDE:
			t.call(total >= 4, true, "horde_adds_two")
	t.call(modifiers.size(), 4, "all_modifiers_roll")
	t.call(extra > 40, true, "extra_enemies_happen")
	t.call(swaps > 40, true, "substitutions_happen")
	var roster := EncounterVariation.roster([[&"a", &"b"], [&"b", &"c"]])
	t.call(roster, [&"a", &"b", &"c"] as Array[StringName], "roster_unique_in_order")
	# Spawn offsets stay on the arena floor.
	var v := EncounterVariation.roll(first, [&"ink_hound", &"blank_man", &"page_swarm"], POOL, 9, "k", 3)
	var inside := true
	for i in 6:
		if absf(EncounterVariation.spawn_offset(v, i)) > 1000.0:
			inside = false
	t.call(inside, true, "spawn_offsets_reasonable")
	t.call(EncounterVariation.modifier_name(EncounterVariation.ELITE), "精英", "modifier_name")


func _test_room_variety(t: Callable) -> void:
	var bounds := Rect2(0, 0, 2560, 1440)
	var floor_surfaces: Array[Rect2] = [Rect2(0, 1424, 2560, 16), Rect2(800, 1344, 320, 16)]
	var avoid: Array[Vector2] = [Vector2(2552, 1334), Vector2(1600, 1334)]
	var shafts: Array[float] = [1280.0]
	t.call(RoomVariety.plan(1, "k", bounds, floor_surfaces, avoid, shafts).is_empty(), true,
		"variety_skips_chapter_1")
	var a := RoomVariety.plan(2, "7|ch2_hub", bounds, floor_surfaces, avoid, shafts)
	var b := RoomVariety.plan(2, "7|ch2_hub", bounds, floor_surfaces, avoid, shafts)
	t.call(a, b, "variety_deterministic")
	t.call(a.size() >= RoomVariety.MIN_COUNT, true, "variety_places_platforms")
	var kinds := {}
	var ok := true
	for chapter in [2, 3, 4]:
		for seed_value in range(1, 30):
			var specs := RoomVariety.plan(chapter, "%d|r" % seed_value, bounds, floor_surfaces, avoid, shafts)
			var placed: Array[Rect2] = floor_surfaces.duplicate()
			for spec in specs:
				kinds["%d:%s" % [chapter, spec["kind"]]] = true
				var rect: Rect2 = spec["rect"]
				# Reachable from some surface below within the jump budget.
				var reachable := false
				for other in placed:
					var rise := other.position.y - rect.position.y
					var gap := maxf(maxf(other.position.x - rect.end.x, rect.position.x - other.end.x), 0.0)
					if rise >= RoomVariety.RISE_MIN - 0.1 and rise <= BigRoomData.MAX_STEP + 0.1 							and gap <= RoomVariety.MAX_GAP + 0.1:
						reachable = true
				if not reachable:
					ok = false
				if absf(rect.get_center().x - 1280.0) < RoomVariety.SHAFT_HALF:
					ok = false
				for point in avoid:
					if absf(clampf(point.x, rect.position.x, rect.end.x) - point.x) < RoomVariety.AVOID_RADIUS.x 							and absf(clampf(point.y, rect.position.y, rect.end.y) - point.y) < RoomVariety.AVOID_RADIUS.y:
						ok = false
				if spec["kind"] != &"moving":
					placed.append(rect)
	t.call(ok, true, "variety_reachable_and_clear")
	t.call(kinds.has("2:one_way") and not kinds.has("2:collapse") and not kinds.has("2:moving"), true,
		"variety_ch2_stone_ledges")
	t.call(kinds.has("3:collapse"), true, "variety_ch3_rotten_planks")
	t.call(kinds.has("4:moving"), true, "variety_ch4_stage_rigs")
