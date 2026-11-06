class_name RoomProgress
extends RefCounted

## Stable ids for one-shot room content and combat encounters.
##
## Chapter 1 has one arena/chest/stele per room, but the big-map chapters reuse
## a room for several encounters and props. Progress is therefore recorded per
## node id (`room/NodeName`, or an authored id), not per room. Rooms without an
## authored id still resolve deterministically from the room id and node name.

const EVENT_ENCOUNTER := "event"


## Authored id first, then `room_id/NodeName`. An empty node name falls back to
## the room id so a malformed fixture can never produce an empty key.
static func content_id(room_id: String, node_name: String, authored := "") -> String:
	if not authored.is_empty():
		return authored
	if node_name.is_empty():
		return room_id
	if room_id.is_empty():
		return node_name
	return "%s/%s" % [room_id, node_name]


static func encounter_id(room_id: String, node_name: String, authored := "") -> String:
	return content_id(room_id, node_name, authored)


static func event_encounter_id(room_id: String) -> String:
	return "%s/%s" % [room_id, EVENT_ENCOUNTER]


## Makes [param base] unique inside [param used] by appending `#2`, `#3`…  The
## winner is recorded in `used`. Deterministic for a given node order, so a
## reload of the same room resolves the same ids.
static func unique_id(base: String, used: Dictionary) -> String:
	var candidate := base
	var index := 2
	while used.has(candidate):
		candidate = "%s#%d" % [base, index]
		index += 1
	used[candidate] = true
	return candidate


## Whether a one-shot id is already recorded, including a legacy checkpoint
## that only stored the room id (one-piece rooms written before per-node ids).
static func is_recorded(ids: Dictionary, legacy_rooms: Dictionary, id: String, room_id: String) -> bool:
	return ids.has(id) or legacy_rooms.has(room_id)
