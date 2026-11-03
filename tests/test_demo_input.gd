extends RefCounted

## The demo's input actions must exist and be bound; the behavioural proof is
## tests/integration_ch1_demo.gd, which drives them without teleporting.

const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"jump", &"attack", &"dodge", &"interact",
	&"cast_1", &"cast_2", &"codex", &"pause", &"map", &"settings",
]


func run(t: Callable) -> void:
	for action in ACTIONS:
		t.call(InputMap.has_action(action), true, "input_action_%s" % action)
		if InputMap.has_action(action):
			t.call(InputMap.action_get_events(action).size() > 0, true, "input_bound_%s" % action)
