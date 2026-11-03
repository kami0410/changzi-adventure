extends RefCounted

class StubTarget:
	extends Node2D
	var damage_taken: int = 0
	var disabled_slot: int = -1

	func take_damage(amount: int) -> void:
		damage_taken += amount

	func disable_phrase_slot(slot: int) -> void:
		disabled_slot = slot


func run(t: Callable) -> void:
	var data := EnemyData.new()
	data.id = &"ink_archivist"
	data.max_health = 120
	data.contact_damage = 10
	data.speed = 60.0

	var boss := InkArchivist.new()
	boss.data = data
	t.call(boss.health, 120, "boss_health_from_data")

	var phases: Array = []
	boss.phase_changed.connect(func(phase): phases.append(phase))
	boss.take_damage(41)
	t.call(boss.health, 79, "boss_health_after_hit")
	t.call(boss.phase, 2, "boss_phase_2")
	t.call(phases, [2], "boss_phase_signal")
	boss.take_damage(40)
	t.call(boss.phase, 3, "boss_phase_3")
	t.call(phases, [2, 3], "boss_phase_signal_once_per_change")

	var target := StubTarget.new()
	boss.target = target
	boss.phase = 3
	boss.attack_cycle = 2
	boss._perform_attack()
	t.call(boss.attack_cycle, 3, "boss_attack_cycle")
	t.call(target.disabled_slot, 1, "boss_rewrite_disables_slot")

	var resource = load("res://resources/bosses/ink_archivist.tres")
	t.call(resource is EnemyData, true, "boss_resource_loads")
	var scene = load("res://scenes/bosses/ink_archivist.tscn")
	t.call(scene != null, true, "boss_scene_loads")

	target.free()
	boss.free()
