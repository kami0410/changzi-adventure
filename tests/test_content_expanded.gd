extends RefCounted

## 正式版内容量验收：词/短语/遗物/武器/敌人资源，以及第二生态区场景。

const BIOME_BREATHING_PATH := "res://scenes/levels/biome_breathing.tscn"


func run(t: Callable) -> void:
	var words := _load_all("res://resources/words")
	var words_by_id := _test_words(t, words)
	_test_phrases(t, words_by_id)
	_test_relics(t)
	_test_weapons(t)
	var enemy_ids := _test_enemy_resources(t)
	_test_enemy_scenes(t, enemy_ids)
	_test_biome_breathing(t)


func _test_words(t: Callable, words: Array) -> Dictionary:
	t.call(words.size(), 95, "expanded_word_count")

	var roles := [0, 0, 0]
	var words_by_id: Dictionary = {}
	for resource in words:
		var word := resource as WordData
		t.call(word != null, true, "expanded_word_type")
		if word == null:
			continue
		t.call(word.id != &"", true, "expanded_word_id")
		t.call(word.glyph.is_empty(), false, "expanded_word_glyph_%s" % word.id)
		t.call(word.meaning.is_empty(), false, "expanded_word_meaning_%s" % word.id)
		t.call(word.tags.size() > 0, true, "expanded_word_tags_%s" % word.id)
		t.call(word.power > 0, true, "expanded_word_power_%s" % word.id)
		t.call(word.corruption >= 0, true, "expanded_word_corruption_%s" % word.id)
		t.call(word.components.size() > 0, true, "expanded_word_components_%s" % word.id)
		t.call(word.grammar_role >= 0 and word.grammar_role <= 2, true, "expanded_word_role_%s" % word.id)
		roles[word.grammar_role] += 1
		words_by_id[word.id] = word

	t.call(roles[0], 39, "expanded_noun_count")
	t.call(roles[1], 29, "expanded_verb_count")
	t.call(roles[2], 27, "expanded_modifier_count")
	t.call(words_by_id.size(), 95, "expanded_word_unique_ids")
	return words_by_id


func _test_phrases(t: Callable, words_by_id: Dictionary) -> void:
	var phrases := _load_all("res://resources/phrases")
	t.call(phrases.size(), 16, "expanded_phrase_count")

	var resolver := PhraseResolver.new()
	var phrase_ids: Dictionary = {}
	for resource in phrases:
		var phrase := resource as PhraseData
		t.call(phrase != null, true, "expanded_phrase_type")
		if phrase == null:
			continue
		phrase_ids[phrase.id] = true
		t.call(phrase.id != &"", true, "expanded_phrase_id")
		t.call(phrase.display_name.is_empty(), false, "expanded_phrase_name_%s" % phrase.id)
		t.call(phrase.tags.size() > 0, true, "expanded_phrase_tags_%s" % phrase.id)
		t.call(
			phrase.word_ids.size() >= 2 and phrase.word_ids.size() <= 3,
			true,
			"expanded_phrase_word_count_%s" % phrase.id
		)

		var phrase_words: Array[WordData] = []
		var all_words_exist := true
		for word_id in phrase.word_ids:
			if not words_by_id.has(word_id):
				all_words_exist = false
				continue
			phrase_words.append(words_by_id[word_id])
		t.call(all_words_exist, true, "expanded_phrase_word_ids_%s" % phrase.id)
		t.call(
			phrase_words.size(),
			phrase.word_ids.size(),
			"expanded_phrase_resolved_words_%s" % phrase.id
		)

		var resolved := resolver.resolve(phrase_words)
		t.call(resolved != null, true, "expanded_phrase_legal_grammar_%s" % phrase.id)
		if resolved != null:
			t.call(resolved.display_name.is_empty(), false, "expanded_phrase_display_%s" % phrase.id)
			t.call(resolved.ink_cost > 0, true, "expanded_phrase_ink_%s" % phrase.id)

	t.call(phrase_ids.size(), 16, "expanded_phrase_unique_ids")


func _test_relics(t: Callable) -> void:
	var relics := _load_all("res://resources/relics")
	t.call(relics.size(), 9, "expanded_relic_count")

	var relic_ids: Dictionary = {}
	for resource in relics:
		var relic := resource as RelicData
		t.call(relic != null, true, "expanded_relic_type")
		if relic == null:
			continue
		relic_ids[relic.id] = true
		t.call(relic.id != &"", true, "expanded_relic_id")
		t.call(relic.display_name.is_empty(), false, "expanded_relic_name_%s" % relic.id)
		t.call(relic.tags.size() > 0, true, "expanded_relic_tags_%s" % relic.id)
		t.call(relic.effect_id != &"", true, "expanded_relic_effect_%s" % relic.id)
		t.call(relic.corruption >= 0, true, "expanded_relic_corruption_%s" % relic.id)
		t.call(relic.description.is_empty(), false, "expanded_relic_description_%s" % relic.id)
	t.call(relic_ids.size(), 9, "expanded_relic_unique_ids")


func _test_weapons(t: Callable) -> void:
	var weapons := _load_all("res://resources/weapons")
	t.call(weapons.size(), 12, "expanded_weapon_count")

	var melee_count := 0
	var ranged_count := 0
	var weapon_ids: Dictionary = {}
	for resource in weapons:
		var weapon := resource as WeaponData
		t.call(weapon != null, true, "expanded_weapon_type")
		if weapon == null:
			continue
		weapon_ids[weapon.id] = true
		t.call(weapon.id != &"", true, "expanded_weapon_id")
		t.call(weapon.display_name.is_empty(), false, "expanded_weapon_name_%s" % weapon.id)
		t.call(weapon.damage > 0, true, "expanded_weapon_damage_%s" % weapon.id)
		t.call(weapon.attack_cooldown > 0.0, true, "expanded_weapon_cooldown_%s" % weapon.id)
		t.call(weapon.attack_range > 0.0, true, "expanded_weapon_range_%s" % weapon.id)
		t.call(weapon.tags.size() > 0, true, "expanded_weapon_tags_%s" % weapon.id)
		if weapon.kind == WeaponData.Kind.MELEE:
			melee_count += 1
		elif weapon.kind == WeaponData.Kind.RANGED:
			ranged_count += 1
			t.call(weapon.projectile_speed > 0.0, true, "expanded_weapon_projectile_%s" % weapon.id)

	t.call(melee_count, 6, "expanded_melee_weapon_count")
	t.call(ranged_count, 6, "expanded_ranged_weapon_count")
	t.call(weapon_ids.size(), 12, "expanded_weapon_unique_ids")


func _test_enemy_resources(t: Callable) -> Dictionary:
	var enemies := _load_all("res://resources/enemies")
	t.call(enemies.size(), 24, "expanded_enemy_count")

	var enemy_ids: Dictionary = {}
	var allowed_behaviors := [&"melee", &"ranged", &"charger", &"flyer", &"elite", &"bomber", &"summoner", &"beam", &"swarm", &"ranged_flyer", &"kamikaze", &"pulse", &"leaper"]
	for resource in enemies:
		var data := resource as EnemyData
		t.call(data != null, true, "expanded_enemy_type")
		if data == null:
			continue
		enemy_ids[data.id] = true
		t.call(data.id != &"", true, "expanded_enemy_id")
		t.call(data.display_name.is_empty(), false, "expanded_enemy_name_%s" % data.id)
		t.call(data.max_health > 0, true, "expanded_enemy_health_%s" % data.id)
		t.call(data.speed > 0.0, true, "expanded_enemy_speed_%s" % data.id)
		t.call(data.contact_damage > 0, true, "expanded_enemy_damage_%s" % data.id)
		t.call(
			allowed_behaviors.has(data.behavior),
			true,
			"expanded_enemy_behavior_%s" % data.id
		)
	t.call(enemy_ids.size(), 24, "expanded_enemy_unique_ids")
	return enemy_ids


func _test_enemy_scenes(t: Callable, enemy_ids: Dictionary) -> void:
	var scene_paths := _list_files("res://scenes/enemies", ".tscn")
	t.call(scene_paths.size(), 25, "expanded_enemy_scene_count")

	for path in scene_paths:
		var packed := load(path) as PackedScene
		t.call(packed != null, true, "expanded_enemy_scene_loads_%s" % path.get_file())
		if packed == null:
			continue
		var enemy := packed.instantiate() as Enemy
		t.call(enemy != null, true, "expanded_enemy_scene_is_enemy_%s" % path.get_file())
		if enemy == null:
			continue
		t.call(enemy.data != null, true, "expanded_enemy_scene_data_%s" % path.get_file())
		if enemy.data != null:
			t.call(
				enemy_ids.has(enemy.data.id),
				true,
				"expanded_enemy_scene_data_id_%s" % path.get_file()
			)
		t.call(enemy.collision_layer, 2, "expanded_enemy_scene_layer_%s" % path.get_file())
		t.call(enemy.collision_mask, 1, "expanded_enemy_scene_mask_%s" % path.get_file())
		t.call(
			enemy.get_node_or_null("Body") is Polygon2D,
			true,
			"expanded_enemy_scene_body_%s" % path.get_file()
		)
		t.call(
			enemy.get_node_or_null("CollisionShape2D") is CollisionShape2D,
			true,
			"expanded_enemy_scene_shape_%s" % path.get_file()
		)
		t.call(
			enemy.get_node_or_null("HealthBar") is ProgressBar,
			true,
			"expanded_enemy_scene_health_bar_%s" % path.get_file()
		)
		enemy.free()


func _test_biome_breathing(t: Callable) -> void:
	var packed := load(BIOME_BREATHING_PATH) as PackedScene
	t.call(packed != null, true, "biome_breathing_scene_loads")
	if packed == null:
		return

	var biome := packed.instantiate()
	t.call(biome is Node2D, true, "biome_breathing_root_is_node_2d")
	t.call(_count_rooms(biome), 7, "biome_breathing_room_count")

	var ground := _find_node(biome, "Ground")
	t.call(ground is StaticBody2D, true, "biome_breathing_has_ground")
	var platform := _find_node(biome, "Platform")
	t.call(platform is StaticBody2D, true, "biome_breathing_has_platform")
	var spawn := _find_node(biome, "SpawnPoint")
	t.call(spawn is Marker2D, true, "biome_breathing_has_spawn_point")

	var background := _find_node(biome, "Background") as ColorRect
	t.call(background != null, true, "biome_breathing_has_background")
	if background != null:
		t.call(background.offset_right, 12000.0, "biome_breathing_background_width")
		t.call(background.offset_bottom, 720.0, "biome_breathing_background_height")

	var room_ids: Dictionary = {}
	var room_id_valid := true
	for room in _find_rooms(biome):
		if room.room_id == &"":
			room_id_valid = false
		room_ids[room.room_id] = true
	t.call(room_id_valid, true, "biome_breathing_room_ids_set")
	t.call(room_ids.size(), 7, "biome_breathing_room_ids_unique")

	biome.free()


func _load_all(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource = load(path + "/" + file_name)
		if resource != null:
			result.append(resource)
	return result


func _list_files(path: String, suffix: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(suffix):
			result.append(path + "/" + file_name)
	result.sort()
	return result


func _find_node(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node(child, node_name)
		if found != null:
			return found
	return null


func _find_rooms(root: Node) -> Array[ArenaRoom]:
	var result: Array[ArenaRoom] = []
	if root is ArenaRoom:
		result.append(root as ArenaRoom)
	for child in root.get_children():
		result.append_array(_find_rooms(child))
	return result


func _count_rooms(root: Node) -> int:
	return _find_rooms(root).size()
