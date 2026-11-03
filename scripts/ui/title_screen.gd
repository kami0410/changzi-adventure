class_name TitleScreen
extends CanvasLayer

signal started
signal settings_requested
signal new_game_requested

var _root: Control
var _flow: GameFlow
var _difficulty: OptionButton
var _difficulty_note: Label
var _built := false

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "res://assets/audio/music/title.ogg", 1.2)
	if is_inside_tree():
		_was_paused = get_tree().paused
		get_tree().paused = true

var _was_paused := false

func _build() -> void:
	if _built:
		return
	_built = true
	if _flow == null:
		_flow = _flow_node()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = preload("res://resources/ui/ink_theme.tres")
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(UIPalette.INK_NIGHT, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var emblem := TextureRect.new()
	emblem.texture = load("res://assets/branding/logo_pixel.png")
	emblem.custom_minimum_size = Vector2(256, 256)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(emblem)
	var title := Label.new()
	title.text = "昌子大冒险"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tagline := Label.new()
	tagline.text = "一页被撕走的名册，一场不愿遗忘的冒险。"
	tagline.add_theme_font_size_override("font_size", 12)
	tagline.add_theme_color_override("font_color", UIPalette.BONE_DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	var version := Label.new()
	version.text = "0.11.0-demo"
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", UIPalette.BONE_DIM)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	column.add_child(gap)
	if _flow == null:
		_flow = _flow_node()
	var has_progress := inv_has_progress(_flow)
	_difficulty = OptionButton.new()
	_difficulty.custom_minimum_size = Vector2(360, 40)
	_difficulty.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_difficulty.add_theme_font_size_override("font_size", 12)
	for index in mini(Difficulty.count(), 2):
		_difficulty.add_item("%s · %s" % [Difficulty.display_name(index), Difficulty.subtitle(index)])
	_difficulty.selected = clampi(_flow.difficulty if _flow != null else 0, 0, 1)
	_difficulty.item_selected.connect(_on_difficulty_selected)
	column.add_child(_difficulty)
	_difficulty_note = Label.new()
	_difficulty_note.add_theme_font_size_override("font_size", 12)
	_difficulty_note.add_theme_color_override("font_color", UIPalette.GOLD)
	_difficulty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_difficulty_note)
	_on_difficulty_selected(_difficulty.selected)
	var settings := Button.new()
	settings.name = "SettingsButton"
	settings.text = "设置"
	settings.custom_minimum_size = Vector2(280, 44)
	settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings.pressed.connect(func(): settings_requested.emit())
	column.add_child(settings)
	if has_progress:
		var new_game := Button.new()
		new_game.name = "NewGameButton"
		new_game.text = "新游戏（清除进度）"
		new_game.custom_minimum_size = Vector2(280, 40)
		new_game.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_game.pressed.connect(_confirm_new_game)
		column.add_child(new_game)
	var start := Button.new()
	start.text = "继续旅程" if has_progress else "开始旅程"
	start.custom_minimum_size = Vector2(280, 50)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_start)
	column.add_child(start)
	var quit := Button.new()
	quit.text = "离开档案馆"
	quit.custom_minimum_size = Vector2(280, 44)
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)
	start.grab_focus()

func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func inv_has_progress(flow: GameFlow) -> bool:
	if flow == null or flow.profile == null:
		return false
	return flow.profile.memory_fragments > 0 or not flow.profile.discovered_phrases.is_empty()


func _confirm_new_game() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.name = "NewGameConfirm"
	dialog.dialog_text = "清除当前进度并重新开始？"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.confirmed.connect(func() -> void:
		new_game_requested.emit()
		if _flow != null:
			_flow.reset_profile()
		_start()
	)
	add_child(dialog)
	dialog.popup_centered()


func _on_difficulty_selected(index: int) -> void:
	if _difficulty_note != null:
		_difficulty_note.text = Difficulty.note(index)
	if _flow != null:
		_flow.difficulty = index


func _start() -> void:
	if _flow != null and _difficulty != null:
		_flow.difficulty = _difficulty.selected
	if is_inside_tree():
		get_tree().paused = _was_paused
	visible = false
	started.emit()
