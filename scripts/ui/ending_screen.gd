class_name EndingScreen
extends Control


func _ready() -> void:
	visible = false
	var button := Button.new()
	button.text = "返回档案馆 [R]"
	button.pressed.connect(func():
		get_tree().paused = false
		Flow.return_to_hub()
		get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")
	)
	$Center/Panel/Margin/VBox.add_child(button)


func show_ending(won: bool, reward: int) -> void:
	var ending := {"title": "史官归位" if won else "记录中断", "body": "名册重新对齐。更深处的污染仍在低语。" if won else "污染吞没了这一页，但记忆碎片已经被写下。"}
	show_campaign_ending(won, reward, ending, 0, 0)


func show_campaign_ending(won: bool, reward: int, ending: Dictionary, records: int, kills: int, demo: bool = false) -> void:
	var title := get_node_or_null("Center/Panel/Margin/VBox/Title") as Label
	var body := get_node_or_null("Center/Panel/Margin/VBox/Body") as Label
	var reward_label := get_node_or_null("Center/Panel/Margin/VBox/Reward") as Label
	if title != null:
		title.text = String(ending.get("title", "史官归位" if won else "记录中断"))
	if body != null:
		body.text = String(ending.get("body", "")) + "\n\n读过 %d 座残碑，击败 %d 个敌人。" % [records, kills]
	if reward_label != null:
		reward_label.text = "记忆碎片 +%d" % reward
	visible = true
	var button := $Center/Panel/Margin/VBox.get_child(-1) as Button
	if button != null and button.is_inside_tree():
		button.grab_focus()
