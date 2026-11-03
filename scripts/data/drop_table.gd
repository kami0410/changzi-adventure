class_name DropTable
extends Resource

@export var entries: Array[Resource] = []


func roll(rng: RandomNumberGenerator) -> StringName:
	var total := 0.0
	for entry in entries:
		total += maxf(float(entry.get("weight")), 0.0)
	if total <= 0.0:
		return &""
	var pick := rng.randf_range(0.0, total)
	var cursor := 0.0
	for entry in entries:
		cursor += maxf(float(entry.get("weight")), 0.0)
		if pick <= cursor:
			return StringName(entry.get("id"))
	return StringName(entries[-1].get("id"))
