extends RefCounted

## Word mastery must show up in actual spell damage, not only in ink cost, and
## the bonus stays capped so it cannot be farmed without bound.

func run(t: Callable) -> void:
	var original_profile: Profile = Flow.profile
	var profile := Profile.new()
	Flow.profile = profile
	var caster := PhraseCaster.new()
	caster.damage_scale = 1.0
	var words: Array[WordData] = [
		load("res://resources/words/ranshao.tres") as WordData,
		load("res://resources/words/yan.tres") as WordData,
	]
	var phrase := PhraseResolver.new().resolve(words)
	var base_damage := caster._build_context(phrase).damage
	t.call(base_damage > 0.0, true, "mastery_phrase_has_damage")

	profile.add_word_mastery(&"ranshao", 50)
	profile.add_word_mastery(&"yan", 50)
	var boosted := caster._build_context(phrase).damage
	t.call(boosted > base_damage, true, "mastery_increases_damage")
	t.call(boosted / base_damage >= 1.01, true, "mastery_damage_is_visible")
	t.call(boosted / base_damage <= 1.25, true, "mastery_damage_is_capped")

	Flow.profile = original_profile
	profile.free()
	caster.free()
