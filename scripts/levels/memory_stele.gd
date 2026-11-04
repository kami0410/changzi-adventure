class_name MemoryStele
extends Area2D

signal claimed(stele: MemoryStele, reward: Dictionary)

const TEXTURE := preload("res://assets/sprites/props/stele.png")
## One line per stele, picked by id so the same stone always reads the same
## even after a save/resume; the reward roll stays untouched.
const EPITAPHS: Array[String] = [
	"碑上刻着一段不属于你的记忆。",
	"碑面被指腹磨亮，像有人反复读同一行字。",
	"雨水顺着刻痕流下，把名字冲成了另一种写法。",
	"你认得这笔迹，却想不起在哪里用过。",
	"碑背刻着一行小字：读到这里的人，请替我记得。",
	"石缝里卡着半枚印章，印面朝下，像在藏起自己的名字。",
	"碑上只有一道新鲜的划痕，像有人刚把最后一笔刮掉。",
	"你把手按上去，碑面回了一句：别读太快。",
]

@export var stele_id: StringName = &""
@export var prompt_text: String = "按 E 读取残碑"
@export var reward_kind: StringName = &"relic"

var is_claimed: bool = false
var _time: float = 0.0
## Resolved from the tree so a `-s` test runner can precompile this script
## before the Flow autoload is registered.
var _game_flow: GameFlow

@onready var prompt: Label = get_node_or_null("Prompt") as Label

func _ready() -> void:
	add_to_group("memory_steles")
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_prompt()
	if prompt != null:
		prompt.hide()


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompt()


func _on_keybinds_changed() -> void:
	_refresh_prompt()


func _refresh_prompt() -> void:
	if prompt == null:
		return
	var action := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	prompt.text = prompt_text.replace("按 E", "按 %s" % action)

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

static func epitaph_for(id: StringName) -> String:
	if EPITAPHS.is_empty():
		return ""
	return EPITAPHS[posmod(hash(String(id)), EPITAPHS.size())]


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
		"description": epitaph_for(stele_id)}

func _draw() -> void:
	draw_texture(TEXTURE, Vector2(-24, -64))
	if not is_claimed:
		var glow := Color("79d8c8")
		var radius := 18.0 + sin(_time * 2.4) * 2.0
		for index in 16:
			var angle := index * TAU / 16.0
			draw_rect(Rect2(cos(angle) * radius - 1.0, -42.0 + sin(angle) * radius - 1.0, 2.0, 2.0), Color(glow, 0.5))
