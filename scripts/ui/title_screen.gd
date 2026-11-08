class_name TitleScreen
extends CanvasLayer

signal started
signal settings_requested
signal new_game_requested

var _root: Control
var _flow: GameFlow
var _difficulty: OptionButton
var _difficulty_note: Label
var _new_game_button: Button
var _confirm_panel: ConfirmPanel
var _gallery: EndingGalleryUI
var _gallery_button: Button
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
	version.text = String(ProjectSettings.get_setting("application/config/version", "0.14.0-demo"))
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
	var resume_button: Button = null
	if _flow != null and _flow.has_run_save():
		var resume := Button.new()
		resume.name = "ResumeRunButton"
		resume.text = "继续本局"
		resume.custom_minimum_size = Vector2(280, 50)
		resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		resume.pressed.connect(_resume_run)
		column.add_child(resume)
		resume_button = resume
	var settings := Button.new()
	settings.name = "SettingsButton"
	settings.text = "设置"
	settings.custom_minimum_size = Vector2(280, 44)
	settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings.pressed.connect(func(): settings_requested.emit())
	column.add_child(settings)
	_gallery_button = Button.new()
	_gallery_button.name = "EndingGalleryButton"
	_gallery_button.text = "结局画廊"
	_gallery_button.custom_minimum_size = Vector2(280, 44)
	_gallery_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_gallery_button.pressed.connect(_open_ending_gallery)
	column.add_child(_gallery_button)
	if has_progress:
		_new_game_button = Button.new()
		_new_game_button.name = "NewGameButton"
		_new_game_button.text = "新游戏（清除进度）"
		_new_game_button.custom_minimum_size = Vector2(280, 40)
		_new_game_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_new_game_button.pressed.connect(_confirm_new_game)
		column.add_child(_new_game_button)
	var start := Button.new()
	start.name = "StartButton"
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
	# A player with a checkpoint is most likely coming back to continue, so the
	# first frame starts on "继续本局"; the rest of the flow (A only closes the
	# title and resumes, never starting a new run) is unchanged.
	if resume_button != null and resume_button.is_inside_tree():
		resume_button.grab_focus()
	elif start.is_inside_tree():
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
	if _confirm_panel == null:
		_confirm_panel = ConfirmPanel.new()
		_confirm_panel.name = "NewGameConfirm"
		add_child(_confirm_panel)
		_confirm_panel.confirmed.connect(_start_new_game)
	_confirm_panel.open("清除当前进度并重新开始？", "确认", "取消", _new_game_button)


## The gallery lives on the title layer so it works before a run starts and
## keeps the title's pause state; locking is Profile-only.
func _open_ending_gallery() -> void:
	if _gallery == null:
		_gallery = EndingGalleryUI.new()
		_gallery.name = "EndingGallery"
		add_child(_gallery)
	_gallery.open(_flow.profile if _flow != null else null, _gallery_button)


## Clears the profile first, then announces the new game. Listeners (the Hub)
## read Flow.profile in the signal handler, so emitting earlier would bind them
## to the profile that is about to be freed.
func _start_new_game() -> void:
	if _flow != null:
		RunSave.clear(_flow.run_save_path)
		_flow.reset_profile()
	new_game_requested.emit()
	_start()


func _on_difficulty_selected(index: int) -> void:
	if _difficulty_note != null:
		_difficulty_note.text = Difficulty.note(index)
	if _flow != null:
		_flow.difficulty = index


func _resume_run() -> void:
	if _flow == null or not _flow.has_run_save():
		return
	_flow.resume_requested = true
	_start()


func _start() -> void:
	if _flow != null and _difficulty != null and not _flow.resume_requested:
		_flow.difficulty = _difficulty.selected
	if is_inside_tree():
		get_tree().paused = _was_paused
	visible = false
	started.emit()
