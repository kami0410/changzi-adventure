class_name HUD
extends CanvasLayer

const EMPTY_SLOT := "—"

const SLOT_STYLES := {
	&"common": preload("res://resources/ui/slot_common.tres"),
	&"rare": preload("res://resources/ui/slot_rare.tres"),
	&"epic": preload("res://resources/ui/slot_epic.tres"),
	&"legendary": preload("res://resources/ui/slot_legendary.tres"),
	&"corrupt": preload("res://resources/ui/slot_corrupt.tres"),
}

var health_label: Label = null
var ink_label: Label = null
var corruption_label: Label = null
var relic_label: Label = null
var health_bar: ProgressBar = null
var ink_bar: ProgressBar = null
var corruption_bar: ProgressBar = null
var region_label: Label = null
var score_label: Label = null
var message_label: Label = null
var boss_panel: PanelContainer = null
var boss_name_label: Label = null
var boss_bar: ProgressBar = null
var weapon_card_1: PanelContainer = null
var weapon_card_2: PanelContainer = null
var phrase_card_1: PanelContainer = null
var phrase_card_2: PanelContainer = null
var weapon_value_1: Label = null
var weapon_value_2: Label = null
var phrase_value_1: Label = null
var phrase_value_2: Label = null

var _run: RunState = null
var _pending_message: String = ""
var _toast: Tween
var _active_weapon: int = 0
var _phrase_identities: Dictionary = {}
var _frenzy_seconds: int = 0


func set_objective(text: String) -> void:
	(find_child("Objective", true, false) as Label).text = text


func set_progress(cleared: int, total: int) -> void:
	(find_child("Progress", true, false) as Label).text = "档案  %d / %d" % [cleared, total]


## The authority slot shows the run-long rule and whether its one use is left.
func set_authority(authority_name: String, available: bool) -> void:
	_ensure_nodes()
	var label := find_child("Authority", true, false) as Label
	if label == null:
		return
	label.text = "权柄  %s · %s" % [authority_name, "可用" if available else "已用"]
	label.add_theme_color_override("font_color", Color("e6c87a") if available else Color("6f7f86"))


func set_active_weapon(slot: int) -> void:
	_active_weapon = slot
	_ensure_nodes()
	var flow := _flow_node()
	var attack := flow.prompt_label(&"attack") if flow != null else "J"
	for i in 2:
		var label := find_child("WeaponCaption%d" % (i + 1), true, false) as Label
		var switch_action := &"weapon_1" if i == 0 else &"weapon_2"
		var switch_label := flow.prompt_label(switch_action) if flow != null else str(i + 1)
		label.text = "[%d] %s" % [i + 1, "手持，%s 攻击" % attack if i == slot else "按 %s 切换" % switch_label]
		label.add_theme_color_override("font_color", Color("f3d79c") if i == slot else Color("7f999c"))


## HUD footer follows the last device: keyboard hints on keys, face buttons
## and sticks after a controller press.
const CONTROLS_HINT_SECONDS := 25.0
const CONTROLS_HINT_FADED := 0.3

func _refresh_controls_hint() -> void:
	var hint := find_child("ControlsHint", true, false) as Label
	if hint == null:
		return
	var flow := _flow_node()
	if flow == null:
		return
	var gamepad := flow.using_gamepad
	var move := "左摇杆" if gamepad else "%s / %s" % [
		flow.prompt_label(&"move_left"), flow.prompt_label(&"move_right")]
	var parts: Array[String] = [move + " 移动"]
	for entry in [[&"jump", "跳跃"], [&"attack", "攻击"], [&"dodge", "翻滚"]]:
		parts.append("%s %s" % [flow.prompt_label(StringName(entry[0])), String(entry[1])])
	parts.append("%s / %s 言灵" % [flow.prompt_label(&"cast_1"), flow.prompt_label(&"cast_2")])
	if gamepad:
		parts.append("%s 造句" % flow.prompt_label(&"codex"))
		parts.append("%s 背包" % flow.prompt_label(&"inventory"))
	else:
		parts.append("%s 背包" % flow.prompt_label(&"inventory"))
		parts.append("%s 造句" % flow.prompt_label(&"codex"))
		parts.append("%s 说明" % flow.prompt_label(&"help"))
		parts.append("%s 地图" % flow.prompt_label(&"map"))
	parts.append("%s 暂停" % flow.prompt_label(&"pause"))
	hint.text = "    ".join(parts)
	_fade_controls_hint(hint)


## The footer is a reminder, not permanent chrome: full strength for a while
## after it changes (start, device or keybind change), then it settles to a
## faint line so it stops competing with the game.
var _hint_tween: Tween

func _fade_controls_hint(hint: Label) -> void:
	hint.modulate.a = 1.0
	if _hint_tween != null:
		_hint_tween.kill()
	if not hint.is_inside_tree():
		return
	_hint_tween = hint.create_tween()
	_hint_tween.tween_interval(CONTROLS_HINT_SECONDS)
	_hint_tween.tween_property(hint, "modulate:a", CONTROLS_HINT_FADED, 1.5)


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_controls_hint()
	set_active_weapon(_active_weapon)


func _on_keybinds_changed() -> void:
	_refresh_controls_hint()
	set_active_weapon(_active_weapon)


## During the 30-second corruption frenzy the corruption line becomes the
## countdown; seconds <= 0 restores the normal pollution readout.
func set_frenzy(seconds: int) -> void:
	_ensure_nodes()
	_frenzy_seconds = maxi(seconds, 0)
	if corruption_label == null:
		return
	if seconds <= 0:
		var value := _run.corruption if _run != null else 0
		var tier_name := _run.corruption_tier_name() if _run != null else "平静"
		corruption_label.text = "污染 %d/100 · %s" % [value, tier_name]
		corruption_label.add_theme_color_override("font_color", _corruption_color())
		return
	corruption_label.text = "污染 100/100 · 发狂 %d 秒" % seconds
	corruption_label.add_theme_color_override("font_color", Color("f0a0ff"))


func set_phrase_status(slot: int, remaining: float, _total: float, cost: int, available: bool) -> void:
	var label := find_child("PhraseStatus%d" % (slot + 1), true, false) as Label
	if label == null:
		return
	var identity: String = _phrase_identities.get(slot, "")
	label.text = "冷却 %.1f 秒" % remaining if remaining > 0 else ("%s，%d 墨" % [identity, cost] if available and identity != "" else ("就绪，%d 墨" % cost if available else "墨不够，要 %d" % cost))
	label.add_theme_color_override("font_color", Color("74d9c3") if available else Color("d4aa8d"))


func set_phrase_identity(slot: int, identity: String, color: Color) -> void:
	_phrase_identities[slot] = identity
	var value := find_child("PhraseValue%d" % (slot + 1), true, false) as Label
	if value != null:
		value.add_theme_color_override("font_color", color)
	var status := find_child("PhraseStatus%d" % (slot + 1), true, false) as Label
	if status != null and identity != "":
		status.text = identity


func _init() -> void:
	add_to_group(&"hud")


func _ready() -> void:
	_ensure_nodes()
	var profile := _profile()
	apply_text_scale(profile.text_scale if profile != null else 16)
	if _run != null:
		_refresh()
	_refresh_controls_hint()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_on_keybinds_changed):
		flow.keybinds_changed.connect(_on_keybinds_changed)
	if OS.has_feature("mobile"):
		var slots := find_child("BottomSlots", true, false) as Control
		slots.offset_top = -212
		slots.offset_bottom = -134
		(find_child("ControlsHint", true, false) as Control).hide()
	if _pending_message != "" and message_label != null:
		message_label.text = _pending_message


## Main info (HP/ink/corruption/objective/progress/phrase slots) stays at the
## chosen 12/16/20 px; auxiliary labels stay 4 px smaller.
func apply_text_scale(size: int) -> void:
	_ensure_nodes()
	var main_size := clampi(size, 12, 20)
	var aux_size := maxi(12, main_size - 4)
	for node_name in ["Health", "Ink", "Corruption", "Objective", "Progress", "Region", "Score", "BossName", "Authority", "WeaponValue1", "WeaponValue2", "PhraseValue1", "PhraseValue2"]:
		var label := find_child(node_name, true, false) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", main_size)
	for node_name in ["Relics", "WeaponCaption1", "WeaponCaption2", "PhraseCaption1", "PhraseCaption2", "Message", "ControlsHint"]:
		var label := find_child(node_name, true, false) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", aux_size)


func get_main_font_size() -> int:
	var label := find_child("Health", true, false) as Label
	return label.get_theme_font_size("font_size") if label != null else 0


func _profile() -> Profile:
	var flow := _flow_node()
	return flow.profile if flow != null else null


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func bind_run_state(run: RunState) -> void:
	if _run == run:
		_refresh()
		return

	_unbind()
	_run = run
	if _run == null:
		_refresh()
		return

	_run.health_changed.connect(_on_health_changed)
	_run.ink_changed.connect(_on_ink_changed)
	_run.corruption_changed.connect(_on_corruption_changed)
	_connect_inventory(_run.inventory)
	_refresh()


func show_message(text: String, icon: Texture2D = null) -> void:
	_pending_message = text
	_ensure_nodes()
	if message_label != null:
		message_label.text = text
		message_label.modulate.a = 1.0
		_place_message_icon(text, icon)
		if _toast != null:
			_toast.kill()
		if is_inside_tree():
			_toast = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
			_toast.tween_interval(3.0)
			_toast.tween_property(message_label, "modulate:a", 0.0, 0.4)


## Optional 32 px icon (encounter affixes) just left of the centred message.
func _place_message_icon(text: String, icon: Texture2D) -> void:
	var holder := message_label.get_node_or_null("Icon") as TextureRect
	if icon == null:
		if holder != null:
			holder.visible = false
		return
	if holder == null:
		holder = TextureRect.new()
		holder.name = "Icon"
		holder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		message_label.add_child(holder)
	holder.texture = icon
	holder.visible = true
	holder.size = Vector2(32, 32)
	var font := message_label.get_theme_font("font")
	var font_size := message_label.get_theme_font_size("font_size")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if font != null else 0.0
	holder.position = Vector2((message_label.size.x - width) * 0.5 - 40.0, (message_label.size.y - 32.0) * 0.5)


func show_boss(title: String, current: int, maximum: int) -> void:
	_ensure_nodes()
	if boss_name_label != null:
		boss_name_label.text = title
	if boss_panel != null:
		boss_panel.visible = true
	update_boss(current, maximum)


func update_boss(current: int, maximum: int) -> void:
	_ensure_nodes()
	if boss_bar == null:
		return
	boss_bar.max_value = maxi(maximum, 1)
	boss_bar.value = clampi(current, 0, maxi(maximum, 1))


func hide_boss() -> void:
	_ensure_nodes()
	if boss_panel != null:
		boss_panel.visible = false


func set_region(region_name: String) -> void:
	_ensure_nodes()
	if region_label != null:
		region_label.text = region_name


# Compatibility shim for the legacy main scene, which drives the HUD directly.
func set_stats(hp: int, max_hp: int, score: int, kills: int, pages: int = 0) -> void:
	_ensure_nodes()
	if health_label == null:
		return
	health_label.text = _health_text(hp, max_hp)
	_apply_bar(health_bar, hp, max_hp)
	if score_label != null:
		score_label.text = "残页 %d    击败 %d" % [pages, kills]


func get_health_text() -> String:
	_ensure_nodes()
	return health_label.text if health_label != null else ""


func get_ink_text() -> String:
	_ensure_nodes()
	return ink_label.text if ink_label != null else ""


func get_corruption_text() -> String:
	_ensure_nodes()
	return corruption_label.text if corruption_label != null else ""


func get_weapons_text() -> String:
	_ensure_nodes()
	if weapon_value_1 == null or weapon_value_2 == null:
		return ""
	return "武器  1: %s   2: %s" % [weapon_value_1.text, weapon_value_2.text]


func get_phrases_text() -> String:
	_ensure_nodes()
	if phrase_value_1 == null or phrase_value_2 == null:
		return ""
	return "短语  1: %s   2: %s" % [phrase_value_1.text, phrase_value_2.text]


func get_message_text() -> String:
	_ensure_nodes()
	return message_label.text if message_label != null else ""


func get_region_text() -> String:
	_ensure_nodes()
	return region_label.text if region_label != null else ""


func get_boss_name_text() -> String:
	_ensure_nodes()
	return boss_name_label.text if boss_name_label != null else ""


func get_boss_health() -> int:
	_ensure_nodes()
	return int(boss_bar.value) if boss_bar != null else 0


func is_boss_visible() -> bool:
	_ensure_nodes()
	return boss_panel.visible if boss_panel != null else false


func _ensure_nodes() -> void:
	if health_label == null:
		health_label = find_child("Health", true, false) as Label
	if ink_label == null:
		ink_label = find_child("Ink", true, false) as Label
	if corruption_label == null:
		corruption_label = find_child("Corruption", true, false) as Label
	if relic_label == null:
		relic_label = find_child("Relics", true, false) as Label
	if health_bar == null:
		health_bar = find_child("HealthBar", true, false) as ProgressBar
	if ink_bar == null:
		ink_bar = find_child("InkBar", true, false) as ProgressBar
	if corruption_bar == null:
		corruption_bar = find_child("CorruptionBar", true, false) as ProgressBar
	if region_label == null:
		region_label = find_child("Region", true, false) as Label
	if score_label == null:
		score_label = find_child("Score", true, false) as Label
	if message_label == null:
		message_label = find_child("Message", true, false) as Label
	if boss_panel == null:
		boss_panel = find_child("BossPanel", true, false) as PanelContainer
	if boss_name_label == null:
		boss_name_label = find_child("BossName", true, false) as Label
	if boss_bar == null:
		boss_bar = find_child("BossBar", true, false) as ProgressBar
	if weapon_card_1 == null:
		weapon_card_1 = find_child("WeaponCard1", true, false) as PanelContainer
	if weapon_card_2 == null:
		weapon_card_2 = find_child("WeaponCard2", true, false) as PanelContainer
	if phrase_card_1 == null:
		phrase_card_1 = find_child("PhraseCard1", true, false) as PanelContainer
	if phrase_card_2 == null:
		phrase_card_2 = find_child("PhraseCard2", true, false) as PanelContainer
	if weapon_value_1 == null:
		weapon_value_1 = find_child("WeaponValue1", true, false) as Label
	if weapon_value_2 == null:
		weapon_value_2 = find_child("WeaponValue2", true, false) as Label
	if phrase_value_1 == null:
		phrase_value_1 = find_child("PhraseValue1", true, false) as Label
	if phrase_value_2 == null:
		phrase_value_2 = find_child("PhraseValue2", true, false) as Label


func _unbind() -> void:
	if _run == null:
		return
	if _run.health_changed.is_connected(_on_health_changed):
		_run.health_changed.disconnect(_on_health_changed)
	if _run.ink_changed.is_connected(_on_ink_changed):
		_run.ink_changed.disconnect(_on_ink_changed)
	if _run.corruption_changed.is_connected(_on_corruption_changed):
		_run.corruption_changed.disconnect(_on_corruption_changed)
	var inventory := _run.inventory
	if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	_run = null


func _connect_inventory(inventory: Inventory) -> void:
	if inventory == null:
		return
	if not inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.connect(_on_inventory_changed)


func _refresh() -> void:
	_ensure_nodes()
	if health_label == null:
		return

	if _run == null:
		health_label.text = _health_text(0, 0)
		ink_label.text = _ink_text(0, 0)
		corruption_label.text = "污染 0/100 · 平静"
		_apply_bar(health_bar, 0, 0)
		_apply_bar(ink_bar, 0, 0)
		_apply_bar(corruption_bar, 0, 100)
		_refresh_relics()
		weapon_value_1.text = EMPTY_SLOT
		weapon_value_2.text = EMPTY_SLOT
		phrase_value_1.text = EMPTY_SLOT
		phrase_value_2.text = EMPTY_SLOT
		_apply_slot_style(weapon_card_1, &"common")
		_apply_slot_style(weapon_card_2, &"common")
		_apply_slot_style(phrase_card_1, &"common")
		_apply_slot_style(phrase_card_2, &"common")
		score_label.text = "SCORE 0    KILLS 0"
		return

	_connect_inventory(_run.inventory)
	health_label.text = _health_text(_run.health, _run.max_health)
	ink_label.text = _ink_text(_run.ink, _run.max_ink)
	corruption_label.text = "污染 %d/100 · %s" % [_run.corruption, _run.corruption_tier_name()]
	corruption_label.add_theme_color_override("font_color", _corruption_color())
	if _frenzy_seconds > 0:
		set_frenzy(_frenzy_seconds)
	_apply_bar(health_bar, _run.health, _run.max_health)
	_apply_bar(ink_bar, _run.ink, _run.max_ink)
	_apply_bar(corruption_bar, _run.corruption, 100)
	_refresh_relics()
	_refresh_slots()


func _refresh_slots() -> void:
	var inventory := _run.inventory if _run != null else null
	var weapons: Array[WeaponData] = []
	var phrases: Array[ResolvedPhrase] = []
	if inventory != null:
		weapons = inventory.weapons
		phrases = inventory.phrases

	var weapon_0: WeaponData = weapons[0] if weapons.size() > 0 else null
	var weapon_1: WeaponData = weapons[1] if weapons.size() > 1 else null
	var phrase_0: ResolvedPhrase = phrases[0] if phrases.size() > 0 else null
	var phrase_1: ResolvedPhrase = phrases[1] if phrases.size() > 1 else null

	weapon_value_1.text = _weapon_name(weapon_0)
	weapon_value_2.text = _weapon_name(weapon_1)
	phrase_value_1.text = _phrase_name(phrase_0)
	phrase_value_2.text = _phrase_name(phrase_1)

	_apply_slot_style(weapon_card_1, _weapon_rarity(weapon_0))
	_apply_slot_style(weapon_card_2, _weapon_rarity(weapon_1))
	_apply_slot_style(phrase_card_1, _phrase_rarity(phrase_0))
	_apply_slot_style(phrase_card_2, _phrase_rarity(phrase_1))


func _apply_bar(bar: ProgressBar, current: int, maximum: int) -> void:
	if bar == null:
		return
	bar.max_value = maxi(maximum, 1)
	bar.value = clampi(current, 0, maxi(maximum, 1))


func _apply_slot_style(card: PanelContainer, rarity: StringName) -> void:
	if card == null:
		return
	var style: StyleBox = SLOT_STYLES.get(rarity, SLOT_STYLES[&"common"])
	card.add_theme_stylebox_override("panel", style)


func _weapon_rarity(weapon: WeaponData) -> StringName:
	if weapon == null:
		return &"common"
	for tag in weapon.tags:
		match tag:
			&"legendary", &"epic", &"rare", &"corrupt":
				return tag
	return &"common"


func _phrase_rarity(phrase: ResolvedPhrase) -> StringName:
	if phrase == null:
		return &"common"
	if phrase.unstable:
		return &"corrupt"
	if phrase.tags.has(&"authority"):
		return &"legendary"
	if phrase.tags.has(&"abyss") or phrase.tags.has(&"corruption"):
		return &"epic"
	return &"rare"


func _health_text(current: int, maximum: int) -> String:
	return "HP %d/%d" % [current, maximum]


func _ink_text(current: int, maximum: int) -> String:
	return "墨量 %d/%d" % [current, maximum]


func _weapon_name(weapon: WeaponData) -> String:
	if weapon == null:
		return EMPTY_SLOT
	if weapon.display_name != "":
		return weapon.display_name
	if weapon.id != &"":
		return String(weapon.id)
	return EMPTY_SLOT


func _phrase_name(phrase: ResolvedPhrase) -> String:
	if phrase == null or phrase.display_name == "":
		return EMPTY_SLOT
	return phrase.display_name


func _on_health_changed(current: int, maximum: int) -> void:
	_ensure_nodes()
	if health_label == null:
		return
	health_label.text = _health_text(current, maximum)
	_apply_bar(health_bar, current, maximum)


func _on_ink_changed(value: int) -> void:
	_ensure_nodes()
	if ink_label == null:
		return
	var maximum := _run.max_ink if _run != null else value
	ink_label.text = _ink_text(value, maximum)
	_apply_bar(ink_bar, value, maximum)


func _on_corruption_changed(value: int) -> void:
	_ensure_nodes()
	if corruption_label == null:
		return
	if _frenzy_seconds > 0:
		_apply_bar(corruption_bar, value, 100)
		set_frenzy(_frenzy_seconds)
		return
	var tier_name := _run.corruption_tier_name() if _run != null else "平静"
	corruption_label.text = "污染 %d/100 · %s" % [value, tier_name]
	corruption_label.add_theme_color_override("font_color", _corruption_color())
	_apply_bar(corruption_bar, value, 100)


func _corruption_color() -> Color:
	var tier := _run.corruption_tier() if _run != null else 0
	match tier:
		1: return Color("b9a6d8")
		2: return Color("b287e0")
		3: return Color("c58cf0")
		4: return Color("f0a0ff")
	return Color(0.62, 0.64, 0.64)


## At-a-glance relic status under the bars; the full effect text lives in the
## tooltip and the inventory page.
func _refresh_relics() -> void:
	if relic_label == null:
		return
	var relics: Array[RelicData] = []
	if _run != null:
		relics = _run.inventory.relics
	if relics.is_empty():
		relic_label.text = "遗物 0 · 尚未获得"
		relic_label.add_theme_color_override("font_color", Color(0.62, 0.64, 0.64))
		relic_label.tooltip_text = ""
		return
	var names: Array[String] = []
	var details: Array[String] = []
	for relic in relics:
		if relic == null:
			continue
		names.append(relic.display_name)
		details.append("%s：%s" % [relic.display_name, RelicEffects.describe(relic.effect_id)])
	relic_label.text = "遗物 %d · %s" % [names.size(), " · ".join(names)]
	relic_label.tooltip_text = "\n".join(details)
	relic_label.add_theme_color_override("font_color", Color("d8b56a"))


func _on_inventory_changed() -> void:
	_refresh()
