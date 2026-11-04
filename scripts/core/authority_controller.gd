class_name AuthorityController
extends RefCounted

## One authority per run. AuthorityEffects fills the flags; this controller owns
## the one-shot uses (revive once, rewrite once, archive once on death) and the
## run-long devour damage rule so game.gd stays thin.

## Devour turns corruption into damage at this fraction per point (100 -> +60%).
const DEVOUR_DAMAGE_PER_CORRUPTION := 0.006

var authority: AuthorityData
var flags: Dictionary = {}
var revive_used := false
var rewrite_used := false
var archive_used := false


func apply(value: AuthorityData, run: RunState) -> Dictionary:
	authority = value
	flags = AuthorityEffects.apply(run, value)
	revive_used = false
	rewrite_used = false
	archive_used = false
	return flags


func effect_id() -> StringName:
	if authority == null:
		return &""
	return authority.effect_id if authority.effect_id != &"" else authority.id


func can_revive() -> bool:
	return bool(flags.get("revive", false)) and not revive_used


func consume_revive() -> bool:
	if not can_revive():
		return false
	revive_used = true
	return true


func can_rewrite() -> bool:
	return bool(flags.get("rewrite", false)) and not rewrite_used


func consume_rewrite() -> bool:
	if not can_rewrite():
		return false
	rewrite_used = true
	return true


func can_archive() -> bool:
	return bool(flags.get("archive", false)) and not archive_used


func consume_archive() -> bool:
	if not can_archive():
		return false
	archive_used = true
	return true


## HUD state for every authority, including the passive devour rule.
func can_use() -> bool:
	match effect_id():
		&"revive":
			return can_revive()
		&"rewrite":
			return can_rewrite()
		&"devour":
			return bool(flags.get("devour", false))
		&"archive":
			return can_archive()
	return false


## Run-long damage multiplier. Devour reads corruption every frame instead of
## snapshotting it, so healing/purifying corruption also lowers the bonus.
func damage_multiplier(run: RunState) -> float:
	if run == null or not bool(flags.get("devour", false)):
		return 1.0
	var corruption := clampf(float(run.corruption), 0.0, 100.0)
	return 1.0 + corruption * DEVOUR_DAMAGE_PER_CORRUPTION


## Boss offer = the chapter's authored pool plus any conditional authority whose
## condition is met. Base entries keep their order; additions follow
## ContentLibrary order and never duplicate an id already offered.
static func build_pool(base: Array[AuthorityData], run: RunState, profile: Profile,
		records: int) -> Array[AuthorityData]:
	var result: Array[AuthorityData] = []
	var seen: Dictionary = {}
	for authority in base:
		if authority == null or seen.has(authority.id):
			continue
		seen[authority.id] = true
		result.append(authority)
	for resource in ContentLibrary.authorities():
		var authority := resource as AuthorityData
		if authority == null or authority.id == &"" or seen.has(authority.id):
			continue
		if not unlock_met(authority, run, profile, records):
			continue
		seen[authority.id] = true
		result.append(authority)
	return result


static func unlock_met(authority: AuthorityData, run: RunState, profile: Profile,
		records: int) -> bool:
	if authority == null or authority.unlock_condition == &"":
		return false
	var threshold := maxi(authority.unlock_threshold, 0)
	match authority.unlock_condition:
		&"corruption":
			return run != null and run.corruption >= threshold
		&"records":
			return records >= threshold
		&"profile_records":
			return profile != null and profile.records_found >= threshold
	return false
