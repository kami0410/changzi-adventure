class_name Inventory
extends RefCounted

signal changed

const MAX_WEAPONS := 2
const MAX_PHRASES := 2

var weapons: Array[WeaponData] = []
var phrases: Array[ResolvedPhrase] = []
var relics: Array[RelicData] = []
var words: Array[WordData] = []


func _init() -> void:
	weapons.resize(MAX_WEAPONS)
	phrases.resize(MAX_PHRASES)


func equip_weapon(slot: int, weapon: WeaponData) -> bool:
	if slot < 0 or slot >= MAX_WEAPONS or weapon == null:
		return false
	weapons[slot] = weapon
	changed.emit()
	return true


func equip_phrase(slot: int, phrase: ResolvedPhrase) -> bool:
	if slot < 0 or slot >= MAX_PHRASES or phrase == null:
		return false
	phrases[slot] = phrase
	changed.emit()
	return true


func add_relic(relic: RelicData) -> bool:
	if relic == null or has_relic(relic.id):
		return false
	relics.append(relic)
	changed.emit()
	return true


func add_word(word: WordData) -> void:
	if word == null or has_word(word.id):
		return
	words.append(word)
	changed.emit()


func has_word(id: StringName) -> bool:
	for word in words:
		if word.id == id:
			return true
	return false


func has_relic(id: StringName) -> bool:
	for relic in relics:
		if relic.id == id:
			return true
	return false


func total_corruption() -> int:
	var total := 0
	for relic in relics:
		if relic != null:
			total += relic.corruption
	for word in words:
		if word != null:
			total += word.corruption
	return total
