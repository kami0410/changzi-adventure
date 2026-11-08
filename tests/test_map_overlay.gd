extends RefCounted

## Map title per chapter. Chapter 1 keeps its historical "档案馆地图" label
## verbatim; Chapter 2 names the big map after its authored region instead of
## inheriting that label. The overlay is driven through its real label node so
## a regression in _build()/set_chapter() cannot hide behind the static helper.

const SCRIPT_PATH := "res://scripts/ui/map_overlay.gd"
const ARCHIVE_TITLE := "档案馆地图"


func run(t: Callable) -> void:
	_test_titles(t)
	_test_overlay_label(t)


func _test_titles(t: Callable) -> void:
	var map_overlay := load(SCRIPT_PATH) as GDScript
	t.call(map_overlay != null, true, "map_overlay_script_loads")
	if map_overlay == null:
		return
	var chapter_1: String = map_overlay.map_title(0)
	var chapter_2: String = map_overlay.map_title(1)
	t.call(chapter_1, ARCHIVE_TITLE, "map_title_chapter_1_unchanged")
	t.call(chapter_2, "呼吸废墟地图", "map_title_chapter_2_region")
	t.call(chapter_2 != chapter_1, true, "map_titles_do_not_collapse")
	# The title is the authored region name + 地图, not a newly invented name.
	var region := String(CampaignData.chapter(1).get("region", ""))
	t.call(region, "呼吸废墟", "map_title_chapter_2_region_source")
	t.call(chapter_2, "%s地图" % region, "map_title_uses_authored_region")
	# Later chapters follow the same rule, so Chapter 3/4 do not fall back to
	# the Chapter 1 label either.
	t.call(map_overlay.map_title(2), "无光海地图", "map_title_chapter_3_region")
	t.call(map_overlay.map_title(3), "笑面剧场地图", "map_title_chapter_4_region")
	t.call(map_overlay.map_title(-1), ARCHIVE_TITLE, "map_title_negative_falls_back")


func _test_overlay_label(t: Callable) -> void:
	# set_chapter() can arrive before _ready(); the title must survive until
	# _build() creates the label.
	var early := load(SCRIPT_PATH).new() as MapOverlay
	early.set_chapter(1)
	t.call(early.title_text(), "呼吸废墟地图", "map_title_survives_pre_ready")
	early._build()
	t.call(early.title_text(), "呼吸废墟地图", "map_title_applied_at_build")
	early.free()

	var overlay := load(SCRIPT_PATH).new() as MapOverlay
	# Unit tests run before the SceneTree root enters the tree, so add_child
	# would not call _ready here. Build the same widgets explicitly; the real
	# _ready path is covered by integration_playability.
	overlay._build()
	t.call(overlay.title_text(), ARCHIVE_TITLE, "map_overlay_default_title")
	overlay.set_chapter(1)
	t.call(overlay.title_text(), "呼吸废墟地图", "map_overlay_chapter_2_label")
	overlay.set_chapter(0)
	t.call(overlay.title_text(), ARCHIVE_TITLE, "map_overlay_chapter_1_label_restored")
	# Switching back and forth must not leave the previous chapter's title.
	overlay.set_chapter(2)
	t.call(overlay.title_text(), "无光海地图", "map_overlay_chapter_3_label")
	overlay.set_chapter(1)
	overlay.set_chapter(0)
	t.call(overlay.title_text(), ARCHIVE_TITLE, "map_overlay_no_sticky_chapter_title")
	overlay.free()
