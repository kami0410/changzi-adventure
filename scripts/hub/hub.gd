class_name Hub
extends Node2D

signal run_requested

const SWORD_ID: StringName = &"broken_page_sword"
const SHOP_STOCK: Array[Dictionary] = [
	{"id": &"jilu", "cost": 12},
	{"id": &"xidi", "cost": 16},
	{"id": &"jinghua", "cost": 20},
	{"id": &"shanhuo", "cost": 16},
	{"id": &"quanbing", "cost": 18},
	{"id": &"lianhuan", "cost": 20},
	{"id": &"guanchuan", "cost": 22},
	{"id": &"yongheng", "cost": 24},
	{"id": &"yueqian", "cost": 24},
	{"id": &"huiwang", "cost": 26},
	{"id": &"shenyuan", "cost": 26},
	{"id": &"zhenming", "cost": 28},
	{"id": &"guize", "cost": 30},
	{"id": &"shemian", "cost": 30},
	{"id": &"hundun", "cost": 32},
	{"id": &"abyssal_bell", "kind": &"relic", "cost": 34},
	{"id": &"clean_ink_lantern", "kind": &"relic", "cost": 28},
	{"id": &"immortal_archive", "kind": &"relic", "cost": 60},
]

@export var demo_starting_fragments: int = 0

var profile: Profile
var shop: Shop

var _words: Dictionary[StringName, WordData] = {}
var _active_npc_id: StringName = &""
## Set while a Hub personal event dialogue is on screen. The event is recorded
## only when its last line is read; closing early leaves it available.
var _pending_event_id := ""
var _owned_profile: Profile
var _initialized := false
var npc_inspire_ui: NPCInspireUI
var help_ui: HelpUI
var archive_ui: ArchiveUI
var settings_menu: SettingsMenu
var tutorial_flow: TutorialFlow
var training_dummy: TrainingDummy
var _tutorial_codex: CodexUI
var _codex_return_focus: Control = null
var _tutorial_run: RunState
var _tutorial_phrase: ResolvedPhrase
var _inspire_key_down := false
var _inspire_pending_npc: StringName = &""
var _npc_effect_used: Dictionary = {}
var _pending_offline_result: Dictionary = {}
var _ai_favors: Dictionary = {}
var _function_free := false
var _function_discount := 0.0
## 托付 with 阿砚 grants one free forge per Hub visit; this flag is per scene,
## so rebuilding the Hub (returning from a run) refreshes the favour.
var _trust_forge_used := false

@onready var player: Player = get_node_or_null("Player") as Player
@onready var portal: HubPortal = get_node_or_null("Portal") as HubPortal
@onready var dialogue_ui: DialogueUI = get_node_or_null("UI/DialogueUI") as DialogueUI
@onready var shop_ui: ShopUI = get_node_or_null("UI/ShopUI") as ShopUI
@onready var fragment_label: Label = get_node_or_null("Overlay/TopLeft/Margin/VBox/FragmentLabel") as Label
@onready var hint_label: Label = get_node_or_null("Overlay/TopLeft/Margin/VBox/Hint") as Label


func _ready() -> void:
	if profile == null and Flow != null and Flow.profile != null:
		profile = Flow.profile
	ensure_ready()
	_connect_prompt_refresh()
	# 闻烬 and 白榆 arrive once the first chapter is cleared (the same gate as
	# the personal events); before that the Hub holds the first three.
	for child in get_children():
		if child is NPC and is_late_npc(child.npc_id):
			var arrived := late_npcs_arrived()
			child.visible = arrived
			child.process_mode = Node.PROCESS_MODE_INHERIT if arrived else Node.PROCESS_MODE_DISABLED
	_apply_background_art()
	$Ground/Visual.hide()
	_build_floor_tiles()
	if not Flow.title_shown_this_session and DisplayServer.get_name() != "headless":
		Flow.title_shown_this_session = true
		var title := TitleScreen.new()
		add_child(title)
		title.started.connect(_on_title_started)
		_connect_title_settings()
	else:
		_play_hub_audio()
		if tutorial_flow != null:
			tutorial_flow.start_if_needed()
	_connect_title_settings()
	if not run_requested.is_connected(_on_run_requested):
		run_requested.connect(_on_run_requested)


## The flat ground colour is hidden in favour of the painted archive, which
## left a black band under the walkway. Paint the archive terrain tiles there
## (visual only; the Ground body still owns collision).
func _build_floor_tiles() -> void:
	if get_node_or_null("FloorTiles") != null:
		return
	var tiles_set := load("res://resources/tiles/ch1_tiles.tres") as TileSet
	if tiles_set == null:
		return
	var top_row := 35  # y = 560, the Ground body's top edge
	var fill := TileMapLayer.new()
	fill.name = "FloorFill"
	fill.tile_set = tiles_set
	fill.collision_enabled = false
	var top := TileMapLayer.new()
	top.name = "FloorTiles"
	top.tile_set = tiles_set
	top.collision_enabled = false
	for column in 80:
		top.set_cell(Vector2i(column, top_row), 0,
			TileVariants.pick(tiles_set, Vector2i(0, 0), column, top_row))
		for row in range(top_row + 1, 46):
			fill.set_cell(Vector2i(column, row), 0,
				TileVariants.fill(tiles_set, Vector2i(1, 0), row - top_row))
	add_child(fill)
	add_child(top)
	move_child(fill, 0)
	move_child(top, 1)
	fill.z_index = -1
	top.z_index = -1


func _apply_background_art() -> void:
	for layer in [
		["BackgroundFar", "res://assets/backgrounds/pixel/ink_archive_far.png", -20, Color(0.78, 0.82, 0.9, 1.0)],
		["BackgroundMid", "res://assets/backgrounds/pixel/ink_archive_mid.png", -19, Color(0.9, 0.94, 1.0, 1.0)],
	]:
		var path := String(layer[1])
		if not ResourceLoader.exists(path):
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(layer[0])
		sprite.texture = load(path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(640, 360)
		sprite.z_index = int(layer[2])
		# Pushed back in value so the characters read in front (art-spec bands).
		sprite.modulate = layer[3]
		add_child(sprite)
	for node_name in ["Background", "SkyGlow", "Moon", "ShelfA", "ShelfA_Spines", "ShelfB", "ShelfB_Spines", "ShelfC", "ShelfC_Spines"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.visible = false


func _play_hub_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "res://assets/audio/music/hub.ogg", 1.0)


func _on_title_started() -> void:
	if Flow != null and Flow.resume_requested:
		# "继续本局" goes straight back into the checkpoint instead of the Hub.
		_play_hub_audio()
		run_requested.emit()
		return
	_play_hub_audio()
	if tutorial_flow != null:
		tutorial_flow.start_if_needed()
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_voice"):
		audio.call("play_voice", "luchen_mission")
	if dialogue_ui != null:
		dialogue_ui.open_dialogue("陆沉", [
			"昌子，你终于回来了。档案馆的灯还亮着，说明世界还没彻底忘记我们。",
			"名册被撕走了三页，散落在墨雨档案馆、呼吸废墟和无光海。没有名册，死者会忘记自己的名字。",
			"去吧。第一页在墨雨档案馆的封印库里。回来时，把你自己也带回来。",
		])
		_refresh_player_freeze()


func _on_run_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func ensure_ready() -> void:
	if _initialized:
		return
	_initialized = true
	_resolve_nodes()
	_ensure_profile()
	_load_words()
	_build_shop()
	_connect_ui()
	_build_npc_inspiration()
	_build_help()
	_build_archive()
	_build_tutorial()
	_refresh_fragment_label()
	_refresh_hint()


func _resolve_nodes() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if portal == null:
		portal = get_node_or_null("Portal") as HubPortal
	if dialogue_ui == null:
		dialogue_ui = get_node_or_null("UI/DialogueUI") as DialogueUI
	if shop_ui == null:
		shop_ui = get_node_or_null("UI/ShopUI") as ShopUI
	if fragment_label == null:
		fragment_label = get_node_or_null("Overlay/TopLeft/Margin/VBox/FragmentLabel") as Label
	if hint_label == null:
		hint_label = get_node_or_null("Overlay/TopLeft/Margin/VBox/Hint") as Label


## The top-left objective line names the current movement and interact keys,
## so it has to follow both a controller switch and a rebind.
func _connect_prompt_refresh() -> void:
	var flow := _flow_node()
	if flow == null:
		return
	if not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if not flow.keybinds_changed.is_connected(_on_keybinds_changed):
		flow.keybinds_changed.connect(_on_keybinds_changed)


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_hint()


func _on_keybinds_changed() -> void:
	_refresh_hint()


func _refresh_hint() -> void:
	if hint_label == null:
		return
	var flow := _flow_node()
	var move := "左摇杆" if flow != null and flow.using_gamepad else "%s / %s" % [
		flow.prompt_label(&"move_left") if flow != null else "A",
		flow.prompt_label(&"move_right") if flow != null else "D"]
	var interact := flow.prompt_label(&"interact") if flow != null else "E"
	hint_label.text = "目标：追回失踪名册的三页 · %s 移动 · %s 交互" % [move, interact]


## Resolved from the tree so a Hub built outside the scene tree (unit tests
## call ensure_ready() before add_child) never uses an absolute get_node().
func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _connect_title_settings() -> void:
	for child in get_children():
		if child is TitleScreen:
			if not child.settings_requested.is_connected(_open_settings):
				child.settings_requested.connect(_open_settings)
			if not child.new_game_requested.is_connected(_on_new_game_requested):
				child.new_game_requested.connect(_on_new_game_requested)


func _on_new_game_requested() -> void:
	# Flow.reset_profile() swaps the profile instance; the old one is freed.
	# Bind everything that cached it (shop page, word copies, tutorial codex)
	# to the new profile before the next frame.
	var new_profile := Flow.profile if Flow != null else profile
	if new_profile != null:
		set_profile(new_profile)
	else:
		_rebind_tutorial_run()


func _build_tutorial() -> void:
	if tutorial_flow != null:
		return
	training_dummy = TrainingDummy.new()
	training_dummy.position = Vector2(700, 560)
	add_child(training_dummy)
	training_dummy.hit.connect(_on_training_dummy_hit)
	tutorial_flow = TutorialFlow.new()
	add_child(tutorial_flow)
	_tutorial_codex = preload("res://scenes/ui/codex.tscn").instantiate() as CodexUI
	ModalLayer.host(self).add_child(_tutorial_codex)
	_tutorial_codex.visible = false
	_rebind_tutorial_run()
	_tutorial_codex.phrase_equip_requested.connect(_on_tutorial_phrase_equipped)
	_tutorial_codex.close_requested.connect(_close_tutorial_codex)


## Rebuilds the tutorial's run copy from the current profile. "New game"
## keeps the codex page alive but must not leave it bound to freed words.
func _rebind_tutorial_run() -> void:
	_tutorial_phrase = null
	if _tutorial_codex == null:
		_tutorial_run = null
		return
	_tutorial_run = RunState.new()
	_tutorial_run.reset_for_new_run(1)
	if profile != null:
		for word in RunLoot.starting_words(profile):
			_tutorial_run.inventory.add_word(word)
		_tutorial_codex.set_persistent_discovered(profile.discovered_phrases)
	_tutorial_codex.bind(PhraseResolver.new(), _tutorial_run)


func _open_tutorial_codex() -> void:
	if _tutorial_codex == null:
		return
	if not _tutorial_codex.visible:
		var viewport := get_viewport()
		_codex_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
	_tutorial_codex.visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_flow.on_codex_opened()
	_refresh_player_freeze()
	# A pad opening the codex must land on a word, not on empty canvas.
	_tutorial_codex.focus_entry()


func _close_tutorial_codex() -> void:
	if _tutorial_codex != null:
		_tutorial_codex.visible = false
	if is_inside_tree():
		get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_player_freeze()
	var previous := _codex_return_focus
	_codex_return_focus = null
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()


func _on_tutorial_phrase_equipped(_slot: int, phrase: ResolvedPhrase) -> void:
	_tutorial_phrase = phrase
	if tutorial_flow != null:
		tutorial_flow.on_phrase_equipped()


func _on_training_dummy_hit(_amount: int) -> void:
	if tutorial_flow != null:
		tutorial_flow.on_training_hit()


func _use_training_dummy() -> void:
	if training_dummy == null:
		return
	if _tutorial_phrase == null:
		if tutorial_flow != null:
			tutorial_flow.start_if_needed()
			tutorial_flow.on_codex_opened()
		return
	var damage := int(round(float(_tutorial_phrase.components.get(&"damage", 0.0))))
	if damage <= 0:
		damage = maxi(int(round(float(_tutorial_phrase.ink_cost) * 0.5)), 1)
	training_dummy.take_damage(damage)


func _open_settings() -> void:
	if settings_menu == null:
		settings_menu = preload("res://scenes/ui/settings_menu.tscn").instantiate() as SettingsMenu
		ModalLayer.host(self).add_child(settings_menu)
		settings_menu.closed.connect(_on_settings_closed)
	settings_menu.open()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_player_freeze()


func _on_settings_closed() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_player_freeze()


func _connect_ui() -> void:
	if portal != null and not portal.activated.is_connected(request_run):
		portal.activated.connect(request_run)
	if dialogue_ui != null:
		if not dialogue_ui.finished.is_connected(_on_dialogue_finished):
			dialogue_ui.finished.connect(_on_dialogue_finished)
		if not dialogue_ui.closed.is_connected(_on_dialogue_closed):
			dialogue_ui.closed.connect(_on_dialogue_closed)
		if not dialogue_ui.inspiration_requested.is_connected(_open_active_inspiration):
			dialogue_ui.inspiration_requested.connect(_open_active_inspiration)
	if shop_ui != null:
		shop_ui.bind(shop, profile)
		if not shop_ui.closed.is_connected(_on_shop_closed):
			shop_ui.closed.connect(_on_shop_closed)
		if not shop_ui.purchased.is_connected(_on_shop_purchased):
			shop_ui.purchased.connect(_on_shop_purchased)


func _process(_delta: float) -> void:
	ensure_ready()
	if player == null:
		return
	# A controller button being captured in Settings is not a Hub action.
	if Flow.input_capture_active:
		return
	if settings_menu != null and settings_menu.visible:
		# Esc/B are handled by SettingsMenu itself (top subpage first). Only
		# the dedicated settings key is polled here so one press never closes
		# both a subpage and the settings page.
		if Input.is_action_just_pressed("settings"):
			if not settings_menu.close_subpage():
				settings_menu.close()
		return
	if _tutorial_codex != null and _tutorial_codex.visible:
		# Match the other Hub pages (settings/dialogue/shop/archive/help/inspire):
		# the pause key backs out of the page instead of doing nothing.
		if Input.is_action_just_pressed("codex") or Input.is_action_just_pressed("ui_cancel") \
				or Input.is_action_just_pressed("pause"):
			_close_tutorial_codex()
		return
	_update_prompts()
	if Input.is_action_just_pressed("settings") and not _is_ui_open():
		_open_settings()
		return
	if Input.is_action_just_pressed("codex") and not _is_ui_open():
		_open_tutorial_codex()
		return
	if Input.is_action_just_pressed("help") and not _is_ui_open():
		if help_ui != null:
			help_ui.open()
			_refresh_player_freeze()
		return
	if npc_inspire_ui != null and npc_inspire_ui.is_open():
		return
	if help_ui != null and help_ui.is_open():
		return
	if archive_ui != null and archive_ui.is_open():
		return
	var y_down := Input.is_action_pressed("npc_inspire")
	var opened_inspiration := false
	if y_down and not _inspire_key_down and dialogue_ui != null and dialogue_ui.is_open():
		opened_inspiration = _open_active_inspiration()
	_inspire_key_down = y_down
	if opened_inspiration:
		# Y is both interact and npc_inspire by default. The same press must not
		# fall through and re-open the dialogue behind the inspiration panel.
		return
	if not Input.is_action_just_pressed("interact"):
		return
	if dialogue_ui != null and dialogue_ui.is_open():
		dialogue_ui.advance()
		return
	if shop_ui != null and shop_ui.is_open():
		return
	var target := get_nearest_interactable()
	if target != null:
		interact_with(target)


func request_run() -> void:
	run_requested.emit()


func get_npcs() -> Array[NPC]:
	var result: Array[NPC] = []
	for child in get_children():
		if child is NPC:
			result.append(child)
	return result


func get_npc(npc_id: StringName) -> NPC:
	for child in get_children():
		if child is NPC and child.npc_id == npc_id:
			return child
	return null


func get_word(word_id: StringName) -> WordData:
	ensure_ready()
	return _words.get(word_id) as WordData


func get_nearest_interactable() -> Node:
	ensure_ready()
	if player == null:
		return null
	var best: Node = null
	var best_distance := INF
	for npc in get_npcs():
		var distance := player.global_position.distance_to(npc.global_position)
		if distance <= npc.interaction_radius and distance < best_distance:
			best = npc
			best_distance = distance
	if portal != null:
		var distance := player.global_position.distance_to(portal.global_position)
		if distance <= portal.interaction_radius and distance < best_distance:
			best = portal
			best_distance = distance
	if training_dummy != null and is_instance_valid(training_dummy):
		var distance := player.global_position.distance_to(training_dummy.global_position)
		if distance <= 110.0 and distance < best_distance:
			best = training_dummy
	return best


func interact_with(target: Node) -> void:
	ensure_ready()
	if target is NPC:
		talk_to_npc(target as NPC)
	elif target is HubPortal:
		(target as HubPortal).activate()
	elif target is TrainingDummy:
		_use_training_dummy()


static func is_late_npc(npc_id: StringName) -> bool:
	return npc_id == &"wenjin" or npc_id == &"baiyu"


func late_npcs_arrived() -> bool:
	return profile != null and profile.demo_cleared


func talk_to_npc(npc: NPC) -> void:
	ensure_ready()
	if npc == null:
		return
	if is_late_npc(npc.npc_id) and not late_npcs_arrived():
		return
	# A personal event replaces the regular conversation once. It reads its own
	# scene, then the NPC goes back to the usual greeting/attitude/function lines.
	if NPCEventData.can_trigger(profile, npc.npc_id):
		_open_npc_event(npc)
		return
	var profile_data := NPCProfiles.get_profile(npc.npc_id)
	var lines: Array[String] = npc.get_lines()
	if not profile_data.is_empty():
		var greeting := String(profile_data.get("greeting", ""))
		if not greeting.is_empty() and (lines.is_empty() or lines[0] != greeting):
			lines.insert(0, greeting)
		var tier := TrustData.tier_for(profile, npc.npc_id)
		var attitude := NPCProfiles.trust_line(npc.npc_id, tier)
		if not attitude.is_empty():
			lines.insert(mini(1, lines.size()), attitude)
	match npc.npc_id:
		&"luchen":
			lines.append(decode_word())
			lines.append("陆沉的服务里新增了「档案馆升级」：用记忆碎片永久强化昌子，demo 每个方向上限 %d 级。" % ArchiveData.MAX_LEVEL)
		&"ayan":
			# Greeting is not a purchase. The paid forge lives on the 言灵 panel's
			# 「锻造基底」 service; this branch used to call upgrade_sword_base()
			# directly, so saying hello spent fragments and raised the base level.
			lines.append("断页剑基底现在是 Lv.%d。要再锻一层，在「言灵对话」里选「锻造基底」——花多少碎片，看交情。" % profile.weapon_base_level(SWORD_ID))
		_:
			pass
	# The "言灵对话" button already shows the live key for the current device;
	# baking a key into the line would go stale after a device switch.
	lines.append("也可以选「言灵对话」，对 TA 说一句只属于你的话。")
	_active_npc_id = npc.npc_id
	if lines.is_empty():
		lines.append("……")
	if dialogue_ui != null:
		dialogue_ui.set_inspiration_enabled(true)
		dialogue_ui.open_dialogue(npc.get_speaker(), lines)
		_refresh_player_freeze()


func _open_npc_event(npc: NPC) -> void:
	if dialogue_ui == null:
		return
	var event := NPCEventData.event_for(npc.npc_id)
	var lines: Array[String] = []
	for line in event.get("lines", []):
		lines.append(String(line))
	if lines.is_empty():
		return
	_pending_event_id = String(event.get("id", ""))
	_active_npc_id = npc.npc_id
	dialogue_ui.set_inspiration_enabled(true)
	dialogue_ui.open_dialogue(npc.get_speaker(), lines)
	_refresh_player_freeze()


## Persist only after the last line. No pages, fragments, trust or items are
## touched: the event is a story beat, not a reward.
func _record_npc_event(event_id: String) -> void:
	if profile == null or event_id.is_empty():
		return
	if profile.record_npc_event(event_id):
		_save_shared_profile()


func _build_help() -> void:
	if help_ui != null:
		return
	help_ui = HelpUI.new()
	ModalLayer.host(self).add_child(help_ui)
	help_ui.closed.connect(_on_help_closed)


func _on_help_closed() -> void:
	_refresh_player_freeze()


func _build_archive() -> void:
	if archive_ui != null:
		return
	archive_ui = ArchiveUI.new()
	ModalLayer.host(self).add_child(archive_ui)
	archive_ui.closed.connect(_on_archive_closed)
	archive_ui.purchased.connect(_on_archive_purchased)


func _on_archive_closed() -> void:
	_refresh_player_freeze()


func _on_archive_purchased(_track_id: StringName) -> void:
	_save_shared_profile()
	_refresh_fragment_label()


func _build_npc_inspiration() -> void:
	if npc_inspire_ui != null:
		return
	npc_inspire_ui = NPCInspireUI.new()
	add_child(npc_inspire_ui)
	npc_inspire_ui.closed.connect(_on_npc_inspiration_closed)
	npc_inspire_ui.inspiration_submitted.connect(_on_npc_inspiration_submitted)
	npc_inspire_ui.function_requested.connect(_on_npc_function_requested)
	if not is_inside_tree():
		return
	var ai := get_node_or_null("/root/AI") as AIService
	if ai != null:
		if not ai.npc_reply_ready.is_connected(_on_npc_ai_ready):
			ai.npc_reply_ready.connect(_on_npc_ai_ready)
		if not ai.npc_reply_failed.is_connected(_on_npc_ai_failed):
			ai.npc_reply_failed.connect(_on_npc_ai_failed)


func _open_active_inspiration() -> bool:
	if _active_npc_id == &"":
		return false
	var npc_id := _active_npc_id
	var npc := get_npc(npc_id)
	if npc == null:
		return false
	if dialogue_ui != null and dialogue_ui.is_open():
		dialogue_ui.close()
	_active_npc_id = npc_id
	_build_npc_inspiration()
	npc_inspire_ui.open(npc)
	_refresh_player_freeze()
	return true


func open_npc_inspiration(npc_id: StringName) -> bool:
	_active_npc_id = npc_id
	var npc := get_npc(npc_id)
	if npc == null:
		return false
	_open_active_inspiration()
	return true


func _on_npc_inspiration_closed() -> void:
	_inspire_pending_npc = &""
	_pending_offline_result = {}
	_refresh_player_freeze()


## AI replaces the offline reply; it must never add a second mechanical effect.
## One NPC effect per Hub visit, whether it came from offline or AI.
func _apply_inspiration_effect(npc_id: StringName, effect: Dictionary, ai_configured: bool, from_ai := false) -> Dictionary:
	if ai_configured:
		return {}
	return NPCProfiles.apply_effect_once(profile, npc_id, effect, _npc_effect_used, from_ai)


## The AI sees the same tier the offline evaluator sees. The keys are optional
## for the request builder, so callers that pass a raw profile stay valid.
func _npc_prompt_profile(npc_id: StringName) -> Dictionary:
	var data := NPCProfiles.get_profile(npc_id)
	if profile != null:
		var tier := TrustData.tier_for(profile, npc_id)
		data["trust_tier"] = TrustData.TIER_NAMES[tier]
		data["trust_attitude"] = NPCProfiles.trust_line(npc_id, tier)
	return data


func _on_npc_inspiration_submitted(npc_id: StringName, text: String) -> void:
	if npc_inspire_ui == null:
		return
	_inspire_pending_npc = npc_id
	var trust := profile.npc_trust_value(npc_id) if profile != null else 0.0
	var result := NPCProfiles.resolve(npc_id, text, trust)
	_pending_offline_result = result
	var ai := get_node_or_null("/root/AI") as AIService
	var ai_configured := ai != null and ai.is_configured()
	var applied := _apply_inspiration_effect(npc_id, result.get("effect", {}), ai_configured)
	if ai_configured:
		npc_inspire_ui.set_busy(true)
		npc_inspire_ui.show_status("正在聆听……AI 若失败，离线回应会生效一次。")
		ai.request_npc_reply(npc_id, text, _npc_prompt_profile(npc_id))
		return
	npc_inspire_ui.set_busy(false)
	npc_inspire_ui.show_reply(String(result.get("reply", "……")), String(result.get("mood", "neutral")))
	var summary := _npc_effect_summary(applied)
	if not summary.is_empty():
		npc_inspire_ui.show_status("言灵改变了 TA 的职能：" + summary)
	else:
		npc_inspire_ui.show_status("离线推演完成。这次对话的职能效果已经用过，或没有触发。")
	_save_shared_profile()
	_refresh_fragment_label()


func _on_npc_ai_ready(npc_id: StringName, sentence: String, reply: String, data: Dictionary) -> void:
	if npc_inspire_ui == null or not npc_inspire_ui.is_open():
		return
	if npc_id != _inspire_pending_npc:
		return
	npc_inspire_ui.set_busy(false)
	var applied := _apply_inspiration_effect(npc_id, data.get("effect", {}), false, true)
	npc_inspire_ui.show_reply(reply, String(data.get("mood", "neutral")))
	var summary := _npc_effect_summary(applied)
	if not summary.is_empty():
		npc_inspire_ui.show_status("AI 的言灵改变了 TA 的职能：" + summary)
	else:
		npc_inspire_ui.show_status("AI 用 %s 的声音回答了你。" % String(NPCProfiles.get_profile(npc_id).get("name", "TA")))
	_save_shared_profile()
	_refresh_fragment_label()
	var action_text := _apply_ai_action(npc_id, data.get("action", {}))
	if not action_text.is_empty() and npc_inspire_ui != null and npc_inspire_ui.is_open():
		npc_inspire_ui.show_status("AI 替你办成了：" + action_text)


func _on_npc_ai_failed(npc_id: StringName, error: String) -> void:
	if npc_inspire_ui == null or npc_id != _inspire_pending_npc:
		return
	npc_inspire_ui.set_busy(false)
	var result := _pending_offline_result
	var applied := _apply_inspiration_effect(npc_id, result.get("effect", {}), false)
	npc_inspire_ui.show_reply(String(result.get("reply", "……")), String(result.get("mood", "neutral")))
	var summary := _npc_effect_summary(applied)
	if not summary.is_empty():
		npc_inspire_ui.show_status("AI 没有回应（%s），离线回应已生效：%s" % [error, summary])
	else:
		npc_inspire_ui.show_status("AI 没有回应（%s），离线回应已保留。" % error)
	_save_shared_profile()
	_refresh_fragment_label()


## One concrete favour per NPC per hub visit. The AI proposes an action; the
## client accepts only ids authored for that NPC and clamps the terms.
func _apply_ai_action(npc_id: StringName, raw: Variant) -> String:
	if _ai_favors.has(npc_id):
		return ""
	var action := NPCProfiles.validate_action(npc_id, raw)
	if action.is_empty():
		return ""
	_ai_favors[npc_id] = true
	var action_id := StringName(action.get("id", &""))
	var discount := float(action.get("discount", 0.0))
	var free := bool(action.get("free", false))
	match action_id:
		&"shop":
			if profile != null and discount > 0.0:
				profile.add_npc_blessing(&"guru", "shop_discount", discount)
			if npc_inspire_ui != null:
				npc_inspire_ui.close()
			if shop_ui != null:
				shop_ui.bind(shop, profile)
				_refresh_shop_discount()
				shop_ui.open()
				shop_ui.announce("AI 言灵：咕噜按你的话打了 %.0f%% 折扣。" % (discount * 100.0))
			return "咕噜把货架拖出来，按你的话给了折扣。"
		&"forge":
			if profile != null:
				if free:
					profile.add_npc_blessing(&"ayan", "forge_free", 1.0)
				elif discount > 0.0:
					profile.add_npc_blessing(&"ayan", "forge_discount", discount)
			var result := upgrade_sword_base()
			return String(result.get("message", ""))
		&"forge_god":
			if not free:
				return ""
			_function_free = true
			var forged := _forge_god()
			_function_free = false
			return forged
		&"lore", &"rumor", &"intel", &"contract", &"map", &"shortcut", &"decode":
			return perform_npc_function(npc_id, action_id, free, discount)
	return ""


func _npc_effect_summary(applied: Dictionary) -> String:
	var labels := {
		"forge_bonus": "锻造祝福 +",
		"forge_discount": "锻造折扣 +",
		"forge_free": "免费神铸 +",
		"shop_discount": "黑市折扣 +",
		"map_pages": "起始残页 +",
		"intel": "情报 +",
		"lore": "档案线索 +",
		"fragments": "记忆碎片 +",
		"corruption": "起始污染 +",
		"trust": "信任 +",
		"start_health": "下一局起始生命 +",
		"start_ink": "下一局起始墨量 +",
		"start_relics": "下一局起始遗物 +",
		"weapon_damage": "武器伤害永久 +",
	}
	var parts: Array[String] = []
	for key in applied.keys():
		if labels.has(String(key)):
			parts.append("%s%s" % [labels[String(key)], str(applied[key])])
	return " · ".join(parts)


func perform_npc_function(npc_id: StringName, function_id: StringName, free := false, discount := 0.0) -> String:
	ensure_ready()
	_ensure_profile()
	_function_free = free
	_function_discount = discount
	var message := ""
	match function_id:
		&"decode":
			message = decode_word()
		&"lore":
			# The demo owns every chapter-1 word from the first run, so there is
			# usually nothing left to hand out. Say that instead of charging for
			# a word that cannot be delivered (the old fallback paid 8 fragments
			# for a 6-fragment service — a repeatable fragment pump).
			if unlockable_word_pool().is_empty():
				message = "陆沉把名册合上：你身上的词已经全了，这一课没有新东西可讲。他没要你的碎片。"
			elif not _spend_fragments(6):
				message = "陆沉把手按在名册上：讲故事也要灯油。需要 6 记忆碎片。"
			else:
				var word := _unlock_random_word()
				message = "陆沉讲了一段被撕掉的世界史。你从纸缝里捡回一个词：%s。" % word
		&"forge":
			message = String(upgrade_sword_base().get("message", ""))
		&"forge_god":
			message = _forge_god()
		&"archive":
			if dialogue_ui != null and dialogue_ui.is_open():
				dialogue_ui.close()
			if npc_inspire_ui != null:
				npc_inspire_ui.close()
			if archive_ui != null:
				archive_ui.bind(profile)
				archive_ui.open()
				_refresh_player_freeze()
			# The demo cap is the same one the archive page enforces; the older
			# "等级没有尽头" line contradicted the page it opens.
			message = "陆沉把档案馆的旧升降台推到你面前：demo 每个方向修到 Lv.%d 为止，档案本身没有尽头。" % ArchiveData.MAX_LEVEL
		&"shop":
			if dialogue_ui != null and dialogue_ui.is_open():
				dialogue_ui.close()
			if npc_inspire_ui != null:
				npc_inspire_ui.close()
			if shop_ui != null:
				shop_ui.bind(shop, profile)
				_refresh_shop_discount()
				shop_ui.open()
			message = "咕噜把货架拖了出来。"
		&"rumor":
			if unlockable_word_pool().is_empty():
				message = "咕噜把货架推回去：没有你不知道的词了，这单不收钱。传闻也一并送你——下一章的门会记得你上一次没拿的东西。"
			elif not _spend_fragments(3):
				message = "咕噜摊手：传闻也要成本。需要 3 记忆碎片。"
			else:
				var word := _unlock_random_word()
				message = "咕噜压低声音：「下一章的门，会记得你上一次没拿的东西。」你得到：%s。" % word
		&"intel":
			if not _spend_fragments(8):
				message = "闻烬用笔尖敲了敲桌面：情报不赊账。需要 8 记忆碎片。"
			else:
				var next_index := mini(1, CampaignData.chapter_count() - 1)
				var chapter := CampaignData.chapter(next_index)
				profile.add_npc_blessing(&"wenjin", "damage", 2.0)
				message = "闻烬把一张折起的纸推给你：下一章的 Boss 是「%s」。它的招式有前摇。你所有武器的伤害永久 +2。" % chapter["boss_name"]
		&"contract":
			if not _spend_fragments(12):
				message = "闻烬笑了：契约也要纸钱。需要 12 记忆碎片。"
			else:
				profile.add_pending_run_bonus(&"start_corruption", 6.0)
				profile.add_pending_run_bonus(&"start_pages", 10.0)
				message = "你在契约上按下名字。墨迹自己爬动起来：本局起始多 10 残页，污染 +6。闻烬没有笑。"
		&"map":
			if not _spend_fragments(6):
				message = "白榆把地图卷起来：路线也要墨水。需要 6 记忆碎片。"
			else:
				profile.add_pending_run_bonus(&"start_pages", 8.0)
				message = "白榆在空白处画了七个点：六个战斗房，一座 Boss 门。宝箱在第三与第五道平台。本局起始多 8 残页。"
		&"shortcut":
			if not _spend_fragments(15):
				message = "白榆摇头：近路不是免费的。需要 15 记忆碎片。"
			else:
				profile.add_pending_run_bonus(&"start_pages", 15.0)
				message = "白榆带你绕过一段不存在的路。本局起始多 15 残页，但他没有告诉你这条路原本通向哪里。"
		_:
			message = "TA 现在没有这个职能。"
	_save_shared_profile()
	_refresh_fragment_label()
	if npc_inspire_ui != null and npc_inspire_ui.is_open():
		npc_inspire_ui.show_reply(message, "neutral")
	_function_free = false
	_function_discount = 0.0
	return message


func _forge_god() -> String:
	if not _spend_fragments(25):
		return "阿砚把锤子放下：神铸要烧掉 25 记忆碎片。你现在的记忆还不够。"
	profile.force_upgrade_weapon_base(SWORD_ID)
	var forge_remaining := maxf(
		NPCProfiles.FORGE_BONUS_TOTAL_CAP - profile.npc_blessing(&"ayan", "forge_bonus", 0.0), 0.0)
	var forge_added := minf(1.0, forge_remaining)
	if forge_added > 0.0:
		profile.add_npc_blessing(&"ayan", "forge_bonus", forge_added)
	_refresh_fragment_label()
	_save_shared_profile()
	# The blessing is capped, so the line reports what was actually added
	# instead of always claiming +1.
	var blessing_line := "锻造祝福已至上限。"
	if forge_added >= 1.0:
		blessing_line = "锻造祝福 +1。"
	elif forge_added > 0.0:
		blessing_line = "锻造祝福 +%.1f。" % forge_added
	return "阿砚沉默了很久。炉膛里没有火，但铁砧自己亮了。断页剑基底升至 Lv.%d，%s他没说那是神迹。" % [
		profile.weapon_base_level(SWORD_ID), blessing_line,
	]


func _spend_fragments(cost: int) -> bool:
	if _function_free:
		return true
	if _function_discount > 0.0:
		cost = maxi(int(ceilf(float(cost) * (1.0 - _function_discount))), 1)
	if profile == null or profile.memory_fragments < cost:
		return false
	profile.memory_fragments -= cost
	_refresh_fragment_label()
	return true


## Every chapter-1 word a paid word service could still hand out. The demo
## grants all of them at profile creation, so this is normally empty and the
## services must refuse instead of inventing a payout.
func unlockable_word_pool() -> Array[WordData]:
	var pool: Array[WordData] = []
	if profile == null:
		return pool
	for word in RunLoot.demo_word_pool():
		if not profile.is_word_unlocked(word.id):
			pool.append(word)
	return pool


## Picks one word from [method unlockable_word_pool]. Callers check the pool
## first; an empty result means there was nothing to unlock.
func _unlock_random_word() -> String:
	var pool := unlockable_word_pool()
	if pool.is_empty():
		return ""
	var picked := pool[randi() % pool.size()]
	profile.unlock_word(picked.id)
	_save_shared_profile()
	return "「%s」%s" % [RunLoot.word_label(picked), picked.glyph]


func _on_npc_function_requested(npc_id: StringName, function_id: StringName) -> void:
	perform_npc_function(npc_id, function_id)


## 陆沉 decodes one owned-but-still-glyph word per Hub visit. State lives on
## Profile; the shared WordData .tres and the Hub copy are never the source.
func decode_word() -> String:
	ensure_ready()
	_ensure_profile()
	var candidates: Array[WordData] = []
	for word in RunLoot.starting_words(profile):
		if word != null and not word.decoded and not profile.is_word_decoded(word.id):
			candidates.append(word)
	if candidates.is_empty():
		return "你身上暂时没有需要解读的残页。去档案馆里找找，或从咕噜那里买词片。"
	var word := candidates[0]
	var word_name := word.meaning if word.meaning != "" else String(word.id)
	var glyph := word.glyph if word.glyph != "" else "?"
	var description := word.description
	if not profile.decode_word(word.id):
		return "「%s」的记忆已经完整。" % word_name
	var hub_word := get_word(word.id)
	if hub_word != null:
		WordRuntime.mark_decoded(hub_word)
	# The tutorial Codex keeps its own run copy of every starting word. Decode
	# that copy too and notify the grid, or the page keeps showing the old
	# "未解码" card until the Hub rebuilds its tutorial run.
	if _tutorial_run != null:
		for entry in _tutorial_run.inventory.words:
			if entry != null and entry.id == word.id and not entry.decoded:
				WordRuntime.mark_decoded(entry)
				_tutorial_run.inventory.changed.emit()
				break
	_save_shared_profile()
	if description != "":
		description = "\n" + description
	return "我替你解开「%s」：%s。%s" % [word_name, glyph, description]


func upgrade_sword_base() -> Dictionary:
	ensure_ready()
	_ensure_profile()
	var level := profile.weapon_base_level(SWORD_ID)
	var base_cost := 10 + level * 10
	var discount := clampf(TrustData.forge_discount(profile), 0.0, 0.85)
	var blessed_upgrade := TrustData.forge_blessing(profile) and not _trust_forge_used
	var free_upgrade := profile.npc_blessing(&"ayan", "forge_free", 0.0) >= 1.0 or blessed_upgrade
	var cost := 0 if free_upgrade else maxi(int(ceilf(float(base_cost) * (1.0 - discount))), 1)
	var fragments_before := profile.memory_fragments
	var success := false
	var trust_blessing_spent := false
	if profile.memory_fragments >= cost:
		profile.memory_fragments -= cost
		profile.force_upgrade_weapon_base(SWORD_ID)
		if free_upgrade:
			# Spend an earned forge_free blessing first; the 托付 favour is the
			# fallback, so the two never both disappear on one upgrade.
			if not profile.consume_npc_blessing(&"ayan", "forge_free", 1.0) and blessed_upgrade:
				_trust_forge_used = true
				trust_blessing_spent = true
		success = true
	var new_level := profile.weapon_base_level(SWORD_ID)
	var message := ""
	if success:
		message = "记忆碎片 -%d。断页剑基底已升至 Lv.%d，所有掉落的断页剑都会继承它。" % [
			fragments_before - profile.memory_fragments,
			new_level,
		]
		if discount > 0.0:
			message += " 阿砚没抬头：这次算你便宜点。"
		if trust_blessing_spent:
			message += " 阿砚把锤子递给你：这次不算钱。"
		elif free_upgrade:
			message += " 炉火自己亮了一瞬。"
	else:
		message = "记忆碎片不足：升级需要 %d，你只有 %d。去破碎区带些记忆回来吧。" % [
			cost,
			fragments_before,
		]
	_refresh_fragment_label()
	return {
		"success": success,
		"cost": cost,
		"level": new_level,
		"fragments": profile.memory_fragments,
		"message": message,
	}


## The shelf price and the purchase must read the same discount; call this
## every time the shop opens, not just on the buy.
func _refresh_shop_discount() -> void:
	if shop != null and profile != null:
		shop.discount = clampf(TrustData.shop_discount(profile), 0.0, 0.8)


func buy_from_shop(item_id: StringName) -> bool:
	ensure_ready()
	_ensure_profile()
	if shop == null:
		return false
	_refresh_shop_discount()
	var success := shop.buy(item_id, profile)
	_refresh_fragment_label()
	return success


func set_profile(new_profile: Profile) -> void:
	if new_profile == null:
		return
	ensure_ready()
	if _owned_profile != null and is_instance_valid(_owned_profile) and _owned_profile != new_profile:
		_owned_profile.queue_free()
		_owned_profile = null
	profile = new_profile
	# Word copies cache Profile decode state; rebuild them so a fresh profile
	# does not inherit the old run's decoded flags.
	_words.clear()
	_load_words()
	_rebind_tutorial_run()
	if shop_ui != null:
		shop_ui.bind(shop, profile)
	_refresh_fragment_label()


func _ensure_profile() -> void:
	if profile != null:
		return
	var created := Profile.new()
	created.name = "HubProfile"
	created.memory_fragments = demo_starting_fragments
	add_child(created)
	profile = created
	_owned_profile = created


func _load_words() -> void:
	for resource in ContentLibrary.WORDS:
		if resource is WordData:
			var word := WordRuntime.for_run(resource as WordData, profile)
			if word.id != &"":
				_words[word.id] = word


func _build_shop() -> void:
	shop = Shop.new()
	for entry in SHOP_STOCK:
		var item_id := StringName(entry.get("id", &""))
		if item_id == &"":
			continue
		var kind := StringName(entry.get("kind", &"word"))
		if kind == &"relic":
			var relic := ContentLibrary.relic_by_id(item_id)
			if relic == null:
				continue
			shop.stock.append({
				"id": item_id,
				"cost": int(entry.get("cost", 0)),
				"kind": &"relic",
				"display_name": relic.display_name,
				"glyph": "◆",
				"description": RelicEffects.describe(relic.effect_id) + ("  污染 +%d" % relic.corruption if relic.corruption > 0 else ""),
			})
			continue
		var word := get_word(item_id)
		shop.stock.append({
			"id": item_id,
			"cost": int(entry.get("cost", 0)),
			"kind": &"word",
			"display_name": RunLoot.word_label(word) if word != null else String(item_id),
			"glyph": word.glyph if word != null else "",
			"description": (word.description if word != null and word.decoded else "尚未解读的词片。") if word != null else "",
		})


func _update_prompts() -> void:
	var ui_open := _is_ui_open()
	for npc in get_npcs():
		npc.set_player_near(not ui_open and npc.is_player_near(player.global_position))
	if portal != null:
		portal.set_player_near(not ui_open and portal.is_player_near(player.global_position))


func _is_ui_open() -> bool:
	var dialogue_open := dialogue_ui != null and dialogue_ui.is_open()
	var shop_open := shop_ui != null and shop_ui.is_open()
	var inspire_open := npc_inspire_ui != null and npc_inspire_ui.is_open()
	var help_open := help_ui != null and help_ui.is_open()
	var archive_open := archive_ui != null and archive_ui.is_open()
	var settings_open := settings_menu != null and settings_menu.visible
	var codex_open := _tutorial_codex != null and _tutorial_codex.visible
	return dialogue_open or shop_open or inspire_open or help_open or archive_open or settings_open or codex_open


func _refresh_player_freeze() -> void:
	if player == null:
		return
	var frozen := _is_ui_open()
	player.set_physics_process(not frozen)
	if frozen:
		player.velocity = Vector2.ZERO


func _save_shared_profile() -> void:
	if is_inside_tree() and profile == Flow.profile and Flow.auto_save:
		Flow.save_profile()


func _refresh_fragment_label() -> void:
	_save_shared_profile()
	if fragment_label == null:
		return
	var fragments := profile.memory_fragments if profile != null else 0
	fragment_label.text = "记忆碎片  %d" % fragments


func _on_dialogue_finished() -> void:
	var npc_id := _active_npc_id
	_active_npc_id = &""
	if not _pending_event_id.is_empty():
		# The personal event owns this conversation; do not fall through into
		# 咕噜's shelf right after he says the bottle is not for sale.
		var event_id := _pending_event_id
		_pending_event_id = ""
		_record_npc_event(event_id)
		return
	if npc_id == &"guru" and shop_ui != null:
		_refresh_shop_discount()
		shop_ui.open()
	_refresh_player_freeze()


func _on_dialogue_closed() -> void:
	# A page closed before its last line (B / Esc / opening 言灵) leaves the
	# event unseen, so the next talk shows it again.
	_pending_event_id = ""
	if npc_inspire_ui == null or not npc_inspire_ui.is_open():
		_active_npc_id = &""
	_refresh_player_freeze()


func _on_shop_closed() -> void:
	_refresh_player_freeze()
	_refresh_fragment_label()


func _on_shop_purchased(_item_id: StringName) -> void:
	_refresh_fragment_label()
