class_name DialogueData
extends Resource

@export var speaker: String = ""
@export var lines: Array[String] = []


func line_at(index: int) -> String:
	if lines.is_empty():
		return ""
	return lines[posmod(index, lines.size())]


func line_count() -> int:
	return lines.size()
