class_name WordRuntime
extends RefCounted

## Per-run word copies. WordData is a shared Resource; writing `decoded` on it
## would leak state between runs and saves. Every acquisition path duplicates
## first, then applies the Profile's decoding state to the copy.

static func for_run(source: WordData, profile: Profile) -> WordData:
	if source == null:
		return null
	var copy := source.duplicate() as WordData
	copy.decoded = profile == null or profile.is_word_decoded(source.id)
	return copy


static func mark_decoded(word: WordData) -> void:
	if word != null:
		word.decoded = true
