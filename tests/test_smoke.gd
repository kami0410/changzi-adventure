extends RefCounted


func run(t: Callable) -> void:
	t.call(1 + 1, 2, "smoke_math")
