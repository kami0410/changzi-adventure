extends RefCounted

## Chapter 2+ vertical/shortcut prop pipeline: one-way platforms, collapsing
## platforms, moving platforms/elevators and bench checkpoints. Physics-level
## behaviour (carrying, drop-through, fall guard) is covered by the
## integration suites; this file pins the authored data and state machines.

func run(t: Callable) -> void:
	_test_one_way(t)
	_test_collapsing(t)
	_test_moving(t)
	_test_bench(t)
	_test_player_unchanged(t)


func _test_one_way(t: Callable) -> void:
	var platform := OneWayPlatform.new()
	platform.size = Vector2(192, 16)
	platform.build()
	t.call(platform.collision_layer, 1, "one_way_platform_layer")
	t.call(platform.collision_mask, 0, "one_way_platform_mask")
	t.call(platform.allows_drop_through(), true, "one_way_platform_drop_default")
	var shape := platform.collision_shape()
	t.call(shape != null, true, "one_way_platform_shape")
	if shape != null:
		t.call(shape.one_way_collision, true, "one_way_platform_one_way_collision")
		t.call(shape.one_way_collision_margin, 2.0, "one_way_platform_margin")
		var box := shape.shape as RectangleShape2D
		t.call(box.size, Vector2(192, 16), "one_way_platform_shape_size")
		t.call(shape.position, Vector2(96, 8), "one_way_platform_shape_center")
	platform.drop_through = false
	t.call(platform.allows_drop_through(), false, "one_way_platform_drop_toggle")
	platform.free()

	var tree := Engine.get_main_loop() as SceneTree
	var grouped := OneWayPlatform.new()
	tree.root.add_child(grouped)
	grouped.build()
	t.call(grouped.is_in_group(OneWayPlatform.GROUP), true, "one_way_platform_group")
	t.call(OneWayPlatform.GROUP, &"one_way_platforms", "one_way_platform_group_name")
	tree.root.remove_child(grouped)
	grouped.free()


func _test_collapsing(t: Callable) -> void:
	var platform := CollapsingPlatform.new()
	platform.size = Vector2(128, 16)
	platform.warn_time = 0.5
	platform.fall_time = 0.3
	platform.respawn_time = 1.0
	platform.build()
	var events := [0, 0]
	platform.collapsed.connect(func(_p: CollapsingPlatform) -> void: events[0] += 1)
	platform.restored.connect(func(_p: CollapsingPlatform) -> void: events[1] += 1)

	t.call(platform.state, CollapsingPlatform.State.IDLE, "collapse_starts_idle")
	t.call(platform.is_solid(), true, "collapse_starts_solid")
	t.call(platform.has_collapsed(), false, "collapse_not_collapsed_initially")

	platform.notify_player_standing(true)
	t.call(platform.is_warning(), true, "collapse_standing_starts_warning")
	t.call(platform.warning_progress(), 0.0, "collapse_warning_starts_at_zero")
	platform.advance(0.1)
	t.call(platform.warning_progress() > 0.15 and platform.warning_progress() < 0.25, true,
		"collapse_warning_progress")
	t.call(platform.visual_offset().length() > 0.01, true, "collapse_warning_shakes")

	# Still solid during the warning: the player must be able to run off.
	t.call(platform.is_solid(), true, "collapse_warning_still_solid")

	platform.advance(0.45)
	t.call(platform.state, CollapsingPlatform.State.FALLING, "collapse_falls_after_warning")
	t.call(platform.is_solid(), false, "collapse_collision_off")
	t.call(platform.has_collapsed(), true, "collapse_has_collapsed")
	t.call(events[0], 1, "collapse_emits_once")
	if platform.collision_shape() != null:
		t.call(platform.collision_shape().disabled, true, "collapse_shape_disabled")
	# Re-triggering while it falls must not restart the warning.
	platform.notify_player_standing(true)
	t.call(platform.state, CollapsingPlatform.State.FALLING, "collapse_no_retrigger_while_falling")

	platform.advance(0.1)
	t.call(platform.visual_offset().y > 0.0, true, "collapse_visual_drops")
	platform.advance(0.25)
	t.call(platform.state, CollapsingPlatform.State.GONE, "collapse_hides")
	t.call(platform.visible, false, "collapse_visual_hidden")
	platform.advance(0.5)
	t.call(platform.state, CollapsingPlatform.State.GONE, "collapse_stays_gone")
	platform.advance(0.6)
	t.call(platform.state, CollapsingPlatform.State.IDLE, "collapse_restores")
	t.call(platform.is_solid(), true, "collapse_restored_solid")
	t.call(platform.visible, true, "collapse_restored_visible")
	t.call(events[1] >= 1, true, "collapse_emits_restored")

	# The fall-guard/death path can restore it instantly.
	platform.notify_player_standing(true)
	platform.advance(0.2)
	t.call(platform.is_warning(), true, "collapse_warning_before_reset")
	platform.reset_now()
	t.call(platform.state, CollapsingPlatform.State.IDLE, "collapse_reset_state")
	t.call(platform.is_solid(), true, "collapse_reset_solid")
	platform.free()


func _test_moving(t: Callable) -> void:
	var mover := MovingPlatform.new()
	mover.size = Vector2(120, 16)
	mover.position = Vector2(300, 400)
	mover.travel = Vector2(0, -160)
	mover.speed = 80.0
	mover.pause_time = 0.5
	mover.build()
	t.call(mover.sync_to_physics, true, "moving_platform_syncs_to_physics")
	t.call(mover.collision_layer, 1, "moving_platform_layer")
	t.call(mover.collision_mask, 0, "moving_platform_mask")
	t.call(mover.effective_travel, Vector2(0, -160), "moving_platform_unclamped_without_bounds")
	t.call(mover.bounds_resolved, false, "moving_platform_bounds_unresolved")
	t.call(mover.position_at_time(0.0), Vector2(300, 400), "moving_platform_starts_at_home")
	t.call(mover.position_at_time(0.5), Vector2(300, 400), "moving_platform_pauses_at_home")
	t.call(mover.position_at_time(1.5), Vector2(300, 320), "moving_platform_halfway")
	t.call(mover.position_at_time(2.5), Vector2(300, 240), "moving_platform_reaches_far_end")
	t.call(mover.position_at_time(4.0), Vector2(300, 320), "moving_platform_returns")

	# The room union clamps travel so the platform rectangle can never leave
	# the bounds MDS gives the camera.
	mover.room_bounds = Rect2(0, 0, 2560, 1440)
	mover.recapture_home()
	t.call(mover.bounds_resolved, true, "moving_platform_bounds_resolved")
	t.call(mover.travel_clamped, false, "moving_platform_inside_room")
	mover.position = Vector2(2400, 1400)
	mover.travel = Vector2(200, 100)
	mover.recapture_home()
	t.call(mover.effective_travel, Vector2(40, 24), "moving_platform_clamps_positive")
	t.call(mover.travel_clamped, true, "moving_platform_reports_clamp")
	t.call(mover.outside_bounds, false, "moving_platform_home_inside_room")
	t.call(mover.platform_rect().end.x <= 2560.0 and mover.platform_rect().end.y <= 1440.0,
		true, "moving_platform_stays_in_bounds")
	mover.position = Vector2(40, 40)
	mover.travel = Vector2(-100, -100)
	mover.recapture_home()
	t.call(mover.effective_travel, Vector2(-40, -40), "moving_platform_clamps_negative")

	# A home rectangle already outside the union stays put instead of sliding
	# further out.
	mover.position = Vector2(2520, 100)
	mover.travel = Vector2(200, 0)
	mover.recapture_home()
	t.call(mover.outside_bounds, true, "moving_platform_home_outside_room")
	t.call(mover.effective_travel, Vector2.ZERO, "moving_platform_outside_stays_put")
	mover.free()


func _test_bench(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var bench := BenchCheckpoint.new()
	bench.position = Vector2(100, 560)
	tree.root.add_child(bench)
	bench.build()
	t.call(bench.is_in_group(BenchCheckpoint.GROUP), true, "bench_group")
	t.call(bench.can_use(Vector2(140, 544)), true, "bench_in_range")
	t.call(bench.can_use(Vector2(400, 544)), false, "bench_out_of_range")
	t.call(bench.respawn_position(), Vector2(100, 544), "bench_respawn_on_floor")
	t.call(bench.prompt_label() != null, true, "bench_prompt")
	t.call(bench.prompt_label().visible, false, "bench_prompt_hidden")
	bench.set_player_near(true)
	t.call(bench.prompt_label().visible, true, "bench_prompt_shows")
	t.call(bench.is_player_near(), true, "bench_near_state")
	bench.activate()
	t.call(bench.use_count, 1, "bench_activation_count")
	t.call(bench.is_player_near(), true, "bench_keeps_near_state")
	tree.root.remove_child(bench)
	bench.free()


func _test_player_unchanged(t: Callable) -> void:
	var player := Player.new()
	t.call(player.jump_velocity, -500.0, "vertical_props_player_jump_unchanged")
	t.call(player.gravity, 1350.0, "vertical_props_player_gravity_unchanged")
	t.call(Player.DROP_THROUGH_TIME, 0.3, "vertical_props_drop_window")
	t.call(Player.is_one_way_platform(null), false, "vertical_props_null_not_one_way")
	player.free()
