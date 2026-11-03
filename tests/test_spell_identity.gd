extends RefCounted

func run(t: Callable) -> void:
	var resolver := PhraseResolver.new()
	var words: Dictionary = {}
	for entry in ContentLibrary.WORDS:
		words[entry.id] = entry
	var fire := resolver.resolve([words[&"ranshao"], words[&"yan"]] as Array[WordData])
	t.call("spell" in fire, true, "resolved_phrase_describes_actual_spell")
	if not "spell" in fire:
		return
	var lightning := resolver.resolve([words[&"grguan"], words[&"lei"]] as Array[WordData])
	var summon := resolver.resolve([words[&"zhaohuan"], words[&"huixiang"]] as Array[WordData])
	var slow := resolver.resolve([words[&"jingmo"], words[&"shenyuan"]] as Array[WordData])
	t.call(fire.spell["shape"], &"flame", "fire_has_directional_flame")
	t.call(lightning.spell["shape"], &"chain", "thunder_chains_between_targets")
	t.call(summon.spell["shape"], &"sentinel", "summon_creates_persistent_attacker")
	t.call(slow.spell["shape"], &"vortex", "time_abyss_creates_area_control")
	var rapid := resolver.resolve([words[&"shanhuo"], words[&"yan"]] as Array[WordData])
	t.call(rapid.spell["pulses"] > fire.spell["pulses"], true, "rapid_modifier_changes_pattern_not_only_damage")
	t.call(SpellStyle.NAMES.size() >= 8, true, "spell_vocabulary_is_varied")
	t.call(words.size() >= 36, true, "word_catalogue_is_richer")
