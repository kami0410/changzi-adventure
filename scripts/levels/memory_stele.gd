class_name MemoryStele
extends Area2D

signal claimed(stele: MemoryStele, reward: Dictionary)

const TEXTURE := preload("res://assets/sprites/props/stele.png")

@export var stele_id: StringName = &""
@export var prompt_text: String = "按 E 读取残碑"
@export var reward_kind: StringName = &"relic"

var is_claimed: bool = false
var _time: float = 0.0

@onready var prompt: Label = get_node_or_null("Prompt") as Label

func _ready() -> void:
	add_to_group("memory_steles")
	if prompt != null:
		prompt.text = prompt_text
		prompt.hide()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func set_player_near(near: bool) -> void:
	if prompt != null and not is_claimed:
		prompt.visible = near


func can_claim() -> bool:
	return not is_claimed

func claim() -> Dictionary:
	if is_claimed:
		return {}
	is_claimed = true
	if prompt != null:
		prompt.hide()
	var reward := _roll_reward()
	claimed.emit(self, reward)
	queue_free()
	return reward

func _roll_reward() -> Dictionary:
	var chapter_demo := String(stele_id).begins_with("ch1")
	var pool: Array[Resource] = []
	for entry in (ContentLibrary.DEMO_RELICS if chapter_demo else ContentLibrary.RELICS):
		pool.append(entry)
	if reward_kind == &"word":
		pool.clear()
		if chapter_demo:
			for word in RunLoot.demo_word_pool():
				pool.append(word)
		else:
			for entry in ContentLibrary.WORDS:
				pool.append(entry)
	if pool.is_empty():
		return {"kind": &"rest", "title": "残碑", "description": "碑文已经模糊。"}
	var resource: Resource = pool[randi() % pool.size()]
	var kind := &"word" if resource is WordData else &"relic"
	var title := RunLoot.word_label(resource as WordData) if resource is WordData else (resource as RelicData).display_name
	return {"kind": kind, "resource": resource, "title": "残碑 · " + title,
		"description": "碑上刻着一段不属于你的记忆。"}

func _draw() -> void:
	draw_texture(TEXTURE, Vector2(-24, -64))
	if not is_claimed:
		var glow := Color("79d8c8")
		var radius := 18.0 + sin(_time * 2.4) * 2.0
		for index in 16:
			var angle := index * TAU / 16.0
			draw_rect(Rect2(cos(angle) * radius - 1.0, -42.0 + sin(angle) * radius - 1.0, 2.0, 2.0), Color(glow, 0.5))
