extends RefCounted

## Called elevators: rest at a stop, come when called from a panel, ride to
## the other end on interact, and only show panels beside a real floor.


func run(t: Callable) -> void:
	var lift := MovingPlatform.new()
	lift.position = Vector2(1200, 1424)
	lift.size = Vector2(160, 16)
	lift.travel = Vector2(0, -1324)
	lift.call_mode = true
	lift.build()
	t.call(lift.progress, 0.0, "lift_rests_at_home")
	t.call(lift.is_moving(), false, "lift_idle_until_called")
	for i in 120:
		lift.step_called(1.0 / 60.0)
	t.call(lift.position, Vector2(1200, 1424), "lift_does_not_auto_loop")

	# Floor on the left at the bottom only (the top is a ceiling exit).
	var floors: Array[Rect2] = [Rect2(0, 1424, 2560, 16)]
	lift.set_surfaces(floors)
	t.call(lift.has_panel(0), true, "bottom_stop_has_panel")
	t.call(lift.has_panel(1), false, "ceiling_stop_has_no_panel")
	t.call(lift.panel_local(0).y, 1424.0, "panel_on_floor_line")
	t.call(lift.panel_local(0).x < 1200.0, true, "panel_beside_the_shaft")

	# A ledge level with the top stop gets a panel there too.
	var with_ledge: Array[Rect2] = [Rect2(0, 1424, 2560, 16), Rect2(1380, 100, 320, 16)]
	lift.set_surfaces(with_ledge)
	t.call(lift.has_panel(1), true, "top_ledge_gets_panel")
	t.call(lift.panel_local(1).x > 1360.0, true, "top_panel_on_the_ledge_side")

	# Rider presses interact: it travels to the far end and stops there.
	var feet_on_car := Vector2(1280, 1424)
	t.call(lift.is_rider(feet_on_car), true, "rider_detected")
	t.call(lift.try_interact(feet_on_car), true, "rider_interact_used")
	t.call(lift.target_stop, 1, "rider_sends_to_far_end")
	var arrived := [-1]
	lift.arrived.connect(func(stop: int) -> void: arrived[0] = stop)
	var seconds := 0.0
	while lift.is_moving() and seconds < 30.0:
		lift.step_called(1.0 / 60.0)
		seconds += 1.0 / 60.0
	t.call(lift.position, Vector2(1200, 100), "lift_reaches_top")
	t.call(arrived[0], 1, "arrived_signal_far")
	t.call(seconds < 6.0, true, "called_lift_is_fast")

	# Calling from the bottom panel brings it back down.
	var at_panel := lift.panel_local(0)
	t.call(lift.stop_near(at_panel), 0, "player_at_bottom_panel")
	t.call(lift.try_interact(at_panel), true, "panel_interact_used")
	t.call(lift.target_stop, 0, "panel_calls_to_its_stop")
	lift.step_called(0.5)
	t.call(lift.is_moving(), true, "lift_moving_after_call")
	# A rider can reverse it mid-way.
	var mid_feet := Vector2(1260, lift.position.y)
	lift.try_interact(mid_feet)
	t.call(lift.target_stop, 1, "rider_reverses_mid_way")

	# Far from everything: not handled, so other interactions still run.
	t.call(lift.try_interact(Vector2(100, 1424)), false, "far_press_not_used")

	# Restart (death / reload) homes it.
	lift.restart()
	t.call(lift.progress, 0.0, "restart_homes_lift")
	t.call(lift.target_stop, 0, "restart_resets_target")

	# Auto mode lifts are untouched by interact.
	var ferry := MovingPlatform.new()
	ferry.build()
	t.call(ferry.try_interact(Vector2.ZERO), false, "auto_lift_ignores_interact")
	lift.free()
	ferry.free()
