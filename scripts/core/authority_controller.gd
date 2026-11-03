class_name AuthorityController
extends RefCounted

## One authority per run. AuthorityEffects fills the flags; this controller owns
## the one-shot uses (revive once, rewrite once) so game.gd stays thin.

var authority: AuthorityData
var flags: Dictionary = {}
var revive_used := false
var rewrite_used := false


func apply(value: AuthorityData, run: RunState) -> Dictionary:
	authority = value
	flags = AuthorityEffects.apply(run, value)
	revive_used = false
	rewrite_used = false
	return flags


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
