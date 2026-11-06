class_name ChapterPlanData
extends Resource

## Authored room plan for a chapter. Chapter 1 has a linear plan; Chapters 2–4
## have big-map plans. Chapter 2 is routed in game.gd; Chapters 3–4 keep using
## CampaignData.rooms + game.gd's ROOM_WAVES until their plans are wired.
##
## Optional per-room keys understood by game.gd:
## - `fall_y`: room-local y below which the player is returned to the
##   checkpoint. Unset: the legacy 850 px rule (Chapter 1 behaviour).
## - `fall_below_bounds`: same, measured below the room's union bottom edge.
## Both are optional so old plans and chapters without a plan keep the default.
##
## Big-map plans ([member big_map], chapters 2–4) author one entry per *region*
## instead of one entry per small room. Extra per-region keys:
## - `type`: entrance / branch / hub / well / elite / event / boss / vault.
## - `size`: [width, height] in pixels, whole 1280x720 screens (1–3 per axis).
## - `encounters`: node ids (`region/Node`) that count toward the clear target.
##   Several encounters per region settle independently.
## - `wave`: big-map enemy waves keyed by *encounter node id* (not by region),
##   so two arenas in one region spawn and settle independently. Every combat
##   encounter owns exactly one non-empty wave; the event encounter owns none,
##   and a boss region consumes no ordinary wave. Linear plans (Chapter 1) keep
##   the room-level `wave` array.
## - `chests`, `steles`: per-node content ids; several per region settle
##   independently (see [RoomProgress]).
## - `shortcuts`: door ids this region's shop/stele unlock.
## - `hidden`: marks a secret region (needs a chest or a stele).
## - `shop`, `rest`: hub dressing; a hub owns a shop, a stele and a shortcut.
## [member doors] is the region graph. Each door connects `from` → `to` through
## named world gates; `one_way = false` doors exist in both directions, while a
## one-way door still names a dead-end arrival gate (`to_gate`) in the target
## room. `requires` holds MDS ability/item ids (shortcut barriers). Plans that
## predate the big map leave [member doors] empty and validate cleanly.
##
## A plan whose content pass has not happened yet sets [member content_pending];
## its regions and door graph are validated, while the wave table is deferred.

const DEFAULT_FALL_Y := 850.0
const CLEAR_ROOM_TYPES: PackedStringArray = ["combat", "elite", "event"]
const BIG_MAP_ROOM_TYPES: PackedStringArray = [
	"entrance", "branch", "hub", "well", "elite", "event", "boss", "vault",
]
const SCREEN_SIZE := Vector2i(1280, 720)
const MAX_REGION_SCREENS := 3

@export var chapter_id: StringName = &""
@export var rooms: Array[Dictionary] = []
@export var boss_scene: PackedScene
@export var authority_pool: Array[AuthorityData] = []
## Explicit number of clears that complete the chapter (HUD target). 0 derives
## it from the region encounters (big map) or room types (Chapter 1), so
## authored plans normally leave this alone.
@export var clear_target_override: int = 0
## Big-map plans author regions plus a door graph; Chapter 1 keeps this false.
@export var big_map: bool = false
## Region the player starts in. Empty: the first `type = entrance` region.
@export var start_room: String = ""
## Region graph edges, see the class docs.
@export var doors: Array[Dictionary] = []
## Structural plan authored ahead of its wave content. [method validate] still
## checks the regions and the door graph, but skips [method validate_waves];
## a plan whose waves have landed leaves this false and must validate them.
@export var content_pending: bool = false


func room(room_id: String) -> Dictionary:
	for entry in rooms:
		if String(entry.get("id", "")) == room_id:
			return entry
	return {}


## How many encounters/events count toward the chapter's clear target.
## Big-map regions list their clearing encounters explicitly, so a region with
## two arenas counts twice. Chapter 1 entries have no `encounters` key, so the
## derived value still matches the old six-room demo rule without hard-coding
## six in game.gd.
func clear_target() -> int:
	if clear_target_override > 0:
		return clear_target_override
	var total := 0
	for entry in rooms:
		var encounters: Variant = entry.get("encounters", null)
		if encounters is Array:
			total += encounters.size()
		elif CLEAR_ROOM_TYPES.has(String(entry.get("type", ""))):
			total += 1
	return total


## Region the chapter starts from: the authored [member start_room], else the
## first entrance region. Empty for plans without a big-map graph.
func start_region() -> String:
	if not start_room.is_empty():
		return start_room
	for entry in rooms:
		if String(entry.get("type", "")) == "entrance":
			return String(entry.get("id", ""))
	return ""


func room_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for entry in rooms:
		var id := String(entry.get("id", ""))
		if not id.is_empty():
			out.append(id)
	return out


func regions_of_type(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in rooms:
		if String(entry.get("type", "")) == type:
			out.append(entry)
	return out


## Authored [width, height] of a big-map region, or Vector2i.ZERO when unset.
func region_size(room_id: String) -> Vector2i:
	var value: Variant = room(room_id).get("size", null)
	if value is Array and value.size() >= 2:
		var width: Variant = value[0]
		var height: Variant = value[1]
		if (width is int or width is float) and (height is int or height is float):
			return Vector2i(int(width), int(height))
	return Vector2i.ZERO


## Fall plane for a big-map region, measured from its own authored height.
func region_fall_limit(room_id: String) -> float:
	var size := region_size(room_id)
	var height := float(size.y) if size.y > 0 else 720.0
	return fall_limit(room_id, height)


func encounter_ids() -> PackedStringArray:
	return _content_ids("encounters")


## Enemy wave authored for one encounter node. Big-map plans key `wave` by
## encounter id (`region/Node`), so the lookup never falls back to room level;
## linear plans keep the room-level array and ignore [param encounter_id].
func wave_for(room_id: String, encounter_id := "") -> Array:
	var value: Variant = room(room_id).get("wave", null)
	if value is Dictionary:
		var wave: Variant = value.get(encounter_id, [])
		return wave if wave is Array else []
	if value is Array:
		return value
	return []


func chest_ids() -> PackedStringArray:
	return _content_ids("chests")


func stele_ids() -> PackedStringArray:
	return _content_ids("steles")


func shortcut_ids() -> PackedStringArray:
	return _content_ids("shortcuts")


func _content_ids(key: String) -> PackedStringArray:
	var out := PackedStringArray()
	for entry in rooms:
		var list: Variant = entry.get(key, null)
		if list is Array:
			for value in list:
				if value is String and not String(value).is_empty():
					out.append(String(value))
	return out


func door(door_id: String) -> Dictionary:
	for entry in doors:
		if String(entry.get("id", "")) == door_id:
			return entry
	return {}


func one_way_doors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in doors:
		if bool(entry.get("one_way", false)):
			out.append(entry)
	return out


## Regions reachable in one step. Two-way doors count in both directions;
## one-way doors only in their authored direction.
func door_targets(room_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for entry in doors:
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		if from == room_id:
			out.append(to)
		if to == room_id and not bool(entry.get("one_way", false)):
			out.append(from)
	return out


## Breadth-first region walk from [param start] (the entrance by default).
## [param directed] follows the authored door directions; pass false to treat
## one-way doors as ordinary edges when checking that nothing is isolated.
func reachable_from(start := "", directed := true) -> PackedStringArray:
	var origin := start if not start.is_empty() else start_region()
	var out := PackedStringArray()
	if origin.is_empty() or not room_ids().has(origin):
		return out
	var queue: Array[String] = [origin]
	var seen := {origin: true}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		out.append(current)
		var targets := door_targets(current) if directed else _undirected_targets(current)
		for target in targets:
			var next := String(target)
			if next.is_empty() or seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return out


func _undirected_targets(room_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for entry in doors:
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		if from == room_id:
			out.append(to)
		elif to == room_id:
			out.append(from)
	return out


## Room-local y of the fall plane. `room_local_height` is the union height of
## the room's rectangles (only used by `fall_below_bounds`).
func fall_limit(room_id: String, room_local_height := 720.0) -> float:
	return fall_limit_from_entry(room(room_id), room_local_height, DEFAULT_FALL_Y)


## Shared by game.gd so the plan and the runtime helper cannot drift. Returns
## [param fallback] when the entry configures neither key (or holds garbage).
static func fall_limit_from_entry(entry: Dictionary, room_local_height: float, fallback: float) -> float:
	if entry.has("fall_y"):
		var y: Variant = entry["fall_y"]
		if y is int or y is float:
			return float(y)
	if entry.has("fall_below_bounds"):
		var below: Variant = entry["fall_below_bounds"]
		if below is int or below is float:
			return room_local_height + float(below)
	return fallback


## Everything wrong with this plan: region fields, per-node content ids and the
## region graph. Empty means the plan is safe to load. Plans marked
## [member content_pending] skip the wave table (its content lands later);
## the region/graph checks still run.
func validate() -> PackedStringArray:
	var errors := validate_regions()
	errors.append_array(validate_graph())
	if not content_pending:
		errors.append_array(validate_waves())
	return errors


## Big-map wave table: `wave` is keyed by encounter node id, every combat
## encounter owns a non-empty enemy list, the event encounter owns none, and
## keys cannot point at another region. Linear plans (Chapter 1) keep their
## historical room-level arrays and are not checked here.
func validate_waves() -> PackedStringArray:
	var errors := PackedStringArray()
	if not big_map:
		return errors
	for entry in rooms:
		var room_id := String(entry.get("id", ""))
		if room_id.is_empty():
			continue
		var encounters := _strings(entry.get("encounters", []))
		var event_region := String(entry.get("type", "")) == "event"
		var value: Variant = entry.get("wave", null)
		var waves: Dictionary = {}
		if value != null:
			if not value is Dictionary:
				errors.append("region %s wave must map encounter node ids to enemy lists" % room_id)
				continue
			waves = value
		for key in waves.keys():
			var key_text := String(key)
			if not encounters.has(key_text):
				errors.append("region %s wave %s is not a listed encounter" % [room_id, key_text])
				continue
			var wave: Variant = waves[key]
			if not wave is Array:
				errors.append("region %s wave %s must be an enemy list" % [room_id, key_text])
				continue
			if wave.is_empty():
				errors.append("region %s wave %s is empty" % [room_id, key_text])
			for enemy_id in wave:
				if not enemy_id is String and not enemy_id is StringName:
					errors.append("region %s wave %s has a non-string enemy id"
						% [room_id, key_text])
				elif String(enemy_id).is_empty():
					errors.append("region %s wave %s has an empty enemy id" % [room_id, key_text])
		if event_region:
			for encounter_id in encounters:
				if waves.has(encounter_id):
					errors.append("event encounter %s must not own a wave" % encounter_id)
			continue
		for encounter_id in encounters:
			if not waves.has(encounter_id):
				errors.append("encounter %s needs a wave" % encounter_id)
	return errors


## Region shape, fall planes and per-node content ids. Chapter 1 plans (no
## [member big_map]) only need unique ids and keep the historical defaults.
func validate_regions() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for entry in rooms:
		var id := String(entry.get("id", ""))
		if id.is_empty():
			errors.append("region entry is missing an id")
			continue
		if seen.has(id):
			errors.append("duplicate region id %s" % id)
		seen[id] = true
	if not big_map:
		return errors
	for entry in rooms:
		var id := String(entry.get("id", ""))
		if id.is_empty():
			continue
		var type := String(entry.get("type", ""))
		if not BIG_MAP_ROOM_TYPES.has(type):
			errors.append("region %s has unknown big-map type '%s'" % [id, type])
		var size := region_size(id)
		if size.x <= 0 or size.y <= 0:
			errors.append("region %s needs a positive [width, height] size" % id)
		else:
			if size.x % SCREEN_SIZE.x != 0 or size.y % SCREEN_SIZE.y != 0:
				errors.append("region %s size %s is not a whole number of 1280x720 screens"
					% [id, size])
			var screens_x := float(size.x) / float(SCREEN_SIZE.x)
			var screens_y := float(size.y) / float(SCREEN_SIZE.y)
			if screens_x < 1.0 or screens_x > float(MAX_REGION_SCREENS) \
					or screens_y < 1.0 or screens_y > float(MAX_REGION_SCREENS):
				errors.append("region %s is %.1f x %.1f screens (allowed 1–%d)"
					% [id, screens_x, screens_y, MAX_REGION_SCREENS])
		if not entry.has("fall_y") and not entry.has("fall_below_bounds"):
			errors.append("region %s needs fall_y or fall_below_bounds" % id)
		elif region_fall_limit(id) <= float(size.y):
			errors.append("region %s fall plane %.0f does not clear its %.0f px height"
				% [id, region_fall_limit(id), float(size.y)])
		if entry.has("hidden") and not entry["hidden"] is bool:
			errors.append("region %s hidden must be a bool" % id)
		if not entry.has("encounters"):
			errors.append("region %s needs an encounters list (empty if none)" % id)
		for key in ["encounters", "chests", "steles", "shortcuts"]:
			var list: Variant = entry.get(key, null)
			if list != null and not list is Array:
				errors.append("region %s %s must be an array" % [id, key])
	errors.append_array(_validate_content_ids("encounters", "encounter"))
	errors.append_array(_validate_content_ids("chests", "chest"))
	errors.append_array(_validate_content_ids("steles", "stele"))
	return errors


## Door graph: gate ownership, explicit one-way edges, the big-map shape
## (entrance → branches → hub → well → elite/event → boss + hidden vault) and
## reachability from the entrance.
func validate_graph() -> PackedStringArray:
	var errors := PackedStringArray()
	var known := {}
	for entry in rooms:
		var id := String(entry.get("id", ""))
		if not id.is_empty():
			known[id] = entry
	var door_ids := {}
	var gate_claims := {}
	var pairs := {}
	for entry in doors:
		var id := String(entry.get("id", ""))
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		if id.is_empty():
			errors.append("door is missing an id")
		elif door_ids.has(id):
			errors.append("duplicate door id %s" % id)
		door_ids[id] = true
		if not known.has(from):
			errors.append("door %s leaves unknown region %s" % [id, from])
		if not known.has(to):
			errors.append("door %s enters unknown region %s" % [id, to])
		if from == to:
			errors.append("door %s connects %s to itself" % [id, from])
		if entry.has("one_way") and not entry["one_way"] is bool:
			errors.append("door %s one_way must be a bool" % id)
		var from_gate := String(entry.get("from_gate", ""))
		var to_gate := String(entry.get("to_gate", ""))
		if from_gate.is_empty():
			errors.append("door %s needs from_gate" % id)
		else:
			var from_error := _claim_gate(gate_claims, from, from_gate, id)
			if not from_error.is_empty():
				errors.append(from_error)
		if to_gate.is_empty():
			errors.append("door %s needs to_gate (the arrival gate)" % id)
		else:
			var to_error := _claim_gate(gate_claims, to, to_gate, id)
			if not to_error.is_empty():
				errors.append(to_error)
		var requires: Variant = entry.get("requires", [])
		if not requires is Array:
			errors.append("door %s requires must be an array" % id)
		else:
			for requirement in requires:
				if not requirement is String or String(requirement).is_empty():
					errors.append("door %s requires entries must be non-empty strings" % id)
		var pair := "%s|%s" % ([from, to] if from < to else [to, from])
		if pairs.has(pair):
			errors.append("more than one door between %s and %s" % [from, to])
		pairs[pair] = true
	if big_map:
		errors.append_array(_validate_big_map_shape(known))
	# Every shortcut id must be a door owned by the region that lists it.
	for entry in rooms:
		var room_id := String(entry.get("id", ""))
		for shortcut in _strings(entry.get("shortcuts", [])):
			var shortcut_door := door(shortcut)
			if shortcut_door.is_empty():
				errors.append("region %s shortcut %s is not a door" % [room_id, shortcut])
				continue
			if String(shortcut_door.get("from", "")) != room_id:
				errors.append("region %s shortcut %s starts elsewhere" % [room_id, shortcut])
			if _strings(shortcut_door.get("requires", [])).is_empty():
				errors.append("shortcut %s needs a requires entry" % shortcut)
	var start := start_region()
	if not start.is_empty() and known.has(start):
		var reached := reachable_from(start)
		for id in known:
			if not reached.has(String(id)):
				errors.append("region %s is unreachable from %s" % [id, start])
	return errors


func _validate_big_map_shape(known: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var entrances := regions_of_type("entrance")
	if entrances.size() != 1:
		errors.append("big-map plan needs exactly one entrance (got %d)" % entrances.size())
	var start := start_region()
	if start.is_empty() or not known.has(start):
		errors.append("big-map plan needs a valid start_room")
	elif String(known[start].get("type", "")) != "entrance":
		errors.append("start_room %s must be the entrance" % start)
	var hubs := regions_of_type("hub")
	if hubs.size() != 1:
		errors.append("big-map plan needs exactly one hub (got %d)" % hubs.size())
	for hub in hubs:
		var hub_id := String(hub.get("id", ""))
		if not bool(hub.get("rest", false)):
			errors.append("hub %s must have rest = true" % hub_id)
		if String(hub.get("shop", "")).is_empty():
			errors.append("hub %s needs a shop id" % hub_id)
		if _strings(hub.get("steles", [])).is_empty():
			errors.append("hub %s needs at least one stele" % hub_id)
		if _strings(hub.get("shortcuts", [])).is_empty():
			errors.append("hub %s needs a shortcut door" % hub_id)
	var bosses := regions_of_type("boss")
	if bosses.size() != 1:
		errors.append("big-map plan needs exactly one boss region (got %d)" % bosses.size())
	if regions_of_type("branch").size() < 2:
		errors.append("big-map plan needs at least two branches")
	if regions_of_type("well").is_empty():
		errors.append("big-map plan needs a vertical well")
	if regions_of_type("elite").is_empty():
		errors.append("big-map plan needs an elite region")
	if regions_of_type("event").is_empty():
		errors.append("big-map plan needs an event region")
	var hidden := 0
	for entry in rooms:
		if not bool(entry.get("hidden", false)):
			continue
		hidden += 1
		var room_id := String(entry.get("id", ""))
		if _strings(entry.get("chests", [])).is_empty() \
				and _strings(entry.get("steles", [])).is_empty():
			errors.append("hidden region %s needs a chest or stele" % room_id)
	if hidden == 0:
		errors.append("big-map plan needs at least one hidden region")
	if pairs_count() < rooms.size():
		errors.append("big-map graph needs a loop (branching routes must reconnect)")
	return errors


## Number of unique room pairs joined by doors, one-way or not.
func pairs_count() -> int:
	var pairs := {}
	for entry in doors:
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		pairs["%s|%s" % ([from, to] if from < to else [to, from])] = true
	return pairs.size()


func _claim_gate(claims: Dictionary, room_id: String, gate: String, door_id: String) -> String:
	var key := "%s/%s" % [room_id, gate]
	if claims.has(key):
		return "gate %s is used by doors %s and %s" % [key, claims[key], door_id]
	claims[key] = door_id
	return ""


func _validate_content_ids(key: String, label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for entry in rooms:
		var room_id := String(entry.get("id", ""))
		var list: Variant = entry.get(key, null)
		if not list is Array:
			continue
		for value in list:
			if not value is String:
				errors.append("%s id in %s must be a string" % [label, room_id])
				continue
			var id := String(value)
			if id.is_empty():
				errors.append("%s id in %s is empty" % [label, room_id])
				continue
			if not id.begins_with(room_id + "/"):
				errors.append("%s id %s must be a node id in %s (region/Node)" % [label, id, room_id])
			if seen.has(id):
				errors.append("duplicate %s id %s" % [label, id])
			seen[id] = true
	return errors


static func _strings(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is Array:
		for item in value:
			if item is String and not String(item).is_empty():
				out.append(String(item))
	return out
