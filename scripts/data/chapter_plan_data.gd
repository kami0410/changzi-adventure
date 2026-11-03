class_name ChapterPlanData
extends Resource

## Authored room plan for the Chapter 1 demo. Chapter 2–4 keep using
## CampaignData.rooms + game.ROOM_WAVES until they get their own demo pass.

@export var chapter_id: StringName = &""
@export var rooms: Array[Dictionary] = []
@export var boss_scene: PackedScene
@export var authority_pool: Array[AuthorityData] = []


func room(room_id: String) -> Dictionary:
	for entry in rooms:
		if String(entry.get("id", "")) == room_id:
			return entry
	return {}
