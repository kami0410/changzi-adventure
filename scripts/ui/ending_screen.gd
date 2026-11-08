class_name EndingScreen
extends Control

var _hint: Label = null
var _return_button: Button = null
var _run_seed: int = 0
var _won := false


func _ready() -> void:
	visible = false
	_hint = find_child("Hint", true, false) as Label
	_return_button = Button.new()
	_return_button.pressed.connect(func():
		get_tree().paused = false
		Flow.return_to_hub()
		get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")
	)
	$Center/Panel/Margin/VBox.add_child(_return_button)
	_refresh_prompts()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_refresh_prompts):
		flow.keybinds_changed.connect(_refresh_prompts)


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


## The ending may sit on screen while the player picks up the other device.
func _refresh_prompts() -> void:
	# The hint can be refreshed before _ready in tests/tools; resolve it then.
	if _hint == null:
		_hint = find_child("Hint", true, false) as Label
	var flow := _flow_node()
	var key := flow.prompt_label(&"restart") if flow != null else GameFlow.key_label(&"restart")
	if _hint != null:
		var template := EndingHintData.pick(_run_seed, _won)
		if template.is_empty():
			_hint.text = "按 %s 回到最后的档案馆" % key
		else:
			_hint.text = EndingHintData.format_hint(template, key)
	if _return_button != null:
		_return_button.text = "返回档案馆 [%s]" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompts()


func show_ending(won: bool, reward: int) -> void:
	var ending := {"title": "史官归位" if won else "记录中断", "body": "名册重新对齐。更深处的污染仍在低语。" if won else "污染吞没了这一页，但记忆碎片已经被写下。"}
	show_campaign_ending(won, reward, ending, 0, 0)


func show_campaign_ending(won: bool, reward: int, ending: Dictionary, records: int, kills: int, demo: bool = false, run_seed: int = 0) -> void:
	_won = won
	_run_seed = run_seed
	# A won campaign closes on the resolved 名册 motif.
	var audio := get_node_or_null("/root/Audio")
	if won and audio != null and audio.has_method("play_music"):
		audio.call("play_music", "res://assets/audio/music/ending.ogg", 1.5)
	var title := get_node_or_null("Center/Panel/Margin/VBox/Title") as Label
	var body := get_node_or_null("Center/Panel/Margin/VBox/Body") as Label
	var echoes := get_node_or_null("Center/Panel/Margin/VBox/Echoes") as Label
	var reward_label := get_node_or_null("Center/Panel/Margin/VBox/Reward") as Label
	if title != null:
		title.text = String(ending.get("title", "史官归位" if won else "记录中断"))
	if body != null:
		body.text = String(ending.get("body", "")) + "\n\n读过 %d 座残碑，击败 %d 个敌人。" % [records, kills]
	if echoes != null:
		# 余味只属于达成的结局；旧调用 / 未知结局没有 id，整块留空。
		var echo_text := EndingEchoData.display_text(StringName(ending.get("id", &"")))
		echoes.text = echo_text
		echoes.visible = not echo_text.is_empty()
	if reward_label != null:
		reward_label.text = "记忆碎片 +%d" % reward
	_refresh_prompts()
	visible = true
	var button := $Center/Panel/Margin/VBox.get_child(-1) as Button
	if button != null and button.is_inside_tree():
		button.grab_focus()
