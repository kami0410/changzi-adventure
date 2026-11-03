extends RefCounted

const RESOURCE_PATHS: Array[String] = [
	"res://resources/enemies/ink_hound.tres",
	"res://resources/enemies/scribe_bug.tres",
	"res://resources/enemies/blank_man.tres",
	"res://resources/enemies/hanging_scribe.tres",
	"res://resources/enemies/amnesiac_echo.tres",
	"res://resources/enemies/typo_beast.tres",
	"res://resources/enemies/ink_bomber.tres",
	"res://resources/enemies/choir_summoner.tres",
	"res://resources/enemies/mirror_sniper.tres",
	"res://resources/enemies/page_swarm.tres",
]

const SCENE_PATHS: Array[String] = [
	"res://scenes/enemies/ink_hound.tscn",
	"res://scenes/enemies/scribe_bug.tscn",
	"res://scenes/enemies/blank_man.tscn",
	"res://scenes/enemies/hanging_scribe.tscn",
	"res://scenes/enemies/echo_enemy.tscn",
	"res://scenes/enemies/typo_beast.tscn",
	"res://scenes/enemies/ink_bomber.tscn",
	"res://scenes/enemies/choir_summoner.tscn",
	"res://scenes/enemies/mirror_sniper.tscn",
	"res://scenes/enemies/page_swarm.tscn",
	"res://scenes/enemies/summoned_page.tscn",
]


func run(t: Callable) -> void:
	_test_resources(t)
	_test_scenes(t)
	_test_damage_and_death(t)
	_test_target_aggro(t)
	_test_state_api(t)


func _test_resources(t: Callable) -> void:
	for path in RESOURCE_PATHS:
		var data := load(path) as EnemyData
		var file_name := path.get_file()
		t.call(data != null, true, "enemy_resource_load_%s" % file_name)
		if data == null:
			continue
		t.call(data.id != &"", true, "enemy_resource_id_%s" % file_name)
		t.call(data.max_health > 0, true, "enemy_resource_health_%s" % file_name)
		t.call(data.speed > 0.0, true, "enemy_resource_speed_%s" % file_name)
		t.call(data.contact_damage > 0, true, "enemy_resource_damage_%s" % file_name)
		t.call(data.behavior != &"", true, "enemy_resource_behavior_%s" % file_name)


func _test_scenes(t: Callable) -> void:
	for path in SCENE_PATHS:
		var packed := load(path) as PackedScene
		var file_name := path.get_file()
		t.call(packed != null, true, "enemy_scene_load_%s" % file_name)
		if packed == null:
			continue
		var enemy := packed.instantiate() as Enemy
		t.call(enemy != null, true, "enemy_scene_instance_%s" % file_name)
		if enemy == null:
			continue
		t.call(enemy.data != null, true, "enemy_scene_data_%s" % file_name)
		t.call(enemy.health, enemy.data.max_health, "enemy_scene_health_%s" % file_name)
		t.call(enemy.state, &"idle", "enemy_scene_idle_%s" % file_name)
		t.call(enemy.get_node_or_null("Body") is Polygon2D, true, "enemy_scene_body_%s" % file_name)
		t.call(enemy.get_node_or_null("CollisionShape2D") is CollisionShape2D, true, "enemy_scene_shape_%s" % file_name)
		var bar := enemy.get_node_or_null("HealthBar") as ProgressBar
		t.call(bar != null, true, "enemy_scene_health_bar_%s" % file_name)
		if bar != null:
			t.call(int(bar.value), enemy.data.max_health, "enemy_health_bar_value_%s" % file_name)
		enemy.free()


func _test_damage_and_death(t: Callable) -> void:
	var packed := load("res://scenes/enemies/ink_hound.tscn") as PackedScene
	var enemy := packed.instantiate() as Enemy
	var full_health := enemy.data.max_health
	enemy.take_damage(4)
	t.call(enemy.health, full_health - 4, "enemy_take_damage")
	enemy.take_damage(0)
	t.call(enemy.health, full_health - 4, "enemy_zero_damage_ignored")

	var death_count := [0]
	enemy.died.connect(func(_dead_enemy): death_count[0] += 1)
	enemy.take_damage(999)
	t.call(enemy.health, 0, "enemy_health_floor")
	t.call(death_count[0], 1, "enemy_died_once")
	t.call(enemy.state, &"dead", "enemy_dead_state")
	enemy.take_damage(10)
	t.call(death_count[0], 1, "enemy_no_double_death")
	enemy.free()


func _test_target_aggro(t: Callable) -> void:
	var packed := load("res://scenes/enemies/ink_hound.tscn") as PackedScene
	var enemy := packed.instantiate() as Enemy
	var near_target := Node2D.new()
	near_target.position = Vector2(80, 0)
	enemy.set_target(near_target)
	t.call(enemy.target, near_target, "enemy_target_assigned")
	t.call(enemy.state, &"chase", "enemy_set_target_starts_chase")
	enemy.free()
	near_target.free()

	var far_enemy := packed.instantiate() as Enemy
	var far_target := Node2D.new()
	far_target.position = Vector2(5000, 0)
	far_enemy.set_target(far_target)
	t.call(far_enemy.state, &"idle", "enemy_far_target_stays_idle")
	far_enemy.free()
	far_target.free()


func _test_state_api(t: Callable) -> void:
	var packed := load("res://scenes/enemies/scribe_bug.tscn") as PackedScene
	var enemy := packed.instantiate() as Enemy
	enemy.change_state(&"chase")
	t.call(enemy.state, &"chase", "enemy_change_state")
	enemy.change_state(&"idle")
	t.call(enemy.state, &"idle", "enemy_change_state_back")
	enemy.free()
