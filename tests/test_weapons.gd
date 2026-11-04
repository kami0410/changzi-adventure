extends RefCounted

const WEAPON_PATHS: Array[String] = [
	"res://resources/weapons/broken_page_sword.tres",
	"res://resources/weapons/ink_axe.tres",
	"res://resources/weapons/chain_blade.tres",
	"res://resources/weapons/ink_bolt_gun.tres",
	"res://resources/weapons/talisman_gun.tres",
	"res://resources/weapons/page_shuriken.tres",
]


func run(t: Callable) -> void:
	var weapon_data := WeaponData.new()
	weapon_data.id = &"test_blade"
	weapon_data.display_name = "测试剑"
	weapon_data.damage = 7
	weapon_data.attack_cooldown = 0.5

	var weapon := Weapon.new()
	weapon.data = weapon_data
	t.call(weapon.can_attack(), true, "weapon_initial_can_attack")
	t.call(weapon.try_attack(), true, "weapon_try_attack")
	t.call(weapon.cooldown_left, 0.5, "weapon_cooldown_set")
	t.call(weapon.can_attack(), false, "weapon_cooldown_blocks")
	t.call(weapon.try_attack(), false, "weapon_try_attack_blocked")
	weapon.tick(0.25)
	t.call(weapon.can_attack(), false, "weapon_cooldown_partial")
	weapon.tick(0.25)
	t.call(weapon.can_attack(), true, "weapon_cooldown_ready")
	t.call(weapon.try_attack(), true, "weapon_attack_after_cooldown")

	var damageable := Damageable.new()
	var hit_targets: Array[Node] = []
	weapon.hit.connect(func(target: Node): hit_targets.append(target))
	weapon.apply_hit(damageable)
	t.call(damageable.health, 3, "weapon_apply_hit_damage")
	t.call(hit_targets.size(), 1, "weapon_hit_signal")
	t.call(hit_targets[0] == damageable, true, "weapon_hit_signal_target")
	weapon.apply_hit(null)
	t.call(hit_targets.size(), 1, "weapon_apply_hit_ignores_null")

	var plain := Node.new()
	weapon.apply_hit(plain)
	t.call(hit_targets.size(), 1, "weapon_apply_hit_ignores_plain_node")

	var melee := MeleeWeapon.new()
	melee.data = weapon_data
	t.call(melee is Weapon, true, "melee_is_weapon")
	t.call(melee.try_attack(), true, "melee_try_attack")
	t.call(melee.can_attack(), false, "melee_cooldown_blocks")

	var ranged_data := WeaponData.new()
	ranged_data.kind = WeaponData.Kind.RANGED
	ranged_data.damage = 5
	ranged_data.projectile_speed = 300.0
	var ranged := RangedWeapon.new()
	ranged.data = ranged_data
	t.call(ranged is Weapon, true, "ranged_is_weapon")
	t.call(ranged.try_attack(), true, "ranged_try_attack")

	var projectile := Projectile.new()
	projectile.damage = 4
	projectile.speed = 100.0
	projectile.direction = Vector2.RIGHT
	projectile._physics_process(0.5)
	t.call(projectile.position, Vector2(50.0, 0.0), "projectile_moves")
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(projectile)
	var projectile_target := Damageable.new()
	projectile.hit_target(projectile_target)
	t.call(projectile_target.health, 6, "projectile_damage")
	t.call(projectile.is_queued_for_deletion(), true, "projectile_frees_on_hit")

	var hitbox_scene := load("res://scenes/combat/hitbox.tscn") as PackedScene
	t.call(hitbox_scene != null, true, "hitbox_scene_loads")
	if hitbox_scene != null:
		var hitbox := hitbox_scene.instantiate()
		t.call(hitbox is Area2D, true, "hitbox_is_area2d")
		hitbox.free()

	var projectile_scene := load("res://scenes/combat/projectile.tscn") as PackedScene
	t.call(projectile_scene != null, true, "projectile_scene_loads")
	if projectile_scene != null:
		var projectile_node := projectile_scene.instantiate()
		t.call(projectile_node is Projectile, true, "projectile_scene_has_script")
		t.call(projectile_node is Area2D, true, "projectile_is_area2d")
		projectile_node.free()

	# Run-long authority multiplier (吞噬): scales every hit without touching
	# the shared WeaponData resource or the combo multiplier.
	var scaled_target := Damageable.new()
	scaled_target.max_health = 100
	scaled_target.health = 100
	weapon.damage_dealt_multiplier = 1.5
	weapon.apply_hit(scaled_target)
	t.call(scaled_target.health, 89, "weapon_authority_multiplier_melee")
	weapon.damage_dealt_multiplier = 1.0
	weapon.apply_hit(scaled_target)
	t.call(scaled_target.health, 82, "weapon_authority_multiplier_resets")
	t.call(weapon_data.damage, 7, "weapon_authority_multiplier_leaves_data")

	var ranged_host := Node2D.new()
	ranged.damage_dealt_multiplier = 2.0
	ranged._spawn_projectile(ranged_host, Vector2.RIGHT, 1.0)
	var scaled_projectile: Projectile = null
	for child in ranged_host.get_children():
		if child is Projectile:
			scaled_projectile = child
			break
	t.call(scaled_projectile != null, true, "ranged_authority_projectile_spawned")
	if scaled_projectile != null:
		t.call(scaled_projectile.damage, 10, "ranged_authority_multiplier_damage")
	ranged_host.free()
	scaled_target.free()

	var loaded_weapons := 0
	for path in WEAPON_PATHS:
		var resource := load(path)
		t.call(resource != null, true, "weapon_resource_loads_" + path.get_file())
		if resource is WeaponData:
			loaded_weapons += 1
			var data := resource as WeaponData
			t.call(data.damage > 0, true, "weapon_damage_positive_" + String(data.id))
			t.call(data.display_name != "", true, "weapon_display_name_" + String(data.id))
	t.call(loaded_weapons, 6, "weapon_resource_count")
	t.call(WEAPON_PATHS.size(), 6, "weapon_path_count")

	weapon.free()
	damageable.free()
	plain.free()
	melee.free()
	ranged.free()
	projectile_target.free()
